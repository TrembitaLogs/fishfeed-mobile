import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keys for secure storage operations.
abstract final class SecureStorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';

  // Apple Sign-In user info keys
  static const String appleUserIdentifier = 'apple_user_identifier';
  static const String appleUserEmail = 'apple_user_email';
  static const String appleUserGivenName = 'apple_user_given_name';
  static const String appleUserFamilyName = 'apple_user_family_name';
}

/// Service for secure storage operations.
///
/// Provides methods for storing and retrieving JWT tokens
/// using platform-specific secure storage mechanisms.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Reads the access token from secure storage.
  Future<String?> getAccessToken() async {
    return _storage.read(key: SecureStorageKeys.accessToken);
  }

  /// Writes the access token to secure storage.
  Future<void> setAccessToken(String token) async {
    await _storage.write(key: SecureStorageKeys.accessToken, value: token);
  }

  /// Reads the refresh token from secure storage.
  Future<String?> getRefreshToken() async {
    return _storage.read(key: SecureStorageKeys.refreshToken);
  }

  /// Writes the refresh token to secure storage.
  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: SecureStorageKeys.refreshToken, value: token);
  }

  /// Stores both access and refresh tokens.
  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      setAccessToken(accessToken),
      setRefreshToken(refreshToken),
    ]);
  }

  /// Clears all authentication tokens.
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: SecureStorageKeys.accessToken),
      _storage.delete(key: SecureStorageKeys.refreshToken),
    ]);
  }

  /// Checks if user has stored tokens.
  Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  // Apple Sign-In user info methods

  /// Stores Apple Sign-In user info.
  ///
  /// Apple provides user's name and email only on the first login,
  /// so we need to store this locally for subsequent sessions.
  Future<void> setAppleUserInfo({
    required String userIdentifier,
    String? email,
    String? givenName,
    String? familyName,
  }) async {
    await Future.wait([
      _storage.write(
        key: SecureStorageKeys.appleUserIdentifier,
        value: userIdentifier,
      ),
      if (email != null)
        _storage.write(key: SecureStorageKeys.appleUserEmail, value: email),
      if (givenName != null)
        _storage.write(
          key: SecureStorageKeys.appleUserGivenName,
          value: givenName,
        ),
      if (familyName != null)
        _storage.write(
          key: SecureStorageKeys.appleUserFamilyName,
          value: familyName,
        ),
    ]);
  }

  /// Retrieves stored Apple user info.
  Future<AppleUserInfo?> getAppleUserInfo() async {
    final userIdentifier = await _storage.read(
      key: SecureStorageKeys.appleUserIdentifier,
    );

    if (userIdentifier == null) return null;

    final email = await _storage.read(key: SecureStorageKeys.appleUserEmail);
    final givenName = await _storage.read(
      key: SecureStorageKeys.appleUserGivenName,
    );
    final familyName = await _storage.read(
      key: SecureStorageKeys.appleUserFamilyName,
    );

    return AppleUserInfo(
      userIdentifier: userIdentifier,
      email: email,
      givenName: givenName,
      familyName: familyName,
    );
  }

  /// Clears stored Apple user info.
  Future<void> clearAppleUserInfo() async {
    await Future.wait([
      _storage.delete(key: SecureStorageKeys.appleUserIdentifier),
      _storage.delete(key: SecureStorageKeys.appleUserEmail),
      _storage.delete(key: SecureStorageKeys.appleUserGivenName),
      _storage.delete(key: SecureStorageKeys.appleUserFamilyName),
    ]);
  }
}

/// Stored Apple Sign-In user info.
class AppleUserInfo {
  const AppleUserInfo({
    required this.userIdentifier,
    this.email,
    this.givenName,
    this.familyName,
  });

  final String userIdentifier;
  final String? email;
  final String? givenName;
  final String? familyName;

  /// Returns the full display name if available.
  String? get displayName {
    if (givenName == null && familyName == null) return null;
    return [givenName, familyName].whereType<String>().join(' ').trim();
  }
}

/// Provider for the secure storage service instance.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
