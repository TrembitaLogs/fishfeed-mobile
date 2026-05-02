import 'package:timezone/timezone.dart' as tz;

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/services/notifications/notification_service.dart';
import 'package:fishfeed/services/notifications/planned_alarm.dart';

/// Result of comparing a planned set of alarms against system pending state.
/// `toAdd`: planned alarms not yet in the system.
/// `toCancel`: pending IDs that are no longer planned (stale).
/// `toKeep`: planned IDs that already match a pending alarm — no action needed.
class DiffResult {
  const DiffResult({
    required this.toAdd,
    required this.toCancel,
    required this.toKeep,
  });

  final List<PlannedAlarm> toAdd;
  final Set<int> toCancel;
  final Set<int> toKeep;
}

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
    required this.notificationService,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ScheduleLocalDataSource scheduleDs;
  final FishLocalDataSource fishDs;
  final AquariumLocalDataSource aquariumDs;
  final NotificationService notificationService;
  final DateTime Function() _now;

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

  /// Computes add/cancel/keep sets by comparing planned alarms with pending IDs.
  /// Pure function — no I/O, no Hive access. Suitable for unit testing.
  static DiffResult diffAgainstSystem({
    required List<PlannedAlarm> planned,
    required Set<int> pendingIds,
  }) {
    final plannedIds = planned.map((p) => p.eventId).toSet();
    return DiffResult(
      toAdd: planned.where((p) => !pendingIds.contains(p.eventId)).toList(),
      toCancel: pendingIds.difference(plannedIds),
      toKeep: plannedIds.intersection(pendingIds),
    );
  }

  /// Builds the rolling-window plan from current Hive state.
  /// Public for testing; used internally by reconcile() in later tasks.
  ///
  /// Skips schedules whose fish or aquarium is missing or soft-deleted, or
  /// whose fish is on a different aquarium (orphan filter).
  ///
  /// When [maxAlarms] is provided and planned alarms exceed this count,
  /// trims to keep only the nearest dates (sorted by scheduledAt ascending).
  List<PlannedAlarm> planForWindow({
    required DateTime now,
    int windowDays = 7,
    int? maxAlarms,
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

    if (maxAlarms != null && planned.length > maxAlarms) {
      planned.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return planned.sublist(0, maxAlarms);
    }
    return planned;
  }

  /// Public entry point: reconciles system pending notifications with the
  /// current Hive state.
  ///
  /// For most reasons does diff-based reconcile (add/cancel only what changed).
  /// For [ReconcileReason.localeChanged] and [ReconcileReason.migration] does
  /// a full cancelAll + replan to refresh body strings / wipe legacy IDs.
  ///
  /// Errors are caught and returned via [ReconcileResult.failed].
  Future<ReconcileResult> reconcile({required ReconcileReason reason}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final planned = planForWindow(now: _now());

      // Locale change & migration force full reset.
      if (reason == ReconcileReason.localeChanged ||
          reason == ReconcileReason.migration) {
        await notificationService.cancelAllNotifications();
        for (final p in planned) {
          await _scheduleOne(p);
        }
        stopwatch.stop();
        return ReconcileResult.success(
          added: planned.length,
          cancelled: 0,
          kept: 0,
          duration: stopwatch.elapsed,
        );
      }

      final pending = await notificationService.getPendingNotifications();
      final pendingIds = pending.map((p) => p.id).toSet();
      final diff = diffAgainstSystem(planned: planned, pendingIds: pendingIds);

      for (final id in diff.toCancel) {
        await notificationService.cancelNotification(id);
      }
      for (final p in diff.toAdd) {
        await _scheduleOne(p);
      }

      stopwatch.stop();
      return ReconcileResult.success(
        added: diff.toAdd.length,
        cancelled: diff.toCancel.length,
        kept: diff.toKeep.length,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return ReconcileResult.failed(e);
    }
  }

  Future<void> _scheduleOne(PlannedAlarm alarm) async {
    await notificationService.scheduleOneShot(
      id: alarm.eventId,
      title: alarm.title,
      body: alarm.body,
      scheduledAt: alarm.scheduledAt,
      payload: alarm.payload,
    );
  }
}
