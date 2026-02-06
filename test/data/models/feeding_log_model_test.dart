import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'hive_feeding_log_model_test_',
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

  group('FeedingLogModel', () {
    test('should create FeedingLogModel with required fields', () {
      final scheduledFor = DateTime(2025, 1, 15, 9, 0);
      final actedAt = DateTime.now().toUtc();
      final createdAt = DateTime.now();

      final model = FeedingLogModel(
        id: 'log-123',
        scheduleId: 'schedule-456',
        fishId: 'fish-789',
        aquariumId: 'aquarium-abc',
        scheduledFor: scheduledFor,
        action: 'fed',
        actedAt: actedAt,
        actedByUserId: 'user-1',
        deviceId: 'device-1',
        createdAt: createdAt,
      );

      expect(model.id, 'log-123');
      expect(model.scheduleId, 'schedule-456');
      expect(model.fishId, 'fish-789');
      expect(model.aquariumId, 'aquarium-abc');
      expect(model.scheduledFor, scheduledFor);
      expect(model.action, 'fed');
      expect(model.actedAt, actedAt);
      expect(model.actedByUserId, 'user-1');
      expect(model.actedByUserName, isNull);
      expect(model.deviceId, 'device-1');
      expect(model.notes, isNull);
      expect(model.createdAt, createdAt);
      expect(model.synced, false);
      expect(model.serverUpdatedAt, isNull);
    });

    test('should create FeedingLogModel with all fields', () {
      final scheduledFor = DateTime(2025, 1, 15, 9, 0);
      final actedAt = DateTime.now().toUtc();
      final createdAt = DateTime.now();
      final serverTime = createdAt.add(const Duration(seconds: 1));

      final model = FeedingLogModel(
        id: 'log-full',
        scheduleId: 'schedule-full',
        fishId: 'fish-full',
        aquariumId: 'aquarium-full',
        scheduledFor: scheduledFor,
        action: 'skipped',
        actedAt: actedAt,
        actedByUserId: 'user-full',
        actedByUserName: 'Mom',
        deviceId: 'device-full',
        notes: 'Fish looked full',
        createdAt: createdAt,
        synced: true,
        serverUpdatedAt: serverTime,
      );

      expect(model.actedByUserName, 'Mom');
      expect(model.notes, 'Fish looked full');
      expect(model.synced, true);
      expect(model.serverUpdatedAt, serverTime);
    });

    test('synced should default to false for offline-first', () {
      final model = FeedingLogModel(
        id: 'offline-log',
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: DateTime.now(),
        action: 'fed',
        actedAt: DateTime.now().toUtc(),
        actedByUserId: 'user-1',
        deviceId: 'device-1',
        createdAt: DateTime.now(),
      );

      expect(model.synced, false);
    });
  });

  group('FeedingLogModel - action helpers', () {
    test('isFed should return true when action is "fed"', () {
      final model = FeedingLogModel(
        id: 'log-fed',
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: DateTime.now(),
        action: 'fed',
        actedAt: DateTime.now().toUtc(),
        actedByUserId: 'user-1',
        deviceId: 'device-1',
        createdAt: DateTime.now(),
      );

      expect(model.isFed, true);
      expect(model.isSkipped, false);
    });

    test('isSkipped should return true when action is "skipped"', () {
      final model = FeedingLogModel(
        id: 'log-skipped',
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: DateTime.now(),
        action: 'skipped',
        actedAt: DateTime.now().toUtc(),
        actedByUserId: 'user-1',
        deviceId: 'device-1',
        createdAt: DateTime.now(),
      );

      expect(model.isFed, false);
      expect(model.isSkipped, true);
    });
  });

  group('FeedingLogModel - JSON serialization', () {
    test('toJson should produce correct snake_case keys', () {
      final scheduledFor = DateTime(2025, 1, 15, 9, 0);
      final actedAt = DateTime(2025, 1, 15, 9, 5).toUtc();
      final createdAt = DateTime(2025, 1, 15, 9, 5);

      final model = FeedingLogModel(
        id: 'log-json',
        scheduleId: 'schedule-json',
        fishId: 'fish-json',
        aquariumId: 'aquarium-json',
        scheduledFor: scheduledFor,
        action: 'fed',
        actedAt: actedAt,
        actedByUserId: 'user-json',
        actedByUserName: 'Dad',
        deviceId: 'device-json',
        notes: 'Morning feeding',
        createdAt: createdAt,
      );

      final json = model.toJson();

      expect(json['id'], 'log-json');
      expect(json['schedule_id'], 'schedule-json');
      expect(json['fish_id'], 'fish-json');
      expect(json['aquarium_id'], 'aquarium-json');
      expect(json['scheduled_for'], scheduledFor.toIso8601String());
      expect(json['action'], 'fed');
      expect(json['acted_at'], actedAt.toUtc().toIso8601String());
      expect(json['acted_by_user_id'], 'user-json');
      expect(json['acted_by_user_name'], 'Dad');
      expect(json['device_id'], 'device-json');
      expect(json['notes'], 'Morning feeding');
      expect(json['created_at'], createdAt.toIso8601String());
    });

    test('fromJson should parse snake_case keys correctly', () {
      final json = {
        'id': 'log-from-json',
        'schedule_id': 'schedule-from-json',
        'fish_id': 'fish-from-json',
        'aquarium_id': 'aquarium-from-json',
        'scheduled_for': '2025-01-15T09:00:00.000',
        'action': 'skipped',
        'acted_at': '2025-01-15T09:05:00.000Z',
        'acted_by_user_id': 'user-from-json',
        'acted_by_user_name': 'Mom',
        'device_id': 'device-from-json',
        'notes': 'Too early',
        'created_at': '2025-01-15T09:05:00.000',
        'updated_at': '2025-01-15T09:10:00.000',
      };

      final model = FeedingLogModel.fromJson(json);

      expect(model.id, 'log-from-json');
      expect(model.scheduleId, 'schedule-from-json');
      expect(model.fishId, 'fish-from-json');
      expect(model.aquariumId, 'aquarium-from-json');
      expect(model.scheduledFor, DateTime.parse('2025-01-15T09:00:00.000'));
      expect(model.action, 'skipped');
      expect(model.actedAt, DateTime.parse('2025-01-15T09:05:00.000Z'));
      expect(model.actedByUserId, 'user-from-json');
      expect(model.actedByUserName, 'Mom');
      expect(model.deviceId, 'device-from-json');
      expect(model.notes, 'Too early');
      expect(model.synced, true); // fromJson sets synced to true
      expect(model.serverUpdatedAt, DateTime.parse('2025-01-15T09:10:00.000'));
    });

    test('fromJson should handle missing optional fields', () {
      final json = {
        'id': 'log-minimal',
        'schedule_id': 'schedule-minimal',
        'fish_id': 'fish-minimal',
        'aquarium_id': 'aquarium-minimal',
        'scheduled_for': '2025-01-15T09:00:00.000',
        'action': 'fed',
        'acted_at': '2025-01-15T09:05:00.000Z',
        'acted_by_user_id': 'user-minimal',
        'device_id': 'device-minimal',
        'created_at': '2025-01-15T09:05:00.000',
      };

      final model = FeedingLogModel.fromJson(json);

      expect(model.actedByUserName, isNull);
      expect(model.notes, isNull);
      expect(model.serverUpdatedAt, DateTime.parse('2025-01-15T09:05:00.000'));
    });

    test('toJson/fromJson roundtrip should preserve data', () {
      final scheduledFor = DateTime(2025, 1, 15, 9, 0);
      final actedAt = DateTime(2025, 1, 15, 9, 5).toUtc();
      final createdAt = DateTime(2025, 1, 15, 9, 5);

      final original = FeedingLogModel(
        id: 'log-roundtrip',
        scheduleId: 'schedule-roundtrip',
        fishId: 'fish-roundtrip',
        aquariumId: 'aquarium-roundtrip',
        scheduledFor: scheduledFor,
        action: 'fed',
        actedAt: actedAt,
        actedByUserId: 'user-roundtrip',
        actedByUserName: 'Sister',
        deviceId: 'device-roundtrip',
        notes: 'Evening feeding',
        createdAt: createdAt,
        synced: true,
      );

      final json = original.toJson();
      // Add updated_at for fromJson
      json['updated_at'] = createdAt.toIso8601String();
      final restored = FeedingLogModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.scheduleId, original.scheduleId);
      expect(restored.fishId, original.fishId);
      expect(restored.aquariumId, original.aquariumId);
      expect(restored.scheduledFor, original.scheduledFor);
      expect(restored.action, original.action);
      expect(restored.actedAt, original.actedAt);
      expect(restored.actedByUserId, original.actedByUserId);
      expect(restored.actedByUserName, original.actedByUserName);
      expect(restored.deviceId, original.deviceId);
      expect(restored.notes, original.notes);
    });

    test('toSyncJson should include only sync-relevant fields', () {
      final scheduledFor = DateTime(2025, 1, 15, 9, 0);
      final actedAt = DateTime(2025, 1, 15, 9, 5).toUtc();
      final createdAt = DateTime(2025, 1, 15, 9, 5);
      final serverTime = createdAt.add(const Duration(seconds: 1));

      final model = FeedingLogModel(
        id: 'log-sync',
        scheduleId: 'schedule-sync',
        fishId: 'fish-sync',
        aquariumId: 'aquarium-sync',
        scheduledFor: scheduledFor,
        action: 'fed',
        actedAt: actedAt,
        actedByUserId: 'user-sync',
        actedByUserName: 'Dad',
        deviceId: 'device-sync',
        notes: 'Fed well',
        createdAt: createdAt,
        synced: false,
        serverUpdatedAt: serverTime,
      );

      final syncJson = model.toSyncJson();

      // Should include core fields
      expect(syncJson['id'], 'log-sync');
      expect(syncJson['schedule_id'], 'schedule-sync');
      expect(syncJson['fish_id'], 'fish-sync');
      expect(syncJson['aquarium_id'], 'aquarium-sync');
      expect(syncJson['scheduled_for'], scheduledFor.toIso8601String());
      expect(syncJson['action'], 'fed');
      expect(syncJson['acted_at'], actedAt.toUtc().toIso8601String());
      expect(syncJson['device_id'], 'device-sync');
      expect(syncJson['notes'], 'Fed well');

      // Should NOT include user display info (server resolves this)
      expect(syncJson.containsKey('acted_by_user_id'), false);
      expect(syncJson.containsKey('acted_by_user_name'), false);
      expect(syncJson.containsKey('created_at'), false);
    });
  });

  group('FeedingLogModel - scheduledFor and actedAt handling', () {
    test('scheduledFor should preserve local time', () {
      // Local time: 9:00 AM on Jan 15
      final scheduledFor = DateTime(2025, 1, 15, 9, 0);

      final model = FeedingLogModel(
        id: 'log-local-time',
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: scheduledFor,
        action: 'fed',
        actedAt: DateTime.now().toUtc(),
        actedByUserId: 'user-1',
        deviceId: 'device-1',
        createdAt: DateTime.now(),
      );

      expect(model.scheduledFor.hour, 9);
      expect(model.scheduledFor.minute, 0);
      expect(model.scheduledFor.day, 15);
    });

    test('actedAt should be stored as UTC', () {
      final actedAtUtc = DateTime.utc(2025, 1, 15, 14, 5);

      final model = FeedingLogModel(
        id: 'log-utc-time',
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: DateTime.now(),
        action: 'fed',
        actedAt: actedAtUtc,
        actedByUserId: 'user-1',
        deviceId: 'device-1',
        createdAt: DateTime.now(),
      );

      expect(model.actedAt.isUtc, true);
      expect(model.actedAt.hour, 14);
      expect(model.actedAt.minute, 5);
    });

    test('toJson should convert actedAt to UTC string', () {
      final actedAt = DateTime(2025, 1, 15, 9, 5);

      final model = FeedingLogModel(
        id: 'log-json-utc',
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: DateTime.now(),
        action: 'fed',
        actedAt: actedAt,
        actedByUserId: 'user-1',
        deviceId: 'device-1',
        createdAt: DateTime.now(),
      );

      final json = model.toJson();
      expect(json['acted_at'], actedAt.toUtc().toIso8601String());
    });
  });

  group('FeedingLogModel - copyWith', () {
    test('copyWith should create a copy with modified fields', () {
      final scheduledFor = DateTime(2025, 1, 15, 9, 0);
      final actedAt = DateTime.now().toUtc();
      final createdAt = DateTime.now();

      final original = FeedingLogModel(
        id: 'log-copy',
        scheduleId: 'schedule-copy',
        fishId: 'fish-copy',
        aquariumId: 'aquarium-copy',
        scheduledFor: scheduledFor,
        action: 'fed',
        actedAt: actedAt,
        actedByUserId: 'user-copy',
        deviceId: 'device-copy',
        createdAt: createdAt,
        synced: false,
      );

      final copy = original.copyWith(
        action: 'skipped',
        notes: 'Changed my mind',
        synced: true,
      );

      expect(copy.id, original.id);
      expect(copy.scheduleId, original.scheduleId);
      expect(copy.action, 'skipped');
      expect(copy.notes, 'Changed my mind');
      expect(copy.synced, true);
      expect(copy.fishId, original.fishId);
    });
  });

  group('FeedingLogModel - Hive persistence', () {
    setUp(() async {
      await HiveBoxes.initForTesting();
    });

    test('should save and retrieve FeedingLogModel from Hive', () async {
      final scheduledFor = DateTime(2025, 1, 15, 9, 0);
      final actedAt = DateTime.now().toUtc();
      final createdAt = DateTime.now();

      final model = FeedingLogModel(
        id: 'persist-log',
        scheduleId: 'persist-schedule',
        fishId: 'persist-fish',
        aquariumId: 'persist-aquarium',
        scheduledFor: scheduledFor,
        action: 'fed',
        actedAt: actedAt,
        actedByUserId: 'user-persist',
        actedByUserName: 'Tester',
        deviceId: 'device-persist',
        notes: 'Test note',
        createdAt: createdAt,
        synced: false,
      );

      await HiveBoxes.feedingLogs.put(model.id, model);
      final retrieved = HiveBoxes.feedingLogs.get(model.id) as FeedingLogModel;

      expect(retrieved.id, model.id);
      expect(retrieved.scheduleId, model.scheduleId);
      expect(retrieved.fishId, model.fishId);
      expect(retrieved.aquariumId, model.aquariumId);
      expect(retrieved.action, model.action);
      expect(retrieved.actedByUserId, model.actedByUserId);
      expect(retrieved.actedByUserName, model.actedByUserName);
      expect(retrieved.deviceId, model.deviceId);
      expect(retrieved.notes, model.notes);
      expect(retrieved.synced, model.synced);
    });

    test('should retrieve logs for specific schedule and date range', () async {
      final scheduledFor1 = DateTime(2025, 1, 15, 9, 0);
      final scheduledFor2 = DateTime(2025, 1, 16, 9, 0);
      final scheduledFor3 = DateTime(2025, 1, 17, 9, 0);
      final actedAt = DateTime.now().toUtc();
      final createdAt = DateTime.now();

      final log1 = FeedingLogModel(
        id: 'log-1',
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: scheduledFor1,
        action: 'fed',
        actedAt: actedAt,
        actedByUserId: 'user-1',
        deviceId: 'device-1',
        createdAt: createdAt,
      );

      final log2 = FeedingLogModel(
        id: 'log-2',
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: scheduledFor2,
        action: 'skipped',
        actedAt: actedAt,
        actedByUserId: 'user-1',
        deviceId: 'device-1',
        createdAt: createdAt,
      );

      final log3 = FeedingLogModel(
        id: 'log-3',
        scheduleId: 'schedule-2', // Different schedule
        fishId: 'fish-2',
        aquariumId: 'aquarium-1',
        scheduledFor: scheduledFor3,
        action: 'fed',
        actedAt: actedAt,
        actedByUserId: 'user-1',
        deviceId: 'device-1',
        createdAt: createdAt,
      );

      await HiveBoxes.feedingLogs.put(log1.id, log1);
      await HiveBoxes.feedingLogs.put(log2.id, log2);
      await HiveBoxes.feedingLogs.put(log3.id, log3);

      final allLogs = HiveBoxes.feedingLogs.values
          .cast<FeedingLogModel>()
          .toList();
      final schedule1Logs = allLogs
          .where((l) => l.scheduleId == 'schedule-1')
          .toList();

      expect(allLogs.length, 3);
      expect(schedule1Logs.length, 2);
      expect(schedule1Logs.any((l) => l.id == 'log-1'), true);
      expect(schedule1Logs.any((l) => l.id == 'log-2'), true);
    });

    test('should retrieve unsynced logs', () async {
      final scheduledFor = DateTime(2025, 1, 15, 9, 0);
      final actedAt = DateTime.now().toUtc();
      final createdAt = DateTime.now();

      final syncedLog = FeedingLogModel(
        id: 'synced-log',
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: scheduledFor,
        action: 'fed',
        actedAt: actedAt,
        actedByUserId: 'user-1',
        deviceId: 'device-1',
        createdAt: createdAt,
        synced: true,
      );

      final unsyncedLog = FeedingLogModel(
        id: 'unsynced-log',
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: scheduledFor.add(const Duration(days: 1)),
        action: 'fed',
        actedAt: actedAt,
        actedByUserId: 'user-1',
        deviceId: 'device-1',
        createdAt: createdAt,
        synced: false,
      );

      await HiveBoxes.feedingLogs.put(syncedLog.id, syncedLog);
      await HiveBoxes.feedingLogs.put(unsyncedLog.id, unsyncedLog);

      final allLogs = HiveBoxes.feedingLogs.values
          .cast<FeedingLogModel>()
          .toList();
      final unsyncedLogs = allLogs.where((l) => !l.synced).toList();

      expect(allLogs.length, 2);
      expect(unsyncedLogs.length, 1);
      expect(unsyncedLogs.first.id, 'unsynced-log');
    });
  });

  group('FeedingLogModel - TypeAdapter', () {
    test('should have correct typeId', () {
      final adapter = FeedingLogModelAdapter();
      expect(adapter.typeId, 25);
    });
  });
}
