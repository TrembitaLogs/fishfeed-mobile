import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fishfeed/core/core.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/widgets/premium/premium_badge.dart';

/// Settings screen with user preferences and subscription management.
///
/// Includes:
/// - Subscription status and management
/// - Restore purchases option
/// - App settings
/// - Account management
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isRestoringPurchases = false;
  String _appVersion = '';
  final InAppReview _inAppReview = InAppReview.instance;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    }
  }

  Future<void> _requestReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      } else {
        await _inAppReview.openStoreListing(
          appStoreId: '6742628065',
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        SnackbarUtils.showError(context, l10n.couldNotOpenAppStore);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ref.watch(subscriptionStatusProvider);
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // Subscription section
          _SectionHeader(title: l10n.settingsSubscriptionSection),
          _SubscriptionTile(
            status: status,
            onTap: () => context.push('/paywall'),
          ),
          _RestorePurchasesTile(
            isLoading: _isRestoringPurchases,
            onTap: _restorePurchases,
          ),
          const Divider(height: 32),

          // App settings section
          _SectionHeader(title: l10n.settingsAppSection),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: l10n.notificationsSettingsTitle,
            subtitle: l10n.settingsNotificationsSubtitle,
            onTap: () => context.push('/settings/notifications'),
          ),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: l10n.appearance,
            subtitle: l10n.settingsAppearanceSubtitle,
            onTap: () => context.push('/settings/appearance'),
          ),
          const Divider(height: 32),

          // Account section
          _SectionHeader(title: l10n.settingsAccountSection),
          _SettingsTile(
            icon: Icons.person_outline,
            title: l10n.profile,
            subtitle: user?.email ?? '',
            onTap: () => context.push('/profile'),
          ),
          _SettingsTile(
            icon: Icons.family_restroom,
            title: l10n.familyMode,
            subtitle: l10n.settingsFamilySubtitle,
            onTap: () => context.push('/family/default?name=My%20Aquarium'),
          ),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            title: l10n.deleteAccountTitle,
            subtitle: l10n.settingsDeleteAccountSubtitle,
            onTap: () => _showDeleteAccountDialog(context, ref),
          ),
          const Divider(height: 32),

          // Legal section
          _SectionHeader(title: l10n.settingsLegalSection),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.settingsPrivacyPolicy,
            subtitle: l10n.settingsPrivacyPolicySubtitle,
            onTap: () => _openUrl(context, 'https://fishfeed.app/privacy'),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: l10n.termsOfService,
            subtitle: l10n.settingsTermsSubtitle,
            onTap: () => _openUrl(context, 'https://fishfeed.app/terms'),
          ),
          _SettingsTile(
            icon: Icons.article_outlined,
            title: l10n.settingsLicenses,
            subtitle: l10n.settingsLicensesSubtitle,
            onTap: () => _showLicenses(context),
          ),
          const Divider(height: 32),

          // Support section
          _SectionHeader(title: l10n.settingsSupportSection),
          _SettingsTile(
            icon: Icons.mail_outlined,
            title: l10n.settingsContactSupport,
            subtitle: l10n.settingsContactSupportSubtitle,
            onTap: () => _openUrl(context, 'mailto:support@fishfeed.app'),
          ),
          _SettingsTile(
            icon: Icons.star_outline,
            title: l10n.settingsRateApp,
            subtitle: l10n.settingsRateAppSubtitle,
            onTap: _requestReview,
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: l10n.settingsAppVersion,
            subtitle: _appVersion.isNotEmpty ? _appVersion : l10n.loading,
          ),
          const SizedBox(height: 32),

          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: Text(l10n.logout),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _restorePurchases() async {
    setState(() => _isRestoringPurchases = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      final purchaseService = ref.read(purchaseServiceProvider);
      final result = await purchaseService.restorePurchases();

      if (!mounted) return;

      result.fold(
        (failure) {
          SnackbarUtils.showError(context, failure.message ?? l10n.failedToRestorePurchases);
        },
        (customerInfo) {
          final hasActiveEntitlements = customerInfo.entitlements.active.isNotEmpty;
          if (hasActiveEntitlements) {
            SnackbarUtils.showSuccess(context, l10n.purchasesRestoredSuccess);
          } else {
            SnackbarUtils.showInfo(context, l10n.noPreviousPurchases);
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, l10n.failedToRestorePurchases);
    } finally {
      if (mounted) {
        setState(() => _isRestoringPurchases = false);
      }
    }
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final l10n = AppLocalizations.of(context)!;
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        SnackbarUtils.showError(context, l10n.couldNotOpenLink);
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarUtils.showError(context, l10n.couldNotOpenLink);
      }
    }
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'FishFeed',
      applicationVersion: '1.0.0',
      applicationIcon: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          Icons.pets,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext dialogContext, WidgetRef ref) async {
    final theme = Theme.of(dialogContext);
    final errorColor = theme.colorScheme.error;
    final onErrorColor = theme.colorScheme.onError;
    final l10n = AppLocalizations.of(dialogContext)!;

    // Step 1: Initial confirmation
    final firstConfirm = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: errorColor,
            ),
            child: Text(l10n.continueButton),
          ),
        ],
      ),
    );

    if (firstConfirm != true || !mounted || !dialogContext.mounted) return;

    // Step 2: Final confirmation with explicit text
    final secondConfirm = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: errorColor,
            ),
            const SizedBox(width: 8),
            Text(l10n.deleteAccountConfirm),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.deleteAccountWillDelete,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('• ${l10n.deleteAccountDataAquariums}'),
            Text('• ${l10n.deleteAccountDataHistory}'),
            Text('• ${l10n.deleteAccountDataAccount}'),
            const SizedBox(height: 16),
            Text(
              l10n.deleteAccountIrreversible,
              style: TextStyle(
                color: errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: onErrorColor,
            ),
            child: Text(l10n.deleteMyAccount),
          ),
        ],
      ),
    );

    if (secondConfirm != true || !mounted) return;

    // Execute account deletion
    // TODO: Call actual delete account API when available
    if (dialogContext.mounted) {
      SnackbarUtils.showInfo(dialogContext, l10n.accountDeletionNotImplemented);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

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

class _SubscriptionTile extends StatelessWidget {
  const _SubscriptionTile({
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
          final daysLeft = status.expirationDate!.difference(DateTime.now()).inDays;
          subtitle = l10n.subscriptionTrialEndsIn(daysLeft);
        }
      } else if (status.expirationDate != null) {
        final formattedDate = DateFormat.yMMMd(locale).format(status.expirationDate!);
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

class _RestorePurchasesTile extends StatelessWidget {
  const _RestorePurchasesTile({
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
        child: Icon(
          Icons.restore,
          color: theme.colorScheme.onSurfaceVariant,
        ),
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
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
        child: Icon(
          icon,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            )
          : null,
      onTap: onTap,
    );
  }
}
