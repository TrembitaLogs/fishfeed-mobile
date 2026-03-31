import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fishfeed/core/core.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/screens/settings/widgets/settings_tiles.dart';

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
        await _inAppReview.openStoreListing(appStoreId: '6742628065');
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
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          // Subscription section
          SettingsSectionHeader(title: l10n.settingsSubscriptionSection),
          SettingsSubscriptionTile(
            status: status,
            onTap: () => context.push('/paywall'),
          ),
          SettingsRestorePurchasesTile(
            isLoading: _isRestoringPurchases,
            onTap: _restorePurchases,
          ),
          const Divider(height: 32),

          // App settings section
          SettingsSectionHeader(title: l10n.settingsAppSection),
          SettingsTile(
            icon: Icons.notifications_outlined,
            title: l10n.notificationsSettingsTitle,
            subtitle: l10n.settingsNotificationsSubtitle,
            onTap: () => context.push('/settings/notifications'),
          ),
          SettingsTile(
            icon: Icons.palette_outlined,
            title: l10n.appearance,
            subtitle: l10n.settingsAppearanceSubtitle,
            onTap: () => context.push('/settings/appearance'),
          ),
          const Divider(height: 32),

          // Account section
          SettingsSectionHeader(title: l10n.settingsAccountSection),
          SettingsTile(
            icon: Icons.person_outline,
            title: l10n.profile,
            subtitle: user?.email ?? '',
            onTap: () => context.push('/profile'),
          ),
          SettingsTile(
            icon: Icons.family_restroom,
            title: l10n.familyMode,
            subtitle: l10n.settingsFamilySubtitle,
            onTap: () => _openFamilyMode(context, ref),
          ),
          SettingsTile(
            icon: Icons.delete_forever_outlined,
            title: l10n.deleteAccountTitle,
            subtitle: l10n.settingsDeleteAccountSubtitle,
            onTap: () => _showDeleteAccountDialog(context, ref),
          ),
          const Divider(height: 32),

          // Legal section
          SettingsSectionHeader(title: l10n.settingsLegalSection),
          SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.settingsPrivacyPolicy,
            subtitle: l10n.settingsPrivacyPolicySubtitle,
            onTap: () => _openUrl(context, 'https://fishfeed.club/privacy'),
          ),
          SettingsTile(
            icon: Icons.description_outlined,
            title: l10n.termsOfService,
            subtitle: l10n.settingsTermsSubtitle,
            onTap: () => _openUrl(context, 'https://fishfeed.club/terms'),
          ),
          SettingsTile(
            icon: Icons.article_outlined,
            title: l10n.settingsLicenses,
            subtitle: l10n.settingsLicensesSubtitle,
            onTap: () => _showLicenses(context),
          ),
          const Divider(height: 32),

          // Support section
          SettingsSectionHeader(title: l10n.settingsSupportSection),
          SettingsTile(
            icon: Icons.mail_outlined,
            title: l10n.settingsContactSupport,
            subtitle: l10n.settingsContactSupportSubtitle,
            onTap: () => _openUrl(context, 'mailto:support@fishfeed.club'),
          ),
          SettingsTile(
            icon: Icons.star_outline,
            title: l10n.settingsRateApp,
            subtitle: l10n.settingsRateAppSubtitle,
            onTap: _requestReview,
          ),
          SettingsTile(
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

  void _openFamilyMode(BuildContext context, WidgetRef ref) {
    final aquariums = ref.read(aquariumsListProvider);

    if (aquariums.isEmpty) return;

    if (aquariums.length == 1) {
      final aq = aquariums.first;
      context.push('/family/${aq.id}?name=${Uri.encodeComponent(aq.name)}');
      return;
    }

    // Multiple aquariums — show picker dialog
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.selectAquarium),
        children: aquariums.map((aq) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              context.push(
                '/family/${aq.id}?name=${Uri.encodeComponent(aq.name)}',
              );
            },
            child: ListTile(
              leading: const Icon(Icons.water),
              title: Text(aq.name),
              contentPadding: EdgeInsets.zero,
            ),
          );
        }).toList(),
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
          SnackbarUtils.showError(
            context,
            failure.message ?? l10n.failedToRestorePurchases,
          );
        },
        (customerInfo) {
          final hasActiveEntitlements =
              customerInfo.entitlements.active.isNotEmpty;
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
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
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
      applicationVersion: _appVersion,
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

  Future<void> _showDeleteAccountDialog(
    BuildContext dialogContext,
    WidgetRef ref,
  ) async {
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
            style: TextButton.styleFrom(foregroundColor: errorColor),
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
            Icon(Icons.warning_amber_rounded, color: errorColor),
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
              style: TextStyle(color: errorColor, fontWeight: FontWeight.w600),
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
