import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/domain/entities/subscription_status.dart';

void main() {
  group('SubscriptionStatus', () {
    group('constructors', () {
      test('default constructor should create with provided values', () {
        final expirationDate = DateTime(2025, 12, 31);
        final status = SubscriptionStatus(
          tier: SubscriptionTier.premium,
          expirationDate: expirationDate,
          isTrialActive: true,
          willRenew: true,
          hasRemoveAds: true,
          productIdentifier: 'premium_monthly',
        );

        expect(status.tier, SubscriptionTier.premium);
        expect(status.expirationDate, expirationDate);
        expect(status.isTrialActive, isTrue);
        expect(status.willRenew, isTrue);
        expect(status.hasRemoveAds, isTrue);
        expect(status.productIdentifier, 'premium_monthly');
      });

      test('free() should create free tier status', () {
        const status = SubscriptionStatus.free();

        expect(status.tier, SubscriptionTier.free);
        expect(status.expirationDate, isNull);
        expect(status.isTrialActive, isFalse);
        expect(status.willRenew, isFalse);
        expect(status.hasRemoveAds, isFalse);
        expect(status.productIdentifier, isNull);
        expect(status.isPremium, isFalse);
      });

      test('premium() should create premium tier status', () {
        final expirationDate = DateTime(2025, 12, 31);
        final status = SubscriptionStatus.premium(
          expirationDate: expirationDate,
          isTrialActive: true,
          willRenew: true,
          productIdentifier: 'premium_annual',
        );

        expect(status.tier, SubscriptionTier.premium);
        expect(status.expirationDate, expirationDate);
        expect(status.isTrialActive, isTrue);
        expect(status.willRenew, isTrue);
        expect(status.hasRemoveAds, isTrue);
        expect(status.productIdentifier, 'premium_annual');
        expect(status.isPremium, isTrue);
      });

      test('removeAdsOnly() should create free tier with remove ads', () {
        const status = SubscriptionStatus.removeAdsOnly();

        expect(status.tier, SubscriptionTier.free);
        expect(status.expirationDate, isNull);
        expect(status.isTrialActive, isFalse);
        expect(status.willRenew, isFalse);
        expect(status.hasRemoveAds, isTrue);
        expect(status.productIdentifier, isNull);
        expect(status.isPremium, isFalse);
      });
    });

    group('isPremium', () {
      test('should return true for premium tier', () {
        final status = SubscriptionStatus.premium();

        expect(status.isPremium, isTrue);
      });

      test('should return false for free tier', () {
        const status = SubscriptionStatus.free();

        expect(status.isPremium, isFalse);
      });

      test('should return false for removeAdsOnly', () {
        const status = SubscriptionStatus.removeAdsOnly();

        expect(status.isPremium, isFalse);
      });
    });

    group('isActive', () {
      test('should return false for free tier', () {
        const status = SubscriptionStatus.free();

        expect(status.isActive, isFalse);
      });

      test('should return true for premium without expiration date', () {
        final status = SubscriptionStatus.premium();

        expect(status.isActive, isTrue);
      });

      test('should return true for premium with future expiration date', () {
        final futureDate = DateTime.now().add(const Duration(days: 30));
        final status = SubscriptionStatus.premium(expirationDate: futureDate);

        expect(status.isActive, isTrue);
      });

      test('should return false for premium with past expiration date', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        final status = SubscriptionStatus.premium(expirationDate: pastDate);

        expect(status.isActive, isFalse);
      });
    });

    group('copyWith', () {
      test('should create copy with updated tier', () {
        const original = SubscriptionStatus.free();
        final copy = original.copyWith(tier: SubscriptionTier.premium);

        expect(copy.tier, SubscriptionTier.premium);
        expect(copy.isTrialActive, original.isTrialActive);
        expect(copy.hasRemoveAds, original.hasRemoveAds);
      });

      test('should create copy with updated expiration date', () {
        final original = SubscriptionStatus.premium();
        final newDate = DateTime(2026, 1, 1);
        final copy = original.copyWith(expirationDate: newDate);

        expect(copy.expirationDate, newDate);
        expect(copy.tier, original.tier);
      });

      test('should clear expiration date when clearExpirationDate is true', () {
        final original = SubscriptionStatus.premium(
          expirationDate: DateTime(2025, 12, 31),
        );
        final copy = original.copyWith(clearExpirationDate: true);

        expect(copy.expirationDate, isNull);
        expect(copy.tier, original.tier);
      });

      test(
        'should clear product identifier when clearProductIdentifier is true',
        () {
          final original = SubscriptionStatus.premium(
            productIdentifier: 'test_product',
          );
          final copy = original.copyWith(clearProductIdentifier: true);

          expect(copy.productIdentifier, isNull);
          expect(copy.tier, original.tier);
        },
      );

      test('should update multiple fields at once', () {
        const original = SubscriptionStatus.free();
        final copy = original.copyWith(
          tier: SubscriptionTier.premium,
          isTrialActive: true,
          hasRemoveAds: true,
          willRenew: true,
        );

        expect(copy.tier, SubscriptionTier.premium);
        expect(copy.isTrialActive, isTrue);
        expect(copy.hasRemoveAds, isTrue);
        expect(copy.willRenew, isTrue);
      });
    });

    group('equality', () {
      test('should be equal for identical values', () {
        final status1 = SubscriptionStatus.premium(
          expirationDate: DateTime(2025, 12, 31),
          isTrialActive: true,
        );
        final status2 = SubscriptionStatus.premium(
          expirationDate: DateTime(2025, 12, 31),
          isTrialActive: true,
        );

        expect(status1, equals(status2));
        expect(status1.hashCode, equals(status2.hashCode));
      });

      test('should not be equal for different tiers', () {
        const status1 = SubscriptionStatus.free();
        final status2 = SubscriptionStatus.premium();

        expect(status1, isNot(equals(status2)));
      });

      test('should not be equal for different expiration dates', () {
        final status1 = SubscriptionStatus.premium(
          expirationDate: DateTime(2025, 12, 31),
        );
        final status2 = SubscriptionStatus.premium(
          expirationDate: DateTime(2026, 1, 1),
        );

        expect(status1, isNot(equals(status2)));
      });
    });
  });

  group('SubscriptionTier', () {
    test('should have correct values', () {
      expect(SubscriptionTier.values.length, 2);
      expect(SubscriptionTier.values.contains(SubscriptionTier.free), isTrue);
      expect(
        SubscriptionTier.values.contains(SubscriptionTier.premium),
        isTrue,
      );
    });
  });
}
