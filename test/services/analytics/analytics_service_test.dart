import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/services/analytics/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;

    setUp(() {
      analyticsService = AnalyticsService.instance;
    });

    group('trackPaywallShown', () {
      test('logs paywall shown event with correct parameters', () {
        // This test verifies the method doesn't throw
        expect(
          () => analyticsService.trackPaywallShown(
            source: PaywallSource.aiCameraCapture,
            scansRemaining: 0,
            isPremium: false,
          ),
          returnsNormally,
        );
      });

      test('handles premium user case', () {
        expect(
          () => analyticsService.trackPaywallShown(
            source: PaywallSource.aiCameraCapture,
            scansRemaining: -1,
            isPremium: true,
          ),
          returnsNormally,
        );
      });

      test('handles settings source', () {
        expect(
          () => analyticsService.trackPaywallShown(
            source: PaywallSource.settings,
            scansRemaining: 3,
            isPremium: false,
          ),
          returnsNormally,
        );
      });
    });

    group('trackPaywallDismissed', () {
      test('logs dismissed event', () {
        expect(
          () => analyticsService.trackPaywallDismissed(
            source: PaywallSource.aiCameraCapture,
          ),
          returnsNormally,
        );
      });

      test('handles settings source', () {
        expect(
          () => analyticsService.trackPaywallDismissed(
            source: PaywallSource.settings,
          ),
          returnsNormally,
        );
      });
    });

    group('trackAiScanStarted', () {
      test('logs scan start with scans remaining', () {
        expect(
          () => analyticsService.trackAiScanStarted(
            scansRemaining: 5,
            isPremium: false,
          ),
          returnsNormally,
        );
      });

      test('logs scan start for premium user', () {
        expect(
          () => analyticsService.trackAiScanStarted(
            scansRemaining: -1,
            isPremium: true,
          ),
          returnsNormally,
        );
      });
    });

    group('trackAiScanResult', () {
      test('logs successful scan with species and confidence', () {
        expect(
          () => analyticsService.trackAiScanResult(
            success: true,
            detectedSpeciesId: 'betta',
            confidence: 0.95,
          ),
          returnsNormally,
        );
      });

      test('handles low confidence scans', () {
        expect(
          () => analyticsService.trackAiScanResult(
            success: true,
            detectedSpeciesId: 'unknown',
            confidence: 0.35,
          ),
          returnsNormally,
        );
      });

      test('handles failed scans', () {
        expect(
          () => analyticsService.trackAiScanResult(
            success: false,
          ),
          returnsNormally,
        );
      });
    });

    group('trackAiScanFailed', () {
      test('logs scan failure with reason', () {
        expect(
          () => analyticsService.trackAiScanFailed(
            reason: 'Network timeout',
          ),
          returnsNormally,
        );
      });

      test('handles empty reason', () {
        expect(
          () => analyticsService.trackAiScanFailed(
            reason: '',
          ),
          returnsNormally,
        );
      });
    });

    group('trackSubscriptionStarted', () {
      test('logs subscription start with plan', () {
        expect(
          () => analyticsService.trackSubscriptionStarted(
            plan: 'annual',
            price: 29.99,
            currency: 'USD',
          ),
          returnsNormally,
        );
      });
    });

    group('trackMyAquariumOpened', () {
      test('logs my aquarium opened event', () {
        expect(
          () => analyticsService.trackMyAquariumOpened(),
          returnsNormally,
        );
      });
    });

    group('trackFishEdited', () {
      test('logs fish edited event with species and quantity', () {
        expect(
          () => analyticsService.trackFishEdited(
            speciesId: 'guppy',
            newQuantity: 5,
          ),
          returnsNormally,
        );
      });

      test('handles single quantity', () {
        expect(
          () => analyticsService.trackFishEdited(
            speciesId: 'betta',
            newQuantity: 1,
          ),
          returnsNormally,
        );
      });

      test('handles large quantity', () {
        expect(
          () => analyticsService.trackFishEdited(
            speciesId: 'neon_tetra',
            newQuantity: 100,
          ),
          returnsNormally,
        );
      });
    });

    group('trackFishDeleted', () {
      test('logs fish deleted event with species', () {
        expect(
          () => analyticsService.trackFishDeleted(
            speciesId: 'guppy',
          ),
          returnsNormally,
        );
      });

      test('handles different species', () {
        expect(
          () => analyticsService.trackFishDeleted(
            speciesId: 'goldfish',
          ),
          returnsNormally,
        );
      });
    });

    group('trackFeedMarked', () {
      test('logs fed status', () {
        expect(
          () => analyticsService.trackFeedMarked(
            eventId: 'feed_123',
            status: FeedStatus.fed,
          ),
          returnsNormally,
        );
      });

      test('logs missed status', () {
        expect(
          () => analyticsService.trackFeedMarked(
            eventId: 'feed_123',
            status: FeedStatus.missed,
          ),
          returnsNormally,
        );
      });

      test('logs first time flag', () {
        expect(
          () => analyticsService.trackFeedMarked(
            eventId: 'feed_123',
            status: FeedStatus.fed,
            isFirstTime: true,
          ),
          returnsNormally,
        );
      });
    });
  });

  group('analyticsServiceProvider', () {
    test('provides AnalyticsService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final analytics = container.read(analyticsServiceProvider);

      expect(analytics, isA<AnalyticsService>());
    });

    test('returns same instance when read multiple times', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final analytics1 = container.read(analyticsServiceProvider);
      final analytics2 = container.read(analyticsServiceProvider);

      expect(analytics1, same(analytics2));
    });
  });

  group('AnalyticsEvents constants', () {
    test('contains paywall events', () {
      expect(AnalyticsEvents.paywallShown, equals('paywall_shown'));
      expect(AnalyticsEvents.paywallDismissed, equals('paywall_dismissed'));
    });

    test('contains AI scan events', () {
      expect(AnalyticsEvents.aiScanStarted, equals('ai_scan_started'));
      expect(AnalyticsEvents.aiScanResult, equals('ai_scan_result'));
      expect(AnalyticsEvents.aiScanFailed, equals('ai_scan_failed'));
    });

    test('contains onboarding events', () {
      expect(AnalyticsEvents.onboardingStart, equals('onboarding_start'));
      expect(AnalyticsEvents.fishAdded, equals('fish_added'));
      expect(AnalyticsEvents.scheduleGenerated, equals('schedule_generated'));
    });

    test('contains feed events', () {
      expect(AnalyticsEvents.feedMarked, equals('feed_marked'));
      expect(AnalyticsEvents.feedEventShown, equals('feed_event_shown'));
      expect(AnalyticsEvents.feedUndo, equals('feed_undo'));
    });

    test('contains streak events', () {
      expect(AnalyticsEvents.streakStarted, equals('streak_started'));
      expect(AnalyticsEvents.streakIncremented, equals('streak_incremented'));
      expect(AnalyticsEvents.streakBroken, equals('streak_broken'));
    });

    test('contains fish management events', () {
      expect(AnalyticsEvents.myAquariumOpened, equals('my_aquarium_opened'));
      expect(AnalyticsEvents.fishEdited, equals('fish_edited'));
      expect(AnalyticsEvents.fishDeleted, equals('fish_deleted'));
    });
  });

  group('AnalyticsParams constants', () {
    test('contains all expected parameters', () {
      expect(AnalyticsParams.source, equals('source'));
      expect(AnalyticsParams.action, equals('action'));
      expect(AnalyticsParams.scansRemaining, equals('scans_remaining'));
      expect(AnalyticsParams.isPremium, equals('is_premium'));
      expect(AnalyticsParams.reason, equals('reason'));
      expect(AnalyticsParams.speciesId, equals('species_id'));
      expect(AnalyticsParams.confidence, equals('confidence'));
    });

    test('contains fish management parameters', () {
      expect(AnalyticsParams.newQuantity, equals('new_quantity'));
    });
  });

  group('PaywallSource enum', () {
    test('has all expected values', () {
      expect(PaywallSource.values, contains(PaywallSource.aiCameraCapture));
      expect(PaywallSource.values, contains(PaywallSource.settings));
      expect(PaywallSource.values, contains(PaywallSource.aiCameraLimit));
      expect(PaywallSource.values, contains(PaywallSource.premiumFeature));
      expect(PaywallSource.values, contains(PaywallSource.familyLimit));
      expect(PaywallSource.values, contains(PaywallSource.adsRemoval));
    });
  });

  group('FeedStatus enum', () {
    test('has all expected values', () {
      expect(FeedStatus.values, contains(FeedStatus.fed));
      expect(FeedStatus.values, contains(FeedStatus.missed));
      expect(FeedStatus.values, contains(FeedStatus.skipped));
    });
  });

  group('AdType enum', () {
    test('has all expected values', () {
      expect(AdType.values, contains(AdType.banner));
      expect(AdType.values, contains(AdType.interstitial));
      expect(AdType.values, contains(AdType.rewarded));
    });
  });
}
