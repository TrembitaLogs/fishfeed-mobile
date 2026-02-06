import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/feeding_log_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';

void main() {
  late Directory tempDir;
  late FeedingLogLocalDataSource dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'hive_feeding_log_ds_test_',
    );
    Hive.init(tempDir.path);
    await HiveBoxes.initForTesting();
    dataSource = FeedingLogLocalDataSource();
  });

  tearDown(() async {
    await HiveBoxes.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  FeedingLogModel createLog({
    String id = 'log-1',
    String scheduleId = 'schedule-1',
    String fishId = 'fish-1',
    String aquariumId = 'aquarium-1',
    DateTime? scheduledFor,
    String action = 'fed',
    bool synced = false,
  }) {
    final now = DateTime.now();
    return FeedingLogModel(
      id: id,
      scheduleId: scheduleId,
      fishId: fishId,
      aquariumId: aquariumId,
      scheduledFor: scheduledFor ?? now,
      action: action,
      actedAt: now.toUtc(),
      actedByUserId: 'user-1',
      deviceId: 'device-1',
      createdAt: now,
      synced: synced,
    );
  }

  group('FeedingLogLocalDataSource - CRUD Operations', () {
    test('save should store log', () async {
      final log = createLog();

      await dataSource.save(log);

      final retrieved = dataSource.getById('log-1');
      expect(retrieved, isNotNull);
      expect(retrieved?.id, 'log-1');
      expect(retrieved?.scheduleId, 'schedule-1');
    });

    test('getById should return null for nonexistent ID', () {
      final result = dataSource.getById('nonexistent');
      expect(result, isNull);
    });

    test('getAll should return all logs sorted by scheduledFor', () async {
      final older = createLog(
        id: 'log-old',
        scheduledFor: DateTime(2025, 1, 1, 9, 0),
      );
      final newer = createLog(
        id: 'log-new',
        scheduledFor: DateTime(2025, 1, 2, 9, 0),
      );

      await dataSource.save(older);
      await dataSource.save(newer);

      final all = dataSource.getAll();

      expect(all.length, 2);
      // Newest first
      expect(all[0].id, 'log-new');
      expect(all[1].id, 'log-old');
    });

    test('clearAll should remove all logs', () async {
      await dataSource.save(createLog(id: 'log-1'));
      await dataSource.save(createLog(id: 'log-2'));

      await dataSource.clearAll();

      expect(dataSource.getAll(), isEmpty);
    });
  });

  group('FeedingLogLocalDataSource - Query Operations', () {
    test('getByDateRange should filter by date range', () async {
      await dataSource.save(
        createLog(id: 'log-1', scheduledFor: DateTime(2025, 1, 10, 9, 0)),
      );
      await dataSource.save(
        createLog(id: 'log-2', scheduledFor: DateTime(2025, 1, 15, 9, 0)),
      );
      await dataSource.save(
        createLog(id: 'log-3', scheduledFor: DateTime(2025, 1, 20, 9, 0)),
      );

      final inRange = dataSource.getByDateRange(
        DateTime(2025, 1, 12),
        DateTime(2025, 1, 18),
      );

      expect(inRange.length, 1);
      expect(inRange[0].id, 'log-2');
    });

    test('getByDateRange should include boundary dates', () async {
      await dataSource.save(
        createLog(id: 'log-start', scheduledFor: DateTime(2025, 1, 10, 0, 0)),
      );
      await dataSource.save(
        createLog(id: 'log-end', scheduledFor: DateTime(2025, 1, 15, 23, 59)),
      );

      final inRange = dataSource.getByDateRange(
        DateTime(2025, 1, 10),
        DateTime(2025, 1, 15),
      );

      expect(inRange.length, 2);
    });

    test('getByScheduleId should filter by schedule', () async {
      await dataSource.save(createLog(id: 'log-1', scheduleId: 'schedule-1'));
      await dataSource.save(createLog(id: 'log-2', scheduleId: 'schedule-1'));
      await dataSource.save(createLog(id: 'log-3', scheduleId: 'schedule-2'));

      final schedule1Logs = dataSource.getByScheduleId('schedule-1');

      expect(schedule1Logs.length, 2);
      expect(schedule1Logs.every((l) => l.scheduleId == 'schedule-1'), true);
    });

    test('getByAquariumId should filter by aquarium', () async {
      await dataSource.save(createLog(id: 'log-1', aquariumId: 'aquarium-1'));
      await dataSource.save(createLog(id: 'log-2', aquariumId: 'aquarium-1'));
      await dataSource.save(createLog(id: 'log-3', aquariumId: 'aquarium-2'));

      final aquarium1Logs = dataSource.getByAquariumId('aquarium-1');

      expect(aquarium1Logs.length, 2);
      expect(aquarium1Logs.every((l) => l.aquariumId == 'aquarium-1'), true);
    });

    test(
      'getByAquariumIdAndDateRange should filter by both criteria',
      () async {
        await dataSource.save(
          createLog(
            id: 'log-1',
            aquariumId: 'aquarium-1',
            scheduledFor: DateTime(2025, 1, 15, 9, 0),
          ),
        );
        await dataSource.save(
          createLog(
            id: 'log-2',
            aquariumId: 'aquarium-2',
            scheduledFor: DateTime(2025, 1, 15, 9, 0),
          ),
        );
        await dataSource.save(
          createLog(
            id: 'log-3',
            aquariumId: 'aquarium-1',
            scheduledFor: DateTime(2025, 1, 20, 9, 0),
          ),
        );

        final filtered = dataSource.getByAquariumIdAndDateRange(
          'aquarium-1',
          DateTime(2025, 1, 10),
          DateTime(2025, 1, 17),
        );

        expect(filtered.length, 1);
        expect(filtered[0].id, 'log-1');
      },
    );

    test('hasLogForScheduleAndDate should return correct boolean', () async {
      await dataSource.save(
        createLog(
          id: 'log-1',
          scheduleId: 'schedule-1',
          scheduledFor: DateTime(2025, 1, 15, 9, 0),
        ),
      );

      // Same schedule and date
      expect(
        dataSource.hasLogForScheduleAndDate(
          'schedule-1',
          DateTime(2025, 1, 15),
        ),
        true,
      );

      // Same schedule, different date
      expect(
        dataSource.hasLogForScheduleAndDate(
          'schedule-1',
          DateTime(2025, 1, 16),
        ),
        false,
      );

      // Different schedule, same date
      expect(
        dataSource.hasLogForScheduleAndDate(
          'schedule-2',
          DateTime(2025, 1, 15),
        ),
        false,
      );
    });

    test('getLogForScheduleAndDate should return log if exists', () async {
      final scheduledFor = DateTime(2025, 1, 15, 9, 0);
      await dataSource.save(
        createLog(
          id: 'log-1',
          scheduleId: 'schedule-1',
          scheduledFor: scheduledFor,
        ),
      );

      final log = dataSource.getLogForScheduleAndDate(
        'schedule-1',
        DateTime(2025, 1, 15),
      );

      expect(log, isNotNull);
      expect(log?.id, 'log-1');

      // Should return null for different date
      expect(
        dataSource.getLogForScheduleAndDate(
          'schedule-1',
          DateTime(2025, 1, 16),
        ),
        isNull,
      );
    });
  });

  group('FeedingLogLocalDataSource - Batch Operations', () {
    test('saveAll should store multiple logs', () async {
      final logs = [
        createLog(id: 'log-1'),
        createLog(id: 'log-2'),
        createLog(id: 'log-3'),
      ];

      await dataSource.saveAll(logs);

      expect(dataSource.getCount(), 3);
      expect(dataSource.getById('log-1'), isNotNull);
      expect(dataSource.getById('log-2'), isNotNull);
      expect(dataSource.getById('log-3'), isNotNull);
    });
  });

  group('FeedingLogLocalDataSource - Sync Operations', () {
    test('getUnsynced should return logs that need sync', () async {
      await dataSource.save(createLog(id: 'log-synced', synced: true));
      await dataSource.save(createLog(id: 'log-unsynced', synced: false));

      final unsynced = dataSource.getUnsynced();

      expect(unsynced.length, 1);
      expect(unsynced[0].id, 'log-unsynced');
    });

    test('markAsSynced should update synced status', () async {
      await dataSource.save(createLog(id: 'log-1', synced: false));

      final serverTime = DateTime.now();
      final result = await dataSource.markAsSynced('log-1', serverTime);

      expect(result, true);
      final retrieved = dataSource.getById('log-1');
      expect(retrieved?.synced, true);
      expect(retrieved?.serverUpdatedAt, serverTime);
    });

    test('markAsSynced should return false for nonexistent log', () async {
      final result = await dataSource.markAsSynced(
        'nonexistent',
        DateTime.now(),
      );
      expect(result, false);
    });

    test('getUnsyncedCount should return correct count', () async {
      await dataSource.save(createLog(id: 'log-1', synced: false));
      await dataSource.save(createLog(id: 'log-2', synced: false));
      await dataSource.save(createLog(id: 'log-3', synced: true));

      expect(dataSource.getUnsyncedCount(), 2);
    });

    test('hasUnsyncedLogs should return correct boolean', () async {
      expect(dataSource.hasUnsyncedLogs(), false);

      await dataSource.save(createLog(synced: true));
      expect(dataSource.hasUnsyncedLogs(), false);

      await dataSource.save(createLog(id: 'log-2', synced: false));
      expect(dataSource.hasUnsyncedLogs(), true);
    });

    test('applyServerUpdate should create new log from server data', () async {
      final serverData = {
        'id': 'server-log-1',
        'schedule_id': 'schedule-server',
        'fish_id': 'fish-server',
        'aquarium_id': 'aquarium-server',
        'scheduled_for': '2025-01-15T09:00:00.000',
        'action': 'fed',
        'acted_at': '2025-01-15T09:05:00.000Z',
        'acted_by_user_id': 'user-server',
        'device_id': 'device-server',
        'created_at': '2025-01-15T09:05:00.000',
      };

      await dataSource.applyServerUpdate(serverData);

      final log = dataSource.getById('server-log-1');
      expect(log, isNotNull);
      expect(log?.scheduleId, 'schedule-server');
      expect(log?.action, 'fed');
      expect(log?.synced, true);
    });

    test(
      'applyServerUpdate should not overwrite existing log (immutable)',
      () async {
        final existing = createLog(id: 'log-1', action: 'fed', synced: true);
        await dataSource.save(existing);

        final serverData = {
          'id': 'log-1',
          'schedule_id': 'schedule-updated',
          'fish_id': 'fish-1',
          'aquarium_id': 'aquarium-1',
          'scheduled_for': '2025-01-15T09:00:00.000',
          'action': 'skipped', // Different action
          'acted_at': '2025-01-15T09:05:00.000Z',
          'acted_by_user_id': 'user-1',
          'device_id': 'device-1',
          'created_at': '2025-01-15T09:05:00.000',
        };

        await dataSource.applyServerUpdate(serverData);

        // Should not be overwritten because FeedingLog is immutable
        final log = dataSource.getById('log-1');
        expect(log?.action, 'fed'); // Original action
        expect(log?.scheduleId, 'schedule-1'); // Original scheduleId
      },
    );
  });

  group('FeedingLogLocalDataSource - buildLookupMap', () {
    test('should build correct lookup map', () async {
      final logs = [
        createLog(
          id: 'log-1',
          scheduleId: 'schedule-1',
          scheduledFor: DateTime(2025, 1, 15, 9, 0),
        ),
        createLog(
          id: 'log-2',
          scheduleId: 'schedule-2',
          scheduledFor: DateTime(2025, 1, 15, 14, 0),
        ),
        createLog(
          id: 'log-3',
          scheduleId: 'schedule-1',
          scheduledFor: DateTime(2025, 1, 16, 9, 0),
        ),
      ];

      final lookupMap = dataSource.buildLookupMap(logs);

      expect(lookupMap.length, 3);
      expect(lookupMap['schedule-1|2025-01-15']?.id, 'log-1');
      expect(lookupMap['schedule-2|2025-01-15']?.id, 'log-2');
      expect(lookupMap['schedule-1|2025-01-16']?.id, 'log-3');
    });

    test('should handle empty list', () {
      final lookupMap = dataSource.buildLookupMap([]);
      expect(lookupMap, isEmpty);
    });

    test('should format date with leading zeros', () async {
      final log = createLog(
        id: 'log-1',
        scheduleId: 'schedule-1',
        scheduledFor: DateTime(2025, 1, 5, 9, 0), // Single digit day
      );

      final lookupMap = dataSource.buildLookupMap([log]);

      expect(lookupMap.containsKey('schedule-1|2025-01-05'), true);
    });
  });

  group('FeedingLogLocalDataSource - Delete Operations', () {
    test('delete should remove log by ID and return true', () async {
      await dataSource.save(createLog(id: 'log-1'));
      expect(dataSource.getById('log-1'), isNotNull);

      final result = await dataSource.delete('log-1');

      expect(result, true);
      expect(dataSource.getById('log-1'), isNull);
      expect(dataSource.getCount(), 0);
    });

    test('delete should return false for nonexistent ID', () async {
      final result = await dataSource.delete('nonexistent');
      expect(result, false);
    });

    test('delete should not affect other logs', () async {
      await dataSource.save(createLog(id: 'log-1'));
      await dataSource.save(createLog(id: 'log-2'));

      await dataSource.delete('log-1');

      expect(dataSource.getById('log-1'), isNull);
      expect(dataSource.getById('log-2'), isNotNull);
      expect(dataSource.getCount(), 1);
    });
  });

  group('FeedingLogLocalDataSource - Utility Methods', () {
    test('getCount should return total count', () async {
      expect(dataSource.getCount(), 0);

      await dataSource.save(createLog(id: 'log-1'));
      expect(dataSource.getCount(), 1);

      await dataSource.save(createLog(id: 'log-2'));
      expect(dataSource.getCount(), 2);
    });
  });
}
