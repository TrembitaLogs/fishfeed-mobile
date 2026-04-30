import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/services/ads/ad_service.dart';

/// Provider for the [AdService] singleton instance.
///
/// Usage:
/// ```dart
/// final adService = ref.watch(adServiceProvider);
/// await adService.showInterstitialAd();
/// ```
final adServiceProvider = Provider<AdService>((ref) {
  return AdService.instance;
});

/// Provider for real-time ad state updates.
///
/// Emits new values whenever the ad state changes (ad loaded, shown, etc.).
///
/// Usage:
/// ```dart
/// final adStateAsync = ref.watch(adStateStreamProvider);
/// adStateAsync.when(
///   data: (state) => Text('Rewarded ready: ${state.isRewardedReady}'),
///   loading: () => CircularProgressIndicator(),
///   error: (e, s) => Text('Error: $e'),
/// );
/// ```
final adStateStreamProvider = StreamProvider<AdState>((ref) {
  final adService = ref.watch(adServiceProvider);
  return adService.adStateStream;
});

/// Provider for the current ad state.
///
/// Returns the current state of ad loading synchronously.
///
/// Usage:
/// ```dart
/// final adState = ref.watch(adStateProvider);
/// if (adState.isRewardedReady) {
///   // Show watch ad button
/// }
/// ```
final adStateProvider = Provider<AdState>((ref) {
  // Watch the stream to trigger updates when ad state changes
  ref.watch(adStateStreamProvider);

  final adService = ref.watch(adServiceProvider);
  return adService.currentState;
});

/// Provider for checking if ads should be shown.
///
/// Returns false if:
/// - User has premium subscription
/// - User has purchased "Remove Ads"
///
/// Usage:
/// ```dart
/// final shouldShowAds = ref.watch(shouldShowAdsProvider);
/// if (shouldShowAds) {
///   // Display banner ad
/// }
/// ```
final shouldShowAdsProvider = Provider<bool>((ref) {
  final hasRemoveAds = ref.watch(hasRemoveAdsProvider);
  return !hasRemoveAds;
});

/// Provider for checking if a rewarded ad is ready.
///
/// Convenience provider for showing "Watch Ad" buttons.
///
/// Usage:
/// ```dart
/// final isRewardedReady = ref.watch(isRewardedAdReadyProvider);
/// if (isRewardedReady) {
///   ElevatedButton(
///     onPressed: () => _watchAdForFreezeDay(),
///     child: Text('Watch Ad for Extra Freeze Day'),
///   )
/// }
/// ```
final isRewardedAdReadyProvider = Provider<bool>((ref) {
  final adService = ref.watch(adServiceProvider);
  // Also watch the stream for updates
  ref.watch(adStateStreamProvider);
  return adService.isRewardedAdReady;
});

/// Provider for checking if an interstitial ad is ready.
///
/// Usage:
/// ```dart
/// final isInterstitialReady = ref.watch(isInterstitialAdReadyProvider);
/// ```
final isInterstitialAdReadyProvider = Provider<bool>((ref) {
  final adService = ref.watch(adServiceProvider);
  // Also watch the stream for updates
  ref.watch(adStateStreamProvider);
  return adService.isInterstitialAdReady;
});

