import 'package:flutter/material.dart';

import 'package:fishfeed/core/errors/error_code_localizer.dart';
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
  /// Resolution order:
  /// 1. Backend `error_code` (preferred — stable, mapped to localized strings)
  /// 2. Custom message on the failure (validation details, OAuth provider)
  /// 3. Default localized message per failure type
  String _mapFailureToMessage(Failure failure) {
    final l10n = AppLocalizations.of(this);

    // If l10n is not available, return the failure message or default
    if (l10n == null) {
      return failure.message ?? 'An error occurred';
    }

    // Prefer the localized message tied to the backend error_code.
    final localizedFromCode = localizeApiErrorCode(failure.apiErrorCode, l10n);
    if (localizedFromCode != null) {
      return localizedFromCode;
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
      ConflictFailure() => l10n.errorUnexpected,
      NotFoundFailure() => l10n.errorUnexpected,
      RateLimitFailure() => l10n.errorTooManyRequests,
      OAuthFailure(:final provider) => _formatOAuthError(provider, l10n),
      CancellationFailure() => l10n.errorOperationCancelled,
      CacheFailure() => l10n.errorLocalStorage,
      UnexpectedFailure() => l10n.errorUnexpected,
      PurchaseFailure(:final message) => message ?? l10n.errorUnexpected,
      PurchaseCancelledFailure() => l10n.errorOperationCancelled,
      ProductNotAvailableFailure() => l10n.errorUnexpected,
      ProductAlreadyOwnedFailure() => l10n.errorUnexpected,
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
      ConflictFailure(:final message) =>
        message ?? 'Conflict with current state.',
      NotFoundFailure(:final message) => message ?? 'Resource not found.',
      RateLimitFailure() => 'Too many requests. Please wait and try again.',
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
      ProductAlreadyOwnedFailure(:final productId) =>
        'Product ${productId ?? ''} is already owned by this account.',
      PurchaseNotInitializedFailure() =>
        'Purchase service not initialized. Please restart the app.',
    };
  }
}
