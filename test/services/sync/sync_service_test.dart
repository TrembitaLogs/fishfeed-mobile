import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/feeding_log_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/data/datasources/remote/api_client.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/services/sync/conflict_resolver.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

// Mock classes
class MockAquariumLocalDataSource extends Mock
    implements AquariumLocalDataSource {}

class MockFishLocalDataSource extends Mock implements FishLocalDataSource {}

class MockFeedingLogLocalDataSource extends Mock
    implements FeedingLogLocalDataSource {}

class MockScheduleLocalDataSource extends Mock
    implements ScheduleLocalDataSource {}

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

class MockConnectivity extends Mock implements Connectivity {}

class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeAquariumModel extends Fake implements AquariumModel {}

class FakeFishModel extends Fake implements FishModel {}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeAquariumModel());
    registerFallbackValue(FakeFishModel());
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(DateTime.now());

    // Initialize HiveBoxes for tests
    tempDir = await Directory.systemTemp.createTemp('sync_service_test_');
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
  late MockApiClient mockApiClient;
  late MockDio mockDio;
  late MockConnectivity mockConnectivity;
  late StreamController<List<ConnectivityResult>> connectivityController;

  setUp(() {
    mockAquariumDs = MockAquariumLocalDataSource();
    mockFishDs = MockFishLocalDataSource();
    mockFeedingLogDs = MockFeedingLogLocalDataSource();
    mockScheduleDs = MockScheduleLocalDataSource();
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    mockConnectivity = MockConnectivity();
    connectivityController = StreamController<List<ConnectivityResult>>();

    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => connectivityController.stream);
    when(() => mockApiClient.dio).thenReturn(mockDio);
  });

  tearDown(() {
    connectivityController.close();
  });

  SyncService createSyncService({SyncConfig? config}) {
    return SyncService(
      apiClient: mockApiClient,
      aquariumDs: mockAquariumDs,
      fishDs: mockFishDs,
      feedingLogDs: mockFeedingLogDs,
      scheduleDs: mockScheduleDs,
      config: config ?? const SyncConfig(),
      connectivity: mockConnectivity,
      logger: Logger(printer: PrettyPrinter(), level: Level.off),
    );
  }

  void setupDefaultMocks({bool isOnline = true}) {
    when(() => mockConnectivity.checkConnectivity()).thenAnswer(
      (_) async =>
          isOnline ? [ConnectivityResult.wifi] : [ConnectivityResult.none],
    );

    // Aquarium mocks
    when(() => mockAquariumDs.getUnsyncedAquariums()).thenReturn([]);
    when(() => mockAquariumDs.getModifiedAquariums()).thenReturn([]);
    when(() => mockAquariumDs.getDeletedAquariums()).thenReturn([]);
    when(
      () => mockAquariumDs.markAsSynced(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockAquariumDs.applyServerUpdate(any()),
    ).thenAnswer((_) async {});
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
    when(
      () => mockScheduleDs.applyServerUpdate(any()),
    ).thenAnswer((_) async {});
    when(() => mockScheduleDs.delete(any())).thenAnswer((_) async => true);
  }

  group('SyncConfig', () {
    test('should have correct default values', () {
      const config = SyncConfig();

      expect(config.initialDelay, const Duration(seconds: 1));
      expect(config.maxRetries, 5);
      expect(config.maxDelay, const Duration(seconds: 32));
      expect(config.pageSize, 100);
      expect(config.syncTimeout, const Duration(seconds: 30));
    });

    test('getDelayForRetry should use exponential backoff', () {
      const config = SyncConfig(
        initialDelay: Duration(seconds: 1),
        maxDelay: Duration(seconds: 32),
      );

      expect(config.getDelayForRetry(0), const Duration(seconds: 1));
      expect(config.getDelayForRetry(1), const Duration(seconds: 2));
      expect(config.getDelayForRetry(2), const Duration(seconds: 4));
      expect(config.getDelayForRetry(3), const Duration(seconds: 8));
      expect(config.getDelayForRetry(4), const Duration(seconds: 16));
      expect(config.getDelayForRetry(5), const Duration(seconds: 32));
      // Should cap at maxDelay
      expect(config.getDelayForRetry(6), const Duration(seconds: 32));
    });
  });

  group('SyncResult', () {
    test('should calculate totalProcessed correctly', () {
      const result = SyncResult(uploadedCount: 5, downloadedCount: 3);

      expect(result.totalProcessed, 8);
    });

    test('isSuccess should return true when no errors', () {
      const result = SyncResult(uploadedCount: 5, downloadedCount: 3);

      expect(result.isSuccess, true);
    });

    test('isSuccess should return false when there are errors', () {
      const result = SyncResult(
        uploadedCount: 5,
        downloadedCount: 3,
        errors: ['Error 1'],
      );

      expect(result.isSuccess, false);
    });

    test('toString should format correctly', () {
      const result = SyncResult(
        uploadedCount: 5,
        downloadedCount: 3,
        errors: ['Error 1'],
      );

      expect(
        result.toString(),
        'SyncResult(uploaded: 5, downloaded: 3, conflicts: 0, errors: 1)',
      );
    });
  });

  group('SyncService initialization', () {
    test('should create instance with required parameters', () {
      setupDefaultMocks();

      final service = createSyncService();

      expect(service, isNotNull);
      expect(service.currentState, SyncState.idle);
      expect(service.isProcessing, false);
    });

    test('should start with idle state', () {
      setupDefaultMocks();

      final service = createSyncService();

      expect(service.currentState, SyncState.idle);
    });

    test('hasPendingChanges should return false when no changes', () {
      setupDefaultMocks();

      final service = createSyncService();

      expect(service.hasPendingChanges, false);
    });
  });

  group('SyncService connectivity', () {
    test('should detect online status on startListening', () async {
      setupDefaultMocks(isOnline: true);
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/sync'),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      final service = createSyncService();
      await service.startListening();

      expect(service.isOnline, true);

      // Wait for the unawaited syncAll() to complete before disposing
      await Future<void>.delayed(const Duration(milliseconds: 100));

      service.dispose();
    });

    test('should detect offline status', () async {
      setupDefaultMocks(isOnline: false);

      final service = createSyncService();
      await service.startListening();

      expect(service.isOnline, false);

      service.dispose();
    });

    test('should trigger sync when connectivity restored', () async {
      setupDefaultMocks(isOnline: false);
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/sync'),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      final service = createSyncService();
      await service.startListening();

      // Simulate connectivity restored
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      connectivityController.add([ConnectivityResult.wifi]);

      // Wait for async processing
      await Future<void>.delayed(const Duration(milliseconds: 100));

      service.dispose();
    });
  });

  group('SyncService syncAll', () {
    test('should return 0 when offline', () async {
      setupDefaultMocks(isOnline: false);

      final service = createSyncService();
      final result = await service.syncAll();

      expect(result, 0);
    });

    test('should return 0 when already processing', () async {
      setupDefaultMocks(isOnline: true);

      // Create a slow response to simulate processing
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return Response(
          requestOptions: RequestOptions(path: '/sync'),
          statusCode: 200,
          data: <String, dynamic>{},
        );
      });

      final service = createSyncService();

      // Start first sync
      final firstSync = service.syncAll();

      // Try to start second sync immediately
      final secondSyncResult = await service.syncAll();

      expect(secondSyncResult, 0);

      // Wait for first sync to complete
      await firstSync;
    });

    test('should update state to syncing during sync', () async {
      setupDefaultMocks(isOnline: true);
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/sync'),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      final service = createSyncService();
      final states = <SyncState>[];

      service.stateStream.listen(states.add);

      await service.syncAll();

      expect(states.contains(SyncState.syncing), true);
    });

    test('should update state to success after successful sync', () async {
      setupDefaultMocks(isOnline: true);
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/sync'),
          statusCode: 200,
          // Return null data to indicate simple success (no changes from server)
          data: null,
        ),
      );

      final service = createSyncService();

      await service.syncAll();

      expect(service.currentState, SyncState.success);
    });

    test('should update state to error after failed sync', () async {
      setupDefaultMocks(isOnline: true);
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/sync'),
          message: 'Network error',
        ),
      );

      final service = createSyncService();

      await service.syncAll();

      expect(service.currentState, SyncState.error);
      expect(service.lastError, isNotNull);
    });
  });

  group('SyncService syncNow', () {
    test('should reset retry count and sync', () async {
      setupDefaultMocks(isOnline: true);
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/sync'),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      final service = createSyncService();

      final result = await service.syncNow();

      expect(result, greaterThanOrEqualTo(0));
    });

    test('should return 0 when offline', () async {
      setupDefaultMocks(isOnline: false);

      final service = createSyncService();

      final result = await service.syncNow();

      expect(result, 0);
    });
  });

  group('SyncService state stream', () {
    test('should emit state changes', () async {
      setupDefaultMocks(isOnline: true);
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/sync'),
          statusCode: 200,
          // Return null data to indicate simple success
          data: null,
        ),
      );

      final service = createSyncService();
      final states = <SyncState>[];

      final subscription = service.stateStream.listen(states.add);

      await service.syncAll();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states, contains(SyncState.syncing));
      expect(states, contains(SyncState.success));

      await subscription.cancel();
      service.dispose();
    });
  });

  group('SyncService dispose', () {
    test('should clean up resources on dispose', () async {
      setupDefaultMocks(isOnline: true);
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/sync'),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      final service = createSyncService();
      await service.startListening();

      // Wait for the unawaited syncAll() to complete before disposing
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Should not throw
      service.dispose();
    });
  });

  group('SyncService backward compatibility', () {
    test('should provide pendingCount getter', () {
      setupDefaultMocks();

      final service = createSyncService();

      expect(service.pendingCount, equals(service.pendingChangesCount));
    });

    test('should provide hasPendingOperations getter', () {
      setupDefaultMocks();

      final service = createSyncService();

      expect(service.hasPendingOperations, equals(service.hasPendingChanges));
    });

    test('should provide unsyncedFeedingCount getter', () {
      setupDefaultMocks();

      final service = createSyncService();

      expect(service.unsyncedFeedingCount, 0);
    });

    test('should provide hasUnsyncedFeedings getter', () {
      setupDefaultMocks();

      final service = createSyncService();

      expect(service.hasUnsyncedFeedings, false);
    });

    test('should provide pendingConflictCount getter', () {
      setupDefaultMocks();

      final service = createSyncService();

      expect(service.pendingConflictCount, 0);
    });
  });

  group('SyncService with new entity types', () {
    test('should apply feeding_logs from server_state', () async {
      setupDefaultMocks(isOnline: true);

      final serverFeedingLogs = [
        {
          'id': 'log-1',
          'schedule_id': 'schedule-1',
          'action': 'fed',
          'acted_at': '2025-01-15T09:00:00Z',
        },
        {
          'id': 'log-2',
          'schedule_id': 'schedule-2',
          'action': 'skipped',
          'acted_at': '2025-01-15T10:00:00Z',
        },
      ];

      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/sync'),
          statusCode: 200,
          data: <String, dynamic>{
            'server_state': {'feeding_logs': serverFeedingLogs},
          },
        ),
      );

      final service = createSyncService();
      final result = await service.syncAllWithResult();

      expect(result.downloadedCount, 2);
      verify(
        () => mockFeedingLogDs.applyServerUpdate(serverFeedingLogs[0]),
      ).called(1);
      verify(
        () => mockFeedingLogDs.applyServerUpdate(serverFeedingLogs[1]),
      ).called(1);
    });

    test('should apply schedules from server_state', () async {
      setupDefaultMocks(isOnline: true);

      final serverSchedules = [
        {
          'id': 'schedule-1',
          'aquarium_id': 'aquarium-1',
          'fish_id': 'fish-1',
          'feeding_time': '09:00:00',
          'is_active': true,
        },
      ];

      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/sync'),
          statusCode: 200,
          data: <String, dynamic>{
            'server_state': {'schedules': serverSchedules},
          },
        ),
      );

      final service = createSyncService();
      final result = await service.syncAllWithResult();

      expect(result.downloadedCount, 1);
      verify(
        () => mockScheduleDs.applyServerUpdate(serverSchedules[0]),
      ).called(1);
    });

    test('should handle deleted feeding_logs from server', () async {
      setupDefaultMocks(isOnline: true);

      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/sync'),
          statusCode: 200,
          data: <String, dynamic>{
            'server_state': {
              'deleted': {
                'feeding_logs': ['log-1', 'log-2'],
              },
            },
          },
        ),
      );

      final service = createSyncService();
      final result = await service.syncAllWithResult();

      expect(result.deletedLocally, contains('log-1'));
      expect(result.deletedLocally, contains('log-2'));
    });

    test('should handle deleted schedules from server', () async {
      setupDefaultMocks(isOnline: true);

      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/sync'),
          statusCode: 200,
          data: <String, dynamic>{
            'server_state': {
              'deleted': {
                'schedules': ['schedule-1'],
              },
            },
          },
        ),
      );

      final service = createSyncService();
      final result = await service.syncAllWithResult();

      expect(result.deletedLocally, contains('schedule-1'));
      verify(() => mockScheduleDs.delete('schedule-1')).called(1);
    });
  });

  group('SyncService conflict parsing', () {
    test(
      'should parse server_data + server_wins format as useServer conflict',
      () async {
        setupDefaultMocks(isOnline: true);

        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/sync'),
            statusCode: 200,
            data: <String, dynamic>{
              'conflicts': [
                {
                  'entity_type': 'feeding_log',
                  'entity_id': 'log-conflict-1',
                  'resolution': 'server_wins',
                  'server_data': {
                    'id': 'log-server-1',
                    'schedule_id': 'schedule-1',
                    'action': 'fed',
                    'acted_at': '2025-01-15T09:00:00Z',
                    'acted_by_user_name': 'Alice',
                  },
                },
              ],
            },
          ),
        );

        final service = createSyncService();
        final result = await service.syncAllWithResult();

        expect(result.conflicts.length, 1);
        expect(result.conflicts[0].entityType, 'feeding_log');
        expect(result.conflicts[0].entityId, 'log-conflict-1');
        expect(result.conflicts[0].resolution, ConflictResolution.useServer);
        expect(
          result.conflicts[0].serverVersion['acted_by_user_name'],
          'Alice',
        );
      },
    );

    test(
      'should parse local_version + server_version as requireManual',
      () async {
        setupDefaultMocks(isOnline: true);

        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/sync'),
            statusCode: 200,
            data: <String, dynamic>{
              'conflicts': [
                {
                  'entity_type': 'fish',
                  'entity_id': 'fish-1',
                  'local_version': {
                    'name': 'Nemo',
                    'updated_at': '2025-01-15T09:00:00Z',
                  },
                  'server_version': {
                    'name': 'Dory',
                    'updated_at': '2025-01-15T10:00:00Z',
                  },
                  'local_updated_at': '2025-01-15T09:00:00Z',
                  'server_updated_at': '2025-01-15T10:00:00Z',
                },
              ],
            },
          ),
        );

        final service = createSyncService();
        final result = await service.syncAllWithResult();

        expect(result.conflicts.length, 1);
        expect(result.conflicts[0].entityType, 'fish');
        expect(result.conflicts[0].entityId, 'fish-1');
        expect(
          result.conflicts[0].resolution,
          ConflictResolution.requireManual,
        );
      },
    );

    test('should return null for conflict with missing entity_id', () async {
      setupDefaultMocks(isOnline: true);

      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/sync'),
          statusCode: 200,
          data: <String, dynamic>{
            'conflicts': [
              {
                'entity_type': 'feeding_log',
                // missing entity_id
                'resolution': 'server_wins',
                'server_data': {'id': 'log-1'},
              },
            ],
          },
        ),
      );

      final service = createSyncService();
      final result = await service.syncAllWithResult();

      // Invalid conflict should be skipped
      expect(result.conflicts, isEmpty);
    });
  });

  group('SyncService feeding_log conflict auto-resolution', () {
    test(
      'should auto-resolve feeding_log conflict by deleting local and applying server',
      () async {
        setupDefaultMocks(isOnline: true);

        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/sync'),
            statusCode: 200,
            data: <String, dynamic>{
              'conflicts': [
                {
                  'entity_type': 'feeding_log',
                  'entity_id': 'log-local-1',
                  'resolution': 'server_wins',
                  'server_data': {
                    'id': 'log-server-1',
                    'schedule_id': 'schedule-1',
                    'action': 'fed',
                    'acted_at': '2025-01-15T09:00:00Z',
                    'acted_by_user_name': 'Bob',
                  },
                },
              ],
            },
          ),
        );

        final service = createSyncService();
        await service.syncAllWithResult();

        // Verify local log was deleted
        verify(() => mockFeedingLogDs.delete('log-local-1')).called(1);

        // Verify server version was applied
        verify(
          () => mockFeedingLogDs.applyServerUpdate({
            'id': 'log-server-1',
            'schedule_id': 'schedule-1',
            'action': 'fed',
            'acted_at': '2025-01-15T09:00:00Z',
            'acted_by_user_name': 'Bob',
          }),
        ).called(1);

        // Verify it was NOT added to pendingConflicts (auto-resolved)
        expect(service.pendingConflicts, isEmpty);
      },
    );

    test(
      'should emit on feedingConflictStream when feeding_log conflict auto-resolved',
      () async {
        setupDefaultMocks(isOnline: true);

        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/sync'),
            statusCode: 200,
            data: <String, dynamic>{
              'conflicts': [
                {
                  'entity_type': 'feeding_log',
                  'entity_id': 'log-local-2',
                  'resolution': 'server_wins',
                  'server_data': {
                    'id': 'log-server-2',
                    'schedule_id': 'schedule-1',
                    'action': 'fed',
                    'acted_at': '2025-01-15T10:00:00Z',
                    'acted_by_user_name': 'Carol',
                  },
                },
              ],
            },
          ),
        );

        final service = createSyncService();

        // Listen for feeding conflict emission
        final feedingConflicts = <SyncConflict<Map<String, dynamic>>>[];
        final subscription = service.feedingConflictStream.listen(
          feedingConflicts.add,
        );

        await service.syncAllWithResult();

        // Wait for stream event
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(feedingConflicts.length, 1);
        expect(feedingConflicts[0].entityId, 'log-local-2');
        expect(feedingConflicts[0].entityType, 'feeding_log');
        expect(
          feedingConflicts[0].serverVersion['acted_by_user_name'],
          'Carol',
        );

        await subscription.cancel();
        service.dispose();
      },
    );

    test('should NOT auto-resolve non-feeding_log conflicts', () async {
      setupDefaultMocks(isOnline: true);

      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/sync'),
          statusCode: 200,
          data: <String, dynamic>{
            'conflicts': [
              {
                'entity_type': 'fish',
                'entity_id': 'fish-1',
                'local_version': {'name': 'Nemo'},
                'server_version': {'name': 'Dory'},
                'local_updated_at': '2025-01-15T09:00:00Z',
                'server_updated_at': '2025-01-15T10:00:00Z',
              },
            ],
          },
        ),
      );

      final service = createSyncService();

      final feedingConflicts = <SyncConflict<Map<String, dynamic>>>[];
      final subscription = service.feedingConflictStream.listen(
        feedingConflicts.add,
      );

      await service.syncAllWithResult();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Should NOT emit on feedingConflictStream
      expect(feedingConflicts, isEmpty);

      // Should be added to pendingConflicts for manual resolution
      expect(service.pendingConflicts.length, 1);
      expect(service.pendingConflicts[0].entityType, 'fish');

      // Should NOT call delete on feedingLogDs
      verifyNever(() => mockFeedingLogDs.delete(any()));

      await subscription.cancel();
      service.dispose();
    });

    test(
      'should handle feeding_log conflict with empty server_data gracefully',
      () async {
        setupDefaultMocks(isOnline: true);

        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/sync'),
            statusCode: 200,
            data: <String, dynamic>{
              'conflicts': [
                {
                  'entity_type': 'feeding_log',
                  'entity_id': 'log-local-3',
                  'resolution': 'server_wins',
                  'server_data': <String, dynamic>{},
                },
              ],
            },
          ),
        );

        final service = createSyncService();
        await service.syncAllWithResult();

        // Should still delete local log
        verify(() => mockFeedingLogDs.delete('log-local-3')).called(1);

        // Should NOT apply server update when server_data is empty
        verifyNever(() => mockFeedingLogDs.applyServerUpdate(any()));
      },
    );
  });

  group('SyncService offline to online sync', () {
    test('should sync pending changes when connectivity restored', () async {
      setupDefaultMocks(isOnline: false);

      // Setup unsynced feeding logs
      when(() => mockFeedingLogDs.hasUnsyncedLogs()).thenReturn(true);
      when(() => mockFeedingLogDs.getUnsyncedCount()).thenReturn(1);

      final service = createSyncService();
      await service.startListening();

      expect(service.isOnline, false);
      // hasPendingChanges now includes feeding logs
      expect(service.hasPendingChanges, true);

      // Simulate going online
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/sync'),
          statusCode: 200,
          data: <String, dynamic>{
            'synced_ids': ['log-1'],
          },
        ),
      );

      connectivityController.add([ConnectivityResult.wifi]);

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(service.isOnline, true);
      // Verify sync was triggered
      verify(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).called(greaterThanOrEqualTo(1));

      service.dispose();
    });
  });
}
