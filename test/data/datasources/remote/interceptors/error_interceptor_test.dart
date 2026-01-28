import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/api_exceptions.dart';
import 'package:fishfeed/data/datasources/remote/interceptors/error_interceptor.dart';

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class FakeDioException extends Fake implements DioException {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDioException());
  });

  group('ErrorInterceptor', () {
    late ErrorInterceptor errorInterceptor;
    late MockErrorInterceptorHandler mockHandler;

    setUp(() {
      errorInterceptor = const ErrorInterceptor();
      mockHandler = MockErrorInterceptorHandler();
    });

    DioException createDioException({
      DioExceptionType type = DioExceptionType.badResponse,
      int? statusCode,
      dynamic data,
    }) {
      return DioException(
        type: type,
        requestOptions: RequestOptions(path: '/test'),
        response: statusCode != null
            ? Response(
                requestOptions: RequestOptions(path: '/test'),
                statusCode: statusCode,
                data: data,
              )
            : null,
      );
    }

    group('network errors', () {
      test('should transform connectionTimeout to NetworkException', () {
        final dioException = createDioException(
          type: DioExceptionType.connectionTimeout,
        );

        errorInterceptor.onError(dioException, mockHandler);

        final captured = verify(() => mockHandler.next(captureAny()))
            .captured
            .single as DioException;
        expect(captured.error, isA<NetworkException>());
        expect(
          (captured.error as NetworkException).message,
          'Connection timeout',
        );
      });

      test('should transform sendTimeout to NetworkException', () {
        final dioException = createDioException(
          type: DioExceptionType.sendTimeout,
        );

        errorInterceptor.onError(dioException, mockHandler);

        final captured = verify(() => mockHandler.next(captureAny()))
            .captured
            .single as DioException;
        expect(captured.error, isA<NetworkException>());
        expect((captured.error as NetworkException).message, 'Send timeout');
      });

      test('should transform receiveTimeout to NetworkException', () {
        final dioException = createDioException(
          type: DioExceptionType.receiveTimeout,
        );

        errorInterceptor.onError(dioException, mockHandler);

        final captured = verify(() => mockHandler.next(captureAny()))
            .captured
            .single as DioException;
        expect(captured.error, isA<NetworkException>());
        expect((captured.error as NetworkException).message, 'Receive timeout');
      });

      test('should transform connectionError to NetworkException', () {
        final dioException = createDioException(
          type: DioExceptionType.connectionError,
        );

        errorInterceptor.onError(dioException, mockHandler);

        final captured = verify(() => mockHandler.next(captureAny()))
            .captured
            .single as DioException;
        expect(captured.error, isA<NetworkException>());
        expect((captured.error as NetworkException).message, 'Connection error');
      });
    });

    group('HTTP status errors', () {
      test('should transform 400 to ValidationException', () {
        final dioException = createDioException(statusCode: 400);

        errorInterceptor.onError(dioException, mockHandler);

        final captured = verify(() => mockHandler.next(captureAny()))
            .captured
            .single as DioException;
        expect(captured.error, isA<ValidationException>());
      });

      test('should transform 422 to ValidationException', () {
        final dioException = createDioException(
          statusCode: 422,
          data: {
            'message': 'Validation error',
            'errors': {
              'email': ['Invalid email'],
            },
          },
        );

        errorInterceptor.onError(dioException, mockHandler);

        final captured = verify(() => mockHandler.next(captureAny()))
            .captured
            .single as DioException;
        expect(captured.error, isA<ValidationException>());
        final exception = captured.error as ValidationException;
        expect(exception.message, 'Validation error');
        expect(exception.errors['email'], ['Invalid email']);
      });

      test('should transform 401 to UnauthorizedException', () {
        final dioException = createDioException(statusCode: 401);

        errorInterceptor.onError(dioException, mockHandler);

        final captured = verify(() => mockHandler.next(captureAny()))
            .captured
            .single as DioException;
        expect(captured.error, isA<UnauthorizedException>());
        expect((captured.error as ApiException).statusCode, 401);
      });

      test('should transform 403 to ForbiddenException', () {
        final dioException = createDioException(statusCode: 403);

        errorInterceptor.onError(dioException, mockHandler);

        final captured = verify(() => mockHandler.next(captureAny()))
            .captured
            .single as DioException;
        expect(captured.error, isA<ForbiddenException>());
        expect((captured.error as ApiException).statusCode, 403);
      });

      test('should transform 404 to NotFoundException', () {
        final dioException = createDioException(statusCode: 404);

        errorInterceptor.onError(dioException, mockHandler);

        final captured = verify(() => mockHandler.next(captureAny()))
            .captured
            .single as DioException;
        expect(captured.error, isA<NotFoundException>());
        expect((captured.error as ApiException).statusCode, 404);
      });

      test('should transform 500 to ServerException', () {
        final dioException = createDioException(statusCode: 500);

        errorInterceptor.onError(dioException, mockHandler);

        final captured = verify(() => mockHandler.next(captureAny()))
            .captured
            .single as DioException;
        expect(captured.error, isA<ServerException>());
        expect(
          (captured.error as ServerException).message,
          'Internal server error',
        );
      });

      test('should transform 502 to ServerException', () {
        final dioException = createDioException(statusCode: 502);

        errorInterceptor.onError(dioException, mockHandler);

        final captured = verify(() => mockHandler.next(captureAny()))
            .captured
            .single as DioException;
        expect(captured.error, isA<ServerException>());
        expect((captured.error as ServerException).message, 'Bad gateway');
      });

      test('should transform 503 to ServerException', () {
        final dioException = createDioException(statusCode: 503);

        errorInterceptor.onError(dioException, mockHandler);

        final captured = verify(() => mockHandler.next(captureAny()))
            .captured
            .single as DioException;
        expect(captured.error, isA<ServerException>());
        expect(
          (captured.error as ServerException).message,
          'Service unavailable',
        );
      });

      test('should transform 504 to ServerException', () {
        final dioException = createDioException(statusCode: 504);

        errorInterceptor.onError(dioException, mockHandler);

        final captured = verify(() => mockHandler.next(captureAny()))
            .captured
            .single as DioException;
        expect(captured.error, isA<ServerException>());
        expect((captured.error as ServerException).message, 'Gateway timeout');
      });

      test('should transform unknown status to UnknownApiException', () {
        final dioException = createDioException(statusCode: 418);

        errorInterceptor.onError(dioException, mockHandler);

        final captured = verify(() => mockHandler.next(captureAny()))
            .captured
            .single as DioException;
        expect(captured.error, isA<UnknownApiException>());
        expect((captured.error as ApiException).statusCode, 418);
      });
    });

    group('edge cases', () {
      test('should handle DioException without response', () {
        final dioException = DioException(
          type: DioExceptionType.unknown,
          requestOptions: RequestOptions(path: '/test'),
        );

        errorInterceptor.onError(dioException, mockHandler);

        final captured = verify(() => mockHandler.next(captureAny()))
            .captured
            .single as DioException;
        expect(captured.error, isA<UnknownApiException>());
      });

      test('should preserve original request options', () {
        final originalOptions = RequestOptions(
          path: '/test',
          method: 'POST',
          headers: {'X-Custom': 'header'},
        );
        final dioException = DioException(
          type: DioExceptionType.badResponse,
          requestOptions: originalOptions,
          response: Response(
            requestOptions: originalOptions,
            statusCode: 500,
          ),
        );

        errorInterceptor.onError(dioException, mockHandler);

        final captured = verify(() => mockHandler.next(captureAny()))
            .captured
            .single as DioException;
        expect(captured.requestOptions.path, '/test');
        expect(captured.requestOptions.method, 'POST');
        expect(captured.requestOptions.headers['X-Custom'], 'header');
      });

      test('should preserve original response', () {
        final dioException = createDioException(
          statusCode: 500,
          data: {'error': 'details'},
        );

        errorInterceptor.onError(dioException, mockHandler);

        final captured = verify(() => mockHandler.next(captureAny()))
            .captured
            .single as DioException;
        expect(captured.response?.statusCode, 500);
        expect(captured.response?.data, {'error': 'details'});
      });
    });
  });
}
