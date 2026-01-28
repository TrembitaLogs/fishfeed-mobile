import 'package:flutter/material.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/services/notifications/notification_permission_service.dart';

/// A banner widget that prompts users to enable notifications.
///
/// This banner is shown when:
/// - User has declined notification permission
/// - System notification permission is permanently denied
///
/// The banner provides a call-to-action to open app settings
/// where the user can enable notifications.
class NotificationSettingsBanner extends StatelessWidget {
  const NotificationSettingsBanner({
    super.key,
    this.onEnablePressed,
    this.onDismissed,
    this.showDismissButton = true,
  });

  /// Callback when the "Enable" button is pressed.
  ///
  /// If null, defaults to opening app settings.
  final VoidCallback? onEnablePressed;

  /// Callback when the banner is dismissed.
  final VoidCallback? onDismissed;

  /// Whether to show a dismiss button.
  final bool showDismissButton;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEnablePressed ?? _openSettings,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Bell icon with slash
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_off_outlined,
                    color: theme.colorScheme.onSecondaryContainer,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.notificationsBannerTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.notificationsBannerDescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Enable button
                FilledButton.tonal(
                  onPressed: onEnablePressed ?? _openSettings,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text(l10n.notificationsBannerAction),
                ),

                // Dismiss button
                if (showDismissButton) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onDismissed,
                    icon: const Icon(Icons.close, size: 20),
                    color: theme.colorScheme.onSecondaryContainer.withValues(
                      alpha: 0.6,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await NotificationPermissionService.instance.openSettings();
  }
}

/// A compact version of the notification settings banner.
///
/// Designed for use in lists or as a list tile in settings screens.
class NotificationSettingsTile extends StatelessWidget {
  const NotificationSettingsTile({super.key, this.onTap});

  /// Callback when the tile is tapped.
  ///
  /// If null, defaults to opening app settings.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.notifications_off,
          color: theme.colorScheme.onErrorContainer,
          size: 20,
        ),
      ),
      title: Text(l10n.notificationsSettingsTitle),
      subtitle: Text(
        l10n.notificationsSettingsDisabledHint,
        style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
      ),
      trailing: TextButton(
        onPressed: onTap ?? _openSettings,
        child: Text(l10n.notificationsSettingsOpenSettings),
      ),
      onTap: onTap ?? _openSettings,
    );
  }

  Future<void> _openSettings() async {
    await NotificationPermissionService.instance.openSettings();
  }
}
