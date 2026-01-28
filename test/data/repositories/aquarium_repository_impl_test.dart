import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/api_exceptions.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/remote/aquarium_remote_ds.dart';
import 'package:fishfeed/data/models/aquarium_dto.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/user_model.dart';
import 'package:fishfeed/data/repositories/aquarium_repository_impl.dart';
import 'package:fishfeed/domain/entities/water_type.dart';

class MockAquariumRemoteDataSource extends Mock
    implements AquariumRemoteDataSource {}

class MockAquariumLocalDataSource extends Mock
    implements AquariumLocalDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class FakeAquariumModel extends Fake implements AquariumModel {}

void main() {
  late MockAquariumRemoteDataSource mockRemoteDataSource;
  late MockAquariumLocalDataSource mockLocalDataSource;
  late MockAuthLocalDataSource mockAuthLocalDataSource;
  late AquariumRepositoryImpl repository;

  final testUserModel = UserModel(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: DateTime(2024, 1, 15),
  );

  final testAquariumDto = AquariumDto(
    id: 'aquarium-123',
    userId: 'user-123',
    name: 'Living Room Tank',
    capacity: 50.0,
    waterType: 'freshwater',
    imageUrl: null,
    createdAt: DateTime(2024, 1, 15),
  );

  final testAquariumModel = AquariumModel(
    id: 'aquarium-123',
    userId: 'user-123',
    name: 'Living Room Tank',
    capacity: 50.0,
    waterType: WaterType.freshwater,
    imageUrl: null,
    createdAt: DateTime(2024, 1, 15),
  );

  setUpAll(() {
    registerFallbackValue(FakeAquariumModel());
    registerFallbackValue(WaterType.freshwater);
  });

  setUp(() {
    mockRemoteDataSource = MockAquariumRemoteDataSource();
    mockLocalDataSource = MockAquariumLocalDataSource();
    mockAuthLocalDataSource = MockAuthLocalDataSource();

    repository = AquariumRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      authLocalDataSource: mockAuthLocalDataSource,
    );
  });

  group('createAquarium', () {
    test('should return Aquarium on successful creation', () async {
      when(
        () => mockAuthLocalDataSource.getCurrentUser(),
      ).thenReturn(testUserModel);

      when(
        () => mockRemoteDataSource.createAquarium(
          name: any(named: 'name'),
          waterType: any(named: 'waterType'),
          capacity: any(named: 'capacity'),
        ),
      ).thenAnswer((_) async => testAquariumDto);

      when(
        () => mockLocalDataSource.saveAquarium(any()),
      ).thenAnswer((_) async {});

      final result = await repository.createAquarium(
        name: 'Living Room Tank',
        waterType: WaterType.freshwater,
        capacity: 50.0,
      );

      expect(result.isRight(), true);
      result.fold((_) => fail('Should be Right'), (aquarium) {
        expect(aquarium.id, 'aquarium-123');
        expect(aquarium.name, 'Living Room Tank');
      });

      verify(() => mockLocalDataSource.saveAquarium(any())).called(1);
    });

    test('should return AuthenticationFailure when not logged in', () async {
      when(() => mockAuthLocalDataSource.getCurrentUser()).thenReturn(null);

      final result = await repository.createAquarium(name: 'Test Tank');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<AuthenticationFailure>()),
        (_) => fail('Should be Left'),
      );
    });

    test('should create locally on network error', () async {
      when(
        () => mockAuthLocalDataSource.getCurrentUser(),
      ).thenReturn(testUserModel);

      when(
        () => mockRemoteDataSource.createAquarium(
          name: any(named: 'name'),
          waterType: any(named: 'waterType'),
          capacity: any(named: 'capacity'),
        ),
      ).thenThrow(const NetworkException());

      when(
        () => mockLocalDataSource.saveAquarium(any()),
      ).thenAnswer((_) async {});

      final result = await repository.createAquarium(name: 'Living Room Tank');

      expect(result.isRight(), true);
      verify(() => mockLocalDataSource.saveAquarium(any())).called(1);
    });

    test('should return ServerFailure on server error', () async {
      when(
        () => mockAuthLocalDataSource.getCurrentUser(),
      ).thenReturn(testUserModel);

      when(
        () => mockRemoteDataSource.createAquarium(
          name: any(named: 'name'),
          waterType: any(named: 'waterType'),
          capacity: any(named: 'capacity'),
        ),
      ).thenThrow(const ServerException());

      final result = await repository.createAquarium(name: 'Test Tank');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should be Left'),
      );
    });
  });

  group('getAquariums', () {
    test('should return aquariums from server and update cache', () async {
      when(
        () => mockAuthLocalDataSource.getCurrentUser(),
      ).thenReturn(testUserModel);

      when(
        () => mockRemoteDataSource.getAquariums(),
      ).thenAnswer((_) async => [testAquariumDto]);

      when(
        () => mockLocalDataSource.replaceAllForUser(any(), any()),
      ).thenAnswer((_) async {});

      final result = await repository.getAquariums();

      expect(result.isRight(), true);
      result.fold((_) => fail('Should be Right'), (aquariums) {
        expect(aquariums.length, 1);
        expect(aquariums[0].name, 'Living Room Tank');
      });

      verify(
        () => mockLocalDataSource.replaceAllForUser('user-123', any()),
      ).called(1);
    });

    test('should return cached data on network error', () async {
      when(
        () => mockAuthLocalDataSource.getCurrentUser(),
      ).thenReturn(testUserModel);

      when(
        () => mockRemoteDataSource.getAquariums(),
      ).thenThrow(const NetworkException());

      when(
        () => mockLocalDataSource.getAquariumsByUserId(any()),
      ).thenReturn([testAquariumModel]);

      final result = await repository.getAquariums();

      expect(result.isRight(), true);
      result.fold((_) => fail('Should be Right'), (aquariums) {
        expect(aquariums.length, 1);
      });
    });

    test(
      'should return CacheFailure when no cached data on network error',
      () async {
        when(
          () => mockAuthLocalDataSource.getCurrentUser(),
        ).thenReturn(testUserModel);

        when(
          () => mockRemoteDataSource.getAquariums(),
        ).thenThrow(const NetworkException());

        when(
          () => mockLocalDataSource.getAquariumsByUserId(any()),
        ).thenReturn([]);

        final result = await repository.getAquariums();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should be Left'),
        );
      },
    );
  });

  group('getAquariumById', () {
    test('should return aquarium from cache when exists', () async {
      when(
        () => mockLocalDataSource.getAquariumById('aquarium-123'),
      ).thenReturn(testAquariumModel);

      final result = await repository.getAquariumById('aquarium-123');

      expect(result.isRight(), true);
      result.fold((_) => fail('Should be Right'), (aquarium) {
        expect(aquarium.id, 'aquarium-123');
        expect(aquarium.name, 'Living Room Tank');
      });

      verifyNever(() => mockRemoteDataSource.getAquariumById(any()));
    });

    test('should fetch from server when not in cache', () async {
      when(
        () => mockLocalDataSource.getAquariumById('aquarium-123'),
      ).thenReturn(null);

      when(
        () => mockRemoteDataSource.getAquariumById('aquarium-123'),
      ).thenAnswer((_) async => testAquariumDto);

      when(
        () => mockLocalDataSource.saveAquarium(any()),
      ).thenAnswer((_) async {});

      final result = await repository.getAquariumById('aquarium-123');

      expect(result.isRight(), true);
      verify(
        () => mockRemoteDataSource.getAquariumById('aquarium-123'),
      ).called(1);
      verify(() => mockLocalDataSource.saveAquarium(any())).called(1);
    });

    test('should return failure when not found', () async {
      when(
        () => mockLocalDataSource.getAquariumById('non-existent'),
      ).thenReturn(null);

      when(
        () => mockRemoteDataSource.getAquariumById('non-existent'),
      ).thenThrow(const NotFoundException());

      final result = await repository.getAquariumById('non-existent');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Should be Left'),
      );
    });
  });

  group('updateAquarium', () {
    test('should return updated aquarium on success', () async {
      final updatedDto = AquariumDto(
        id: 'aquarium-123',
        userId: 'user-123',
        name: 'Updated Name',
        capacity: 75.0,
        waterType: 'saltwater',
        createdAt: DateTime(2024, 1, 15),
      );

      when(
        () => mockRemoteDataSource.updateAquarium(
          aquariumId: any(named: 'aquariumId'),
          name: any(named: 'name'),
          waterType: any(named: 'waterType'),
          capacity: any(named: 'capacity'),
          imageUrl: any(named: 'imageUrl'),
        ),
      ).thenAnswer((_) async => updatedDto);

      when(
        () => mockLocalDataSource.updateAquarium(any()),
      ).thenAnswer((_) async => true);

      final result = await repository.updateAquarium(
        aquariumId: 'aquarium-123',
        name: 'Updated Name',
        waterType: WaterType.saltwater,
        capacity: 75.0,
      );

      expect(result.isRight(), true);
      result.fold((_) => fail('Should be Right'), (aquarium) {
        expect(aquarium.name, 'Updated Name');
        expect(aquarium.waterType, WaterType.saltwater);
      });
    });

    test('should update locally on network error when cached', () async {
      when(
        () => mockRemoteDataSource.updateAquarium(
          aquariumId: any(named: 'aquariumId'),
          name: any(named: 'name'),
          waterType: any(named: 'waterType'),
          capacity: any(named: 'capacity'),
          imageUrl: any(named: 'imageUrl'),
        ),
      ).thenThrow(const NetworkException());

      when(
        () => mockLocalDataSource.getAquariumById('aquarium-123'),
      ).thenReturn(testAquariumModel);

      when(
        () => mockLocalDataSource.updateAquarium(any()),
      ).thenAnswer((_) async => true);

      final result = await repository.updateAquarium(
        aquariumId: 'aquarium-123',
        name: 'Updated Name',
      );

      expect(result.isRight(), true);
      verify(() => mockLocalDataSource.updateAquarium(any())).called(1);
    });

    test(
      'should return CacheFailure on network error when not cached',
      () async {
        when(
          () => mockRemoteDataSource.updateAquarium(
            aquariumId: any(named: 'aquariumId'),
            name: any(named: 'name'),
            waterType: any(named: 'waterType'),
            capacity: any(named: 'capacity'),
            imageUrl: any(named: 'imageUrl'),
          ),
        ).thenThrow(const NetworkException());

        when(
          () => mockLocalDataSource.getAquariumById('aquarium-123'),
        ).thenReturn(null);

        final result = await repository.updateAquarium(
          aquariumId: 'aquarium-123',
          name: 'Updated Name',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Should be Left'),
        );
      },
    );
  });

  group('deleteAquarium', () {
    test('should return unit on successful delete', () async {
      when(
        () => mockRemoteDataSource.deleteAquarium('aquarium-123'),
      ).thenAnswer((_) async {});

      when(
        () => mockLocalDataSource.deleteAquarium('aquarium-123'),
      ).thenAnswer((_) async => true);

      final result = await repository.deleteAquarium('aquarium-123');

      expect(result.isRight(), true);
      verify(
        () => mockRemoteDataSource.deleteAquarium('aquarium-123'),
      ).called(1);
      verify(
        () => mockLocalDataSource.deleteAquarium('aquarium-123'),
      ).called(1);
    });

    test('should delete locally on network error', () async {
      when(
        () => mockRemoteDataSource.deleteAquarium('aquarium-123'),
      ).thenThrow(const NetworkException());

      when(
        () => mockLocalDataSource.deleteAquarium('aquarium-123'),
      ).thenAnswer((_) async => true);

      final result = await repository.deleteAquarium('aquarium-123');

      expect(result.isRight(), true);
      verify(
        () => mockLocalDataSource.deleteAquarium('aquarium-123'),
      ).called(1);
    });
  });

  group('syncAquariums', () {
    test('should fetch and replace local cache', () async {
      when(
        () => mockAuthLocalDataSource.getCurrentUser(),
      ).thenReturn(testUserModel);

      when(
        () => mockRemoteDataSource.getAquariums(),
      ).thenAnswer((_) async => [testAquariumDto]);

      when(
        () => mockLocalDataSource.replaceAllForUser(any(), any()),
      ).thenAnswer((_) async {});

      final result = await repository.syncAquariums();

      expect(result.isRight(), true);
      verify(
        () => mockLocalDataSource.replaceAllForUser('user-123', any()),
      ).called(1);
    });

    test('should return NetworkFailure on network error', () async {
      when(
        () => mockRemoteDataSource.getAquariums(),
      ).thenThrow(const NetworkException());

      final result = await repository.syncAquariums();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should be Left'),
      );
    });
  });

  group('getCachedAquariums', () {
    test('should return cached aquariums when available', () {
      when(
        () => mockAuthLocalDataSource.getCurrentUser(),
      ).thenReturn(testUserModel);

      when(
        () => mockLocalDataSource.getAquariumsByUserId('user-123'),
      ).thenReturn([testAquariumModel]);

      final result = repository.getCachedAquariums();

      expect(result.isRight(), true);
      result.fold((_) => fail('Should be Right'), (aquariums) {
        expect(aquariums.length, 1);
        expect(aquariums[0].name, 'Living Room Tank');
      });
    });

    test('should return CacheFailure when not logged in', () {
      when(() => mockAuthLocalDataSource.getCurrentUser()).thenReturn(null);

      final result = repository.getCachedAquariums();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Should be Left'),
      );
    });

    test('should return CacheFailure when cache is empty', () {
      when(
        () => mockAuthLocalDataSource.getCurrentUser(),
      ).thenReturn(testUserModel);

      when(
        () => mockLocalDataSource.getAquariumsByUserId('user-123'),
      ).thenReturn([]);

      final result = repository.getCachedAquariums();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Should be Left'),
      );
    });
  });
}
