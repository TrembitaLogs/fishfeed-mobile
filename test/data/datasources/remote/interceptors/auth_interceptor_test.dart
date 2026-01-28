import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/services/secure_storage_service.dart';
import 'package:fishfeed/data/datasources/remote/interceptors/auth_interceptor.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  group('AuthInterceptor', () {
    late MockSecureStorageService mockSecureStorageService;
    late MockRequestInterceptorHandler mockHandler;
    late AuthInterceptor authInterceptor;

    setUp(() {
      mockSecureStorageService = MockSecureStorageService();
      mockHandler = MockRequestInterceptorHandler();
      authInterceptor = AuthInterceptor(
        secureStorageService: mockSecureStorageService,
      );
    });

    group('onRequest', () {
      test('should add Authorization header when token exists', () async {
        const accessToken = 'test-access-token';
        when(
          () => mockSecureStorageService.getAccessToken(),
        ).thenAnswer((_) async => accessToken);

        final options = RequestOptions(path: '/api/users');

        await authInterceptor.onRequest(options, mockHandler);

        expect(options.headers['Authorization'], 'Bearer $accessToken');
        verify(() => mockHandler.next(options)).called(1);
      });

      test('should not add Authorization header when token is null', () async {
        when(
          () => mockSecureStorageService.getAccessToken(),
        ).thenAnswer((_) async => null);

        final options = RequestOptions(path: '/api/users');

        await authInterceptor.onRequest(options, mockHandler);

        expect(options.headers.containsKey('Authorization'), isFalse);
        verify(() => mockHandler.next(options)).called(1);
      });

      test('should not add Authorization header when token is empty', () async {
        when(
          () => mockSecureStorageService.getAccessToken(),
        ).thenAnswer((_) async => '');

        final options = RequestOptions(path: '/api/users');

        await authInterceptor.onRequest(options, mockHandler);

        expect(options.headers.containsKey('Authorization'), isFalse);
        verify(() => mockHandler.next(options)).called(1);
      });

      test('should skip auth for login endpoint', () async {
        final options = RequestOptions(path: '/auth/login');

        await authInterceptor.onRequest(options, mockHandler);

        verifyNever(() => mockSecureStorageService.getAccessToken());
        expect(options.headers.containsKey('Authorization'), isFalse);
        verify(() => mockHandler.next(options)).called(1);
      });

      test('should skip auth for register endpoint', () async {
        final options = RequestOptions(path: '/auth/register');

        await authInterceptor.onRequest(options, mockHandler);

        verifyNever(() => mockSecureStorageService.getAccessToken());
        expect(options.headers.containsKey('Authorization'), isFalse);
        verify(() => mockHandler.next(options)).called(1);
      });

      test('should skip auth for refresh endpoint', () async {
        final options = RequestOptions(path: '/auth/refresh');

        await authInterceptor.onRequest(options, mockHandler);

        verifyNever(() => mockSecureStorageService.getAccessToken());
        expect(options.headers.containsKey('Authorization'), isFalse);
        verify(() => mockHandler.next(options)).called(1);
      });

      test('should skip auth for oauth endpoint', () async {
        final options = RequestOptions(path: '/auth/oauth');

        await authInterceptor.onRequest(options, mockHandler);

        verifyNever(() => mockSecureStorageService.getAccessToken());
        expect(options.headers.containsKey('Authorization'), isFalse);
        verify(() => mockHandler.next(options)).called(1);
      });

      test('should add auth for non-public endpoints', () async {
        const accessToken = 'valid-token';
        when(
          () => mockSecureStorageService.getAccessToken(),
        ).thenAnswer((_) async => accessToken);

        final options = RequestOptions(path: '/api/aquariums');

        await authInterceptor.onRequest(options, mockHandler);

        expect(options.headers['Authorization'], 'Bearer $accessToken');
        verify(() => mockHandler.next(options)).called(1);
      });

      test('should handle path with query parameters', () async {
        const accessToken = 'valid-token';
        when(
          () => mockSecureStorageService.getAccessToken(),
        ).thenAnswer((_) async => accessToken);

        final options = RequestOptions(path: '/api/users?page=1&limit=10');

        await authInterceptor.onRequest(options, mockHandler);

        expect(options.headers['Authorization'], 'Bearer $accessToken');
        verify(() => mockHandler.next(options)).called(1);
      });
    });
  });
}
