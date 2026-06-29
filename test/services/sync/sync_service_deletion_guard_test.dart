import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:fishfeed/data/datasources/local/achievement_local_ds.dart';
import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/feeding_log_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/data/datasources/local/user_progress_local_ds.dart';
import 'package:fishfeed/data/datasources/remote/api_client.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/services/sentry/sentry_service.dart';
import 'package:fishfeed/services/sync/conflict_resolver.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

class MockAquariumLocalDataSource extends Mock
    implements AquariumLocalDataSource {}

class MockFishLocalDataSource extends Mock implements FishLocalDataSource {}

class MockFeedingLogLocalDataSource extends Mock
    implements FeedingLogLocalDataSource {}

class MockScheduleLocalDataSource extends Mock
    implements ScheduleLocalDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockStreakLocalDataSource extends Mock implements StreakLocalDataSource {}

class MockAchievementLocalDataSource extends Mock
    implements AchievementLocalDataSource {}

class MockUserProgressLocalDataSource extends Mock
    implements UserProgressLocalDataSource {}

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

class MockConnectivity extends Mock implements Connectivity {}

class MockSentryService extends Mock implements SentryService {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(DateTime.now());
    registerFallbackValue(SentryLevel.warning);

    tempDir = await Directory.systemTemp.createTemp('deletion_guard_test_');
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
  late MockScheduleLocalDataSource mockScheduleDs;
  late MockAuthLocalDataSource mockAuthLocalDs;
  late MockStreakLocalDataSource mockStreakDs;
  late MockAchievementLocalDataSource mockAchievementDs;
  late MockUserProgressLocalDataSource mockProgressDs;
  late MockApiClient mockApiClient;
  late MockDio mockDio;
  late MockConnectivity mockConnectivity;
  late MockSentryService mockSentry;
  late StreamController<List<ConnectivityResult>> connectivityController;

