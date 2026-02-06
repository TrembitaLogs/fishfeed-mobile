import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/api_config.dart';
import 'package:fishfeed/core/services/secure_storage_service.dart';
import 'package:fishfeed/data/datasources/remote/api_client.dart';
import 'package:fishfeed/data/datasources/remote/interceptors/interceptors.dart';

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
  });
  group('ApiEnvKeys', () {
    test('should have correct key names', () {
      expect(ApiEnvKeys.baseUrl, 'API_BASE_URL');
    });
  });

  group('ApiTimeouts', () {
    test('should have correct timeout values', () {
      expect(ApiTimeouts.connect, const Duration(seconds: 30));
      expect(ApiTimeouts.receive, const Duration(seconds: 30));
      expect(ApiTimeouts.send, const Duration(seconds: 30));
    });
  });

  group('ApiClient', () {
    late MockDio mockDio;
    late MockSecureStorageService mockSecureStorageService;

    setUp(() {
      mockDio = MockDio();
      mockSecureStorageService = MockSecureStorageService();
    });

    group('constructor', () {
      test('should create instance with default Dio when none provided', () {
        final apiClient = ApiClient(
          secureStorageService: mockSecureStorageService,
          baseUrl: 'https://test.api.com',
        );
        expect(apiClient, isA<ApiClient>());
        expect(apiClient.dio, isA<Dio>());
      });

      test('should use provided Dio instance', () {
        final apiClient = ApiClient(
          secureStorageService: mockSecureStorageService,
          dio: mockDio,
          baseUrl: 'https://test.api.com',
        );
        expect(apiClient.dio, mockDio);
      });

      test('should use provided baseUrl', () {
        const testBaseUrl = 'https://custom.api.com';
        final apiClient = ApiClient(
          secureStorageService: mockSecureStorageService,
          baseUrl: testBaseUrl,
        );

        expect(
          apiClient.dio.options.baseUrl,
          '$testBaseUrl${ApiVersion.pathPrefix}',
        );
      });
    });

    group('configuration', () {
      test('should set correct connect timeout', () {
        final apiClient = ApiClient(
          secureStorageService: mockSecureStorageService,
          baseUrl: 'https://test.api.com',
        );

        expect(apiClient.dio.options.connectTimeout, ApiTimeouts.connect);
      });

      test('should set correct receive timeout', () {
        final apiClient = ApiClient(
          secureStorageService: mockSecureStorageService,
          baseUrl: 'https://test.api.com',
        );

        expect(apiClient.dio.options.receiveTimeout, ApiTimeouts.receive);
      });

      test('should set correct send timeout', () {
        final apiClient = ApiClient(
          secureStorageService: mockSecureStorageService,
          baseUrl: 'https://test.api.com',
        );

        expect(apiClient.dio.options.sendTimeout, ApiTimeouts.send);
      });

      test('should set Content-Type header to application/json', () {
        final apiClient = ApiClient(
          secureStorageService: mockSecureStorageService,
          baseUrl: 'https://test.api.com',
        );

        expect(
          apiClient.dio.options.headers['Content-Type'],
          'application/json',
        );
      });

      test('should set Accept header to application/json', () {
        final apiClient = ApiClient(
          secureStorageService: mockSecureStorageService,
          baseUrl: 'https://test.api.com',
        );

        expect(apiClient.dio.options.headers['Accept'], 'application/json');
      });
    });

    group('interceptors', () {
      test('should have AuthInterceptor', () {
        final apiClient = ApiClient(
          secureStorageService: mockSecureStorageService,
          baseUrl: 'https://test.api.com',
        );

        final hasAuthInterceptor = apiClient.dio.interceptors.any(
          (interceptor) => interceptor is AuthInterceptor,
        );

        expect(hasAuthInterceptor, isTrue);
      });

      test('should have TokenRefreshInterceptor', () {
        final apiClient = ApiClient(
          secureStorageService: mockSecureStorageService,
          baseUrl: 'https://test.api.com',
        );

        final hasTokenRefreshInterceptor = apiClient.dio.interceptors.any(
          (interceptor) => interceptor is TokenRefreshInterceptor,
        );

        expect(hasTokenRefreshInterceptor, isTrue);
      });

      test('should have LogInterceptor in debug mode', () {
        final apiClient = ApiClient(
          secureStorageService: mockSecureStorageService,
          baseUrl: 'https://test.api.com',
        );

        final hasLogInterceptor = apiClient.dio.interceptors.any(
          (interceptor) => interceptor is LogInterceptor,
        );

        // Note: In debug mode (test environment), LogInterceptor should be present
        expect(hasLogInterceptor, isTrue);
      });
    });

    group('baseUrl from dotenv', () {
      setUpAll(() async {
        // Load test environment
        dotenv.testLoad(fileInput: 'API_BASE_URL=https://dotenv.api.com');
      });

      test('should use baseUrl from dotenv when not provided explicitly', () {
        final apiClient = ApiClient(
          secureStorageService: mockSecureStorageService,
        );

        expect(
          apiClient.dio.options.baseUrl,
          'https://dotenv.api.com${ApiVersion.pathPrefix}',
        );
      });

      test('should prefer explicit baseUrl over dotenv', () {
        const explicitUrl = 'https://explicit.api.com';
        final apiClient = ApiClient(
          secureStorageService: mockSecureStorageService,
          baseUrl: explicitUrl,
        );

        expect(
          apiClient.dio.options.baseUrl,
          '$explicitUrl${ApiVersion.pathPrefix}',
        );
      });
    });
  });

  group('apiClientProvider', () {
    test('should provide ApiClient instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final apiClient = container.read(apiClientProvider);

      expect(apiClient, isA<ApiClient>());
    });

    test('should return same instance on multiple reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final apiClient1 = container.read(apiClientProvider);
      final apiClient2 = container.read(apiClientProvider);

      expect(identical(apiClient1, apiClient2), isTrue);
    });
  });

  group('HTTP requests', () {
    late MockSecureStorageService mockSecureStorageService;

    setUp(() {
      mockSecureStorageService = MockSecureStorageService();
    });

    test('should make successful GET request', () async {
      final mockAdapter = MockHttpClientAdapter();
      final dio = Dio();
      dio.httpClientAdapter = mockAdapter;

      final responsePayload = ResponseBody.fromString(
        '{"data": "test"}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

      when(
        () => mockAdapter.fetch(any(), any(), any()),
      ).thenAnswer((_) async => responsePayload);
      when(
        () => mockSecureStorageService.getAccessToken(),
      ).thenAnswer((_) async => 'test-token');

      final apiClient = ApiClient(
        secureStorageService: mockSecureStorageService,
        dio: dio,
        baseUrl: 'https://test.api.com',
      );
      final response = await apiClient.dio.get<Map<String, dynamic>>('/test');

      expect(response.statusCode, 200);
      expect(response.data, {'data': 'test'});

      dio.close();
    });

    test('should make successful POST request with body', () async {
      final mockAdapter = MockHttpClientAdapter();
      final dio = Dio();
      dio.httpClientAdapter = mockAdapter;

      final responsePayload = ResponseBody.fromString(
        '{"id": 1, "created": true}',
        201,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

      when(
        () => mockAdapter.fetch(any(), any(), any()),
      ).thenAnswer((_) async => responsePayload);
      when(
        () => mockSecureStorageService.getAccessToken(),
      ).thenAnswer((_) async => 'test-token');

      final apiClient = ApiClient(
        secureStorageService: mockSecureStorageService,
        dio: dio,
        baseUrl: 'https://test.api.com',
      );
      final response = await apiClient.dio.post<Map<String, dynamic>>(
        '/users',
        data: {'name': 'Test User'},
      );

      expect(response.statusCode, 201);
      expect(response.data, {'id': 1, 'created': true});

      dio.close();
    });

    test('should handle error response', () async {
      final mockAdapter = MockHttpClientAdapter();
      final dio = Dio();
      dio.httpClientAdapter = mockAdapter;

      final errorPayload = ResponseBody.fromString(
        '{"error": "Not Found"}',
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

      when(
        () => mockAdapter.fetch(any(), any(), any()),
      ).thenAnswer((_) async => errorPayload);
      when(
        () => mockSecureStorageService.getAccessToken(),
      ).thenAnswer((_) async => 'test-token');

      final apiClient = ApiClient(
        secureStorageService: mockSecureStorageService,
        dio: dio,
        baseUrl: 'https://test.api.com',
      );

      expect(
        () => apiClient.dio.get<Map<String, dynamic>>('/not-found'),
        throwsA(isA<DioException>()),
      );

      dio.close();
    });
  });
}
