import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/constants/levels.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/datasources/local/user_progress_local_ds.dart';
import 'package:fishfeed/data/models/feeding_event_model.dart';
import 'package:fishfeed/domain/entities/user_statistics.dart';

/// Parameters for [CalculateStatisticsUseCase].
class CalculateStatisticsParams {
  const CalculateStatisticsParams({
    required this.userId,
  });

  /// The ID of the user to calculate statistics for.
  final String userId;
}

/// Use case for calculating user profile statistics.
///
/// Aggregates data from feeding events and user progress to compute:
/// - On-time feeding percentage
/// - Total feedings count
/// - Days with app
/// - Level and XP progress
class CalculateStatisticsUseCase {
  CalculateStatisticsUseCase({
    required FeedingLocalDataSource feedingDataSource,
    required UserProgressLocalDataSource userProgressDataSource,
  })  : _feedingDataSource = feedingDataSource,
        _userProgressDataSource = userProgressDataSource;

  final FeedingLocalDataSource _feedingDataSource;
  final UserProgressLocalDataSource _userProgressDataSource;

  /// Number of scheduled feedings per day (mock data).
  /// In production, this would come from user's actual schedule.
  static const int _feedingsPerDay = 4;

  /// Executes the calculate statistics use case.
  Future<Either<Failure, UserStatistics>> call(
    CalculateStatisticsParams params,
  ) async {
    try {
      // Get all feeding events
      final allEvents = _feedingDataSource.getAllFeedingEvents();

      // Calculate total feedings
      final totalFeedings = allEvents.length;

      // Calculate days with app
      final daysWithApp = _calculateDaysWithApp(allEvents);

      // Calculate on-time percentage
      final onTimePercentage = _calculateOnTimePercentage(
        totalFeedings: totalFeedings,
        daysWithApp: daysWithApp,
      );

      // Get user progress for level/XP info
      final progress = _userProgressDataSource.getProgressByUserId(params.userId);
      final totalXp = progress?.totalXp ?? 0;
      final currentLevel = LevelConstants.getLevelForXp(totalXp);
      final levelProgress = LevelConstants.getXpProgress(totalXp);
      final isMaxLevel = currentLevel == UserLevel.aquariumPro;

      // Calculate XP in current level
      final xpInCurrentLevel = totalXp - currentLevel.minXp;

      // Calculate XP for current level
      final nextLevel = currentLevel.nextLevel;
      final xpForCurrentLevel = nextLevel != null
          ? nextLevel.minXp - currentLevel.minXp
          : 0;

      return Right(UserStatistics(
        onTimePercentage: onTimePercentage,
        totalFeedings: totalFeedings,
        daysWithApp: daysWithApp,
        currentLevel: currentLevel,
        totalXp: totalXp,
        xpInCurrentLevel: xpInCurrentLevel,
        xpForCurrentLevel: xpForCurrentLevel,
        levelProgress: levelProgress,
        isMaxLevel: isMaxLevel,
      ));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to calculate statistics: $e'));
    }
  }

  /// Calculates the number of days since the first feeding event.
  int _calculateDaysWithApp(List<FeedingEventModel> events) {
    if (events.isEmpty) {
      return 0;
    }

    // Find the earliest feeding event
    DateTime? earliestDate;
    for (final event in events) {
      final feedingTime = event.feedingTime;
      if (earliestDate == null || feedingTime.isBefore(earliestDate)) {
        earliestDate = feedingTime;
      }
    }

    if (earliestDate == null) {
      return 0;
    }

    // Calculate days difference from earliest event to now
    final now = DateTime.now();
    final difference = now.difference(earliestDate);
    return difference.inDays + 1; // +1 to include the first day
  }

  /// Calculates the on-time feeding percentage.
  ///
  /// On-time percentage = (completed feedings / expected feedings) * 100
  /// Expected feedings = days with app * feedings per day
  double _calculateOnTimePercentage({
    required int totalFeedings,
    required int daysWithApp,
  }) {
    if (daysWithApp == 0) {
      return 0.0;
    }

    final expectedFeedings = daysWithApp * _feedingsPerDay;
    if (expectedFeedings == 0) {
      return 0.0;
    }

    final percentage = (totalFeedings / expectedFeedings) * 100;
    // Cap at 100% in case of over-feeding
    return percentage > 100 ? 100.0 : percentage;
  }
}
