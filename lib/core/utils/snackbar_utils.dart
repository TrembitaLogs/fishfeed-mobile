import 'package:flutter/material.dart';

/// Utility functions for displaying snackbars throughout the application.
///
/// Provides consistent styling for error and success messages.
class SnackbarUtils {
  SnackbarUtils._();

  /// Shows an error snackbar with red background.
  ///
  /// Duration: 4 seconds.
  /// Includes an 'OK' action button for dismissal.
  static void showError(
    BuildContext context,
    String message, {
    String actionLabel = 'OK',
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: colorScheme.onError)),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: actionLabel,
          textColor: colorScheme.onError,
          // Flutter dismisses the snackbar automatically when an action is
          // tapped — no manual hideCurrentSnackBar needed (and calling it via
          // ScaffoldMessenger.of(context) crashes if context is unmounted).
          onPressed: () {},
        ),
      ),
    );
  }

  /// Shows a success snackbar with green background.
  ///
  /// Duration: 2 seconds.
  /// Includes an 'OK' action button for dismissal.
  static void showSuccess(
    BuildContext context,
    String message, {
    String actionLabel = 'OK',
  }) {
    const successColor = Color(0xFF4CAF50);
    const onSuccessColor = Colors.white;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: onSuccessColor)),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: actionLabel,
          textColor: onSuccessColor,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Shows an info snackbar with primary color background.
  ///
  /// Duration: 3 seconds.
  /// Includes an 'OK' action button for dismissal.
  static void showInfo(
    BuildContext context,
    String message, {
    String actionLabel = 'OK',
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: colorScheme.onPrimary)),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: actionLabel,
          textColor: colorScheme.onPrimary,
          onPressed: () {},
        ),
      ),
    );
  }
}
