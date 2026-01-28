import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fishfeed/services/notifications/notification_permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationPermissionStatus', () {
    test('should have all expected values', () {
      expect(NotificationPermissionStatus.values, hasLength(5));
      expect(NotificationPermissionStatus.granted, isNotNull);
      expect(NotificationPermissionStatus.notDetermined, isNotNull);
      expect(NotificationPermissionStatus.denied, isNotNull);
      expect(NotificationPermissionStatus.permanentlyDenied, isNotNull);
      expect(NotificationPermissionStatus.restricted, isNotNull);
    });
  });

  group('NotificationPermissionService', () {
    late NotificationPermissionService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = NotificationPermissionService.instance;
    });

    tearDown(() async {
      await service.resetAllState();
    });

    group('singleton', () {
      test('should return same instance', () {
        final instance1 = NotificationPermissionService.instance;
        final instance2 = NotificationPermissionService.instance;

        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('permission declined storage', () {
      test('hasUserDeclinedPermission returns false initially', () async {
        final result = await service.hasUserDeclinedPermission();
        expect(result, isFalse);
      });

      test('recordPermissionDeclined stores declined status', () async {
        await service.recordPermissionDeclined();

        final result = await service.hasUserDeclinedPermission();
        expect(result, isTrue);
      });

      test('clearPermissionDeclined clears declined status', () async {
        await service.recordPermissionDeclined();
        await service.clearPermissionDeclined();

        final result = await service.hasUserDeclinedPermission();
        expect(result, isFalse);
      });

      test('getDeclineCount returns 0 initially', () async {
        final count = await service.getDeclineCount();
        expect(count, equals(0));
      });

      test('getDeclineCount increments on each decline', () async {
        await service.recordPermissionDeclined();
        expect(await service.getDeclineCount(), equals(1));

        await service.recordPermissionDeclined();
        expect(await service.getDeclineCount(), equals(2));

        await service.recordPermissionDeclined();
        expect(await service.getDeclineCount(), equals(3));
      });

      test('clearPermissionDeclined does not reset decline count', () async {
        await service.recordPermissionDeclined();
        await service.recordPermissionDeclined();
        await service.clearPermissionDeclined();

        // Count should be preserved for analytics
        final count = await service.getDeclineCount();
        expect(count, equals(2));
      });

      test('getLastDeclinedAt returns null initially', () async {
        final timestamp = await service.getLastDeclinedAt();
        expect(timestamp, isNull);
      });

      test('getLastDeclinedAt returns timestamp after decline', () async {
        final beforeDecline = DateTime.now();
        await service.recordPermissionDeclined();
        final afterDecline = DateTime.now();

        final timestamp = await service.getLastDeclinedAt();

        expect(timestamp, isNotNull);
        expect(
          timestamp!.isAfter(
            beforeDecline.subtract(const Duration(seconds: 1)),
          ),
          isTrue,
        );
        expect(
          timestamp.isBefore(afterDecline.add(const Duration(seconds: 1))),
          isTrue,
        );
      });
    });

    group('canShowPermissionDialog', () {
      test('returns true when never declined', () async {
        final canShow = await service.canShowPermissionDialog();
        expect(canShow, isTrue);
      });

      test('returns false immediately after decline', () async {
        await service.recordPermissionDeclined();

        final canShow = await service.canShowPermissionDialog(
          minDaysBetweenPrompts: 7,
        );
        expect(canShow, isFalse);
      });

      test('uses provided minDaysBetweenPrompts', () async {
        await service.recordPermissionDeclined();

        // With 0 days, should allow showing immediately
        final canShow = await service.canShowPermissionDialog(
          minDaysBetweenPrompts: 0,
        );
        expect(canShow, isTrue);
      });
    });

    group('resetAllState', () {
      test('clears all stored state', () async {
        await service.recordPermissionDeclined();
        await service.recordPermissionDeclined();
        await service.resetAllState();

        expect(await service.hasUserDeclinedPermission(), isFalse);
        expect(await service.getDeclineCount(), equals(0));
        expect(await service.getLastDeclinedAt(), isNull);
      });
    });
  });
}
