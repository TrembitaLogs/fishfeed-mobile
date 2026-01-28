/// Application-wide constants
abstract final class AppConstants {
  /// Application name
  static const String appName = 'FishFeed';

  /// Minimum supported iOS version
  static const String minIosVersion = '14.0';

  /// Minimum supported Android API level
  static const int minAndroidSdk = 24;

  /// Default animation duration in milliseconds
  static const int defaultAnimationDuration = 300;

  /// Default page size for pagination
  static const int defaultPageSize = 20;

  /// Maximum retry attempts for network requests
  static const int maxRetryAttempts = 3;

  /// Request timeout in seconds
  static const int requestTimeoutSeconds = 30;

  /// Cache duration in hours
  static const int cacheDurationHours = 24;
}
