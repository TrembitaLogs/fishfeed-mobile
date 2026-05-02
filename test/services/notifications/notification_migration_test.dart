import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fishfeed/services/notifications/notification_migration.dart';
import 'package:fishfeed/services/notifications/notification_orchestrator.dart';
import 'package:fishfeed/services/notifications/notification_service.dart';
import 'package:fishfeed/services/notifications/planned_alarm.dart';

class MockNotificationOrchestrator extends Mock
    implements NotificationOrchestrator {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(ReconcileReason.migration);
  });

  group('runNotificationMigrationV2', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('cancels all + reconciles + sets flag on first run', () async {
      final mockOrch = MockNotificationOrchestrator();
      final mockNotif = MockNotificationService();
      when(() => mockNotif.cancelAllNotifications()).thenAnswer((_) async {});
      when(() => mockOrch.reconcile(reason: any(named: 'reason'))).thenAnswer(
        (_) async =>
            const ReconcileResult.success(added: 5, cancelled: 0, kept: 0),
      );

      final prefs = await SharedPreferences.getInstance();
      await runNotificationMigrationV2(
        orchestrator: mockOrch,
        notificationService: mockNotif,
        prefs: prefs,
      );

      verify(() => mockNotif.cancelAllNotifications()).called(1);
      verify(
        () => mockOrch.reconcile(reason: ReconcileReason.migration),
      ).called(1);
      expect(prefs.getBool(kNotificationMigrationV2Key), isTrue);
    });

    test('skips when flag already set', () async {
      final mockOrch = MockNotificationOrchestrator();
      final mockNotif = MockNotificationService();

      SharedPreferences.setMockInitialValues({
        kNotificationMigrationV2Key: true,
      });
      final prefs = await SharedPreferences.getInstance();

      await runNotificationMigrationV2(
        orchestrator: mockOrch,
        notificationService: mockNotif,
        prefs: prefs,
      );

      verifyNever(() => mockNotif.cancelAllNotifications());
      verifyNever(() => mockOrch.reconcile(reason: any(named: 'reason')));
    });

    test('does not set flag when reconcile reports failure', () async {
      final mockOrch = MockNotificationOrchestrator();
      final mockNotif = MockNotificationService();
      when(() => mockNotif.cancelAllNotifications()).thenAnswer((_) async {});
      when(
        () => mockOrch.reconcile(reason: any(named: 'reason')),
      ).thenAnswer((_) async => ReconcileResult.failed(StateError('boom')));

      final prefs = await SharedPreferences.getInstance();
      await runNotificationMigrationV2(
        orchestrator: mockOrch,
        notificationService: mockNotif,
        prefs: prefs,
      );

      expect(prefs.getBool(kNotificationMigrationV2Key) ?? false, isFalse);
    });

    test('does not set flag when cancelAll throws', () async {
      final mockOrch = MockNotificationOrchestrator();
      final mockNotif = MockNotificationService();
      when(
        () => mockNotif.cancelAllNotifications(),
      ).thenThrow(StateError('boom'));

      final prefs = await SharedPreferences.getInstance();
      await runNotificationMigrationV2(
        orchestrator: mockOrch,
        notificationService: mockNotif,
        prefs: prefs,
      );

      expect(prefs.getBool(kNotificationMigrationV2Key) ?? false, isFalse);
    });
  });
}
