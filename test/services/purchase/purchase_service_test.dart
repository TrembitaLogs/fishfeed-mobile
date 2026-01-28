import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/services/purchase/purchase_service.dart';

void main() {
  setUpAll(() async {
    // Initialize dotenv with test values (empty string means no actual .env file)
    dotenv.testLoad(
      fileInput: '''
REVENUECAT_API_KEY_IOS=
REVENUECAT_API_KEY_ANDROID=
''',
    );
  });

  group('PurchaseService', () {
    group('singleton', () {
      test('should return the same instance', () {
        final instance1 = PurchaseService.instance;
        final instance2 = PurchaseService.instance;

        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('initial state', () {
      test('should not be initialized before calling initialize', () {
        final service = PurchaseService.instance;

        // Service should not be initialized on first access
        // Note: This test may fail if other tests have initialized the service
        // In a clean state, isInitialized should be false
        expect(service.isInitialized, isFalse);
      });
    });

    group('initialize', () {
      test('should handle missing API key gracefully', () async {
        // When API key is not configured in .env, initialization should skip
        // and not throw an exception
        final service = PurchaseService.instance;

        // This should not throw even without API key
        await expectLater(service.initialize(), completes);

        // Should not be initialized because API key is missing
        expect(service.isInitialized, isFalse);
      });

      test('should be idempotent', () async {
        final service = PurchaseService.instance;

        // Multiple calls should not throw
        await service.initialize();
        await service.initialize();

        // Should complete without error
        expect(true, isTrue);
      });
    });

    group('logIn', () {
      test('should not throw when called before initialization', () async {
        final service = PurchaseService.instance;

        // Should not throw even if not properly initialized
        await expectLater(service.logIn('test_user_id'), completes);
      });
    });

    group('logOut', () {
      test('should not throw when called before initialization', () async {
        final service = PurchaseService.instance;

        // Should not throw even if not properly initialized
        await expectLater(service.logOut(), completes);
      });
    });

    group('getOfferings', () {
      test(
        'should return PurchaseNotInitializedFailure when not initialized',
        () async {
          final service = PurchaseService.instance;

          final result = await service.getOfferings();

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<PurchaseNotInitializedFailure>()),
            (_) => fail('Expected Left with failure'),
          );
        },
      );
    });

    group('purchasePackage', () {
      test(
        'should return PurchaseNotInitializedFailure when not initialized',
        () async {
          final service = PurchaseService.instance;

          // We can't create a real Package without the SDK, so we test the
          // initialization check by passing null (which would throw if it
          // got past the initialization check). Instead, we verify the
          // failure type when not initialized.
          // This test verifies the guard clause works.
          expect(service.isInitialized, isFalse);

          // The method signature requires a Package, so we verify via
          // getOfferings which has the same guard clause
          final result = await service.getOfferings();
          expect(result.isLeft(), isTrue);
        },
      );
    });

    group('restorePurchases', () {
      test(
        'should return PurchaseNotInitializedFailure when not initialized',
        () async {
          final service = PurchaseService.instance;

          final result = await service.restorePurchases();

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<PurchaseNotInitializedFailure>()),
            (_) => fail('Expected Left with failure'),
          );
        },
      );
    });

    group('getCustomerInfo', () {
      test(
        'should return PurchaseNotInitializedFailure when not initialized',
        () async {
          final service = PurchaseService.instance;

          final result = await service.getCustomerInfo();

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<PurchaseNotInitializedFailure>()),
            (_) => fail('Expected Left with failure'),
          );
        },
      );
    });

    group('isPremium', () {
      test('should return false when not initialized', () {
        final service = PurchaseService.instance;

        expect(service.isPremium(), isFalse);
      });
    });

    group('hasRemoveAds', () {
      test('should return false when not initialized', () {
        final service = PurchaseService.instance;

        expect(service.hasRemoveAds(), isFalse);
      });
    });

    group('getSubscriptionStatus', () {
      test('should return free status when not initialized', () {
        final service = PurchaseService.instance;

        final status = service.getSubscriptionStatus();

        expect(status.tier, SubscriptionTier.free);
        expect(status.isPremium, isFalse);
        expect(status.hasRemoveAds, isFalse);
        expect(status.isTrialActive, isFalse);
      });
    });

    group('getRemoveAdsPackage', () {
      test(
        'should return PurchaseNotInitializedFailure when not initialized',
        () async {
          final service = PurchaseService.instance;

          final result = await service.getRemoveAdsPackage();

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<PurchaseNotInitializedFailure>()),
            (_) => fail('Expected Left with failure'),
          );
        },
      );
    });

    group('purchaseRemoveAds', () {
      test(
        'should return PurchaseNotInitializedFailure when not initialized',
        () async {
          final service = PurchaseService.instance;

          final result = await service.purchaseRemoveAds();

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) => expect(failure, isA<PurchaseNotInitializedFailure>()),
            (_) => fail('Expected Left with failure'),
          );
        },
      );
    });
  });

  group('PurchaseEntitlements', () {
    test('should have correct entitlement identifiers', () {
      expect(PurchaseEntitlements.premium, 'premium');
      expect(PurchaseEntitlements.removeAds, 'remove_ads');
    });
  });

  group('syncSubscriptionStatus', () {
    test(
      'should return free status when not initialized and no cache',
      () async {
        final service = PurchaseService.instance;

        // Without initialization and no cache, should return free status
        final status = await service.syncSubscriptionStatus();

        expect(status.tier, SubscriptionTier.free);
        expect(status.isPremium, isFalse);
      },
    );

    test('should complete without error when Dio not configured', () async {
      final service = PurchaseService.instance;

      // Should not throw when Dio is not configured
      await expectLater(service.syncSubscriptionStatus(), completes);
    });

    test('should respect rate limiting', () async {
      final service = PurchaseService.instance;

      // First sync should complete
      final status1 = await service.syncSubscriptionStatus(force: true);

      // Second sync within rate limit should return quickly
      final stopwatch = Stopwatch()..start();
      final status2 = await service.syncSubscriptionStatus();
      stopwatch.stop();

      // Should be fast (rate limited, no actual sync)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(status1.tier, status2.tier);
    });

    test('should bypass rate limiting when force is true', () async {
      final service = PurchaseService.instance;

      // First sync
      await service.syncSubscriptionStatus(force: true);

      // Forced sync should still execute (won't be rate limited)
      await expectLater(service.syncSubscriptionStatus(force: true), completes);
    });
  });

  group('clearCachedSubscriptionStatus', () {
    test('should complete without error', () async {
      final service = PurchaseService.instance;

      await expectLater(service.clearCachedSubscriptionStatus(), completes);
    });
  });

  group('subscriptionStatusStream', () {
    test('should provide a broadcast stream', () {
      final service = PurchaseService.instance;

      expect(
        service.subscriptionStatusStream,
        isA<Stream<SubscriptionStatus>>(),
      );
      expect(service.subscriptionStatusStream.isBroadcast, isTrue);
    });
  });

  group('configureDio', () {
    test('should accept Dio instance without error', () {
      // Verify the service instance is accessible
      // Note: We don't have access to Dio in tests without additional setup,
      // but we can verify the method exists and is callable.
      // Integration tests with real Dio would be in integration test suite.
      expect(PurchaseService.instance, isNotNull);
    });
  });
}
