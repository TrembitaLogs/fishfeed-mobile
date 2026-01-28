import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:fishfeed/services/analytics/analytics_service.dart';

/// Test Ad Unit IDs for development.
/// These are official Google test ad units that always return test ads.
class TestAdUnitIds {
  TestAdUnitIds._();

  // iOS Test Ad Unit IDs
  static const String iosBanner = 'ca-app-pub-3940256099942544/2435281174';
  static const String iosInterstitial =
      'ca-app-pub-3940256099942544/4411468910';
  static const String iosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  // Android Test Ad Unit IDs
  static const String androidBanner = 'ca-app-pub-3940256099942544/9214589741';
  static const String androidInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String androidRewarded =
      'ca-app-pub-3940256099942544/5224354917';
}

/// Production Ad Unit IDs.
/// Replace these with your actual Ad Unit IDs from AdMob dashboard.
class AdUnitIds {
  AdUnitIds._();

  // TODO: Replace with actual production Ad Unit IDs from AdMob dashboard
  // iOS Production Ad Unit IDs
  static const String iosBanner = 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';
  static const String iosInterstitial =
      'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';
  static const String iosRewarded = 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';

  // Android Production Ad Unit IDs
  static const String androidBanner = 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';
  static const String androidInterstitial =
      'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';
  static const String androidRewarded =
      'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';
}

/// Callback type for when user earns a reward from rewarded ad.
typedef OnRewardEarnedCallback = void Function(RewardItem reward);

/// Service for managing Google AdMob advertisements.
///
/// Handles initialization of the AdMob SDK and provides functionality
/// for banner, interstitial, and rewarded ads.
///
/// Ad Logic (as per requirements):
/// - Banner: Permanently displayed on Home screen (Free tier only)
/// - Interstitial: Shown after every 5 feedings
/// - Rewarded: User-initiated for extra freeze day
class AdService {
  AdService._();

  static final AdService _instance = AdService._();

  /// Singleton instance of [AdService].
  static AdService get instance => _instance;

  bool _isInitialized = false;

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Counter for feedings to trigger interstitial ads.
  int _feedingCounter = 0;

  /// Number of feedings before showing interstitial ad.
  static const int feedingsBeforeInterstitial = 5;

  /// Cached interstitial ad ready to be shown.
  InterstitialAd? _interstitialAd;

  /// Cached rewarded ad ready to be shown.
  RewardedAd? _rewardedAd;

  /// Stream controller for ad loading state changes.
  final _adStateController = StreamController<AdState>.broadcast();

  /// Stream of ad state updates.
  Stream<AdState> get adStateStream => _adStateController.stream;

  /// Current ad state.
  AdState _currentState = const AdState();

  /// Gets the current ad state.
  AdState get currentState => _currentState;

