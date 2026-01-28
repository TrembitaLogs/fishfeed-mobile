import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/user_model.dart';

/// Keys used for storing authentication tokens in secure storage.
abstract final class AuthStorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String tokenExpiry = 'token_expiry';
}

/// Key used for storing the current user in Hive.
const String _currentUserKey = 'current_user';

/// Data source for securely storing and retrieving authentication tokens.
///
/// Uses [FlutterSecureStorage] to store JWT tokens securely on the device.
/// On Android, uses EncryptedSharedPreferences for AES encryption.
/// On iOS, uses Keychain with first_unlock accessibility.
///
/// Example:
/// ```dart
/// final authDs = AuthLocalDataSource();
/// await authDs.saveTokens(
///   accessToken: 'jwt_access_token',
///   refreshToken: 'jwt_refresh_token',
///   expiry: DateTime.now().add(Duration(hours: 1)),
/// );
/// ```
class AuthLocalDataSource {
  AuthLocalDataSource({
    FlutterSecureStorage? storage,
    Box<dynamic>? usersBox,
  })  : _storage = storage ?? _createSecureStorage(),
        _usersBox = usersBox;

  final FlutterSecureStorage _storage;
  final Box<dynamic>? _usersBox;

  /// Gets the users box, using the injected box or the default HiveBoxes.
  Box<dynamic> get _users => _usersBox ?? HiveBoxes.users;

  /// Creates a [FlutterSecureStorage] instance with platform-specific options.
  static FlutterSecureStorage _createSecureStorage() {
    return const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
  }

  /// Saves authentication tokens to secure storage.
  ///
  /// [accessToken] - The JWT access token for API authentication.
  /// [refreshToken] - The refresh token for obtaining new access tokens.
  /// [expiry] - The expiration time of the access token.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiry,
  }) async {
    await Future.wait([
      _storage.write(key: AuthStorageKeys.accessToken, value: accessToken),
      _storage.write(key: AuthStorageKeys.refreshToken, value: refreshToken),
      _storage.write(
        key: AuthStorageKeys.tokenExpiry,
        value: expiry.toIso8601String(),
      ),
    ]);
  }

  /// Retrieves the stored access token.
  ///
  /// Returns `null` if no access token is stored.
  Future<String?> getAccessToken() async {
    return _storage.read(key: AuthStorageKeys.accessToken);
  }

  /// Retrieves the stored refresh token.
  ///
  /// Returns `null` if no refresh token is stored.
  Future<String?> getRefreshToken() async {
    return _storage.read(key: AuthStorageKeys.refreshToken);
  }

  /// Retrieves the stored token expiry time.
  ///
  /// Returns `null` if no expiry time is stored or if parsing fails.
  Future<DateTime?> getTokenExpiry() async {
    final expiryString = await _storage.read(key: AuthStorageKeys.tokenExpiry);
    if (expiryString == null) return null;
    return DateTime.tryParse(expiryString);
  }

  /// Checks if the stored access token is still valid.
  ///
  /// Returns `true` if an access token exists and has not expired.
  /// Returns `false` if no token exists or if the token has expired.
  Future<bool> isTokenValid() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return false;

    final expiry = await getTokenExpiry();
    if (expiry == null) return false;

    return DateTime.now().isBefore(expiry);
  }

  /// Clears all stored authentication tokens.
  ///
  /// Call this method when logging out or when tokens need to be invalidated.
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: AuthStorageKeys.accessToken),
      _storage.delete(key: AuthStorageKeys.refreshToken),
      _storage.delete(key: AuthStorageKeys.tokenExpiry),
    ]);
  }

  // ============ User Data Methods ============

  /// Saves user data to local Hive storage.
  ///
  /// [user] - The user model to save locally.
  /// This is typically called after successful authentication.
  Future<void> saveUserLocally(UserModel user) async {
    await _users.put(_currentUserKey, user);
  }

  /// Retrieves the currently stored user from local storage.
  ///
  /// Returns `null` if no user is stored.
  UserModel? getCurrentUser() {
    final user = _users.get(_currentUserKey);
    if (user is UserModel) {
      return user;
    }
    return null;
  }

  /// Updates the stored user data in local storage.
  ///
  /// [user] - The updated user model to save.
  /// Always saves the user data, regardless of whether a user already exists.
  Future<void> updateUserLocally(UserModel user) async {
    await _users.put(_currentUserKey, user);
  }

  /// Clears all user data from local storage.
  ///
  /// Call this method when logging out to remove cached user information.
  Future<void> clearUserData() async {
    await _users.delete(_currentUserKey);
  }

  /// Clears all authentication data (tokens and user data).
  ///
  /// Convenience method that clears both tokens and user data.
  Future<void> clearAll() async {
    await Future.wait([
      clearTokens(),
      clearUserData(),
    ]);
  }
}
