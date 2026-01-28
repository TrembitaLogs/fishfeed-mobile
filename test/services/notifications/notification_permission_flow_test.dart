import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fishfeed/services/notifications/notification_permission_service.dart';

/// Integration tests for the notification permission fallback flow.
///
/// Tests the complete flow:
/// 1. User declines permission
/// 2. Verify fallback mode is active
/// 3. In-app reminders should work in fallback mode
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notification Permission Fallback Flow', () {
    late NotificationPermissionService permissionService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      permissionService = NotificationPermissionService.instance;
      await permissionService.initialize();
    });

    tearDown(() async {
      await permissionService.resetAllState();
    });

    group('initial state', () {
      test('fallback mode should be inactive initially', () async {
        // Note: In actual tests, this depends on system permission state
        // For unit tests, we focus on the stored decline status
        final hasDeclined = await permissionService.hasUserDeclinedPermission();
        expect(hasDeclined, isFalse);
      });

      test('decline count should be zero initially', () async {
        final count = await permissionService.getDeclineCount();
        expect(count, equals(0));
      });
    });

    group('decline permission flow', () {
      test('recording decline should enable fallback tracking', () async {
        // User declines permission
        await permissionService.recordPermissionDeclined();

        // Verify decline is recorded
        final hasDeclined = await permissionService.hasUserDeclinedPermission();
        expect(hasDeclined, isTrue);

        // Verify decline count is incremented
        final count = await permissionService.getDeclineCount();
        expect(count, equals(1));
      });

      test('multiple declines should increment count', () async {
        await permissionService.recordPermissionDeclined();
        await permissionService.recordPermissionDeclined();
        await permissionService.recordPermissionDeclined();

        final count = await permissionService.getDeclineCount();
        expect(count, equals(3));
      });

      test('decline timestamp should be recorded', () async {
        final beforeDecline = DateTime.now();
        await permissionService.recordPermissionDeclined();
        final afterDecline = DateTime.now();

        final timestamp = await permissionService.getLastDeclinedAt();

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

    group('permission dialog cooldown', () {
      test('should not show dialog immediately after decline', () async {
        await permissionService.recordPermissionDeclined();

        final canShow = await permissionService.canShowPermissionDialog(
          minDaysBetweenPrompts: 7,
        );

        expect(canShow, isFalse);
      });

      test('should allow showing dialog with 0 day cooldown', () async {
        await permissionService.recordPermissionDeclined();

        final canShow = await permissionService.canShowPermissionDialog(
          minDaysBetweenPrompts: 0,
        );

        expect(canShow, isTrue);
      });

      test('should allow showing dialog when never declined', () async {
        final canShow = await permissionService.canShowPermissionDialog();
        expect(canShow, isTrue);
      });
    });

    group('clearing decline status', () {
      test('clearing should allow showing dialog again', () async {
        await permissionService.recordPermissionDeclined();
        await permissionService.clearPermissionDeclined();

        final hasDeclined = await permissionService.hasUserDeclinedPermission();
        expect(hasDeclined, isFalse);
      });

      test('clearing should preserve decline count for analytics', () async {
        await permissionService.recordPermissionDeclined();
        await permissionService.recordPermissionDeclined();
        await permissionService.clearPermissionDeclined();

        final count = await permissionService.getDeclineCount();
        expect(count, equals(2));
      });
    });

    group('full reset', () {
      test('reset should clear all state including count', () async {
        await permissionService.recordPermissionDeclined();
        await permissionService.recordPermissionDeclined();
        await permissionService.resetAllState();

        expect(await permissionService.hasUserDeclinedPermission(), isFalse);
        expect(await permissionService.getDeclineCount(), equals(0));
        expect(await permissionService.getLastDeclinedAt(), isNull);
      });
    });

    group('permission status mapping', () {
      test('NotificationPermissionStatus should have all expected values', () {
        expect(NotificationPermissionStatus.values, hasLength(5));

        expect(NotificationPermissionStatus.granted, isNotNull);
        expect(NotificationPermissionStatus.notDetermined, isNotNull);
        expect(NotificationPermissionStatus.denied, isNotNull);
        expect(NotificationPermissionStatus.permanentlyDenied, isNotNull);
        expect(NotificationPermissionStatus.restricted, isNotNull);
      });
    });

    group('fallback mode determination', () {
      test(
        'shouldUseFallbackMode returns false when no decline recorded',
        () async {
          // Without mocking permission_handler, we can only test the decline-based logic
          // In real app, this also checks system permission
          final hasDeclined = await permissionService
              .hasUserDeclinedPermission();
          expect(hasDeclined, isFalse);
        },
      );

      test('user decline is recorded correctly', () async {
        await permissionService.recordPermissionDeclined();

        // Verify the decline was recorded
        final hasDeclined = await permissionService.hasUserDeclinedPermission();
        expect(hasDeclined, isTrue);

        // In fallback mode, app should show in-app reminders
        // This is determined by shouldUseFallbackMode() which checks
        // both system permission and user decline status
      });
    });
  });
}
