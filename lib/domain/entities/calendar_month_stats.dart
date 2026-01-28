import 'package:equatable/equatable.dart';

/// Statistics for a calendar month's feeding data.
///
/// Provides aggregated metrics about feeding performance for a month,
/// including completion rates and streak information.
class CalendarMonthStats extends Equatable {
  const CalendarMonthStats({
    this.totalScheduledFeedings = 0,
    this.completedFeedings = 0,
    this.missedFeedings = 0,
    this.longestStreak = 0,
    this.currentStreak = 0,
  });

  /// Total number of scheduled feedings for the month.
  final int totalScheduledFeedings;

  /// Number of feedings that were completed.
  final int completedFeedings;

  /// Number of feedings that were missed.
  final int missedFeedings;

  /// Longest consecutive days with all feedings completed in the month.
  final int longestStreak;

  /// Current streak of consecutive days with all feedings completed.
  ///
  /// Only set if the streak is currently active (includes today or yesterday).
  final int currentStreak;

  /// Percentage of completed feedings (0-100).
  double get completionPercentage {
    if (totalScheduledFeedings == 0) return 0;
    return (completedFeedings / totalScheduledFeedings) * 100;
  }

  /// Number of feedings that are still pending (not yet due).
  int get pendingFeedings =>
      totalScheduledFeedings - completedFeedings - missedFeedings;

  /// Whether there are any feedings scheduled for this month.
  bool get hasFeedings => totalScheduledFeedings > 0;

  /// Creates a copy with updated fields.
  CalendarMonthStats copyWith({
    int? totalScheduledFeedings,
    int? completedFeedings,
    int? missedFeedings,
    int? longestStreak,
    int? currentStreak,
  }) {
    return CalendarMonthStats(
      totalScheduledFeedings:
          totalScheduledFeedings ?? this.totalScheduledFeedings,
      completedFeedings: completedFeedings ?? this.completedFeedings,
      missedFeedings: missedFeedings ?? this.missedFeedings,
      longestStreak: longestStreak ?? this.longestStreak,
      currentStreak: currentStreak ?? this.currentStreak,
    );
  }

  @override
  List<Object?> get props => [
        totalScheduledFeedings,
        completedFeedings,
        missedFeedings,
        longestStreak,
        currentStreak,
      ];
}
