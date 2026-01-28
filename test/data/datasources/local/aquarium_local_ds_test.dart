import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/domain/entities/water_type.dart';

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  late MockBox mockAquariumBox;
  late AquariumLocalDataSource aquariumDs;

  setUp(() {
    mockAquariumBox = MockBox();
    aquariumDs = AquariumLocalDataSource(aquariumBox: mockAquariumBox);
  });

  AquariumModel createTestAquarium({
    String id = 'aquarium_1',
    String userId = 'user_1',
    String name = 'Test Aquarium',
    double? capacity = 50.0,
    WaterType waterType = WaterType.freshwater,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return AquariumModel(
      id: id,
      userId: userId,
      name: name,
      capacity: capacity,
      waterType: waterType,
      imageUrl: imageUrl,
      createdAt: createdAt ?? DateTime(2025, 6, 15, 10, 0),
    );
  }

  group('CRUD Operations', () {
    group('getAllAquariums', () {
      test(
        'should return all aquariums sorted by createdAt (newest first)',
        () {
          final oldAquarium = createTestAquarium(
            id: 'aquarium_1',
            createdAt: DateTime(2025, 6, 15, 8, 0),
          );
          final newAquarium = createTestAquarium(
            id: 'aquarium_2',
            createdAt: DateTime(2025, 6, 15, 12, 0),
          );

          when(
            () => mockAquariumBox.values,
          ).thenReturn([oldAquarium, newAquarium]);

          final result = aquariumDs.getAllAquariums();

          expect(result.length, 2);
          expect(result[0].id, 'aquarium_2');
          expect(result[1].id, 'aquarium_1');
        },
      );

      test('should return empty list when no aquariums exist', () {
        when(() => mockAquariumBox.values).thenReturn([]);

        final result = aquariumDs.getAllAquariums();

        expect(result, isEmpty);
      });

      test('should filter out non-AquariumModel values', () {
        final aquarium = createTestAquarium();

        when(
          () => mockAquariumBox.values,
        ).thenReturn([aquarium, 'invalid', 123, null]);

        final result = aquariumDs.getAllAquariums();

        expect(result.length, 1);
        expect(result[0].id, 'aquarium_1');
      });
    });

    group('getAquariumById', () {
      test('should return aquarium when exists', () {
        final aquarium = createTestAquarium();
        when(() => mockAquariumBox.get('aquarium_1')).thenReturn(aquarium);

        final result = aquariumDs.getAquariumById('aquarium_1');

        expect(result, aquarium);
        expect(result?.id, 'aquarium_1');
      });

      test('should return null when aquarium does not exist', () {
        when(() => mockAquariumBox.get('aquarium_1')).thenReturn(null);

        final result = aquariumDs.getAquariumById('aquarium_1');

        expect(result, isNull);
      });

      test('should return null when stored value is not AquariumModel', () {
        when(() => mockAquariumBox.get('aquarium_1')).thenReturn('invalid');

        final result = aquariumDs.getAquariumById('aquarium_1');

        expect(result, isNull);
      });
    });

    group('getAquariumsByUserId', () {
      test('should return aquariums for specific user', () {
        final aquarium1 = createTestAquarium(
          id: 'aquarium_1',
          userId: 'user_1',
          createdAt: DateTime(2025, 6, 15, 10, 0),
        );
        final aquarium2 = createTestAquarium(
          id: 'aquarium_2',
          userId: 'user_1',
          createdAt: DateTime(2025, 6, 15, 12, 0),
        );
        final aquarium3 = createTestAquarium(
          id: 'aquarium_3',
          userId: 'user_2',
        );

        when(
          () => mockAquariumBox.values,
        ).thenReturn([aquarium1, aquarium2, aquarium3]);

        final result = aquariumDs.getAquariumsByUserId('user_1');

        expect(result.length, 2);
        expect(result.every((a) => a.userId == 'user_1'), isTrue);
      });

      test('should return aquariums sorted by createdAt (newest first)', () {
        final oldAquarium = createTestAquarium(
          id: 'aquarium_1',
          createdAt: DateTime(2025, 6, 15, 8, 0),
        );
        final newAquarium = createTestAquarium(
          id: 'aquarium_2',
          createdAt: DateTime(2025, 6, 15, 12, 0),
        );

        when(
          () => mockAquariumBox.values,
        ).thenReturn([oldAquarium, newAquarium]);

        final result = aquariumDs.getAquariumsByUserId('user_1');

        expect(result[0].id, 'aquarium_2');
        expect(result[1].id, 'aquarium_1');
      });

      test('should return empty list when no aquariums for user', () {
        when(() => mockAquariumBox.values).thenReturn([]);

        final result = aquariumDs.getAquariumsByUserId('user_1');

        expect(result, isEmpty);
      });
    });

    group('saveAquarium', () {
      test('should save aquarium to Hive box', () async {
        final aquarium = createTestAquarium();
        when(
          () => mockAquariumBox.put(any<dynamic>(), any<dynamic>()),
        ).thenAnswer((_) async {});

        await aquariumDs.saveAquarium(aquarium);

        verify(() => mockAquariumBox.put('aquarium_1', aquarium)).called(1);
      });
    });

    group('updateAquarium', () {
      test('should update aquarium when exists', () async {
        final aquarium = createTestAquarium();
        final updatedAquarium = AquariumModel(
          id: 'aquarium_1',
          userId: 'user_1',
          name: 'Updated Name',
          capacity: 75.0,
          waterType: WaterType.saltwater,
          createdAt: DateTime(2025, 6, 15, 10, 0),
        );

        when(() => mockAquariumBox.get('aquarium_1')).thenReturn(aquarium);
        when(
          () => mockAquariumBox.put(any<dynamic>(), any<dynamic>()),
        ).thenAnswer((_) async {});

        final result = await aquariumDs.updateAquarium(updatedAquarium);

        expect(result, isTrue);
        verify(
          () => mockAquariumBox.put('aquarium_1', updatedAquarium),
        ).called(1);
      });

      test('should return false when aquarium does not exist', () async {
        final aquarium = createTestAquarium();
        when(() => mockAquariumBox.get('aquarium_1')).thenReturn(null);

        final result = await aquariumDs.updateAquarium(aquarium);

        expect(result, isFalse);
        verifyNever(() => mockAquariumBox.put(any<dynamic>(), any<dynamic>()));
      });
    });

    group('deleteAquarium', () {
      test('should delete aquarium when exists', () async {
        final aquarium = createTestAquarium();
        when(() => mockAquariumBox.get('aquarium_1')).thenReturn(aquarium);
        when(
          () => mockAquariumBox.delete(any<dynamic>()),
        ).thenAnswer((_) async {});

        final result = await aquariumDs.deleteAquarium('aquarium_1');

        expect(result, isTrue);
        verify(() => mockAquariumBox.delete('aquarium_1')).called(1);
      });

      test('should return false when aquarium does not exist', () async {
        when(() => mockAquariumBox.get('aquarium_1')).thenReturn(null);

        final result = await aquariumDs.deleteAquarium('aquarium_1');

        expect(result, isFalse);
        verifyNever(() => mockAquariumBox.delete(any<dynamic>()));
      });
    });
  });

  group('Query Methods', () {
    group('getAquariumCount', () {
      test('should return total count of aquariums', () {
        final aquarium1 = createTestAquarium(id: 'aquarium_1');
        final aquarium2 = createTestAquarium(id: 'aquarium_2');
        final aquarium3 = createTestAquarium(id: 'aquarium_3');

        when(
          () => mockAquariumBox.values,
        ).thenReturn([aquarium1, aquarium2, aquarium3]);

        final result = aquariumDs.getAquariumCount();

        expect(result, 3);
      });

      test('should return 0 when no aquariums exist', () {
        when(() => mockAquariumBox.values).thenReturn([]);

        final result = aquariumDs.getAquariumCount();

        expect(result, 0);
      });

      test('should not count non-AquariumModel values', () {
        final aquarium = createTestAquarium();

        when(
          () => mockAquariumBox.values,
        ).thenReturn([aquarium, 'invalid', 123]);

        final result = aquariumDs.getAquariumCount();

        expect(result, 1);
      });
    });

    group('getAquariumCountByUserId', () {
      test('should return count of aquariums for specific user', () {
        final aquarium1 = createTestAquarium(
          id: 'aquarium_1',
          userId: 'user_1',
        );
        final aquarium2 = createTestAquarium(
          id: 'aquarium_2',
          userId: 'user_1',
        );
        final aquarium3 = createTestAquarium(
          id: 'aquarium_3',
          userId: 'user_2',
        );

        when(
          () => mockAquariumBox.values,
        ).thenReturn([aquarium1, aquarium2, aquarium3]);

        final result = aquariumDs.getAquariumCountByUserId('user_1');

        expect(result, 2);
      });

      test('should return 0 when no aquariums for user', () {
        final aquarium = createTestAquarium(userId: 'user_2');

        when(() => mockAquariumBox.values).thenReturn([aquarium]);

        final result = aquariumDs.getAquariumCountByUserId('user_1');

        expect(result, 0);
      });
    });

    group('getFirstAquariumByUserId', () {
      test('should return first (oldest) aquarium for user', () {
        final oldAquarium = createTestAquarium(
          id: 'aquarium_1',
          createdAt: DateTime(2025, 6, 15, 8, 0),
        );
        final newAquarium = createTestAquarium(
          id: 'aquarium_2',
          createdAt: DateTime(2025, 6, 15, 12, 0),
        );

        when(
          () => mockAquariumBox.values,
        ).thenReturn([newAquarium, oldAquarium]);

        final result = aquariumDs.getFirstAquariumByUserId('user_1');

        expect(result?.id, 'aquarium_1');
      });

      test('should return null when no aquariums for user', () {
        when(() => mockAquariumBox.values).thenReturn([]);

        final result = aquariumDs.getFirstAquariumByUserId('user_1');

        expect(result, isNull);
      });
    });

    group('findLegacyAquariums', () {
      test('should find aquariums with default ID', () {
        final legacyAquarium = createTestAquarium(id: 'default');
        final normalAquarium = createTestAquarium(id: 'uuid-123');

        when(
          () => mockAquariumBox.values,
        ).thenReturn([legacyAquarium, normalAquarium]);

        final result = aquariumDs.findLegacyAquariums();

        expect(result.length, 1);
        expect(result[0].id, 'default');
      });

      test('should find aquariums with empty ID', () {
        final emptyIdAquarium = createTestAquarium(id: '');
        final normalAquarium = createTestAquarium(id: 'uuid-123');

        when(
          () => mockAquariumBox.values,
        ).thenReturn([emptyIdAquarium, normalAquarium]);

        final result = aquariumDs.findLegacyAquariums();

        expect(result.length, 1);
        expect(result[0].id, '');
      });

      test('should return empty list when no legacy aquariums', () {
        final normalAquarium = createTestAquarium(id: 'uuid-123');

        when(() => mockAquariumBox.values).thenReturn([normalAquarium]);

        final result = aquariumDs.findLegacyAquariums();

        expect(result, isEmpty);
      });
    });
  });

  group('Utility Methods', () {
    group('clearAll', () {
      test('should clear all aquariums from box', () async {
        when(() => mockAquariumBox.clear()).thenAnswer((_) async => 0);

        await aquariumDs.clearAll();

        verify(() => mockAquariumBox.clear()).called(1);
      });
    });

    group('saveMultipleAquariums', () {
      test('should save multiple aquariums to box', () async {
        final aquarium1 = createTestAquarium(id: 'aquarium_1');
        final aquarium2 = createTestAquarium(id: 'aquarium_2');
        final aquarium3 = createTestAquarium(id: 'aquarium_3');

        when(
          () => mockAquariumBox.put(any<dynamic>(), any<dynamic>()),
        ).thenAnswer((_) async {});

        await aquariumDs.saveMultipleAquariums([
          aquarium1,
          aquarium2,
          aquarium3,
        ]);

        verify(() => mockAquariumBox.put('aquarium_1', aquarium1)).called(1);
        verify(() => mockAquariumBox.put('aquarium_2', aquarium2)).called(1);
        verify(() => mockAquariumBox.put('aquarium_3', aquarium3)).called(1);
      });

      test('should handle empty list', () async {
        await aquariumDs.saveMultipleAquariums([]);

        verifyNever(() => mockAquariumBox.put(any<dynamic>(), any<dynamic>()));
      });
    });

    group('replaceAllForUser', () {
      test('should delete existing and save new aquariums', () async {
        final existingAquarium = createTestAquarium(id: 'existing_1');
        final newAquarium1 = createTestAquarium(id: 'new_1');
        final newAquarium2 = createTestAquarium(id: 'new_2');

        when(() => mockAquariumBox.values).thenReturn([existingAquarium]);
        when(
          () => mockAquariumBox.delete(any<dynamic>()),
        ).thenAnswer((_) async {});
        when(
          () => mockAquariumBox.put(any<dynamic>(), any<dynamic>()),
        ).thenAnswer((_) async {});

        await aquariumDs.replaceAllForUser('user_1', [
          newAquarium1,
          newAquarium2,
        ]);

        verify(() => mockAquariumBox.delete('existing_1')).called(1);
        verify(() => mockAquariumBox.put('new_1', newAquarium1)).called(1);
        verify(() => mockAquariumBox.put('new_2', newAquarium2)).called(1);
      });

      test('should only save when no existing aquariums', () async {
        final newAquarium = createTestAquarium(id: 'new_1');

        when(() => mockAquariumBox.values).thenReturn([]);
        when(
          () => mockAquariumBox.put(any<dynamic>(), any<dynamic>()),
        ).thenAnswer((_) async {});

        await aquariumDs.replaceAllForUser('user_1', [newAquarium]);

        verifyNever(() => mockAquariumBox.delete(any<dynamic>()));
        verify(() => mockAquariumBox.put('new_1', newAquarium)).called(1);
      });
    });
  });

  group('AquariumLocalDataSource constructor', () {
    test('should create instance with injected box', () {
      final ds = AquariumLocalDataSource(aquariumBox: mockAquariumBox);
      expect(ds, isA<AquariumLocalDataSource>());
    });
  });
}
