import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/species_model.dart';
import 'package:fishfeed/domain/entities/species.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_species_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await HiveBoxes.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SpeciesModel', () {
    test('should create SpeciesModel with required fields', () {
      final model = SpeciesModel(
        id: 'species-123',
        name: 'Neon Tetra',
      );

      expect(model.id, 'species-123');
      expect(model.name, 'Neon Tetra');
      expect(model.feedingFrequency, isNull);
      expect(model.optimalTemperature, isNull);
      expect(model.careLevel, isNull);
    });

    test('should create SpeciesModel with all fields', () {
      final model = SpeciesModel(
        id: 'species-full',
        name: 'Betta Splendens',
        feedingFrequency: 'twice_daily',
        optimalTemperature: 26.0,
        careLevel: 'beginner',
      );

      expect(model.id, 'species-full');
      expect(model.name, 'Betta Splendens');
      expect(model.feedingFrequency, 'twice_daily');
      expect(model.optimalTemperature, 26.0);
      expect(model.careLevel, 'beginner');
    });
  });

  group('SpeciesModel - entity conversion', () {
    test('toEntity should convert to Species entity', () {
      final model = SpeciesModel(
        id: 'species-123',
        name: 'Guppy',
        feedingFrequency: 'daily',
        optimalTemperature: 24.0,
        careLevel: 'beginner',
      );

      final entity = model.toEntity();

      expect(entity, isA<Species>());
      expect(entity.id, 'species-123');
      expect(entity.name, 'Guppy');
      expect(entity.feedingFrequency, 'daily');
      expect(entity.optimalTemperature, 24.0);
      expect(entity.careLevel, 'beginner');
    });

    test('fromEntity should create model from Species entity', () {
      const entity = Species(
        id: 'entity-species',
        name: 'Corydoras',
        feedingFrequency: 'daily',
        optimalTemperature: 25.0,
        careLevel: 'beginner',
      );

      final model = SpeciesModel.fromEntity(entity);

      expect(model.id, 'entity-species');
      expect(model.name, 'Corydoras');
      expect(model.feedingFrequency, 'daily');
      expect(model.optimalTemperature, 25.0);
      expect(model.careLevel, 'beginner');
    });

    test('round-trip conversion should preserve data', () {
      const originalEntity = Species(
        id: 'round-trip',
        name: 'Angelfish',
        feedingFrequency: 'twice_daily',
        optimalTemperature: 27.0,
        careLevel: 'intermediate',
      );

      final model = SpeciesModel.fromEntity(originalEntity);
      final resultEntity = model.toEntity();

      expect(resultEntity, equals(originalEntity));
    });

    test('round-trip should preserve null optional fields', () {
      const originalEntity = Species(
        id: 'minimal',
        name: 'Unknown Fish',
      );

      final model = SpeciesModel.fromEntity(originalEntity);
      final resultEntity = model.toEntity();

      expect(resultEntity, equals(originalEntity));
      expect(resultEntity.feedingFrequency, isNull);
      expect(resultEntity.optimalTemperature, isNull);
      expect(resultEntity.careLevel, isNull);
    });
  });

  group('SpeciesModel - Hive persistence', () {
    setUp(() async {
      await HiveBoxes.initForTesting();
    });

    test('should save and retrieve SpeciesModel from Hive', () async {
      final model = SpeciesModel(
        id: 'persist-species',
        name: 'Platy',
        feedingFrequency: 'daily',
        optimalTemperature: 24.0,
        careLevel: 'beginner',
      );

      await HiveBoxes.species.put(model.id, model);
      final retrieved = HiveBoxes.species.get(model.id) as SpeciesModel;

      expect(retrieved.id, model.id);
      expect(retrieved.name, model.name);
      expect(retrieved.feedingFrequency, model.feedingFrequency);
      expect(retrieved.optimalTemperature, model.optimalTemperature);
      expect(retrieved.careLevel, model.careLevel);
    });

    test('should retrieve multiple species', () async {
      final species1 = SpeciesModel(
        id: 'species-1',
        name: 'Neon Tetra',
        careLevel: 'beginner',
      );

      final species2 = SpeciesModel(
        id: 'species-2',
        name: 'Discus',
        careLevel: 'advanced',
      );

      final species3 = SpeciesModel(
        id: 'species-3',
        name: 'Oscar',
        careLevel: 'intermediate',
      );

      await HiveBoxes.species.put(species1.id, species1);
      await HiveBoxes.species.put(species2.id, species2);
      await HiveBoxes.species.put(species3.id, species3);

      expect(HiveBoxes.species.length, 3);

      final beginnerSpecies = HiveBoxes.species.values
          .cast<SpeciesModel>()
          .where((s) => s.careLevel == 'beginner')
          .toList();
      expect(beginnerSpecies.length, 1);
      expect(beginnerSpecies.first.name, 'Neon Tetra');
    });

    test('should filter species by care level', () async {
      final species = [
        SpeciesModel(id: '1', name: 'Guppy', careLevel: 'beginner'),
        SpeciesModel(id: '2', name: 'Betta', careLevel: 'beginner'),
        SpeciesModel(id: '3', name: 'Angelfish', careLevel: 'intermediate'),
        SpeciesModel(id: '4', name: 'Discus', careLevel: 'advanced'),
      ];

      for (final s in species) {
        await HiveBoxes.species.put(s.id, s);
      }

      final allSpecies =
          HiveBoxes.species.values.cast<SpeciesModel>().toList();
      final beginnerSpecies =
          allSpecies.where((s) => s.careLevel == 'beginner').toList();
      final advancedSpecies =
          allSpecies.where((s) => s.careLevel == 'advanced').toList();

      expect(allSpecies.length, 4);
      expect(beginnerSpecies.length, 2);
      expect(advancedSpecies.length, 1);
    });
  });

  group('SpeciesModel - TypeAdapter', () {
    test('should have correct typeId', () {
      final adapter = SpeciesModelAdapter();
      expect(adapter.typeId, 7);
    });
  });
}
