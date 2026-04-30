import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:fishfeed/presentation/providers/ad_provider.dart';

/// A widget that displays a banner ad.
///
/// Only shows ads if the user hasn't purchased "Remove Ads" or premium.
/// Each instance owns its own [BannerAd] — disposed in [State.dispose].
/// Sharing a single ad across multiple widgets caused the "This AdWidget
/// is already in the Widget tree" assert when navigation kept two
/// host screens mounted (Sentry MOBILE-4).
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
  BannerAd? _bannerAd;
  bool _isLoading = false;
  bool _loadAttempted = false;
  bool _loadFinished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadAttempted) {
      _loadAttempted = true;
      // Defer until after the first build so MediaQuery / providers are stable.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadAd();
        }
      });
    }
  }

  Future<void> _loadAd() async {
    if (_isLoading || _bannerAd != null) return;

    final shouldShowAds = ref.read(shouldShowAdsProvider);
    if (!shouldShowAds) return;

    setState(() => _isLoading = true);

    final adService = ref.read(adServiceProvider);
    final width = MediaQuery.of(context).size.width.toInt();

    try {
      final ad = await adService.loadBannerAd(width);

      if (!mounted) {
        // Widget was disposed before the ad finished loading.
        unawaited(ad?.dispose());
        return;
      }

      setState(() {
        _bannerAd = ad;
        _isLoading = false;
        _loadFinished = true;
      });
    } catch (e) {
      if (kDebugMode) {
        print('BannerAdWidget: Failed to load ad: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadFinished = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowAds = ref.watch(shouldShowAdsProvider);

    if (!shouldShowAds) {
      return const SizedBox.shrink();
    }

    final ad = _bannerAd;

    if (ad == null) {
      // Show a loader from the moment we know we'll attempt a load until
      // the load resolves (success path replaces this branch with the ad,
      // failure / null sets _loadFinished and we collapse to nothing).
      if (!_loadFinished) {
        return Padding(
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
        );
      }
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
  }
}
