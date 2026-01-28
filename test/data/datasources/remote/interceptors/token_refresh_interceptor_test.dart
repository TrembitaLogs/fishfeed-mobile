import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/services/secure_storage_service.dart';
import 'package:fishfeed/data/datasources/remote/interceptors/token_refresh_interceptor.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockDio extends Mock implements Dio {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeResponse extends Fake implements Response<dynamic> {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeResponse());
    registerFallbackValue(
      DioException(requestOptions: RequestOptions(path: '')),
    );
    registerFallbackValue(Options());
  });

  group('TokenRefreshInterceptor', () {
    late MockSecureStorageService mockSecureStorageService;
    late MockDio mockDio;
    late MockErrorInterceptorHandler mockHandler;
    late TokenRefreshInterceptor tokenRefreshInterceptor;
    late bool logoutCalled;

    setUp(() {
      mockSecureStorageService = MockSecureStorageService();
      mockDio = MockDio();
      mockHandler = MockErrorInterceptorHandler();
      logoutCalled = false;

      tokenRefreshInterceptor = TokenRefreshInterceptor(
        secureStorageService: mockSecureStorageService,
        dio: mockDio,
        onLogout: () async {
          logoutCalled = true;
        },
      );
    });

    group('onError', () {
      test('should pass through non-401 errors', () async {
        final requestOptions = RequestOptions(path: '/api/users');
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(requestOptions: requestOptions, statusCode: 500),
        );

        await tokenRefreshInterceptor.onError(error, mockHandler);

        verify(() => mockHandler.next(error)).called(1);
        verifyNever(() => mockSecureStorageService.getRefreshToken());
      });

      test('should logout on 401 from refresh endpoint', () async {
        final requestOptions = RequestOptions(path: '/auth/refresh');
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(requestOptions: requestOptions, statusCode: 401),
        );

        when(
          () => mockSecureStorageService.clearTokens(),
        ).thenAnswer((_) async {});

        await tokenRefreshInterceptor.onError(error, mockHandler);

        verify(() => mockSecureStorageService.clearTokens()).called(1);
        expect(logoutCalled, isTrue);
        verify(() => mockHandler.next(error)).called(1);
      });

      test('should logout when refresh token is null', () async {
        final requestOptions = RequestOptions(path: '/api/users');
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(requestOptions: requestOptions, statusCode: 401),
        );

        when(
          () => mockSecureStorageService.getRefreshToken(),
        ).thenAnswer((_) async => null);
        when(
          () => mockSecureStorageService.clearTokens(),
        ).thenAnswer((_) async {});

        await tokenRefreshInterceptor.onError(error, mockHandler);

        verify(() => mockSecureStorageService.clearTokens()).called(1);
        expect(logoutCalled, isTrue);
        verify(() => mockHandler.next(error)).called(1);
      });

      test('should logout when refresh token is empty', () async {
        final requestOptions = RequestOptions(path: '/api/users');
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(requestOptions: requestOptions, statusCode: 401),
        );

        when(
          () => mockSecureStorageService.getRefreshToken(),
        ).thenAnswer((_) async => '');
        when(
          () => mockSecureStorageService.clearTokens(),
        ).thenAnswer((_) async {});

        await tokenRefreshInterceptor.onError(error, mockHandler);

        verify(() => mockSecureStorageService.clearTokens()).called(1);
        expect(logoutCalled, isTrue);
        verify(() => mockHandler.next(error)).called(1);
      });

      test('should refresh token and retry request on 401', () async {
        final requestOptions = RequestOptions(
          path: '/api/users',
          headers: {'Authorization': 'Bearer old-token'},
        );
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(requestOptions: requestOptions, statusCode: 401),
        );

        const refreshToken = 'valid-refresh-token';
        const newAccessToken = 'new-access-token';
        const newRefreshToken = 'new-refresh-token';

        when(
          () => mockSecureStorageService.getRefreshToken(),
        ).thenAnswer((_) async => refreshToken);
        when(
          () => mockSecureStorageService.setAccessToken(newAccessToken),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorageService.setRefreshToken(newRefreshToken),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorageService.getAccessToken(),
        ).thenAnswer((_) async => newAccessToken);

        when(
          () => mockDio.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/auth/refresh'),
            statusCode: 200,
            data: {
              'access_token': newAccessToken,
              'refresh_token': newRefreshToken,
            },
          ),
        );

        final retryResponse = Response<dynamic>(
          requestOptions: requestOptions,
          statusCode: 200,
          data: {'user': 'data'},
        );

        when(
          () => mockDio.fetch<dynamic>(any()),
        ).thenAnswer((_) async => retryResponse);

        await tokenRefreshInterceptor.onError(error, mockHandler);

        verify(
          () => mockSecureStorageService.setAccessToken(newAccessToken),
        ).called(1);
        verify(
          () => mockSecureStorageService.setRefreshToken(newRefreshToken),
        ).called(1);
        verify(() => mockHandler.resolve(retryResponse)).called(1);
      });

      test('should logout when refresh request returns 401', () async {
        final requestOptions = RequestOptions(path: '/api/users');
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(requestOptions: requestOptions, statusCode: 401),
        );

        const refreshToken = 'expired-refresh-token';

        when(
          () => mockSecureStorageService.getRefreshToken(),
        ).thenAnswer((_) async => refreshToken);
        when(
          () => mockSecureStorageService.clearTokens(),
        ).thenAnswer((_) async {});

        when(
          () => mockDio.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/refresh'),
            response: Response(
              requestOptions: RequestOptions(path: '/auth/refresh'),
              statusCode: 401,
            ),
          ),
        );

        await tokenRefreshInterceptor.onError(error, mockHandler);

        verify(() => mockSecureStorageService.clearTokens()).called(1);
        expect(logoutCalled, isTrue);
        verify(() => mockHandler.next(error)).called(1);
      });

      test('should pass error through when retry request fails', () async {
        final requestOptions = RequestOptions(path: '/api/users');
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(requestOptions: requestOptions, statusCode: 401),
        );

        const refreshToken = 'valid-refresh-token';
        const newAccessToken = 'new-access-token';

        when(
          () => mockSecureStorageService.getRefreshToken(),
        ).thenAnswer((_) async => refreshToken);
        when(
          () => mockSecureStorageService.setAccessToken(newAccessToken),
        ).thenAnswer((_) async {});
        when(
          () => mockSecureStorageService.getAccessToken(),
        ).thenAnswer((_) async => newAccessToken);

        when(
          () => mockDio.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/auth/refresh'),
            statusCode: 200,
            data: {'access_token': newAccessToken},
          ),
        );

        when(() => mockDio.fetch<dynamic>(any())).thenThrow(
          DioException(
            requestOptions: requestOptions,
            type: DioExceptionType.connectionError,
          ),
        );

        await tokenRefreshInterceptor.onError(error, mockHandler);

        verify(() => mockHandler.next(error)).called(1);
      });

      test('should logout when refresh response is invalid', () async {
        final requestOptions = RequestOptions(path: '/api/users');
        final error = DioException(
          requestOptions: requestOptions,
          response: Response(requestOptions: requestOptions, statusCode: 401),
        );

        const refreshToken = 'valid-refresh-token';

        when(
          () => mockSecureStorageService.getRefreshToken(),
        ).thenAnswer((_) async => refreshToken);
        when(
          () => mockSecureStorageService.clearTokens(),
        ).thenAnswer((_) async {});

        when(
          () => mockDio.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/auth/refresh'),
            statusCode: 200,
            data: <String, dynamic>{}, // Missing access_token
          ),
        );

        await tokenRefreshInterceptor.onError(error, mockHandler);

        verify(() => mockSecureStorageService.clearTokens()).called(1);
        expect(logoutCalled, isTrue);
        verify(() => mockHandler.next(error)).called(1);
      });
    });
  });
}
