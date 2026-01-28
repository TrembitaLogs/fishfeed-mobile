import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/models/fish_model.dart';

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  late MockBox mockFishBox;
  late FishLocalDataSource fishDs;

  setUp(() {
    mockFishBox = MockBox();
    fishDs = FishLocalDataSource(fishBox: mockFishBox);
  });

  FishModel createTestFish({
    String id = 'fish_1',
    String aquariumId = 'aquarium_1',
    String speciesId = 'species_1',
    String? name,
    int quantity = 1,
    String? notes,
    DateTime? addedAt,
  }) {
    return FishModel(
      id: id,
      aquariumId: aquariumId,
      speciesId: speciesId,
      name: name,
      quantity: quantity,
      notes: notes,
      addedAt: addedAt ?? DateTime(2025, 6, 15, 10, 0),
    );
  }

  group('CRUD Operations', () {
    group('getAllFish', () {
      test('should return all fish sorted by addedAt (newest first)', () {
        final oldFish = createTestFish(
          id: 'fish_1',
          addedAt: DateTime(2025, 6, 15, 8, 0),
        );
        final newFish = createTestFish(
          id: 'fish_2',
          addedAt: DateTime(2025, 6, 15, 12, 0),
        );

        when(() => mockFishBox.values).thenReturn([oldFish, newFish]);

        final result = fishDs.getAllFish();

        expect(result.length, 2);
        expect(result[0].id, 'fish_2');
        expect(result[1].id, 'fish_1');
      });

      test('should return empty list when no fish exist', () {
        when(() => mockFishBox.values).thenReturn([]);

        final result = fishDs.getAllFish();

        expect(result, isEmpty);
      });

      test('should filter out non-FishModel values', () {
        final fish = createTestFish();

        when(() => mockFishBox.values).thenReturn([fish, 'invalid', 123, null]);

        final result = fishDs.getAllFish();

        expect(result.length, 1);
        expect(result[0].id, 'fish_1');
      });
    });

    group('getFishById', () {
      test('should return fish when exists', () {
        final fish = createTestFish();
        when(() => mockFishBox.get('fish_1')).thenReturn(fish);

        final result = fishDs.getFishById('fish_1');

        expect(result, fish);
        expect(result?.id, 'fish_1');
      });

      test('should return null when fish does not exist', () {
        when(() => mockFishBox.get('fish_1')).thenReturn(null);

        final result = fishDs.getFishById('fish_1');

        expect(result, isNull);
      });

      test('should return null when stored value is not FishModel', () {
        when(() => mockFishBox.get('fish_1')).thenReturn('invalid');

        final result = fishDs.getFishById('fish_1');

        expect(result, isNull);
      });
    });

    group('getFishByAquariumId', () {
      test('should return fish for specific aquarium', () {
        final fish1 = createTestFish(
          id: 'fish_1',
          aquariumId: 'aquarium_1',
          addedAt: DateTime(2025, 6, 15, 10, 0),
        );
        final fish2 = createTestFish(
          id: 'fish_2',
          aquariumId: 'aquarium_1',
          addedAt: DateTime(2025, 6, 15, 12, 0),
        );
        final fish3 = createTestFish(
          id: 'fish_3',
          aquariumId: 'aquarium_2',
        );

        when(() => mockFishBox.values).thenReturn([fish1, fish2, fish3]);

        final result = fishDs.getFishByAquariumId('aquarium_1');

        expect(result.length, 2);
        expect(result.every((f) => f.aquariumId == 'aquarium_1'), isTrue);
      });

      test('should return fish sorted by addedAt (newest first)', () {
        final oldFish = createTestFish(
          id: 'fish_1',
          addedAt: DateTime(2025, 6, 15, 8, 0),
        );
        final newFish = createTestFish(
          id: 'fish_2',
          addedAt: DateTime(2025, 6, 15, 12, 0),
        );

        when(() => mockFishBox.values).thenReturn([oldFish, newFish]);

        final result = fishDs.getFishByAquariumId('aquarium_1');

        expect(result[0].id, 'fish_2');
        expect(result[1].id, 'fish_1');
      });

      test('should return empty list when no fish for aquarium', () {
        when(() => mockFishBox.values).thenReturn([]);

        final result = fishDs.getFishByAquariumId('aquarium_1');

        expect(result, isEmpty);
      });
    });

    group('saveFish', () {
      test('should save fish to Hive box', () async {
        final fish = createTestFish();
        when(() => mockFishBox.put(any<dynamic>(), any<dynamic>()))
            .thenAnswer((_) async {});

        await fishDs.saveFish(fish);

        verify(() => mockFishBox.put('fish_1', fish)).called(1);
      });
    });

    group('updateFish', () {
      test('should update fish when exists', () async {
        final fish = createTestFish();
        final updatedFish = FishModel(
          id: 'fish_1',
          aquariumId: 'aquarium_1',
          speciesId: 'species_1',
          name: 'Updated Name',
          quantity: 5,
          notes: 'Updated notes',
          addedAt: DateTime(2025, 6, 15, 10, 0),
        );

        when(() => mockFishBox.get('fish_1')).thenReturn(fish);
        when(() => mockFishBox.put(any<dynamic>(), any<dynamic>()))
            .thenAnswer((_) async {});

        final result = await fishDs.updateFish(updatedFish);

        expect(result, isTrue);
        verify(() => mockFishBox.put('fish_1', updatedFish)).called(1);
      });

      test('should return false when fish does not exist', () async {
        final fish = createTestFish();
        when(() => mockFishBox.get('fish_1')).thenReturn(null);

        final result = await fishDs.updateFish(fish);

        expect(result, isFalse);
        verifyNever(() => mockFishBox.put(any<dynamic>(), any<dynamic>()));
      });
    });

    group('deleteFish', () {
      test('should delete fish when exists', () async {
        final fish = createTestFish();
        when(() => mockFishBox.get('fish_1')).thenReturn(fish);
        when(() => mockFishBox.delete(any<dynamic>())).thenAnswer((_) async {});

        final result = await fishDs.deleteFish('fish_1');

        expect(result, isTrue);
        verify(() => mockFishBox.delete('fish_1')).called(1);
      });

      test('should return false when fish does not exist', () async {
        when(() => mockFishBox.get('fish_1')).thenReturn(null);

        final result = await fishDs.deleteFish('fish_1');

        expect(result, isFalse);
        verifyNever(() => mockFishBox.delete(any<dynamic>()));
      });
    });
  });

  group('Query Methods', () {
    group('getFishBySpeciesId', () {
      test('should return fish for specific species', () {
        final fish1 = createTestFish(
          id: 'fish_1',
          speciesId: 'species_1',
          addedAt: DateTime(2025, 6, 15, 10, 0),
        );
        final fish2 = createTestFish(
          id: 'fish_2',
          speciesId: 'species_1',
          addedAt: DateTime(2025, 6, 15, 12, 0),
        );
        final fish3 = createTestFish(
          id: 'fish_3',
          speciesId: 'species_2',
        );

        when(() => mockFishBox.values).thenReturn([fish1, fish2, fish3]);

        final result = fishDs.getFishBySpeciesId('species_1');

        expect(result.length, 2);
        expect(result.every((f) => f.speciesId == 'species_1'), isTrue);
      });

      test('should return fish sorted by addedAt (newest first)', () {
        final oldFish = createTestFish(
          id: 'fish_1',
          speciesId: 'species_1',
          addedAt: DateTime(2025, 6, 15, 8, 0),
        );
        final newFish = createTestFish(
          id: 'fish_2',
          speciesId: 'species_1',
          addedAt: DateTime(2025, 6, 15, 12, 0),
        );

        when(() => mockFishBox.values).thenReturn([oldFish, newFish]);

        final result = fishDs.getFishBySpeciesId('species_1');

        expect(result[0].id, 'fish_2');
        expect(result[1].id, 'fish_1');
      });

      test('should return empty list when no fish for species', () {
        when(() => mockFishBox.values).thenReturn([]);

        final result = fishDs.getFishBySpeciesId('species_1');

        expect(result, isEmpty);
      });
    });

    group('getFishCount', () {
      test('should return total count of fish', () {
        final fish1 = createTestFish(id: 'fish_1');
        final fish2 = createTestFish(id: 'fish_2');
        final fish3 = createTestFish(id: 'fish_3');

        when(() => mockFishBox.values).thenReturn([fish1, fish2, fish3]);

        final result = fishDs.getFishCount();

        expect(result, 3);
      });

      test('should return 0 when no fish exist', () {
        when(() => mockFishBox.values).thenReturn([]);

        final result = fishDs.getFishCount();

        expect(result, 0);
      });

      test('should not count non-FishModel values', () {
        final fish = createTestFish();

        when(() => mockFishBox.values).thenReturn([fish, 'invalid', 123]);

        final result = fishDs.getFishCount();

        expect(result, 1);
      });
    });

    group('getFishCountByAquariumId', () {
      test('should return count of fish for specific aquarium', () {
        final fish1 = createTestFish(id: 'fish_1', aquariumId: 'aquarium_1');
        final fish2 = createTestFish(id: 'fish_2', aquariumId: 'aquarium_1');
        final fish3 = createTestFish(id: 'fish_3', aquariumId: 'aquarium_2');

        when(() => mockFishBox.values).thenReturn([fish1, fish2, fish3]);

        final result = fishDs.getFishCountByAquariumId('aquarium_1');

        expect(result, 2);
      });

      test('should return 0 when no fish for aquarium', () {
        final fish = createTestFish(aquariumId: 'aquarium_2');

        when(() => mockFishBox.values).thenReturn([fish]);

        final result = fishDs.getFishCountByAquariumId('aquarium_1');

        expect(result, 0);
      });
    });
  });

  group('Utility Methods', () {
    group('clearAll', () {
      test('should clear all fish from box', () async {
        when(() => mockFishBox.clear()).thenAnswer((_) async => 0);

        await fishDs.clearAll();

        verify(() => mockFishBox.clear()).called(1);
      });
    });

    group('deleteFishByAquariumId', () {
      test('should delete all fish for specific aquarium', () async {
        final fish1 = createTestFish(id: 'fish_1', aquariumId: 'aquarium_1');
        final fish2 = createTestFish(id: 'fish_2', aquariumId: 'aquarium_1');

        when(() => mockFishBox.values).thenReturn([fish1, fish2]);
        when(() => mockFishBox.delete(any<dynamic>())).thenAnswer((_) async {});

        final result = await fishDs.deleteFishByAquariumId('aquarium_1');

        expect(result, 2);
        verify(() => mockFishBox.delete('fish_1')).called(1);
        verify(() => mockFishBox.delete('fish_2')).called(1);
      });

      test('should return 0 when no fish for aquarium', () async {
        when(() => mockFishBox.values).thenReturn([]);

        final result = await fishDs.deleteFishByAquariumId('aquarium_1');

        expect(result, 0);
        verifyNever(() => mockFishBox.delete(any<dynamic>()));
      });
    });

    group('saveMultipleFish', () {
      test('should save multiple fish to box', () async {
        final fish1 = createTestFish(id: 'fish_1');
        final fish2 = createTestFish(id: 'fish_2');
        final fish3 = createTestFish(id: 'fish_3');

        when(() => mockFishBox.put(any<dynamic>(), any<dynamic>()))
            .thenAnswer((_) async {});

        await fishDs.saveMultipleFish([fish1, fish2, fish3]);

        verify(() => mockFishBox.put('fish_1', fish1)).called(1);
        verify(() => mockFishBox.put('fish_2', fish2)).called(1);
        verify(() => mockFishBox.put('fish_3', fish3)).called(1);
      });

      test('should handle empty list', () async {
        await fishDs.saveMultipleFish([]);

        verifyNever(() => mockFishBox.put(any<dynamic>(), any<dynamic>()));
      });
    });
  });

  group('FishLocalDataSource constructor', () {
    test('should create instance with injected box', () {
      final ds = FishLocalDataSource(fishBox: mockFishBox);
      expect(ds, isA<FishLocalDataSource>());
    });
  });
}
