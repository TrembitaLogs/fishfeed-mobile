import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/profile_provider.dart';
import 'package:fishfeed/presentation/router/app_router.dart';
import 'package:fishfeed/presentation/widgets/common/app_button.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';
import 'package:fishfeed/presentation/widgets/common/app_text_field.dart';
import 'package:fishfeed/presentation/widgets/common/image_picker_button.dart';
import 'package:fishfeed/presentation/widgets/premium/premium_badge.dart';
import 'package:fishfeed/presentation/widgets/profile/achievements_gallery.dart';
import 'package:fishfeed/presentation/widgets/profile/extended_statistics_section.dart';
import 'package:fishfeed/presentation/widgets/profile/statistics_section.dart';
import 'package:fishfeed/presentation/widgets/profile/streak_section.dart';

/// Profile screen for viewing and editing user profile information.
///
/// Features:
/// - Avatar display and editing via image picker
/// - Nickname editing with validation
/// - Subscription status badge
/// - Quick actions: Share Profile, View Premium
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isEditingNickname = false;
  String? _originalNickname;
  Timer? _autoSaveTimer;

  static const _autoSaveDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _initializeNickname();
    _nicknameController.addListener(_onNicknameChanged);
  }

  void _initializeNickname() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _nicknameController.text = user.displayName ?? '';
      _originalNickname = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _nicknameController.removeListener(_onNicknameChanged);
    _nicknameController.dispose();
    super.dispose();
  }

  void _onNicknameChanged() {
    // Trigger rebuild to show/hide save button
    setState(() {});

    // Clear any previous error when user types
    ref.read(profileNotifierProvider.notifier).clearNicknameError();

    // Schedule auto-save with debounce
    _autoSaveTimer?.cancel();
    if (_hasNicknameChanged && _isEditingNickname) {
      _autoSaveTimer = Timer(_autoSaveDelay, _autoSaveNickname);
    }
  }

  bool get _hasNicknameChanged =>
      _originalNickname != null &&
      _nicknameController.text.trim() != _originalNickname;

  Future<void> _autoSaveNickname() async {
    if (!_hasNicknameChanged) return;
    await _saveNickname(showSuccessSnackbar: true);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Update nickname controller when user changes externally
    // Remove listener temporarily to avoid triggering _onNicknameChanged during build
    if (user.displayName != _originalNickname && !_isEditingNickname) {
      _nicknameController.removeListener(_onNicknameChanged);
      _nicknameController.text = user.displayName ?? '';
      _originalNickname = user.displayName ?? '';
      _nicknameController.addListener(_onNicknameChanged);
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () => context.push(AppRouter.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar section
              _AvatarSection(
                userId: user.id,
                avatarKey: user.avatarKey,
                onImageSelected: (localKey) async {
                  await ref
                      .read(profileNotifierProvider.notifier)
                      .updateAvatarKey(localKey);
                },
                onRemoveAvatar: user.avatarKey != null
                    ? () => _removeAvatar()
                    : null,
              ),
              const SizedBox(height: 24),

              // Subscription badge
              PremiumBadge(
                size: PremiumBadgeSize.large,
                onTap: _navigateToSubscription,
              ),
              const SizedBox(height: 24),

              // Nickname section
              _NicknameSection(
                controller: _nicknameController,
                isEditing: _isEditingNickname,
                isLoading: profileState.isUpdatingNickname,
                hasChanged: _hasNicknameChanged,
                error: profileState.nicknameError,
                onEditToggle: _toggleNicknameEdit,
                onSave: () => _saveNickname(showSuccessSnackbar: true),
              ),
              const SizedBox(height: 8),

              // Email (read-only)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Streak section
              const StreakSection(),
              const SizedBox(height: 24),

              // Statistics section
              const StatisticsSection(),
              const SizedBox(height: 24),

              // Extended statistics (premium feature)
              const ExtendedStatisticsSection(),
              const SizedBox(height: 24),

              // Achievements gallery
              const AchievementsGallery(),
              const SizedBox(height: 24),

              // Error display
              if (profileState.error != null)
                _ErrorBanner(
                  error: profileState.error!,
                  onDismiss: () =>
                      ref.read(profileNotifierProvider.notifier).clearErrors(),
                ),

              // Quick actions
              _QuickActionsSection(
                onShareProfile: () =>
                    _shareProfile(user.displayName ?? user.email),
                onViewPremium: _navigateToSubscription,
                isPremium: user.subscriptionStatus.isPremium,
                hasRemoveAds: user.subscriptionStatus.hasRemoveAds,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeAvatar() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.imageDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.imageDeleteButton),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(profileNotifierProvider.notifier).updateAvatarKey(null);
    }
  }

  void _toggleNicknameEdit() {
    setState(() {
      _isEditingNickname = true;
    });
  }

  Future<void> _saveNickname({bool showSuccessSnackbar = false}) async {
    if (!_hasNicknameChanged) return;

    final trimmedNickname = _nicknameController.text.trim();
    if (trimmedNickname.isEmpty) return;

    // Cancel auto-save timer since we're saving now
    _autoSaveTimer?.cancel();

    final success = await ref
        .read(profileNotifierProvider.notifier)
        .updateNickname(trimmedNickname);

    if (success && mounted) {
      setState(() {
        _isEditingNickname = false;
        _originalNickname = trimmedNickname;
      });

      if (showSuccessSnackbar) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.nicknameUpdated),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _navigateToSubscription() {
    context.push(AppRouter.paywall);
  }

  Future<void> _shareProfile(String userName) async {
    final l10n = AppLocalizations.of(context)!;
    final shareText = l10n.shareProfileText(userName);

    try {
      await Share.share(shareText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToShareProfile),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// Avatar section with image picker overlay and optional remove button.
class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.userId,
    required this.avatarKey,
    required this.onImageSelected,
    this.onRemoveAvatar,
  });

  final String userId;
  final String? avatarKey;
  final ValueChanged<String> onImageSelected;
  final VoidCallback? onRemoveAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        ImagePickerButton(
          entityType: 'avatar',
          entityId: userId,
          onImageSelected: onImageSelected,
          child: Stack(
            children: [
              EntityImage(
                photoKey: avatarKey,
                entityType: 'avatar',
                entityId: userId,
                width: 120,
                height: 120,
                isCircular: true,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (onRemoveAvatar != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRemoveAvatar,
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: theme.colorScheme.error,
            ),
            label: Text(l10n.imageDeleteButton),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

/// Nickname editing section with auto-save.
class _NicknameSection extends StatelessWidget {
  const _NicknameSection({
    required this.controller,
    required this.isEditing,
    required this.isLoading,
    required this.hasChanged,
    required this.error,
    required this.onEditToggle,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool isEditing;
  final bool isLoading;
  final bool hasChanged;
  final String? error;
  final VoidCallback onEditToggle;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (!isEditing) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                controller.text.isEmpty
                    ? l10n.setYourNickname
                    : controller.text,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: controller.text.isEmpty
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEditToggle,
              tooltip: l10n.editNickname,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: controller,
                  hint: l10n.enterYourNickname,
                  errorText: error,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onSave(),
                ),
              ),
              if (hasChanged) ...[
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: isLoading ? null : onSave,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Error banner for displaying profile errors.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error, required this.onDismiss});

  final Failure error;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error.message ?? AppLocalizations.of(context)!.anErrorOccurred,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onDismiss,
            color: theme.colorScheme.onErrorContainer,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

/// Quick actions section with share and premium buttons.
class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({
    required this.onShareProfile,
    required this.onViewPremium,
    required this.isPremium,
    required this.hasRemoveAds,
  });

  final VoidCallback onShareProfile;
  final VoidCallback onViewPremium;
  final bool isPremium;
  final bool hasRemoveAds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Determine which upgrade button to show
    // - Premium users: no upgrade button
    // - Users with Remove Ads only: show "View Premium" to upgrade
    // - Free users: show "Remove Ads" as a simpler option
    final showUpgradeButton = !isPremium;
    final upgradeLabel = hasRemoveAds ? l10n.viewPremium : l10n.removeAds;
    final upgradeIcon = hasRemoveAds ? Icons.star : Icons.block;

    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AppButton(
              label: l10n.shareProfile,
              icon: Icons.share,
              buttonType: AppButtonType.secondary,
              onPressed: onShareProfile,
            ),
            if (showUpgradeButton)
              AppButton(
                label: upgradeLabel,
                icon: upgradeIcon,
                buttonType: AppButtonType.primary,
                onPressed: onViewPremium,
              ),
          ],
        ),
      ],
    );
  }
}
