/// Status of feeding events for a specific day in the calendar.
///
/// Used in Calendar View to indicate the overall feeding status
/// for a particular date based on completed vs scheduled feedings.
enum DayFeedingStatus {
  /// All scheduled feedings were completed for this day.
  allFed,

  /// All scheduled feedings were missed for this day.
  allMissed,

  /// Some feedings were completed, some were missed.
  partial,

  /// No feeding data available for this day.
  noData,
}
