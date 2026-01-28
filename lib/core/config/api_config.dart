/// API endpoint configuration.
///
/// Contains all API endpoint paths used throughout the app.
abstract final class ApiEndpoints {
  // AI Scan endpoints
  static const String aiScan = '/ai/scan/upload';

  // Auth endpoints (reference - actual endpoints in auth_remote_ds.dart)
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authOauth = '/auth/oauth';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

  // Subscription endpoints
  static const String subscriptionSync = '/subscription/sync';

  // Species endpoints
  static const String speciesList = '/species';
  static const String speciesSearch = '/species/search';
  static const String speciesPopular = '/species/popular';

  // Aquarium endpoints
  static const String aquariums = '/aquariums';
}

/// API timeout configuration for different operation types.
abstract final class ApiScanTimeouts {
  /// Timeout for AI scan requests (longer due to image processing).
  static const Duration scanTimeout = Duration(seconds: 30);

  /// Timeout for retry prompts.
  static const Duration retryDelay = Duration(seconds: 2);
}
