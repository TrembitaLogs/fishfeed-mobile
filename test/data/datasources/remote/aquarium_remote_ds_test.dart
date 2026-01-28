import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/api_config.dart';
import 'package:fishfeed/core/services/secure_storage_service.dart';
import 'package:fishfeed/data/datasources/remote/api_client.dart';
import 'package:fishfeed/data/datasources/remote/aquarium_remote_ds.dart';
import 'package:fishfeed/domain/entities/water_type.dart';

class MockDio extends Mock implements Dio {
  @override
  BaseOptions options = BaseOptions();

  @override
  Interceptors interceptors = Interceptors();
}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(Options());
  });

  group('AquariumRemoteDataSourceImpl', () {
    late MockDio mockDio;
    late AquariumRemoteDataSourceImpl dataSource;

    final aquariumJson = {
      'id': 'aquarium-123',
      'owner_id': 'user-456',
      'name': 'Living Room Tank',
      'capacity': 50.0,
      'water_type': 'freshwater',
      'image_url': null,
      'created_at': '2024-01-15T10:30:00.000Z',
    };

    final aquariumListJson = [
      aquariumJson,
      {
        'id': 'aquarium-456',
        'owner_id': 'user-456',
        'name': 'Bedroom Tank',
        'capacity': 30.0,
        'water_type': 'saltwater',
        'image_url': 'https://example.com/image.jpg',
        'created_at': '2024-01-16T10:30:00.000Z',
      },
    ];

    setUp(() {
      mockDio = MockDio();
      dataSource = AquariumRemoteDataSourceImpl(dio: mockDio);
    });

    group('createAquarium', () {
      test('should call POST /aquariums with name only', () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: aquariumJson,
            statusCode: 201,
            requestOptions: RequestOptions(),
          ),
        );

        await dataSource.createAquarium(name: 'Living Room Tank');

        verify(
          () => mockDio.post<Map<String, dynamic>>(
            ApiEndpoints.aquariums,
            data: {'name': 'Living Room Tank'},
          ),
        ).called(1);
      });

      test('should call POST /aquariums with all parameters', () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: aquariumJson,
            statusCode: 201,
            requestOptions: RequestOptions(),
          ),
        );

        await dataSource.createAquarium(
          name: 'Living Room Tank',
          waterType: WaterType.freshwater,
          capacity: 50.0,
        );

        verify(
          () => mockDio.post<Map<String, dynamic>>(
            ApiEndpoints.aquariums,
            data: {
              'name': 'Living Room Tank',
              'water_type': 'freshwater',
              'capacity': 50.0,
            },
          ),
        ).called(1);
      });

      test('should return AquariumDto on success', () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: aquariumJson,
            statusCode: 201,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await dataSource.createAquarium(
          name: 'Living Room Tank',
        );

        expect(result.id, 'aquarium-123');
        expect(result.userId, 'user-456');
        expect(result.name, 'Living Room Tank');
        expect(result.capacity, 50.0);
        expect(result.waterType, 'freshwater');
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
              data: {'message': 'Validation failed'},
              requestOptions: RequestOptions(),
            ),
          ),
        );

        expect(
          () => dataSource.createAquarium(name: ''),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getAquariums', () {
      test('should call GET /aquariums', () async {
        when(
          () => mockDio.get<List<dynamic>>(any()),
        ).thenAnswer(
          (_) async => Response(
            data: aquariumListJson,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        await dataSource.getAquariums();

        verify(
          () => mockDio.get<List<dynamic>>(ApiEndpoints.aquariums),
        ).called(1);
      });

      test('should return list of AquariumDto on success', () async {
        when(
          () => mockDio.get<List<dynamic>>(any()),
        ).thenAnswer(
          (_) async => Response(
            data: aquariumListJson,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await dataSource.getAquariums();

        expect(result.length, 2);
        expect(result[0].id, 'aquarium-123');
        expect(result[0].name, 'Living Room Tank');
        expect(result[1].id, 'aquarium-456');
        expect(result[1].name, 'Bedroom Tank');
      });

      test('should return empty list when no aquariums', () async {
        when(
          () => mockDio.get<List<dynamic>>(any()),
        ).thenAnswer(
          (_) async => Response(
            data: <Map<String, dynamic>>[],
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await dataSource.getAquariums();

        expect(result, isEmpty);
      });

      test('should return empty list when response data is null', () async {
        when(
          () => mockDio.get<List<dynamic>>(any()),
        ).thenAnswer(
          (_) async => Response(
            data: null,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await dataSource.getAquariums();

        expect(result, isEmpty);
      });

      test('should throw DioException on network error', () async {
        when(
          () => mockDio.get<List<dynamic>>(any()),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionError,
          ),
        );

        expect(
          () => dataSource.getAquariums(),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getAquariumById', () {
      test('should call GET /aquariums/{id}', () async {
        when(
          () => mockDio.get<Map<String, dynamic>>(any()),
        ).thenAnswer(
          (_) async => Response(
            data: aquariumJson,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        await dataSource.getAquariumById('aquarium-123');

        verify(
          () => mockDio.get<Map<String, dynamic>>(
            '${ApiEndpoints.aquariums}/aquarium-123',
          ),
        ).called(1);
      });

      test('should return AquariumDto on success', () async {
        when(
          () => mockDio.get<Map<String, dynamic>>(any()),
        ).thenAnswer(
          (_) async => Response(
            data: aquariumJson,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await dataSource.getAquariumById('aquarium-123');

        expect(result.id, 'aquarium-123');
        expect(result.name, 'Living Room Tank');
      });

      test('should throw DioException when not found', () async {
        when(
          () => mockDio.get<Map<String, dynamic>>(any()),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              statusCode: 404,
              data: {'message': 'Aquarium not found'},
              requestOptions: RequestOptions(),
            ),
          ),
        );

        expect(
          () => dataSource.getAquariumById('non-existent'),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('updateAquarium', () {
      test('should call PUT /aquariums/{id} with name', () async {
        final updatedJson = Map<String, dynamic>.from(aquariumJson);
        updatedJson['name'] = 'Updated Name';

        when(
          () => mockDio.put<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: updatedJson,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        await dataSource.updateAquarium(
          aquariumId: 'aquarium-123',
          name: 'Updated Name',
        );

        verify(
          () => mockDio.put<Map<String, dynamic>>(
            '${ApiEndpoints.aquariums}/aquarium-123',
            data: {'name': 'Updated Name'},
          ),
        ).called(1);
      });

      test('should call PUT with multiple parameters', () async {
        final updatedJson = Map<String, dynamic>.from(aquariumJson);
        updatedJson['name'] = 'Updated Name';
        updatedJson['capacity'] = 75.0;
        updatedJson['water_type'] = 'saltwater';

        when(
          () => mockDio.put<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: updatedJson,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        await dataSource.updateAquarium(
          aquariumId: 'aquarium-123',
          name: 'Updated Name',
          waterType: WaterType.saltwater,
          capacity: 75.0,
        );

        verify(
          () => mockDio.put<Map<String, dynamic>>(
            '${ApiEndpoints.aquariums}/aquarium-123',
            data: {
              'name': 'Updated Name',
              'water_type': 'saltwater',
              'capacity': 75.0,
            },
          ),
        ).called(1);
      });

      test('should return updated AquariumDto on success', () async {
        final updatedJson = Map<String, dynamic>.from(aquariumJson);
        updatedJson['name'] = 'Updated Name';

        when(
          () => mockDio.put<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: updatedJson,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await dataSource.updateAquarium(
          aquariumId: 'aquarium-123',
          name: 'Updated Name',
        );

        expect(result.name, 'Updated Name');
      });

      test('should throw DioException on error', () async {
        when(
          () => mockDio.put<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              statusCode: 404,
              data: {'message': 'Aquarium not found'},
              requestOptions: RequestOptions(),
            ),
          ),
        );

        expect(
          () => dataSource.updateAquarium(
            aquariumId: 'non-existent',
            name: 'Updated Name',
          ),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('deleteAquarium', () {
      test('should call DELETE /aquariums/{id}', () async {
        when(
          () => mockDio.delete<void>(any()),
        ).thenAnswer(
          (_) async => Response(
            statusCode: 204,
            requestOptions: RequestOptions(),
          ),
        );

        await dataSource.deleteAquarium('aquarium-123');

        verify(
          () => mockDio.delete<void>(
            '${ApiEndpoints.aquariums}/aquarium-123',
          ),
        ).called(1);
      });

      test('should complete without error on success', () async {
        when(
          () => mockDio.delete<void>(any()),
        ).thenAnswer(
          (_) async => Response(
            statusCode: 204,
            requestOptions: RequestOptions(),
          ),
        );

        await expectLater(
          dataSource.deleteAquarium('aquarium-123'),
          completes,
        );
      });

      test('should throw DioException on error', () async {
        when(
          () => mockDio.delete<void>(any()),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              statusCode: 404,
              data: {'message': 'Aquarium not found'},
              requestOptions: RequestOptions(),
            ),
          ),
        );

        expect(
          () => dataSource.deleteAquarium('non-existent'),
          throwsA(isA<DioException>()),
        );
      });
    });
  });

  group('aquariumRemoteDataSourceProvider', () {
    test('should provide AquariumRemoteDataSource instance', () {
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

      final aquariumRemoteDs =
          container.read(aquariumRemoteDataSourceProvider);

      expect(aquariumRemoteDs, isA<AquariumRemoteDataSource>());
      expect(aquariumRemoteDs, isA<AquariumRemoteDataSourceImpl>());
    });
  });
}
