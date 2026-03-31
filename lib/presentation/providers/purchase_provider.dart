import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:fishfeed/core/di/datasource_providers.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/services/purchase/purchase_service.dart';

/// Provider for the [PurchaseService] singleton instance.
///
/// Automatically configures the Dio client for backend sync when available.
///
/// Usage:
/// ```dart
/// final purchaseService = ref.watch(purchaseServiceProvider);
/// await purchaseService.purchasePackage(package);
/// ```
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final purchaseService = PurchaseService.instance;

  // Configure Dio for backend sync if available
  try {
    final apiClient = ref.watch(apiClientProvider);
    purchaseService.configureDio(apiClient.dio);
  } catch (e) {
    debugPrint('PurchaseProvider: ApiClient not available yet: $e');
  }

  return purchaseService;
});

/// Provider for real-time customer info updates.
///
/// Emits new values whenever the customer's subscription status changes.
/// This is useful for updating the UI when a purchase is made or restored.
///
/// Usage:
/// ```dart
/// final customerInfoAsync = ref.watch(customerInfoStreamProvider);
/// customerInfoAsync.when(
///   data: (info) => Text('Entitlements: ${info.entitlements.active.keys}'),
///   loading: () => CircularProgressIndicator(),
///   error: (e, s) => Text('Error: $e'),
/// );
/// ```
final customerInfoStreamProvider = StreamProvider<CustomerInfo>((ref) {
  final purchaseService = ref.watch(purchaseServiceProvider);
  return purchaseService.customerInfoStream;
});

/// Stream provider for real-time subscription status updates.
///
/// Emits new values when subscription status changes (sync, purchase, etc.).
///
/// Usage:
/// ```dart
/// final statusAsync = ref.watch(subscriptionStatusStreamProvider);
/// statusAsync.when(
///   data: (status) => Text('Premium: ${status.isPremium}'),
///   loading: () => CircularProgressIndicator(),
///   error: (e, s) => Text('Error: $e'),
/// );
/// ```
final subscriptionStatusStreamProvider = StreamProvider<SubscriptionStatus>((
  ref,
) {
  final purchaseService = ref.watch(purchaseServiceProvider);
  return purchaseService.subscriptionStatusStream;
});

/// Provider for the current subscription status.
///
/// Returns the user's current subscription status based on cached customer info.
/// Updates automatically when customer info or sync status changes.
///
/// Usage:
/// ```dart
/// final status = ref.watch(subscriptionStatusProvider);
/// if (status.isPremium) {
///   // Show premium features
/// }
/// ```
final subscriptionStatusProvider = Provider<SubscriptionStatus>((ref) {
  // Watch streams to trigger updates when status changes
  ref.watch(customerInfoStreamProvider);
  ref.watch(subscriptionStatusStreamProvider);

  final purchaseService = ref.watch(purchaseServiceProvider);
  return purchaseService.getSubscriptionStatus();
});

/// Provider for syncing subscription status with backend.
///
/// Returns a Future that resolves to the synced subscription status.
/// Useful for triggering manual sync or getting latest status.
///
/// Usage:
/// ```dart
/// // Trigger sync
/// final status = await ref.read(syncSubscriptionStatusProvider.future);
///
/// // Or use with FutureProvider refresh
/// ref.invalidate(syncSubscriptionStatusProvider);
/// ```
final syncSubscriptionStatusProvider = FutureProvider<SubscriptionStatus>((
  ref,
) async {
  final purchaseService = ref.watch(purchaseServiceProvider);
  return purchaseService.syncSubscriptionStatus();
});

/// Provider for checking if the user has premium access.
///
/// Convenience provider for simple premium checks.
///
/// Usage:
/// ```dart
/// final isPremium = ref.watch(isPremiumProvider);
/// if (isPremium) {
///   // Show premium content
/// }
/// ```
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionStatusProvider.select((s) => s.isPremium));
});

/// Provider for checking if the user has remove ads access.
///
/// Returns true if the user has premium subscription or
/// has purchased the one-time remove ads product.
///
/// Usage:
/// ```dart
/// final hasRemoveAds = ref.watch(hasRemoveAdsProvider);
/// if (!hasRemoveAds) {
///   // Show ads
/// }
/// ```
final hasRemoveAdsProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionStatusProvider.select((s) => s.hasRemoveAds));
});

/// Provider for checking if the user is in a trial period.
///
/// Usage:
/// ```dart
/// final isTrialActive = ref.watch(isTrialActiveProvider);
/// if (isTrialActive) {
///   // Show trial badge or countdown
/// }
/// ```
final isTrialActiveProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionStatusProvider.select((s) => s.isTrialActive));
});
