import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/presentation/providers/purchase_provider.dart';

/// Premium features available in the app.
enum PremiumFeature {
  /// Remove all ads from the app.
  noAds,

  /// Unlimited AI fish scans (free tier has 5 per day).
  unlimitedAiScans,

  /// Extended statistics history (6 months vs 7 days).
  extendedStatistics,

  /// Family mode with 5+ users.
  familyMode,

  /// Multiple aquariums support.
  multipleAquariums,
}

/// Extension to get display information for premium features.
extension PremiumFeatureX on PremiumFeature {
  /// Human-readable name for the feature.
  String get displayName {
    switch (this) {
      case PremiumFeature.noAds:
        return 'No Ads';
      case PremiumFeature.unlimitedAiScans:
        return 'Unlimited AI Scans';
      case PremiumFeature.extendedStatistics:
        return 'Extended Statistics';
      case PremiumFeature.familyMode:
        return 'Family Mode';
      case PremiumFeature.multipleAquariums:
        return 'Multiple Aquariums';
    }
  }

  /// Description of what the feature provides.
  String get description {
    switch (this) {
      case PremiumFeature.noAds:
        return 'Enjoy an ad-free experience';
      case PremiumFeature.unlimitedAiScans:
        return 'Scan as many fish as you want';
      case PremiumFeature.extendedStatistics:
        return 'View 6 months of feeding history';
      case PremiumFeature.familyMode:
        return 'Share with up to 5 family members';
      case PremiumFeature.multipleAquariums:
        return 'Manage multiple aquariums';
    }
  }
}

/// Checks if a feature requires premium subscription.
///
/// All features in [PremiumFeature] require premium except [PremiumFeature.noAds],
/// which can also be unlocked with the one-time "Remove Ads" purchase.
bool requiresPremium(PremiumFeature feature) {
  // All premium features require premium subscription
  // noAds is special - it can be unlocked with either premium or remove ads purchase
  return true;
}

/// Provider that checks if a specific feature is available for the current user.
///
/// Returns true if the user has access to the feature based on their subscription.
///
/// Usage:
/// ```dart
/// final hasAccess = ref.watch(featureAccessProvider(PremiumFeature.extendedStatistics));
/// if (hasAccess) {
///   // Show extended statistics
/// }
/// ```
final featureAccessProvider = Provider.family<bool, PremiumFeature>((
  ref,
  feature,
) {
  final isPremium = ref.watch(isPremiumProvider);
  final hasRemoveAds = ref.watch(hasRemoveAdsProvider);

  switch (feature) {
    case PremiumFeature.noAds:
      // Available with premium OR remove ads purchase
      return isPremium || hasRemoveAds;
    case PremiumFeature.unlimitedAiScans:
    case PremiumFeature.extendedStatistics:
    case PremiumFeature.familyMode:
    case PremiumFeature.multipleAquariums:
      // These require full premium
      return isPremium;
  }
});

/// Provider that returns all premium features the user currently has access to.
///
/// Usage:
/// ```dart
/// final accessibleFeatures = ref.watch(accessibleFeaturesProvider);
/// for (final feature in accessibleFeatures) {
///   print('User has access to ${feature.displayName}');
/// }
/// ```
final accessibleFeaturesProvider = Provider<Set<PremiumFeature>>((ref) {
  final accessibleFeatures = <PremiumFeature>{};

  for (final feature in PremiumFeature.values) {
    if (ref.watch(featureAccessProvider(feature))) {
      accessibleFeatures.add(feature);
    }
  }

  return accessibleFeatures;
});

/// Provider that returns all locked premium features for the current user.
///
/// Useful for showing what features the user would get by upgrading.
///
/// Usage:
/// ```dart
/// final lockedFeatures = ref.watch(lockedFeaturesProvider);
/// for (final feature in lockedFeatures) {
///   print('Upgrade to unlock ${feature.displayName}');
/// }
/// ```
final lockedFeaturesProvider = Provider<Set<PremiumFeature>>((ref) {
  final lockedFeatures = <PremiumFeature>{};

  for (final feature in PremiumFeature.values) {
    if (!ref.watch(featureAccessProvider(feature))) {
      lockedFeatures.add(feature);
    }
  }

  return lockedFeatures;
});