  /// Initializes the Google Mobile Ads SDK.
  ///
  /// Must be called before any other ad methods.
  /// Typically called during app startup in main.dart.
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('AdService: Already initialized');
      }
      return;
    }

    try {
      final initStatus = await MobileAds.instance.initialize();

      if (kDebugMode) {
        initStatus.adapterStatuses.forEach((key, value) {
          print('AdService: Adapter status for $key: ${value.description}');
        });
      }

      _isInitialized = true;

      // Pre-load interstitial and rewarded ads
      await Future.wait([_loadInterstitialAd(), _loadRewardedAd()]);

      if (kDebugMode) {
        print('AdService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AdService: Failed to initialize: $e');
      }
    }
  }

  /// Returns the appropriate banner ad unit ID based on platform and build mode.
  String get _bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isIOS
          ? TestAdUnitIds.iosBanner
          : TestAdUnitIds.androidBanner;
    }
    return Platform.isIOS ? AdUnitIds.iosBanner : AdUnitIds.androidBanner;
  }

  /// Returns the appropriate interstitial ad unit ID based on platform and build mode.
  String get _interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isIOS
          ? TestAdUnitIds.iosInterstitial
          : TestAdUnitIds.androidInterstitial;
    }
    return Platform.isIOS
        ? AdUnitIds.iosInterstitial
        : AdUnitIds.androidInterstitial;
  }

  /// Returns the appropriate rewarded ad unit ID based on platform and build mode.
  String get _rewardedAdUnitId {
    if (kDebugMode) {
      return Platform.isIOS
          ? TestAdUnitIds.iosRewarded
          : TestAdUnitIds.androidRewarded;
    }
    return Platform.isIOS ? AdUnitIds.iosRewarded : AdUnitIds.androidRewarded;
  }

  /// Creates and loads a banner ad.
  ///
  /// [width] - The width of the banner in logical pixels.
  /// Returns null if initialization failed or width is invalid.
  Future<BannerAd?> loadBannerAd(int width) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('AdService: Cannot load banner - not initialized');
      }
      return null;
    }

    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );

    if (size == null) {
      if (kDebugMode) {
        print('AdService: Unable to get adaptive banner size');
      }
      return null;
    }

    final completer = Completer<BannerAd?>();

    final bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (kDebugMode) {
            print('AdService: Banner ad loaded');
          }
          _updateState(_currentState.copyWith(isBannerLoaded: true));
          completer.complete(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            print('AdService: Banner ad failed to load: $error');
          }
          _updateState(_currentState.copyWith(isBannerLoaded: false));
          ad.dispose();
          completer.complete(null);
        },
        onAdImpression: (ad) {
          if (kDebugMode) {
            print('AdService: Banner ad impression');
          }
          AnalyticsService.instance.trackAdImpression(
            adType: AdType.banner,
            placement: 'home_screen',
          );
        },
        onAdClicked: (ad) {
          if (kDebugMode) {
            print('AdService: Banner ad clicked');
          }
          AnalyticsService.instance.trackAdClicked(
            adType: AdType.banner,
            placement: 'home_screen',
          );
        },
      ),
    );

    await bannerAd.load();
    return completer.future;
  }

  /// Loads an interstitial ad.
  ///
  /// Called automatically after showing an interstitial to prepare the next one.
  Future<void> _loadInterstitialAd() async {
    if (!_isInitialized) {
      return;
    }

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (kDebugMode) {
            print('AdService: Interstitial ad loaded');
          }
          _interstitialAd = ad;
          _updateState(_currentState.copyWith(isInterstitialReady: true));

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              if (kDebugMode) {
                print('AdService: Interstitial ad shown');
              }
              AnalyticsService.instance.trackAdImpression(
                adType: AdType.interstitial,
                placement: 'feeding_completed',
              );
            },
            onAdDismissedFullScreenContent: (ad) {
              if (kDebugMode) {
                print('AdService: Interstitial ad dismissed');
              }
              ad.dispose();
              _interstitialAd = null;
              _updateState(_currentState.copyWith(isInterstitialReady: false));
              // Preload next interstitial
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              if (kDebugMode) {
                print('AdService: Interstitial failed to show: $error');
              }
              ad.dispose();
              _interstitialAd = null;
              _updateState(_currentState.copyWith(isInterstitialReady: false));
              // Try to reload
              _loadInterstitialAd();
            },
            onAdClicked: (ad) {
              if (kDebugMode) {
                print('AdService: Interstitial ad clicked');
              }
              AnalyticsService.instance.trackAdClicked(
                adType: AdType.interstitial,
                placement: 'feeding_completed',
              );
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            print('AdService: Interstitial ad failed to load: $error');
          }
          _updateState(_currentState.copyWith(isInterstitialReady: false));
        },
      ),
    );
  }

  /// Increments the feeding counter and shows interstitial if threshold reached.
  ///
  /// Call this after each feeding is marked as completed.
  /// Returns true if an interstitial was shown.
  Future<bool> onFeedingCompleted() async {
    _feedingCounter++;

    if (kDebugMode) {
      print(
        'AdService: Feeding count: $_feedingCounter/$feedingsBeforeInterstitial',
      );
    }

    if (_feedingCounter >= feedingsBeforeInterstitial) {
      _feedingCounter = 0;
      return showInterstitialAd();
    }

    return false;
  }

  /// Shows an interstitial ad if one is ready.
  ///
  /// Returns true if the ad was shown, false otherwise.
  Future<bool> showInterstitialAd() async {
    if (_interstitialAd == null) {
      if (kDebugMode) {
        print('AdService: No interstitial ad ready');
      }
      return false;
    }

    try {
      await _interstitialAd!.show();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('AdService: Error showing interstitial: $e');
      }
      return false;
    }
  }

  /// Loads a rewarded ad.
  ///
  /// Called automatically after showing a rewarded ad to prepare the next one.
  Future<void> _loadRewardedAd() async {
    if (!_isInitialized) {
      return;
    }

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (kDebugMode) {
            print('AdService: Rewarded ad loaded');
          }
          _rewardedAd = ad;
          _updateState(_currentState.copyWith(isRewardedReady: true));
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            print('AdService: Rewarded ad failed to load: $error');
          }
          _updateState(_currentState.copyWith(isRewardedReady: false));
        },
      ),
    );
  }

  /// Shows a rewarded ad for extra freeze day.
  ///
  /// [onRewardEarned] - Callback invoked when user earns the reward.
  /// Returns true if the ad was shown, false otherwise.
  Future<bool> showRewardedAd({
    required OnRewardEarnedCallback onRewardEarned,
  }) async {
    if (_rewardedAd == null) {
      if (kDebugMode) {
        print('AdService: No rewarded ad ready');
      }
      return false;
    }

    final completer = Completer<bool>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        if (kDebugMode) {
          print('AdService: Rewarded ad shown');
        }
        AnalyticsService.instance.trackAdImpression(
          adType: AdType.rewarded,
          placement: 'freeze_day',
        );
      },
      onAdDismissedFullScreenContent: (ad) {
        if (kDebugMode) {
          print('AdService: Rewarded ad dismissed');
        }
        ad.dispose();
        _rewardedAd = null;
        _updateState(_currentState.copyWith(isRewardedReady: false));
        // Preload next rewarded ad
        _loadRewardedAd();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (kDebugMode) {
          print('AdService: Rewarded ad failed to show: $error');
        }
        ad.dispose();
        _rewardedAd = null;
        _updateState(_currentState.copyWith(isRewardedReady: false));
        // Try to reload
        _loadRewardedAd();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
      onAdClicked: (ad) {
        if (kDebugMode) {
          print('AdService: Rewarded ad clicked');
        }
        AnalyticsService.instance.trackAdClicked(
          adType: AdType.rewarded,
          placement: 'freeze_day',
        );
      },
    );

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          if (kDebugMode) {
            print(
              'AdService: User earned reward: ${reward.amount} ${reward.type}',
            );
          }
          onRewardEarned(reward);
        },
      );
      return completer.future;
    } catch (e) {
      if (kDebugMode) {
        print('AdService: Error showing rewarded ad: $e');
      }
      return false;
    }
  }

  /// Returns true if a rewarded ad is ready to be shown.
  bool get isRewardedAdReady => _rewardedAd != null;

  /// Returns true if an interstitial ad is ready to be shown.
  bool get isInterstitialAdReady => _interstitialAd != null;

  /// Resets the feeding counter.
  ///
  /// Call this when user purchases premium or removes ads.
  void resetFeedingCounter() {
    _feedingCounter = 0;
  }

  /// Gets the current feeding counter value.
  int get feedingCounter => _feedingCounter;

  /// Updates the current state and notifies listeners.
  void _updateState(AdState newState) {
    _currentState = newState;
    _adStateController.add(newState);
  }

  /// Disposes of resources.
  ///
  /// Call this when the service is no longer needed.
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _adStateController.close();
  }
}

/// Represents the current state of ad loading.
class AdState {
  const AdState({
    this.isBannerLoaded = false,
    this.isInterstitialReady = false,
    this.isRewardedReady = false,
  });

  /// Whether a banner ad is currently loaded.
  final bool isBannerLoaded;

  /// Whether an interstitial ad is ready to show.
  final bool isInterstitialReady;

  /// Whether a rewarded ad is ready to show.
  final bool isRewardedReady;

  /// Creates a copy of this state with the given fields replaced.
  AdState copyWith({
    bool? isBannerLoaded,
    bool? isInterstitialReady,
    bool? isRewardedReady,
  }) {
    return AdState(
      isBannerLoaded: isBannerLoaded ?? this.isBannerLoaded,
      isInterstitialReady: isInterstitialReady ?? this.isInterstitialReady,
      isRewardedReady: isRewardedReady ?? this.isRewardedReady,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdState &&
        other.isBannerLoaded == isBannerLoaded &&
        other.isInterstitialReady == isInterstitialReady &&
        other.isRewardedReady == isRewardedReady;
  }

  @override
  int get hashCode {
    return Object.hash(isBannerLoaded, isInterstitialReady, isRewardedReady);
  }
}
