import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/local/feeding_log_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:fishfeed/data/models/streak_model.dart';
import 'package:fishfeed/services/feeding/feeding_service.dart';
import 'package:fishfeed/services/sync/conflict_resolver.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

// Mock classes
class MockFeedingLogLocalDataSource extends Mock
    implements FeedingLogLocalDataSource {}

class MockScheduleLocalDataSource extends Mock
    implements ScheduleLocalDataSource {}

class MockStreakLocalDataSource extends Mock implements StreakLocalDataSource {}

class MockSyncService extends Mock implements SyncService {}

class FakeFeedingLogModel extends Fake implements FeedingLogModel {}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    registerFallbackValue(FakeFeedingLogModel());
    registerFallbackValue(DateTime.now());

    // Initialize HiveBoxes for tests
    tempDir = await Directory.systemTemp.createTemp('feeding_service_test_');
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

  late MockFeedingLogLocalDataSource mockFeedingLogDs;
  late MockScheduleLocalDataSource mockScheduleDs;
  late MockStreakLocalDataSource mockStreakDs;
  late MockSyncService mockSyncService;

  setUp(() {
    mockFeedingLogDs = MockFeedingLogLocalDataSource();
    mockScheduleDs = MockScheduleLocalDataSource();
    mockStreakDs = MockStreakLocalDataSource();
    mockSyncService = MockSyncService();
  });

  FeedingService createFeedingService() {
    return FeedingService(
      feedingLogLocalDs: mockFeedingLogDs,
      scheduleLocalDs: mockScheduleDs,
      streakLocalDs: mockStreakDs,
      syncService: mockSyncService,
    );
  }

  ScheduleModel createTestSchedule({
    String id = 'schedule-123',
    String aquariumId = 'aquarium-456',
    String fishId = 'fish-789',
  }) {
    return ScheduleModel(
      id: id,
      aquariumId: aquariumId,
      fishId: fishId,
      time: '09:00',
      intervalDays: 1,
      anchorDate: DateTime.now(),
      foodType: 'flakes',
      active: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdByUserId: 'user-123',
    );
  }

  StreakModel createTestStreak({
    String userId = 'user-123',
    int currentStreak = 5,
    int longestStreak = 10,
  }) {
    return StreakModel(
      id: 'streak_$userId',
      userId: userId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }

  group('FeedingService', () {
    group('markAsFed', () {
      test(
        'should return FeedingAlreadyDone when log already exists',
        () async {
          // Arrange
          when(
            () => mockFeedingLogDs.hasLogForScheduleAndDate(any(), any()),
          ).thenReturn(true);

          final service = createFeedingService();
          final scheduledFor = DateTime(2025, 1, 15, 9, 0);

          // Act
          final result = await service.markAsFed(
            scheduleId: 'schedule-123',
            scheduledFor: scheduledFor,
            userId: 'user-123',
          );

          // Assert
          expect(result, isA<FeedingAlreadyDone>());
          final alreadyDone = result as FeedingAlreadyDone;
          expect(alreadyDone.scheduledFor, scheduledFor);
          expect(alreadyDone.message, 'This feeding has already been marked.');
        },
      );

      test(
        'should return FeedingAlreadyDone when schedule not found',
        () async {
          // Arrange
          when(
            () => mockFeedingLogDs.hasLogForScheduleAndDate(any(), any()),
          ).thenReturn(false);
          when(() => mockScheduleDs.getById(any())).thenReturn(null);

          final service = createFeedingService();
          final scheduledFor = DateTime(2025, 1, 15, 9, 0);

          // Act
          final result = await service.markAsFed(
            scheduleId: 'schedule-123',
            scheduledFor: scheduledFor,
            userId: 'user-123',
          );

          // Assert
          expect(result, isA<FeedingAlreadyDone>());
          final alreadyDone = result as FeedingAlreadyDone;
          expect(alreadyDone.message, 'Schedule not found.');
        },
      );

      test('should create log and trigger syncNow when offline', () async {
        // Arrange
        final schedule = createTestSchedule();
        final streak = createTestStreak();

        when(
          () => mockFeedingLogDs.hasLogForScheduleAndDate(any(), any()),
        ).thenReturn(false);
        when(() => mockScheduleDs.getById(any())).thenReturn(schedule);
        when(() => mockFeedingLogDs.save(any())).thenAnswer((_) async {});
        when(() => mockSyncService.isOnline).thenReturn(false);
        when(() => mockSyncService.isProcessing).thenReturn(false);
        when(() => mockSyncService.syncNow()).thenAnswer((_) async => 0);
        when(
          () => mockStreakDs.incrementStreak(any(), any()),
        ).thenAnswer((_) async => streak);

        final service = createFeedingService();
        final scheduledFor = DateTime(2025, 1, 15, 9, 0);

        // Act
        final result = await service.markAsFed(
          scheduleId: 'schedule-123',
          scheduledFor: scheduledFor,
          userId: 'user-123',
          userDisplayName: 'John',
          notes: 'Morning feeding',
        );

        // Assert
        expect(result, isA<FeedingSuccess>());
        final success = result as FeedingSuccess;
        expect(success.log.scheduleId, 'schedule-123');
        expect(success.log.action, 'fed');
        expect(success.log.aquariumId, schedule.aquariumId);
        expect(success.log.fishId, schedule.fishId);
        expect(success.log.actedByUserId, 'user-123');
        expect(success.log.actedByUserName, 'John');
        expect(success.log.notes, 'Morning feeding');
        expect(success.log.synced, false);
        expect(success.streak.currentStreak, streak.currentStreak);

        // Verify: save locally, trigger sync (fire-and-forget)
        verify(() => mockFeedingLogDs.save(any())).called(1);
        // syncNow is called asynchronously (fire-and-forget)
        await Future<void>.delayed(const Duration(milliseconds: 50));
        verify(() => mockSyncService.syncNow()).called(1);
        // syncAllWithResult should NOT be called when offline
        verifyNever(() => mockSyncService.syncAllWithResult());
      });

      test('should await syncAllWithResult when online', () async {
        // Arrange
        final schedule = createTestSchedule();
        final streak = createTestStreak();

        when(
          () => mockFeedingLogDs.hasLogForScheduleAndDate(any(), any()),
        ).thenReturn(false);
        when(() => mockScheduleDs.getById(any())).thenReturn(schedule);
        when(() => mockFeedingLogDs.save(any())).thenAnswer((_) async {});
        when(() => mockSyncService.isOnline).thenReturn(true);
        when(() => mockSyncService.isProcessing).thenReturn(false);
        when(() => mockSyncService.syncAllWithResult()).thenAnswer(
          (_) async => const SyncResult(uploadedCount: 1, downloadedCount: 0),
        );
        when(
          () => mockStreakDs.incrementStreak(any(), any()),
        ).thenAnswer((_) async => streak);

        final service = createFeedingService();
        final scheduledFor = DateTime(2025, 1, 15, 9, 0);

        // Act
        final result = await service.markAsFed(
          scheduleId: 'schedule-123',
          scheduledFor: scheduledFor,
          userId: 'user-123',
        );

        // Assert
        expect(result, isA<FeedingSuccess>());
        verify(() => mockSyncService.syncAllWithResult()).called(1);
        verifyNever(() => mockSyncService.syncNow());
      });

      test(
        'should return FeedingAlreadyDone when sync returns conflict',
        () async {
          // Arrange
          final schedule = createTestSchedule();
          late String capturedLogId;

          when(
            () => mockFeedingLogDs.hasLogForScheduleAndDate(any(), any()),
          ).thenReturn(false);
          when(() => mockScheduleDs.getById(any())).thenReturn(schedule);
          when(() => mockFeedingLogDs.save(any())).thenAnswer((
            invocation,
          ) async {
            final log = invocation.positionalArguments[0] as FeedingLogModel;
            capturedLogId = log.id;
          });
          when(() => mockSyncService.isOnline).thenReturn(true);
          when(() => mockSyncService.isProcessing).thenReturn(false);

          // SyncAllWithResult returns a conflict matching our entity
          when(() => mockSyncService.syncAllWithResult()).thenAnswer((_) async {
            return SyncResult(
              uploadedCount: 0,
              downloadedCount: 0,
              conflicts: [
                SyncConflict(
                  entityId: capturedLogId,
                  entityType: 'feeding_log',
                  localVersion: const <String, dynamic>{},
                  serverVersion: const <String, dynamic>{
                    'acted_by_user_name': 'Jane',
                  },
                  localUpdatedAt: DateTime.now(),
                  serverUpdatedAt: DateTime.now(),
                  resolution: ConflictResolution.useServer,
                ),
              ],
            );
          });

          final service = createFeedingService();
          final scheduledFor = DateTime(2025, 1, 15, 9, 0);

          // Act
          final result = await service.markAsFed(
            scheduleId: 'schedule-123',
            scheduledFor: scheduledFor,
            userId: 'user-123',
          );

          // Assert
          expect(result, isA<FeedingAlreadyDone>());
          final alreadyDone = result as FeedingAlreadyDone;
          expect(
            alreadyDone.message,
            'This feeding was already marked by Jane.',
          );
        },
      );

      test(
        'should return FeedingAlreadyDone with generic message when no name',
        () async {
          // Arrange
          final schedule = createTestSchedule();
          late String capturedLogId;

          when(
            () => mockFeedingLogDs.hasLogForScheduleAndDate(any(), any()),
          ).thenReturn(false);
          when(() => mockScheduleDs.getById(any())).thenReturn(schedule);
          when(() => mockFeedingLogDs.save(any())).thenAnswer((
            invocation,
          ) async {
            final log = invocation.positionalArguments[0] as FeedingLogModel;
            capturedLogId = log.id;
          });
          when(() => mockSyncService.isOnline).thenReturn(true);
          when(() => mockSyncService.isProcessing).thenReturn(false);

          when(() => mockSyncService.syncAllWithResult()).thenAnswer((_) async {
            return SyncResult(
              uploadedCount: 0,
              downloadedCount: 0,
              conflicts: [
                SyncConflict(
                  entityId: capturedLogId,
                  entityType: 'feeding_log',
                  localVersion: const <String, dynamic>{},
                  serverVersion: const <String, dynamic>{},
                  localUpdatedAt: DateTime.now(),
                  serverUpdatedAt: DateTime.now(),
                  resolution: ConflictResolution.useServer,
                ),
              ],
            );
          });

          final service = createFeedingService();
          final scheduledFor = DateTime(2025, 1, 15, 9, 0);

          // Act
          final result = await service.markAsFed(
            scheduleId: 'schedule-123',
            scheduledFor: scheduledFor,
            userId: 'user-123',
          );

          // Assert
          expect(result, isA<FeedingAlreadyDone>());
          final alreadyDone = result as FeedingAlreadyDone;
          expect(
            alreadyDone.message,
            'This feeding was already marked by another family member.',
          );
        },
      );

      test('should fire-and-forget syncNow when sync is processing', () async {
        // Arrange
        final schedule = createTestSchedule();
        final streak = createTestStreak();

        when(
          () => mockFeedingLogDs.hasLogForScheduleAndDate(any(), any()),
        ).thenReturn(false);
        when(() => mockScheduleDs.getById(any())).thenReturn(schedule);
        when(() => mockFeedingLogDs.save(any())).thenAnswer((_) async {});
        when(() => mockSyncService.isOnline).thenReturn(true);
        when(() => mockSyncService.isProcessing).thenReturn(true);
        when(() => mockSyncService.syncNow()).thenAnswer((_) async => 0);
        when(
          () => mockStreakDs.incrementStreak(any(), any()),
        ).thenAnswer((_) async => streak);

        final service = createFeedingService();

        // Act
        final result = await service.markAsFed(
          scheduleId: 'schedule-123',
          scheduledFor: DateTime(2025, 1, 15, 9, 0),
          userId: 'user-123',
        );

        // Assert
        expect(result, isA<FeedingSuccess>());
        verifyNever(() => mockSyncService.syncAllWithResult());
        // syncNow is called asynchronously
        await Future<void>.delayed(const Duration(milliseconds: 50));
        verify(() => mockSyncService.syncNow()).called(1);
      });
    });

    group('markAsSkipped', () {
      test('should create log with skipped action', () async {
        // Arrange
        final schedule = createTestSchedule();
        final streak = createTestStreak();

        when(
          () => mockFeedingLogDs.hasLogForScheduleAndDate(any(), any()),
        ).thenReturn(false);
        when(() => mockScheduleDs.getById(any())).thenReturn(schedule);
        when(() => mockFeedingLogDs.save(any())).thenAnswer((_) async {});
        when(() => mockSyncService.isOnline).thenReturn(false);
        when(() => mockSyncService.isProcessing).thenReturn(false);
        when(() => mockSyncService.syncNow()).thenAnswer((_) async => 0);
        when(() => mockStreakDs.getStreakByUserId(any())).thenReturn(streak);

        final service = createFeedingService();
        final scheduledFor = DateTime(2025, 1, 15, 9, 0);

        // Act
        final result = await service.markAsSkipped(
          scheduleId: 'schedule-123',
          scheduledFor: scheduledFor,
          userId: 'user-123',
          notes: 'Fish not hungry',
        );

        // Assert
        expect(result, isA<FeedingSuccess>());
        final success = result as FeedingSuccess;
        expect(success.log.action, 'skipped');
        expect(success.log.notes, 'Fish not hungry');
        expect(success.streak.currentStreak, streak.currentStreak);
      });

      test('should not reset streak when skipping', () async {
        // Arrange
        final schedule = createTestSchedule();
        final streak = createTestStreak(currentStreak: 10, longestStreak: 15);

        when(
          () => mockFeedingLogDs.hasLogForScheduleAndDate(any(), any()),
        ).thenReturn(false);
        when(() => mockScheduleDs.getById(any())).thenReturn(schedule);
        when(() => mockFeedingLogDs.save(any())).thenAnswer((_) async {});
        when(() => mockSyncService.isOnline).thenReturn(false);
        when(() => mockSyncService.isProcessing).thenReturn(false);
        when(() => mockSyncService.syncNow()).thenAnswer((_) async => 0);
        when(() => mockStreakDs.getStreakByUserId(any())).thenReturn(streak);

        final service = createFeedingService();

        // Act
        final result = await service.markAsSkipped(
          scheduleId: 'schedule-123',
          scheduledFor: DateTime(2025, 1, 15, 9, 0),
          userId: 'user-123',
        );

        // Assert
        expect(result, isA<FeedingSuccess>());
        final success = result as FeedingSuccess;
        expect(success.streak.currentStreak, 10);
        verifyNever(() => mockStreakDs.incrementStreak(any(), any()));
      });
    });

    group('FeedingResult pattern matching', () {
      test('should support exhaustive pattern matching', () async {
        // Arrange
        when(
          () => mockFeedingLogDs.hasLogForScheduleAndDate(any(), any()),
        ).thenReturn(true);

        final service = createFeedingService();

        // Act
        final result = await service.markAsFed(
          scheduleId: 'schedule-123',
          scheduledFor: DateTime.now(),
          userId: 'user-123',
        );

        // Assert - demonstrate pattern matching
        final message = switch (result) {
          FeedingSuccess(:final log, :final streak) =>
            'Fed! Log: ${log.id}, Streak: ${streak.currentStreak}',
          FeedingAlreadyDone(:final message) => 'Already done: $message',
        };

        expect(message, contains('Already done'));
      });
    });
  });

  group('FeedingService edge cases', () {
    test('should handle multiple rapid calls for same schedule', () async {
      // Arrange - first call succeeds, second detects duplicate
      final schedule = createTestSchedule();
      final streak = createTestStreak();
      var callCount = 0;

      when(
        () => mockFeedingLogDs.hasLogForScheduleAndDate(any(), any()),
      ).thenAnswer((_) {
        callCount++;
        return callCount > 1;
      });
      when(() => mockScheduleDs.getById(any())).thenReturn(schedule);
      when(() => mockFeedingLogDs.save(any())).thenAnswer((_) async {});
      when(() => mockSyncService.isOnline).thenReturn(false);
      when(() => mockSyncService.isProcessing).thenReturn(false);
      when(() => mockSyncService.syncNow()).thenAnswer((_) async => 0);
      when(
        () => mockStreakDs.incrementStreak(any(), any()),
      ).thenAnswer((_) async => streak);

      final service = createFeedingService();
      final scheduledFor = DateTime(2025, 1, 15, 9, 0);

      // Act
      final result1 = await service.markAsFed(
        scheduleId: 'schedule-123',
        scheduledFor: scheduledFor,
        userId: 'user-123',
      );
      final result2 = await service.markAsFed(
        scheduleId: 'schedule-123',
        scheduledFor: scheduledFor,
        userId: 'user-123',
      );

      // Assert
      expect(result1, isA<FeedingSuccess>());
      expect(result2, isA<FeedingAlreadyDone>());
    });

    test('should preserve user display name in created log', () async {
      // Arrange
      final schedule = createTestSchedule();
      final streak = createTestStreak();
      late FeedingLogModel capturedLog;

      when(
        () => mockFeedingLogDs.hasLogForScheduleAndDate(any(), any()),
      ).thenReturn(false);
      when(() => mockScheduleDs.getById(any())).thenReturn(schedule);
      when(() => mockFeedingLogDs.save(any())).thenAnswer((invocation) async {
        capturedLog = invocation.positionalArguments[0] as FeedingLogModel;
      });
      when(() => mockSyncService.isOnline).thenReturn(false);
      when(() => mockSyncService.isProcessing).thenReturn(false);
      when(() => mockSyncService.syncNow()).thenAnswer((_) async => 0);
      when(
        () => mockStreakDs.incrementStreak(any(), any()),
      ).thenAnswer((_) async => streak);

      final service = createFeedingService();

      // Act
      await service.markAsFed(
        scheduleId: 'schedule-123',
        scheduledFor: DateTime(2025, 1, 15, 9, 0),
        userId: 'user-123',
        userDisplayName: 'John Doe',
      );

      // Assert
      expect(capturedLog.actedByUserName, 'John Doe');
      expect(capturedLog.actedByUserId, 'user-123');
    });

    test('should generate unique UUIDs for each log', () async {
      // Arrange
      final schedule1 = createTestSchedule(id: 'schedule-1');
      final schedule2 = createTestSchedule(id: 'schedule-2');
      final streak = createTestStreak();
      final capturedLogIds = <String>[];

      when(
        () => mockFeedingLogDs.hasLogForScheduleAndDate(any(), any()),
      ).thenReturn(false);
      when(() => mockScheduleDs.getById('schedule-1')).thenReturn(schedule1);
      when(() => mockScheduleDs.getById('schedule-2')).thenReturn(schedule2);
      when(() => mockFeedingLogDs.save(any())).thenAnswer((invocation) async {
        final log = invocation.positionalArguments[0] as FeedingLogModel;
        capturedLogIds.add(log.id);
      });
      when(() => mockSyncService.isOnline).thenReturn(false);
      when(() => mockSyncService.isProcessing).thenReturn(false);
      when(() => mockSyncService.syncNow()).thenAnswer((_) async => 0);
      when(
        () => mockStreakDs.incrementStreak(any(), any()),
      ).thenAnswer((_) async => streak);

      final service = createFeedingService();

      // Act
      await service.markAsFed(
        scheduleId: 'schedule-1',
        scheduledFor: DateTime(2025, 1, 15, 9, 0),
        userId: 'user-123',
      );
      await service.markAsFed(
        scheduleId: 'schedule-2',
        scheduledFor: DateTime(2025, 1, 15, 10, 0),
        userId: 'user-123',
      );

      // Assert
      expect(capturedLogIds.length, 2);
      expect(capturedLogIds[0], isNot(capturedLogIds[1]));
      expect(capturedLogIds[0].length, 36); // UUID v4 format
      expect(capturedLogIds[1].length, 36);
    });

    test('should handle streak for user without existing streak', () async {
      // Arrange
      final schedule = createTestSchedule();

      when(
        () => mockFeedingLogDs.hasLogForScheduleAndDate(any(), any()),
      ).thenReturn(false);
      when(() => mockScheduleDs.getById(any())).thenReturn(schedule);
      when(() => mockFeedingLogDs.save(any())).thenAnswer((_) async {});
      when(() => mockSyncService.isOnline).thenReturn(false);
      when(() => mockSyncService.isProcessing).thenReturn(false);
      when(() => mockSyncService.syncNow()).thenAnswer((_) async => 0);
      when(() => mockStreakDs.getStreakByUserId(any())).thenReturn(null);

      final service = createFeedingService();

      // Act
      final result = await service.markAsSkipped(
        scheduleId: 'schedule-123',
        scheduledFor: DateTime(2025, 1, 15, 9, 0),
        userId: 'new-user',
      );

      // Assert
      expect(result, isA<FeedingSuccess>());
      final success = result as FeedingSuccess;
      expect(success.streak.currentStreak, 0);
      expect(success.streak.longestStreak, 0);
    });
  });
}
