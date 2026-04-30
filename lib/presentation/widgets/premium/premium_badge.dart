import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';

/// A badge widget displaying the user's subscription status.
///
/// Shows "Premium" with a crown icon for premium users,
/// or "Free" for free tier users.
class PremiumBadge extends ConsumerWidget {
  const PremiumBadge({
    super.key,
    this.size = PremiumBadgeSize.medium,
    this.showLabel = true,
    this.onTap,
  });

  /// Size variant of the badge.
  final PremiumBadgeSize size;

  /// Whether to show the text label.
  final bool showLabel;

  /// Optional callback when badge is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(subscriptionStatusProvider);
    final isPremium = status.isPremium;
    final isTrialActive = status.isTrialActive;

    // Premium / trial users already have the entitlement — tapping the badge
    // should not reopen the paywall. Free users keep the conversion CTA.
    final effectiveOnTap = isPremium ? null : onTap;

    return GestureDetector(
      onTap: effectiveOnTap,
      child: _buildBadge(context, isPremium, isTrialActive),
    );
  }

  Widget _buildBadge(BuildContext context, bool isPremium, bool isTrialActive) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final dimensions = _getDimensions(size);

    final Color backgroundColor;
    final Color foregroundColor;
    final Color borderColor;
    final IconData icon;
    final String label;

    if (isPremium) {
      if (isTrialActive) {
        backgroundColor = Colors.purple.shade50;
        foregroundColor = Colors.purple.shade700;
        borderColor = Colors.purple.shade200;
        icon = Icons.hourglass_top;
        label = l.trial;
      } else {
        backgroundColor = Colors.amber.shade50;
        foregroundColor = Colors.amber.shade800;
        borderColor = Colors.amber.shade200;
        icon = Icons.workspace_premium;
        label = l.premium;
      }
    } else {
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
      foregroundColor = theme.colorScheme.onSurfaceVariant;
      borderColor = theme.colorScheme.outlineVariant;
      icon = Icons.person_outline;
      label = l.free;
    }

    return Semantics(
      label: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dimensions.horizontalPadding,
          vertical: dimensions.verticalPadding,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(dimensions.borderRadius),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: dimensions.iconSize, color: foregroundColor),
            if (showLabel) ...[
              SizedBox(width: dimensions.spacing),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.bold,
                  fontSize: dimensions.fontSize,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _BadgeDimensions _getDimensions(PremiumBadgeSize size) {
    return switch (size) {
      PremiumBadgeSize.small => const _BadgeDimensions(
        horizontalPadding: 8,
        verticalPadding: 4,
        iconSize: 14,
        fontSize: 11,
        spacing: 4,
        borderRadius: 12,
      ),
      PremiumBadgeSize.medium => const _BadgeDimensions(
        horizontalPadding: 12,
        verticalPadding: 6,
        iconSize: 18,
        fontSize: 13,
        spacing: 6,
        borderRadius: 16,
      ),
      PremiumBadgeSize.large => const _BadgeDimensions(
        horizontalPadding: 16,
        verticalPadding: 8,
        iconSize: 24,
        fontSize: 16,
        spacing: 8,
        borderRadius: 20,
      ),
    };
  }
}

/// Size variants for PremiumBadge.
enum PremiumBadgeSize {
  /// Small badge for compact displays.
  small,

  /// Medium badge for standard use (default).
  medium,

  /// Large badge for prominent displays.
  large,
}

/// Dimension configuration for badge sizes.
class _BadgeDimensions {
  const _BadgeDimensions({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.iconSize,
    required this.fontSize,
    required this.spacing,
    required this.borderRadius,
  });

  final double horizontalPadding;
  final double verticalPadding;
  final double iconSize;
  final double fontSize;
  final double spacing;
  final double borderRadius;
}

/// Standalone badge that doesn't depend on Riverpod.
///
/// Useful for testing or when you already have the subscription status.
class PremiumBadgeStatic extends StatelessWidget {
  const PremiumBadgeStatic({
    super.key,
    required this.status,
    this.size = PremiumBadgeSize.medium,
    this.showLabel = true,
    this.onTap,
  });

  /// The subscription status to display.
  final SubscriptionStatus status;

  /// Size variant of the badge.
  final PremiumBadgeSize size;

  /// Whether to show the text label.
  final bool showLabel;

  /// Optional callback when badge is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumBadge(size: size, showLabel: showLabel, onTap: onTap);
  }
}
