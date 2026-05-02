import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:fishfeed/services/notifications/notification_service.dart';

/// In-memory fake of [NotificationService] for orchestrator tests.
///
/// Tracks scheduled/cancelled alarms via internal maps + counters.
class FakeNotificationService extends Mock implements NotificationService {
  final Map<int, _ScheduledRecord> _pending = <int, _ScheduledRecord>{};

  /// When true, [scheduleOneShot] throws to exercise per-alarm error isolation.
  bool throwOnSchedule = false;

  /// Backing field for [canScheduleExactAlarms] override.
  bool _canScheduleExactAlarms = true;

  /// Test-only setter — controls what canScheduleExactAlarms() returns.
  // ignore: avoid_setters_without_getters
  set canScheduleExactAlarmsValue(bool value) =>
      _canScheduleExactAlarms = value;

  /// Optional: fail the Nth scheduleOneShot call to test partial failures.
  int? failNthSchedule;
  int _scheduleAttempt = 0;

  int scheduleCallCount = 0;
  int cancelCallCount = 0;
  int cancelAllCallCount = 0;

  /// Last AndroidScheduleMode passed in — used by T16 fallback assertions.
  AndroidScheduleMode? lastUsedMode;

  @override
  Future<bool> canScheduleExactAlarms() async => _canScheduleExactAlarms;

  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _pending.values
        .map(
          (r) => PendingNotificationRequest(r.id, r.title, r.body, r.payload),
        )
        .toList();
  }

  @override
  Future<void> cancelAllNotifications() async {
    cancelAllCallCount++;
    _pending.clear();
  }

  @override
  Future<void> cancelNotification(int id) async {
    cancelCallCount++;
    _pending.remove(id);
  }

  @override
  Future<void> scheduleOneShot({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledAt,
    required String payload,
    AndroidScheduleMode androidScheduleMode =
        AndroidScheduleMode.exactAllowWhileIdle,
  }) async {
    _scheduleAttempt++;
    if (failNthSchedule != null && _scheduleAttempt == failNthSchedule) {
      throw Exception('Forced fail (failNthSchedule)');
    }
    if (throwOnSchedule) {
      throw Exception('Forced fail');
    }
    scheduleCallCount++;
    lastUsedMode = androidScheduleMode;
    _pending[id] = _ScheduledRecord(
      id: id,
      title: title,
      body: body,
      payload: payload,
      scheduledAt: scheduledAt,
      mode: androidScheduleMode,
    );
  }
}

class _ScheduledRecord {
  _ScheduledRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
    required this.scheduledAt,
    required this.mode,
  });

  final int id;
  final String title;
  final String body;
  final String payload;
  final tz.TZDateTime scheduledAt;
  final AndroidScheduleMode mode;
}
