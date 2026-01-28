import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/water_type.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_aquarium_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await HiveBoxes.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AquariumModel', () {
    test('should create AquariumModel with required fields', () {
      final now = DateTime.now();
      final model = AquariumModel(
        id: 'aquarium-123',
        userId: 'user-456',
        name: 'My Aquarium',
        createdAt: now,
      );

      expect(model.id, 'aquarium-123');
      expect(model.userId, 'user-456');
      expect(model.name, 'My Aquarium');
      expect(model.createdAt, now);
      expect(model.capacity, isNull);
      expect(model.waterType, WaterType.freshwater);
      expect(model.imageUrl, isNull);
    });

    test('should create AquariumModel with all fields', () {
      final now = DateTime.now();
      final model = AquariumModel(
        id: 'aquarium-789',
        userId: 'user-111',
        name: 'Saltwater Tank',
        capacity: 200.5,
        waterType: WaterType.saltwater,
        imageUrl: 'https://example.com/tank.png',
        createdAt: now,
      );

      expect(model.id, 'aquarium-789');
      expect(model.userId, 'user-111');
      expect(model.name, 'Saltwater Tank');
      expect(model.capacity, 200.5);
      expect(model.waterType, WaterType.saltwater);
      expect(model.imageUrl, 'https://example.com/tank.png');
    });

    test('should support brackish water type', () {
      final model = AquariumModel(
        id: 'aquarium-brackish',
        userId: 'user-1',
        name: 'Brackish Tank',
        waterType: WaterType.brackish,
        createdAt: DateTime.now(),
      );

      expect(model.waterType, WaterType.brackish);
    });
  });

  group('AquariumModel - entity conversion', () {
    test('toEntity should convert to Aquarium entity', () {
      final now = DateTime.now();
      final model = AquariumModel(
        id: 'aquarium-123',
        userId: 'user-456',
        name: 'Test Aquarium',
        capacity: 100.0,
        waterType: WaterType.saltwater,
        imageUrl: 'https://example.com/test.png',
        createdAt: now,
      );

      final entity = model.toEntity();

      expect(entity, isA<Aquarium>());
      expect(entity.id, 'aquarium-123');
      expect(entity.userId, 'user-456');
      expect(entity.name, 'Test Aquarium');
      expect(entity.capacity, 100.0);
      expect(entity.waterType, WaterType.saltwater);
      expect(entity.imageUrl, 'https://example.com/test.png');
      expect(entity.createdAt, now);
    });

    test('fromEntity should create model from Aquarium entity', () {
      final now = DateTime.now();
      final entity = Aquarium(
        id: 'entity-aquarium',
        userId: 'entity-user',
        name: 'Entity Aquarium',
        capacity: 150.0,
        waterType: WaterType.brackish,
        imageUrl: 'https://example.com/entity.png',
        createdAt: now,
      );

      final model = AquariumModel.fromEntity(entity);

      expect(model.id, 'entity-aquarium');
      expect(model.userId, 'entity-user');
      expect(model.name, 'Entity Aquarium');
      expect(model.capacity, 150.0);
      expect(model.waterType, WaterType.brackish);
      expect(model.imageUrl, 'https://example.com/entity.png');
      expect(model.createdAt, now);
    });

    test('round-trip conversion should preserve data', () {
      final now = DateTime.now();
      final originalEntity = Aquarium(
        id: 'round-trip-aquarium',
        userId: 'round-trip-user',
        name: 'Round Trip Tank',
        capacity: 75.5,
        waterType: WaterType.freshwater,
        imageUrl: 'https://example.com/round.png',
        createdAt: now,
      );

      final model = AquariumModel.fromEntity(originalEntity);
      final resultEntity = model.toEntity();

      expect(resultEntity, equals(originalEntity));
    });

    test('round-trip should preserve null optional fields', () {
      final now = DateTime.now();
      final originalEntity = Aquarium(
        id: 'minimal-aquarium',
        userId: 'minimal-user',
        name: 'Minimal Tank',
        createdAt: now,
      );

      final model = AquariumModel.fromEntity(originalEntity);
      final resultEntity = model.toEntity();

      expect(resultEntity, equals(originalEntity));
      expect(resultEntity.capacity, isNull);
      expect(resultEntity.imageUrl, isNull);
    });
  });

  group('AquariumModel - Hive persistence', () {
    setUp(() async {
      await HiveBoxes.initForTesting();
    });

    test('should save and retrieve AquariumModel from Hive', () async {
      final now = DateTime.now();
      final model = AquariumModel(
        id: 'persist-aquarium',
        userId: 'persist-user',
        name: 'Persist Tank',
        capacity: 120.0,
        waterType: WaterType.freshwater,
        createdAt: now,
      );

      await HiveBoxes.aquariums.put(model.id, model);
      final retrieved = HiveBoxes.aquariums.get(model.id) as AquariumModel;

      expect(retrieved.id, model.id);
      expect(retrieved.userId, model.userId);
      expect(retrieved.name, model.name);
      expect(retrieved.capacity, model.capacity);
      expect(retrieved.waterType, model.waterType);
    });

    test('should persist all WaterType enum values', () async {
      for (final waterType in WaterType.values) {
        final model = AquariumModel(
          id: 'water-type-${waterType.name}',
          userId: 'user-1',
          name: '${waterType.name} Tank',
          waterType: waterType,
          createdAt: DateTime.now(),
        );

        await HiveBoxes.aquariums.put(model.id, model);
        final retrieved = HiveBoxes.aquariums.get(model.id) as AquariumModel;

        expect(retrieved.waterType, waterType);
      }
    });
  });
}
