import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/core/utils/premium_gate.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';

void main() {
  group('PremiumFeature', () {
    test('has all expected values', () {
      expect(PremiumFeature.values, contains(PremiumFeature.noAds));
      expect(PremiumFeature.values, contains(PremiumFeature.unlimitedAiScans));
      expect(
        PremiumFeature.values,
        contains(PremiumFeature.extendedStatistics),
      );
      expect(PremiumFeature.values, contains(PremiumFeature.familyMode));
      expect(PremiumFeature.values, contains(PremiumFeature.multipleAquariums));
      expect(PremiumFeature.values.length, equals(5));
    });

    group('displayName', () {
      test('noAds has correct display name', () {
        expect(PremiumFeature.noAds.displayName, equals('No Ads'));
      });

      test('unlimitedAiScans has correct display name', () {
        expect(
          PremiumFeature.unlimitedAiScans.displayName,
          equals('Unlimited AI Scans'),
        );
      });

      test('extendedStatistics has correct display name', () {
        expect(
          PremiumFeature.extendedStatistics.displayName,
          equals('Extended Statistics'),
        );
      });

      test('familyMode has correct display name', () {
        expect(PremiumFeature.familyMode.displayName, equals('Family Mode'));
      });

      test('multipleAquariums has correct display name', () {
        expect(
          PremiumFeature.multipleAquariums.displayName,
          equals('Multiple Aquariums'),
        );
      });
    });

    group('description', () {
      test('noAds has correct description', () {
        expect(
          PremiumFeature.noAds.description,
          equals('Enjoy an ad-free experience'),
        );
      });

      test('unlimitedAiScans has correct description', () {
        expect(
          PremiumFeature.unlimitedAiScans.description,
          equals('Scan as many fish as you want'),
        );
      });

      test('extendedStatistics has correct description', () {
        expect(
          PremiumFeature.extendedStatistics.description,
          equals('View 6 months of feeding history'),
        );
      });

      test('familyMode has correct description', () {
        expect(
          PremiumFeature.familyMode.description,
          equals('Share with up to 5 family members'),
        );
      });

      test('multipleAquariums has correct description', () {
        expect(
          PremiumFeature.multipleAquariums.description,
          equals('Manage multiple aquariums'),
        );
      });
    });
  });

  group('requiresPremium', () {
    test('returns true for all premium features', () {
      for (final feature in PremiumFeature.values) {
        expect(requiresPremium(feature), isTrue);
      }
    });
  });

  group('featureAccessProvider', () {
    test('free user has no access to premium features', () {
      final container = ProviderContainer(
        overrides: [
          isPremiumProvider.overrideWith((ref) => false),
          hasRemoveAdsProvider.overrideWith((ref) => false),
        ],
      );
      addTearDown(container.dispose);

      for (final feature in PremiumFeature.values) {
        expect(
          container.read(featureAccessProvider(feature)),
          isFalse,
          reason: '${feature.name} should be locked for free users',
        );
      }
    });

    test('premium user has access to all features', () {
      final container = ProviderContainer(
        overrides: [
          isPremiumProvider.overrideWith((ref) => true),
          hasRemoveAdsProvider.overrideWith((ref) => true),
        ],
      );
      addTearDown(container.dispose);

      for (final feature in PremiumFeature.values) {
        expect(
          container.read(featureAccessProvider(feature)),
          isTrue,
          reason: '${feature.name} should be unlocked for premium users',
        );
      }
    });

    test('remove ads user only has access to noAds feature', () {
      final container = ProviderContainer(
        overrides: [
          isPremiumProvider.overrideWith((ref) => false),
          hasRemoveAdsProvider.overrideWith((ref) => true),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(featureAccessProvider(PremiumFeature.noAds)),
        isTrue,
      );
      expect(
        container.read(featureAccessProvider(PremiumFeature.unlimitedAiScans)),
        isFalse,
      );
      expect(
        container.read(
          featureAccessProvider(PremiumFeature.extendedStatistics),
        ),
        isFalse,
      );
      expect(
        container.read(featureAccessProvider(PremiumFeature.familyMode)),
        isFalse,
      );
      expect(
        container.read(featureAccessProvider(PremiumFeature.multipleAquariums)),
        isFalse,
      );
    });
  });

  group('accessibleFeaturesProvider', () {
    test('returns empty set for free user', () {
      final container = ProviderContainer(
        overrides: [
          isPremiumProvider.overrideWith((ref) => false),
          hasRemoveAdsProvider.overrideWith((ref) => false),
        ],
      );
      addTearDown(container.dispose);

      final accessibleFeatures = container.read(accessibleFeaturesProvider);
      expect(accessibleFeatures, isEmpty);
    });

    test('returns all features for premium user', () {
      final container = ProviderContainer(
        overrides: [
          isPremiumProvider.overrideWith((ref) => true),
          hasRemoveAdsProvider.overrideWith((ref) => true),
        ],
      );
      addTearDown(container.dispose);

      final accessibleFeatures = container.read(accessibleFeaturesProvider);
      expect(accessibleFeatures, containsAll(PremiumFeature.values));
    });

    test('returns only noAds for remove ads user', () {
      final container = ProviderContainer(
        overrides: [
          isPremiumProvider.overrideWith((ref) => false),
          hasRemoveAdsProvider.overrideWith((ref) => true),
        ],
      );
      addTearDown(container.dispose);

      final accessibleFeatures = container.read(accessibleFeaturesProvider);
      expect(accessibleFeatures, equals({PremiumFeature.noAds}));
    });
  });

  group('lockedFeaturesProvider', () {
    test('returns all features for free user', () {
      final container = ProviderContainer(
        overrides: [
          isPremiumProvider.overrideWith((ref) => false),
          hasRemoveAdsProvider.overrideWith((ref) => false),
        ],
      );
      addTearDown(container.dispose);

      final lockedFeatures = container.read(lockedFeaturesProvider);
      expect(lockedFeatures, containsAll(PremiumFeature.values));
    });

    test('returns empty set for premium user', () {
      final container = ProviderContainer(
        overrides: [
          isPremiumProvider.overrideWith((ref) => true),
          hasRemoveAdsProvider.overrideWith((ref) => true),
        ],
      );
      addTearDown(container.dispose);

      final lockedFeatures = container.read(lockedFeaturesProvider);
      expect(lockedFeatures, isEmpty);
    });

    test('returns all except noAds for remove ads user', () {
      final container = ProviderContainer(
        overrides: [
          isPremiumProvider.overrideWith((ref) => false),
          hasRemoveAdsProvider.overrideWith((ref) => true),
        ],
      );
      addTearDown(container.dispose);

      final lockedFeatures = container.read(lockedFeaturesProvider);
      expect(lockedFeatures, isNot(contains(PremiumFeature.noAds)));
      expect(lockedFeatures, contains(PremiumFeature.unlimitedAiScans));
      expect(lockedFeatures, contains(PremiumFeature.extendedStatistics));
      expect(lockedFeatures, contains(PremiumFeature.familyMode));
      expect(lockedFeatures, contains(PremiumFeature.multipleAquariums));
    });
  });
}
