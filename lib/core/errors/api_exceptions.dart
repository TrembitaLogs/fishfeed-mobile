import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

/// Base class for all API-related exceptions.
///
/// Provides a unified interface for handling API errors throughout the app.
/// All API exceptions extend this class and carry an optional [message],
/// [statusCode], and the original [originalException].
sealed class ApiException extends Equatable implements Exception {
  const ApiException({this.message, this.statusCode, this.originalException});

  /// Human-readable error message.
  final String? message;

  /// HTTP status code if available.
  final int? statusCode;

  /// The original exception that caused this error.
  final DioException? originalException;

  @override
  List<Object?> get props => [message, statusCode];

  @override
  String toString() => '$runtimeType: $message (status: $statusCode)';
}

/// Exception thrown when there is no network connectivity.
///
/// This is typically thrown when:
/// - Device has no internet connection
/// - Connection timeout occurred
/// - DNS resolution failed
class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'No internet connection',
    super.originalException,
  }) : super(statusCode: null);

  /// Creates a NetworkException from a DioException.
  factory NetworkException.fromDioException(DioException exception) {
    final message = switch (exception.type) {
      DioExceptionType.connectionTimeout => 'Connection timeout',
      DioExceptionType.sendTimeout => 'Send timeout',
      DioExceptionType.receiveTimeout => 'Receive timeout',
      DioExceptionType.connectionError => 'Connection error',
      _ => 'No internet connection',
    };

    return NetworkException(message: message, originalException: exception);
  }
}

/// Exception thrown for server errors (5xx status codes).
///
/// Indicates that the server encountered an error while processing the request.
class ServerException extends ApiException {
  const ServerException({
    super.message = 'Server error occurred',
    super.statusCode,
    super.originalException,
  });

  /// Creates a ServerException from a DioException.
  factory ServerException.fromDioException(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final message = switch (statusCode) {
      500 => 'Internal server error',
      501 => 'Not implemented',
      502 => 'Bad gateway',
      503 => 'Service unavailable',
      504 => 'Gateway timeout',
      _ => 'Server error occurred',
    };

    return ServerException(
      message: message,
      statusCode: statusCode,
      originalException: exception,
    );
  }
}

/// Exception thrown for unauthorized requests (401 status code).
///
/// Indicates that authentication is required or the provided credentials
/// are invalid.
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Unauthorized',
    super.originalException,
  }) : super(statusCode: 401);

  /// Creates an UnauthorizedException from a DioException.
  factory UnauthorizedException.fromDioException(DioException exception) {
    return UnauthorizedException(
      message: 'Authentication required',
      originalException: exception,
    );
  }
}

/// Exception thrown for validation errors (400, 422 status codes).
///
/// Contains detailed field-level validation errors when available.
class ValidationException extends ApiException {
  const ValidationException({
    super.message = 'Validation failed',
    super.statusCode,
    super.originalException,
    this.errors = const {},
  });

  /// Creates a ValidationException from a DioException.
  ///
  /// Attempts to parse validation errors from the response body.
  /// Expected response format:
  /// ```json
  /// {
  ///   "message": "Validation failed",
  ///   "errors": {
  ///     "email": ["Invalid email format"],
  ///     "password": ["Password too short", "Must contain a number"]
  ///   }
  /// }
  /// ```
  factory ValidationException.fromDioException(DioException exception) {
    final response = exception.response;
    final statusCode = response?.statusCode;
    String message = 'Validation failed';
    Map<String, List<String>> errors = {};

    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;

      if (data['message'] is String) {
        message = data['message'] as String;
      }

      if (data['errors'] is Map<String, dynamic>) {
        final rawErrors = data['errors'] as Map<String, dynamic>;
        errors = rawErrors.map((key, value) {
          if (value is List) {
            return MapEntry(key, value.cast<String>());
          } else if (value is String) {
            return MapEntry(key, [value]);
          }
          return MapEntry(key, <String>[]);
        });
      }
    }

    return ValidationException(
      message: message,
      statusCode: statusCode,
      originalException: exception,
      errors: errors,
    );
  }

  /// Field-specific validation errors.
  ///
  /// Keys are field names, values are lists of error messages for that field.
  final Map<String, List<String>> errors;

  @override
  List<Object?> get props => [...super.props, errors];
}

/// Exception thrown for forbidden requests (403 status code).
///
/// Indicates that the user is authenticated but lacks permission
/// for the requested resource.
class ForbiddenException extends ApiException {
  const ForbiddenException({
    super.message = 'Access forbidden',
    super.originalException,
  }) : super(statusCode: 403);

  /// Creates a ForbiddenException from a DioException.
  factory ForbiddenException.fromDioException(DioException exception) {
    return ForbiddenException(
      message: 'You do not have permission to access this resource',
      originalException: exception,
    );
  }
}

/// Exception thrown when a requested resource is not found (404 status code).
class NotFoundException extends ApiException {
  const NotFoundException({
    super.message = 'Resource not found',
    super.originalException,
  }) : super(statusCode: 404);

  /// Creates a NotFoundException from a DioException.
  factory NotFoundException.fromDioException(DioException exception) {
    return NotFoundException(
      message: 'The requested resource was not found',
      originalException: exception,
    );
  }
}

/// Exception thrown for unexpected or unknown API errors.
///
/// Used as a fallback when the error doesn't match any specific category.
class UnknownApiException extends ApiException {
  const UnknownApiException({
    super.message = 'An unexpected error occurred',
    super.statusCode,
    super.originalException,
  });

  /// Creates an UnknownApiException from a DioException.
  factory UnknownApiException.fromDioException(DioException exception) {
    return UnknownApiException(
      message: exception.message ?? 'An unexpected error occurred',
      statusCode: exception.response?.statusCode,
      originalException: exception,
    );
  }
}
