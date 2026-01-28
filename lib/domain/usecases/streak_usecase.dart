import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/data/models/streak_model.dart';
import 'package:fishfeed/domain/entities/streak.dart';

/// Parameters for [CheckAndUpdateStreakUseCase].
class CheckAndUpdateStreakParams {
  const CheckAndUpdateStreakParams({
    required this.userId,
    required this.aquariumId,
    required this.totalScheduledFeedings,
    required this.completedFeedings,
    this.date,
  });

  /// ID of the user whose streak to update.
  final String userId;

  /// ID of the aquarium to check feedings for.
  final String aquariumId;

  /// Total number of scheduled feedings for the day.
  final int totalScheduledFeedings;

  /// Number of completed feedings for the day.
  final int completedFeedings;

  /// Date to check (defaults to today).
  final DateTime? date;
}

/// Result of streak update operation.
class StreakUpdateResult {
  const StreakUpdateResult({
    required this.streak,
    required this.wasIncremented,
    required this.wasReset,
    required this.freezeUsed,
  });

  /// The updated streak.
  final Streak streak;

  /// Whether the streak was incremented.
  final bool wasIncremented;

  /// Whether the streak was reset to 0.
  final bool wasReset;

  /// Whether a freeze day was used.
  final bool freezeUsed;
}

/// Use case for checking and updating streak based on feeding completion.
///
/// Handles the business logic for:
/// - Incrementing streak when all feedings are completed
/// - Using freeze days when feedings are missed
/// - Resetting streak when no freeze is available
/// - Monthly freeze reset
class StreakUseCase {
  StreakUseCase({
    required StreakLocalDataSource streakDataSource,
    required FeedingLocalDataSource feedingDataSource,
  }) : _streakDataSource = streakDataSource,
       _feedingDataSource = feedingDataSource;

  final StreakLocalDataSource _streakDataSource;
  final FeedingLocalDataSource _feedingDataSource;

  /// Checks if all feedings for the day are completed and updates streak accordingly.
  ///
  /// If all scheduled feedings are completed:
  /// - Increments the current streak
  /// - Updates best streak if current exceeds it
  ///
  /// Returns [Right(StreakUpdateResult)] on success.
  /// Returns [Left(Failure)] on error.
  Future<Either<Failure, StreakUpdateResult>> checkAndUpdateStreak(
    CheckAndUpdateStreakParams params,
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
      // Check and apply monthly freeze reset if needed
      await _streakDataSource.checkAndResetMonthlyFreeze(params.userId);

      final date = params.date ?? DateTime.now();
      final allFed = isAllFedForDay(
        params.totalScheduledFeedings,
        params.completedFeedings,
      );

      if (allFed) {
        // All feedings completed - increment streak
        final updatedStreak = await _streakDataSource.incrementStreak(
          params.userId,
          date,
        );

        return Right(
          StreakUpdateResult(
            streak: updatedStreak.toEntity(),
            wasIncremented: true,
            wasReset: false,
            freezeUsed: false,
          ),
        );
      }

      // Not all feedings completed - check current streak status
      final currentStreak = _streakDataSource.getStreakByUserId(params.userId);
      if (currentStreak == null) {
        // No existing streak, create one
        final newStreak = StreakModel(
          id: 'streak_${params.userId}',
          userId: params.userId,
          currentStreak: 0,
          longestStreak: 0,
        );
        await _streakDataSource.saveStreak(newStreak);

        return Right(
          StreakUpdateResult(
            streak: newStreak.toEntity(),
            wasIncremented: false,
            wasReset: false,
            freezeUsed: false,
          ),
        );
      }

      return Right(
        StreakUpdateResult(
          streak: currentStreak.toEntity(),
          wasIncremented: false,
          wasReset: false,
          freezeUsed: false,
        ),
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to update streak: $e'));
    }
  }

