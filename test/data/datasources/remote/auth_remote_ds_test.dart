import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/services/secure_storage_service.dart';
import 'package:fishfeed/data/datasources/remote/api_client.dart';
import 'package:fishfeed/data/datasources/remote/auth_remote_ds.dart';

class MockDio extends Mock implements Dio {
  @override
  BaseOptions options = BaseOptions();

  @override
  Interceptors interceptors = Interceptors();
}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeStream extends Fake implements Stream<List<int>> {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeStream());
    registerFallbackValue(Options());
  });

  group('AuthEndpoints', () {
    test('should have correct endpoint paths', () {
      expect(AuthEndpoints.register, '/auth/register');
      expect(AuthEndpoints.login, '/auth/login');
      expect(AuthEndpoints.oauth, '/auth/oauth');
      expect(AuthEndpoints.refresh, '/auth/refresh');
      expect(AuthEndpoints.logout, '/auth/logout');
    });
  });

  group('AuthRemoteDataSourceImpl', () {
    late MockDio mockDio;
    late AuthRemoteDataSourceImpl dataSource;
    // ignore: unused_local_variable
    late MockHttpClientAdapter mockAdapter;

    final userJson = {
      'id': 'user-123',
      'email': 'test@example.com',
      'display_name': 'Test User',
      'avatar_url': null,
      'created_at': '2024-01-15T10:30:00.000Z',
      'subscription_status': 'free',
      'free_ai_scans_remaining': 5,
    };

    final tokensJson = {
      'access_token': 'access-token-123',
      'refresh_token': 'refresh-token-456',
      'expires_in': 3600,
    };

    final authResponseJson = {
      'user': userJson,
      'access_token': 'access-token-123',
      'refresh_token': 'refresh-token-456',
    };

    setUp(() {
      mockDio = MockDio();
      mockAdapter = MockHttpClientAdapter();
      dataSource = AuthRemoteDataSourceImpl(dio: mockDio);
    });

    group('register', () {
      test('should call POST /auth/register with email and password', () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: authResponseJson,
            statusCode: 201,
            requestOptions: RequestOptions(),
          ),
        );

        await dataSource.register(
          email: 'test@example.com',
          password: 'password123',
        );

        verify(
          () => mockDio.post<Map<String, dynamic>>(
            '/auth/register',
            data: {'email': 'test@example.com', 'password': 'password123'},
          ),
        ).called(1);
      });

      test('should return AuthResponseDto on success', () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: authResponseJson,
            statusCode: 201,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await dataSource.register(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result.user.id, 'user-123');
        expect(result.user.email, 'test@example.com');
        expect(result.tokens.accessToken, 'access-token-123');
        expect(result.tokens.refreshToken, 'refresh-token-456');
      });

      test('should throw DioException on error', () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              statusCode: 400,
              data: {'message': 'Email already exists'},
              requestOptions: RequestOptions(),
            ),
          ),
        );

        expect(
          () => dataSource.register(
            email: 'existing@example.com',
            password: 'password123',
          ),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('login', () {
      test('should call POST /auth/login with email and password', () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: authResponseJson,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        await dataSource.login(
          email: 'test@example.com',
          password: 'password123',
        );

        verify(
          () => mockDio.post<Map<String, dynamic>>(
            '/auth/login',
            data: {'email': 'test@example.com', 'password': 'password123'},
          ),
        ).called(1);
      });

      test('should return AuthResponseDto on success', () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: authResponseJson,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await dataSource.login(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result.user.email, 'test@example.com');
        expect(result.tokens.accessToken, 'access-token-123');
      });

      test('should throw DioException on invalid credentials', () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              statusCode: 401,
              data: {'message': 'Invalid credentials'},
              requestOptions: RequestOptions(),
            ),
          ),
        );

        expect(
          () => dataSource.login(
            email: 'test@example.com',
            password: 'wrong-password',
          ),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('oauthLogin', () {
      test('should call POST /auth/oauth with provider and idToken', () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: authResponseJson,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        await dataSource.oauthLogin(
          provider: 'google',
          idToken: 'google-id-token-123',
        );

        verify(
          () => mockDio.post<Map<String, dynamic>>(
            '/auth/oauth',
            data: {'provider': 'google', 'id_token': 'google-id-token-123'},
          ),
        ).called(1);
      });

      test('should return AuthResponseDto for Google login', () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: authResponseJson,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await dataSource.oauthLogin(
          provider: 'google',
          idToken: 'google-id-token-123',
        );

        expect(result.user.id, 'user-123');
        expect(result.tokens.accessToken, 'access-token-123');
      });

      test('should return AuthResponseDto for Apple login', () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: authResponseJson,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await dataSource.oauthLogin(
          provider: 'apple',
          idToken: 'apple-id-token-123',
        );

        expect(result.user.id, 'user-123');
      });

      test('should throw DioException on invalid token', () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              statusCode: 401,
              data: {'message': 'Invalid OAuth token'},
              requestOptions: RequestOptions(),
            ),
          ),
        );

        expect(
          () => dataSource.oauthLogin(
            provider: 'google',
            idToken: 'invalid-token',
          ),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('refreshToken', () {
      test('should call POST /auth/refresh with refresh token', () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: tokensJson,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        await dataSource.refreshToken(refreshToken: 'old-refresh-token');

        verify(
          () => mockDio.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refresh_token': 'old-refresh-token'},
            options: any(named: 'options'),
          ),
        ).called(1);
      });

      test('should return TokenPairDto on success', () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: tokensJson,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await dataSource.refreshToken(
          refreshToken: 'old-refresh-token',
        );

        expect(result.accessToken, 'access-token-123');
        expect(result.refreshToken, 'refresh-token-456');
        expect(result.expiresIn, 3600);
      });

      test('should throw DioException on expired refresh token', () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              statusCode: 401,
              data: {'message': 'Refresh token expired'},
              requestOptions: RequestOptions(),
            ),
          ),
        );

        expect(
          () => dataSource.refreshToken(refreshToken: 'expired-token'),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('logout', () {
      test('should call POST /auth/logout with refresh token', () async {
        when(
          () => mockDio.post<void>(any(), data: any(named: 'data')),
        ).thenAnswer(
          (_) async =>
              Response(statusCode: 200, requestOptions: RequestOptions()),
        );

        await dataSource.logout(refreshToken: 'refresh-token-to-invalidate');

        verify(
          () => mockDio.post<void>(
            '/auth/logout',
            data: {'refresh_token': 'refresh-token-to-invalidate'},
          ),
        ).called(1);
      });

      test('should complete without error on success', () async {
        when(
          () => mockDio.post<void>(any(), data: any(named: 'data')),
        ).thenAnswer(
          (_) async =>
              Response(statusCode: 200, requestOptions: RequestOptions()),
        );

        await expectLater(
          dataSource.logout(refreshToken: 'valid-token'),
          completes,
        );
      });

      test('should throw DioException on server error', () async {
        when(
          () => mockDio.post<void>(any(), data: any(named: 'data')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              statusCode: 500,
              data: {'message': 'Server error'},
              requestOptions: RequestOptions(),
            ),
          ),
        );

        expect(
          () => dataSource.logout(refreshToken: 'any-token'),
          throwsA(isA<DioException>()),
        );
      });
    });
  });

  group('authRemoteDataSourceProvider', () {
    test('should provide AuthRemoteDataSource instance', () {
      final container = ProviderContainer(
        overrides: [
          secureStorageServiceProvider.overrideWithValue(
            MockSecureStorageService(),
          ),
          apiClientProvider.overrideWithValue(
            ApiClient(
              secureStorageService: MockSecureStorageService(),
              baseUrl: 'https://test.api.com',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final authRemoteDs = container.read(authRemoteDataSourceProvider);

      expect(authRemoteDs, isA<AuthRemoteDataSource>());
      expect(authRemoteDs, isA<AuthRemoteDataSourceImpl>());
    });
  });
}
