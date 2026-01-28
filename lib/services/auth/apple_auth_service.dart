import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:fishfeed/core/services/secure_storage_service.dart';

/// Exception thrown when Apple Sign-In fails.
class AppleAuthException implements Exception {
  const AppleAuthException(this.code, [this.message]);

  /// Error code identifying the failure type.
  final AppleAuthErrorCode code;

  /// Optional error message with additional details.
  final String? message;

  @override
  String toString() =>
      'AppleAuthException($code${message != null ? ': $message' : ''})';
}

/// Error codes for Apple Sign-In failures.
enum AppleAuthErrorCode {
  /// User cancelled the sign-in flow.
  cancelled,

  /// Failed to retrieve identity token.
  tokenError,

  /// Sign in with Apple is not available on this device.
  notAvailable,

  /// Authorization failed.
  authorizationFailed,

  /// Unknown error occurred.
  unknown,
}

/// Result of a successful Apple Sign-In.
class AppleSignInResult {
  const AppleSignInResult({
    required this.identityToken,
    required this.authorizationCode,
    required this.userIdentifier,
    this.email,
    this.givenName,
    this.familyName,
  });

  /// The identity token (JWT) to send to the backend for authentication.
  final String identityToken;

  /// The authorization code for server-side validation.
  final String authorizationCode;

  /// Unique user identifier from Apple.
  final String userIdentifier;

  /// User's email address (may be null, provided only on first login).
  final String? email;

  /// User's given name (may be null, provided only on first login).
  final String? givenName;

  /// User's family name (may be null, provided only on first login).
  final String? familyName;

  /// Returns the full display name if available.
  String? get displayName {
    if (givenName == null && familyName == null) return null;
    return [givenName, familyName].whereType<String>().join(' ').trim();
  }
}

/// Service for Apple Sign-In authentication.
///
/// Handles the Apple OAuth flow and provides identity tokens for backend authentication.
/// Note: Apple provides user's name and email only on the FIRST login.
/// This service caches user info locally for subsequent logins.
///
/// Example:
/// ```dart
/// final appleAuthService = ref.read(appleAuthServiceProvider);
/// try {
///   final result = await appleAuthService.signIn();
///   // Use result.identityToken with AuthRemoteDataSource.oauthLogin()
/// } on AppleAuthException catch (e) {
///   if (e.code == AppleAuthErrorCode.cancelled) {
///     // User cancelled sign-in
///   }
/// }
/// ```
class AppleAuthService {
  AppleAuthService({
    SecureStorageService? storageService,
    @visibleForTesting bool? isAvailableOverride,
  }) : _storageService = storageService,
       _isAvailableOverride = isAvailableOverride;

  final SecureStorageService? _storageService;
  final bool? _isAvailableOverride;

  /// Cached credential from the last successful sign-in.
  AuthorizationCredentialAppleID? _cachedCredential;

  /// Checks if Sign in with Apple is available on this device.
  ///
  /// Returns true on iOS 13+ and macOS 10.15+.
  Future<bool> isAvailable() async {
    if (_isAvailableOverride != null) {
      return _isAvailableOverride;
    }

    // Sign in with Apple is only available on iOS and macOS
    if (!Platform.isIOS && !Platform.isMacOS) {
      return false;
    }

    try {
      return await SignInWithApple.isAvailable();
    } catch (e) {
      debugPrint('AppleAuthService: Error checking availability - $e');
      return false;
    }
  }

