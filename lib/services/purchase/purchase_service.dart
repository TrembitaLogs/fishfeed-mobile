import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:fishfeed/core/config/api_config.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';

/// Entitlement identifiers configured in RevenueCat dashboard.
class PurchaseEntitlements {
  PurchaseEntitlements._();

  /// Premium subscription entitlement.
  static const String premium = 'premium';

  /// Remove ads one-time purchase entitlement.
  static const String removeAds = 'remove_ads';
}

/// Service for managing in-app purchases and subscriptions via RevenueCat.
///
/// Handles initialization of the RevenueCat SDK and provides access
/// to purchase functionality across the app. Also manages subscription
/// status synchronization with the backend server.
class PurchaseService with WidgetsBindingObserver {
  PurchaseService._();

  static final PurchaseService _instance = PurchaseService._();

  /// Singleton instance of [PurchaseService].
  static PurchaseService get instance => _instance;

  bool _isInitialized = false;

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Environment variable key for iOS RevenueCat API key.
  static const String _envKeyIos = 'REVENUECAT_API_KEY_IOS';

  /// Environment variable key for Android RevenueCat API key.
  static const String _envKeyAndroid = 'REVENUECAT_API_KEY_ANDROID';

  /// Cached customer info for synchronous access.
  CustomerInfo? _cachedCustomerInfo;

  /// Stream controller for customer info updates.
  final _customerInfoController = StreamController<CustomerInfo>.broadcast();

  /// Stream of customer info updates.
  ///
  /// Emits new customer info whenever it changes (purchase, restore, etc.).
  Stream<CustomerInfo> get customerInfoStream => _customerInfoController.stream;

  /// Stream controller for subscription status updates.
  final _subscriptionStatusController =
      StreamController<SubscriptionStatus>.broadcast();

  /// Stream of subscription status updates.
  ///
  /// Emits when subscription status changes (sync, purchase, etc.).
  Stream<SubscriptionStatus> get subscriptionStatusStream =>
      _subscriptionStatusController.stream;

  /// Dio client for backend API calls.
  Dio? _dio;

  /// Whether app lifecycle observer is active.
  bool _isObservingLifecycle = false;

  /// Whether the app is currently in foreground.
  bool _isAppActive = true;

  /// Last sync timestamp for rate limiting.
  DateTime? _lastSyncTime;

  /// Minimum interval between syncs (in seconds).
  static const int _minSyncIntervalSeconds = 30;

  /// Configures the Dio client for backend API calls.
  ///
  /// Call this after API client is available to enable backend sync.
  /// If not configured, sync operations will only use local cache.
  void configureDio(Dio dio) {
    _dio = dio;
    if (kDebugMode) {
      print('PurchaseService: Dio configured for backend sync');
    }
  }

