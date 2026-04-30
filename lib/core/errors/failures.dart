import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
///
/// Used as the Left side of Either types in use cases and repositories.
/// Failures represent expected error conditions that the app can handle gracefully.
sealed class Failure extends Equatable {
  const Failure({this.message, this.apiErrorCode});

  /// Human-readable error message (English fallback for logs / debugging).
  final String? message;

  /// Stable backend error_code (e.g. `auth.invalid_credentials`).
  ///
  /// Use this for localization mapping; falls back to per-type defaults
  /// when `null` (older backend or non-API failure).
  final String? apiErrorCode;

  @override
  List<Object?> get props => [message, apiErrorCode];
}

/// Failure due to network connectivity issues.
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection'});
}

/// Failure due to server-side errors.
class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Server error occurred',
    super.apiErrorCode,
  });
}

/// Failure due to invalid credentials or expired session.
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    super.message = 'Authentication failed',
    super.apiErrorCode,
  });
}

/// Failure due to invalid input or validation errors.
class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'Validation failed',
    super.apiErrorCode,
    this.errors = const {},
  });

  /// Field-specific validation errors.
  final Map<String, List<String>> errors;

  @override
  List<Object?> get props => [message, apiErrorCode, errors];
}

/// Failure due to a state conflict on the server (HTTP 409).
class ConflictFailure extends Failure {
  const ConflictFailure({super.message = 'Conflict', super.apiErrorCode});
}

/// Failure due to a missing resource (HTTP 404).
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'Resource not found',
    super.apiErrorCode,
  });
}

/// Failure due to too many requests (HTTP 429).
class RateLimitFailure extends Failure {
  const RateLimitFailure({
    super.message = 'Too many requests',
    super.apiErrorCode,
  });
}

/// Failure due to OAuth provider issues.
class OAuthFailure extends Failure {
  const OAuthFailure({
    super.message = 'OAuth authentication failed',
    this.provider,
  });

  /// The OAuth provider that failed (e.g., 'google', 'apple').
  final String? provider;

  @override
  List<Object?> get props => [message, provider];
}

/// Failure when user cancels an operation.
class CancellationFailure extends Failure {
  const CancellationFailure({super.message = 'Operation cancelled by user'});
}

/// Failure due to local storage issues.
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Local storage error'});
}

/// Failure for unexpected errors.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message = 'An unexpected error occurred'});
}

/// Failure due to in-app purchase issues.
class PurchaseFailure extends Failure {
  const PurchaseFailure({super.message = 'Purchase failed', this.errorCode});

  /// The error code from the purchase SDK.
  final String? errorCode;

  @override
  List<Object?> get props => [message, errorCode];
}

/// Failure when user cancels a purchase.
class PurchaseCancelledFailure extends Failure {
  const PurchaseCancelledFailure({
    super.message = 'Purchase cancelled by user',
  });
}

/// Failure when product is not available for purchase.
class ProductNotAvailableFailure extends Failure {
  const ProductNotAvailableFailure({
    super.message = 'Product not available',
    this.productId,
  });

  /// The product identifier that was not available.
  final String? productId;

  @override
  List<Object?> get props => [message, productId];
}

/// Failure when the store reports the product is already owned by this account.
///
/// Indicates a race / sync gap between the store account and the local
/// RevenueCat alias — the user actually owns the entitlement, the local cache
/// just hasn't reconciled yet. Callers should trigger a restore instead of
/// surfacing a generic error.
class ProductAlreadyOwnedFailure extends Failure {
  const ProductAlreadyOwnedFailure({
    super.message = 'Product already owned',
    this.productId,
  });

  /// The product identifier that is already owned.
  final String? productId;

  @override
  List<Object?> get props => [message, productId];
}

/// Failure when purchase service is not initialized.
class PurchaseNotInitializedFailure extends Failure {
  const PurchaseNotInitializedFailure({
    super.message = 'Purchase service not initialized',
  });
}
