import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/services/image_sync_queue.dart';
import 'package:fishfeed/data/services/image_upload_service.dart';
import 'package:fishfeed/data/services/image_upload_task.dart';
import 'package:fishfeed/presentation/providers/image_upload_provider.dart';
import 'package:fishfeed/services/connectivity/connectivity_service.dart';

// --- Mocks ---

class MockImageSyncQueue extends Mock implements ImageSyncQueue {}

class MockImageUploadService extends Mock implements ImageUploadService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  // ---------------------------------------------------------------------------
  // ImageUploadQueueStatus
  // ---------------------------------------------------------------------------
  group('ImageUploadQueueStatus', () {
    test('empty has all zero counts and not processing', () {
      const status = ImageUploadQueueStatus.empty;
      expect(status.pendingCount, 0);
      expect(status.failedCount, 0);
      expect(status.isProcessing, false);
      expect(status.hasWork, false);
    });

    test('hasWork returns true when pending > 0', () {
      const status = ImageUploadQueueStatus(pendingCount: 1);
      expect(status.hasWork, true);
    });

    test('hasWork returns true when failed > 0', () {
      const status = ImageUploadQueueStatus(failedCount: 2);
      expect(status.hasWork, true);
    });

    test('hasWork returns false when both counts are 0', () {
      const status = ImageUploadQueueStatus(isProcessing: true);
      expect(status.hasWork, false);
    });

    test('copyWith replaces specified fields', () {
      const original = ImageUploadQueueStatus(
        pendingCount: 1,
        failedCount: 2,
        isProcessing: true,
      );
      final copy = original.copyWith(pendingCount: 5, isProcessing: false);

      expect(copy.pendingCount, 5);
      expect(copy.failedCount, 2); // Unchanged
      expect(copy.isProcessing, false);
    });

    test('copyWith with no arguments returns equal instance', () {
      const original = ImageUploadQueueStatus(pendingCount: 3);
      final copy = original.copyWith();
      expect(copy, original);
    });

    test('equality compares all fields', () {
      const a = ImageUploadQueueStatus(
        pendingCount: 1,
        failedCount: 2,
        isProcessing: true,
      );
      const b = ImageUploadQueueStatus(
        pendingCount: 1,
        failedCount: 2,
        isProcessing: true,
      );
      const c = ImageUploadQueueStatus(
        pendingCount: 1,
        failedCount: 3,
        isProcessing: true,
      );

      expect(a, b);
      expect(a, isNot(c));
    });

    test('hashCode is consistent with equality', () {
      const a = ImageUploadQueueStatus(pendingCount: 1, failedCount: 2);
      const b = ImageUploadQueueStatus(pendingCount: 1, failedCount: 2);
      expect(a.hashCode, b.hashCode);
    });

    test('toString contains all fields', () {
      const status = ImageUploadQueueStatus(
        pendingCount: 3,
        failedCount: 1,
        isProcessing: true,
      );
      final str = status.toString();
      expect(str, contains('pending: 3'));
      expect(str, contains('failed: 1'));
      expect(str, contains('processing: true'));
    });
  });

  // ---------------------------------------------------------------------------
  // ImageUploadNotifier
  // ---------------------------------------------------------------------------
  group('ImageUploadNotifier', () {
    late MockImageSyncQueue mockQueue;
    late MockImageUploadService mockUploadService;
    late MockConnectivityService mockConnectivityService;
    late StreamController<bool> connectivityController;
    late ImageUploadNotifier notifier;

    setUp(() {
      mockQueue = MockImageSyncQueue();
      mockUploadService = MockImageUploadService();
      mockConnectivityService = MockConnectivityService();
      connectivityController = StreamController<bool>.broadcast();

      when(
        () => mockConnectivityService.statusStream,
      ).thenAnswer((_) => connectivityController.stream);
      when(() => mockConnectivityService.isOnline).thenReturn(false);

      // Default queue methods
      when(() => mockQueue.initialize()).thenAnswer((_) async {});
      when(() => mockQueue.recoverStuckTasks()).thenAnswer((_) async => 0);
      when(() => mockQueue.readAll()).thenAnswer((_) async => []);
    });

    tearDown(() {
      if (notifier.mounted) {
        notifier.dispose();
      }
      connectivityController.close();
    });

    ImageUploadNotifier createNotifier({bool isOnline = false}) {
      when(() => mockConnectivityService.isOnline).thenReturn(isOnline);

      notifier = ImageUploadNotifier(
        queue: mockQueue,
        uploadService: mockUploadService,
        connectivityService: mockConnectivityService,
      );
      return notifier;
    }

    // --- initialize ---

    test('initializes queue and recovers stuck tasks', () async {
      createNotifier();

      await notifier.initialize();

      verify(() => mockQueue.initialize()).called(1);
      verify(() => mockQueue.recoverStuckTasks()).called(1);
      expect(notifier.isInitialized, true);
    });

    test('initialize is idempotent', () async {
      createNotifier();

      await notifier.initialize();
      await notifier.initialize();

      verify(() => mockQueue.initialize()).called(1);
    });

    test('processes queue after initialize when online', () async {
      createNotifier(isOnline: true);
      when(() => mockUploadService.processQueue()).thenAnswer((_) async {});

      await notifier.initialize();

      // Give the unawaited processQueue() a chance to run
      await Future<void>.delayed(Duration.zero);

      verify(() => mockUploadService.processQueue()).called(1);
    });

    test('does not process queue after initialize when offline', () async {
      createNotifier(isOnline: false);

      await notifier.initialize();
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => mockUploadService.processQueue());
    });

    test('refreshes status after initialize', () async {
      when(() => mockQueue.readAll()).thenAnswer(
        (_) async => [
          ImageUploadTask(
            id: 'task-1',
            entityType: 'aquarium',
            entityId: 'aq-1',
            localPath: '/fake/path.webp',
            createdAt: DateTime(2025),
            status: ImageUploadStatus.pending,
          ),
          ImageUploadTask(
            id: 'task-2',
            entityType: 'fish',
            entityId: 'fish-1',
            localPath: '/fake/path2.webp',
            createdAt: DateTime(2025),
            status: ImageUploadStatus.failed,
          ),
        ],
      );

      createNotifier();
      await notifier.initialize();

      expect(notifier.state.pendingCount, 1);
      expect(notifier.state.failedCount, 1);
    });

    // --- connectivity trigger ---

    test(
      'processes queue when connectivity restores (offline -> online)',
      () async {
        createNotifier(isOnline: false);
        when(() => mockUploadService.processQueue()).thenAnswer((_) async {});

        await notifier.initialize();

        // Simulate connectivity restored
        connectivityController.add(true);
        await Future<void>.delayed(Duration.zero);

        verify(() => mockUploadService.processQueue()).called(1);
      },
    );

    test('does not process queue on online -> online', () async {
      createNotifier(isOnline: true);
      when(() => mockUploadService.processQueue()).thenAnswer((_) async {});

      await notifier.initialize();
      await Future<void>.delayed(Duration.zero);
      // Reset interaction count from the initial online processQueue
      clearInteractions(mockUploadService);

      // Online -> still online — should NOT trigger processQueue
      connectivityController.add(true);
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => mockUploadService.processQueue());
    });

    test('tracks offline -> online transition correctly', () async {
      createNotifier(isOnline: true);
      when(() => mockUploadService.processQueue()).thenAnswer((_) async {});

      await notifier.initialize();
      await Future<void>.delayed(Duration.zero);
      clearInteractions(mockUploadService);

      // Go offline
      connectivityController.add(false);
      await Future<void>.delayed(Duration.zero);
      verifyNever(() => mockUploadService.processQueue());

      // Come back online
      connectivityController.add(true);
      await Future<void>.delayed(Duration.zero);
      verify(() => mockUploadService.processQueue()).called(1);
    });

    // --- processQueue ---

    test('processQueue sets isProcessing to true then false', () async {
      createNotifier();
      await notifier.initialize();
      when(() => mockUploadService.processQueue()).thenAnswer((_) async {});

      final states = <ImageUploadQueueStatus>[];
      notifier.addListener(states.add);

      await notifier.processQueue();

      // Should have set isProcessing=true then false
      final processingStates = states.map((s) => s.isProcessing).toList();
      expect(processingStates, contains(true));
      expect(processingStates.last, false);
    });

    test('processQueue is no-op when already processing', () async {
      createNotifier();
      await notifier.initialize();

      final completer = Completer<void>();
      when(
        () => mockUploadService.processQueue(),
      ).thenAnswer((_) => completer.future);

      // Start first processQueue
      unawaited(notifier.processQueue());
      await Future<void>.delayed(Duration.zero);

      // Try second processQueue — should be no-op
      await notifier.processQueue();
      completer.complete();
      await Future<void>.delayed(Duration.zero);

      verify(() => mockUploadService.processQueue()).called(1);
    });

    test('processQueue resets isProcessing even on error', () async {
      createNotifier();
      await notifier.initialize();
      when(
        () => mockUploadService.processQueue(),
      ).thenThrow(Exception('Upload failed'));

      // Should not throw
      await notifier.processQueue();

      expect(notifier.state.isProcessing, false);
    });

    // --- queueUpload ---

    test(
      'queueUpload delegates to upload service and refreshes status',
      () async {
        createNotifier();
        await notifier.initialize();

        when(
          () => mockUploadService.queueUpload(
            entityType: any(named: 'entityType'),
            entityId: any(named: 'entityId'),
            imageBytes: any(named: 'imageBytes'),
          ),
        ).thenAnswer((_) async => 'local://abc-123');

        // Stub processQueue (called via unawaited in queueUpload)
        when(() => mockUploadService.processQueue()).thenAnswer((_) async {});

        // After queueUpload, readAll returns one pending task
        when(() => mockQueue.readAll()).thenAnswer(
          (_) async => [
            ImageUploadTask(
              id: 'abc-123',
              entityType: 'aquarium',
              entityId: 'aq-1',
              localPath: '/fake/path.webp',
              createdAt: DateTime(2025),
            ),
          ],
        );

        final result = await notifier.queueUpload(
          entityType: 'aquarium',
          entityId: 'aq-1',
          imageBytes: Uint8List.fromList([1, 2, 3]),
        );

        expect(result, 'local://abc-123');
        expect(notifier.state.pendingCount, 1);
      },
    );

    // --- retryFailed ---

    test(
      'retryFailed delegates to upload service and refreshes status',
      () async {
        createNotifier();
        await notifier.initialize();

        when(() => mockUploadService.retryFailed()).thenAnswer((_) async => 2);

        final count = await notifier.retryFailed();

        expect(count, 2);
        verify(() => mockUploadService.retryFailed()).called(1);
      },
    );

    // --- getLocalImagePath ---

    test('getLocalImagePath delegates to upload service', () async {
      createNotifier();
      when(
        () => mockUploadService.getLocalImagePath(any()),
      ).thenAnswer((_) async => '/fake/path/abc.webp');

      final path = await notifier.getLocalImagePath('local://abc');
      expect(path, '/fake/path/abc.webp');
    });

    // --- dispose ---

    test('dispose cancels connectivity subscription', () async {
      createNotifier();
      await notifier.initialize();

      notifier.dispose();

      // Adding events after dispose should not trigger processQueue
      connectivityController.add(true);
      await Future<void>.delayed(Duration.zero);
      // No way to verify with certainty, but no error should occur
    });
  });

  // ---------------------------------------------------------------------------
  // Integration: offline enqueue -> online processQueue
  // ---------------------------------------------------------------------------
  group('offline -> online cycle', () {
    late MockImageSyncQueue mockQueue;
    late MockImageUploadService mockUploadService;
    late MockConnectivityService mockConnectivityService;
    late StreamController<bool> connectivityController;
    late ImageUploadNotifier notifier;

    setUp(() {
      mockQueue = MockImageSyncQueue();
      mockUploadService = MockImageUploadService();
      mockConnectivityService = MockConnectivityService();
      connectivityController = StreamController<bool>.broadcast();

      when(
        () => mockConnectivityService.statusStream,
      ).thenAnswer((_) => connectivityController.stream);
      when(() => mockQueue.initialize()).thenAnswer((_) async {});
      when(() => mockQueue.recoverStuckTasks()).thenAnswer((_) async => 0);
    });

    tearDown(() {
      if (notifier.mounted) {
        notifier.dispose();
      }
      connectivityController.close();
    });

    test('enqueue offline, then process when online', () async {
      // Start offline
      when(() => mockConnectivityService.isOnline).thenReturn(false);

      notifier = ImageUploadNotifier(
        queue: mockQueue,
        uploadService: mockUploadService,
        connectivityService: mockConnectivityService,
      );

      // Initialize with one pending task already in queue
      when(() => mockQueue.readAll()).thenAnswer(
        (_) async => [
          ImageUploadTask(
            id: 'offline-task',
            entityType: 'aquarium',
            entityId: 'aq-1',
            localPath: '/fake/path.webp',
            createdAt: DateTime(2025),
          ),
        ],
      );

      await notifier.initialize();
      expect(notifier.state.pendingCount, 1);
      verifyNever(() => mockUploadService.processQueue());

      // Enqueue another task while offline
      // Stub processQueue (called via unawaited in queueUpload)
      when(() => mockUploadService.processQueue()).thenAnswer((_) async {});

      when(
        () => mockUploadService.queueUpload(
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          imageBytes: any(named: 'imageBytes'),
        ),
      ).thenAnswer((_) async => 'local://task-2');

      when(() => mockQueue.readAll()).thenAnswer(
        (_) async => [
          ImageUploadTask(
            id: 'offline-task',
            entityType: 'aquarium',
            entityId: 'aq-1',
            localPath: '/fake/path.webp',
            createdAt: DateTime(2025),
          ),
          ImageUploadTask(
            id: 'task-2',
            entityType: 'fish',
            entityId: 'fish-1',
            localPath: '/fake/path2.webp',
            createdAt: DateTime(2025),
          ),
        ],
      );

      await notifier.queueUpload(
        entityType: 'fish',
        entityId: 'fish-1',
        imageBytes: Uint8List.fromList([1, 2, 3]),
      );
      expect(notifier.state.pendingCount, 2);

      // Go online — processQueue should be called again
      when(() => mockQueue.readAll()).thenAnswer((_) async => []);

      connectivityController.add(true);
      await Future<void>.delayed(Duration.zero);

      // called(2): once from queueUpload (unawaited), once from connectivity
      verify(() => mockUploadService.processQueue()).called(2);
      expect(notifier.state.pendingCount, 0);
    });
  });
}
