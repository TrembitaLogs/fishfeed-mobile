/// Orchestrates local notification scheduling — single source of truth
/// for which alarms are pending in the OS vs. what current Hive state implies.
///
/// Public API: `reconcile(reason)`, `reconcileForAquarium(aquariumId)` (added in
/// later tasks). Triggers: edit screens, family sync, post-sync, app lifecycle,
/// locale change, daily Workmanager refill, migration.
class NotificationOrchestrator {
  /// Deterministic 32-bit positive int derived from `(scheduleId, date, time)`.
  /// Same input → same id. Used for diff-based reconcile (no double-schedule).
  ///
  /// `date` is normalized to YYYY-MM-DD; `hhmm` must be `HH:mm`.
  static int eventIdFor(String scheduleId, DateTime date, String hhmm) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final input = '$scheduleId|$dateStr|$hhmm';
    return input.hashCode.abs() & 0x7FFFFFFF;
  }
}
