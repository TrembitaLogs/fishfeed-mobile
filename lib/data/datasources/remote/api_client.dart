import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:sentry_dio/sentry_dio.dart';

import 'package:fishfeed/core/config/api_config.dart';
import 'package:fishfeed/core/services/secure_storage_service.dart';
import 'package:fishfeed/data/datasources/remote/interceptors/interceptors.dart';
import 'package:fishfeed/services/sentry/sentry_service.dart';

/// Environment variable keys used by the API client.
abstract final class ApiEnvKeys {
  static const String baseUrl = 'API_BASE_URL';
  static const String baseUrlIosDevice = 'API_BASE_URL_IOS_DEVICE';
}

/// Default timeout durations for API requests.
abstract final class ApiTimeouts {
  static const Duration connect = Duration(seconds: 30);
  static const Duration receive = Duration(seconds: 30);
  static const Duration send = Duration(seconds: 30);
}

/// Callback type for logout operation triggered by token refresh failure.
typedef OnLogoutCallback = Future<void> Function();

/// HTTP client wrapper around Dio with pre-configured settings.
///
/// Provides a configured Dio instance with:
/// - Base URL from environment variables
/// - Request/response logging in debug mode
/// - Configured timeouts
/// - JSON content-type headers
/// - AuthInterceptor for Bearer token injection
/// - TokenRefreshInterceptor for automatic token refresh
/// - RetryInterceptor for automatic retry with exponential backoff
/// - ErrorInterceptor for unified error handling
///
/// Example:
/// ```dart
/// final apiClient = ApiClient(secureStorageService: secureStorageService);
/// final response = await apiClient.dio.get('/users');
/// ```
class ApiClient {
  ApiClient({
    required SecureStorageService secureStorageService,
    Dio? dio,
    String? baseUrl,
    OnLogoutCallback? onLogout,
  }) : _secureStorageService = secureStorageService,
       _dio = dio ?? Dio(),
       _onLogout = onLogout {
    _configure(baseUrl);
  }

  final Dio _dio;
  final SecureStorageService _secureStorageService;
  final OnLogoutCallback? _onLogout;

  /// The configured Dio instance for making HTTP requests.
  Dio get dio => _dio;

  /// Resolves the base URL based on platform and environment.
  ///
  /// Priority:
  /// 1. For physical iOS device: API_BASE_URL_IOS_DEVICE (if set)
  /// 2. Default: API_BASE_URL
  ///
  /// Physical iOS device is detected by checking if running on iOS
  /// and not in a simulator (no SIMULATOR_DEVICE_NAME env var).
  String _resolveBaseUrl() {
    final defaultUrl = dotenv.env[ApiEnvKeys.baseUrl] ?? '';
    final iosDeviceUrl = dotenv.env[ApiEnvKeys.baseUrlIosDevice];

    // Check if running on physical iOS device
    if (Platform.isIOS && iosDeviceUrl != null && iosDeviceUrl.isNotEmpty) {
      // Check if NOT running in simulator
      // In simulator, environment contains SIMULATOR_DEVICE_NAME
      final isSimulator = Platform.environment.containsKey(
        'SIMULATOR_DEVICE_NAME',
      );
      if (!isSimulator) {
        if (kDebugMode) {
          print(
            'ApiClient: Detected physical iOS device, using iOS device URL',
          );
        }
        return iosDeviceUrl;
      }
    }

    return defaultUrl;
  }

  /// Configures the Dio instance with base options and interceptors.
  void _configure(String? baseUrl) {
    final resolvedBaseUrl = baseUrl ?? _resolveBaseUrl();
    final versionedBaseUrl = '$resolvedBaseUrl${ApiVersion.pathPrefix}';

    if (kDebugMode) {
      print('ApiClient: Using base URL: $versionedBaseUrl');
    }

    _dio.options = BaseOptions(
      baseUrl: versionedBaseUrl,
      connectTimeout: ApiTimeouts.connect,
      receiveTimeout: ApiTimeouts.receive,
      sendTimeout: ApiTimeouts.send,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _addInterceptors();
  }

  /// Adds interceptors to the Dio instance.
  ///
  /// Order matters for error handling:
  /// 1. Auth - adds Bearer token to requests
  /// 2. TokenRefresh - handles 401 by refreshing tokens
  /// 3. Retry - retries failed requests with exponential backoff
  /// 4. Error - transforms DioException to typed ApiException
  /// 5. Log - logs requests/responses (debug only)
  void _addInterceptors() {
    _dio.interceptors.add(
      AuthInterceptor(secureStorageService: _secureStorageService),
    );

    _dio.interceptors.add(
      TokenRefreshInterceptor(
        secureStorageService: _secureStorageService,
        dio: _dio,
        onLogout: _onLogout,
      ),
    );

    _dio.interceptors.add(RetryInterceptor(dio: _dio));

    _dio.interceptors.add(const ErrorInterceptor());

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
          logPrint: (object) => debugPrint(object.toString()),
        ),
      );
    }

    // Add Sentry interceptor for HTTP tracing and error capture
    // Must be added last to wrap the entire request lifecycle
    if (SentryService.instance.isInitialized) {
      _dio.addSentry(captureFailedRequests: true);
    }
  }
}

/// Provider for the API client instance.
///
/// Usage:
/// ```dart
/// final apiClient = ref.watch(apiClientProvider);
/// final response = await apiClient.dio.get('/endpoint');
/// ```
final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorageService = ref.watch(secureStorageServiceProvider);
  return ApiClient(secureStorageService: secureStorageService);
});
