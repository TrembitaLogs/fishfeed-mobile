import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/constants/achievements.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/achievement_local_ds.dart';
import 'package:fishfeed/data/datasources/local/feeding_log_local_ds.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/data/datasources/local/user_progress_local_ds.dart';
import 'package:fishfeed/domain/entities/achievement.dart';
import 'package:fishfeed/domain/entities/user_achievement.dart';

/// Result of an achievement unlock check operation.
class AchievementCheckResult {
  const AchievementCheckResult({
    required this.newlyUnlocked,
    required this.totalXpAwarded,
  });

  /// List of achievements that were newly unlocked.
  final List<Achievement> newlyUnlocked;

  /// Total XP awarded for the newly unlocked achievements.
  final int totalXpAwarded;

  /// Whether any achievements were unlocked.
  bool get hasUnlocked => newlyUnlocked.isNotEmpty;
}

/// Use case for managing achievements.
///
/// Handles:
/// - Checking and unlocking achievements based on user stats
/// - Getting achievement progress
/// - Retrieving unlocked and all achievements
class AchievementUseCase {
  AchievementUseCase({
    required AchievementLocalDataSource achievementDataSource,
    required FeedingLogLocalDataSource feedingLogDataSource,
    required StreakLocalDataSource streakDataSource,
    required UserProgressLocalDataSource progressDataSource,
  }) : _achievementDataSource = achievementDataSource,
       _feedingLogDataSource = feedingLogDataSource,
       _streakDataSource = streakDataSource,
       _progressDataSource = progressDataSource;

  final AchievementLocalDataSource _achievementDataSource;
  final FeedingLogLocalDataSource _feedingLogDataSource;
  final StreakLocalDataSource _streakDataSource;
  final UserProgressLocalDataSource _progressDataSource;

  /// Checks all achievements and unlocks any that meet their criteria.
  ///
  /// [userId] - The ID of the user.
  ///
  /// Returns [Right(AchievementCheckResult)] with newly unlocked achievements.
  /// Returns [Left(Failure)] on error.
  Future<Either<Failure, AchievementCheckResult>> checkAchievements(
    String userId,
  ) async {
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
      final stats = await _getUserStats(userId);
      final newlyUnlocked = <Achievement>[];
      int totalXp = 0;

      // Check each achievement type
      for (final type in AchievementType.values) {
        if (_achievementDataSource.isAchievementUnlocked(userId, type)) {
          continue; // Already unlocked
        }

        final shouldUnlock = _checkUnlockCondition(type, stats);
        if (shouldUnlock) {
          final unlocked = await _achievementDataSource.unlockAchievement(
            userId,
            type,
          );
          if (unlocked != null) {
            newlyUnlocked.add(unlocked.toEntity());
            totalXp += type.xpReward;

            // Award XP for the achievement
            await _progressDataSource.addXp(userId, type.xpReward);
          }
        } else {
          // Update progress for partial achievements
          final progress = _calculateProgress(type, stats);
          if (progress > 0) {
            await _achievementDataSource.updateProgress(userId, type, progress);
          }
        }
      }

      return Right(
        AchievementCheckResult(
          newlyUnlocked: newlyUnlocked,
          totalXpAwarded: totalXp,
        ),
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to check achievements: $e'));
    }
  }

  /// Checks a specific achievement type for unlock.
  ///
  /// [userId] - The ID of the user.
  /// [type] - The achievement type to check.
  ///
  /// Returns the unlocked achievement if newly unlocked, null otherwise.
  Future<Either<Failure, Achievement?>> checkSingleAchievement(
    String userId,
    AchievementType type,
  ) async {
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
      if (_achievementDataSource.isAchievementUnlocked(userId, type)) {
        return const Right(null); // Already unlocked
      }

      final stats = await _getUserStats(userId);
      final shouldUnlock = _checkUnlockCondition(type, stats);

      if (shouldUnlock) {
        final unlocked = await _achievementDataSource.unlockAchievement(
          userId,
          type,
        );
        if (unlocked != null) {
          await _progressDataSource.addXp(userId, type.xpReward);
          return Right(unlocked.toEntity());
        }
      } else {
        // Update progress
        final progress = _calculateProgress(type, stats);
        await _achievementDataSource.updateProgress(userId, type, progress);
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to check achievement: $e'));
    }
  }

