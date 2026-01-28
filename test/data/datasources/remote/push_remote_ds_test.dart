import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/remote/push_remote_ds.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late PushRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDio = MockDio();
    dataSource = PushRemoteDataSourceImpl(dio: mockDio);
  });

  group('PushEndpoints', () {
    test('should have correct token endpoint', () {
      expect(PushEndpoints.token, '/push/token');
    });
  });

  group('registerToken', () {
    test('should call POST with correct data', () async {
      when(
        () => mockDio.post<void>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async =>
            Response(requestOptions: RequestOptions(), statusCode: 200),
      );

      await dataSource.registerToken(
        token: 'test-fcm-token',
        platform: 'android',
      );

      verify(
        () => mockDio.post<void>(
          '/push/token',
          data: {'token': 'test-fcm-token', 'platform': 'android'},
        ),
      ).called(1);
    });

    test('should register iOS token correctly', () async {
      when(
        () => mockDio.post<void>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async =>
            Response(requestOptions: RequestOptions(), statusCode: 200),
      );

      await dataSource.registerToken(token: 'test-apns-token', platform: 'ios');

      verify(
        () => mockDio.post<void>(
          '/push/token',
          data: {'token': 'test-apns-token', 'platform': 'ios'},
        ),
      ).called(1);
    });

    test('should throw DioException on network error', () async {
      when(() => mockDio.post<void>(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () =>
            dataSource.registerToken(token: 'test-token', platform: 'android'),
        throwsA(isA<DioException>()),
      );
    });

    test('should throw DioException on server error', () async {
      when(() => mockDio.post<void>(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(requestOptions: RequestOptions(), statusCode: 500),
        ),
      );

      expect(
        () =>
            dataSource.registerToken(token: 'test-token', platform: 'android'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('unregisterToken', () {
    test('should call DELETE on token endpoint', () async {
      when(() => mockDio.delete<void>(any())).thenAnswer(
        (_) async =>
            Response(requestOptions: RequestOptions(), statusCode: 200),
      );

      await dataSource.unregisterToken();

      verify(() => mockDio.delete<void>('/push/token')).called(1);
    });

    test('should throw DioException on network error', () async {
      when(() => mockDio.delete<void>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(() => dataSource.unregisterToken(), throwsA(isA<DioException>()));
    });
  });
}
