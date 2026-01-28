import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:fishfeed/presentation/providers/ad_provider.dart';

/// A widget that displays a banner ad.
///
/// Only shows ads if the user hasn't purchased "Remove Ads" or premium.
/// Automatically loads the ad when the widget is built.
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  /// Padding around the banner ad.
  final EdgeInsets padding;

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded) {
      _isLoaded = true;
      // Schedule ad loading after build to avoid modifying provider during build
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadAd();
        }
      });
    }
  }

  void _loadAd() {
    final width = MediaQuery.of(context).size.width.toInt();
    ref.read(bannerAdProvider.notifier).loadAd(width);
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowAds = ref.watch(shouldShowAdsProvider);

    if (!shouldShowAds) {
      return const SizedBox.shrink();
    }

    final bannerAdState = ref.watch(bannerAdProvider);

    return bannerAdState.when(
      data: (ad) {
        if (ad == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: widget.padding,
          child: Container(
            alignment: Alignment.center,
            width: ad.size.width.toDouble(),
            height: ad.size.height.toDouble(),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AdWidget(ad: ad),
          ),
        );
      },
      loading: () => Padding(
        padding: widget.padding,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
