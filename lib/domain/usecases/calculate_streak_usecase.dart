import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/core/utils/date_time_utils.dart';
import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/data/models/streak_model.dart';
import 'package:fishfeed/domain/entities/streak.dart';

/// Parameters for [CalculateStreakUseCase].
class CalculateStreakParams {
  const CalculateStreakParams({required this.userId});

  /// ID of the user whose streak to calculate.
  final String userId;
}

/// Result of streak calculation.
class StreakCalculationResult {
  const StreakCalculationResult({
    required this.streak,
    required this.isActive,
    required this.daysUntilExpiry,
  });

  /// The calculated streak.
  final Streak streak;

  /// Whether the streak is still active (fed today or yesterday).
  final bool isActive;

  /// Days until streak expires (0 if already expired, 1 if need to feed today).
  final int daysUntilExpiry;
}

/// Use case for calculating and retrieving a user's feeding streak.
///
/// Calculates the current streak based on feeding history and returns
/// detailed information about the streak status.
///
/// Returns [Right(StreakCalculationResult)] on success.
/// Returns [Left(Failure)] on error.
class CalculateStreakUseCase {
  CalculateStreakUseCase({
    required StreakLocalDataSource streakDataSource,
    required FeedingLocalDataSource feedingDataSource,
  }) : _streakDataSource = streakDataSource,
       _feedingDataSource = feedingDataSource;

  final StreakLocalDataSource _streakDataSource;
  final FeedingLocalDataSource _feedingDataSource;

  /// Executes the calculate streak use case.
  Future<Either<Failure, StreakCalculationResult>> call(
    CalculateStreakParams params,
  ) async {
    // Validate params
    if (params.userId.isEmpty) {
      return const Left(
        ValidationFailure(
          errors: {
            'userId': ['User ID is required'],
          },
        ),
      );
    }

    try {
      // Get or create streak
      var streakModel = _streakDataSource.getStreakByUserId(params.userId);

      if (streakModel == null) {
        // Create default streak if none exists
        streakModel = StreakModel(
          id: 'streak_${params.userId}',
          userId: params.userId,
          currentStreak: 0,
          longestStreak: 0,
        );
        await _streakDataSource.saveStreak(streakModel);
      }

      // Check if streak needs to be reset (no feeding yesterday or today)
      final updatedStreak = await _checkAndUpdateStreak(streakModel);

      // Calculate streak status
      final isActive = _streakDataSource.isStreakActive(params.userId);
      final daysUntilExpiry = _calculateDaysUntilExpiry(updatedStreak);

      return Right(
        StreakCalculationResult(
          streak: updatedStreak.toEntity(),
          isActive: isActive,
          daysUntilExpiry: daysUntilExpiry,
        ),
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to calculate streak: $e'));
    }
  }

  /// Checks if streak should be reset based on last feeding date.
  ///
  /// Uses [DateTimeUtils] for timezone-aware date comparison to handle
  /// DST transitions and timezone changes correctly.
  Future<StreakModel> _checkAndUpdateStreak(StreakModel streak) async {
    final lastFeedingDate = streak.lastFeedingDate;
    if (lastFeedingDate == null) {
      return streak;
    }

    // Use DateTimeUtils for proper timezone-aware day calculation
    final difference = DateTimeUtils.daysBetween(
      lastFeedingDate,
      DateTime.now(),
    );

    // If more than 1 day has passed, reset streak
    if (difference > 1 && streak.currentStreak > 0) {
      streak.currentStreak = 0;
      streak.streakStartDate = null;
      await _streakDataSource.saveStreak(streak);
    }

    return streak;
  }

  /// Calculates days until streak expires.
  ///
  /// Uses [DateTimeUtils.checkStreakValidity] for timezone-aware calculation.
  ///
  /// Returns:
  /// - 0 if streak is already broken (no feeding for more than 1 day)
  /// - 1 if user needs to feed today to maintain streak
  /// - 2 if user fed today and has until tomorrow
  int _calculateDaysUntilExpiry(StreakModel streak) {
    final lastFeedingDate = streak.lastFeedingDate;
    if (lastFeedingDate == null || streak.currentStreak == 0) {
      return 0;
    }

    final result = DateTimeUtils.checkStreakValidity(lastFeedingDate);
    return result.daysUntilExpiry;
  }

  /// Recalculates streak from feeding history.
  ///
  /// This method can be used to rebuild streak data if it gets corrupted
  /// or out of sync. It iterates through all feeding events and counts
  /// consecutive days of feeding.
  ///
  /// Uses [DateTimeUtils] for timezone-aware date operations.
  Future<Either<Failure, Streak>> recalculateFromHistory(String userId) async {
    try {
      final allEvents = _feedingDataSource.getAllFeedingEvents();

      if (allEvents.isEmpty) {
        final streak = StreakModel(
          id: 'streak_$userId',
          userId: userId,
          currentStreak: 0,
          longestStreak: 0,
        );
        await _streakDataSource.saveStreak(streak);
        return Right(streak.toEntity());
      }

      // Group events by date using DateTimeUtils for timezone awareness
      final eventsByDate = <DateTime, bool>{};
      for (final event in allEvents) {
        final date = DateTimeUtils.startOfDay(event.feedingTime);
        eventsByDate[date] = true;
      }

      // Sort dates
      final sortedDates = eventsByDate.keys.toList()
        ..sort((a, b) => b.compareTo(a));

      if (sortedDates.isEmpty) {
        final streak = StreakModel(
          id: 'streak_$userId',
          userId: userId,
          currentStreak: 0,
          longestStreak: 0,
        );
        await _streakDataSource.saveStreak(streak);
        return Right(streak.toEntity());
      }

      // Calculate current streak from most recent date backwards
      final today = DateTimeUtils.todayStart;
      final mostRecentDate = sortedDates.first;

      // Check if streak is still active using timezone-aware comparison
      final daysSinceLastFeeding = DateTimeUtils.daysBetween(
        mostRecentDate,
        DateTime.now(),
      );
      if (daysSinceLastFeeding > 1) {
        // Streak is broken
        final existingStreak = _streakDataSource.getStreakByUserId(userId);
        final streak = StreakModel(
          id: 'streak_$userId',
          userId: userId,
          currentStreak: 0,
          longestStreak: existingStreak?.longestStreak ?? 0,
          lastFeedingDate: mostRecentDate,
        );
        await _streakDataSource.saveStreak(streak);
        return Right(streak.toEntity());
      }

      // Count consecutive days
      int currentStreak = 0;
      DateTime? checkDate = daysSinceLastFeeding == 0 ? today : mostRecentDate;

      while (eventsByDate.containsKey(checkDate)) {
        currentStreak++;
        checkDate = checkDate!.subtract(const Duration(days: 1));
      }

      // Find streak start date
      final streakStartDate = mostRecentDate.subtract(
        Duration(days: currentStreak - 1),
      );

      // Get existing longest streak
      final existingStreak = _streakDataSource.getStreakByUserId(userId);
      final longestStreak = existingStreak != null
          ? (currentStreak > existingStreak.longestStreak
                ? currentStreak
                : existingStreak.longestStreak)
          : currentStreak;

      final streak = StreakModel(
        id: 'streak_$userId',
        userId: userId,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastFeedingDate: mostRecentDate,
        streakStartDate: streakStartDate,
      );

      await _streakDataSource.saveStreak(streak);
      return Right(streak.toEntity());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to recalculate streak: $e'));
    }
  }
}
