import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/profile_provider.dart';
import 'package:fishfeed/presentation/router/app_router.dart';
import 'package:fishfeed/presentation/screens/profile/widgets/profile_widgets.dart';
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
              ProfileAvatarSection(
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
              ProfileNicknameSection(
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
                ProfileErrorBanner(
                  error: profileState.error!,
                  onDismiss: () =>
                      ref.read(profileNotifierProvider.notifier).clearErrors(),
                ),

              // Quick actions
              ProfileQuickActionsSection(
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
