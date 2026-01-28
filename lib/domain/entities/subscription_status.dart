import 'package:equatable/equatable.dart';

/// Subscription tier levels.
enum SubscriptionTier {
  /// Free tier with limited features.
  free,

  /// Premium tier with full access.
  premium,
}

/// Detailed subscription status for user accounts.
///
/// Contains information about the user's current subscription,
/// including tier, expiration, and trial status.
class SubscriptionStatus extends Equatable {
  const SubscriptionStatus({
    this.tier = SubscriptionTier.free,
    this.expirationDate,
    this.isTrialActive = false,
    this.willRenew = false,
    this.hasRemoveAds = false,
    this.productIdentifier,
  });

  /// Creates a free tier subscription status.
  const SubscriptionStatus.free()
    : tier = SubscriptionTier.free,
      expirationDate = null,
      isTrialActive = false,
      willRenew = false,
      hasRemoveAds = false,
      productIdentifier = null;

  /// Creates a premium subscription status.
  factory SubscriptionStatus.premium({
    DateTime? expirationDate,
    bool isTrialActive = false,
    bool willRenew = true,
    String? productIdentifier,
  }) {
    return SubscriptionStatus(
      tier: SubscriptionTier.premium,
      expirationDate: expirationDate,
      isTrialActive: isTrialActive,
      willRenew: willRenew,
      hasRemoveAds: true,
      productIdentifier: productIdentifier,
    );
  }

  /// Creates a status with only remove ads purchased.
  const SubscriptionStatus.removeAdsOnly()
    : tier = SubscriptionTier.free,
      expirationDate = null,
      isTrialActive = false,
      willRenew = false,
      hasRemoveAds = true,
      productIdentifier = null;

  /// The subscription tier (free or premium).
  final SubscriptionTier tier;

  /// When the subscription expires, if applicable.
  final DateTime? expirationDate;

  /// Whether the user is currently in a trial period.
  final bool isTrialActive;

  /// Whether the subscription will auto-renew.
  final bool willRenew;

  /// Whether the user has purchased remove ads (one-time or via premium).
  final bool hasRemoveAds;

  /// The product identifier of the active subscription.
  final String? productIdentifier;

  /// Whether the user has premium access.
  bool get isPremium => tier == SubscriptionTier.premium;

  /// Whether the subscription is active (not expired).
  bool get isActive {
    if (tier == SubscriptionTier.free) return false;
    if (expirationDate == null) return true;
    return expirationDate!.isAfter(DateTime.now());
  }

  /// Creates a copy with updated fields.
  SubscriptionStatus copyWith({
    SubscriptionTier? tier,
    DateTime? expirationDate,
    bool? isTrialActive,
    bool? willRenew,
    bool? hasRemoveAds,
    String? productIdentifier,
    bool clearExpirationDate = false,
    bool clearProductIdentifier = false,
  }) {
    return SubscriptionStatus(
      tier: tier ?? this.tier,
      expirationDate: clearExpirationDate
          ? null
          : (expirationDate ?? this.expirationDate),
      isTrialActive: isTrialActive ?? this.isTrialActive,
      willRenew: willRenew ?? this.willRenew,
      hasRemoveAds: hasRemoveAds ?? this.hasRemoveAds,
      productIdentifier: clearProductIdentifier
          ? null
          : (productIdentifier ?? this.productIdentifier),
    );
  }

  @override
  List<Object?> get props => [
    tier,
    expirationDate,
    isTrialActive,
    willRenew,
    hasRemoveAds,
    productIdentifier,
  ];
}