  setUp(() {
    mockAquariumDs = MockAquariumLocalDataSource();
    mockFishDs = MockFishLocalDataSource();
    mockFeedingLogDs = MockFeedingLogLocalDataSource();
    mockScheduleDs = MockScheduleLocalDataSource();
    mockAuthLocalDs = MockAuthLocalDataSource();
    mockStreakDs = MockStreakLocalDataSource();
    mockAchievementDs = MockAchievementLocalDataSource();
    mockProgressDs = MockUserProgressLocalDataSource();
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    mockConnectivity = MockConnectivity();
    mockSentry = MockSentryService();
    connectivityController = StreamController<List<ConnectivityResult>>();

    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => connectivityController.stream);
    when(() => mockApiClient.dio).thenReturn(mockDio);

    _setupDefaultMocks(
      mockConnectivity: mockConnectivity,
      mockAquariumDs: mockAquariumDs,
      mockFishDs: mockFishDs,
      mockFeedingLogDs: mockFeedingLogDs,
      mockScheduleDs: mockScheduleDs,
      mockAuthLocalDs: mockAuthLocalDs,
      mockStreakDs: mockStreakDs,
      mockAchievementDs: mockAchievementDs,
      mockProgressDs: mockProgressDs,
      mockSentry: mockSentry,
    );
  });

  tearDown(() {
    connectivityController.close();
  });

  SyncService createSyncService() {
    return SyncService(
      apiClient: mockApiClient,
      aquariumDs: mockAquariumDs,
      fishDs: mockFishDs,
      feedingLogDs: mockFeedingLogDs,
      scheduleDs: mockScheduleDs,
      authLocalDs: mockAuthLocalDs,
      streakDs: mockStreakDs,
      achievementDs: mockAchievementDs,
      progressDs: mockProgressDs,
      connectivity: mockConnectivity,
      logger: Logger(printer: PrettyPrinter(), level: Level.off),
      sentry: mockSentry,
    );
  }

  void stubDeletedAquarium(List<String> ids) {
    when(
      () => mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/sync'),
        statusCode: 200,
        data: <String, dynamic>{
          'server_state': {
            'deleted': {'aquariums': ids},
          },
        },
      ),
    );
  }

  void stubDeletedFish(List<String> ids) {
    when(
      () => mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/sync'),
        statusCode: 200,
        data: <String, dynamic>{
          'server_state': {
            'deleted': {'fish': ids},
          },
        },
      ),
    );
  }

  AquariumModel buildAquarium({required bool synced, required bool deleted}) {
    return AquariumModel(
      id: 'aq-1',
      userId: 'user-1',
      name: 'Tank',
      createdAt: DateTime(2025, 1, 1),
      synced: synced,
      updatedAt: DateTime(2025, 1, 2),
      serverUpdatedAt: DateTime(2025, 1, 1),
      deletedAt: deleted ? DateTime(2025, 1, 3) : null,
    );
  }

  FishModel buildFish({required bool synced, required bool deleted}) {
    return FishModel(
      id: 'fish-1',
      aquariumId: 'aq-1',
      speciesId: 'species-1',
      addedAt: DateTime(2025, 1, 1),
      synced: synced,
      updatedAt: DateTime(2025, 1, 2),
      serverUpdatedAt: DateTime(2025, 1, 1),
      deletedAt: deleted ? DateTime(2025, 1, 3) : null,
    );
  }

  group('_applyServerDeletions aquarium matrix', () {
    test('absent local record: no crash, reported, not hard-deleted', () async {
      when(() => mockAquariumDs.getAquariumById('aq-1')).thenReturn(null);
      stubDeletedAquarium(['aq-1']);

      final service = createSyncService();
      final result = await service.syncAllWithResult();

      expect(result.deletedLocally, contains('aq-1'));
      verifyNever(() => mockAquariumDs.deleteAquarium('aq-1'));
    });

    test('locally-also-deleted: marked synced and hard-deleted', () async {
      when(
        () => mockAquariumDs.getAquariumById('aq-1'),
      ).thenReturn(buildAquarium(synced: false, deleted: true));
      stubDeletedAquarium(['aq-1']);

      final service = createSyncService();
      final result = await service.syncAllWithResult();

      verify(() => mockAquariumDs.markAsSynced('aq-1', any())).called(1);
      verify(() => mockAquariumDs.deleteAquarium('aq-1')).called(1);
      expect(result.deletedLocally, contains('aq-1'));
    });

    test(
      'present + synced (no local edits): accepted and hard-deleted',
      () async {
        when(
          () => mockAquariumDs.getAquariumById('aq-1'),
        ).thenReturn(buildAquarium(synced: true, deleted: false));
        stubDeletedAquarium(['aq-1']);

        final service = createSyncService();
        final result = await service.syncAllWithResult();

        verify(() => mockAquariumDs.deleteAquarium('aq-1')).called(1);
        expect(result.deletedLocally, contains('aq-1'));
        verify(
          () => mockSentry.captureMessage(
            'Aquarium deleted by server sync',
            level: SentryLevel.warning,
            extras: {'aquarium_id': 'aq-1', 'origin': 'server_sync'},
          ),
        ).called(1);
      },
    );

    test(
      'present + unsynced edits: PRESERVED, conflict emitted, telemetry fired',
      () async {
        when(
          () => mockAquariumDs.getAquariumById('aq-1'),
        ).thenReturn(buildAquarium(synced: false, deleted: false));
        stubDeletedAquarium(['aq-1']);

        final service = createSyncService();
        final conflicts = <SyncConflict<Map<String, dynamic>>>[];
        final subscription = service.conflictStream.listen(conflicts.add);

        final result = await service.syncAllWithResult();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // The local record is preserved (never hard-deleted) and not reported.
        verifyNever(() => mockAquariumDs.deleteAquarium('aq-1'));
        expect(result.deletedLocally, isNot(contains('aq-1')));

        // A deletion conflict is emitted on the conflict stream.
        expect(conflicts.length, 1);
        expect(conflicts.first.entityId, 'aq-1');
        expect(conflicts.first.entityType, 'aquarium');
        expect(conflicts.first.conflictType, ConflictType.deletionConflict);
        expect(conflicts.first.isDeletionConflict, isTrue);

        // Telemetry attributes the skipped server deletion.
        verify(
          () => mockSentry.captureMessage(
            'Server deletion skipped: local has unsynced edits',
            level: SentryLevel.warning,
            extras: {'aquarium_id': 'aq-1', 'origin': 'server_sync'},
          ),
        ).called(1);

        await subscription.cancel();
        service.dispose();
      },
    );
  });

  group('_applyServerDeletions fish matrix', () {
    test('absent local record: no crash, reported, not hard-deleted', () async {
      when(() => mockFishDs.getFishById('fish-1')).thenReturn(null);
      stubDeletedFish(['fish-1']);

      final service = createSyncService();
      final result = await service.syncAllWithResult();

      expect(result.deletedLocally, contains('fish-1'));
      verifyNever(() => mockFishDs.deleteFish('fish-1'));
    });

    test('locally-also-deleted: marked synced and hard-deleted', () async {
      when(
        () => mockFishDs.getFishById('fish-1'),
      ).thenReturn(buildFish(synced: false, deleted: true));
      stubDeletedFish(['fish-1']);

      final service = createSyncService();
      final result = await service.syncAllWithResult();

      verify(() => mockFishDs.markAsSynced('fish-1', any())).called(1);
      verify(() => mockFishDs.deleteFish('fish-1')).called(1);
      expect(result.deletedLocally, contains('fish-1'));
    });

    test(
      'present + synced (no local edits): accepted and hard-deleted',
      () async {
        when(
          () => mockFishDs.getFishById('fish-1'),
        ).thenReturn(buildFish(synced: true, deleted: false));
        stubDeletedFish(['fish-1']);

        final service = createSyncService();
        final result = await service.syncAllWithResult();

        verify(() => mockFishDs.deleteFish('fish-1')).called(1);
        expect(result.deletedLocally, contains('fish-1'));
      },
    );

    test(
      'present + unsynced edits: PRESERVED, conflict emitted, telemetry fired',
      () async {
        when(
          () => mockFishDs.getFishById('fish-1'),
        ).thenReturn(buildFish(synced: false, deleted: false));
        stubDeletedFish(['fish-1']);

        final service = createSyncService();
        final conflicts = <SyncConflict<Map<String, dynamic>>>[];
        final subscription = service.conflictStream.listen(conflicts.add);

        final result = await service.syncAllWithResult();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        verifyNever(() => mockFishDs.deleteFish('fish-1'));
        expect(result.deletedLocally, isNot(contains('fish-1')));

        expect(conflicts.length, 1);
        expect(conflicts.first.entityId, 'fish-1');
        expect(conflicts.first.entityType, 'fish');
        expect(conflicts.first.conflictType, ConflictType.deletionConflict);

        verify(
          () => mockSentry.captureMessage(
            'Server deletion skipped: local has unsynced edits',
            level: SentryLevel.warning,
            extras: {'fish_id': 'fish-1', 'origin': 'server_sync'},
          ),
        ).called(1);

        await subscription.cancel();
        service.dispose();
      },
    );
  });
}

