import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fishfeed/services/notifications/notification_permission_service.dart';

/// Sets up a mock MethodChannel handler for permission_handler that returns
/// [permissionStatus] (an integer matching PermissionStatus) for all calls.
///
/// permission_handler int values: granted=1, denied=0, permanentlyDenied=2,
/// restricted=3, provisional=4, limited=5.
void _setPermissionHandlerMock(int permissionStatus) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'checkPermissionStatus') {
            return permissionStatus;
          }
          return null;
        },
      );
}

void _clearPermissionHandlerMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        null,
      );
}

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

    group('refreshFromOs', () {
      setUp(() {
        // Mock permission_handler to return "denied" (0) consistently.
        _setPermissionHandlerMock(0);
      });

      tearDown(() {
        _clearPermissionHandlerMock();
      });

      test('refreshFromOs is idempotent across consecutive calls', () async {
        // First call primes the cache with whatever the mocked OS reports.
        await service.refreshFromOs();
        // Second call: cache already matches OS → must report no change.
        final second = await service.refreshFromOs();
        expect(second, isFalse, reason: 'cache matches OS after first call');
      });

      test(
        'refreshFromOs returns false when cache is null (first call)',
        () async {
          // Prime to null by setting a known non-null status then checking that
          // consecutive calls are stable regardless of cache start value.
          // After first call the cache is set; the second call must return false.
          final first = await service.refreshFromOs();
          // First call either sets the cache (returns false) or detects change
          // from a prior primed value. Either way the second call must be false.
          expect(first, isFalse);
        },
      );

      test(
        'detects change when primed status differs from OS-reported status',
        () async {
          // Mock reports "denied" (0 → NotificationPermissionStatus.denied).
          // Prime cache to "granted" — differs from what mock returns.
          service.primeLastKnownStatusForTesting(
            NotificationPermissionStatus.granted,
          );
          final changed = await service.refreshFromOs();
          // OS (mock) returns denied; cache was granted → change detected.
          expect(changed, isTrue, reason: 'granted→denied is a change');
        },
      );

      test('no change when primed status matches OS-reported status', () async {
        // Mock reports "denied" (0 → denied). Prime cache to same.
        service.primeLastKnownStatusForTesting(
          NotificationPermissionStatus.denied,
        );
        final changed = await service.refreshFromOs();
        expect(changed, isFalse, reason: 'denied→denied is not a change');
      });

      test('updates cache to OS value after refresh', () async {
        // Prime to granted; after refresh cache should equal denied (mock value).
        service.primeLastKnownStatusForTesting(
          NotificationPermissionStatus.granted,
        );
        await service.refreshFromOs(); // cache updated to denied
        // Second call: both cache and OS are denied → no change.
        final second = await service.refreshFromOs();
        expect(second, isFalse, reason: 'cache was updated by prior refresh');
      });
    });
  });
}