  /// Signs in the user with Apple and returns the result with identity token.
  ///
  /// Throws [AppleAuthException] if sign-in fails.
  /// Note: Apple provides user's name and email only on the first login.
  Future<AppleSignInResult> signIn() async {
    // Check availability first
    final available = await isAvailable();
    if (!available) {
      throw const AppleAuthException(
        AppleAuthErrorCode.notAvailable,
        'Sign in with Apple is not available on this device',
      );
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) {
        throw const AppleAuthException(
          AppleAuthErrorCode.tokenError,
          'Failed to retrieve identity token',
        );
      }

      final authorizationCode = credential.authorizationCode;

      final userIdentifier = credential.userIdentifier;
      if (userIdentifier == null) {
        throw const AppleAuthException(
          AppleAuthErrorCode.tokenError,
          'Failed to retrieve user identifier',
        );
      }

      // Cache the credential
      _cachedCredential = credential;

      // Get user info - either from credential or from storage
      String? email = credential.email;
      String? givenName = credential.givenName;
      String? familyName = credential.familyName;

      // If user info is not in credential (not first login), try to get from storage
      if (email == null && givenName == null && familyName == null) {
        final storedInfo = await _getStoredUserInfo(userIdentifier);
        email = storedInfo['email'];
        givenName = storedInfo['givenName'];
        familyName = storedInfo['familyName'];
      } else {
        // First login - store user info for future use
        await _storeUserInfo(
          userIdentifier: userIdentifier,
          email: email,
          givenName: givenName,
          familyName: familyName,
        );
      }

      debugPrint('AppleAuthService: Sign-in successful for $userIdentifier');

      return AppleSignInResult(
        identityToken: identityToken,
        authorizationCode: authorizationCode,
        userIdentifier: userIdentifier,
        email: email,
        givenName: givenName,
        familyName: familyName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('AppleAuthService: AuthorizationException - ${e.code}');

      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          throw const AppleAuthException(AppleAuthErrorCode.cancelled);
        case AuthorizationErrorCode.failed:
          throw AppleAuthException(
            AppleAuthErrorCode.authorizationFailed,
            e.message,
          );
        case AuthorizationErrorCode.invalidResponse:
          throw AppleAuthException(AppleAuthErrorCode.tokenError, e.message);
        case AuthorizationErrorCode.notHandled:
          throw AppleAuthException(AppleAuthErrorCode.unknown, e.message);
        case AuthorizationErrorCode.notInteractive:
          throw const AppleAuthException(
            AppleAuthErrorCode.authorizationFailed,
            'Non-interactive authorization is not supported',
          );
        case AuthorizationErrorCode.credentialExport:
          throw AppleAuthException(AppleAuthErrorCode.unknown, e.message);
        case AuthorizationErrorCode.credentialImport:
        case AuthorizationErrorCode.matchedExcludedCredential:
        case AuthorizationErrorCode.unknown:
          throw AppleAuthException(AppleAuthErrorCode.unknown, e.message);
      }
    } on PlatformException catch (e) {
      debugPrint(
        'AppleAuthService: PlatformException - ${e.code}: ${e.message}',
      );

      if (e.code == 'ERROR_CANCELED') {
        throw const AppleAuthException(AppleAuthErrorCode.cancelled);
      }

      throw AppleAuthException(
        AppleAuthErrorCode.unknown,
        '${e.code}: ${e.message}',
      );
    } on AppleAuthException {
      rethrow;
    } catch (e) {
      debugPrint('AppleAuthService: Unknown error - $e');
      throw AppleAuthException(AppleAuthErrorCode.unknown, e.toString());
    }
  }

  /// Gets a fresh identity token for the currently signed-in user.
  ///
  /// Throws [AppleAuthException] if no cached credential or token retrieval fails.
  /// Note: This returns the cached token from the last sign-in.
  /// For a fresh token, call [signIn] again.
  String getIdToken() {
    final credential = _cachedCredential;

    if (credential == null) {
      throw const AppleAuthException(
        AppleAuthErrorCode.tokenError,
        'No cached credential available. Call signIn() first.',
      );
    }

    final identityToken = credential.identityToken;
    if (identityToken == null) {
      throw const AppleAuthException(
        AppleAuthErrorCode.tokenError,
        'Cached credential has no identity token',
      );
    }

    return identityToken;
  }

  /// Clears the cached credential.
  ///
  /// Unlike Google Sign-In, Apple Sign-In doesn't have a dedicated sign-out API.
  /// The user session is managed by your backend, not by Apple.
  void signOut() {
    _cachedCredential = null;
    debugPrint('AppleAuthService: Cached credential cleared');
  }

  /// Clears all stored Apple user info.
  ///
  /// Use this when the user wants to completely remove their Apple account
  /// association with the app.
  Future<void> clearStoredUserInfo() async {
    final storage = _storageService;
    if (storage == null) return;

    try {
      await storage.clearAppleUserInfo();
      debugPrint('AppleAuthService: Stored user info cleared');
    } catch (e) {
      debugPrint('AppleAuthService: Failed to clear stored user info - $e');
    }
  }

  /// Stores user info for future logins.
  Future<void> _storeUserInfo({
    required String userIdentifier,
    String? email,
    String? givenName,
    String? familyName,
  }) async {
    final storage = _storageService;
    if (storage == null) return;

    try {
      await storage.setAppleUserInfo(
        userIdentifier: userIdentifier,
        email: email,
        givenName: givenName,
        familyName: familyName,
      );
      debugPrint('AppleAuthService: User info stored for $userIdentifier');
    } catch (e) {
      debugPrint('AppleAuthService: Failed to store user info - $e');
    }
  }

  /// Retrieves stored user info for the given user identifier.
  Future<Map<String, String?>> _getStoredUserInfo(String userIdentifier) async {
    final storage = _storageService;
    if (storage == null) {
      return {'email': null, 'givenName': null, 'familyName': null};
    }

    try {
      final storedInfo = await storage.getAppleUserInfo();

      // Only return stored info if it matches the current user
      if (storedInfo != null && storedInfo.userIdentifier == userIdentifier) {
        return {
          'email': storedInfo.email,
          'givenName': storedInfo.givenName,
          'familyName': storedInfo.familyName,
        };
      }
    } catch (e) {
      debugPrint('AppleAuthService: Failed to get stored user info - $e');
    }

    return {'email': null, 'givenName': null, 'familyName': null};
  }
}

/// Provider for [AppleAuthService].
///
/// Usage:
/// ```dart
/// final appleAuthService = ref.watch(appleAuthServiceProvider);
/// if (await appleAuthService.isAvailable()) {
///   final result = await appleAuthService.signIn();
/// }
/// ```
final appleAuthServiceProvider = Provider<AppleAuthService>((ref) {
  final storageService = ref.watch(secureStorageServiceProvider);
  return AppleAuthService(storageService: storageService);
});
