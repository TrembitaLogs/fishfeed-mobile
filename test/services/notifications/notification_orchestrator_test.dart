import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/services/notifications/notification_orchestrator.dart';

void main() {
  group('NotificationOrchestrator.eventIdFor', () {
    test('produces deterministic positive 32-bit int', () {
      final id1 = NotificationOrchestrator.eventIdFor(
        'schedule-1',
        DateTime(2026, 5, 6),
        '09:00',
      );
      final id2 = NotificationOrchestrator.eventIdFor(
        'schedule-1',
        DateTime(2026, 5, 6),
        '09:00',
      );
      expect(id1, equals(id2));
      expect(id1, greaterThanOrEqualTo(0));
      expect(id1, lessThanOrEqualTo(0x7FFFFFFF));
    });

    test('different scheduleId → different id', () {
      final id1 = NotificationOrchestrator.eventIdFor(
        'schedule-1',
        DateTime(2026, 5, 6),
        '09:00',
      );
      final id2 = NotificationOrchestrator.eventIdFor(
        'schedule-2',
        DateTime(2026, 5, 6),
        '09:00',
      );
      expect(id1, isNot(equals(id2)));
    });

    test('different date → different id', () {
      final id1 = NotificationOrchestrator.eventIdFor(
        'schedule-1',
        DateTime(2026, 5, 6),
        '09:00',
      );
      final id2 = NotificationOrchestrator.eventIdFor(
        'schedule-1',
        DateTime(2026, 5, 7),
        '09:00',
      );
      expect(id1, isNot(equals(id2)));
    });

    test('different time → different id', () {
      final id1 = NotificationOrchestrator.eventIdFor(
        'schedule-1',
        DateTime(2026, 5, 6),
        '09:00',
      );
      final id2 = NotificationOrchestrator.eventIdFor(
        'schedule-1',
        DateTime(2026, 5, 6),
        '10:00',
      );
      expect(id1, isNot(equals(id2)));
    });
  });
}
