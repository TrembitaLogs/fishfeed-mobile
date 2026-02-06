import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/data/models/user_model.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/services/migration/migration_service.dart';

class MockBox extends Mock implements Box<dynamic> {}

class MockAquariumLocalDataSource extends Mock
    implements AquariumLocalDataSource {}

class MockFishLocalDataSource extends Mock implements FishLocalDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late MockAquariumLocalDataSource mockAquariumDs;
  late MockFishLocalDataSource mockFishDs;
  late MockAuthLocalDataSource mockAuthDs;
  late MigrationService migrationService;

  setUp(() {
    mockAquariumDs = MockAquariumLocalDataSource();
    mockFishDs = MockFishLocalDataSource();
    mockAuthDs = MockAuthLocalDataSource();

    migrationService = MigrationService(
      aquariumLocalDs: mockAquariumDs,
      fishLocalDs: mockFishDs,
      authLocalDs: mockAuthDs,
    );
  });

  setUpAll(() {
    registerFallbackValue(
      AquariumModel(
        id: 'test',
        userId: 'test',
        name: 'Test',
        waterType: WaterType.freshwater,
        createdAt: DateTime.now(),
      ),
    );
    registerFallbackValue(
      FishModel(
        id: 'test',
        aquariumId: 'test',
        speciesId: 'test',
        addedAt: DateTime.now(),
      ),
    );
  });

  FishModel createTestFish({
    String id = 'fish_1',
    String aquariumId = 'default',
    String speciesId = 'goldfish',
    DateTime? addedAt,
  }) {
    return FishModel(
      id: id,
      aquariumId: aquariumId,
      speciesId: speciesId,
      addedAt: addedAt ?? DateTime.now(),
    );
  }

  UserModel createTestUser({
    String id = 'user_123',
    String email = 'test@example.com',
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id,
      email: email,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  group('needsMigration', () {
    test('should return true when fish with default aquariumId exists', () {
      final fish1 = createTestFish(id: 'fish_1', aquariumId: 'default');
      final fish2 = createTestFish(id: 'fish_2', aquariumId: 'uuid-123');

      when(() => mockFishDs.getAllFish()).thenReturn([fish1, fish2]);

      final result = migrationService.needsMigration();

      expect(result, isTrue);
    });

    test('should return false when no fish with default aquariumId', () {
      final fish1 = createTestFish(id: 'fish_1', aquariumId: 'uuid-123');
      final fish2 = createTestFish(id: 'fish_2', aquariumId: 'uuid-456');

      when(() => mockFishDs.getAllFish()).thenReturn([fish1, fish2]);

      final result = migrationService.needsMigration();

      expect(result, isFalse);
    });

    test('should return false when no fish exist', () {
      when(() => mockFishDs.getAllFish()).thenReturn([]);

      final result = migrationService.needsMigration();

      expect(result, isFalse);
    });
  });

  group('migrateDefaultAquarium', () {
    test(
      'should return NoMigrationNeeded when no default fish exist',
      () async {
        when(() => mockFishDs.getAllFish()).thenReturn([]);

        final result = await migrationService.migrateDefaultAquarium();

        expect(result, isA<NoMigrationNeeded>());
      },
    );

    test(
      'should create aquarium and migrate fish when default fish exist',
      () async {
        final fish1 = createTestFish(id: 'fish_1', aquariumId: 'default');
        final fish2 = createTestFish(id: 'fish_2', aquariumId: 'default');
        final user = createTestUser(id: 'user_123');

        when(() => mockFishDs.getAllFish()).thenReturn([fish1, fish2]);
        when(() => mockAuthDs.getCurrentUser()).thenReturn(user);
        when(() => mockAquariumDs.saveAquarium(any())).thenAnswer((_) async {});
        when(() => mockFishDs.updateFish(any())).thenAnswer((_) async => true);

        final result = await migrationService.migrateDefaultAquarium();

        expect(result, isA<MigrationSuccess>());
        final success = result as MigrationSuccess;
        expect(success.migratedFishCount, 2);
        expect(success.migratedEventsCount, 0);
        expect(success.newAquariumName, 'My Aquarium');

        verify(() => mockAquariumDs.saveAquarium(any())).called(1);
        verify(() => mockFishDs.updateFish(any())).called(2);
      },
    );

    test('should use local userId when no user logged in', () async {
      final fish = createTestFish(aquariumId: 'default');

      when(() => mockFishDs.getAllFish()).thenReturn([fish]);
      when(() => mockAuthDs.getCurrentUser()).thenReturn(null);
      when(() => mockAquariumDs.saveAquarium(any())).thenAnswer((_) async {});
      when(() => mockFishDs.updateFish(any())).thenAnswer((_) async => true);

      final result = await migrationService.migrateDefaultAquarium();

      expect(result, isA<MigrationSuccess>());

      final captured = verify(
        () => mockAquariumDs.saveAquarium(captureAny()),
      ).captured;
      expect(captured.length, 1);
      final savedAquarium = captured.first as AquariumModel;
      expect(savedAquarium.userId, 'local');
    });

    test('should return MigrationError when exception occurs', () async {
      final fish = createTestFish(aquariumId: 'default');

      when(() => mockFishDs.getAllFish()).thenReturn([fish]);
      when(() => mockAuthDs.getCurrentUser()).thenReturn(null);
      when(
        () => mockAquariumDs.saveAquarium(any()),
      ).thenThrow(Exception('Hive error'));

      final result = await migrationService.migrateDefaultAquarium();

      expect(result, isA<MigrationError>());
      final error = result as MigrationError;
      expect(error.message, contains('Failed to migrate'));
    });

    test('should update fish aquariumId to new UUID', () async {
      final fish = createTestFish(id: 'fish_1', aquariumId: 'default');
      final user = createTestUser();

      when(() => mockFishDs.getAllFish()).thenReturn([fish]);
      when(() => mockAuthDs.getCurrentUser()).thenReturn(user);
      when(() => mockAquariumDs.saveAquarium(any())).thenAnswer((_) async {});
      when(() => mockFishDs.updateFish(any())).thenAnswer((_) async => true);

      final result = await migrationService.migrateDefaultAquarium();

      expect(result, isA<MigrationSuccess>());

      final capturedFish = verify(
        () => mockFishDs.updateFish(captureAny()),
      ).captured;
      expect(capturedFish.length, 1);
      final updatedFish = capturedFish.first as FishModel;
      expect(updatedFish.aquariumId, isNot('default'));
      expect(updatedFish.aquariumId.length, 36); // UUID length
    });

    test('should not migrate fish with non-default aquariumId', () async {
      final defaultFish = createTestFish(id: 'fish_1', aquariumId: 'default');
      final otherFish = createTestFish(id: 'fish_2', aquariumId: 'other_uuid');
      final user = createTestUser();

      when(() => mockFishDs.getAllFish()).thenReturn([defaultFish, otherFish]);
      when(() => mockAuthDs.getCurrentUser()).thenReturn(user);
      when(() => mockAquariumDs.saveAquarium(any())).thenAnswer((_) async {});
      when(() => mockFishDs.updateFish(any())).thenAnswer((_) async => true);

      final result = await migrationService.migrateDefaultAquarium();

      expect(result, isA<MigrationSuccess>());
      final success = result as MigrationSuccess;
      expect(success.migratedFishCount, 1);

      verify(() => mockFishDs.updateFish(any())).called(1);
    });
  });

  group('idempotency', () {
    test(
      'should return NoMigrationNeeded on second call after migration',
      () async {
        final fish = createTestFish(aquariumId: 'default');
        final user = createTestUser();

        // First call - migration happens
        when(() => mockFishDs.getAllFish()).thenReturn([fish]);
        when(() => mockAuthDs.getCurrentUser()).thenReturn(user);
        when(() => mockAquariumDs.saveAquarium(any())).thenAnswer((_) async {});
        when(() => mockFishDs.updateFish(any())).thenAnswer((_) async => true);

        final firstResult = await migrationService.migrateDefaultAquarium();
        expect(firstResult, isA<MigrationSuccess>());

        // Second call - fish no longer has default aquariumId
        when(() => mockFishDs.getAllFish()).thenReturn([]);

        final secondResult = await migrationService.migrateDefaultAquarium();
        expect(secondResult, isA<NoMigrationNeeded>());
      },
    );
  });

  group('MigrationResult types', () {
    test('NoMigrationNeeded should be a MigrationResult', () {
      const result = NoMigrationNeeded();
      expect(result, isA<MigrationResult>());
    });

    test('MigrationSuccess should contain migration details', () {
      const result = MigrationSuccess(
        migratedFishCount: 5,
        migratedEventsCount: 10,
        newAquariumId: 'uuid-123',
        newAquariumName: 'My Aquarium',
      );

      expect(result, isA<MigrationResult>());
      expect(result.migratedFishCount, 5);
      expect(result.migratedEventsCount, 10);
      expect(result.newAquariumId, 'uuid-123');
      expect(result.newAquariumName, 'My Aquarium');
    });

    test('MigrationError should contain error details', () {
      const result = MigrationError(
        message: 'Test error',
        error: 'Some exception',
      );

      expect(result, isA<MigrationResult>());
      expect(result.message, 'Test error');
      expect(result.error, 'Some exception');
    });
  });
}
