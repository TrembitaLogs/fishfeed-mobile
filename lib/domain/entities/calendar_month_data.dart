import 'package:equatable/equatable.dart';

import 'package:fishfeed/domain/entities/calendar_day_data.dart';
import 'package:fishfeed/domain/entities/calendar_month_stats.dart';
import 'package:fishfeed/domain/entities/day_feeding_status.dart';

/// Aggregated feeding data for a calendar month.
///
/// Contains day-by-day status information and overall statistics
/// for display in the calendar view.
class CalendarMonthData extends Equatable {
  const CalendarMonthData({
    required this.year,
    required this.month,
    required this.days,
    required this.stats,
  });

  /// Creates an empty month data with no days.
  factory CalendarMonthData.empty(int year, int month) {
    return CalendarMonthData(
      year: year,
      month: month,
      days: const {},
      stats: const CalendarMonthStats(),
    );
  }

  /// Year of this month data.
  final int year;

  /// Month (1-12) of this month data.
  final int month;

  /// Map of day data keyed by normalized date (year, month, day only).
  ///
  /// Use [getDayStatus] or [getDayData] for convenient access.
  final Map<DateTime, CalendarDayData> days;

  /// Aggregated statistics for the month.
  final CalendarMonthStats stats;

  /// Gets the feeding status for a specific day.
  ///
  /// Returns [DayFeedingStatus.noData] if no data exists for the day.
  DayFeedingStatus getDayStatus(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return days[normalized]?.status ?? DayFeedingStatus.noData;
  }

  /// Gets the full day data for a specific day.
  ///
  /// Returns an empty [CalendarDayData] if no data exists for the day.
  CalendarDayData getDayData(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return days[normalized] ?? CalendarDayData.empty(normalized);
  }

  /// Whether this month has any feeding data.
  bool get hasData => days.isNotEmpty;

  /// Number of days with all feedings completed.
  int get daysAllFed =>
      days.values.where((d) => d.status == DayFeedingStatus.allFed).length;

  /// Number of days with all feedings missed.
  int get daysAllMissed =>
      days.values.where((d) => d.status == DayFeedingStatus.allMissed).length;

  /// Number of days with partial completion.
  int get daysPartial =>
      days.values.where((d) => d.status == DayFeedingStatus.partial).length;

  /// Creates a copy with updated fields.
  CalendarMonthData copyWith({
    int? year,
    int? month,
    Map<DateTime, CalendarDayData>? days,
    CalendarMonthStats? stats,
  }) {
    return CalendarMonthData(
      year: year ?? this.year,
      month: month ?? this.month,
      days: days ?? this.days,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [year, month, days, stats];
}
