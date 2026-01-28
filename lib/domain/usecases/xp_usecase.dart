import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/constants/levels.dart';
import 'package:fishfeed/core/constants/xp_constants.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/user_progress_local_ds.dart';
import 'package:fishfeed/domain/entities/user_progress.dart';

/// Result of an XP award operation.
class XpAwardResult {
  const XpAwardResult({
    required this.progress,
    required this.xpAwarded,
    required this.didLevelUp,
    this.previousLevel,
    this.newLevel,
  });

  /// The updated user progress.
  final UserProgress progress;

  /// Amount of XP awarded.
  final int xpAwarded;

  /// Whether the user leveled up from this award.
  final bool didLevelUp;

  /// Previous level (if level changed).
  final UserLevel? previousLevel;

  /// New level (if level changed).
  final UserLevel? newLevel;
}

/// Result of a streak bonus check operation.
class StreakBonusResult {
  const StreakBonusResult({
    required this.progress,
    required this.bonusAwarded,
    this.milestone,
    required this.didLevelUp,
    this.previousLevel,
    this.newLevel,
  });

  /// The updated user progress.
  final UserProgress progress;

  /// Bonus XP awarded (0 if no bonus).
  final int bonusAwarded;

  /// The milestone reached (e.g., 7, 30, 100), if any.
  final int? milestone;

  /// Whether the user leveled up from this bonus.
  final bool didLevelUp;

  /// Previous level (if level changed).
  final UserLevel? previousLevel;

  /// New level (if level changed).
  final UserLevel? newLevel;
}

/// Use case for managing XP and level progression.
///
/// Handles:
/// - Awarding XP for feeding events
/// - Checking and awarding streak bonuses
/// - Tracking level progression
class XpUseCase {
  XpUseCase({
    required UserProgressLocalDataSource progressDataSource,
  }) : _progressDataSource = progressDataSource;

  final UserProgressLocalDataSource _progressDataSource;

  /// Awards XP for a feeding event.
  ///
  /// [userId] - The ID of the user.
  /// [isOnTime] - Whether the feeding was completed on time.
  ///
  /// Awards [XpConstants.xpOnTimeFeeding] for on-time feedings,
  /// or [XpConstants.xpLateFeeding] for late feedings.
  ///
  /// Returns [Right(XpAwardResult)] on success.
  /// Returns [Left(Failure)] on error.
  Future<Either<Failure, XpAwardResult>> awardFeedingXp({
    required String userId,
    required bool isOnTime,
  }) async {
    if (userId.isEmpty) {
      return const Left(
        ValidationFailure(errors: {'userId': ['User ID is required']}),
      );
    }

    try {
      // Get current progress to check for level up
      final beforeProgress = await _progressDataSource.getOrCreateProgress(userId);
      final beforeLevel = LevelConstants.getLevelForXp(beforeProgress.totalXp);

      // Determine XP amount based on timing
      final xpAmount = isOnTime
          ? XpConstants.xpOnTimeFeeding
          : XpConstants.xpLateFeeding;

      // Award XP
      final updatedModel = await _progressDataSource.addXp(userId, xpAmount);
      final afterLevel = LevelConstants.getLevelForXp(updatedModel.totalXp);

      // Check for level up
      final didLevelUp = afterLevel != beforeLevel;
      if (didLevelUp) {
        await _progressDataSource.recordLevelUp(userId);
      }

      return Right(XpAwardResult(
        progress: updatedModel.toEntity(),
        xpAwarded: xpAmount,
        didLevelUp: didLevelUp,
        previousLevel: didLevelUp ? beforeLevel : null,
        newLevel: didLevelUp ? afterLevel : null,
      ));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to award XP: $e'));
    }
  }

