import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/widgets/premium/premium_badge.dart';

/// Section header for the settings screen.
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Subscription status tile showing current plan and upgrade option.
class SettingsSubscriptionTile extends StatelessWidget {
  const SettingsSubscriptionTile({
    super.key,
    required this.status,
    required this.onTap,
  });

  final SubscriptionStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    String subtitle;
    if (status.isPremium) {
      if (status.isTrialActive) {
        subtitle = l10n.subscriptionTrialActive;
        if (status.expirationDate != null) {
          final daysLeft = status.expirationDate!
              .difference(DateTime.now())
              .inDays;
          subtitle = l10n.subscriptionTrialEndsIn(daysLeft);
        }
      } else if (status.expirationDate != null) {
        final formattedDate = DateFormat.yMMMd(
          locale,
        ).format(status.expirationDate!);
        subtitle = status.willRenew
            ? l10n.subscriptionRenewsOn(formattedDate)
            : l10n.subscriptionExpiresOn(formattedDate);
      } else {
        subtitle = l10n.subscriptionActive;
      }
    } else if (status.hasRemoveAds) {
      subtitle = l10n.subscriptionAdsRemoved;
    } else {
      subtitle = l10n.subscriptionFreePlan;
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: status.isPremium
              ? Colors.amber.shade50
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          status.isPremium ? Icons.workspace_premium : Icons.star_border,
          color: status.isPremium
              ? Colors.amber.shade800
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Row(
        children: [
          Text(l10n.settingsSubscriptionSection),
          const SizedBox(width: 8),
          const PremiumBadge(size: PremiumBadgeSize.small, showLabel: false),
        ],
      ),
      subtitle: Text(subtitle),
      trailing: status.isPremium
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                l10n.upgrade,
                style: TextStyle(
                  color: Colors.amber.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
      onTap: onTap,
    );
  }
}

/// Restore purchases tile with loading indicator.
class SettingsRestorePurchasesTile extends StatelessWidget {
  const SettingsRestorePurchasesTile({
    super.key,
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.restore, color: theme.colorScheme.onSurfaceVariant),
      ),
      title: Text(l10n.restorePurchases),
      subtitle: Text(l10n.restorePurchasesSubtitle),
      trailing: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: isLoading ? null : onTap,
    );
  }
}

/// Generic settings tile with icon, title, subtitle, and optional onTap.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant)
          : null,
      onTap: onTap,
    );
  }
}
