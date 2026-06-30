import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show AndroidScheduleMode;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/services/notifications/notification_permission_service.dart';
import 'package:fishfeed/services/notifications/notification_service.dart';
import 'package:fishfeed/services/notifications/planned_alarm.dart'
    show
        NotifError,
        PlannedAlarm,
        ReconcileReason,
        ReconcileResult,
        NotificationChannel;

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
    required this.permissionService,
    DateTime Function()? now,
    bool? isIos,
  }) : _now = now ?? DateTime.now,
       _isIos = isIos ?? Platform.isIOS;

  final ScheduleLocalDataSource scheduleDs;
  final FishLocalDataSource fishDs;
  final AquariumLocalDataSource aquariumDs;
  final NotificationService notificationService;
  final NotificationPermissionService permissionService;
  final DateTime Function() _now;
  final bool _isIos;

  /// In-flight reconcile future; used to serialize concurrent calls.
  /// If a reconcile is running, other calls wait for it to complete.
  Future<ReconcileResult>? _inFlight;

  /// Platform-specific max alarms: iOS 60, Android 200.
  int _platformMaxAlarms() => _isIos ? 60 : 200;

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
    // Wall-clock "now" in the scheduling zone. Built component-wise (not via
    // instant conversion) so the comparison matches how `scheduledAt` below is
    // constructed from local date + time, regardless of the host time zone.
    final nowLocal = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
      now.microsecond,
    );
    for (final s in activeSchedules) {
      final fish = fishDs.getFishById(s.fishId);
      if (fish == null || fish.isDeleted) continue;
      final aquarium = aquariumDs.getAquariumById(s.aquariumId);
      if (aquarium == null || aquarium.isDeleted) continue;
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
        // Never plan an occurrence whose time has already passed. Otherwise a
        // diff-based reconcile run after the alarm fired would see the id
        // missing from the OS pending set, re-add it for a past instant, and
        // the OS would fire it immediately (duplicate "now"/"x min ago" spam).
        if (scheduledAt.isBefore(nowLocal)) continue;
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
      final dropped = planned.length - maxAlarms;
      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(
            category: 'notif',
            message: 'alarm-budget-trim',
            data: {
              'kept': maxAlarms,
              'dropped': dropped,
              'window_days': windowDays,
            },
          ),
        ),
      );
      planned.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return planned.sublist(0, maxAlarms);
    }
    return planned;
  }

  /// Public entry point: reconciles system pending notifications with the
  /// current Hive state.
  ///
  /// Concurrent calls are serialized via an in-flight mutex. If a reconcile is
  /// running, subsequent calls wait for it to complete before starting.
  ///
  /// For most reasons does diff-based reconcile (add/cancel only what changed).
  /// For [ReconcileReason.localeChanged] and [ReconcileReason.migration] does
  /// a full cancelAll + replan to refresh body strings / wipe legacy IDs.
  ///
  /// Per-alarm failures (schedule/cancel) are caught and collected into
  /// [ReconcileResult.errors], allowing the reconcile to process all alarms.
  /// Catastrophic non-loop errors (e.g., Hive failures) are caught by the
  /// outer try/catch and returned via [ReconcileResult.failed].
  Future<ReconcileResult> reconcile({required ReconcileReason reason}) async {
    // If a reconcile is already running, wait for it to finish before starting.
    while (_inFlight != null) {
      await _inFlight;
    }
    final completer = Completer<ReconcileResult>();
    _inFlight = completer.future;
    try {
      final result = await _doReconcile(reason);
      completer.complete(result);
      return result;
    } catch (e) {
      final result = ReconcileResult.failed(e);
      completer.complete(result);
      return result;
    } finally {
      _inFlight = null;
    }
  }

  /// Internal implementation of reconcile logic.
  /// Extracted for testing and clarity; called by [reconcile] after mutex gate.
  Future<ReconcileResult> _doReconcile(ReconcileReason reason) async {
    final stopwatch = Stopwatch()..start();
    unawaited(
      Sentry.addBreadcrumb(
        Breadcrumb(
          category: 'notif',
          message: 'reconcile.start',
          data: {'reason': reason.name},
        ),
      ),
    );
    try {
      // Early-return when OS permission is not granted — no alarms scheduled.
      final permission = await permissionService.checkPermission();
      if (permission == NotificationPermissionStatus.denied ||
          permission == NotificationPermissionStatus.permanentlyDenied ||
          permission == NotificationPermissionStatus.restricted) {
        stopwatch.stop();
        unawaited(
          Sentry.addBreadcrumb(
            Breadcrumb(
              category: 'notif',
              message: 'reconcile.skipped',
              data: {'reason': reason.name, 'cause': 'permission_denied'},
            ),
          ),
        );
        return ReconcileResult.success(
          added: 0,
          cancelled: 0,
          kept: 0,
          duration: stopwatch.elapsed,
        );
      }

      final planned = planForWindow(
        now: _now(),
        maxAlarms: _platformMaxAlarms(),
      );

      // Resolve AndroidScheduleMode once per reconcile pass.
      final scheduleMode = await _resolveAndroidScheduleMode();

      // Locale change & migration force full reset.
      if (reason == ReconcileReason.localeChanged ||
          reason == ReconcileReason.migration) {
        await notificationService.cancelAllNotifications();
        final errors = <NotifError>[];
        var added = 0;
        for (final p in planned) {
          try {
            await _scheduleOne(p, scheduleMode);
            added++;
          } catch (e) {
            errors.add(
              NotifError(
                eventId: p.eventId,
                kind: e.runtimeType.toString(),
                message: e.toString(),
              ),
            );
          }
        }
        stopwatch.stop();
        unawaited(
          Sentry.addBreadcrumb(
            Breadcrumb(
              category: 'notif',
              message: 'reconcile.done',
              data: {
                'reason': reason.name,
                'added': planned.length,
                'cancelled': 0,
                'kept': 0,
                'duration_ms': stopwatch.elapsedMilliseconds,
              },
            ),
          ),
        );
        return ReconcileResult.success(
          added: added,
          cancelled: 0,
          kept: 0,
          errors: errors,
          duration: stopwatch.elapsed,
        );
      }

      final pending = await notificationService.getPendingNotifications();
      final pendingIds = pending.map((p) => p.id).toSet();
      final diff = diffAgainstSystem(planned: planned, pendingIds: pendingIds);

      final errors = <NotifError>[];
      var cancelled = 0;
      for (final id in diff.toCancel) {
        try {
          await notificationService.cancelNotification(id);
          cancelled++;
        } catch (e) {
          errors.add(
            NotifError(
              eventId: id,
              kind: e.runtimeType.toString(),
              message: e.toString(),
            ),
          );
        }
      }

      var added = 0;
      for (final p in diff.toAdd) {
        try {
          await _scheduleOne(p, scheduleMode);
          added++;
        } catch (e) {
          errors.add(
            NotifError(
              eventId: p.eventId,
              kind: e.runtimeType.toString(),
              message: e.toString(),
            ),
          );
        }
      }

      stopwatch.stop();
      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(
            category: 'notif',
            message: 'reconcile.done',
            data: {
              'reason': reason.name,
              'added': diff.toAdd.length,
              'cancelled': diff.toCancel.length,
              'kept': diff.toKeep.length,
              'duration_ms': stopwatch.elapsedMilliseconds,
            },
          ),
        ),
      );
      return ReconcileResult.success(
        added: added,
        cancelled: cancelled,
        kept: diff.toKeep.length,
        errors: errors,
        duration: stopwatch.elapsed,
      );
    } catch (e, st) {
      stopwatch.stop();
      unawaited(
        Sentry.captureException(
          e,
          stackTrace: st,
          withScope: (scope) {
            scope.setTag('component', 'notification_orchestrator');
            scope.setTag('reason', reason.name);
          },
        ),
      );
      return ReconcileResult.failed(e);
    }
  }

  /// Resolves the AndroidScheduleMode for the current reconcile pass.
  ///
  /// On iOS always returns [AndroidScheduleMode.exactAllowWhileIdle] (the value
  /// is passed to [scheduleOneShot] but has no effect on the platform plugin).
  /// On Android 12+ checks whether SCHEDULE_EXACT_ALARM is still granted; if
  /// revoked, falls back silently to [AndroidScheduleMode.inexactAllowWhileIdle].
  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    if (_isIos) return AndroidScheduleMode.exactAllowWhileIdle;
    final canExact = await notificationService.canScheduleExactAlarms();
    if (!canExact) {
      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(
            category: 'notif',
            message: 'exact-alarm-revoked-fallback',
          ),
        ),
      );
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
    return AndroidScheduleMode.exactAllowWhileIdle;
  }

  /// Reconcile alarms scoped to a specific aquarium.
  ///
  /// v1: simply delegates to full [reconcile] with [ReconcileReason.userMutation].
  /// The `aquariumId` parameter is preserved on the API surface for future
  /// optimization (per-aquarium scoped reconcile).
  Future<ReconcileResult> reconcileForAquarium(String aquariumId) {
    return reconcile(reason: ReconcileReason.userMutation);
  }

  Future<void> _scheduleOne(
    PlannedAlarm alarm,
    AndroidScheduleMode mode,
  ) async {
    await notificationService.scheduleOneShot(
      id: alarm.eventId,
      title: alarm.title,
      body: alarm.body,
      scheduledAt: alarm.scheduledAt,
      payload: alarm.payload,
      androidScheduleMode: mode,
    );
  }
}
