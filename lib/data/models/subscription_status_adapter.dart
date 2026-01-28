import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/domain/entities/subscription_status.dart';

/// Hive TypeAdapter for [SubscriptionTier] enum.
class SubscriptionTierAdapter extends TypeAdapter<SubscriptionTier> {
  @override
  final int typeId = 12;

  @override
  SubscriptionTier read(BinaryReader reader) {
    final index = reader.readByte();
    return SubscriptionTier.values[index];
  }

  @override
  void write(BinaryWriter writer, SubscriptionTier obj) {
    writer.writeByte(obj.index);
  }
}

/// Hive TypeAdapter for [SubscriptionStatus] class.
///
/// Serializes all fields of the subscription status including tier,
/// expiration date, trial status, and product identifier.
class SubscriptionStatusAdapter extends TypeAdapter<SubscriptionStatus> {
  @override
  final int typeId = 13;

  @override
  SubscriptionStatus read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }

    return SubscriptionStatus(
      tier: fields[0] as SubscriptionTier? ?? SubscriptionTier.free,
      expirationDate: fields[1] as DateTime?,
      isTrialActive: fields[2] as bool? ?? false,
      willRenew: fields[3] as bool? ?? false,
      hasRemoveAds: fields[4] as bool? ?? false,
      productIdentifier: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SubscriptionStatus obj) {
    writer.writeByte(6); // Number of fields
    writer.writeByte(0);
    writer.write(obj.tier);
    writer.writeByte(1);
    writer.write(obj.expirationDate);
    writer.writeByte(2);
    writer.write(obj.isTrialActive);
    writer.writeByte(3);
    writer.write(obj.willRenew);
    writer.writeByte(4);
    writer.write(obj.hasRemoveAds);
    writer.writeByte(5);
    writer.write(obj.productIdentifier);
  }
}

/// Cached subscription status for offline support.
///
/// Wraps [SubscriptionStatus] with caching metadata including
/// timestamp and TTL for cache validity checking.
class CachedSubscriptionStatusModel extends HiveObject {
  CachedSubscriptionStatusModel({
    required this.status,
    required this.cachedAt,
    this.ttlMinutes = 60,
  });

  /// The cached subscription status.
  final SubscriptionStatus status;

  /// When this status was cached.
  final DateTime cachedAt;

  /// Time-to-live in minutes (default: 60 minutes).
  final int ttlMinutes;

  /// Checks if the cache is still valid.
  bool get isValid {
    final expiresAt = cachedAt.add(Duration(minutes: ttlMinutes));
    return DateTime.now().isBefore(expiresAt);
  }

  /// Checks if the cache has expired.
  bool get isExpired => !isValid;
}

/// Hive TypeAdapter for [CachedSubscriptionStatusModel].
class CachedSubscriptionStatusModelAdapter
    extends TypeAdapter<CachedSubscriptionStatusModel> {
  @override
  final int typeId = 14;

  @override
  CachedSubscriptionStatusModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }

    return CachedSubscriptionStatusModel(
      status: fields[0] as SubscriptionStatus? ?? const SubscriptionStatus.free(),
      cachedAt: fields[1] as DateTime? ?? DateTime.now(),
      ttlMinutes: fields[2] as int? ?? 60,
    );
  }

  @override
  void write(BinaryWriter writer, CachedSubscriptionStatusModel obj) {
    writer.writeByte(3); // Number of fields
    writer.writeByte(0);
    writer.write(obj.status);
    writer.writeByte(1);
    writer.write(obj.cachedAt);
    writer.writeByte(2);
    writer.write(obj.ttlMinutes);
  }
}
