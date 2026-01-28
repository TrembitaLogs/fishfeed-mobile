import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/data/models/subscription_status_adapter.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';

void main() {
  group('SubscriptionTierAdapter', () {
    late SubscriptionTierAdapter adapter;

    setUp(() {
      adapter = SubscriptionTierAdapter();
    });

    test('should have correct typeId', () {
      expect(adapter.typeId, 12);
    });
  });

  group('SubscriptionStatusAdapter', () {
    late SubscriptionStatusAdapter adapter;

    setUp(() {
      adapter = SubscriptionStatusAdapter();
    });

    test('should have correct typeId', () {
      expect(adapter.typeId, 13);
    });
  });

  group('CachedSubscriptionStatusModel', () {
    test('should calculate isValid correctly for fresh cache', () {
      final cached = CachedSubscriptionStatusModel(
        status: const SubscriptionStatus.free(),
        cachedAt: DateTime.now(),
        ttlMinutes: 60,
      );

      expect(cached.isValid, isTrue);
      expect(cached.isExpired, isFalse);
    });

    test('should calculate isValid correctly for expired cache', () {
      final cached = CachedSubscriptionStatusModel(
        status: const SubscriptionStatus.free(),
        cachedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ttlMinutes: 60,
      );

      expect(cached.isValid, isFalse);
      expect(cached.isExpired, isTrue);
    });

    test('should use default TTL of 60 minutes', () {
      final cached = CachedSubscriptionStatusModel(
        status: const SubscriptionStatus.free(),
        cachedAt: DateTime.now(),
      );

      expect(cached.ttlMinutes, 60);
    });

    test('should preserve subscription status', () {
      final status = SubscriptionStatus.premium(
        expirationDate: DateTime(2025, 12, 31),
        isTrialActive: true,
      );

      final cached = CachedSubscriptionStatusModel(
        status: status,
        cachedAt: DateTime.now(),
      );

      expect(cached.status.tier, SubscriptionTier.premium);
      expect(cached.status.isTrialActive, isTrue);
      expect(cached.status.expirationDate, DateTime(2025, 12, 31));
    });

    test('should calculate isValid for edge case at TTL boundary', () {
      // Cache that is exactly at TTL boundary
      final cached = CachedSubscriptionStatusModel(
        status: const SubscriptionStatus.free(),
        cachedAt: DateTime.now().subtract(const Duration(minutes: 60)),
        ttlMinutes: 60,
      );

      // At exactly 60 minutes, it should be expired
      expect(cached.isExpired, isTrue);
    });

    test('should be valid just before TTL expires', () {
      final cached = CachedSubscriptionStatusModel(
        status: const SubscriptionStatus.free(),
        cachedAt: DateTime.now().subtract(const Duration(minutes: 59)),
        ttlMinutes: 60,
      );

      expect(cached.isValid, isTrue);
    });
  });

  group('CachedSubscriptionStatusModelAdapter', () {
    late CachedSubscriptionStatusModelAdapter adapter;

    setUp(() {
      adapter = CachedSubscriptionStatusModelAdapter();
    });

    test('should have correct typeId', () {
      expect(adapter.typeId, 14);
    });
  });
}
