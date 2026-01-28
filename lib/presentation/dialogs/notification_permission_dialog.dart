import 'package:flutter/material.dart';

import 'package:fishfeed/l10n/app_localizations.dart';

/// Result of the notification permission dialog.
enum NotificationPermissionDialogResult {
  /// User tapped "Enable Notifications" button.
  enable,

  /// User tapped "Later" button or dismissed the dialog.
  later,
}

/// A dialog that explains why notifications are needed and asks for permission.
///
/// This dialog should be shown before requesting the system notification
/// permission to give context to the user about why the app needs notifications.
///
/// Returns [NotificationPermissionDialogResult.enable] if the user wants to
/// proceed with the permission request, or [NotificationPermissionDialogResult.later]
/// if they want to skip for now.
class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({super.key});

  /// Shows the notification permission dialog.
  ///
  /// Returns the user's choice or [NotificationPermissionDialogResult.later]
  /// if the dialog was dismissed.
  static Future<NotificationPermissionDialogResult> show(
    BuildContext context,
  ) async {
    final result = await showDialog<NotificationPermissionDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const NotificationPermissionDialog(),
    );

    return result ?? NotificationPermissionDialogResult.later;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fish with bell icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.set_meal,
                    size: 40,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              l10n.notificationPermissionTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              l10n.notificationPermissionDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Enable button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  NotificationPermissionDialogResult.enable,
                ),
                child: Text(l10n.notificationPermissionEnable),
              ),
            ),

            const SizedBox(height: 8),

            // Later button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(
                  NotificationPermissionDialogResult.later,
                ),
                child: Text(l10n.notificationPermissionLater),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
