import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/domain/entities/calendar_day_data.dart';
import 'package:fishfeed/domain/entities/calendar_month_data.dart';
import 'package:fishfeed/domain/entities/calendar_month_stats.dart';
import 'package:fishfeed/domain/entities/day_feeding_status.dart';

/// Parameters for [GetCalendarDataUseCase].
class GetCalendarDataParams {
  const GetCalendarDataParams({required this.year, required this.month});

  /// Year to get data for.
  final int year;

  /// Month (1-12) to get data for.
  final int month;
}

/// Use case for aggregating calendar data for a month.
///
/// Retrieves feeding events from local storage and calculates:
/// - Daily feeding status (allFed, allMissed, partial, noData)
/// - Monthly statistics (completion rate, streaks)
///
/// Returns [Right(CalendarMonthData)] on success.
/// Returns [Left(Failure)] on error.
class GetCalendarDataUseCase {
  GetCalendarDataUseCase({required FeedingLocalDataSource feedingDataSource})
    : _feedingDataSource = feedingDataSource;

  final FeedingLocalDataSource _feedingDataSource;

  /// Number of scheduled feedings per day (mock data).
  /// In production, this would come from user's actual schedule.
  static const int _feedingsPerDay = 4;

  /// Executes the get calendar data use case.
  Future<Either<Failure, CalendarMonthData>> call(
    GetCalendarDataParams params,
  ) async {
    try {
      final days = <DateTime, CalendarDayData>{};
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get the first and last day of the month
      final firstDayOfMonth = DateTime(params.year, params.month, 1);
      final lastDayOfMonth = DateTime(params.year, params.month + 1, 0);

      int totalScheduledFeedings = 0;
      int totalCompletedFeedings = 0;
      int totalMissedFeedings = 0;

      // Process each day of the month
      for (
        var day = firstDayOfMonth;
        !day.isAfter(lastDayOfMonth);
        day = day.add(const Duration(days: 1))
      ) {
        final normalizedDay = DateTime(day.year, day.month, day.day);

        // Skip future days
        if (normalizedDay.isAfter(today)) {
          continue;
        }

        final dayData = _calculateDayData(normalizedDay, today);
        days[normalizedDay] = dayData;

        // Accumulate totals
        totalScheduledFeedings += dayData.totalFeedings;
        totalCompletedFeedings += dayData.completedFeedings;
        totalMissedFeedings += dayData.missedFeedings;
      }

      // Calculate streaks
      final streakInfo = _calculateStreaks(days, today);

      final stats = CalendarMonthStats(
        totalScheduledFeedings: totalScheduledFeedings,
        completedFeedings: totalCompletedFeedings,
        missedFeedings: totalMissedFeedings,
        longestStreak: streakInfo.longestStreak,
        currentStreak: streakInfo.currentStreak,
      );

      return Right(
        CalendarMonthData(
          year: params.year,
          month: params.month,
          days: days,
          stats: stats,
        ),
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get calendar data: $e'));
    }
  }

  /// Calculates feeding data for a single day.
  CalendarDayData _calculateDayData(DateTime day, DateTime today) {
    // Get completed feeding events for this day
    final completedEvents = _feedingDataSource.getFeedingEventsByDate(day);
    final completedCount = completedEvents.length;

    // Use mock schedule: 4 feedings per day
    const totalFeedings = _feedingsPerDay;

    // Calculate missed feedings
    final missedCount = totalFeedings - completedCount;

    // Determine status
    final status = _calculateDayStatus(
      totalFeedings: totalFeedings,
      completedCount: completedCount,
      missedCount: missedCount,
    );

    return CalendarDayData(
      date: day,
      status: status,
      totalFeedings: totalFeedings,
      completedFeedings: completedCount,
      missedFeedings: missedCount > 0 ? missedCount : 0,
    );
  }

  /// Determines the feeding status for a day based on counts.
  DayFeedingStatus _calculateDayStatus({
    required int totalFeedings,
    required int completedCount,
    required int missedCount,
  }) {
    if (totalFeedings == 0) {
      return DayFeedingStatus.noData;
    }

    if (completedCount >= totalFeedings) {
      return DayFeedingStatus.allFed;
    }

    if (completedCount == 0) {
      return DayFeedingStatus.allMissed;
    }

    return DayFeedingStatus.partial;
  }

  /// Calculates streak information from day data.
  _StreakInfo _calculateStreaks(
    Map<DateTime, CalendarDayData> days,
    DateTime today,
  ) {
    if (days.isEmpty) {
      return const _StreakInfo(longestStreak: 0, currentStreak: 0);
    }

    // Sort days by date
    final sortedDays = days.keys.toList()..sort();

    int longestStreak = 0;
    int currentStreakCount = 0;
    int tempStreak = 0;
    DateTime? lastStreakDay;

    for (final day in sortedDays) {
      final dayData = days[day]!;

      if (dayData.status == DayFeedingStatus.allFed) {
        // Continue or start a streak
        if (lastStreakDay == null ||
            day.difference(lastStreakDay).inDays == 1) {
          tempStreak++;
        } else {
          // Gap in days, reset temp streak
          tempStreak = 1;
        }
        lastStreakDay = day;

        // Update longest streak
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        // Streak broken
        tempStreak = 0;
        lastStreakDay = null;
      }
    }

    // Determine if current streak is active
    // (includes today or yesterday with all feedings completed)
    if (lastStreakDay != null) {
      final daysSinceLastStreak = today.difference(lastStreakDay).inDays;
      if (daysSinceLastStreak <= 1) {
        currentStreakCount = tempStreak;
      }
    }

    return _StreakInfo(
      longestStreak: longestStreak,
      currentStreak: currentStreakCount,
    );
  }
}

/// Internal class to hold streak calculation results.
class _StreakInfo {
  const _StreakInfo({required this.longestStreak, required this.currentStreak});

  final int longestStreak;
  final int currentStreak;
}
