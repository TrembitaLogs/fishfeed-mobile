import 'package:dio/dio.dart';
import 'package:fishfeed/core/errors/api_error_codes.dart';
import 'package:fishfeed/core/errors/api_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _dioException({required int statusCode, required Object? data}) {
  final requestOptions = RequestOptions(path: '/test');
  final response = Response<Object?>(
    requestOptions: requestOptions,
    statusCode: statusCode,
    data: data,
  );
  return DioException(
    requestOptions: requestOptions,
    response: response,
    type: DioExceptionType.badResponse,
  );
}

void main() {
  group('ApiException error_code parsing', () {
    test('UnauthorizedException reads error_code from response body', () {
      final exception = UnauthorizedException.fromDioException(
        _dioException(
          statusCode: 401,
          data: <String, dynamic>{
            'error_code': ApiErrorCodes.authInvalidCredentials,
            'detail': 'Invalid email or password',
          },
        ),
      );

      expect(exception.errorCode, ApiErrorCodes.authInvalidCredentials);
      expect(exception.message, 'Invalid email or password');
      expect(exception.statusCode, 401);
    });

    test('ConflictException reads error_code for email-already-exists', () {
      final exception = ConflictException.fromDioException(
        _dioException(
          statusCode: 409,
          data: <String, dynamic>{
            'error_code': ApiErrorCodes.authEmailExists,
            'detail': 'Email already registered',
          },
        ),
      );

      expect(exception.errorCode, ApiErrorCodes.authEmailExists);
      expect(exception.message, 'Email already registered');
      expect(exception.statusCode, 409);
    });

    test('ServerException reads error_code for sync.processing_failed', () {
      final exception = ServerException.fromDioException(
        _dioException(
          statusCode: 500,
          data: <String, dynamic>{
            'error_code': ApiErrorCodes.syncFailed,
            'detail': 'Sync processing failed',
          },
        ),
      );

      expect(exception.errorCode, ApiErrorCodes.syncFailed);
      expect(exception.message, 'Sync processing failed');
    });

    test(
      'ValidationException parses Pydantic-style errors list (new contract)',
      () {
        final exception = ValidationException.fromDioException(
          _dioException(
            statusCode: 422,
            data: <String, dynamic>{
              'error_code': ApiErrorCodes.validationError,
              'detail': 'Validation failed',
              'errors': [
                {
                  'loc': ['body', 'email'],
                  'msg': 'field required',
                  'type': 'missing',
                },
                {
                  'loc': ['body', 'password'],
                  'msg': 'must be at least 8 characters',
                  'type': 'string_too_short',
                },
              ],
            },
          ),
        );

        expect(exception.errorCode, ApiErrorCodes.validationError);
        expect(exception.errors['email'], ['field required']);
        expect(exception.errors['password'], ['must be at least 8 characters']);
      },
    );

    test(
      'ValidationException still parses legacy errors map (backwards compat)',
      () {
        final exception = ValidationException.fromDioException(
          _dioException(
            statusCode: 400,
            data: <String, dynamic>{
              'message': 'Validation failed',
              'errors': <String, dynamic>{
                'email': ['Invalid email format'],
              },
            },
          ),
        );

        expect(exception.errorCode, isNull);
        expect(exception.errors['email'], ['Invalid email format']);
      },
    );

    test('errorCode is null when response body lacks the field', () {
      final exception = UnauthorizedException.fromDioException(
        _dioException(
          statusCode: 401,
          data: <String, dynamic>{'detail': 'Unauthorized'},
        ),
      );

      expect(exception.errorCode, isNull);
    });

    test('errorCode is null when response body is not a JSON object', () {
      final exception = ServerException.fromDioException(
        _dioException(statusCode: 500, data: 'plain text body'),
      );

      expect(exception.errorCode, isNull);
    });
  });
}
