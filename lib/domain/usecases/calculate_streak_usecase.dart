import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/core/utils/date_time_utils.dart';
import 'package:fishfeed/data/datasources/local/feeding_log_local_ds.dart';
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
    required FeedingLogLocalDataSource feedingLogDataSource,
  }) : _streakDataSource = streakDataSource,
       _feedingLogDataSource = feedingLogDataSource;

  final StreakLocalDataSource _streakDataSource;
  final FeedingLogLocalDataSource _feedingLogDataSource;

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

  /// Checks if the streak needs to be broken due to missed days.
  ///
  /// Uses freeze days to cover gaps when available. If not enough
  /// freezes exist to cover the gap, the streak is reset to 0.
  /// The client is authoritative for streak state.
  Future<StreakModel> _checkAndUpdateStreak(StreakModel streak) async {
    if (streak.lastFeedingDate == null || streak.currentStreak == 0) {
      return streak;
    }

    final today = DateTimeUtils.todayStart;
    final lastFeedDate = DateTimeUtils.startOfDay(streak.lastFeedingDate!);
    final daysSinceLastFeed = today.difference(lastFeedDate).inDays;

    if (daysSinceLastFeed <= 1) return streak; // Fed today or yesterday

    // Gap detected - missed day(s)
    final missedDays = daysSinceLastFeed - 1;

    if (missedDays <= streak.freezeAvailable) {
      // Can cover all missed days with freezes
      return _streakDataSource.useFreezeMultiple(streak.userId, missedDays);
    } else {
      // Not enough freezes - streak breaks
      final resetStreak = await _streakDataSource.resetStreak(streak.userId);
      return resetStreak ?? streak;
    }
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
  /// or out of sync. It iterates through all feeding logs and counts
  /// consecutive days of feeding.
  ///
  /// Uses [DateTimeUtils] for timezone-aware date operations.
  Future<Either<Failure, Streak>> recalculateFromHistory(String userId) async {
    try {
      // Get all feeding logs with action="fed" (not skipped)
      final allLogs = _feedingLogDataSource
          .getAll()
          .where((l) => l.isFed)
          .toList();

      if (allLogs.isEmpty) {
        final streak = StreakModel(
          id: 'streak_$userId',
          userId: userId,
          currentStreak: 0,
          longestStreak: 0,
        );
        await _streakDataSource.saveStreak(streak);
        return Right(streak.toEntity());
      }

      // Group logs by date using DateTimeUtils for timezone awareness
      final eventsByDate = <DateTime, bool>{};
      for (final log in allLogs) {
        final date = DateTimeUtils.startOfDay(log.scheduledFor);
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
