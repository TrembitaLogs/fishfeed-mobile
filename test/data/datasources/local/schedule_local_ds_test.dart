import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/data/models/schedule_model.dart';

void main() {
  late Directory tempDir;
  late ScheduleLocalDataSource dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_schedule_ds_test_');
    Hive.init(tempDir.path);
    await HiveBoxes.initForTesting();
    dataSource = ScheduleLocalDataSource();
  });

  tearDown(() async {
    await HiveBoxes.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  ScheduleModel createSchedule({
    String id = 'schedule-1',
    String fishId = 'fish-1',
    String aquariumId = 'aquarium-1',
    String time = '09:00',
    int intervalDays = 1,
    bool active = true,
    bool synced = false,
  }) {
    final now = DateTime.now();
    return ScheduleModel(
      id: id,
      fishId: fishId,
      aquariumId: aquariumId,
      time: time,
      intervalDays: intervalDays,
      anchorDate: now,
      foodType: 'flakes',
      active: active,
      createdAt: now,
      updatedAt: now,
      createdByUserId: 'user-1',
      synced: synced,
    );
  }

  group('ScheduleLocalDataSource - CRUD Operations', () {
    test('save should store schedule', () async {
      final schedule = createSchedule();

      await dataSource.save(schedule);

      final retrieved = dataSource.getById('schedule-1');
      expect(retrieved, isNotNull);
      expect(retrieved?.id, 'schedule-1');
      expect(retrieved?.fishId, 'fish-1');
    });

    test('getById should return null for nonexistent ID', () {
      final result = dataSource.getById('nonexistent');
      expect(result, isNull);
    });

    test('getAll should return all schedules sorted by createdAt', () async {
      final older = createSchedule(id: 'schedule-old');
      await dataSource.save(older);

      // Add a small delay to ensure different createdAt
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final newer = createSchedule(id: 'schedule-new');
      await dataSource.save(newer);

      final all = dataSource.getAll();

      expect(all.length, 2);
      // Newest first
      expect(all[0].id, 'schedule-new');
      expect(all[1].id, 'schedule-old');
    });

    test('update should modify existing schedule', () async {
      final schedule = createSchedule();
      await dataSource.save(schedule);

      final updated = schedule.copyWith(time: '14:00');
      final result = await dataSource.update(updated);

      expect(result, true);
      final retrieved = dataSource.getById('schedule-1');
      expect(retrieved?.time, '14:00');
    });

    test('update should return false for nonexistent schedule', () async {
      final schedule = createSchedule(id: 'nonexistent');
      final result = await dataSource.update(schedule);
      expect(result, false);
    });

    test('delete should remove schedule', () async {
      final schedule = createSchedule();
      await dataSource.save(schedule);

      final result = await dataSource.delete('schedule-1');

      expect(result, true);
      expect(dataSource.getById('schedule-1'), isNull);
    });

    test('delete should return false for nonexistent schedule', () async {
      final result = await dataSource.delete('nonexistent');
      expect(result, false);
    });

    test('clearAll should remove all schedules', () async {
      await dataSource.save(createSchedule(id: 'schedule-1'));
      await dataSource.save(createSchedule(id: 'schedule-2'));

      await dataSource.clearAll();

      expect(dataSource.getAll(), isEmpty);
    });
  });

  group('ScheduleLocalDataSource - Query Operations', () {
    test('getByAquariumId should filter by aquarium', () async {
      await dataSource.save(
        createSchedule(
          id: 'schedule-1',
          aquariumId: 'aquarium-1',
          time: '09:00',
        ),
      );
      await dataSource.save(
        createSchedule(
          id: 'schedule-2',
          aquariumId: 'aquarium-1',
          time: '14:00',
        ),
      );
      await dataSource.save(
        createSchedule(
          id: 'schedule-3',
          aquariumId: 'aquarium-2',
          time: '18:00',
        ),
      );

      final aquarium1Schedules = dataSource.getByAquariumId('aquarium-1');

      expect(aquarium1Schedules.length, 2);
      expect(
        aquarium1Schedules.every((s) => s.aquariumId == 'aquarium-1'),
        true,
      );
    });

    test('getByAquariumId should sort by time', () async {
      await dataSource.save(
        createSchedule(
          id: 'schedule-evening',
          aquariumId: 'aquarium-1',
          time: '18:00',
        ),
      );
      await dataSource.save(
        createSchedule(
          id: 'schedule-morning',
          aquariumId: 'aquarium-1',
          time: '09:00',
        ),
      );

      final schedules = dataSource.getByAquariumId('aquarium-1');

      expect(schedules[0].time, '09:00');
      expect(schedules[1].time, '18:00');
    });

    test('getByAquariumId with activeOnly should filter inactive', () async {
      await dataSource.save(
        createSchedule(
          id: 'schedule-active',
          aquariumId: 'aquarium-1',
          active: true,
        ),
      );
      await dataSource.save(
        createSchedule(
          id: 'schedule-inactive',
          aquariumId: 'aquarium-1',
          active: false,
        ),
      );

      final all = dataSource.getByAquariumId('aquarium-1');
      final activeOnly = dataSource.getByAquariumId(
        'aquarium-1',
        activeOnly: true,
      );

      expect(all.length, 2);
      expect(activeOnly.length, 1);
      expect(activeOnly[0].id, 'schedule-active');
    });

    test('getByFishId should filter by fish', () async {
      await dataSource.save(createSchedule(id: 'schedule-1', fishId: 'fish-1'));
      await dataSource.save(createSchedule(id: 'schedule-2', fishId: 'fish-1'));
      await dataSource.save(createSchedule(id: 'schedule-3', fishId: 'fish-2'));

      final fish1Schedules = dataSource.getByFishId('fish-1');

      expect(fish1Schedules.length, 2);
      expect(fish1Schedules.every((s) => s.fishId == 'fish-1'), true);
    });

    test('getActiveByAquariumId should return only active schedules', () async {
      await dataSource.save(
        createSchedule(
          id: 'schedule-1',
          aquariumId: 'aquarium-1',
          active: true,
        ),
      );
      await dataSource.save(
        createSchedule(
          id: 'schedule-2',
          aquariumId: 'aquarium-1',
          active: false,
        ),
      );

      final active = dataSource.getActiveByAquariumId('aquarium-1');

      expect(active.length, 1);
      expect(active[0].active, true);
    });
  });

  group('ScheduleLocalDataSource - Batch Operations', () {
    test('saveAll should store multiple schedules', () async {
      final schedules = [
        createSchedule(id: 'schedule-1'),
        createSchedule(id: 'schedule-2'),
        createSchedule(id: 'schedule-3'),
      ];

      await dataSource.saveAll(schedules);

      expect(dataSource.getCount(), 3);
      expect(dataSource.getById('schedule-1'), isNotNull);
      expect(dataSource.getById('schedule-2'), isNotNull);
      expect(dataSource.getById('schedule-3'), isNotNull);
    });

    test('deleteByFishId should remove all schedules for fish', () async {
      await dataSource.save(createSchedule(id: 'schedule-1', fishId: 'fish-1'));
      await dataSource.save(createSchedule(id: 'schedule-2', fishId: 'fish-1'));
      await dataSource.save(createSchedule(id: 'schedule-3', fishId: 'fish-2'));

      final deleted = await dataSource.deleteByFishId('fish-1');

      expect(deleted, 2);
      expect(dataSource.getByFishId('fish-1'), isEmpty);
      expect(dataSource.getByFishId('fish-2').length, 1);
    });
  });

  group('ScheduleLocalDataSource - Sync Operations', () {
    test('getUnsynced should return schedules that need sync', () async {
      await dataSource.save(
        createSchedule(id: 'schedule-synced', synced: true),
      );
      await dataSource.save(
        createSchedule(id: 'schedule-unsynced', synced: false),
      );

      final unsynced = dataSource.getUnsynced();

      expect(unsynced.length, 1);
      expect(unsynced[0].id, 'schedule-unsynced');
    });

    test('markAsSynced should update synced status', () async {
      await dataSource.save(createSchedule(id: 'schedule-1', synced: false));

      final serverTime = DateTime.now();
      final result = await dataSource.markAsSynced('schedule-1', serverTime);

      expect(result, true);
      final retrieved = dataSource.getById('schedule-1');
      expect(retrieved?.synced, true);
      expect(retrieved?.serverUpdatedAt, serverTime);
    });

    test('markAsSynced should return false for nonexistent schedule', () async {
      final result = await dataSource.markAsSynced(
        'nonexistent',
        DateTime.now(),
      );
      expect(result, false);
    });

    test('getUnsyncedCount should return correct count', () async {
      await dataSource.save(createSchedule(id: 'schedule-1', synced: false));
      await dataSource.save(createSchedule(id: 'schedule-2', synced: false));
      await dataSource.save(createSchedule(id: 'schedule-3', synced: true));

      expect(dataSource.getUnsyncedCount(), 2);
    });

    test('hasUnsyncedSchedules should return correct boolean', () async {
      expect(dataSource.hasUnsyncedSchedules(), false);

      await dataSource.save(createSchedule(synced: true));
      expect(dataSource.hasUnsyncedSchedules(), false);

      await dataSource.save(createSchedule(id: 'schedule-2', synced: false));
      expect(dataSource.hasUnsyncedSchedules(), true);
    });

    test(
      'applyServerUpdate should create new schedule from server data',
      () async {
        final serverData = {
          'id': 'server-schedule-1',
          'fish_id': 'fish-server',
          'aquarium_id': 'aquarium-server',
          'time': '10:00',
          'interval_days': 2,
          'anchor_date': '2025-01-15T00:00:00.000',
          'food_type': 'pellets',
          'active': true,
          'created_at': '2025-01-15T00:00:00.000',
          'updated_at': '2025-01-15T01:00:00.000',
          'created_by_user_id': 'user-server',
        };

        await dataSource.applyServerUpdate(serverData);

        final schedule = dataSource.getById('server-schedule-1');
        expect(schedule, isNotNull);
        expect(schedule?.fishId, 'fish-server');
        expect(schedule?.time, '10:00');
        expect(schedule?.synced, true);
      },
    );

    test(
      'applyServerUpdate should update existing schedule if server is newer',
      () async {
        final now = DateTime.now();
        final schedule = createSchedule(id: 'schedule-1', synced: true);
        schedule.serverUpdatedAt = now.subtract(const Duration(hours: 1));
        await dataSource.save(schedule);

        final serverData = {
          'id': 'schedule-1',
          'fish_id': 'fish-updated',
          'aquarium_id': 'aquarium-1',
          'time': '15:00',
          'anchor_date': now.toIso8601String(),
          'food_type': 'live',
          'active': true,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'created_by_user_id': 'user-1',
        };

        await dataSource.applyServerUpdate(serverData);

        final updated = dataSource.getById('schedule-1');
        expect(updated?.fishId, 'fish-updated');
        expect(updated?.time, '15:00');
      },
    );
  });

  group('ScheduleLocalDataSource - Utility Methods', () {
    test('getCount should return total count', () async {
      expect(dataSource.getCount(), 0);

      await dataSource.save(createSchedule(id: 'schedule-1'));
      expect(dataSource.getCount(), 1);

      await dataSource.save(createSchedule(id: 'schedule-2'));
      expect(dataSource.getCount(), 2);
    });
  });
}
