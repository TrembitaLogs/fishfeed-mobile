import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/domain/entities/fish.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_fish_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await HiveBoxes.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FishModel', () {
    test('should create FishModel with required fields', () {
      final now = DateTime.now();
      final model = FishModel(
        id: 'fish-123',
        aquariumId: 'aquarium-456',
        speciesId: 'species-789',
        addedAt: now,
      );

      expect(model.id, 'fish-123');
      expect(model.aquariumId, 'aquarium-456');
      expect(model.speciesId, 'species-789');
      expect(model.addedAt, now);
      expect(model.name, isNull);
      expect(model.quantity, 1);
      expect(model.notes, isNull);
    });

    test('should create FishModel with all fields', () {
      final now = DateTime.now();
      final model = FishModel(
        id: 'fish-789',
        aquariumId: 'aquarium-111',
        speciesId: 'neon-tetra',
        name: 'My Neons',
        quantity: 10,
        notes: 'Healthy school of neon tetras',
        addedAt: now,
      );

      expect(model.id, 'fish-789');
      expect(model.aquariumId, 'aquarium-111');
      expect(model.speciesId, 'neon-tetra');
      expect(model.name, 'My Neons');
      expect(model.quantity, 10);
      expect(model.notes, 'Healthy school of neon tetras');
    });
  });

  group('FishModel - entity conversion', () {
    test('toEntity should convert to Fish entity', () {
      final now = DateTime.now();
      final model = FishModel(
        id: 'fish-123',
        aquariumId: 'aquarium-456',
        speciesId: 'guppy',
        name: 'Fancy Guppies',
        quantity: 5,
        notes: 'Colorful guppies',
        addedAt: now,
      );

      final entity = model.toEntity();

      expect(entity, isA<Fish>());
      expect(entity.id, 'fish-123');
      expect(entity.aquariumId, 'aquarium-456');
      expect(entity.speciesId, 'guppy');
      expect(entity.name, 'Fancy Guppies');
      expect(entity.quantity, 5);
      expect(entity.notes, 'Colorful guppies');
      expect(entity.addedAt, now);
    });

    test('fromEntity should create model from Fish entity', () {
      final now = DateTime.now();
      final entity = Fish(
        id: 'entity-fish',
        aquariumId: 'entity-aquarium',
        speciesId: 'betta',
        name: 'Betta Bob',
        quantity: 1,
        notes: 'Beautiful betta',
        addedAt: now,
      );

      final model = FishModel.fromEntity(entity);

      expect(model.id, 'entity-fish');
      expect(model.aquariumId, 'entity-aquarium');
      expect(model.speciesId, 'betta');
      expect(model.name, 'Betta Bob');
      expect(model.quantity, 1);
      expect(model.notes, 'Beautiful betta');
      expect(model.addedAt, now);
    });

    test('round-trip conversion should preserve data', () {
      final now = DateTime.now();
      final originalEntity = Fish(
        id: 'round-trip-fish',
        aquariumId: 'round-trip-aquarium',
        speciesId: 'angelfish',
        name: 'Angel',
        quantity: 2,
        notes: 'Pair of angelfish',
        addedAt: now,
      );

      final model = FishModel.fromEntity(originalEntity);
      final resultEntity = model.toEntity();

      expect(resultEntity, equals(originalEntity));
    });

    test('round-trip should preserve null optional fields', () {
      final now = DateTime.now();
      final originalEntity = Fish(
        id: 'minimal-fish',
        aquariumId: 'minimal-aquarium',
        speciesId: 'goldfish',
        addedAt: now,
      );

      final model = FishModel.fromEntity(originalEntity);
      final resultEntity = model.toEntity();

      expect(resultEntity, equals(originalEntity));
      expect(resultEntity.name, isNull);
      expect(resultEntity.notes, isNull);
      expect(resultEntity.quantity, 1);
    });
  });

  group('FishModel - Hive persistence', () {
    setUp(() async {
      await HiveBoxes.initForTesting();
    });

    test('should save and retrieve FishModel from Hive', () async {
      final now = DateTime.now();
      final model = FishModel(
        id: 'persist-fish',
        aquariumId: 'persist-aquarium',
        speciesId: 'corydoras',
        name: 'Cory Cats',
        quantity: 6,
        notes: 'Bottom dwellers',
        addedAt: now,
      );

      await HiveBoxes.fish.put(model.id, model);
      final retrieved = HiveBoxes.fish.get(model.id) as FishModel;

      expect(retrieved.id, model.id);
      expect(retrieved.aquariumId, model.aquariumId);
      expect(retrieved.speciesId, model.speciesId);
      expect(retrieved.name, model.name);
      expect(retrieved.quantity, model.quantity);
      expect(retrieved.notes, model.notes);
    });

    test('should retrieve multiple fish models', () async {
      final fish1 = FishModel(
        id: 'fish-1',
        aquariumId: 'aquarium-1',
        speciesId: 'guppy',
        quantity: 5,
        addedAt: DateTime.now(),
      );

      final fish2 = FishModel(
        id: 'fish-2',
        aquariumId: 'aquarium-1',
        speciesId: 'neon-tetra',
        quantity: 10,
        addedAt: DateTime.now(),
      );

      await HiveBoxes.fish.put(fish1.id, fish1);
      await HiveBoxes.fish.put(fish2.id, fish2);

      expect(HiveBoxes.fish.length, 2);
      expect((HiveBoxes.fish.get('fish-1') as FishModel).speciesId, 'guppy');
      expect(
        (HiveBoxes.fish.get('fish-2') as FishModel).speciesId,
        'neon-tetra',
      );
    });
  });
}
