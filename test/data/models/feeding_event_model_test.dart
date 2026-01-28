import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/feeding_event_model.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_feeding_event_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await HiveBoxes.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FeedingEventModel', () {
    test('should create FeedingEventModel with required fields', () {
      final feedingTime = DateTime.now();
      final createdAt = DateTime.now();
      final model = FeedingEventModel(
        id: 'event-123',
        fishId: 'fish-456',
        aquariumId: 'aquarium-789',
        feedingTime: feedingTime,
        createdAt: createdAt,
      );

      expect(model.id, 'event-123');
      expect(model.fishId, 'fish-456');
      expect(model.aquariumId, 'aquarium-789');
      expect(model.feedingTime, feedingTime);
      expect(model.createdAt, createdAt);
      expect(model.synced, false);
      expect(model.amount, isNull);
      expect(model.foodType, isNull);
      expect(model.notes, isNull);
      expect(model.localId, isNull);
    });

    test('should create FeedingEventModel with all fields', () {
      final feedingTime = DateTime.now();
      final createdAt = DateTime.now();
      final model = FeedingEventModel(
        id: 'event-full',
        fishId: 'fish-full',
        aquariumId: 'aquarium-full',
        feedingTime: feedingTime,
        amount: 2.5,
        foodType: 'flakes',
        notes: 'Fed in the morning',
        synced: true,
        createdAt: createdAt,
        localId: 'local-123',
      );

      expect(model.id, 'event-full');
      expect(model.amount, 2.5);
      expect(model.foodType, 'flakes');
      expect(model.notes, 'Fed in the morning');
      expect(model.synced, true);
      expect(model.localId, 'local-123');
    });

    test('synced should default to false for offline-first', () {
      final model = FeedingEventModel(
        id: 'offline-event',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        feedingTime: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(model.synced, false);
    });
  });

  group('FeedingEventModel - entity conversion', () {
    test('toEntity should convert to FeedingEvent entity', () {
      final feedingTime = DateTime.now();
      final createdAt = DateTime.now();
      final model = FeedingEventModel(
        id: 'event-123',
        fishId: 'fish-456',
        aquariumId: 'aquarium-789',
        feedingTime: feedingTime,
        amount: 1.5,
        foodType: 'pellets',
        notes: 'Evening feeding',
        synced: false,
        createdAt: createdAt,
        localId: 'local-456',
      );

      final entity = model.toEntity();

      expect(entity, isA<FeedingEvent>());
      expect(entity.id, 'event-123');
      expect(entity.fishId, 'fish-456');
      expect(entity.aquariumId, 'aquarium-789');
      expect(entity.feedingTime, feedingTime);
      expect(entity.amount, 1.5);
      expect(entity.foodType, 'pellets');
      expect(entity.notes, 'Evening feeding');
      expect(entity.synced, false);
      expect(entity.createdAt, createdAt);
      expect(entity.localId, 'local-456');
    });

    test('fromEntity should create model from FeedingEvent entity', () {
      final feedingTime = DateTime.now();
      final createdAt = DateTime.now();
      final entity = FeedingEvent(
        id: 'entity-event',
        fishId: 'entity-fish',
        aquariumId: 'entity-aquarium',
        feedingTime: feedingTime,
        amount: 3.0,
        foodType: 'live',
        notes: 'Brine shrimp',
        synced: true,
        createdAt: createdAt,
        localId: 'entity-local',
      );

      final model = FeedingEventModel.fromEntity(entity);

      expect(model.id, 'entity-event');
      expect(model.fishId, 'entity-fish');
      expect(model.aquariumId, 'entity-aquarium');
      expect(model.feedingTime, feedingTime);
      expect(model.amount, 3.0);
      expect(model.foodType, 'live');
      expect(model.notes, 'Brine shrimp');
      expect(model.synced, true);
      expect(model.createdAt, createdAt);
      expect(model.localId, 'entity-local');
    });

    test('round-trip conversion should preserve data', () {
      final feedingTime = DateTime.now();
      final createdAt = DateTime.now();
      final originalEntity = FeedingEvent(
        id: 'round-trip',
        fishId: 'fish-rt',
        aquariumId: 'aquarium-rt',
        feedingTime: feedingTime,
        amount: 2.0,
        foodType: 'frozen',
        notes: 'Bloodworms',
        synced: false,
        createdAt: createdAt,
        localId: 'local-rt',
      );

      final model = FeedingEventModel.fromEntity(originalEntity);
      final resultEntity = model.toEntity();

      expect(resultEntity, equals(originalEntity));
    });

    test('round-trip should preserve synced field correctly', () {
      final feedingTime = DateTime.now();
      final createdAt = DateTime.now();

      final unsyncedEntity = FeedingEvent(
        id: 'unsynced',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        feedingTime: feedingTime,
        synced: false,
        createdAt: createdAt,
      );

      final syncedEntity = FeedingEvent(
        id: 'synced',
        fishId: 'fish-2',
        aquariumId: 'aquarium-2',
        feedingTime: feedingTime,
        synced: true,
        createdAt: createdAt,
      );

      final unsyncedModel = FeedingEventModel.fromEntity(unsyncedEntity);
      final syncedModel = FeedingEventModel.fromEntity(syncedEntity);

      expect(unsyncedModel.toEntity().synced, false);
      expect(syncedModel.toEntity().synced, true);
    });
  });

  group('FeedingEventModel - Hive persistence', () {
    setUp(() async {
      await HiveBoxes.initForTesting();
    });

    test('should save and retrieve FeedingEventModel from Hive', () async {
      final feedingTime = DateTime.now();
      final createdAt = DateTime.now();
      final model = FeedingEventModel(
        id: 'persist-event',
        fishId: 'persist-fish',
        aquariumId: 'persist-aquarium',
        feedingTime: feedingTime,
        amount: 1.0,
        foodType: 'flakes',
        synced: false,
        createdAt: createdAt,
      );

      await HiveBoxes.feedingEvents.put(model.id, model);
      final retrieved =
          HiveBoxes.feedingEvents.get(model.id) as FeedingEventModel;

      expect(retrieved.id, model.id);
      expect(retrieved.fishId, model.fishId);
      expect(retrieved.aquariumId, model.aquariumId);
      expect(retrieved.amount, model.amount);
      expect(retrieved.foodType, model.foodType);
      expect(retrieved.synced, model.synced);
    });

    test('should retrieve unsynced events', () async {
      final event1 = FeedingEventModel(
        id: 'synced-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        feedingTime: DateTime.now(),
        synced: true,
        createdAt: DateTime.now(),
      );

      final event2 = FeedingEventModel(
        id: 'unsynced-1',
        fishId: 'fish-2',
        aquariumId: 'aquarium-1',
        feedingTime: DateTime.now(),
        synced: false,
        createdAt: DateTime.now(),
      );

      final event3 = FeedingEventModel(
        id: 'unsynced-2',
        fishId: 'fish-3',
        aquariumId: 'aquarium-1',
        feedingTime: DateTime.now(),
        synced: false,
        createdAt: DateTime.now(),
      );

      await HiveBoxes.feedingEvents.put(event1.id, event1);
      await HiveBoxes.feedingEvents.put(event2.id, event2);
      await HiveBoxes.feedingEvents.put(event3.id, event3);

      final allEvents =
          HiveBoxes.feedingEvents.values.cast<FeedingEventModel>().toList();
      final unsyncedEvents =
          allEvents.where((event) => !event.synced).toList();

      expect(allEvents.length, 3);
      expect(unsyncedEvents.length, 2);
      expect(unsyncedEvents.any((e) => e.id == 'unsynced-1'), true);
      expect(unsyncedEvents.any((e) => e.id == 'unsynced-2'), true);
    });
  });

  group('FeedingEventModel - TypeAdapter', () {
    test('should have correct typeId', () {
      final adapter = FeedingEventModelAdapter();
      expect(adapter.typeId, 4);
    });
  });
}
