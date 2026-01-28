import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Exception thrown when Google Sign-In fails.
class GoogleAuthException implements Exception {
  const GoogleAuthException(this.code, [this.message]);

  /// Error code identifying the failure type.
  final GoogleAuthErrorCode code;

  /// Optional error message with additional details.
  final String? message;

  @override
  String toString() =>
      'GoogleAuthException($code${message != null ? ': $message' : ''})';
}

/// Error codes for Google Sign-In failures.
enum GoogleAuthErrorCode {
  /// User cancelled the sign-in flow.
  cancelled,

  /// Network error during sign-in.
  networkError,

  /// Failed to retrieve ID token.
  tokenError,

  /// Google Sign-In is not configured properly.
  configurationError,

  /// Unknown error occurred.
  unknown,
}

/// Result of a successful Google Sign-In.
class GoogleSignInResult {
  const GoogleSignInResult({
    required this.idToken,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  /// The ID token to send to the backend for authentication.
  final String idToken;

  /// User's email address.
  final String email;

  /// User's display name (may be null).
  final String? displayName;

  /// URL to user's profile photo (may be null).
  final String? photoUrl;
}

/// Service for Google Sign-In authentication.
///
/// Handles the Google OAuth flow and provides ID tokens for backend authentication.
///
/// Example:
/// ```dart
/// final googleAuthService = ref.read(googleAuthServiceProvider);
/// try {
///   final result = await googleAuthService.signIn();
///   // Use result.idToken with AuthRemoteDataSource.oauthLogin()
/// } on GoogleAuthException catch (e) {
///   if (e.code == GoogleAuthErrorCode.cancelled) {
///     // User cancelled sign-in
///   }
/// }
/// ```
class GoogleAuthService {
  GoogleAuthService({GoogleSignIn? googleSignIn})
    : _googleSignIn =
          googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  final GoogleSignIn _googleSignIn;

  /// Returns the currently signed-in Google account, if any.
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Whether there is a currently signed-in user.
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Signs in the user with Google and returns the result with ID token.
  ///
  /// Throws [GoogleAuthException] if sign-in fails.
  Future<GoogleSignInResult> signIn() async {
    try {
      final account = await _googleSignIn.signIn();

      if (account == null) {
        throw const GoogleAuthException(GoogleAuthErrorCode.cancelled);
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;

      if (idToken == null) {
        throw const GoogleAuthException(
          GoogleAuthErrorCode.tokenError,
          'Failed to retrieve ID token',
        );
      }

      debugPrint('GoogleAuthService: Sign-in successful for ${account.email}');

      return GoogleSignInResult(
        idToken: idToken,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
      );
    } on PlatformException catch (e) {
      debugPrint(
        'GoogleAuthService: PlatformException - ${e.code}: ${e.message}',
      );

      if (e.code == 'sign_in_canceled') {
        throw const GoogleAuthException(GoogleAuthErrorCode.cancelled);
      }

      if (e.code == 'network_error') {
        throw GoogleAuthException(GoogleAuthErrorCode.networkError, e.message);
      }

      if (e.code == 'sign_in_failed' &&
          e.message?.contains('configuration') == true) {
        throw GoogleAuthException(
          GoogleAuthErrorCode.configurationError,
          e.message,
        );
      }

      throw GoogleAuthException(
        GoogleAuthErrorCode.unknown,
        '${e.code}: ${e.message}',
      );
    } on GoogleAuthException {
      rethrow;
    } catch (e) {
      debugPrint('GoogleAuthService: Unknown error - $e');
      throw GoogleAuthException(GoogleAuthErrorCode.unknown, e.toString());
    }
  }

  /// Attempts to sign in silently without user interaction.
  ///
  /// Returns null if silent sign-in is not possible.
  /// Useful for restoring the previous session on app start.
  Future<GoogleSignInResult?> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();

      if (account == null) {
        return null;
      }

      final authentication = await account.authentication;
      final idToken = authentication.idToken;

      if (idToken == null) {
        debugPrint('GoogleAuthService: Silent sign-in failed - no ID token');
        return null;
      }

      debugPrint(
        'GoogleAuthService: Silent sign-in successful for ${account.email}',
      );

      return GoogleSignInResult(
        idToken: idToken,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
      );
    } catch (e) {
      debugPrint('GoogleAuthService: Silent sign-in failed - $e');
      return null;
    }
  }

  /// Gets a fresh ID token for the currently signed-in user.
  ///
  /// Throws [GoogleAuthException] if no user is signed in or token retrieval fails.
  Future<String> getIdToken() async {
    final account = _googleSignIn.currentUser;

    if (account == null) {
      throw const GoogleAuthException(
        GoogleAuthErrorCode.tokenError,
        'No user is signed in',
      );
    }

    try {
      final authentication = await account.authentication;
      final idToken = authentication.idToken;

      if (idToken == null) {
        throw const GoogleAuthException(
          GoogleAuthErrorCode.tokenError,
          'Failed to retrieve ID token',
        );
      }

      return idToken;
    } catch (e) {
      if (e is GoogleAuthException) rethrow;

      throw GoogleAuthException(GoogleAuthErrorCode.tokenError, e.toString());
    }
  }

  /// Signs out the current user from Google.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      debugPrint('GoogleAuthService: Sign-out successful');
    } catch (e) {
      debugPrint('GoogleAuthService: Sign-out failed - $e');
      // Silently fail on sign-out errors
    }
  }

  /// Disconnects the Google account and revokes access.
  ///
  /// Use this when the user wants to completely remove their Google account
  /// association with the app.
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      debugPrint('GoogleAuthService: Disconnect successful');
    } catch (e) {
      debugPrint('GoogleAuthService: Disconnect failed - $e');
      // Silently fail on disconnect errors
    }
  }
}

/// Provider for [GoogleAuthService].
///
/// Usage:
/// ```dart
/// final googleAuthService = ref.watch(googleAuthServiceProvider);
/// final result = await googleAuthService.signIn();
/// ```
final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});
