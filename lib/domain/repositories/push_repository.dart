import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/errors/failures.dart';

/// Repository interface for push notification token management.
///
/// Handles registration and unregistration of FCM/APNs tokens
/// on the backend server with automatic retry logic.
abstract interface class PushRepository {
  /// Registers a push token on the backend.
  ///
  /// [token] is the FCM token from Firebase Messaging.
  /// [platform] is the device platform ('android' or 'ios').
  ///
  /// Only registers if the token is different from the last registered token.
  /// Stores the token locally after successful registration.
  ///
  /// Returns [Right(unit)] on success.
  /// Returns [Left(Failure)] on error after all retries exhausted:
  /// - [NetworkFailure] for connectivity issues
  /// - [ServerFailure] for server errors
  Future<Either<Failure, Unit>> registerToken({
    required String token,
    required String platform,
  });

  /// Registers a push token with automatic retry on failure.
  ///
  /// Same as [registerToken] but continues retrying in the background
  /// with exponential backoff. Does not return a result.
  ///
  /// Use this when you don't need to wait for the result.
  Future<void> registerTokenWithRetry({
    required String token,
    required String platform,
  });

  /// Unregisters the push token from the backend.
  ///
  /// Clears the locally stored token regardless of server response.
  /// Should be called on logout.
  ///
  /// Returns [Right(unit)] on success.
  /// Returns [Left(Failure)] on error:
  /// - [NetworkFailure] for connectivity issues
  /// - [ServerFailure] for server errors
  Future<Either<Failure, Unit>> unregisterToken();

  /// Gets the currently stored push token.
  ///
  /// Returns null if no token is stored.
  String? getStoredToken();

  /// Gets the platform of the stored push token.
  ///
  /// Returns null if no token is stored.
  String? getStoredPlatform();

  /// Checks if a token needs to be registered or re-registered.
  ///
  /// [currentToken] is the current FCM token from Firebase Messaging.
  /// [platform] is the device platform.
  ///
  /// Returns true if the token is different from the stored token
  /// or if no token is stored.
  bool needsRegistration(String currentToken, String platform);
}
