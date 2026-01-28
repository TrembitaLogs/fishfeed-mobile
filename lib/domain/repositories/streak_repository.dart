import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/entities/streak.dart';

/// Repository interface for streak operations.
///
/// Provides a clean API for managing user feeding streaks following Clean Architecture.
/// All methods return [Either] type for explicit error handling.
abstract interface class StreakRepository {
  /// Gets the streak for a specific user.
  ///
  /// [userId] is the ID of the user whose streak to retrieve.
  ///
  /// Returns [Right(Streak)] on success.
  /// Returns [Left(Failure)] on error:
  /// - [CacheFailure] for local storage issues
  Future<Either<Failure, Streak>> getStreak(String userId);

  /// Watches the streak for a specific user as a stream.
  ///
  /// [userId] is the ID of the user whose streak to watch.
  /// Emits new values whenever the streak is updated.
  Stream<Streak> watchStreak(String userId);

  /// Updates the streak in local storage.
  ///
  /// [streak] is the updated streak entity to save.
  ///
  /// Returns [Right(unit)] on success.
  /// Returns [Left(Failure)] on error:
  /// - [CacheFailure] for local storage issues
  Future<Either<Failure, Unit>> updateStreak(Streak streak);

  /// Increments the streak for a user after a successful feeding.
  ///
  /// [userId] is the ID of the user.
  /// [feedingDate] is the date of the completed feeding.
  ///
  /// Automatically updates best streak if current exceeds it.
  ///
  /// Returns [Right(Streak)] with the updated streak on success.
  /// Returns [Left(Failure)] on error.
  Future<Either<Failure, Streak>> incrementStreak(
    String userId,
    DateTime feedingDate,
  );

  /// Handles a missed feeding day.
  ///
  /// [userId] is the ID of the user.
  /// [missedDate] is the date that was missed.
  ///
  /// If freeze is available, uses it to preserve the streak.
  /// Otherwise, resets the current streak to 0.
  ///
  /// Returns [Right(Streak)] with the updated streak on success.
  /// Returns [Left(Failure)] on error.
  Future<Either<Failure, Streak>> handleMissedDay(
    String userId,
    DateTime missedDate,
  );

  /// Uses a freeze day to prevent streak loss.
  ///
  /// [userId] is the ID of the user.
  /// [freezeDate] is the date to apply the freeze.
  ///
  /// Returns [Right(Streak)] with updated freeze count on success.
  /// Returns [Left(Failure)] on error:
  /// - [ValidationFailure] if no freeze days available
  Future<Either<Failure, Streak>> useFreeze(
    String userId,
    DateTime freezeDate,
  );

  /// Resets the monthly freeze availability.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Should be called at the start of each month to restore freeze days.
  ///
  /// Returns [Right(Streak)] with reset freeze count on success.
  /// Returns [Left(Failure)] on error.
  Future<Either<Failure, Streak>> resetMonthlyFreeze(String userId);

  /// Checks if streak needs monthly freeze reset.
  ///
  /// [userId] is the ID of the user.
  ///
  /// Returns true if last reset was in a previous month.
  Future<bool> needsMonthlyFreezeReset(String userId);
}