  /// Checks and awards streak bonus if a milestone is reached.
  ///
  /// [userId] - The ID of the user.
  /// [currentStreak] - The user's current streak count.
  ///
  /// Checks if the streak matches any milestone (7, 30, 100 days).
  /// Awards bonus XP only once per milestone.
  ///
  /// Returns [Right(StreakBonusResult)] on success.
  /// Returns [Left(Failure)] on error.
  Future<Either<Failure, StreakBonusResult>> checkStreakBonus({
    required String userId,
    required int currentStreak,
  }) async {
    if (userId.isEmpty) {
      return const Left(
        ValidationFailure(errors: {'userId': ['User ID is required']}),
      );
    }

    try {
      // Get current progress
      final beforeProgress = await _progressDataSource.getOrCreateProgress(userId);
      final beforeLevel = LevelConstants.getLevelForXp(beforeProgress.totalXp);

      // Find the highest milestone the current streak qualifies for
      // that hasn't been earned yet
      int? eligibleMilestone;
      int bonusXp = 0;

      for (final milestone in XpConstants.streakMilestones) {
        if (currentStreak >= milestone &&
            !_progressDataSource.hasEarnedStreakBonus(userId, milestone)) {
          eligibleMilestone = milestone;
          bonusXp = XpConstants.streakBonuses[milestone]!;
        }
      }

      if (eligibleMilestone == null) {
        // No bonus to award
        return Right(StreakBonusResult(
          progress: beforeProgress.toEntity(),
          bonusAwarded: 0,
          milestone: null,
          didLevelUp: false,
        ));
      }

      // Record that this bonus has been earned
      await _progressDataSource.recordStreakBonusEarned(userId, eligibleMilestone);

      // Award the bonus XP
      final updatedModel = await _progressDataSource.addXp(userId, bonusXp);
      final afterLevel = LevelConstants.getLevelForXp(updatedModel.totalXp);

      // Check for level up
      final didLevelUp = afterLevel != beforeLevel;
      if (didLevelUp) {
        await _progressDataSource.recordLevelUp(userId);
      }

      return Right(StreakBonusResult(
        progress: updatedModel.toEntity(),
        bonusAwarded: bonusXp,
        milestone: eligibleMilestone,
        didLevelUp: didLevelUp,
        previousLevel: didLevelUp ? beforeLevel : null,
        newLevel: didLevelUp ? afterLevel : null,
      ));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to check streak bonus: $e'));
    }
  }

  /// Gets the current user progress.
  ///
  /// [userId] - The ID of the user.
  ///
  /// Creates a new progress record if one doesn't exist.
  ///
  /// Returns [Right(UserProgress)] on success.
  /// Returns [Left(Failure)] on error.
  Future<Either<Failure, UserProgress>> getProgress(String userId) async {
    if (userId.isEmpty) {
      return const Left(
        ValidationFailure(errors: {'userId': ['User ID is required']}),
      );
    }

    try {
      final model = await _progressDataSource.getOrCreateProgress(userId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get progress: $e'));
    }
  }

  /// Watches the user's progress for changes.
  ///
  /// [userId] - The ID of the user whose progress to watch.
  ///
  /// Emits new values whenever the progress is updated.
  Stream<UserProgress?> watchProgress(String userId) {
    return _progressDataSource.watchProgress(userId).map(
      (model) => model?.toEntity(),
    );
  }

  /// Calculates level up information for a given XP amount.
  ///
  /// [currentXp] - Current total XP.
  /// [xpToAdd] - XP that would be added.
  ///
  /// Returns a tuple of (wouldLevelUp, newLevel).
  ({bool wouldLevelUp, UserLevel? newLevel}) getLevelUpInfo({
    required int currentXp,
    required int xpToAdd,
  }) {
    final currentLevel = LevelConstants.getLevelForXp(currentXp);
    final newXp = currentXp + xpToAdd;
    final afterLevel = LevelConstants.getLevelForXp(newXp);

    if (afterLevel != currentLevel) {
      return (wouldLevelUp: true, newLevel: afterLevel);
    }

    return (wouldLevelUp: false, newLevel: null);
  }

  /// Gets earned streak bonuses for a user.
  ///
  /// [userId] - The ID of the user.
  ///
  /// Returns list of milestone values that have been earned.
  List<int> getEarnedStreakBonuses(String userId) {
    return _progressDataSource.getEarnedStreakBonuses(userId);
  }

  /// Checks which streak bonuses are pending for the current streak.
  ///
  /// [userId] - The ID of the user.
  /// [currentStreak] - The user's current streak count.
  ///
  /// Returns list of (milestone, xpAmount) tuples for pending bonuses.
  List<({int milestone, int xpAmount})> getPendingStreakBonuses({
    required String userId,
    required int currentStreak,
  }) {
    final pending = <({int milestone, int xpAmount})>[];
    final earned = _progressDataSource.getEarnedStreakBonuses(userId);

    for (final milestone in XpConstants.streakMilestones) {
      if (currentStreak >= milestone && !earned.contains(milestone)) {
        pending.add((
          milestone: milestone,
          xpAmount: XpConstants.streakBonuses[milestone]!,
        ));
      }
    }

    return pending;
  }
}
