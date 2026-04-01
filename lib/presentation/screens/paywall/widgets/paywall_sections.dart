import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/widgets/paywall/benefit_item.dart';
import 'package:fishfeed/presentation/widgets/paywall/product_card.dart';
import 'package:fishfeed/presentation/widgets/paywall/remove_ads_card.dart';

/// Hero section with premium badge and headline.
class PaywallHeroSection extends StatelessWidget {
  const PaywallHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
}

/// Benefits list section.
class PaywallBenefitsList extends StatelessWidget {
  const PaywallBenefitsList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
}

/// Product options section showing available packages.
class PaywallProductOptions extends StatelessWidget {
  const PaywallProductOptions({
    super.key,
    required this.offerings,
    required this.selectedPackage,
    required this.selectedFallbackPlan,
    required this.onPackageSelected,
    required this.onFallbackPlanSelected,
  });

  final Offerings? offerings;
  final Package? selectedPackage;
  final String selectedFallbackPlan;
  final ValueChanged<Package> onPackageSelected;
  final ValueChanged<String> onFallbackPlanSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final current = offerings?.current;

    if (current == null) {
      return _buildFallbackProducts(context, theme, l);
    }

    final packages = <Package>[];
    if (current.monthly != null) packages.add(current.monthly!);
    if (current.annual != null) packages.add(current.annual!);

    if (packages.isEmpty) {
      return _buildFallbackProducts(context, theme, l);
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
        ...packages.map(
          (package) => _buildPackageCard(context, package, theme),
        ),
      ],
    );
  }

  Widget _buildPackageCard(
    BuildContext context,
    Package package,
    ThemeData theme,
  ) {
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
        isSelected: selectedPackage == package,
        onTap: () => onPackageSelected(package),
      ),
    );
  }

  Widget _buildFallbackProducts(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l,
  ) {
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
          isSelected: selectedFallbackPlan == 'monthly',
          onTap: () => onFallbackPlanSelected('monthly'),
        ),
        const SizedBox(height: 12),
        ProductCard(
          title: l.paywallAnnual,
          price: '\$29.99/year',
          subtitle: l.paywallPerMonth('2.50'),
          badge: l.paywallBestValue,
          savings: l.paywallSavePercent(37),
          isSelected: selectedFallbackPlan == 'annual',
          onTap: () => onFallbackPlanSelected('annual'),
        ),
      ],
    );
  }
}

/// Error banner for displaying purchase errors.
class PaywallErrorBanner extends StatelessWidget {
  const PaywallErrorBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              message,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDismiss,
            color: theme.colorScheme.onErrorContainer,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// CTA button for starting purchase.
class PaywallCtaButton extends StatelessWidget {
  const PaywallCtaButton({
    super.key,
    required this.isPurchasing,
    required this.isRestoring,
    required this.hasSelection,
    required this.onPurchase,
  });

  final bool isPurchasing;
  final bool isRestoring;
  final bool hasSelection;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final isLoading = isPurchasing || isRestoring;

    return FilledButton(
      onPressed: isLoading || !hasSelection ? null : onPurchase,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isPurchasing
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
}

/// Remove Ads alternative section.
class PaywallRemoveAdsSection extends StatelessWidget {
  const PaywallRemoveAdsSection({
    super.key,
    required this.price,
    required this.isLoading,
    required this.onPurchase,
  });

  final String price;
  final bool isLoading;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

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
        RemoveAdsCard(price: price, isLoading: isLoading, onTap: onPurchase),
      ],
    );
  }
}

/// Terms and restore section at the bottom.
class PaywallTermsAndRestore extends StatelessWidget {
  const PaywallTermsAndRestore({
    super.key,
    required this.isRestoring,
    required this.onRestore,
    required this.onOpenUrl,
  });

  final bool isRestoring;
  final VoidCallback onRestore;
  final void Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          onPressed: isRestoring ? null : onRestore,
          child: isRestoring
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
              onPressed: () => onOpenUrl('https://fishfeed.club/terms'),
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
              onPressed: () => onOpenUrl('https://fishfeed.club/privacy'),
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
