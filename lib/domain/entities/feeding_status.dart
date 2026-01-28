/// Status of a scheduled feeding event.
///
/// Used in Today View to indicate whether a feeding has been completed,
/// missed, or is still pending.
enum FeedingStatus {
  /// Feeding was completed successfully.
  fed,

  /// Feeding time has passed without marking as fed.
  missed,

  /// Feeding is scheduled but time hasn't arrived yet.
  pending,
}
