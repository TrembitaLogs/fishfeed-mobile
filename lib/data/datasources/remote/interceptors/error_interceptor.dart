import 'package:dio/dio.dart';
import 'package:fishfeed/core/errors/api_exceptions.dart';

/// Interceptor that transforms [DioException] into typed [ApiException].
///
/// This interceptor catches all Dio errors and converts them to specific
/// exception types based on the error type and HTTP status code:
///
/// - Connection/timeout errors → [NetworkException]
/// - 401 → [UnauthorizedException]
/// - 403 → [ForbiddenException]
/// - 404 → [NotFoundException]
/// - 400, 422 → [ValidationException]
/// - 5xx → [ServerException]
/// - Other → [UnknownApiException]
///
/// Usage:
/// ```dart
/// dio.interceptors.add(ErrorInterceptor());
/// ```
class ErrorInterceptor extends Interceptor {
  const ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiException = _mapToApiException(err);

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
        message: apiException.message,
      ),
    );
  }

  /// Maps a [DioException] to the appropriate [ApiException] subtype.
  ApiException _mapToApiException(DioException exception) {
    // Handle connection and timeout errors
    if (_isNetworkError(exception)) {
      return NetworkException.fromDioException(exception);
    }

    // Handle HTTP status code errors
    final statusCode = exception.response?.statusCode;

    if (statusCode == null) {
      return UnknownApiException.fromDioException(exception);
    }

    return switch (statusCode) {
      400 || 422 => ValidationException.fromDioException(exception),
      401 => UnauthorizedException.fromDioException(exception),
      403 => ForbiddenException.fromDioException(exception),
      404 => NotFoundException.fromDioException(exception),
      >= 500 && < 600 => ServerException.fromDioException(exception),
      _ => UnknownApiException.fromDioException(exception),
    };
  }

  /// Checks if the exception is a network-related error.
  bool _isNetworkError(DioException exception) {
    return switch (exception.type) {
      DioExceptionType.connectionTimeout => true,
      DioExceptionType.sendTimeout => true,
      DioExceptionType.receiveTimeout => true,
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }
}
