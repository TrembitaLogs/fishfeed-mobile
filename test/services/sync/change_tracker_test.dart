import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/feeding_log_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:fishfeed/data/models/user_model.dart';
import 'package:fishfeed/services/sync/change_tracker.dart';

// Mock classes
class MockAquariumLocalDataSource extends Mock
    implements AquariumLocalDataSource {}

class MockFishLocalDataSource extends Mock implements FishLocalDataSource {}

class MockFeedingLogLocalDataSource extends Mock
    implements FeedingLogLocalDataSource {}

class MockScheduleLocalDataSource extends Mock
    implements ScheduleLocalDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('change_tracker_test_');
    Hive.init(tempDir.path);
    await HiveBoxes.initForTesting();
  });

  tearDownAll(() async {
    await HiveBoxes.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  late MockAquariumLocalDataSource mockAquariumDs;
  late MockFishLocalDataSource mockFishDs;
  late MockFeedingLogLocalDataSource mockFeedingLogDs;
  late MockScheduleLocalDataSource mockNewScheduleDs;
  late MockAuthLocalDataSource mockAuthLocalDs;

  setUp(() {
    mockAquariumDs = MockAquariumLocalDataSource();
    mockFishDs = MockFishLocalDataSource();
    mockFeedingLogDs = MockFeedingLogLocalDataSource();
    mockNewScheduleDs = MockScheduleLocalDataSource();
    mockAuthLocalDs = MockAuthLocalDataSource();
  });

  ChangeTracker createChangeTracker({bool includeNewDatasources = true}) {
    return ChangeTracker(
      aquariumDs: mockAquariumDs,
      fishDs: mockFishDs,
      authLocalDs: mockAuthLocalDs,
      feedingLogDs: includeNewDatasources ? mockFeedingLogDs : null,
      newScheduleDs: includeNewDatasources ? mockNewScheduleDs : null,
    );
  }

  void setupEmptyMocks() {
    when(() => mockAquariumDs.getUnsyncedAquariums()).thenReturn([]);
    when(() => mockAquariumDs.getDeletedAquariums()).thenReturn([]);
    when(() => mockFishDs.getUnsyncedFish()).thenReturn([]);
    when(() => mockFishDs.getDeletedFish()).thenReturn([]);
    when(() => mockFeedingLogDs.hasUnsyncedLogs()).thenReturn(false);
    when(() => mockFeedingLogDs.getUnsynced()).thenReturn([]);
    when(() => mockNewScheduleDs.hasUnsyncedSchedules()).thenReturn(false);
    when(() => mockNewScheduleDs.getUnsynced()).thenReturn([]);
    when(() => mockAuthLocalDs.getUnsyncedUser()).thenReturn(null);
  }

  FeedingLogModel createTestFeedingLog({
    String id = 'log-123',
    String scheduleId = 'schedule-456',
    bool synced = false,
  }) {
    return FeedingLogModel(
      id: id,
      scheduleId: scheduleId,
      fishId: 'fish-789',
      aquariumId: 'aquarium-abc',
      scheduledFor: DateTime(2025, 1, 15, 9, 0),
      action: 'fed',
      actedAt: DateTime(2025, 1, 15, 9, 5),
      actedByUserId: 'user-xyz',
      deviceId: 'device-123',
      createdAt: DateTime(2025, 1, 15, 9, 5),
      synced: synced,
    );
  }

  ScheduleModel createTestSchedule({
    String id = 'schedule-123',
    bool synced = false,
    DateTime? serverUpdatedAt,
  }) {
    return ScheduleModel(
      id: id,
      aquariumId: 'aquarium-456',
      fishId: 'fish-789',
      time: '09:00',
      intervalDays: 1,
      anchorDate: DateTime.now(),
      foodType: 'flakes',
      active: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdByUserId: 'user-123',
      synced: synced,
      serverUpdatedAt: serverUpdatedAt,
    );
  }

  group('ChangeTracker', () {
    group('EntityType enum', () {
      test('should have all required entity types', () {
        expect(EntityType.values, contains(EntityType.aquarium));
        expect(EntityType.values, contains(EntityType.fish));
        expect(EntityType.values, contains(EntityType.feedingLog));
        expect(EntityType.values, contains(EntityType.newSchedule));
        expect(EntityType.values, contains(EntityType.streak));
        expect(EntityType.values, contains(EntityType.achievement));
        expect(EntityType.values, contains(EntityType.progress));
      });

      test('should not contain legacy event and schedule types', () {
        final typeNames = EntityType.values.map((e) => e.name).toList();
        expect(typeNames, isNot(contains('event')));
        expect(typeNames, isNot(contains('schedule')));
      });
    });

    group('collectAllChanges', () {
      test('should return empty list when no changes', () {
        setupEmptyMocks();

        final tracker = createChangeTracker();
        final changes = tracker.collectAllChanges();

        expect(changes, isEmpty);
      });

      test('should collect unsynced feeding logs', () {
        setupEmptyMocks();

        final unsyncedLog = createTestFeedingLog(id: 'log-1');
        when(() => mockFeedingLogDs.getUnsynced()).thenReturn([unsyncedLog]);

        final tracker = createChangeTracker();
        final changes = tracker.collectAllChanges();

        final feedingLogChanges = changes.where(
          (c) => c.entityType == EntityType.feedingLog,
        );
        expect(feedingLogChanges.length, 1);
        expect(feedingLogChanges.first.entityId, 'log-1');
        expect(feedingLogChanges.first.operation, SyncOperation.create);
      });

      test('should collect unsynced new schedules', () {
        setupEmptyMocks();

        final unsyncedSchedule = createTestSchedule(id: 'schedule-1');
        when(
          () => mockNewScheduleDs.getUnsynced(),
        ).thenReturn([unsyncedSchedule]);

        final tracker = createChangeTracker();
        final changes = tracker.collectAllChanges();

        final scheduleChanges = changes.where(
          (c) => c.entityType == EntityType.newSchedule,
        );
        expect(scheduleChanges.length, 1);
        expect(scheduleChanges.first.entityId, 'schedule-1');
        expect(scheduleChanges.first.operation, SyncOperation.create);
      });

      test(
        'should detect update operation for schedules with serverUpdatedAt',
        () {
          setupEmptyMocks();

          final modifiedSchedule = createTestSchedule(
            id: 'schedule-1',
            serverUpdatedAt: DateTime.now().subtract(const Duration(hours: 1)),
          );
          when(
            () => mockNewScheduleDs.getUnsynced(),
          ).thenReturn([modifiedSchedule]);

          final tracker = createChangeTracker();
          final changes = tracker.collectAllChanges();

          final scheduleChanges = changes.where(
            (c) => c.entityType == EntityType.newSchedule,
          );
          expect(scheduleChanges.first.operation, SyncOperation.update);
        },
      );

      test('should collect multiple entity types together', () {
        setupEmptyMocks();

        final unsyncedLog = createTestFeedingLog(id: 'log-1');
        final unsyncedSchedule = createTestSchedule(id: 'schedule-1');

        when(() => mockFeedingLogDs.getUnsynced()).thenReturn([unsyncedLog]);
        when(
          () => mockNewScheduleDs.getUnsynced(),
        ).thenReturn([unsyncedSchedule]);

        final tracker = createChangeTracker();
        final changes = tracker.collectAllChanges();

        expect(changes.length, 2);
        expect(changes.any((c) => c.entityType == EntityType.feedingLog), true);
        expect(
          changes.any((c) => c.entityType == EntityType.newSchedule),
          true,
        );
      });
    });

    group('collectChangesForType', () {
      test('should collect only feedingLog changes', () {
        setupEmptyMocks();

        final unsyncedLog = createTestFeedingLog(id: 'log-1');
        when(() => mockFeedingLogDs.getUnsynced()).thenReturn([unsyncedLog]);

        final tracker = createChangeTracker();
        final changes = tracker.collectChangesForType(EntityType.feedingLog);

        expect(changes.length, 1);
        expect(changes.first.entityType, EntityType.feedingLog);
      });

      test('should collect only newSchedule changes', () {
        setupEmptyMocks();

        final unsyncedSchedule = createTestSchedule(id: 'schedule-1');
        when(
          () => mockNewScheduleDs.getUnsynced(),
        ).thenReturn([unsyncedSchedule]);

        final tracker = createChangeTracker();
        final changes = tracker.collectChangesForType(EntityType.newSchedule);

        expect(changes.length, 1);
        expect(changes.first.entityType, EntityType.newSchedule);
      });

      test('should return empty for server-managed types', () {
        setupEmptyMocks();

        final tracker = createChangeTracker();

        expect(tracker.collectChangesForType(EntityType.streak), isEmpty);
        expect(tracker.collectChangesForType(EntityType.achievement), isEmpty);
        expect(tracker.collectChangesForType(EntityType.progress), isEmpty);
      });
    });

    group('hasChanges', () {
      test('should return false when no changes', () {
        setupEmptyMocks();

        final tracker = createChangeTracker();

        expect(tracker.hasChanges, false);
      });

      test('should return true when feeding logs have unsynced', () {
        setupEmptyMocks();
        when(() => mockFeedingLogDs.hasUnsyncedLogs()).thenReturn(true);

        final tracker = createChangeTracker();

        expect(tracker.hasChanges, true);
      });

      test('should return true when new schedules have unsynced', () {
        setupEmptyMocks();
        when(() => mockNewScheduleDs.hasUnsyncedSchedules()).thenReturn(true);

        final tracker = createChangeTracker();

        expect(tracker.hasChanges, true);
      });
    });

    group('pendingChangesCount', () {
      test('should return 0 when no changes', () {
        setupEmptyMocks();
        when(() => mockFeedingLogDs.getUnsyncedCount()).thenReturn(0);
        when(() => mockNewScheduleDs.getUnsyncedCount()).thenReturn(0);

        final tracker = createChangeTracker();

        expect(tracker.pendingChangesCount, 0);
      });

      test('should count feeding logs', () {
        setupEmptyMocks();
        when(() => mockFeedingLogDs.getUnsyncedCount()).thenReturn(3);
        when(() => mockNewScheduleDs.getUnsyncedCount()).thenReturn(0);

        final tracker = createChangeTracker();

        expect(tracker.pendingChangesCount, 3);
      });

      test('should count new schedules', () {
        setupEmptyMocks();
        when(() => mockFeedingLogDs.getUnsyncedCount()).thenReturn(0);
        when(() => mockNewScheduleDs.getUnsyncedCount()).thenReturn(2);

        final tracker = createChangeTracker();

        expect(tracker.pendingChangesCount, 2);
      });

      test('should sum all entity types', () {
        setupEmptyMocks();
        when(() => mockFeedingLogDs.getUnsyncedCount()).thenReturn(3);
        when(() => mockNewScheduleDs.getUnsyncedCount()).thenReturn(2);

        final tracker = createChangeTracker();

        expect(tracker.pendingChangesCount, 5);
      });
    });

    group('SyncChange', () {
      test('toJson should produce correct format', () {
        final change = SyncChange(
          entityType: EntityType.feedingLog,
          entityId: 'log-123',
          operation: SyncOperation.create,
          data: {'schedule_id': 'schedule-456', 'action': 'fed'},
          clientUpdatedAt: DateTime.utc(2025, 1, 15, 9, 0),
        );

        final json = change.toJson();

        expect(json['entity_type'], 'feeding_log');
        expect(json['entity_id'], 'log-123');
        expect(json['operation'], 'create');
        expect(json['data']['schedule_id'], 'schedule-456');
        expect(json['client_updated_at'], '2025-01-15T09:00:00.000Z');
      });

      test('toString should be readable', () {
        final change = SyncChange(
          entityType: EntityType.newSchedule,
          entityId: 'schedule-123',
          operation: SyncOperation.update,
          data: {},
          clientUpdatedAt: DateTime.now(),
        );

        expect(
          change.toString(),
          'SyncChange(newSchedule:schedule-123, update)',
        );
      });
    });

    group('without new datasources', () {
      test('should work gracefully without feedingLogDs', () {
        setupEmptyMocks();

        final tracker = createChangeTracker(includeNewDatasources: false);
        final changes = tracker.collectAllChanges();

        expect(changes, isEmpty);
        expect(tracker.hasChanges, false);
        expect(tracker.pendingChangesCount, 0);
      });
    });

    group('local:// photo_key filtering', () {
      AquariumModel createTestAquarium({
        String id = 'aquarium-123',
        String? photoKey,
        DateTime? serverUpdatedAt,
      }) {
        return AquariumModel(
          id: id,
          userId: 'user-abc',
          name: 'Test Aquarium',
          createdAt: DateTime(2025, 1, 15),
          serverUpdatedAt: serverUpdatedAt,
          photoKey: photoKey,
        );
      }

      FishModel createTestFish({
        String id = 'fish-123',
        String? photoKey,
        DateTime? serverUpdatedAt,
      }) {
        return FishModel(
          id: id,
          aquariumId: 'aquarium-456',
          speciesId: 'species-789',
          addedAt: DateTime(2025, 1, 15),
          serverUpdatedAt: serverUpdatedAt,
          photoKey: photoKey,
        );
      }

      group('aquarium sync data', () {
        test('should NOT include photo_key when it starts with local://', () {
          setupEmptyMocks();

          final aquarium = createTestAquarium(
            photoKey: 'local://a1b2c3d4-e5f6-7890-abcd-ef1234567890',
          );
          when(
            () => mockAquariumDs.getUnsyncedAquariums(),
          ).thenReturn([aquarium]);

          final tracker = createChangeTracker();
          final changes = tracker.collectAllChanges();

          final aquariumChange = changes.firstWhere(
            (c) => c.entityType == EntityType.aquarium,
          );
          expect(aquariumChange.data.containsKey('photo_key'), false);
        });

        test('should include photo_key when it is a valid S3 key', () {
          setupEmptyMocks();

          final aquarium = createTestAquarium(
            photoKey: 'aquariums/aquarium-123/f7a3b2c1.webp',
          );
          when(
            () => mockAquariumDs.getUnsyncedAquariums(),
          ).thenReturn([aquarium]);

          final tracker = createChangeTracker();
          final changes = tracker.collectAllChanges();

          final aquariumChange = changes.firstWhere(
            (c) => c.entityType == EntityType.aquarium,
          );
          expect(
            aquariumChange.data['photo_key'],
            'aquariums/aquarium-123/f7a3b2c1.webp',
          );
        });

        test('should include photo_key as null when it is null', () {
          setupEmptyMocks();

          final aquarium = createTestAquarium();
          when(
            () => mockAquariumDs.getUnsyncedAquariums(),
          ).thenReturn([aquarium]);

          final tracker = createChangeTracker();
          final changes = tracker.collectAllChanges();

          final aquariumChange = changes.firstWhere(
            (c) => c.entityType == EntityType.aquarium,
          );
          // null photo_key is included so server receives photo deletion
          expect(aquariumChange.data.containsKey('photo_key'), true);
          expect(aquariumChange.data['photo_key'], isNull);
        });

        test('should include water_type in sync payload', () {
          setupEmptyMocks();

          final aquarium = createTestAquarium(
            photoKey: 'aquariums/aquarium-123/abc.webp',
          );
          when(
            () => mockAquariumDs.getUnsyncedAquariums(),
          ).thenReturn([aquarium]);

          final tracker = createChangeTracker();
          final changes = tracker.collectAllChanges();

          final aquariumChange = changes.firstWhere(
            (c) => c.entityType == EntityType.aquarium,
          );
          expect(aquariumChange.data['water_type'], 'freshwater');
        });

        test('should include capacity in sync payload', () {
          setupEmptyMocks();

          final aquarium = AquariumModel(
            id: 'aquarium-cap',
            userId: 'user-abc',
            name: 'Big Tank',
            capacity: 120.5,
            createdAt: DateTime(2025, 1, 15),
          );
          when(
            () => mockAquariumDs.getUnsyncedAquariums(),
          ).thenReturn([aquarium]);

          final tracker = createChangeTracker();
          final changes = tracker.collectAllChanges();

          final aquariumChange = changes.firstWhere(
            (c) => c.entityType == EntityType.aquarium,
          );
          expect(aquariumChange.data['capacity'], 120.5);
        });
      });

      group('fish sync data', () {
        test('should NOT include photo_key when it starts with local://', () {
          setupEmptyMocks();

          final fish = createTestFish(
            photoKey: 'local://b2c3d4e5-f6a7-8901-bcde-f12345678901',
          );
          when(() => mockFishDs.getUnsyncedFish()).thenReturn([fish]);

          final tracker = createChangeTracker();
          final changes = tracker.collectAllChanges();

          final fishChange = changes.firstWhere(
            (c) => c.entityType == EntityType.fish,
          );
          expect(fishChange.data.containsKey('photo_key'), false);
        });

        test('should include photo_key when it is a valid S3 key', () {
          setupEmptyMocks();

          final fish = createTestFish(photoKey: 'fish/fish-123/c4e82a1f.webp');
          when(() => mockFishDs.getUnsyncedFish()).thenReturn([fish]);

          final tracker = createChangeTracker();
          final changes = tracker.collectAllChanges();

          final fishChange = changes.firstWhere(
            (c) => c.entityType == EntityType.fish,
          );
          expect(fishChange.data['photo_key'], 'fish/fish-123/c4e82a1f.webp');
        });

        test('should include photo_key as null when it is null', () {
          setupEmptyMocks();

          final fish = createTestFish();
          when(() => mockFishDs.getUnsyncedFish()).thenReturn([fish]);

          final tracker = createChangeTracker();
          final changes = tracker.collectAllChanges();

          final fishChange = changes.firstWhere(
            (c) => c.entityType == EntityType.fish,
          );
          // null photo_key is included so server receives photo deletion
          expect(fishChange.data.containsKey('photo_key'), true);
          expect(fishChange.data['photo_key'], isNull);
        });

        test('should include notes field in sync payload', () {
          setupEmptyMocks();

          final fish = FishModel(
            id: 'fish-notes',
            aquariumId: 'aquarium-456',
            speciesId: 'species-789',
            addedAt: DateTime(2025, 1, 15),
            notes: 'Very friendly fish',
          );
          when(() => mockFishDs.getUnsyncedFish()).thenReturn([fish]);

          final tracker = createChangeTracker();
          final changes = tracker.collectAllChanges();

          final fishChange = changes.firstWhere(
            (c) => c.entityType == EntityType.fish,
          );
          expect(fishChange.data['notes'], 'Very friendly fish');
        });

        test('should include null notes in sync payload', () {
          setupEmptyMocks();

          final fish = FishModel(
            id: 'fish-no-notes',
            aquariumId: 'aquarium-456',
            speciesId: 'species-789',
            addedAt: DateTime(2025, 1, 15),
          );
          when(() => mockFishDs.getUnsyncedFish()).thenReturn([fish]);

          final tracker = createChangeTracker();
          final changes = tracker.collectAllChanges();

          final fishChange = changes.firstWhere(
            (c) => c.entityType == EntityType.fish,
          );
          expect(fishChange.data.containsKey('notes'), true);
          expect(fishChange.data['notes'], isNull);
        });

        test('should include aquarium_id in sync payload', () {
          setupEmptyMocks();

          final fish = createTestFish(photoKey: 'fish/fish-123/abc.webp');
          when(() => mockFishDs.getUnsyncedFish()).thenReturn([fish]);

          final tracker = createChangeTracker();
          final changes = tracker.collectAllChanges();

          final fishChange = changes.firstWhere(
            (c) => c.entityType == EntityType.fish,
          );
          expect(fishChange.data['aquarium_id'], 'aquarium-456');
        });

        test('should include quantity in sync payload', () {
          setupEmptyMocks();

          final fish = FishModel(
            id: 'fish-qty',
            aquariumId: 'aquarium-456',
            speciesId: 'species-789',
            quantity: 5,
            addedAt: DateTime(2025, 1, 15),
          );
          when(() => mockFishDs.getUnsyncedFish()).thenReturn([fish]);

          final tracker = createChangeTracker();
          final changes = tracker.collectAllChanges();

          final fishChange = changes.firstWhere(
            (c) => c.entityType == EntityType.fish,
          );
          expect(fishChange.data['quantity'], 5);
        });
      });

      group('user profile sync data', () {
        test('should NOT include avatar_key when it starts with local://', () {
          setupEmptyMocks();

          final user = UserModel(
            id: 'user-123',
            email: 'test@example.com',
            createdAt: DateTime(2025, 1, 15),
            avatarKey: 'local://c3d4e5f6-a7b8-9012-cdef-123456789012',
            synced: false,
          );
          when(() => mockAuthLocalDs.getUnsyncedUser()).thenReturn(user);

          final tracker = createChangeTracker();
          final changes = tracker.collectAllChanges();

          final userChange = changes.firstWhere(
            (c) => c.entityType == EntityType.userProfile,
          );
          expect(userChange.data.containsKey('avatar_key'), false);
        });

        test('should include avatar_key when it is a valid S3 key', () {
          setupEmptyMocks();

          final user = UserModel(
            id: 'user-123',
            email: 'test@example.com',
            createdAt: DateTime(2025, 1, 15),
            avatarKey: 'avatars/user-123/d5e6f7a8.webp',
            synced: false,
          );
          when(() => mockAuthLocalDs.getUnsyncedUser()).thenReturn(user);

          final tracker = createChangeTracker();
          final changes = tracker.collectAllChanges();

          final userChange = changes.firstWhere(
            (c) => c.entityType == EntityType.userProfile,
          );
          expect(
            userChange.data['avatar_key'],
            'avatars/user-123/d5e6f7a8.webp',
          );
        });

        test('should NOT include avatar_key when it is null', () {
          setupEmptyMocks();

          final user = UserModel(
            id: 'user-123',
            email: 'test@example.com',
            createdAt: DateTime(2025, 1, 15),
            synced: false,
          );
          when(() => mockAuthLocalDs.getUnsyncedUser()).thenReturn(user);

          final tracker = createChangeTracker();
          final changes = tracker.collectAllChanges();

          final userChange = changes.firstWhere(
            (c) => c.entityType == EntityType.userProfile,
          );
          // User toSyncJson only includes avatar_key when it's a valid S3 key
          expect(userChange.data.containsKey('avatar_key'), false);
        });
      });
    });
  });
}