  /// Initializes the RevenueCat SDK.
  ///
  /// Must be called before any other purchase methods.
  /// Typically called during app startup in main.dart.
  ///
  /// The SDK will be configured with the appropriate API key based on platform:
  /// - iOS: Uses REVENUECAT_API_KEY_IOS from .env
  /// - Android: Uses REVENUECAT_API_KEY_ANDROID from .env
  ///
  /// If the API key is not configured, initialization will be skipped
  /// and a warning will be logged.
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('PurchaseService: Already initialized');
      }
      return;
    }

    final apiKey = _getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      if (kDebugMode) {
        print('PurchaseService: API key not configured, skipping initialization');
        print('PurchaseService: Set $_envKeyIos or $_envKeyAndroid in .env');
      }
      return;
    }

    try {
      // Enable debug logging in debug mode
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      // Configure RevenueCat with the API key
      final configuration = PurchasesConfiguration(apiKey)
        ..purchasesAreCompletedBy = const PurchasesAreCompletedByRevenueCat()
        ..shouldShowInAppMessagesAutomatically = true;

      await Purchases.configure(configuration);

      // Set up customer info listener
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      // Fetch initial customer info
      try {
        _cachedCustomerInfo = await Purchases.getCustomerInfo();
        _customerInfoController.add(_cachedCustomerInfo!);
      } catch (e) {
        if (kDebugMode) {
          print('PurchaseService: Failed to fetch initial customer info: $e');
        }
      }

      _isInitialized = true;

      // Start lifecycle observer
      _startLifecycleObserver();

      if (kDebugMode) {
        print('PurchaseService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PurchaseService: Failed to initialize: $e');
      }
    }
  }

  /// Starts the app lifecycle observer for sync on resume.
  void _startLifecycleObserver() {
    if (_isObservingLifecycle) return;

    WidgetsBinding.instance.addObserver(this);
    _isObservingLifecycle = true;

    if (kDebugMode) {
      print('PurchaseService: Lifecycle observer started');
    }
  }

  /// Stops the app lifecycle observer.
  void _stopLifecycleObserver() {
    if (!_isObservingLifecycle) return;

    WidgetsBinding.instance.removeObserver(this);
    _isObservingLifecycle = false;

    if (kDebugMode) {
      print('PurchaseService: Lifecycle observer stopped');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasActive = _isAppActive;
    _isAppActive = state == AppLifecycleState.resumed;

    if (kDebugMode) {
      print('PurchaseService: App lifecycle changed to $state');
    }

    // Sync subscription status when app resumes from background
    if (!wasActive && _isAppActive) {
      syncSubscriptionStatus();
    }
  }

  /// Handles customer info updates from RevenueCat.
  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    _cachedCustomerInfo = customerInfo;
    _customerInfoController.add(customerInfo);

    if (kDebugMode) {
      print('PurchaseService: Customer info updated');
      print('PurchaseService: Active entitlements: ${customerInfo.entitlements.active.keys}');
    }
  }

  /// Returns the appropriate API key based on the current platform.
  String? _getApiKey() {
    if (Platform.isIOS || Platform.isMacOS) {
      return dotenv.env[_envKeyIos];
    } else if (Platform.isAndroid) {
      return dotenv.env[_envKeyAndroid];
    }
    return null;
  }

  /// Logs in a user to RevenueCat.
  ///
  /// Call this after the user authenticates in your app.
  /// This will identify the user in RevenueCat and sync their purchases.
  ///
  /// [userId] - The unique identifier for the user in your system.
  Future<void> logIn(String userId) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('PurchaseService: Cannot log in - not initialized');
      }
      return;
    }

    try {
      final result = await Purchases.logIn(userId);
      _cachedCustomerInfo = result.customerInfo;
      _customerInfoController.add(result.customerInfo);

      if (kDebugMode) {
        print('PurchaseService: User logged in: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PurchaseService: Failed to log in user: $e');
      }
    }
  }

  /// Logs out the current user from RevenueCat.
  ///
  /// Call this when the user logs out of your app.
  /// This will reset the user to an anonymous state.
  Future<void> logOut() async {
    if (!_isInitialized) {
      return;
    }

    try {
      final customerInfo = await Purchases.logOut();
      _cachedCustomerInfo = customerInfo;
      _customerInfoController.add(customerInfo);

      if (kDebugMode) {
        print('PurchaseService: User logged out');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PurchaseService: Failed to log out user: $e');
      }
    }
  }

  /// Fetches available offerings from RevenueCat.
  ///
  /// Returns the offerings configured in the RevenueCat dashboard,
  /// including products and packages.
  ///
  /// Returns [Left] with failure if not initialized or fetch fails.
  /// Returns [Right] with offerings on success.
  Future<Either<Failure, Offerings>> getOfferings() async {
    if (!_isInitialized) {
      return const Left(PurchaseNotInitializedFailure());
    }

    try {
      final offerings = await Purchases.getOfferings();
      return Right(offerings);
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('PurchaseService: Failed to fetch offerings: $e');
      }
      return Left(PurchaseFailure(
        message: e.message ?? 'Failed to fetch offerings',
        errorCode: e.code,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('PurchaseService: Failed to fetch offerings: $e');
      }
      return Left(PurchaseFailure(message: e.toString()));
    }
  }

  /// Purchases a package.
  ///
  /// [package] - The package to purchase from an offering.
  ///
  /// Returns [Left] with failure if purchase fails or is cancelled.
  /// Returns [Right] with customer info on success.
  Future<Either<Failure, CustomerInfo>> purchasePackage(Package package) async {
    if (!_isInitialized) {
      return const Left(PurchaseNotInitializedFailure());
    }

    try {
      // purchasePackage returns CustomerInfo directly in purchases_flutter 8.x
      final customerInfo = await Purchases.purchasePackage(package);

      _cachedCustomerInfo = customerInfo;
      _customerInfoController.add(customerInfo);

      if (kDebugMode) {
        print('PurchaseService: Purchase successful');
        print('PurchaseService: Active entitlements: ${customerInfo.entitlements.active.keys}');
      }

      // Sync with backend after successful purchase
      unawaited(syncSubscriptionStatus(force: true));

      return Right(customerInfo);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);

      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        if (kDebugMode) {
          print('PurchaseService: Purchase cancelled by user');
        }
        return const Left(PurchaseCancelledFailure());
      }

      if (errorCode == PurchasesErrorCode.productNotAvailableForPurchaseError) {
        if (kDebugMode) {
          print('PurchaseService: Product not available');
        }
        return Left(ProductNotAvailableFailure(
          productId: package.storeProduct.identifier,
        ));
      }

      if (kDebugMode) {
        print('PurchaseService: Purchase failed: $e');
      }

      return Left(PurchaseFailure(
        message: e.message ?? 'Purchase failed',
        errorCode: errorCode.name,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('PurchaseService: Purchase failed: $e');
      }
      return Left(PurchaseFailure(message: e.toString()));
    }
  }

  /// Restores previous purchases.
  ///
  /// Use this when users switch devices or reinstall the app.
  /// This will sync any previous purchases to the current account.
  ///
  /// Returns [Left] with failure if restore fails.
  /// Returns [Right] with customer info on success.
  Future<Either<Failure, CustomerInfo>> restorePurchases() async {
    if (!_isInitialized) {
      return const Left(PurchaseNotInitializedFailure());
    }

    try {
      final customerInfo = await Purchases.restorePurchases();

      _cachedCustomerInfo = customerInfo;
      _customerInfoController.add(customerInfo);

      if (kDebugMode) {
        print('PurchaseService: Purchases restored successfully');
        print('PurchaseService: Active entitlements: ${customerInfo.entitlements.active.keys}');
      }

      // Sync with backend after successful restore
      unawaited(syncSubscriptionStatus(force: true));

      return Right(customerInfo);
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('PurchaseService: Restore failed: $e');
      }

      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      return Left(PurchaseFailure(
        message: e.message ?? 'Failed to restore purchases',
        errorCode: errorCode.name,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('PurchaseService: Restore failed: $e');
      }
      return Left(PurchaseFailure(message: e.toString()));
    }
  }

  /// Gets the current customer info.
  ///
  /// Returns cached info if available, otherwise fetches from RevenueCat.
  ///
  /// Returns [Left] with failure if not initialized or fetch fails.
  /// Returns [Right] with customer info on success.
  Future<Either<Failure, CustomerInfo>> getCustomerInfo() async {
    if (!_isInitialized) {
      return const Left(PurchaseNotInitializedFailure());
    }

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _cachedCustomerInfo = customerInfo;
      return Right(customerInfo);
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('PurchaseService: Failed to get customer info: $e');
      }

      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      return Left(PurchaseFailure(
        message: e.message ?? 'Failed to get customer info',
        errorCode: errorCode.name,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('PurchaseService: Failed to get customer info: $e');
      }
      return Left(PurchaseFailure(message: e.toString()));
    }
  }

  /// Checks if the user has premium access.
  ///
  /// Uses cached customer info for synchronous access.
  /// Returns false if not initialized or no cached info.
  bool isPremium() {
    if (!_isInitialized || _cachedCustomerInfo == null) {
      return false;
    }

    return _cachedCustomerInfo!.entitlements.active
        .containsKey(PurchaseEntitlements.premium);
  }

  /// Checks if the user has the remove ads entitlement.
  ///
  /// This can be from either a premium subscription or
  /// the one-time remove ads purchase.
  ///
  /// Uses cached customer info for synchronous access.
  /// Returns false if not initialized or no cached info.
  bool hasRemoveAds() {
    if (!_isInitialized || _cachedCustomerInfo == null) {
      return false;
    }

    final entitlements = _cachedCustomerInfo!.entitlements.active;

    // Remove ads if premium or has specific remove_ads entitlement
    return entitlements.containsKey(PurchaseEntitlements.premium) ||
        entitlements.containsKey(PurchaseEntitlements.removeAds);
  }

  /// Gets the "Remove Ads" package from offerings.
  ///
  /// Looks for a package with the remove_ads product in the current offering.
  /// This is a non-consumable one-time purchase.
  ///
  /// Returns [Left] with failure if not initialized or package not found.
  /// Returns [Right] with the package on success.
  Future<Either<Failure, Package>> getRemoveAdsPackage() async {
    if (!_isInitialized) {
      return const Left(PurchaseNotInitializedFailure());
    }

    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      if (current == null) {
        return const Left(PurchaseFailure(
          message: 'No offerings available',
        ));
      }

      // Look for remove_ads package in the current offering
      // It could be a lifetime package or a custom package
      Package? removeAdsPackage;

      // Check lifetime package first
      if (current.lifetime != null) {
        final product = current.lifetime!.storeProduct;
        if (product.identifier.contains('remove_ads')) {
          removeAdsPackage = current.lifetime;
        }
      }

      // Check all available packages if not found in lifetime
      if (removeAdsPackage == null) {
        for (final package in current.availablePackages) {
          if (package.storeProduct.identifier.contains('remove_ads')) {
            removeAdsPackage = package;
            break;
          }
        }
      }

      if (removeAdsPackage == null) {
        return const Left(ProductNotAvailableFailure(
          productId: 'remove_ads',
        ));
      }

      return Right(removeAdsPackage);
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('PurchaseService: Failed to get remove ads package: $e');
      }
      return Left(PurchaseFailure(
        message: e.message ?? 'Failed to get remove ads package',
        errorCode: e.code,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('PurchaseService: Failed to get remove ads package: $e');
      }
      return Left(PurchaseFailure(message: e.toString()));
    }
  }

  /// Purchases the "Remove Ads" one-time product.
  ///
  /// Convenience method that fetches the remove_ads package and purchases it.
  ///
  /// Returns [Left] with failure if purchase fails or is cancelled.
  /// Returns [Right] with customer info on success.
  Future<Either<Failure, CustomerInfo>> purchaseRemoveAds() async {
    final packageResult = await getRemoveAdsPackage();

    return packageResult.fold(
      (failure) => Left(failure),
      (package) => purchasePackage(package),
    );
  }

  /// Gets the current subscription status.
  ///
  /// Returns a [SubscriptionStatus] representing the user's current
  /// subscription state including tier, expiration, and trial status.
  SubscriptionStatus getSubscriptionStatus() {
    if (!_isInitialized || _cachedCustomerInfo == null) {
      return const SubscriptionStatus.free();
    }

    final entitlements = _cachedCustomerInfo!.entitlements.active;

    // Check for premium entitlement
    if (entitlements.containsKey(PurchaseEntitlements.premium)) {
      final premium = entitlements[PurchaseEntitlements.premium]!;

      DateTime? expirationDate;
      if (premium.expirationDate != null) {
        expirationDate = DateTime.tryParse(premium.expirationDate!);
      }

      return SubscriptionStatus.premium(
        expirationDate: expirationDate,
        isTrialActive: premium.periodType == PeriodType.trial,
        willRenew: premium.willRenew,
        productIdentifier: premium.productIdentifier,
      );
    }

    // Check for remove ads only
    if (entitlements.containsKey(PurchaseEntitlements.removeAds)) {
      return const SubscriptionStatus.removeAdsOnly();
    }

    return const SubscriptionStatus.free();
  }

  /// Synchronizes subscription status with the backend server.
  ///
  /// This method:
  /// 1. Gets current customer info from RevenueCat
  /// 2. Sends it to the backend for server-side validation
  /// 3. Caches the validated status locally
  /// 4. Emits the updated status through [subscriptionStatusStream]
  ///
  /// If offline or sync fails, falls back to cached status.
  /// Rate-limited to prevent excessive API calls.
  ///
  /// [force] - If true, ignores rate limiting and syncs immediately.
  ///
  /// Returns the synchronized [SubscriptionStatus].
  Future<SubscriptionStatus> syncSubscriptionStatus({bool force = false}) async {
    // Rate limiting check
    if (!force && _lastSyncTime != null) {
      final elapsed = DateTime.now().difference(_lastSyncTime!);
      if (elapsed.inSeconds < _minSyncIntervalSeconds) {
        if (kDebugMode) {
          print('PurchaseService: Sync rate limited, using cached status');
        }
        return _getCachedOrCurrentStatus();
      }
    }

    if (kDebugMode) {
      print('PurchaseService: Syncing subscription status...');
    }

    // Get current status from RevenueCat
    final currentStatus = getSubscriptionStatus();

    // If no Dio client configured, just cache locally
    if (_dio == null) {
      if (kDebugMode) {
        print('PurchaseService: No Dio client, caching locally only');
      }
      await _cacheSubscriptionStatus(currentStatus);
      _emitSubscriptionStatus(currentStatus);
      return currentStatus;
    }

    // Try to sync with backend
    try {
      final syncedStatus = await _syncWithBackend(currentStatus);
      _lastSyncTime = DateTime.now();
      await _cacheSubscriptionStatus(syncedStatus);
      _emitSubscriptionStatus(syncedStatus);

      if (kDebugMode) {
        print('PurchaseService: Sync completed successfully');
      }

      return syncedStatus;
    } catch (e) {
      if (kDebugMode) {
        print('PurchaseService: Sync failed, using cached/current status: $e');
      }

      // On failure, use cached or current status
      final fallbackStatus = _getCachedOrCurrentStatus();
      _emitSubscriptionStatus(fallbackStatus);
      return fallbackStatus;
    }
  }

  /// Syncs subscription status with the backend API.
  Future<SubscriptionStatus> _syncWithBackend(SubscriptionStatus localStatus) async {
    if (_dio == null) {
      throw StateError('Dio client not configured');
    }

    final customerInfo = _cachedCustomerInfo;
    if (customerInfo == null) {
      throw StateError('No customer info available');
    }

    final platform = Platform.isIOS ? 'ios' : 'android';
    final appUserId = customerInfo.originalAppUserId;

    // Prepare entitlements data for backend
    final entitlementsData = <String, dynamic>{};
    for (final entry in customerInfo.entitlements.active.entries) {
      final entitlement = entry.value;
      entitlementsData[entry.key] = {
        'identifier': entitlement.identifier,
        'productIdentifier': entitlement.productIdentifier,
        'expirationDate': entitlement.expirationDate,
        'willRenew': entitlement.willRenew,
        'periodType': entitlement.periodType.name,
        'isActive': entitlement.isActive,
      };
    }

    final response = await _dio!.post<Map<String, dynamic>>(
      ApiEndpoints.subscriptionSync,
      data: {
        'platform': platform,
        'appUserId': appUserId,
        'entitlements': entitlementsData,
        'localStatus': {
          'tier': localStatus.tier.name,
          'isPremium': localStatus.isPremium,
          'hasRemoveAds': localStatus.hasRemoveAds,
          'isTrialActive': localStatus.isTrialActive,
          'willRenew': localStatus.willRenew,
          'expirationDate': localStatus.expirationDate?.toIso8601String(),
          'productIdentifier': localStatus.productIdentifier,
        },
      },
    );

    // Parse backend response
    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      return _parseBackendStatus(data);
    }

    // If backend returns non-200, use local status
    return localStatus;
  }

  /// Parses subscription status from backend response.
  SubscriptionStatus _parseBackendStatus(Map<String, dynamic> data) {
    final status = data['status'] as Map<String, dynamic>?;
    if (status == null) {
      return const SubscriptionStatus.free();
    }

    final tierStr = status['tier'] as String? ?? 'free';
    final tier = tierStr == 'premium'
        ? SubscriptionTier.premium
        : SubscriptionTier.free;

    DateTime? expirationDate;
    final expStr = status['expirationDate'] as String?;
    if (expStr != null) {
      expirationDate = DateTime.tryParse(expStr);
    }

    return SubscriptionStatus(
      tier: tier,
      expirationDate: expirationDate,
      isTrialActive: status['isTrialActive'] as bool? ?? false,
      willRenew: status['willRenew'] as bool? ?? false,
      hasRemoveAds: status['hasRemoveAds'] as bool? ?? false,
      productIdentifier: status['productIdentifier'] as String?,
    );
  }

  /// Gets cached status or falls back to current RevenueCat status.
  SubscriptionStatus _getCachedOrCurrentStatus() {
    // Try cached status first
    if (HiveBoxes.isInitialized) {
      final cached = HiveBoxes.getCachedSubscriptionStatus();
      if (cached != null && cached.isValid) {
        return cached.status;
      }
    }

    // Fall back to current RevenueCat status
    return getSubscriptionStatus();
  }

  /// Caches subscription status to local storage.
  Future<void> _cacheSubscriptionStatus(SubscriptionStatus status) async {
    if (!HiveBoxes.isInitialized) {
      if (kDebugMode) {
        print('PurchaseService: HiveBoxes not initialized, skipping cache');
      }
      return;
    }

    await HiveBoxes.setCachedSubscriptionStatus(status);

    if (kDebugMode) {
      print('PurchaseService: Subscription status cached');
    }
  }

  /// Emits subscription status to the stream.
  void _emitSubscriptionStatus(SubscriptionStatus status) {
    if (!_subscriptionStatusController.isClosed) {
      _subscriptionStatusController.add(status);
    }
  }

  /// Clears the cached subscription status.
  ///
  /// Call this when user logs out or subscription data should be reset.
  Future<void> clearCachedSubscriptionStatus() async {
    if (HiveBoxes.isInitialized) {
      await HiveBoxes.clearCachedSubscriptionStatus();
    }
    _lastSyncTime = null;

    if (kDebugMode) {
      print('PurchaseService: Cached subscription status cleared');
    }
  }

  /// Disposes of resources.
  ///
  /// Call this when the service is no longer needed.
  void dispose() {
    _stopLifecycleObserver();
    _customerInfoController.close();
    _subscriptionStatusController.close();
  }
}
