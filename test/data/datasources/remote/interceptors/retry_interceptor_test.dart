import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/remote/interceptors/retry_interceptor.dart';

class MockDio extends Mock implements Dio {}

class MockConnectivityChecker extends Mock implements ConnectivityChecker {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeDioException extends Fake implements DioException {}

class FakeResponse extends Fake implements Response<dynamic> {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeDioException());
    registerFallbackValue(FakeResponse());
  });

  group('RetryInterceptor', () {
    late MockDio mockDio;
    late MockConnectivityChecker mockConnectivityChecker;
    late MockErrorInterceptorHandler mockHandler;
    late RetryInterceptor retryInterceptor;

    setUp(() {
      mockDio = MockDio();
      mockConnectivityChecker = MockConnectivityChecker();
      mockHandler = MockErrorInterceptorHandler();

      retryInterceptor = RetryInterceptor(
        dio: mockDio,
        connectivityChecker: mockConnectivityChecker,
        config: const RetryConfig(
          maxRetries: 3,
          initialDelay: Duration(milliseconds: 10),
          maxDelay: Duration(milliseconds: 100),
        ),
      );
    });

    DioException createDioException({
      DioExceptionType type = DioExceptionType.badResponse,
      int? statusCode,
      String method = 'GET',
      Map<String, dynamic>? extra,
    }) {
      final options = RequestOptions(path: '/test', method: method);
      if (extra != null) {
        options.extra = extra;
      }
      return DioException(
        type: type,
        requestOptions: options,
        response: statusCode != null
            ? Response(requestOptions: options, statusCode: statusCode)
            : null,
      );
    }

    group('should retry', () {
      test('on connectionTimeout', () async {
        when(
          () => mockConnectivityChecker.hasConnection(),
        ).thenAnswer((_) async => true);
        when(() => mockDio.fetch<dynamic>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 200,
          ),
        );

        final dioException = createDioException(
          type: DioExceptionType.connectionTimeout,
        );

        await retryInterceptor.onError(dioException, mockHandler);

        verify(() => mockDio.fetch<dynamic>(any())).called(1);
        verify(() => mockHandler.resolve(any())).called(1);
      });

      test('on sendTimeout', () async {
        when(
          () => mockConnectivityChecker.hasConnection(),
        ).thenAnswer((_) async => true);
        when(() => mockDio.fetch<dynamic>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 200,
          ),
        );

        final dioException = createDioException(
          type: DioExceptionType.sendTimeout,
        );

        await retryInterceptor.onError(dioException, mockHandler);

        verify(() => mockDio.fetch<dynamic>(any())).called(1);
        verify(() => mockHandler.resolve(any())).called(1);
      });

      test('on receiveTimeout', () async {
        when(
          () => mockConnectivityChecker.hasConnection(),
        ).thenAnswer((_) async => true);
        when(() => mockDio.fetch<dynamic>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 200,
          ),
        );

        final dioException = createDioException(
          type: DioExceptionType.receiveTimeout,
        );

        await retryInterceptor.onError(dioException, mockHandler);

        verify(() => mockDio.fetch<dynamic>(any())).called(1);
      });

      test('on connectionError', () async {
        when(
          () => mockConnectivityChecker.hasConnection(),
        ).thenAnswer((_) async => true);
        when(() => mockDio.fetch<dynamic>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 200,
          ),
        );

        final dioException = createDioException(
          type: DioExceptionType.connectionError,
        );

        await retryInterceptor.onError(dioException, mockHandler);

        verify(() => mockDio.fetch<dynamic>(any())).called(1);
      });

      test('on 500 status code', () async {
        when(
          () => mockConnectivityChecker.hasConnection(),
        ).thenAnswer((_) async => true);
        when(() => mockDio.fetch<dynamic>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 200,
          ),
        );

        final dioException = createDioException(statusCode: 500);

        await retryInterceptor.onError(dioException, mockHandler);

        verify(() => mockDio.fetch<dynamic>(any())).called(1);
      });

      test('on 502 status code', () async {
        when(
          () => mockConnectivityChecker.hasConnection(),
        ).thenAnswer((_) async => true);
        when(() => mockDio.fetch<dynamic>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 200,
          ),
        );

        final dioException = createDioException(statusCode: 502);

        await retryInterceptor.onError(dioException, mockHandler);

        verify(() => mockDio.fetch<dynamic>(any())).called(1);
      });

      test('on 503 status code', () async {
        when(
          () => mockConnectivityChecker.hasConnection(),
        ).thenAnswer((_) async => true);
        when(() => mockDio.fetch<dynamic>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 200,
          ),
        );

        final dioException = createDioException(statusCode: 503);

        await retryInterceptor.onError(dioException, mockHandler);

        verify(() => mockDio.fetch<dynamic>(any())).called(1);
      });

      test('on 504 status code', () async {
        when(
          () => mockConnectivityChecker.hasConnection(),
        ).thenAnswer((_) async => true);
        when(() => mockDio.fetch<dynamic>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 200,
          ),
        );

        final dioException = createDioException(statusCode: 504);

        await retryInterceptor.onError(dioException, mockHandler);

        verify(() => mockDio.fetch<dynamic>(any())).called(1);
      });

      test('on 429 (rate limit) status code', () async {
        when(
          () => mockConnectivityChecker.hasConnection(),
        ).thenAnswer((_) async => true);
        when(() => mockDio.fetch<dynamic>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 200,
          ),
        );

        final dioException = createDioException(statusCode: 429);

        await retryInterceptor.onError(dioException, mockHandler);

        verify(() => mockDio.fetch<dynamic>(any())).called(1);
      });
    });

    group('should not retry', () {
      test('on cancel', () async {
        final dioException = createDioException(type: DioExceptionType.cancel);

        await retryInterceptor.onError(dioException, mockHandler);

        verifyNever(() => mockConnectivityChecker.hasConnection());
        verifyNever(() => mockDio.fetch<dynamic>(any()));
        verify(() => mockHandler.next(dioException)).called(1);
      });

      test('on 400 status code', () async {
        final dioException = createDioException(statusCode: 400);

        await retryInterceptor.onError(dioException, mockHandler);

        verifyNever(() => mockConnectivityChecker.hasConnection());
        verifyNever(() => mockDio.fetch<dynamic>(any()));
        verify(() => mockHandler.next(dioException)).called(1);
      });

      test('on 401 status code', () async {
        final dioException = createDioException(statusCode: 401);

        await retryInterceptor.onError(dioException, mockHandler);

        verifyNever(() => mockConnectivityChecker.hasConnection());
        verifyNever(() => mockDio.fetch<dynamic>(any()));
        verify(() => mockHandler.next(dioException)).called(1);
      });

      test('on 403 status code', () async {
        final dioException = createDioException(statusCode: 403);

        await retryInterceptor.onError(dioException, mockHandler);

        verifyNever(() => mockConnectivityChecker.hasConnection());
        verifyNever(() => mockDio.fetch<dynamic>(any()));
        verify(() => mockHandler.next(dioException)).called(1);
      });

      test('on 404 status code', () async {
        final dioException = createDioException(statusCode: 404);

        await retryInterceptor.onError(dioException, mockHandler);

        verifyNever(() => mockConnectivityChecker.hasConnection());
        verifyNever(() => mockDio.fetch<dynamic>(any()));
        verify(() => mockHandler.next(dioException)).called(1);
      });

      test('on POST request by default', () async {
        final dioException = createDioException(
          type: DioExceptionType.connectionTimeout,
          method: 'POST',
        );

        await retryInterceptor.onError(dioException, mockHandler);

        verifyNever(() => mockConnectivityChecker.hasConnection());
        verifyNever(() => mockDio.fetch<dynamic>(any()));
        verify(() => mockHandler.next(dioException)).called(1);
      });

      test('on PUT request by default', () async {
        final dioException = createDioException(
          type: DioExceptionType.connectionTimeout,
          method: 'PUT',
        );

        await retryInterceptor.onError(dioException, mockHandler);

        verifyNever(() => mockDio.fetch<dynamic>(any()));
        verify(() => mockHandler.next(dioException)).called(1);
      });

      test('on PATCH request by default', () async {
        final dioException = createDioException(
          type: DioExceptionType.connectionTimeout,
          method: 'PATCH',
        );

        await retryInterceptor.onError(dioException, mockHandler);

        verifyNever(() => mockDio.fetch<dynamic>(any()));
        verify(() => mockHandler.next(dioException)).called(1);
      });

      test('on DELETE request by default', () async {
        final dioException = createDioException(
          type: DioExceptionType.connectionTimeout,
          method: 'DELETE',
        );

        await retryInterceptor.onError(dioException, mockHandler);

        verifyNever(() => mockDio.fetch<dynamic>(any()));
        verify(() => mockHandler.next(dioException)).called(1);
      });

      test('when no connectivity', () async {
        when(
          () => mockConnectivityChecker.hasConnection(),
        ).thenAnswer((_) async => false);

        final dioException = createDioException(
          type: DioExceptionType.connectionTimeout,
        );

        await retryInterceptor.onError(dioException, mockHandler);

        verify(() => mockConnectivityChecker.hasConnection()).called(1);
        verifyNever(() => mockDio.fetch<dynamic>(any()));
        verify(() => mockHandler.next(dioException)).called(1);
      });
    });

    group('retry with mutating requests enabled', () {
      setUp(() {
        retryInterceptor = RetryInterceptor(
          dio: mockDio,
          connectivityChecker: mockConnectivityChecker,
          retryMutatingRequests: true,
          config: const RetryConfig(
            maxRetries: 3,
            initialDelay: Duration(milliseconds: 10),
            maxDelay: Duration(milliseconds: 100),
          ),
        );
      });

      test('should retry POST when retryMutatingRequests is true', () async {
        when(
          () => mockConnectivityChecker.hasConnection(),
        ).thenAnswer((_) async => true);
        when(() => mockDio.fetch<dynamic>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 200,
          ),
        );

        final dioException = createDioException(
          type: DioExceptionType.connectionTimeout,
          method: 'POST',
        );

        await retryInterceptor.onError(dioException, mockHandler);

        verify(() => mockDio.fetch<dynamic>(any())).called(1);
      });
    });

    group('max retries', () {
      test('should stop after max retries reached', () async {
        when(
          () => mockConnectivityChecker.hasConnection(),
        ).thenAnswer((_) async => true);

        final dioException = createDioException(
          type: DioExceptionType.connectionTimeout,
          extra: {'retry_count': 3},
        );

        await retryInterceptor.onError(dioException, mockHandler);

        verifyNever(() => mockDio.fetch<dynamic>(any()));
        verify(() => mockHandler.next(dioException)).called(1);
      });

      test('should increment retry count on each attempt', () async {
        when(
          () => mockConnectivityChecker.hasConnection(),
        ).thenAnswer((_) async => true);
        when(() => mockDio.fetch<dynamic>(any())).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 200,
          ),
        );

        final dioException = createDioException(
          type: DioExceptionType.connectionTimeout,
        );

        await retryInterceptor.onError(dioException, mockHandler);

        final captured =
            verify(() => mockDio.fetch<dynamic>(captureAny())).captured.single
                as RequestOptions;
        expect(captured.extra['retry_count'], 1);
      });
    });

    group('retry failure handling', () {
      test('should pass error to handler when retry fails', () async {
        when(
          () => mockConnectivityChecker.hasConnection(),
        ).thenAnswer((_) async => true);

        final retryError = DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );
        when(() => mockDio.fetch<dynamic>(any())).thenThrow(retryError);

        final dioException = createDioException(
          type: DioExceptionType.connectionTimeout,
        );

        await retryInterceptor.onError(dioException, mockHandler);

        verify(() => mockHandler.next(retryError)).called(1);
      });
    });
  });

  group('RetryConfig', () {
    test('should have correct default values', () {
      const config = RetryConfig();

      expect(config.maxRetries, 3);
      expect(config.initialDelay, const Duration(seconds: 1));
      expect(config.maxDelay, const Duration(seconds: 8));
      expect(config.backoffMultiplier, 2.0);
      expect(config.retryableStatusCodes, [408, 429, 500, 502, 503, 504]);
    });
  });

  group('DefaultConnectivityChecker', () {
    test('should be instantiable', () {
      final checker = DefaultConnectivityChecker();
      expect(checker, isA<ConnectivityChecker>());
    });
  });
}
