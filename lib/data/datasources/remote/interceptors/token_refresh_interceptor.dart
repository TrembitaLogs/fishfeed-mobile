import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fishfeed/core/services/secure_storage_service.dart';

/// Callback type for logout operation.
typedef LogoutCallback = Future<void> Function();

/// Interceptor that handles automatic token refresh on 401 errors.
///
/// Uses [QueuedInterceptor] to ensure sequential processing of requests,
/// preventing race conditions when multiple requests fail simultaneously.
///
/// When a 401 response is received:
/// 1. Attempts to refresh the access token using the stored refresh token
/// 2. Retries the original request with the new token
/// 3. If refresh fails (e.g., refresh token expired), triggers logout
class TokenRefreshInterceptor extends QueuedInterceptor {
  TokenRefreshInterceptor({
    required SecureStorageService secureStorageService,
    required Dio dio,
    LogoutCallback? onLogout,
    String refreshEndpoint = '/auth/refresh',
  }) : _secureStorageService = secureStorageService,
       _dio = dio,
       _onLogout = onLogout,
       _refreshEndpoint = refreshEndpoint;

  final SecureStorageService _secureStorageService;
  final Dio _dio;
  final LogoutCallback? _onLogout;
  final String _refreshEndpoint;

  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Skip if this is the refresh endpoint itself
    if (err.requestOptions.path.contains(_refreshEndpoint)) {
      await _handleLogout();
      return handler.next(err);
    }

    final refreshed = await _ensureTokenRefreshed();

    if (!refreshed) {
      return handler.next(err);
    }

    // Retry the original request with the new token
    try {
      final newAccessToken = await _secureStorageService.getAccessToken();
      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer $newAccessToken';

      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } catch (e) {
      return handler.next(err);
    }
  }

  /// Ensures token is refreshed, handling concurrent refresh attempts.
  Future<bool> _ensureTokenRefreshed() async {
    if (_isRefreshing) {
      return _refreshCompleter?.future ?? Future.value(false);
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final success = await _refreshToken();
      _refreshCompleter?.complete(success);
      return success;
    } catch (e) {
      _refreshCompleter?.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  /// Attempts to refresh the access token.
  Future<bool> _refreshToken() async {
    final refreshToken = await _secureStorageService.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      await _handleLogout();
      return false;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _refreshEndpoint,
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final newAccessToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;

        if (newAccessToken != null) {
          await _secureStorageService.setAccessToken(newAccessToken);

          if (newRefreshToken != null) {
            await _secureStorageService.setRefreshToken(newRefreshToken);
          }

          return true;
        }
      }

      await _handleLogout();
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleLogout();
      }
      return false;
    }
  }

  /// Handles logout when refresh fails.
  Future<void> _handleLogout() async {
    await _secureStorageService.clearTokens();
    await _onLogout?.call();
  }
}
