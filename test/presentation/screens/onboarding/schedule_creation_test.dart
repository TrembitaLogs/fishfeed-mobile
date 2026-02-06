import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:fishfeed/domain/entities/species.dart';
import 'package:fishfeed/presentation/providers/onboarding_provider.dart';

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  group('Schedule Creation from Onboarding', () {
    late MockBox mockBox;
    late ScheduleLocalDataSource scheduleDs;

    setUp(() {
      mockBox = MockBox();
      scheduleDs = ScheduleLocalDataSource(schedulesBox: mockBox);
    });

    test(
      'should create correct number of schedules for twice daily feeding',
      () async {
        // Arrange
        const userId = 'test-user-123';
        const aquariumId = 'test-aquarium-123';
        const fishId = 'test-fish-123';
        const speciesId = 'guppy';
        final now = DateTime.now();

        final generatedSchedule = [
          GeneratedScheduleEntry(
            speciesId: speciesId,
            speciesName: 'Guppy',
            feedingTimes: ['08:00', '20:00'], // Two feeding times
            foodType: FoodType.flakes,
            portionGrams: 0.5,
          ),
        ];

        final selectedSpecies = [
          SpeciesSelection(
            species: const Species(
              id: speciesId,
              name: 'Guppy',
              feedingFrequency: 'twice_daily',
              foodType: FoodType.flakes,
            ),
            quantity: 3,
          ),
        ];

        final speciesIdToFishId = <String, String>{speciesId: fishId};

        // Track saved schedules
        final savedSchedules = <ScheduleModel>[];
        when(() => mockBox.putAll(any())).thenAnswer((invocation) async {
          final entries =
              invocation.positionalArguments[0] as Map<String, ScheduleModel>;
          savedSchedules.addAll(entries.values);
        });

        // Act - simulate the logic from _saveSchedules
        const uuid = Uuid();
        final schedulesToSave = <ScheduleModel>[];

        final speciesFrequencyMap = <String, String>{};
        for (final selection in selectedSpecies) {
          speciesFrequencyMap[selection.species.id] =
              selection.species.feedingFrequency ?? 'daily';
        }

        for (final entry in generatedSchedule) {
          final targetFishId = speciesIdToFishId[entry.speciesId];
          if (targetFishId == null) continue;

          final frequency = speciesFrequencyMap[entry.speciesId] ?? 'daily';
          final intervalDays = frequency == 'every_other_day' ? 2 : 1;

          for (final time in entry.feedingTimes) {
            final schedule = ScheduleModel(
              id: uuid.v4(),
              fishId: targetFishId,
              aquariumId: aquariumId,
              time: time,
              intervalDays: intervalDays,
              anchorDate: DateTime(now.year, now.month, now.day),
              foodType: entry.foodType.name,
              portionHint: '${entry.portionGrams.toStringAsFixed(1)}g',
              active: true,
              createdAt: now,
              updatedAt: now,
              createdByUserId: userId,
              synced: false,
            );
            schedulesToSave.add(schedule);
          }
        }

        await scheduleDs.saveAll(schedulesToSave);

        // Assert
        verify(() => mockBox.putAll(any())).called(1);
        expect(savedSchedules.length, 2);

        // Verify first schedule (08:00)
        final schedule1 = savedSchedules[0];
        expect(schedule1.fishId, fishId);
        expect(schedule1.aquariumId, aquariumId);
        expect(schedule1.time, '08:00');
        expect(schedule1.intervalDays, 1);
        expect(schedule1.foodType, 'flakes');
        expect(schedule1.portionHint, '0.5g');
        expect(schedule1.active, true);
        expect(schedule1.synced, false);
        expect(schedule1.createdByUserId, userId);

        // Verify second schedule (20:00)
        final schedule2 = savedSchedules[1];
        expect(schedule2.time, '20:00');
        expect(schedule2.fishId, fishId);
      },
    );

    test(
      'should create schedules with intervalDays=2 for every_other_day frequency',
      () async {
        // Arrange
        const userId = 'test-user-123';
        const aquariumId = 'test-aquarium-123';
        const fishId = 'test-fish-456';
        const speciesId = 'betta';
        final now = DateTime.now();

        final generatedSchedule = [
          GeneratedScheduleEntry(
            speciesId: speciesId,
            speciesName: 'Betta',
            feedingTimes: ['09:00'],
            foodType: FoodType.pellets,
            portionGrams: 0.3,
          ),
        ];

        final selectedSpecies = [
          SpeciesSelection(
            species: const Species(
              id: speciesId,
              name: 'Betta',
              feedingFrequency:
                  'every_other_day', // Should result in intervalDays=2
              foodType: FoodType.pellets,
            ),
            quantity: 1,
          ),
        ];

        final speciesIdToFishId = <String, String>{speciesId: fishId};

        final savedSchedules = <ScheduleModel>[];
        when(() => mockBox.putAll(any())).thenAnswer((invocation) async {
          final entries =
              invocation.positionalArguments[0] as Map<String, ScheduleModel>;
          savedSchedules.addAll(entries.values);
        });

        // Act
        const uuid = Uuid();
        final schedulesToSave = <ScheduleModel>[];

        final speciesFrequencyMap = <String, String>{};
        for (final selection in selectedSpecies) {
          speciesFrequencyMap[selection.species.id] =
              selection.species.feedingFrequency ?? 'daily';
        }

        for (final entry in generatedSchedule) {
          final targetFishId = speciesIdToFishId[entry.speciesId];
          if (targetFishId == null) continue;

          final frequency = speciesFrequencyMap[entry.speciesId] ?? 'daily';
          final intervalDays = frequency == 'every_other_day' ? 2 : 1;

          for (final time in entry.feedingTimes) {
            final schedule = ScheduleModel(
              id: uuid.v4(),
              fishId: targetFishId,
              aquariumId: aquariumId,
              time: time,
              intervalDays: intervalDays,
              anchorDate: DateTime(now.year, now.month, now.day),
              foodType: entry.foodType.name,
              portionHint: '${entry.portionGrams.toStringAsFixed(1)}g',
              active: true,
              createdAt: now,
              updatedAt: now,
              createdByUserId: userId,
              synced: false,
            );
            schedulesToSave.add(schedule);
          }
        }

        await scheduleDs.saveAll(schedulesToSave);

        // Assert
        expect(savedSchedules.length, 1);

        final schedule = savedSchedules[0];
        expect(schedule.fishId, fishId);
        expect(schedule.time, '09:00');
        expect(schedule.intervalDays, 2); // Key assertion
        expect(schedule.foodType, 'pellets');
        expect(schedule.synced, false);
      },
    );

    test('should create schedules for multiple species', () async {
      // Arrange
      const userId = 'test-user-123';
      const aquariumId = 'test-aquarium-123';
      final now = DateTime.now();

      final generatedSchedule = [
        GeneratedScheduleEntry(
          speciesId: 'guppy',
          speciesName: 'Guppy',
          feedingTimes: ['08:00', '20:00'],
          foodType: FoodType.flakes,
          portionGrams: 1.0,
        ),
        GeneratedScheduleEntry(
          speciesId: 'neon_tetra',
          speciesName: 'Neon Tetra',
          feedingTimes: ['09:00', '18:00'],
          foodType: FoodType.flakes,
          portionGrams: 0.5,
        ),
      ];

      final selectedSpecies = [
        SpeciesSelection(
          species: const Species(
            id: 'guppy',
            name: 'Guppy',
            feedingFrequency: 'twice_daily',
          ),
          quantity: 5,
        ),
        SpeciesSelection(
          species: const Species(
            id: 'neon_tetra',
            name: 'Neon Tetra',
            feedingFrequency: 'twice_daily',
          ),
          quantity: 10,
        ),
      ];

      final speciesIdToFishId = <String, String>{
        'guppy': 'fish-guppy-123',
        'neon_tetra': 'fish-neon-456',
      };

      final savedSchedules = <ScheduleModel>[];
      when(() => mockBox.putAll(any())).thenAnswer((invocation) async {
        final entries =
            invocation.positionalArguments[0] as Map<String, ScheduleModel>;
        savedSchedules.addAll(entries.values);
      });

      // Act
      const uuid = Uuid();
      final schedulesToSave = <ScheduleModel>[];

      final speciesFrequencyMap = <String, String>{};
      for (final selection in selectedSpecies) {
        speciesFrequencyMap[selection.species.id] =
            selection.species.feedingFrequency ?? 'daily';
      }

      for (final entry in generatedSchedule) {
        final targetFishId = speciesIdToFishId[entry.speciesId];
        if (targetFishId == null) continue;

        final frequency = speciesFrequencyMap[entry.speciesId] ?? 'daily';
        final intervalDays = frequency == 'every_other_day' ? 2 : 1;

        for (final time in entry.feedingTimes) {
          final schedule = ScheduleModel(
            id: uuid.v4(),
            fishId: targetFishId,
            aquariumId: aquariumId,
            time: time,
            intervalDays: intervalDays,
            anchorDate: DateTime(now.year, now.month, now.day),
            foodType: entry.foodType.name,
            portionHint: '${entry.portionGrams.toStringAsFixed(1)}g',
            active: true,
            createdAt: now,
            updatedAt: now,
            createdByUserId: userId,
            synced: false,
          );
          schedulesToSave.add(schedule);
        }
      }

      await scheduleDs.saveAll(schedulesToSave);

      // Assert
      expect(savedSchedules.length, 4); // 2 times x 2 species

      // Verify guppy schedules
      final guppySchedules = savedSchedules
          .where((s) => s.fishId == 'fish-guppy-123')
          .toList();
      expect(guppySchedules.length, 2);
      expect(guppySchedules.map((s) => s.time).toSet(), {'08:00', '20:00'});

      // Verify neon tetra schedules
      final neonSchedules = savedSchedules
          .where((s) => s.fishId == 'fish-neon-456')
          .toList();
      expect(neonSchedules.length, 2);
      expect(neonSchedules.map((s) => s.time).toSet(), {'09:00', '18:00'});
    });

    test('should skip species without matching fish ID', () async {
      // Arrange
      const aquariumId = 'test-aquarium-123';
      final now = DateTime.now();

      final generatedSchedule = [
        GeneratedScheduleEntry(
          speciesId: 'guppy',
          speciesName: 'Guppy',
          feedingTimes: ['08:00'],
          foodType: FoodType.flakes,
          portionGrams: 0.5,
        ),
        GeneratedScheduleEntry(
          speciesId: 'unknown_species', // No matching fish
          speciesName: 'Unknown',
          feedingTimes: ['09:00'],
          foodType: FoodType.mixed,
          portionGrams: 1.0,
        ),
      ];

      final selectedSpecies = [
        SpeciesSelection(
          species: const Species(id: 'guppy', name: 'Guppy'),
          quantity: 3,
        ),
      ];

      // Only guppy has a fish ID
      final speciesIdToFishId = <String, String>{'guppy': 'fish-guppy-123'};

      final savedSchedules = <ScheduleModel>[];
      when(() => mockBox.putAll(any())).thenAnswer((invocation) async {
        final entries =
            invocation.positionalArguments[0] as Map<String, ScheduleModel>;
        savedSchedules.addAll(entries.values);
      });

      // Act
      const uuid = Uuid();
      final schedulesToSave = <ScheduleModel>[];

      final speciesFrequencyMap = <String, String>{};
      for (final selection in selectedSpecies) {
        speciesFrequencyMap[selection.species.id] =
            selection.species.feedingFrequency ?? 'daily';
      }

      for (final entry in generatedSchedule) {
        final targetFishId = speciesIdToFishId[entry.speciesId];
        if (targetFishId == null) continue; // Skip unknown species

        final frequency = speciesFrequencyMap[entry.speciesId] ?? 'daily';
        final intervalDays = frequency == 'every_other_day' ? 2 : 1;

        for (final time in entry.feedingTimes) {
          final schedule = ScheduleModel(
            id: uuid.v4(),
            fishId: targetFishId,
            aquariumId: aquariumId,
            time: time,
            intervalDays: intervalDays,
            anchorDate: DateTime(now.year, now.month, now.day),
            foodType: entry.foodType.name,
            portionHint: '${entry.portionGrams.toStringAsFixed(1)}g',
            active: true,
            createdAt: now,
            updatedAt: now,
            createdByUserId: 'test-user',
            synced: false,
          );
          schedulesToSave.add(schedule);
        }
      }

      await scheduleDs.saveAll(schedulesToSave);

      // Assert - only guppy schedule should be created
      expect(savedSchedules.length, 1);
      expect(savedSchedules[0].fishId, 'fish-guppy-123');
      expect(savedSchedules[0].time, '08:00');
    });

    test('should preserve user-edited times from onboarding', () async {
      // Arrange - user edited default 09:00 to 08:30
      const aquariumId = 'test-aquarium-123';
      final now = DateTime.now();

      final generatedSchedule = [
        GeneratedScheduleEntry(
          speciesId: 'guppy',
          speciesName: 'Guppy',
          feedingTimes: ['08:30', '19:45'], // User-edited times
          foodType: FoodType.flakes,
          portionGrams: 0.5,
        ),
      ];

      final speciesIdToFishId = <String, String>{'guppy': 'fish-guppy-123'};

      final savedSchedules = <ScheduleModel>[];
      when(() => mockBox.putAll(any())).thenAnswer((invocation) async {
        final entries =
            invocation.positionalArguments[0] as Map<String, ScheduleModel>;
        savedSchedules.addAll(entries.values);
      });

      // Act
      const uuid = Uuid();
      final schedulesToSave = <ScheduleModel>[];

      for (final entry in generatedSchedule) {
        final targetFishId = speciesIdToFishId[entry.speciesId];
        if (targetFishId == null) continue;

        for (final time in entry.feedingTimes) {
          final schedule = ScheduleModel(
            id: uuid.v4(),
            fishId: targetFishId,
            aquariumId: aquariumId,
            time: time,
            intervalDays: 1,
            anchorDate: DateTime(now.year, now.month, now.day),
            foodType: entry.foodType.name,
            portionHint: '${entry.portionGrams.toStringAsFixed(1)}g',
            active: true,
            createdAt: now,
            updatedAt: now,
            createdByUserId: 'test-user',
            synced: false,
          );
          schedulesToSave.add(schedule);
        }
      }

      await scheduleDs.saveAll(schedulesToSave);

      // Assert - user-edited times should be preserved
      expect(savedSchedules.length, 2);
      expect(savedSchedules[0].time, '08:30');
      expect(savedSchedules[1].time, '19:45');
    });
  });
}
