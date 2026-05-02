import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import 'package:fishfeed/services/notifications/planned_alarm.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('PlannedAlarm', () {
    test('two alarms with same eventId are equal', () {
      final at = tz.TZDateTime(tz.local, 2026, 5, 6, 9, 0);
      final a = PlannedAlarm(
        eventId: 42,
        scheduleId: 's1',
        fishId: 'f1',
        aquariumId: 'a1',
        scheduledAt: at,
        title: 'T',
        body: 'B',
        channel: NotificationChannel.feedingReminders,
        payload: 'feeding|s1|2026-05-06|0900',
      );
      final b = PlannedAlarm(
        eventId: 42,
        scheduleId: 's1',
        fishId: 'f1',
        aquariumId: 'a1',
        scheduledAt: at,
        title: 'T',
        body: 'B',
        channel: NotificationChannel.feedingReminders,
        payload: 'feeding|s1|2026-05-06|0900',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('ReconcileReason', () {
    test('has all expected variants', () {
      expect(
        ReconcileReason.values,
        containsAll(<ReconcileReason>[
          ReconcileReason.appLaunch,
          ReconcileReason.appResume,
          ReconcileReason.userMutation,
          ReconcileReason.onboardingComplete,
          ReconcileReason.syncComplete,
          ReconcileReason.localeChanged,
          ReconcileReason.permissionChanged,
          ReconcileReason.dailyRefill,
          ReconcileReason.migration,
        ]),
      );
    });
  });

  group('ReconcileResult', () {
    test('success constructor sets fields', () {
      const r = ReconcileResult.success(added: 5, cancelled: 2, kept: 10);
      expect(r.added, 5);
      expect(r.cancelled, 2);
      expect(r.kept, 10);
      expect(r.errors, isEmpty);
      expect(r.isSuccess, isTrue);
    });

    test('failed constructor captures error', () {
      final err = StateError('boom');
      final r = ReconcileResult.failed(err);
      expect(r.isSuccess, isFalse);
      expect(r.error, err);
    });
  });
}
