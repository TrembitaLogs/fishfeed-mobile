import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/core/utils/premium_gate.dart';
import 'package:fishfeed/l10n/app_localizations.dart';

/// A wrapper widget that guards premium features.
///
/// Shows the child content if the user has access to the feature,
/// or shows a locked overlay with upgrade CTA if not.
class PremiumFeatureGuard extends ConsumerWidget {
  const PremiumFeatureGuard({
    super.key,
    required this.feature,
    required this.child,
    this.lockedChild,
    this.showBlur = true,
    this.blurSigma = 5.0,
    this.showLockIcon = true,
    this.showUpgradeButton = true,
    this.onUpgradeTap,
  });

  /// The premium feature to check.
  final PremiumFeature feature;

  /// The content to show when feature is unlocked.
  final Widget child;

  /// Optional widget to show when locked (shown behind blur).
  /// If not provided, [child] is shown with blur overlay.
  final Widget? lockedChild;

  /// Whether to blur the content when locked.
  final bool showBlur;

  /// The blur sigma value.
  final double blurSigma;

  /// Whether to show a lock icon overlay.
  final bool showLockIcon;

  /// Whether to show an upgrade button.
  final bool showUpgradeButton;

  /// Custom callback when upgrade is tapped.
  /// If not provided, navigates to /paywall.
  final VoidCallback? onUpgradeTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(featureAccessProvider(feature));

    if (hasAccess) {
      return child;
    }

    return _buildLockedOverlay(context);
  }

  Widget _buildLockedOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final contentToShow = lockedChild ?? child;

    return Stack(
      children: [
        if (showBlur)
          ClipRect(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: blurSigma,
                sigmaY: blurSigma,
              ),
              child: contentToShow,
            ),
          )
        else
          Opacity(opacity: 0.5, child: contentToShow),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.3),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showLockIcon) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.amber.shade200,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 32,
                        color: Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    feature.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.premiumFeature,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (showUpgradeButton) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _handleUpgradeTap(context),
                      icon: const Icon(Icons.workspace_premium, size: 18),
                      label: Text(l.upgrade),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleUpgradeTap(BuildContext context) {
    if (onUpgradeTap != null) {
      onUpgradeTap!();
    } else {
      context.push('/paywall');
    }
  }
}

/// A simpler locked overlay without the blur effect.
///
/// Shows a semi-transparent overlay with lock icon and upgrade CTA.
class LockedFeatureOverlay extends StatelessWidget {
  const LockedFeatureOverlay({
    super.key,
    required this.feature,
    this.onUpgradeTap,
    this.compact = false,
  });

  /// The premium feature that's locked.
  final PremiumFeature feature;

  /// Custom callback when upgrade is tapped.
  final VoidCallback? onUpgradeTap;

  /// Whether to use compact layout.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return _buildCompactOverlay(context, theme);
    }

    return _buildFullOverlay(context, theme);
  }

  Widget _buildCompactOverlay(BuildContext context, ThemeData theme) {
    final l = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 16, color: Colors.amber.shade800),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l.upgradeToUnlock(feature.displayName),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.amber.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.amber.shade800,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullOverlay(BuildContext context, ThemeData theme) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline,
              size: 32,
              color: Colors.amber.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            feature.displayName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feature.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleTap(context),
              icon: const Icon(Icons.workspace_premium),
              label: Text(l.upgradeToPremium),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (onUpgradeTap != null) {
      onUpgradeTap!();
    } else {
      context.push('/paywall');
    }
  }
}
