import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/widgets/paywall/benefit_item.dart';
import 'package:fishfeed/presentation/widgets/paywall/product_card.dart';
import 'package:fishfeed/presentation/widgets/paywall/remove_ads_card.dart';
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

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
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
    final theme = Theme.of(context);
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
          : _buildContent(theme),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero section
          _buildHeroSection(theme),
          const SizedBox(height: 24),

          // Trial banner
          const TrialBanner(),
          const SizedBox(height: 24),

          // Benefits list
          _buildBenefitsList(theme),
          const SizedBox(height: 24),

          // Product options
          _buildProductOptions(theme),
          const SizedBox(height: 24),

          // Error message
          if (_errorMessage != null) ...[
            _buildErrorBanner(theme),
            const SizedBox(height: 16),
          ],

          // CTA button
          _buildCtaButton(theme),
          const SizedBox(height: 24),

          // Remove Ads alternative (if available)
          if (_removeAdsPackage != null) ...[
            _buildRemoveAdsSection(theme),
            const SizedBox(height: 24),
          ],

          // Terms and restore
          _buildTermsAndRestore(theme),
        ],
      ),
    );
  }

  Widget _buildHeroSection(ThemeData theme) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        // Premium badge
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD700).withValues(alpha: 0.3),
                const Color(0xFFFFA500).withValues(alpha: 0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.workspace_premium,
            size: 56,
            color: Color(0xFFFFD700),
          ),
        ),
        const SizedBox(height: 20),

        // Headline
        Text(
          l.paywallUnlockPremium,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l.paywallSubtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBenefitsList(ThemeData theme) {
    final l = AppLocalizations.of(context)!;
    final premiumBenefits = [
      (Icons.block, l.noAds),
      (Icons.camera_enhance, l.paywallUnlimitedAiScans),
      (Icons.analytics, l.paywallExtendedStatistics),
      (Icons.family_restroom, l.paywallFamilyMode),
      (Icons.water, l.paywallMultipleAquariums),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.paywallPremiumBenefits,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...premiumBenefits.map(
          (benefit) => BenefitItem(icon: benefit.$1, text: benefit.$2),
        ),
      ],
    );
  }

  Widget _buildProductOptions(ThemeData theme) {
    final l = AppLocalizations.of(context)!;
    final current = _offerings?.current;
    if (current == null) {
      return _buildFallbackProducts(theme);
    }

    final packages = <Package>[];
    if (current.monthly != null) packages.add(current.monthly!);
    if (current.annual != null) packages.add(current.annual!);

    if (packages.isEmpty) {
      return _buildFallbackProducts(theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.paywallChooseYourPlan,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...packages.map((package) => _buildPackageCard(package, theme)),
      ],
    );
  }

  Widget _buildPackageCard(Package package, ThemeData theme) {
    final l = AppLocalizations.of(context)!;
    final product = package.storeProduct;
    final isAnnual = package.packageType == PackageType.annual;
    final isMonthly = package.packageType == PackageType.monthly;

    String title;
    String? subtitle;
    String? badge;
    String? savings;

    if (isAnnual) {
      title = l.paywallAnnual;
      badge = l.paywallBestValue;
      // Calculate monthly equivalent and savings
      final annualPrice = product.price;
      final monthlyEquivalent = annualPrice / 12;
      subtitle = l.paywallPerMonth(monthlyEquivalent.toStringAsFixed(2));
      savings = l.paywallSavePercent(37);
    } else if (isMonthly) {
      title = l.paywallMonthly;
      subtitle = l.paywallMostFlexible;
    } else {
      title = product.title;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ProductCard(
        title: title,
        price: product.priceString,
        subtitle: subtitle,
        badge: badge,
        savings: savings,
        isSelected: _selectedPackage == package,
        onTap: () => setState(() => _selectedPackage = package),
      ),
    );
  }

  Widget _buildFallbackProducts(ThemeData theme) {
    final l = AppLocalizations.of(context)!;
    // Fallback UI when offerings aren't available
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.paywallChooseYourPlan,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ProductCard(
          title: l.paywallMonthly,
          price: l.paywallPerMonth('3.99'),
          subtitle: l.paywallMostFlexible,
          isSelected: _selectedFallbackPlan == 'monthly',
          onTap: () => setState(() => _selectedFallbackPlan = 'monthly'),
        ),
        const SizedBox(height: 12),
        ProductCard(
          title: l.paywallAnnual,
          price: '\$29.99/year',
          subtitle: l.paywallPerMonth('2.50'),
          badge: l.paywallBestValue,
          savings: l.paywallSavePercent(37),
          isSelected: _selectedFallbackPlan == 'annual',
          onTap: () => setState(() => _selectedFallbackPlan = 'annual'),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _errorMessage = null),
            color: theme.colorScheme.onErrorContainer,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaButton(ThemeData theme) {
    final isLoading = _isPurchasing || _isRestoring;
    final hasSelection =
        _selectedPackage != null || _offerings?.current == null;

    return FilledButton(
      onPressed: isLoading || !hasSelection ? null : _purchaseSelectedPackage,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isPurchasing
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.card_giftcard),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.paywallStartFreeTrial,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRemoveAdsSection(ThemeData theme) {
    final l = AppLocalizations.of(context)!;
    final price = _removeAdsPackage?.storeProduct.priceString ?? '\$3.99';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Divider with "or" text
        Row(
          children: [
            Expanded(
              child: Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l.paywallOr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Remove Ads card
        RemoveAdsCard(
          price: price,
          isLoading: _isPurchasingRemoveAds,
          onTap: _purchaseRemoveAds,
        ),
      ],
    );
  }

  Widget _buildTermsAndRestore(ThemeData theme) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        // Trial terms
        Text(
          l.paywallTrialTerms,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Restore purchases link
        TextButton(
          onPressed: _isRestoring ? null : _restorePurchases,
          child: _isRestoring
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  l.restorePurchases,
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
        ),

        // Links to terms and privacy
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => _openUrl(context, 'https://fishfeed.club/terms'),
              child: Text(
                l.termsOfService,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(
              ' | ',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            TextButton(
              onPressed: () =>
                  _openUrl(context, 'https://fishfeed.club/privacy'),
              child: Text(
                l.privacyPolicy,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