  /// Handles a missed feeding day.
  ///
  /// [userId] - The ID of the user.
  /// [missedDate] - The date that was missed.
  ///
  /// If freeze is available and streak is active:
  /// - Uses freeze to preserve the streak
  ///
  /// If no freeze is available:
  /// - Resets the current streak to 0
  ///
  /// Returns [Right(StreakUpdateResult)] on success.
  /// Returns [Left(Failure)] on error.
  Future<Either<Failure, StreakUpdateResult>> handleMissedDay({
    required String userId,
    required DateTime missedDate,
  }) async {
    if (userId.isEmpty) {
      return const Left(
        ValidationFailure(
          errors: {
            'userId': ['User ID is required'],
          },
        ),
      );
    }

    try {
      // Check and apply monthly freeze reset if needed
      await _streakDataSource.checkAndResetMonthlyFreeze(userId);

      final beforeStreak = _streakDataSource.getStreakByUserId(userId);
      final hadStreak = beforeStreak != null && beforeStreak.currentStreak > 0;
      final hadFreeze =
          beforeStreak != null && beforeStreak.freezeAvailable > 0;

      final updatedStreak = await _streakDataSource.handleMissedDay(
        userId,
        missedDate,
      );

      final freezeUsed =
          hadStreak &&
          hadFreeze &&
          updatedStreak.currentStreak > 0 &&
          updatedStreak.frozenDays.any(
            (d) =>
                d.year == missedDate.year &&
                d.month == missedDate.month &&
                d.day == missedDate.day,
          );

      final wasReset = hadStreak && updatedStreak.currentStreak == 0;

      return Right(
        StreakUpdateResult(
          streak: updatedStreak.toEntity(),
          wasIncremented: false,
          wasReset: wasReset,
          freezeUsed: freezeUsed,
        ),
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to handle missed day: $e'));
    }
  }

  /// Uses a freeze day to prevent streak loss.
  ///
  /// [userId] - The ID of the user.
  /// [freezeDate] - The date to apply the freeze.
  ///
  /// Returns [Right(Streak)] on success.
  /// Returns [Left(Failure)] on error or if no freeze available.
  Future<Either<Failure, Streak>> useFreeze({
    required String userId,
    required DateTime freezeDate,
  }) async {
    if (userId.isEmpty) {
      return const Left(
        ValidationFailure(
          errors: {
            'userId': ['User ID is required'],
          },
        ),
      );
    }

    try {
      final result = await _streakDataSource.useFreeze(userId, freezeDate);

      if (result == null) {
        return const Left(
          ValidationFailure(
            errors: {
              'freeze': ['No freeze days available'],
            },
          ),
        );
      }

      return Right(result.toEntity());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to use freeze: $e'));
    }
  }

  /// Checks if all scheduled feedings for the day are completed.
  ///
  /// [totalScheduled] - Total number of scheduled feedings.
  /// [completed] - Number of completed feedings.
  ///
  /// Returns `true` if all feedings are completed.
  bool isAllFedForDay(int totalScheduled, int completed) {
    if (totalScheduled <= 0) {
      return false;
    }
    return completed >= totalScheduled;
  }

  /// Checks if all feedings for an aquarium on a specific date are completed.
  ///
  /// [aquariumId] - The ID of the aquarium.
  /// [date] - The date to check.
  /// [scheduledCount] - Number of scheduled feedings for that day.
  ///
  /// Returns `true` if all scheduled feedings have been completed.
  bool isAllFedToday({
    required String aquariumId,
    required DateTime date,
    required int scheduledCount,
  }) {
    if (scheduledCount <= 0) {
      return false;
    }

    final events = _feedingDataSource.getFeedingEventsByDate(date);
    final aquariumEvents = events
        .where((e) => e.aquariumId == aquariumId)
        .length;

    return aquariumEvents >= scheduledCount;
  }

  /// Gets the current streak for a user.
  ///
  /// [userId] - The ID of the user.
  ///
  /// Returns [Right(Streak)] on success.
  /// Returns [Left(Failure)] on error.
  Future<Either<Failure, Streak>> getStreak(String userId) async {
    if (userId.isEmpty) {
      return const Left(
        ValidationFailure(
          errors: {
            'userId': ['User ID is required'],
          },
        ),
      );
    }

    try {
      // Check and apply monthly freeze reset if needed
      final streak = await _streakDataSource.checkAndResetMonthlyFreeze(userId);

      if (streak == null) {
        // Create default streak if none exists
        final newStreak = StreakModel(
          id: 'streak_$userId',
          userId: userId,
          currentStreak: 0,
          longestStreak: 0,
        );
        await _streakDataSource.saveStreak(newStreak);
        return Right(newStreak.toEntity());
      }

      return Right(streak.toEntity());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get streak: $e'));
    }
  }

  /// Resets the monthly freeze availability.
  ///
  /// [userId] - The ID of the user.
  ///
  /// Returns [Right(Streak)] on success.
  /// Returns [Left(Failure)] on error.
  Future<Either<Failure, Streak>> resetMonthlyFreeze(String userId) async {
    if (userId.isEmpty) {
      return const Left(
        ValidationFailure(
          errors: {
            'userId': ['User ID is required'],
          },
        ),
      );
    }

    try {
      final result = await _streakDataSource.resetMonthlyFreeze(userId);

      if (result == null) {
        return const Left(CacheFailure(message: 'No streak found for user'));
      }

      return Right(result.toEntity());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to reset monthly freeze: $e'));
    }
  }

  /// Watches the streak for a specific user.
  ///
  /// [userId] - The ID of the user whose streak to watch.
  ///
  /// Emits new values whenever the streak is updated.
  Stream<Streak?> watchStreak(String userId) {
    return _streakDataSource
        .watchStreak(userId)
        .map((model) => model?.toEntity());
  }

  /// Checks if the streak is at risk of being lost today.
  ///
  /// [userId] - The ID of the user.
  /// [currentlyAllFed] - Whether all feedings for today are completed.
  ///
  /// Returns `true` if:
  /// - User has an active streak (currentStreak > 0)
  /// - Not all feedings are completed today
  /// - User has freeze days available
  ///
  /// This is useful for triggering freeze warning notifications.
  Future<bool> isStreakAtRisk({
    required String userId,
    required bool currentlyAllFed,
  }) async {
    if (currentlyAllFed) {
      return false;
    }

    final streakResult = await getStreak(userId);

    return streakResult.fold(
      (_) => false,
      (streak) => streak.currentStreak > 0 && streak.freezeAvailable > 0,
    );
  }

  /// Gets the time for freeze warning notification (2 hours before end of day).
  ///
  /// Returns DateTime at 22:00 (10 PM) of the current day.
  DateTime getFreezeWarningTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 22, 0);
  }
}
