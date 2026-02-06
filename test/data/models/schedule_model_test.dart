import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/schedule_model.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'hive_schedule_model_test_',
    );
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await HiveBoxes.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ScheduleModel', () {
    test('should create ScheduleModel with required fields', () {
      final now = DateTime.now();
      final model = ScheduleModel(
        id: 'schedule-123',
        fishId: 'fish-456',
        aquariumId: 'aquarium-789',
        time: '09:00',
        intervalDays: 1,
        anchorDate: now,
        foodType: 'flakes',
        active: true,
        createdAt: now,
        updatedAt: now,
        createdByUserId: 'user-1',
      );

      expect(model.id, 'schedule-123');
      expect(model.fishId, 'fish-456');
      expect(model.aquariumId, 'aquarium-789');
      expect(model.time, '09:00');
      expect(model.intervalDays, 1);
      expect(model.anchorDate, now);
      expect(model.foodType, 'flakes');
      expect(model.portionHint, isNull);
      expect(model.active, true);
      expect(model.synced, false);
    });

    test('should create ScheduleModel with all fields', () {
      final now = DateTime.now();
      final serverTime = now.add(const Duration(seconds: 1));
      final model = ScheduleModel(
        id: 'schedule-full',
        fishId: 'fish-full',
        aquariumId: 'aquarium-full',
        time: '14:30',
        intervalDays: 2,
        anchorDate: now,
        foodType: 'pellets',
        portionHint: '3 pellets',
        active: false,
        createdAt: now,
        updatedAt: now,
        createdByUserId: 'user-2',
        synced: true,
        serverUpdatedAt: serverTime,
      );

      expect(model.portionHint, '3 pellets');
      expect(model.active, false);
      expect(model.synced, true);
      expect(model.serverUpdatedAt, serverTime);
    });

    test('synced should default to false for offline-first', () {
      final now = DateTime.now();
      final model = ScheduleModel(
        id: 'offline-schedule',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: now,
        foodType: 'flakes',
        active: true,
        createdAt: now,
        updatedAt: now,
        createdByUserId: 'user-1',
      );

      expect(model.synced, false);
    });
  });

  group('ScheduleModel - shouldFeedOn', () {
    test('should return true for every day when intervalDays=1', () {
      final anchorDate = DateTime(2025, 1, 1);
      final model = ScheduleModel(
        id: 'schedule-daily',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: anchorDate,
        foodType: 'flakes',
        active: true,
        createdAt: anchorDate,
        updatedAt: anchorDate,
        createdByUserId: 'user-1',
      );

      // Should feed every day from anchor date onwards
      expect(model.shouldFeedOn(DateTime(2025, 1, 1)), true); // Day 0
      expect(model.shouldFeedOn(DateTime(2025, 1, 2)), true); // Day 1
      expect(model.shouldFeedOn(DateTime(2025, 1, 3)), true); // Day 2
      expect(model.shouldFeedOn(DateTime(2025, 1, 7)), true); // Day 6
      expect(model.shouldFeedOn(DateTime(2025, 1, 15)), true); // Day 14
    });

    test('should return true every other day when intervalDays=2', () {
      final anchorDate = DateTime(2025, 1, 1);
      final model = ScheduleModel(
        id: 'schedule-alt-days',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 2,
        anchorDate: anchorDate,
        foodType: 'flakes',
        active: true,
        createdAt: anchorDate,
        updatedAt: anchorDate,
        createdByUserId: 'user-1',
      );

      // Should feed on Jan 1, 3, 5, 7... (every other day)
      expect(model.shouldFeedOn(DateTime(2025, 1, 1)), true); // Day 0
      expect(model.shouldFeedOn(DateTime(2025, 1, 2)), false); // Day 1
      expect(model.shouldFeedOn(DateTime(2025, 1, 3)), true); // Day 2
      expect(model.shouldFeedOn(DateTime(2025, 1, 4)), false); // Day 3
      expect(model.shouldFeedOn(DateTime(2025, 1, 5)), true); // Day 4
      expect(model.shouldFeedOn(DateTime(2025, 1, 6)), false); // Day 5
      expect(model.shouldFeedOn(DateTime(2025, 1, 7)), true); // Day 6
    });

    test('should return true weekly when intervalDays=7', () {
      final anchorDate = DateTime(2025, 1, 1); // Wednesday
      final model = ScheduleModel(
        id: 'schedule-weekly',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 7,
        anchorDate: anchorDate,
        foodType: 'flakes',
        active: true,
        createdAt: anchorDate,
        updatedAt: anchorDate,
        createdByUserId: 'user-1',
      );

      // Should feed on Jan 1, 8, 15, 22, 29...
      expect(model.shouldFeedOn(DateTime(2025, 1, 1)), true); // Day 0
      expect(model.shouldFeedOn(DateTime(2025, 1, 2)), false); // Day 1
      expect(model.shouldFeedOn(DateTime(2025, 1, 7)), false); // Day 6
      expect(model.shouldFeedOn(DateTime(2025, 1, 8)), true); // Day 7
      expect(model.shouldFeedOn(DateTime(2025, 1, 15)), true); // Day 14
      expect(model.shouldFeedOn(DateTime(2025, 1, 22)), true); // Day 21
      expect(model.shouldFeedOn(DateTime(2025, 1, 14)), false); // Day 13
    });

    test('should return false for dates before anchor date', () {
      final anchorDate = DateTime(2025, 1, 15);
      final model = ScheduleModel(
        id: 'schedule-future',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: anchorDate,
        foodType: 'flakes',
        active: true,
        createdAt: anchorDate,
        updatedAt: anchorDate,
        createdByUserId: 'user-1',
      );

      // Should not feed before anchor date
      expect(model.shouldFeedOn(DateTime(2025, 1, 1)), false);
      expect(model.shouldFeedOn(DateTime(2025, 1, 10)), false);
      expect(model.shouldFeedOn(DateTime(2025, 1, 14)), false);
      // But should feed on and after anchor date
      expect(model.shouldFeedOn(DateTime(2025, 1, 15)), true);
      expect(model.shouldFeedOn(DateTime(2025, 1, 16)), true);
    });

    test('should handle edge case with intervalDays=3', () {
      final anchorDate = DateTime(2025, 1, 1);
      final model = ScheduleModel(
        id: 'schedule-3days',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 3,
        anchorDate: anchorDate,
        foodType: 'flakes',
        active: true,
        createdAt: anchorDate,
        updatedAt: anchorDate,
        createdByUserId: 'user-1',
      );

      // Should feed on Jan 1, 4, 7, 10, 13...
      expect(model.shouldFeedOn(DateTime(2025, 1, 1)), true); // Day 0
      expect(model.shouldFeedOn(DateTime(2025, 1, 2)), false); // Day 1
      expect(model.shouldFeedOn(DateTime(2025, 1, 3)), false); // Day 2
      expect(model.shouldFeedOn(DateTime(2025, 1, 4)), true); // Day 3
      expect(model.shouldFeedOn(DateTime(2025, 1, 5)), false); // Day 4
      expect(model.shouldFeedOn(DateTime(2025, 1, 6)), false); // Day 5
      expect(model.shouldFeedOn(DateTime(2025, 1, 7)), true); // Day 6
      expect(model.shouldFeedOn(DateTime(2025, 1, 10)), true); // Day 9
      expect(model.shouldFeedOn(DateTime(2025, 1, 13)), true); // Day 12
    });

    test('should ignore time component when checking dates', () {
      final anchorDate = DateTime(2025, 1, 1, 9, 0);
      final model = ScheduleModel(
        id: 'schedule-time-ignore',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: anchorDate,
        foodType: 'flakes',
        active: true,
        createdAt: anchorDate,
        updatedAt: anchorDate,
        createdByUserId: 'user-1',
      );

      // Same day but different times should all return true
      expect(model.shouldFeedOn(DateTime(2025, 1, 1, 0, 0)), true);
      expect(model.shouldFeedOn(DateTime(2025, 1, 1, 8, 0)), true);
      expect(model.shouldFeedOn(DateTime(2025, 1, 1, 12, 30)), true);
      expect(model.shouldFeedOn(DateTime(2025, 1, 1, 23, 59)), true);
    });
  });

  group('ScheduleModel - timeComponents', () {
    test('should parse time correctly', () {
      final now = DateTime.now();
      final model = ScheduleModel(
        id: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '14:30',
        intervalDays: 1,
        anchorDate: now,
        foodType: 'flakes',
        active: true,
        createdAt: now,
        updatedAt: now,
        createdByUserId: 'user-1',
      );

      final components = model.timeComponents;
      expect(components.hour, 14);
      expect(components.minute, 30);
    });

    test('should parse morning time correctly', () {
      final now = DateTime.now();
      final model = ScheduleModel(
        id: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: now,
        foodType: 'flakes',
        active: true,
        createdAt: now,
        updatedAt: now,
        createdByUserId: 'user-1',
      );

      final components = model.timeComponents;
      expect(components.hour, 9);
      expect(components.minute, 0);
    });

    test('should throw FormatException for invalid time format', () {
      final now = DateTime.now();
      final model = ScheduleModel(
        id: 'schedule-invalid',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: 'invalid',
        intervalDays: 1,
        anchorDate: now,
        foodType: 'flakes',
        active: true,
        createdAt: now,
        updatedAt: now,
        createdByUserId: 'user-1',
      );

      expect(() => model.timeComponents, throwsFormatException);
    });
  });

  group('ScheduleModel - JSON serialization', () {
    test('toJson should produce correct snake_case keys', () {
      final now = DateTime(2025, 1, 15, 10, 30, 0);
      final model = ScheduleModel(
        id: 'schedule-json',
        fishId: 'fish-json',
        aquariumId: 'aquarium-json',
        time: '09:00',
        intervalDays: 2,
        anchorDate: now,
        foodType: 'pellets',
        portionHint: '2 pinches',
        active: true,
        createdAt: now,
        updatedAt: now,
        createdByUserId: 'user-json',
      );

      final json = model.toJson();

      expect(json['id'], 'schedule-json');
      expect(json['fish_id'], 'fish-json');
      expect(json['aquarium_id'], 'aquarium-json');
      expect(json['time'], '09:00');
      expect(json['interval_days'], 2);
      expect(json['anchor_date'], now.toIso8601String());
      expect(json['food_type'], 'pellets');
      expect(json['portion_hint'], '2 pinches');
      expect(json['active'], true);
      expect(json['created_at'], now.toIso8601String());
      expect(json['updated_at'], now.toIso8601String());
      expect(json['created_by_user_id'], 'user-json');
    });

    test('fromJson should parse snake_case keys correctly', () {
      final json = {
        'id': 'schedule-from-json',
        'fish_id': 'fish-from-json',
        'aquarium_id': 'aquarium-from-json',
        'time': '14:00',
        'interval_days': 3,
        'anchor_date': '2025-01-15T10:30:00.000',
        'food_type': 'live',
        'portion_hint': '5 worms',
        'active': false,
        'created_at': '2025-01-15T10:30:00.000',
        'updated_at': '2025-01-15T11:00:00.000',
        'created_by_user_id': 'user-from-json',
      };

      final model = ScheduleModel.fromJson(json);

      expect(model.id, 'schedule-from-json');
      expect(model.fishId, 'fish-from-json');
      expect(model.aquariumId, 'aquarium-from-json');
      expect(model.time, '14:00');
      expect(model.intervalDays, 3);
      expect(model.anchorDate, DateTime.parse('2025-01-15T10:30:00.000'));
      expect(model.foodType, 'live');
      expect(model.portionHint, '5 worms');
      expect(model.active, false);
      expect(model.createdByUserId, 'user-from-json');
      expect(model.synced, true); // fromJson sets synced to true
    });

    test('fromJson should handle missing optional fields', () {
      final json = {
        'id': 'schedule-minimal',
        'fish_id': 'fish-minimal',
        'aquarium_id': 'aquarium-minimal',
        'time': '09:00',
        'anchor_date': '2025-01-15T10:30:00.000',
        'food_type': 'flakes',
        'created_at': '2025-01-15T10:30:00.000',
        'updated_at': '2025-01-15T10:30:00.000',
        'created_by_user_id': 'user-minimal',
      };

      final model = ScheduleModel.fromJson(json);

      expect(model.intervalDays, 1); // Default value
      expect(model.portionHint, isNull);
      expect(model.active, true); // Default value
    });

    test('toJson/fromJson roundtrip should preserve data', () {
      final now = DateTime(2025, 1, 15, 10, 30, 0);
      final original = ScheduleModel(
        id: 'schedule-roundtrip',
        fishId: 'fish-roundtrip',
        aquariumId: 'aquarium-roundtrip',
        time: '18:45',
        intervalDays: 5,
        anchorDate: now,
        foodType: 'frozen',
        portionHint: 'half cube',
        active: true,
        createdAt: now,
        updatedAt: now,
        createdByUserId: 'user-roundtrip',
        synced: true,
      );

      final json = original.toJson();
      final restored = ScheduleModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.fishId, original.fishId);
      expect(restored.aquariumId, original.aquariumId);
      expect(restored.time, original.time);
      expect(restored.intervalDays, original.intervalDays);
      expect(restored.anchorDate, original.anchorDate);
      expect(restored.foodType, original.foodType);
      expect(restored.portionHint, original.portionHint);
      expect(restored.active, original.active);
      expect(restored.createdByUserId, original.createdByUserId);
    });

    test('toSyncJson should include only sync-relevant fields', () {
      final now = DateTime(2025, 1, 15, 10, 30, 0);
      final model = ScheduleModel(
        id: 'schedule-sync',
        fishId: 'fish-sync',
        aquariumId: 'aquarium-sync',
        time: '09:00',
        intervalDays: 1,
        anchorDate: now,
        foodType: 'flakes',
        portionHint: '2 pinches',
        active: true,
        createdAt: now,
        updatedAt: now,
        createdByUserId: 'user-sync',
        synced: false,
        serverUpdatedAt: now,
      );

      final syncJson = model.toSyncJson();

      // Should include core fields
      expect(syncJson['id'], 'schedule-sync');
      expect(syncJson['fish_id'], 'fish-sync');
      expect(syncJson['aquarium_id'], 'aquarium-sync');
      expect(syncJson['time'], '09:00');
      expect(syncJson['interval_days'], 1);
      expect(syncJson['anchor_date'], now.toIso8601String());
      expect(syncJson['food_type'], 'flakes');
      expect(syncJson['portion_hint'], '2 pinches');
      expect(syncJson['active'], true);
      expect(syncJson['created_by_user_id'], 'user-sync');

      // Should NOT include sync metadata
      expect(syncJson.containsKey('created_at'), false);
      expect(syncJson.containsKey('updated_at'), false);
    });
  });

  group('ScheduleModel - sync methods', () {
    test(
      'markAsSynced should set synced to true and update serverUpdatedAt',
      () {
        final now = DateTime.now();
        final model = ScheduleModel(
          id: 'schedule-mark-synced',
          fishId: 'fish-1',
          aquariumId: 'aquarium-1',
          time: '09:00',
          intervalDays: 1,
          anchorDate: now,
          foodType: 'flakes',
          active: true,
          createdAt: now,
          updatedAt: now,
          createdByUserId: 'user-1',
          synced: false,
        );

        expect(model.synced, false);
        expect(model.serverUpdatedAt, isNull);

        final serverTime = DateTime.now().add(const Duration(seconds: 5));
        model.markAsSynced(serverTime);

        expect(model.synced, true);
        expect(model.serverUpdatedAt, serverTime);
      },
    );

    test('markAsModified should set synced to false and update updatedAt', () {
      final now = DateTime.now();
      final serverTime = now.add(const Duration(seconds: 1));
      final model = ScheduleModel(
        id: 'schedule-mark-modified',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: now,
        foodType: 'flakes',
        active: true,
        createdAt: now,
        updatedAt: now,
        createdByUserId: 'user-1',
        synced: true,
        serverUpdatedAt: serverTime,
      );

      expect(model.synced, true);
      final originalUpdatedAt = model.updatedAt;

      // Wait a bit to ensure updatedAt changes
      model.markAsModified();

      expect(model.synced, false);
      expect(model.updatedAt.isAfter(originalUpdatedAt), true);
    });

    test('needsSync should return true when not synced', () {
      final now = DateTime.now();
      final model = ScheduleModel(
        id: 'schedule-needs-sync',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: now,
        foodType: 'flakes',
        active: true,
        createdAt: now,
        updatedAt: now,
        createdByUserId: 'user-1',
        synced: false,
      );

      expect(model.needsSync, true);
    });

    test(
      'needsSync should return true when updatedAt is after serverUpdatedAt',
      () {
        final now = DateTime.now();
        final model = ScheduleModel(
          id: 'schedule-needs-sync-2',
          fishId: 'fish-1',
          aquariumId: 'aquarium-1',
          time: '09:00',
          intervalDays: 1,
          anchorDate: now,
          foodType: 'flakes',
          active: true,
          createdAt: now,
          updatedAt: now.add(const Duration(seconds: 10)),
          createdByUserId: 'user-1',
          synced: true,
          serverUpdatedAt: now,
        );

        expect(model.needsSync, true);
      },
    );

    test(
      'needsSync should return false when synced and serverUpdatedAt >= updatedAt',
      () {
        final now = DateTime.now();
        final model = ScheduleModel(
          id: 'schedule-no-sync',
          fishId: 'fish-1',
          aquariumId: 'aquarium-1',
          time: '09:00',
          intervalDays: 1,
          anchorDate: now,
          foodType: 'flakes',
          active: true,
          createdAt: now,
          updatedAt: now,
          createdByUserId: 'user-1',
          synced: true,
          serverUpdatedAt: now.add(const Duration(seconds: 1)),
        );

        expect(model.needsSync, false);
      },
    );
  });

  group('ScheduleModel - copyWith', () {
    test('copyWith should create a copy with modified fields', () {
      final now = DateTime.now();
      final original = ScheduleModel(
        id: 'schedule-copy',
        fishId: 'fish-copy',
        aquariumId: 'aquarium-copy',
        time: '09:00',
        intervalDays: 1,
        anchorDate: now,
        foodType: 'flakes',
        active: true,
        createdAt: now,
        updatedAt: now,
        createdByUserId: 'user-copy',
      );

      final copy = original.copyWith(
        time: '14:00',
        intervalDays: 2,
        active: false,
      );

      expect(copy.id, original.id);
      expect(copy.fishId, original.fishId);
      expect(copy.time, '14:00');
      expect(copy.intervalDays, 2);
      expect(copy.active, false);
      expect(copy.foodType, original.foodType);
    });
  });

  group('ScheduleModel - Hive persistence', () {
    setUp(() async {
      await HiveBoxes.initForTesting();
    });

    test('should save and retrieve ScheduleModel from Hive', () async {
      final now = DateTime.now();
      final model = ScheduleModel(
        id: 'persist-schedule',
        fishId: 'persist-fish',
        aquariumId: 'persist-aquarium',
        time: '09:00',
        intervalDays: 1,
        anchorDate: now,
        foodType: 'flakes',
        portionHint: '2 pinches',
        active: true,
        createdAt: now,
        updatedAt: now,
        createdByUserId: 'user-persist',
        synced: false,
      );

      await HiveBoxes.schedules.put(model.id, model);
      final retrieved = HiveBoxes.schedules.get(model.id) as ScheduleModel;

      expect(retrieved.id, model.id);
      expect(retrieved.fishId, model.fishId);
      expect(retrieved.aquariumId, model.aquariumId);
      expect(retrieved.time, model.time);
      expect(retrieved.intervalDays, model.intervalDays);
      expect(retrieved.foodType, model.foodType);
      expect(retrieved.portionHint, model.portionHint);
      expect(retrieved.active, model.active);
      expect(retrieved.synced, model.synced);
    });

    test('should retrieve active schedules for aquarium', () async {
      final now = DateTime.now();
      final schedule1 = ScheduleModel(
        id: 'active-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: now,
        foodType: 'flakes',
        active: true,
        createdAt: now,
        updatedAt: now,
        createdByUserId: 'user-1',
      );

      final schedule2 = ScheduleModel(
        id: 'inactive-1',
        fishId: 'fish-2',
        aquariumId: 'aquarium-1',
        time: '14:00',
        intervalDays: 1,
        anchorDate: now,
        foodType: 'pellets',
        active: false,
        createdAt: now,
        updatedAt: now,
        createdByUserId: 'user-1',
      );

      final schedule3 = ScheduleModel(
        id: 'active-2',
        fishId: 'fish-3',
        aquariumId: 'aquarium-1',
        time: '18:00',
        intervalDays: 2,
        anchorDate: now,
        foodType: 'frozen',
        active: true,
        createdAt: now,
        updatedAt: now,
        createdByUserId: 'user-1',
      );

      await HiveBoxes.schedules.put(schedule1.id, schedule1);
      await HiveBoxes.schedules.put(schedule2.id, schedule2);
      await HiveBoxes.schedules.put(schedule3.id, schedule3);

      final allSchedules = HiveBoxes.schedules.values
          .cast<ScheduleModel>()
          .toList();
      final activeSchedules = allSchedules
          .where((s) => s.aquariumId == 'aquarium-1' && s.active)
          .toList();

      expect(allSchedules.length, 3);
      expect(activeSchedules.length, 2);
      expect(activeSchedules.any((s) => s.id == 'active-1'), true);
      expect(activeSchedules.any((s) => s.id == 'active-2'), true);
    });
  });

  group('ScheduleModel - TypeAdapter', () {
    test('should have correct typeId', () {
      final adapter = ScheduleModelAdapter();
      expect(adapter.typeId, 24);
    });
  });
}
