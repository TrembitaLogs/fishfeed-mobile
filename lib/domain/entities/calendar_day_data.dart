import 'package:equatable/equatable.dart';

import 'package:fishfeed/domain/entities/day_feeding_status.dart';

/// Feeding data for a single calendar day.
///
/// Contains the overall status and individual feeding counts
/// for display in the calendar view.
class CalendarDayData extends Equatable {
  const CalendarDayData({
    required this.date,
    required this.status,
    this.totalFeedings = 0,
    this.completedFeedings = 0,
    this.missedFeedings = 0,
  });

  /// Creates a day data with no feedings.
  factory CalendarDayData.empty(DateTime date) {
    return CalendarDayData(date: date, status: DayFeedingStatus.noData);
  }

  /// The date this data represents.
  final DateTime date;

  /// Overall feeding status for the day.
  final DayFeedingStatus status;

  /// Total number of scheduled feedings for the day.
  final int totalFeedings;

  /// Number of feedings that were completed.
  final int completedFeedings;

  /// Number of feedings that were missed.
  final int missedFeedings;

  /// Number of feedings that are still pending.
  int get pendingFeedings => totalFeedings - completedFeedings - missedFeedings;

  /// Whether there are any feedings scheduled for this day.
  bool get hasFeedings => totalFeedings > 0;

  /// Completion percentage for the day (0-100).
  double get completionPercentage {
    if (totalFeedings == 0) return 0;
    return (completedFeedings / totalFeedings) * 100;
  }

  /// Creates a copy with updated fields.
  CalendarDayData copyWith({
    DateTime? date,
    DayFeedingStatus? status,
    int? totalFeedings,
    int? completedFeedings,
    int? missedFeedings,
  }) {
    return CalendarDayData(
      date: date ?? this.date,
      status: status ?? this.status,
      totalFeedings: totalFeedings ?? this.totalFeedings,
      completedFeedings: completedFeedings ?? this.completedFeedings,
      missedFeedings: missedFeedings ?? this.missedFeedings,
    );
  }

  @override
  List<Object?> get props => [
    date,
    status,
    totalFeedings,
    completedFeedings,
    missedFeedings,
  ];
}
