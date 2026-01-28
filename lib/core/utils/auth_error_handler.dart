import 'package:flutter/material.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/core/utils/snackbar_utils.dart';
import 'package:fishfeed/l10n/app_localizations.dart';

/// Extension on [BuildContext] for handling authentication errors.
///
/// Provides convenient methods to display user-friendly error messages
/// based on [Failure] types.
extension AuthErrorHandler on BuildContext {
  /// Shows an error snackbar with a user-friendly message for the given [failure].
  ///
  /// Maps [Failure] types to localized messages using [AppLocalizations].
  void showAuthError(Failure failure) {
    final message = _mapFailureToMessage(failure);
    SnackbarUtils.showError(this, message);
  }

  /// Shows a success snackbar with the given [message].
  void showAuthSuccess(String message) {
    SnackbarUtils.showSuccess(this, message);
  }

  /// Maps a [Failure] to a user-friendly localized message.
  ///
  /// If the failure has a custom message that differs from the default,
  /// the custom message is used. Otherwise, falls back to localized messages.
  String _mapFailureToMessage(Failure failure) {
    final l10n = AppLocalizations.of(this);

    // If l10n is not available, return the failure message or default
    if (l10n == null) {
      return failure.message ?? 'An error occurred';
    }

    // Check if failure has a custom message (not the default)
    // Use custom message if it was explicitly set
    if (_hasCustomMessage(failure)) {
      return failure.message!;
    }

    return switch (failure) {
      NetworkFailure() => l10n.errorNoConnection,
      ServerFailure() => l10n.errorServer,
      AuthenticationFailure() => l10n.errorInvalidCredentials,
      ValidationFailure(:final errors) => _formatValidationErrors(errors, l10n),
      OAuthFailure(:final provider) => _formatOAuthError(provider, l10n),
      CancellationFailure() => l10n.errorOperationCancelled,
      CacheFailure() => l10n.errorLocalStorage,
      UnexpectedFailure() => l10n.errorUnexpected,
      PurchaseFailure(:final message) => message ?? l10n.errorUnexpected,
      PurchaseCancelledFailure() => l10n.errorOperationCancelled,
      ProductNotAvailableFailure() => l10n.errorUnexpected,
      PurchaseNotInitializedFailure() => l10n.errorUnexpected,
    };
  }

  /// Checks if the failure has a custom message set (not the default).
  bool _hasCustomMessage(Failure failure) {
    final message = failure.message;
    if (message == null) return false;

    // Default messages from Failure classes
    const defaultMessages = {
      'No internet connection',
      'Server error occurred',
      'Authentication failed',
      'Validation failed',
      'OAuth authentication failed',
      'Operation cancelled by user',
      'Local storage error',
      'An unexpected error occurred',
    };

    return !defaultMessages.contains(message);
  }

  /// Formats validation errors into a single message.
  String _formatValidationErrors(
    Map<String, List<String>> errors,
    AppLocalizations l10n,
  ) {
    if (errors.isEmpty) {
      return l10n.errorValidation;
    }

    // Return the first error message from the first field
    final firstField = errors.entries.first;
    if (firstField.value.isNotEmpty) {
      return firstField.value.first;
    }

    return l10n.errorValidation;
  }

  /// Formats OAuth error based on provider.
  String _formatOAuthError(String? provider, AppLocalizations l10n) {
    return switch (provider) {
      'google' => l10n.errorGoogleSignIn,
      'apple' => l10n.errorAppleSignIn,
      _ => l10n.errorOAuth,
    };
  }
}

/// Utility class for mapping failures to messages without BuildContext.
///
/// Useful for logging or when context is not available.
class FailureMessageMapper {
  FailureMessageMapper._();

  /// Returns a default English message for the given [failure].
  static String toMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure() => 'No internet connection. Please check your network.',
      ServerFailure() => 'Server error. Please try again later.',
      AuthenticationFailure() => 'Invalid credentials. Please try again.',
      ValidationFailure(:final message) => message ?? 'Validation failed.',
      OAuthFailure(:final provider, :final message) =>
        message ?? 'Failed to sign in with ${provider ?? 'OAuth'}.',
      CancellationFailure() => 'Operation was cancelled.',
      CacheFailure() => 'Local storage error. Please restart the app.',
      UnexpectedFailure(:final message) =>
        message ?? 'An unexpected error occurred.',
      PurchaseFailure(:final message) => message ?? 'Purchase failed.',
      PurchaseCancelledFailure() => 'Purchase was cancelled.',
      ProductNotAvailableFailure(:final productId) =>
        'Product ${productId ?? ''} is not available.',
      PurchaseNotInitializedFailure() =>
        'Purchase service not initialized. Please restart the app.',
    };
  }
}
