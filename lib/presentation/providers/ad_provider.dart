import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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

/// Notifier for managing banner ad loading.
///
/// Handles loading banner ads with the correct width.
class BannerAdNotifier extends StateNotifier<AsyncValue<BannerAd?>> {
  BannerAdNotifier(this._adService, this._shouldShowAds)
      : super(const AsyncValue.loading());

  final AdService _adService;
  final bool _shouldShowAds;

  /// Loads a banner ad with the given width.
  ///
  /// [width] - The width of the banner in logical pixels.
  Future<void> loadAd(int width) async {
    if (!_shouldShowAds) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final ad = await _adService.loadBannerAd(width);
      state = AsyncValue.data(ad);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Disposes the current banner ad.
  void disposeAd() {
    state.whenData((ad) => ad?.dispose());
    state = const AsyncValue.data(null);
  }
}

/// Provider for managing banner ads with automatic loading.
///
/// Usage:
/// ```dart
/// final bannerAdState = ref.watch(bannerAdProvider);
/// bannerAdState.when(
///   data: (ad) => ad != null
///     ? SizedBox(
///         width: ad.size.width.toDouble(),
///         height: ad.size.height.toDouble(),
///         child: AdWidget(ad: ad),
///       )
///     : SizedBox.shrink(),
///   loading: () => SizedBox(height: 50),
///   error: (e, s) => SizedBox.shrink(),
/// );
///
/// // To load the ad:
/// ref.read(bannerAdProvider.notifier).loadAd(screenWidth);
/// ```
final bannerAdProvider =
    StateNotifierProvider<BannerAdNotifier, AsyncValue<BannerAd?>>((ref) {
  final adService = ref.watch(adServiceProvider);
  final shouldShowAds = ref.watch(shouldShowAdsProvider);

  final notifier = BannerAdNotifier(adService, shouldShowAds);

  ref.onDispose(() {
    notifier.disposeAd();
  });

  return notifier;
});
