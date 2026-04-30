import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

/// Base class for all API-related exceptions.
///
/// Provides a unified interface for handling API errors throughout the app.
/// All API exceptions extend this class and carry an optional [message],
/// [statusCode], [errorCode], and the original [originalException].
sealed class ApiException extends Equatable implements Exception {
  const ApiException({
    this.message,
    this.statusCode,
    this.errorCode,
    this.originalException,
  });

  /// Human-readable error message (English, from backend `detail` field).
  ///
  /// Use [errorCode] for localization mapping; [message] is for logs and as
  /// a last-resort fallback when no [errorCode] mapping exists.
  final String? message;

  /// HTTP status code if available.
  final int? statusCode;

  /// Stable machine-readable error identifier from backend `error_code` field.
  ///
  /// Format: `namespace.identifier`, e.g. `auth.invalid_credentials`.
  /// May be `null` for older API versions or non-domain errors.
  final String? errorCode;

  /// The original exception that caused this error.
  final DioException? originalException;

  @override
  List<Object?> get props => [message, statusCode, errorCode];

  @override
  String toString() =>
      '$runtimeType: $message (status: $statusCode, code: $errorCode)';
}

/// Reads a stable `error_code` string from a Dio response body, if present.
///
/// Returns `null` when the body is missing, not a JSON object, or the field
/// is absent / non-string.
String? _extractErrorCode(DioException exception) {
  final data = exception.response?.data;
  if (data is! Map<String, dynamic>) {
    return null;
  }
  final code = data['error_code'];
  return code is String ? code : null;
}

/// Reads the backend `detail` text, if present.
String? _extractDetail(DioException exception) {
  final data = exception.response?.data;
  if (data is! Map<String, dynamic>) {
    return null;
  }
  final detail = data['detail'];
  return detail is String ? detail : null;
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
    super.errorCode,
    super.originalException,
  });

  /// Creates a ServerException from a DioException.
  factory ServerException.fromDioException(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final detail = _extractDetail(exception);
    final message =
        detail ??
        switch (statusCode) {
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
      errorCode: _extractErrorCode(exception),
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
    super.errorCode,
    super.originalException,
  }) : super(statusCode: 401);

  /// Creates an UnauthorizedException from a DioException.
  factory UnauthorizedException.fromDioException(DioException exception) {
    return UnauthorizedException(
      message: _extractDetail(exception) ?? 'Authentication required',
      errorCode: _extractErrorCode(exception),
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
    super.errorCode,
    super.originalException,
    this.errors = const {},
  });

  /// Creates a ValidationException from a DioException.
  ///
  /// Supports two response shapes:
  ///
  /// 1. New error_code contract (backend ≥ feat/error-code-contract):
  ///    ```json
  ///    {
  ///      "error_code": "validation.error",
  ///      "detail": "Validation failed",
  ///      "errors": [{"loc": ["body", "email"], "msg": "field required", "type": "..."}]
  ///    }
  ///    ```
  ///
  /// 2. Legacy shape (still supported as a fallback):
  ///    ```json
  ///    {
  ///      "message": "Validation failed",
  ///      "errors": {"email": ["Invalid email format"]}
  ///    }
  ///    ```
  factory ValidationException.fromDioException(DioException exception) {
    final response = exception.response;
    final statusCode = response?.statusCode;
    String message = 'Validation failed';
    Map<String, List<String>> errors = {};
    String? errorCode;

    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;

      if (data['error_code'] is String) {
        errorCode = data['error_code'] as String;
      }

      // Prefer `detail` (new contract) over `message` (legacy).
      if (data['detail'] is String) {
        message = data['detail'] as String;
      } else if (data['message'] is String) {
        message = data['message'] as String;
      }

      final rawErrors = data['errors'];
      if (rawErrors is Map<String, dynamic>) {
        // Legacy shape: {field: [messages]}
        errors = rawErrors.map((key, value) {
          if (value is List) {
            return MapEntry(key, value.cast<String>());
          } else if (value is String) {
            return MapEntry(key, [value]);
          }
          return MapEntry(key, <String>[]);
        });
      } else if (rawErrors is List) {
        // New contract: list of Pydantic-style errors.
        // Each entry typically has {loc: [...], msg: "...", type: "..."}.
        // Group by the deepest field name in `loc`.
        final grouped = <String, List<String>>{};
        for (final entry in rawErrors) {
          if (entry is! Map<String, dynamic>) continue;
          final loc = entry['loc'];
          final msg = entry['msg'];
          if (msg is! String) continue;
          final field = loc is List && loc.isNotEmpty
              ? loc.last.toString()
              : '_';
          grouped.putIfAbsent(field, () => <String>[]).add(msg);
        }
        errors = grouped;
      }
    }

    return ValidationException(
      message: message,
      statusCode: statusCode,
      errorCode: errorCode,
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
    super.errorCode,
    super.originalException,
  }) : super(statusCode: 403);

  /// Creates a ForbiddenException from a DioException.
  factory ForbiddenException.fromDioException(DioException exception) {
    return ForbiddenException(
      message:
          _extractDetail(exception) ??
          'You do not have permission to access this resource',
      errorCode: _extractErrorCode(exception),
      originalException: exception,
    );
  }
}

/// Exception thrown when a requested resource is not found (404 status code).
class NotFoundException extends ApiException {
  const NotFoundException({
    super.message = 'Resource not found',
    super.errorCode,
    super.originalException,
  }) : super(statusCode: 404);

  /// Creates a NotFoundException from a DioException.
  factory NotFoundException.fromDioException(DioException exception) {
    return NotFoundException(
      message:
          _extractDetail(exception) ?? 'The requested resource was not found',
      errorCode: _extractErrorCode(exception),
      originalException: exception,
    );
  }
}

/// Exception thrown for conflicts (409 status code).
///
/// Indicates that the request conflicts with the current state of the
/// resource (e.g. duplicate email, version mismatch).
class ConflictException extends ApiException {
  const ConflictException({
    super.message = 'Conflict',
    super.errorCode,
    super.originalException,
  }) : super(statusCode: 409);

  /// Creates a ConflictException from a DioException.
  factory ConflictException.fromDioException(DioException exception) {
    return ConflictException(
      message: _extractDetail(exception) ?? 'Conflict with current state',
      errorCode: _extractErrorCode(exception),
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
    super.errorCode,
    super.originalException,
  });

  /// Creates an UnknownApiException from a DioException.
  factory UnknownApiException.fromDioException(DioException exception) {
    return UnknownApiException(
      message:
          _extractDetail(exception) ??
          exception.message ??
          'An unexpected error occurred',
      statusCode: exception.response?.statusCode,
      errorCode: _extractErrorCode(exception),
      originalException: exception,
    );
  }
}
