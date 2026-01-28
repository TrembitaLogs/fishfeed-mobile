import 'package:dio/dio.dart';
import 'package:fishfeed/core/services/secure_storage_service.dart';

/// Paths that should not include the Authorization header.
const _publicPaths = [
  '/auth/login',
  '/auth/register',
  '/auth/refresh',
  '/auth/oauth',
];

/// Interceptor that adds Bearer token to outgoing requests.
///
/// Reads the access token from secure storage and adds it as an
/// Authorization header to all requests except authentication endpoints.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required SecureStorageService secureStorageService})
    : _secureStorageService = secureStorageService;

  final SecureStorageService _secureStorageService;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublicPath(options.path)) {
      return handler.next(options);
    }

    final accessToken = await _secureStorageService.getAccessToken();

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  /// Checks if the path should skip authentication.
  bool _isPublicPath(String path) {
    return _publicPaths.any((publicPath) => path.contains(publicPath));
  }
}
