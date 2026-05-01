import 'package:equatable/equatable.dart';

/// Time window selectable in the Feeding History feature.
enum FeedingHistoryRange { sevenDays, thirtyDays, sixMonths }

extension FeedingHistoryRangeX on FeedingHistoryRange {
  /// Number of days the range spans, inclusive of today.
  int get durationInDays {
    switch (this) {
      case FeedingHistoryRange.sevenDays:
        return 7;
      case FeedingHistoryRange.thirtyDays:
        return 30;
      case FeedingHistoryRange.sixMonths:
        return 180;
    }
  }
}

/// One bucket in the feeding-history heatmap, representing a single local-time
/// calendar day across all accessible aquariums.
class FeedingHistoryDay extends Equatable {
  const FeedingHistoryDay({
    required this.date,
    required this.fedCount,
    required this.aquariumIds,
  });

  /// Local-time start of day for this bucket (no UTC).
  final DateTime date;

  /// Number of `action == 'fed'` logs that fell on [date].
  final int fedCount;

  /// Distinct aquarium IDs that had at least one fed log on [date].
  final List<String> aquariumIds;

  @override
  List<Object?> get props => [date, fedCount, aquariumIds];
}

/// Per-aquarium summary used for the sparkline strip on the profile section
/// when the user has 2 or more accessible aquariums.
class AquariumSparkline extends Equatable {
  const AquariumSparkline({
    required this.aquariumId,
    required this.aquariumName,
    required this.last7DaysCounts,
    required this.totalCountInRange,
  });

  final String aquariumId;
  final String aquariumName;

  /// Length must be exactly 7. Index 0 is the oldest day, 6 is today.
  final List<int> last7DaysCounts;

  /// Sum of fed events for this aquarium across the active range.
  final int totalCountInRange;

  @override
  List<Object?> get props => [
    aquariumId,
    aquariumName,
    last7DaysCounts,
    totalCountInRange,
  ];
}

/// Top-level aggregate consumed by the UI: a dense list of daily buckets,
/// summary numbers, and per-aquarium sparkline data.
class FeedingHistory extends Equatable {
  const FeedingHistory({
    required this.range,
    required this.rangeStart,
    required this.rangeEnd,
    required this.days,
    required this.totalFedCount,
    required this.currentStreak,
    required this.longestStreak,
    required this.bestDayOfWeek,
    required this.aquariumBreakdown,
  });

  final FeedingHistoryRange range;

  /// Inclusive start of the active window, local-time start of day.
  final DateTime rangeStart;

  /// Inclusive end of the active window, local-time start of day (today).
  final DateTime rangeEnd;

  /// One entry per day in `[rangeStart, rangeEnd]`, ordered oldest first.
  /// Days with zero feedings are present with `fedCount = 0`.
  final List<FeedingHistoryDay> days;

  /// Total count of `action == 'fed'` logs in the active range.
  final int totalFedCount;

  /// Current streak from the existing Streak entity, copied for convenience.
  final int currentStreak;

  /// Longest streak from the existing Streak entity, copied for convenience.
  final int longestStreak;

  /// Weekday number (1=Mon..7=Sun, matching `DateTime.weekday`) with the
  /// highest average fed-count across the range. Null if all weekdays
  /// have zero feedings.
  final int? bestDayOfWeek;

  /// Per-aquarium breakdown. Empty if user has fewer than 2 aquariums or if
  /// the caller filtered by a specific aquariumId.
  final List<AquariumSparkline> aquariumBreakdown;

  @override
  List<Object?> get props => [
    range,
    rangeStart,
    rangeEnd,
    days,
    totalFedCount,
    currentStreak,
    longestStreak,
    bestDayOfWeek,
    aquariumBreakdown,
  ];
}
