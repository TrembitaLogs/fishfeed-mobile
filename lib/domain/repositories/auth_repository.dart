import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/entities/user.dart';

/// Repository interface for authentication operations.
///
/// Provides a clean API for authentication flows following Clean Architecture.
/// All methods return [Either] type for explicit error handling.
abstract interface class AuthRepository {
  /// Authenticates a user with email and password.
  ///
  /// Returns [Right(User)] on success.
  /// Returns [Left(Failure)] on error:
  /// - [ValidationFailure] for invalid credentials format
  /// - [AuthenticationFailure] for wrong credentials
  /// - [NetworkFailure] for connectivity issues
  /// - [ServerFailure] for server errors
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  /// Registers a new user with email and password.
  ///
  /// Returns [Right(User)] on success.
  /// Returns [Left(Failure)] on error:
  /// - [ValidationFailure] for invalid input (email taken, weak password)
  /// - [NetworkFailure] for connectivity issues
  /// - [ServerFailure] for server errors
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
  });

  /// Authenticates a user via OAuth provider.
  ///
  /// [provider] is the OAuth provider name ('google' or 'apple').
  /// [idToken] is the OAuth ID token from the provider.
  ///
  /// Returns [Right(User)] on success.
  /// Returns [Left(Failure)] on error:
  /// - [OAuthFailure] for OAuth-specific errors
  /// - [CancellationFailure] if user cancelled OAuth flow
  /// - [NetworkFailure] for connectivity issues
  /// - [ServerFailure] for server errors
  Future<Either<Failure, User>> oauthLogin({
    required String provider,
    required String idToken,
  });

  /// Logs out the current user.
  ///
  /// Clears local tokens and invalidates the refresh token on server.
  ///
  /// Returns [Right(unit)] on success.
  /// Returns [Left(Failure)] on error:
  /// - [NetworkFailure] for connectivity issues (tokens still cleared locally)
  /// - [ServerFailure] for server errors (tokens still cleared locally)
  Future<Either<Failure, Unit>> logout();

  /// Gets the currently authenticated user from local storage.
  ///
  /// Returns [Right(User)] if a user is cached locally.
  /// Returns [Left(CacheFailure)] if no user is cached.
  Future<Either<Failure, User>> getCurrentUser();

  /// Checks if a user is currently authenticated.
  ///
  /// Returns `true` if valid tokens exist locally.
  Future<bool> isAuthenticated();

  /// Saves a user to local storage for offline access.
  ///
  /// Used after login/OAuth to persist user data locally.
  Future<void> saveUserLocally(User user);

  /// Gets the current user from local storage synchronously.
  ///
  /// Returns the locally cached user, or null if not found.
  /// Unlike [getCurrentUser], this returns the domain entity directly.
  User? getLocalUser();

  /// Gets whether onboarding has been completed.
  bool getOnboardingCompleted();

  /// Sets the onboarding completion flag.
  Future<void> setOnboardingCompleted(bool completed);
}
