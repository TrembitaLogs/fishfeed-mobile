/// API versioning configuration.
abstract final class ApiVersion {
  /// The current API version path prefix.
  static const String pathPrefix = '/api/v1';
}

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

  // Image endpoints
  static const String imageUpload = '/images/upload';
  static const String imageUrls = '/images/urls';

  // Aquarium endpoints
  static const String aquariums = '/aquariums';

  // Family endpoints
  static String familyMembers(String aquariumId) =>
      '/aquariums/$aquariumId/family';
  static String familyCreateInvite(String aquariumId) =>
      '/aquariums/$aquariumId/family/invite';
  static String familyInvites(String aquariumId) =>
      '/aquariums/$aquariumId/family/invites';
  static String familyCancelInvite(String aquariumId, String inviteId) =>
      '/aquariums/$aquariumId/family/invites/$inviteId';
  static const String familyAccept = '/family/accept';
  static String familyRemoveMember(String aquariumId, String userId) =>
      '/aquariums/$aquariumId/family/$userId';
}

/// API timeout configuration for different operation types.
abstract final class ApiScanTimeouts {
  /// Timeout for AI scan requests (longer due to image processing).
  static const Duration scanTimeout = Duration(seconds: 30);

  /// Timeout for retry prompts.
  static const Duration retryDelay = Duration(seconds: 2);
}