void _setupDefaultMocks({
  required MockConnectivity mockConnectivity,
  required MockAquariumLocalDataSource mockAquariumDs,
  required MockFishLocalDataSource mockFishDs,
  required MockFeedingLogLocalDataSource mockFeedingLogDs,
  required MockScheduleLocalDataSource mockScheduleDs,
  required MockAuthLocalDataSource mockAuthLocalDs,
  required MockStreakLocalDataSource mockStreakDs,
  required MockAchievementLocalDataSource mockAchievementDs,
  required MockUserProgressLocalDataSource mockProgressDs,
  required MockSentryService mockSentry,
}) {
  when(
    () => mockConnectivity.checkConnectivity(),
  ).thenAnswer((_) async => [ConnectivityResult.wifi]);

  // Aquarium mocks
  when(() => mockAquariumDs.getUnsyncedAquariums()).thenReturn([]);
  when(() => mockAquariumDs.getModifiedAquariums()).thenReturn([]);
  when(() => mockAquariumDs.getDeletedAquariums()).thenReturn([]);
  when(
    () => mockAquariumDs.markAsSynced(any(), any()),
  ).thenAnswer((_) async {});
  when(() => mockAquariumDs.applyServerUpdate(any())).thenAnswer((_) async {});
  when(
    () => mockAquariumDs.deleteAquarium(any()),
  ).thenAnswer((_) async => true);
  when(() => mockAquariumDs.purgeSyncedDeletions()).thenAnswer((_) async {});

  // Fish mocks
  when(() => mockFishDs.getUnsyncedFish()).thenReturn([]);
  when(() => mockFishDs.getModifiedFish()).thenReturn([]);
  when(() => mockFishDs.getDeletedFish()).thenReturn([]);
  when(
    () => mockFishDs.markAsSynced(any(), any()),
  ).thenAnswer((_) async => true);
  when(() => mockFishDs.applyServerUpdate(any())).thenAnswer((_) async {});
  when(() => mockFishDs.deleteFish(any())).thenAnswer((_) async => true);
  when(() => mockFishDs.purgeSyncedDeletions()).thenAnswer((_) async {});

  // FeedingLog mocks
  when(() => mockFeedingLogDs.hasUnsyncedLogs()).thenReturn(false);
  when(() => mockFeedingLogDs.getUnsynced()).thenReturn([]);
  when(() => mockFeedingLogDs.getUnsyncedCount()).thenReturn(0);
  when(
    () => mockFeedingLogDs.markAsSynced(any(), any()),
  ).thenAnswer((_) async => true);
  when(
    () => mockFeedingLogDs.applyServerUpdate(any()),
  ).thenAnswer((_) async {});
  when(() => mockFeedingLogDs.delete(any())).thenAnswer((_) async => true);

  // Schedule mocks
  when(() => mockScheduleDs.hasUnsyncedSchedules()).thenReturn(false);
  when(() => mockScheduleDs.getUnsynced()).thenReturn([]);
  when(() => mockScheduleDs.getUnsyncedCount()).thenReturn(0);
  when(
    () => mockScheduleDs.markAsSynced(any(), any()),
  ).thenAnswer((_) async => true);
  when(() => mockScheduleDs.applyServerUpdate(any())).thenAnswer((_) async {});
  when(() => mockScheduleDs.delete(any())).thenAnswer((_) async => true);

  // Streak mocks
  when(() => mockStreakDs.getUnsyncedStreaks()).thenReturn([]);
  when(() => mockStreakDs.getUnsyncedCount()).thenReturn(0);
  when(() => mockStreakDs.hasUnsyncedStreaks()).thenReturn(false);
  when(() => mockStreakDs.markAsSynced(any(), any())).thenAnswer((_) async {});
  when(() => mockStreakDs.applyServerUpdate(any())).thenAnswer((_) async {});

  // Achievement mocks
  when(() => mockAchievementDs.getUnsyncedAchievements()).thenReturn([]);
  when(() => mockAchievementDs.getUnsyncedCount()).thenReturn(0);
  when(() => mockAchievementDs.hasUnsyncedAchievements()).thenReturn(false);
  when(
    () => mockAchievementDs.markAsSynced(any(), any()),
  ).thenAnswer((_) async {});
  when(
    () => mockAchievementDs.applyServerUpdate(any()),
  ).thenAnswer((_) async {});

  // Progress mocks
  when(() => mockProgressDs.getUnsyncedProgress()).thenReturn([]);
  when(() => mockProgressDs.getUnsyncedCount()).thenReturn(0);
  when(() => mockProgressDs.hasUnsyncedProgress()).thenReturn(false);
  when(
    () => mockProgressDs.markAsSynced(any(), any()),
  ).thenAnswer((_) async {});
  when(() => mockProgressDs.applyServerUpdate(any())).thenAnswer((_) async {});

  // Auth local mocks
  when(() => mockAuthLocalDs.getUnsyncedUser()).thenReturn(null);
  when(() => mockAuthLocalDs.markUserSynced(any())).thenAnswer((_) async {});
  when(
    () => mockAuthLocalDs.applyServerProfileUpdate(any()),
  ).thenAnswer((_) async {});
  when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(null);

  // Sentry mocks
  when(
    () => mockSentry.captureMessage(
      any(),
      level: any(named: 'level'),
      extras: any(named: 'extras'),
    ),
  ).thenAnswer((_) async {});
  when(
    () => mockSentry.addBreadcrumb(
      message: any(named: 'message'),
      category: any(named: 'category'),
      data: any(named: 'data'),
    ),
  ).thenAnswer((_) async {});
}
