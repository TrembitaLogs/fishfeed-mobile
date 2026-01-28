import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/core/errors/api_exceptions.dart';

void main() {
  group('ApiException', () {
    group('NetworkException', () {
      test('should have default message', () {
        const exception = NetworkException();

        expect(exception.message, 'No internet connection');
        expect(exception.statusCode, isNull);
      });

      test('should create from DioException with connectionTimeout', () {
        final dioException = DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );

        final exception = NetworkException.fromDioException(dioException);

        expect(exception.message, 'Connection timeout');
        expect(exception.originalException, dioException);
      });

      test('should create from DioException with sendTimeout', () {
        final dioException = DioException(
          type: DioExceptionType.sendTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );

        final exception = NetworkException.fromDioException(dioException);

        expect(exception.message, 'Send timeout');
      });

      test('should create from DioException with receiveTimeout', () {
        final dioException = DioException(
          type: DioExceptionType.receiveTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );

        final exception = NetworkException.fromDioException(dioException);

        expect(exception.message, 'Receive timeout');
      });

      test('should create from DioException with connectionError', () {
        final dioException = DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/test'),
        );

        final exception = NetworkException.fromDioException(dioException);

        expect(exception.message, 'Connection error');
      });

      test('should support equality', () {
        const exception1 = NetworkException(message: 'test');
        const exception2 = NetworkException(message: 'test');
        const exception3 = NetworkException(message: 'different');

        expect(exception1, equals(exception2));
        expect(exception1, isNot(equals(exception3)));
      });
    });

    group('ServerException', () {
      test('should have default message', () {
        const exception = ServerException();

        expect(exception.message, 'Server error occurred');
      });

      test('should create from DioException with 500 status', () {
        final dioException = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 500,
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        final exception = ServerException.fromDioException(dioException);

        expect(exception.message, 'Internal server error');
        expect(exception.statusCode, 500);
      });

      test('should create from DioException with 502 status', () {
        final dioException = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 502,
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        final exception = ServerException.fromDioException(dioException);

        expect(exception.message, 'Bad gateway');
        expect(exception.statusCode, 502);
      });

      test('should create from DioException with 503 status', () {
        final dioException = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 503,
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        final exception = ServerException.fromDioException(dioException);

        expect(exception.message, 'Service unavailable');
        expect(exception.statusCode, 503);
      });

      test('should create from DioException with 504 status', () {
        final dioException = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 504,
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        final exception = ServerException.fromDioException(dioException);

        expect(exception.message, 'Gateway timeout');
        expect(exception.statusCode, 504);
      });
    });

    group('UnauthorizedException', () {
      test('should have default message and status code 401', () {
        const exception = UnauthorizedException();

        expect(exception.message, 'Unauthorized');
        expect(exception.statusCode, 401);
      });

      test('should create from DioException', () {
        final dioException = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 401,
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        final exception = UnauthorizedException.fromDioException(dioException);

        expect(exception.message, 'Authentication required');
        expect(exception.statusCode, 401);
        expect(exception.originalException, dioException);
      });
    });

    group('ForbiddenException', () {
      test('should have default message and status code 403', () {
        const exception = ForbiddenException();

        expect(exception.message, 'Access forbidden');
        expect(exception.statusCode, 403);
      });

      test('should create from DioException', () {
        final dioException = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 403,
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        final exception = ForbiddenException.fromDioException(dioException);

        expect(
          exception.message,
          'You do not have permission to access this resource',
        );
        expect(exception.statusCode, 403);
      });
    });

    group('NotFoundException', () {
      test('should have default message and status code 404', () {
        const exception = NotFoundException();

        expect(exception.message, 'Resource not found');
        expect(exception.statusCode, 404);
      });

      test('should create from DioException', () {
        final dioException = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 404,
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        final exception = NotFoundException.fromDioException(dioException);

        expect(exception.message, 'The requested resource was not found');
        expect(exception.statusCode, 404);
      });
    });

    group('ValidationException', () {
      test('should have default message', () {
        const exception = ValidationException();

        expect(exception.message, 'Validation failed');
        expect(exception.errors, isEmpty);
      });

      test('should create from DioException with errors map', () {
        final dioException = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 422,
            data: {
              'message': 'Validation error',
              'errors': {
                'email': ['Invalid email format', 'Email already taken'],
                'password': ['Password too short'],
              },
            },
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        final exception = ValidationException.fromDioException(dioException);

        expect(exception.message, 'Validation error');
        expect(exception.statusCode, 422);
        expect(exception.errors['email'], ['Invalid email format', 'Email already taken']);
        expect(exception.errors['password'], ['Password too short']);
      });

      test('should handle string errors in response', () {
        final dioException = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: {
              'message': 'Bad request',
              'errors': {
                'email': 'Invalid email',
              },
            },
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        final exception = ValidationException.fromDioException(dioException);

        expect(exception.errors['email'], ['Invalid email']);
      });

      test('should handle missing errors in response', () {
        final dioException = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: {
              'message': 'Bad request',
            },
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        final exception = ValidationException.fromDioException(dioException);

        expect(exception.message, 'Bad request');
        expect(exception.errors, isEmpty);
      });

      test('should handle non-map response data', () {
        final dioException = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
            data: 'Error string',
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        final exception = ValidationException.fromDioException(dioException);

        expect(exception.message, 'Validation failed');
        expect(exception.errors, isEmpty);
      });

      test('should support equality with errors', () {
        const exception1 = ValidationException(
          message: 'error',
          errors: {'field': ['message']},
        );
        const exception2 = ValidationException(
          message: 'error',
          errors: {'field': ['message']},
        );
        const exception3 = ValidationException(
          message: 'error',
          errors: {'field': ['different']},
        );

        expect(exception1, equals(exception2));
        expect(exception1, isNot(equals(exception3)));
      });
    });

    group('UnknownApiException', () {
      test('should have default message', () {
        const exception = UnknownApiException();

        expect(exception.message, 'An unexpected error occurred');
        expect(exception.statusCode, isNull);
      });

      test('should create from DioException', () {
        final dioException = DioException(
          type: DioExceptionType.unknown,
          message: 'Something went wrong',
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 418,
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        final exception = UnknownApiException.fromDioException(dioException);

        expect(exception.message, 'Something went wrong');
        expect(exception.statusCode, 418);
      });

      test('should use default message when DioException message is null', () {
        final dioException = DioException(
          type: DioExceptionType.unknown,
          requestOptions: RequestOptions(path: '/test'),
        );

        final exception = UnknownApiException.fromDioException(dioException);

        expect(exception.message, 'An unexpected error occurred');
      });
    });

    group('toString', () {
      test('should format exception correctly', () {
        const exception = ServerException(
          message: 'Internal server error',
          statusCode: 500,
        );

        expect(
          exception.toString(),
          'ServerException: Internal server error (status: 500)',
        );
      });
    });
  });
}
