import 'package:timezone/timezone.dart' as tz;

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/services/notifications/planned_alarm.dart';

/// Orchestrates local notification scheduling — single source of truth
/// for which alarms are pending in the OS vs. what current Hive state implies.
///
/// Public API: `planForWindow(now, windowDays)`, `reconcile(reason)`,
/// `reconcileForAquarium(aquariumId)` (added in later tasks).
/// Triggers: edit screens, family sync, post-sync, app lifecycle,
/// locale change, daily Workmanager refill, migration.
class NotificationOrchestrator {
  NotificationOrchestrator({
    required this.scheduleDs,
    required this.fishDs,
    required this.aquariumDs,
  });

  final ScheduleLocalDataSource scheduleDs;
  final FishLocalDataSource fishDs;
  final AquariumLocalDataSource aquariumDs;

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

  /// Builds the rolling-window plan from current Hive state.
  /// Public for testing; used internally by reconcile() in later tasks.
  ///
  /// Skips schedules whose fish or aquarium is missing or soft-deleted, or
  /// whose fish is on a different aquarium (orphan filter).
  List<PlannedAlarm> planForWindow({
    required DateTime now,
    int windowDays = 7,
    String? title,
    String Function(String fishName)? bodyBuilder,
  }) {
    final activeSchedules = scheduleDs.getAll().where((s) => s.active).toList();

    final planned = <PlannedAlarm>[];
    for (final s in activeSchedules) {
      final fish = fishDs.getFishById(s.fishId);
      if (fish == null || fish.isDeleted) continue;
      final aquarium = aquariumDs.getAquariumById(s.aquariumId);
      if (aquarium == null) continue;
      if (fish.aquariumId != s.aquariumId) continue;

      for (var dayOffset = 0; dayOffset < windowDays; dayOffset++) {
        final date = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(Duration(days: dayOffset));
        if (!s.shouldFeedOn(date)) continue;
        final parts = s.time.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final scheduledAt = tz.TZDateTime(
          tz.local,
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );
        final fishName = fish.name ?? 'fish';
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        planned.add(
          PlannedAlarm(
            eventId: eventIdFor(s.id, date, s.time),
            scheduleId: s.id,
            fishId: s.fishId,
            aquariumId: s.aquariumId,
            scheduledAt: scheduledAt,
            title: title ?? 'Feeding time',
            body: bodyBuilder?.call(fishName) ?? 'Time to feed $fishName',
            channel: NotificationChannel.feedingReminders,
            payload: 'feeding|${s.id}|$dateStr|${s.time.replaceAll(':', '')}',
          ),
        );
      }
    }
    return planned;
  }
}
