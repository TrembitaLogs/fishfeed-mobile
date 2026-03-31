import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/screens/paywall/widgets/paywall_sections.dart';
import 'package:fishfeed/presentation/widgets/paywall/trial_banner.dart';
import 'package:fishfeed/services/analytics/analytics_service.dart';

/// Paywall screen for displaying premium subscription options.
///
/// Shows:
/// - Premium badge and headline
/// - List of premium benefits
/// - Monthly and annual subscription options
/// - Free trial CTA
/// - Restore purchases link
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.source = PaywallSource.settings});

  /// Source that triggered the paywall display.
  final PaywallSource source;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Offerings? _offerings;
  Package? _selectedPackage;
  Package? _removeAdsPackage;
  bool _isLoadingOfferings = true;
  bool _isPurchasing = false;
  bool _isPurchasingRemoveAds = false;
  bool _isRestoring = false;
  String? _errorMessage;
  bool _purchaseCompleted = false;
  String _selectedFallbackPlan = 'monthly';

  @override
  void initState() {
    super.initState();
    // Track paywall shown
    AnalyticsService.instance.trackPaywallShown(source: widget.source);
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _isLoadingOfferings = true;
      _errorMessage = null;
    });

    final purchaseService = ref.read(purchaseServiceProvider);

    // Load offerings and remove ads package in parallel
    final results = await Future.wait([
      purchaseService.getOfferings(),
      purchaseService.getRemoveAdsPackage(),
    ]);

    if (!mounted) return;

    final offeringsResult = results[0];
    final removeAdsResult = results[1];

    offeringsResult.fold(
      (failure) {
        setState(() {
          _isLoadingOfferings = false;
          _errorMessage =
              failure.message ??
              AppLocalizations.of(context)!.paywallFailedToLoadProducts;
        });
      },
      (offerings) {
        setState(() {
          _isLoadingOfferings = false;
          _offerings = offerings as Offerings;
          // Auto-select annual package if available (best value)
          final current = _offerings!.current;
          if (current != null) {
            _selectedPackage = current.annual ?? current.monthly;
          }
        });
      },
    );

    // Load remove ads package (don't fail if not available)
    removeAdsResult.fold(
      (failure) {
        // Remove ads package not available, that's okay
        setState(() {
          _removeAdsPackage = null;
        });
      },
      (package) {
        setState(() {
          _removeAdsPackage = package as Package;
        });
      },
    );
  }

  Future<void> _purchaseSelectedPackage() async {
    if (_selectedPackage == null) return;

    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    final purchaseService = ref.read(purchaseServiceProvider);
    final result = await purchaseService.purchasePackage(_selectedPackage!);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isPurchasing = false;
          // Don't show error for user cancellation
          if (failure.message != 'Purchase cancelled') {
            _errorMessage = failure.message ?? 'Purchase failed';
          }
        });
      },
      (customerInfo) {
        setState(() {
          _isPurchasing = false;
          _purchaseCompleted = true;
        });
        // Track subscription started
        final package = _selectedPackage!;
        final isAnnual = package.packageType == PackageType.annual;
        AnalyticsService.instance.trackSubscriptionStarted(
          plan: isAnnual ? 'annual' : 'monthly',
          price: package.storeProduct.price,
          currency: package.storeProduct.currencyCode,
        );
        _showSuccessAndClose();
      },
    );
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });

    final purchaseService = ref.read(purchaseServiceProvider);
    final result = await purchaseService.restorePurchases();

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isRestoring = false;
          _errorMessage = failure.message ?? 'Failed to restore purchases';
        });
      },
      (customerInfo) {
        setState(() => _isRestoring = false);

        final activeEntitlements = customerInfo.entitlements.active;

        // Check if user now has premium or remove_ads
        if (activeEntitlements.containsKey('premium')) {
          _showSuccessAndClose();
        } else if (activeEntitlements.containsKey('remove_ads')) {
          _showRemoveAdsSuccessAndClose();
        } else {
          _showNoRestorableMessage();
        }
      },
    );
  }

  Future<void> _purchaseRemoveAds() async {
    if (_removeAdsPackage == null) return;

    setState(() {
      _isPurchasingRemoveAds = true;
      _errorMessage = null;
    });

    final purchaseService = ref.read(purchaseServiceProvider);
    final result = await purchaseService.purchasePackage(_removeAdsPackage!);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isPurchasingRemoveAds = false;
          // Don't show error for user cancellation
          if (failure.message != 'Purchase cancelled') {
            _errorMessage = failure.message ?? 'Purchase failed';
          }
        });
      },
      (customerInfo) {
        setState(() {
          _isPurchasingRemoveAds = false;
          _purchaseCompleted = true;
        });
        // Track remove ads purchase
        final price = _removeAdsPackage?.storeProduct.price;
        final currency = _removeAdsPackage?.storeProduct.currencyCode;
        AnalyticsService.instance.trackRemoveAdsPurchase(
          price: price,
          currency: currency,
        );
        _showRemoveAdsSuccessAndClose();
      },
    );
  }

  void _handleDismiss() {
    // Only track dismissal if no purchase was completed
    if (!_purchaseCompleted) {
      AnalyticsService.instance.trackPaywallDismissed(source: widget.source);
    }
    context.pop();
  }

  void _showSuccessAndClose() {
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.welcomeToPremium),
        backgroundColor: Colors.green,
      ),
    );
    context.pop();
  }

  void _showRemoveAdsSuccessAndClose() {
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.adsRemovedSuccessfully),
        backgroundColor: Colors.green,
      ),
    );
    context.pop();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.couldNotOpenLink),
          ),
        );
      }
    }
  }

  void _showNoRestorableMessage() {
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.noPreviousPurchases)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handleDismiss,
        ),
        title: Text(l.premium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoadingOfferings
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PaywallHeroSection(),
                  const SizedBox(height: 24),
                  const TrialBanner(),
                  const SizedBox(height: 24),
                  const PaywallBenefitsList(),
                  const SizedBox(height: 24),
                  PaywallProductOptions(
                    offerings: _offerings,
                    selectedPackage: _selectedPackage,
                    selectedFallbackPlan: _selectedFallbackPlan,
                    onPackageSelected: (package) =>
                        setState(() => _selectedPackage = package),
                    onFallbackPlanSelected: (plan) =>
                        setState(() => _selectedFallbackPlan = plan),
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    PaywallErrorBanner(
                      message: _errorMessage!,
                      onDismiss: () => setState(() => _errorMessage = null),
                    ),
                    const SizedBox(height: 16),
                  ],
                  PaywallCtaButton(
                    isPurchasing: _isPurchasing,
                    isRestoring: _isRestoring,
                    hasSelection:
                        _selectedPackage != null || _offerings?.current == null,
                    onPurchase: _purchaseSelectedPackage,
                  ),
                  const SizedBox(height: 24),
                  if (_removeAdsPackage != null) ...[
                    PaywallRemoveAdsSection(
                      price:
                          _removeAdsPackage?.storeProduct.priceString ??
                          '\$3.99',
                      isLoading: _isPurchasingRemoveAds,
                      onPurchase: _purchaseRemoveAds,
                    ),
                    const SizedBox(height: 24),
                  ],
                  PaywallTermsAndRestore(
                    isRestoring: _isRestoring,
                    onRestore: _restorePurchases,
                    onOpenUrl: _openUrl,
                  ),
                ],
              ),
            ),
    );
  }
}
