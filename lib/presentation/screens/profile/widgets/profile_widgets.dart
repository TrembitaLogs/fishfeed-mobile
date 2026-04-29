import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/widgets/common/app_button.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';
import 'package:fishfeed/presentation/widgets/common/app_text_field.dart';
import 'package:fishfeed/presentation/widgets/common/image_picker_button.dart';

/// Avatar section with image picker overlay and optional remove button.
class ProfileAvatarSection extends StatelessWidget {
  const ProfileAvatarSection({
    super.key,
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
class ProfileNicknameSection extends StatelessWidget {
  const ProfileNicknameSection({
    super.key,
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
class ProfileErrorBanner extends StatelessWidget {
  const ProfileErrorBanner({
    super.key,
    required this.error,
    required this.onDismiss,
  });

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
///
/// Reads premium / remove-ads state from RevenueCat via Riverpod providers
/// (the same source the [PremiumBadge] uses), not from `User.subscriptionStatus`
/// returned by the backend. The backend value lags the RC → backend webhook by
/// a few seconds after a purchase, so reading from there caused the upgrade CTA
/// to keep showing right after a successful payment (sandbox issue #12).
class ProfileQuickActionsSection extends ConsumerWidget {
  const ProfileQuickActionsSection({
    super.key,
    required this.onShareProfile,
    required this.onViewPremium,
  });

  final VoidCallback onShareProfile;
  final VoidCallback onViewPremium;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = ref.watch(isPremiumProvider);
    final hasRemoveAds = ref.watch(hasRemoveAdsProvider);

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