  /// Gets all achievements for a user.
  ///
  /// [userId] - The ID of the user.
  ///
  /// Returns all achievements in display order.
  Future<Either<Failure, List<Achievement>>> getAllAchievements(
    String userId,
  ) async {
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
      final achievements = await _achievementDataSource
          .getAllAchievementsOrdered(userId);
      return Right(achievements);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get achievements: $e'));
    }
  }

  /// Gets unlocked achievements for a user.
  ///
  /// [userId] - The ID of the user.
  ///
  /// Returns only unlocked achievements.
  Future<Either<Failure, List<Achievement>>> getUnlockedAchievements(
    String userId,
  ) async {
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
      final unlocked = _achievementDataSource
          .getUnlockedAchievements(userId)
          .map((m) => m.toEntity())
          .toList();
      return Right(unlocked);
    } catch (e) {
      return Left(
        CacheFailure(message: 'Failed to get unlocked achievements: $e'),
      );
    }
  }

  /// Gets the progress for a specific achievement.
  ///
  /// [userId] - The ID of the user.
  /// [type] - The achievement type.
  ///
  /// Returns progress as a value between 0.0 and 1.0.
  Future<Either<Failure, double>> getProgress(
    String userId,
    AchievementType type,
  ) async {
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
      final achievement = _achievementDataSource.getAchievementByType(
        userId,
        type,
      );
      if (achievement != null) {
        return Right(achievement.progress);
      }

      // Calculate current progress
      final stats = await _getUserStats(userId);
      final progress = _calculateProgress(type, stats);
      return Right(progress);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get progress: $e'));
    }
  }

  /// Gets the count of unlocked achievements.
  ///
  /// [userId] - The ID of the user.
  int getUnlockedCount(String userId) {
    return _achievementDataSource.getUnlockedAchievements(userId).length;
  }

  /// Gets the total count of achievements.
  int getTotalCount() {
    return AchievementType.values.length;
  }

  /// Watches achievements for changes.
  ///
  /// [userId] - The ID of the user.
  Stream<List<Achievement>> watchAchievements(String userId) {
    return _achievementDataSource.watchAchievements(userId);
  }

  // ============ Private Methods ============

  /// Gets the current user stats for achievement checking.
  Future<UserStats> _getUserStats(String userId) async {
    // Get total feedings count (only "fed" actions, not "skipped")
    final allLogs = _feedingLogDataSource.getAll();
    final totalFeedings = allLogs.where((log) => log.isFed).length;

    // Get streak info
    final streakModel = _streakDataSource.getStreakByUserId(userId);
    final currentStreak = streakModel?.currentStreak ?? 0;
    final longestStreak = streakModel?.longestStreak ?? 0;

    // For now, use current streak as consecutive days without miss
    // In a more complex implementation, this would be calculated separately
    final consecutiveDaysWithoutMiss = currentStreak;

    return UserStats(
      userId: userId,
      totalFeedings: totalFeedings,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      consecutiveDaysWithoutMiss: consecutiveDaysWithoutMiss,
    );
  }

  /// Checks if the unlock condition is met for an achievement.
  bool _checkUnlockCondition(AchievementType type, UserStats stats) {
    switch (type) {
      case AchievementType.firstFeeding:
        return stats.totalFeedings >= 1;

      case AchievementType.streak7:
        return stats.currentStreak >= 7 || stats.longestStreak >= 7;

      case AchievementType.streak30:
        return stats.currentStreak >= 30 || stats.longestStreak >= 30;

      case AchievementType.streak100:
        return stats.currentStreak >= 100 || stats.longestStreak >= 100;

      case AchievementType.weekWithoutMiss:
        return stats.consecutiveDaysWithoutMiss >= 7;

      case AchievementType.feedings50:
        return stats.totalFeedings >= 50;

      case AchievementType.feedings100:
        return stats.totalFeedings >= 100;

      case AchievementType.feedings500:
        return stats.totalFeedings >= 500;

      case AchievementType.feedings1000:
        return stats.totalFeedings >= 1000;
    }
  }

  /// Calculates progress towards an achievement (0.0 to 1.0).
  double _calculateProgress(AchievementType type, UserStats stats) {
    final target = type.targetValue;
    if (target == null || target == 0) return 0.0;

    double current;
    switch (type) {
      case AchievementType.firstFeeding:
        current = stats.totalFeedings.toDouble();
        break;

      case AchievementType.streak7:
      case AchievementType.streak30:
      case AchievementType.streak100:
        // Use the higher of current or longest streak
        current =
            (stats.currentStreak > stats.longestStreak
                    ? stats.currentStreak
                    : stats.longestStreak)
                .toDouble();
        break;

      case AchievementType.weekWithoutMiss:
        current = stats.consecutiveDaysWithoutMiss.toDouble();
        break;

      case AchievementType.feedings50:
      case AchievementType.feedings100:
      case AchievementType.feedings500:
      case AchievementType.feedings1000:
        current = stats.totalFeedings.toDouble();
        break;
    }

    return (current / target).clamp(0.0, 1.0);
  }
}
