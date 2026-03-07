import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:fishfeed/domain/entities/water_type.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'apply_server_update_test_',
    );
    Hive.init(tempDir.path);
    await HiveBoxes.initForTesting();
  });

  tearDown(() async {
    await HiveBoxes.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FishLocalDataSource.applyServerUpdate', () {
    late FishLocalDataSource fishDs;

    setUp(() {
      fishDs = FishLocalDataSource();
    });

    FishModel createExistingFish({
      String id = 'fish-1',
      String aquariumId = 'aquarium-1',
      String speciesId = 'species-1',
      String? name,
      int quantity = 1,
      String? notes,
      String? photoKey,
      DateTime? serverUpdatedAt,
    }) {
      return FishModel(
        id: id,
        aquariumId: aquariumId,
        speciesId: speciesId,
        name: name,
        quantity: quantity,
        notes: notes,
        photoKey: photoKey,
        addedAt: DateTime(2025, 1, 15),
        synced: true,
        serverUpdatedAt: serverUpdatedAt,
        updatedAt: serverUpdatedAt,
      );
    }

    test('UPDATE: notes applied from server data', () async {
      final oldTime = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 12, 0);

      await fishDs.saveFish(
        createExistingFish(
          id: 'fish-1',
          notes: 'Old notes',
          serverUpdatedAt: oldTime,
        ),
      );

      await fishDs.applyServerUpdate({
        'id': 'fish-1',
        'notes': 'Updated notes from server',
        'updated_at': newTime.toIso8601String(),
      });

      final updated = fishDs.getFishById('fish-1');
      expect(updated, isNotNull);
      expect(updated!.notes, 'Updated notes from server');
    });

    test('UPDATE: explicit null notes clears existing notes', () async {
      final oldTime = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 12, 0);

      await fishDs.saveFish(
        createExistingFish(
          id: 'fish-1',
          notes: 'Some notes',
          serverUpdatedAt: oldTime,
        ),
      );

      // Server explicitly sends notes: null → clears the value.
      // Implementation uses containsKey('notes') so null is applied.
      await fishDs.applyServerUpdate({
        'id': 'fish-1',
        'notes': null,
        'updated_at': newTime.toIso8601String(),
      });

      final updated = fishDs.getFishById('fish-1');
      expect(updated, isNotNull);
      expect(updated!.notes, isNull);
    });

    test('UPDATE: aquarium_id applied (fish move)', () async {
      final oldTime = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 12, 0);

      await fishDs.saveFish(
        createExistingFish(
          id: 'fish-1',
          aquariumId: 'aquarium-old',
          serverUpdatedAt: oldTime,
        ),
      );

      await fishDs.applyServerUpdate({
        'id': 'fish-1',
        'aquarium_id': 'aquarium-new',
        'updated_at': newTime.toIso8601String(),
      });

      final updated = fishDs.getFishById('fish-1');
      expect(updated, isNotNull);
      expect(updated!.aquariumId, 'aquarium-new');
    });

    test('UPDATE: photo_key applied when containsKey(photo_key)', () async {
      final oldTime = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 12, 0);

      await fishDs.saveFish(
        createExistingFish(
          id: 'fish-1',
          photoKey: null,
          serverUpdatedAt: oldTime,
        ),
      );

      await fishDs.applyServerUpdate({
        'id': 'fish-1',
        'photo_key': 'fish/fish-1/abc123.webp',
        'updated_at': newTime.toIso8601String(),
      });

      final updated = fishDs.getFishById('fish-1');
      expect(updated, isNotNull);
      expect(updated!.photoKey, 'fish/fish-1/abc123.webp');
    });

    test('UPDATE: photo_key set to null when server sends null', () async {
      final oldTime = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 12, 0);

      await fishDs.saveFish(
        createExistingFish(
          id: 'fish-1',
          photoKey: 'fish/fish-1/old-photo.webp',
          serverUpdatedAt: oldTime,
        ),
      );

      // Server sends photo_key: null (photo deleted)
      await fishDs.applyServerUpdate({
        'id': 'fish-1',
        'photo_key': null,
        'updated_at': newTime.toIso8601String(),
      });

      final updated = fishDs.getFishById('fish-1');
      expect(updated, isNotNull);
      expect(updated!.photoKey, isNull);
    });

    test(
      'UPDATE: photo_key NOT changed when key absent from server data',
      () async {
        final oldTime = DateTime(2025, 1, 15, 10, 0);
        final newTime = DateTime(2025, 1, 15, 12, 0);

        await fishDs.saveFish(
          createExistingFish(
            id: 'fish-1',
            photoKey: 'fish/fish-1/existing.webp',
            serverUpdatedAt: oldTime,
          ),
        );

        // Server data does NOT include photo_key at all
        await fishDs.applyServerUpdate({
          'id': 'fish-1',
          'quantity': 3,
          'updated_at': newTime.toIso8601String(),
        });

        final updated = fishDs.getFishById('fish-1');
        expect(updated, isNotNull);
        // photo_key should remain unchanged
        expect(updated!.photoKey, 'fish/fish-1/existing.webp');
        // quantity should be updated
        expect(updated.quantity, 3);
      },
    );

    test('UPDATE: synced flag set to true after server update', () async {
      final oldTime = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 12, 0);

      final fish = createExistingFish(id: 'fish-1', serverUpdatedAt: oldTime);
      fish.synced = false;
      await fishDs.saveFish(fish);

      await fishDs.applyServerUpdate({
        'id': 'fish-1',
        'quantity': 2,
        'updated_at': newTime.toIso8601String(),
      });

      final updated = fishDs.getFishById('fish-1');
      expect(updated, isNotNull);
      expect(updated!.synced, true);
    });

    test('UPDATE: skipped when server version is not newer', () async {
      final serverTime = DateTime(2025, 1, 15, 12, 0);

      await fishDs.saveFish(
        createExistingFish(
          id: 'fish-1',
          notes: 'Local notes',
          serverUpdatedAt: serverTime,
        ),
      );

      // Server sends older or equal timestamp
      await fishDs.applyServerUpdate({
        'id': 'fish-1',
        'notes': 'Should be ignored',
        'updated_at': serverTime.toIso8601String(),
      });

      final updated = fishDs.getFishById('fish-1');
      expect(updated, isNotNull);
      expect(updated!.notes, 'Local notes');
    });

    test('CREATE: new fish created from server data', () async {
      await fishDs.applyServerUpdate({
        'id': 'fish-new',
        'aquarium_id': 'aquarium-server',
        'species_id': 'species-clownfish',
        'custom_name': 'Nemo',
        'quantity': 2,
        'notes': 'Server created fish',
        'photo_key': 'fish/fish-new/photo.webp',
        'created_at': '2025-01-15T10:00:00.000',
        'updated_at': '2025-01-15T12:00:00.000',
      });

      final created = fishDs.getFishById('fish-new');
      expect(created, isNotNull);
      expect(created!.aquariumId, 'aquarium-server');
      expect(created.speciesId, 'species-clownfish');
      expect(created.name, 'Nemo');
      expect(created.quantity, 2);
      expect(created.notes, 'Server created fish');
      expect(created.photoKey, 'fish/fish-new/photo.webp');
      expect(created.synced, true);
    });
  });

  group('AquariumLocalDataSource.applyServerUpdate', () {
    late AquariumLocalDataSource aquariumDs;

    setUp(() {
      aquariumDs = AquariumLocalDataSource();
    });

    AquariumModel createExistingAquarium({
      String id = 'aquarium-1',
      String userId = 'user-1',
      String name = 'Test Aquarium',
      double? capacity = 50.0,
      WaterType waterType = WaterType.freshwater,
      String? photoKey,
      DateTime? serverUpdatedAt,
    }) {
      return AquariumModel(
        id: id,
        userId: userId,
        name: name,
        capacity: capacity,
        waterType: waterType,
        photoKey: photoKey,
        createdAt: DateTime(2025, 1, 15),
        synced: true,
        serverUpdatedAt: serverUpdatedAt,
        updatedAt: serverUpdatedAt,
      );
    }

    test('UPDATE: water_type parsed correctly (freshwater)', () async {
      final oldTime = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 12, 0);

      await aquariumDs.saveAquarium(
        createExistingAquarium(
          id: 'aquarium-1',
          waterType: WaterType.saltwater,
          serverUpdatedAt: oldTime,
        ),
      );

      await aquariumDs.applyServerUpdate({
        'id': 'aquarium-1',
        'water_type': 'freshwater',
        'updated_at': newTime.toIso8601String(),
      });

      final updated = aquariumDs.getAquariumById('aquarium-1');
      expect(updated, isNotNull);
      expect(updated!.waterType, WaterType.freshwater);
    });

    test('UPDATE: water_type parsed correctly (saltwater)', () async {
      final oldTime = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 12, 0);

      await aquariumDs.saveAquarium(
        createExistingAquarium(
          id: 'aquarium-1',
          waterType: WaterType.freshwater,
          serverUpdatedAt: oldTime,
        ),
      );

      await aquariumDs.applyServerUpdate({
        'id': 'aquarium-1',
        'water_type': 'saltwater',
        'updated_at': newTime.toIso8601String(),
      });

      final updated = aquariumDs.getAquariumById('aquarium-1');
      expect(updated, isNotNull);
      expect(updated!.waterType, WaterType.saltwater);
    });

    test('UPDATE: water_type parsed correctly (brackish)', () async {
      final oldTime = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 12, 0);

      await aquariumDs.saveAquarium(
        createExistingAquarium(
          id: 'aquarium-1',
          waterType: WaterType.freshwater,
          serverUpdatedAt: oldTime,
        ),
      );

      await aquariumDs.applyServerUpdate({
        'id': 'aquarium-1',
        'water_type': 'brackish',
        'updated_at': newTime.toIso8601String(),
      });

      final updated = aquariumDs.getAquariumById('aquarium-1');
      expect(updated, isNotNull);
      expect(updated!.waterType, WaterType.brackish);
    });

    test('UPDATE: invalid water_type falls back to freshwater', () async {
      final oldTime = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 12, 0);

      await aquariumDs.saveAquarium(
        createExistingAquarium(
          id: 'aquarium-1',
          waterType: WaterType.saltwater,
          serverUpdatedAt: oldTime,
        ),
      );

      await aquariumDs.applyServerUpdate({
        'id': 'aquarium-1',
        'water_type': 'unknown_water_type',
        'updated_at': newTime.toIso8601String(),
      });

      final updated = aquariumDs.getAquariumById('aquarium-1');
      expect(updated, isNotNull);
      expect(updated!.waterType, WaterType.freshwater);
    });

    test('UPDATE: capacity applied as double', () async {
      final oldTime = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 12, 0);

      await aquariumDs.saveAquarium(
        createExistingAquarium(
          id: 'aquarium-1',
          capacity: 50.0,
          serverUpdatedAt: oldTime,
        ),
      );

      await aquariumDs.applyServerUpdate({
        'id': 'aquarium-1',
        'capacity': 120.5,
        'updated_at': newTime.toIso8601String(),
      });

      final updated = aquariumDs.getAquariumById('aquarium-1');
      expect(updated, isNotNull);
      expect(updated!.capacity, 120.5);
    });

    test('UPDATE: capacity from int is converted to double', () async {
      final oldTime = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 12, 0);

      await aquariumDs.saveAquarium(
        createExistingAquarium(
          id: 'aquarium-1',
          capacity: 50.0,
          serverUpdatedAt: oldTime,
        ),
      );

      await aquariumDs.applyServerUpdate({
        'id': 'aquarium-1',
        'capacity': 100,
        'updated_at': newTime.toIso8601String(),
      });

      final updated = aquariumDs.getAquariumById('aquarium-1');
      expect(updated, isNotNull);
      expect(updated!.capacity, 100.0);
    });

    test('UPDATE: capacity from string is parsed as double', () async {
      final oldTime = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 12, 0);

      await aquariumDs.saveAquarium(
        createExistingAquarium(
          id: 'aquarium-1',
          capacity: 50.0,
          serverUpdatedAt: oldTime,
        ),
      );

      await aquariumDs.applyServerUpdate({
        'id': 'aquarium-1',
        'capacity': '75.5',
        'updated_at': newTime.toIso8601String(),
      });

      final updated = aquariumDs.getAquariumById('aquarium-1');
      expect(updated, isNotNull);
      expect(updated!.capacity, 75.5);
    });

    test('UPDATE: photo_key applied when containsKey(photo_key)', () async {
      final oldTime = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 12, 0);

      await aquariumDs.saveAquarium(
        createExistingAquarium(
          id: 'aquarium-1',
          photoKey: null,
          serverUpdatedAt: oldTime,
        ),
      );

      await aquariumDs.applyServerUpdate({
        'id': 'aquarium-1',
        'photo_key': 'aquariums/aquarium-1/abc123.webp',
        'updated_at': newTime.toIso8601String(),
      });

      final updated = aquariumDs.getAquariumById('aquarium-1');
      expect(updated, isNotNull);
      expect(updated!.photoKey, 'aquariums/aquarium-1/abc123.webp');
    });

    test('UPDATE: photo_key set to null when server sends null', () async {
      final oldTime = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 12, 0);

      await aquariumDs.saveAquarium(
        createExistingAquarium(
          id: 'aquarium-1',
          photoKey: 'aquariums/aquarium-1/old-photo.webp',
          serverUpdatedAt: oldTime,
        ),
      );

      // Server sends photo_key: null (photo deleted)
      await aquariumDs.applyServerUpdate({
        'id': 'aquarium-1',
        'photo_key': null,
        'updated_at': newTime.toIso8601String(),
      });

      final updated = aquariumDs.getAquariumById('aquarium-1');
      expect(updated, isNotNull);
      expect(updated!.photoKey, isNull);
    });

    test(
      'UPDATE: photo_key NOT changed when key absent from server data',
      () async {
        final oldTime = DateTime(2025, 1, 15, 10, 0);
        final newTime = DateTime(2025, 1, 15, 12, 0);

        await aquariumDs.saveAquarium(
          createExistingAquarium(
            id: 'aquarium-1',
            photoKey: 'aquariums/aquarium-1/existing.webp',
            serverUpdatedAt: oldTime,
          ),
        );

        // Server data does NOT include photo_key at all
        await aquariumDs.applyServerUpdate({
          'id': 'aquarium-1',
          'name': 'Updated Name',
          'updated_at': newTime.toIso8601String(),
        });

        final updated = aquariumDs.getAquariumById('aquarium-1');
        expect(updated, isNotNull);
        // photo_key should remain unchanged
        expect(updated!.photoKey, 'aquariums/aquarium-1/existing.webp');
        // name should be updated
        expect(updated.name, 'Updated Name');
      },
    );

    test('UPDATE: synced flag set to true after server update', () async {
      final oldTime = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 12, 0);

      final aquarium = createExistingAquarium(
        id: 'aquarium-1',
        serverUpdatedAt: oldTime,
      );
      aquarium.synced = false;
      await aquariumDs.saveAquarium(aquarium);

      await aquariumDs.applyServerUpdate({
        'id': 'aquarium-1',
        'name': 'Updated',
        'updated_at': newTime.toIso8601String(),
      });

      final updated = aquariumDs.getAquariumById('aquarium-1');
      expect(updated, isNotNull);
      expect(updated!.synced, true);
    });

    test('UPDATE: skipped when server version is not newer', () async {
      final serverTime = DateTime(2025, 1, 15, 12, 0);

      await aquariumDs.saveAquarium(
        createExistingAquarium(
          id: 'aquarium-1',
          name: 'Local Name',
          serverUpdatedAt: serverTime,
        ),
      );

      // Server sends same timestamp (not newer)
      await aquariumDs.applyServerUpdate({
        'id': 'aquarium-1',
        'name': 'Should be ignored',
        'updated_at': serverTime.toIso8601String(),
      });

      final updated = aquariumDs.getAquariumById('aquarium-1');
      expect(updated, isNotNull);
      expect(updated!.name, 'Local Name');
    });

    test('CREATE: new aquarium created from server data', () async {
      await aquariumDs.applyServerUpdate({
        'id': 'aquarium-new',
        'owner_id': 'user-server',
        'name': 'Server Aquarium',
        'water_type': 'saltwater',
        'capacity': 200.0,
        'photo_key': 'aquariums/aquarium-new/photo.webp',
        'created_at': '2025-01-15T10:00:00.000',
        'updated_at': '2025-01-15T12:00:00.000',
      });

      final created = aquariumDs.getAquariumById('aquarium-new');
      expect(created, isNotNull);
      expect(created!.userId, 'user-server');
      expect(created.name, 'Server Aquarium');
      expect(created.waterType, WaterType.saltwater);
      expect(created.capacity, 200.0);
      expect(created.photoKey, 'aquariums/aquarium-new/photo.webp');
      expect(created.synced, true);
    });
  });

  group('ScheduleLocalDataSource.applyServerUpdate', () {
    late ScheduleLocalDataSource scheduleDs;

    setUp(() {
      scheduleDs = ScheduleLocalDataSource();
    });

    test('UPDATE: aquarium_id updated from server data', () async {
      final now = DateTime.now();
      final oldTime = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 12, 0);

      // ScheduleModel.fromJson is used in applyServerUpdate, so we set up
      // an existing schedule first
      final existingSchedule = ScheduleModel.fromJson({
        'id': 'schedule-1',
        'fish_id': 'fish-1',
        'aquarium_id': 'aquarium-old',
        'time': '09:00',
        'interval_days': 1,
        'anchor_date': now.toIso8601String(),
        'food_type': 'flakes',
        'active': true,
        'created_at': now.toIso8601String(),
        'updated_at': oldTime.toIso8601String(),
        'created_by_user_id': 'user-1',
      });
      existingSchedule.serverUpdatedAt = oldTime;
      await scheduleDs.save(existingSchedule);

      // Server update moves schedule to a new aquarium
      await scheduleDs.applyServerUpdate({
        'id': 'schedule-1',
        'fish_id': 'fish-1',
        'aquarium_id': 'aquarium-new',
        'time': '09:00',
        'interval_days': 1,
        'anchor_date': now.toIso8601String(),
        'food_type': 'flakes',
        'active': true,
        'created_at': now.toIso8601String(),
        'updated_at': newTime.toIso8601String(),
        'created_by_user_id': 'user-1',
      });

      final updated = scheduleDs.getById('schedule-1');
      expect(updated, isNotNull);
      expect(updated!.aquariumId, 'aquarium-new');
    });

    test('UPDATE: skipped when server version is not newer', () async {
      final now = DateTime.now();
      final serverTime = DateTime(2025, 1, 15, 12, 0);

      final existingSchedule = ScheduleModel.fromJson({
        'id': 'schedule-1',
        'fish_id': 'fish-1',
        'aquarium_id': 'aquarium-1',
        'time': '09:00',
        'interval_days': 1,
        'anchor_date': now.toIso8601String(),
        'food_type': 'flakes',
        'active': true,
        'created_at': now.toIso8601String(),
        'updated_at': serverTime.toIso8601String(),
        'created_by_user_id': 'user-1',
      });
      existingSchedule.serverUpdatedAt = serverTime;
      await scheduleDs.save(existingSchedule);

      // Server sends same timestamp (not newer)
      await scheduleDs.applyServerUpdate({
        'id': 'schedule-1',
        'fish_id': 'fish-1',
        'aquarium_id': 'aquarium-updated',
        'time': '15:00',
        'interval_days': 2,
        'anchor_date': now.toIso8601String(),
        'food_type': 'pellets',
        'active': false,
        'created_at': now.toIso8601String(),
        'updated_at': serverTime.toIso8601String(),
        'created_by_user_id': 'user-1',
      });

      final existing = scheduleDs.getById('schedule-1');
      expect(existing, isNotNull);
      // Should remain unchanged
      expect(existing!.aquariumId, 'aquarium-1');
      expect(existing.time, '09:00');
    });

    test('CREATE: new schedule created from server data', () async {
      final now = DateTime.now();
      final serverTime = DateTime(2025, 1, 15, 12, 0);

      await scheduleDs.applyServerUpdate({
        'id': 'schedule-new',
        'fish_id': 'fish-server',
        'aquarium_id': 'aquarium-server',
        'time': '14:00',
        'interval_days': 3,
        'anchor_date': now.toIso8601String(),
        'food_type': 'pellets',
        'portion_hint': '3 pellets',
        'active': true,
        'created_at': now.toIso8601String(),
        'updated_at': serverTime.toIso8601String(),
        'created_by_user_id': 'user-server',
      });

      final created = scheduleDs.getById('schedule-new');
      expect(created, isNotNull);
      expect(created!.fishId, 'fish-server');
      expect(created.aquariumId, 'aquarium-server');
      expect(created.time, '14:00');
      expect(created.intervalDays, 3);
      expect(created.foodType, 'pellets');
      expect(created.portionHint, '3 pellets');
      expect(created.active, true);
      expect(created.synced, true);
    });

    test('UPDATE: fish_id updated from server data', () async {
      final now = DateTime.now();
      final oldTime = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 12, 0);

      final existingSchedule = ScheduleModel.fromJson({
        'id': 'schedule-1',
        'fish_id': 'fish-old',
        'aquarium_id': 'aquarium-1',
        'time': '09:00',
        'interval_days': 1,
        'anchor_date': now.toIso8601String(),
        'food_type': 'flakes',
        'active': true,
        'created_at': now.toIso8601String(),
        'updated_at': oldTime.toIso8601String(),
        'created_by_user_id': 'user-1',
      });
      existingSchedule.serverUpdatedAt = oldTime;
      await scheduleDs.save(existingSchedule);

      await scheduleDs.applyServerUpdate({
        'id': 'schedule-1',
        'fish_id': 'fish-new',
        'aquarium_id': 'aquarium-1',
        'time': '09:00',
        'interval_days': 1,
        'anchor_date': now.toIso8601String(),
        'food_type': 'flakes',
        'active': true,
        'created_at': now.toIso8601String(),
        'updated_at': newTime.toIso8601String(),
        'created_by_user_id': 'user-1',
      });

      final updated = scheduleDs.getById('schedule-1');
      expect(updated, isNotNull);
      expect(updated!.fishId, 'fish-new');
    });
  });
}
