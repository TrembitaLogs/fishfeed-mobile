import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/services/ads/ad_service.dart';

void main() {
  group('AdService', () {
    group('singleton', () {
      test('should return the same instance', () {
        final instance1 = AdService.instance;
        final instance2 = AdService.instance;

        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('initial state', () {
      test('should not be initialized before calling initialize', () {
        final service = AdService.instance;

        // Service should not be initialized on first access
        expect(service.isInitialized, isFalse);
      });

      test('should have feeding counter at 0 initially', () {
        final service = AdService.instance;

        expect(service.feedingCounter, 0);
      });

      test('should have no interstitial ad ready initially', () {
        final service = AdService.instance;

        expect(service.isInterstitialAdReady, isFalse);
      });

      test('should have no rewarded ad ready initially', () {
        final service = AdService.instance;

        expect(service.isRewardedAdReady, isFalse);
      });
    });

    group('loadBannerAd', () {
      test('should return null when not initialized', () async {
        final service = AdService.instance;

        final result = await service.loadBannerAd(320);

        expect(result, isNull);
      });
    });

    group('showInterstitialAd', () {
      test('should return false when no ad is loaded', () async {
        final service = AdService.instance;

        final result = await service.showInterstitialAd();

        expect(result, isFalse);
      });
    });

    group('showRewardedAd', () {
      test('should return false when no ad is loaded', () async {
        final service = AdService.instance;
        var rewardCalled = false;

        final result = await service.showRewardedAd(
          onRewardEarned: (_) {
            rewardCalled = true;
          },
        );

        expect(result, isFalse);
        expect(rewardCalled, isFalse);
      });
    });

    group('onFeedingCompleted', () {
      test('should increment feeding counter', () async {
        final service = AdService.instance;
        final initialCount = service.feedingCounter;

        await service.onFeedingCompleted();

        expect(service.feedingCounter, initialCount + 1);
      });

      test('should reset counter after threshold and return false when no ad ready',
          () async {
        final service = AdService.instance;
        service.resetFeedingCounter();

        // Increment to threshold - 1
        for (var i = 0; i < AdService.feedingsBeforeInterstitial - 1; i++) {
          await service.onFeedingCompleted();
        }

        expect(service.feedingCounter, AdService.feedingsBeforeInterstitial - 1);

        // This should trigger the ad (but return false since no ad loaded)
        final result = await service.onFeedingCompleted();

        expect(result, isFalse); // No ad loaded
        expect(service.feedingCounter, 0); // Counter should be reset
      });
    });

    group('resetFeedingCounter', () {
      test('should reset counter to 0', () async {
        final service = AdService.instance;

        // First increment the counter
        await service.onFeedingCompleted();
        await service.onFeedingCompleted();
        expect(service.feedingCounter, greaterThan(0));

        // Then reset
        service.resetFeedingCounter();

        expect(service.feedingCounter, 0);
      });
    });

    group('currentState', () {
      test('should return AdState with all false values initially', () {
        final service = AdService.instance;

        final state = service.currentState;

        expect(state.isBannerLoaded, isFalse);
        expect(state.isInterstitialReady, isFalse);
        expect(state.isRewardedReady, isFalse);
      });
    });
  });

  group('AdState', () {
    test('should create with default false values', () {
      const state = AdState();

      expect(state.isBannerLoaded, isFalse);
      expect(state.isInterstitialReady, isFalse);
      expect(state.isRewardedReady, isFalse);
    });

    test('should create with specified values', () {
      const state = AdState(
        isBannerLoaded: true,
        isInterstitialReady: true,
        isRewardedReady: false,
      );

      expect(state.isBannerLoaded, isTrue);
      expect(state.isInterstitialReady, isTrue);
      expect(state.isRewardedReady, isFalse);
    });

    test('copyWith should create new instance with updated values', () {
      const original = AdState();
      final updated = original.copyWith(isBannerLoaded: true);

      expect(original.isBannerLoaded, isFalse);
      expect(updated.isBannerLoaded, isTrue);
      expect(updated.isInterstitialReady, isFalse);
      expect(updated.isRewardedReady, isFalse);
    });

    test('copyWith should preserve unchanged values', () {
      const original = AdState(
        isBannerLoaded: true,
        isInterstitialReady: true,
        isRewardedReady: true,
      );
      final updated = original.copyWith(isRewardedReady: false);

      expect(updated.isBannerLoaded, isTrue);
      expect(updated.isInterstitialReady, isTrue);
      expect(updated.isRewardedReady, isFalse);
    });

    test('equality should work correctly', () {
      const state1 = AdState(isBannerLoaded: true);
      const state2 = AdState(isBannerLoaded: true);
      const state3 = AdState(isBannerLoaded: false);

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('hashCode should be consistent with equality', () {
      const state1 = AdState(isBannerLoaded: true);
      const state2 = AdState(isBannerLoaded: true);

      expect(state1.hashCode, equals(state2.hashCode));
    });
  });

  group('TestAdUnitIds', () {
    test('should have iOS test ad unit IDs', () {
      expect(TestAdUnitIds.iosBanner, isNotEmpty);
      expect(TestAdUnitIds.iosInterstitial, isNotEmpty);
      expect(TestAdUnitIds.iosRewarded, isNotEmpty);
    });

    test('should have Android test ad unit IDs', () {
      expect(TestAdUnitIds.androidBanner, isNotEmpty);
      expect(TestAdUnitIds.androidInterstitial, isNotEmpty);
      expect(TestAdUnitIds.androidRewarded, isNotEmpty);
    });

    test('iOS test ad unit IDs should start with ca-app-pub-3940256099942544', () {
      expect(TestAdUnitIds.iosBanner.startsWith('ca-app-pub-3940256099942544'),
          isTrue);
      expect(TestAdUnitIds.iosInterstitial.startsWith('ca-app-pub-3940256099942544'),
          isTrue);
      expect(TestAdUnitIds.iosRewarded.startsWith('ca-app-pub-3940256099942544'),
          isTrue);
    });

    test('Android test ad unit IDs should start with ca-app-pub-3940256099942544',
        () {
      expect(TestAdUnitIds.androidBanner.startsWith('ca-app-pub-3940256099942544'),
          isTrue);
      expect(
          TestAdUnitIds.androidInterstitial
              .startsWith('ca-app-pub-3940256099942544'),
          isTrue);
      expect(TestAdUnitIds.androidRewarded.startsWith('ca-app-pub-3940256099942544'),
          isTrue);
    });
  });

  group('AdUnitIds', () {
    test('should have iOS production ad unit IDs defined', () {
      // These are placeholder IDs that need to be replaced
      expect(AdUnitIds.iosBanner, isNotEmpty);
      expect(AdUnitIds.iosInterstitial, isNotEmpty);
      expect(AdUnitIds.iosRewarded, isNotEmpty);
    });

    test('should have Android production ad unit IDs defined', () {
      // These are placeholder IDs that need to be replaced
      expect(AdUnitIds.androidBanner, isNotEmpty);
      expect(AdUnitIds.androidInterstitial, isNotEmpty);
      expect(AdUnitIds.androidRewarded, isNotEmpty);
    });
  });

  group('AdService constants', () {
    test('feedingsBeforeInterstitial should be 5', () {
      expect(AdService.feedingsBeforeInterstitial, 5);
    });
  });
}
