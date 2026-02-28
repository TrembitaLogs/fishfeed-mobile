// E2E tests for the offline image upload flow.
//
// Tests the integration between:
// - ImageSyncQueue — real file-based queue in a temp directory
// - ImageUploadService — real service with mocked HTTP and compression
// - ChangeTracker — real tracker with mocked local datasources
//
// These tests verify the complete journey:
// 1. User takes photo offline → local:// key generated
// 2. Background upload processes queue when online → S3 key returned
// 3. Sync data correctly includes S3 keys and excludes local:// keys
//
// Widget display states (EntityImage 4-state logic) are tested separately
// in test/presentation/widgets/common/entity_image_test.dart.
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/data/models/user_model.dart';
import 'package:fishfeed/data/services/image_sync_queue.dart';
import 'package:fishfeed/data/services/image_upload_service.dart';
import 'package:fishfeed/data/services/image_upload_task.dart';
import 'package:fishfeed/services/image_processing_service.dart';
import 'package:fishfeed/services/sync/change_tracker.dart';

// --- Mocks ---

class MockImageProcessingService extends Mock
    implements ImageProcessingService {}

class MockDio extends Mock implements Dio {}

class MockUuid extends Mock implements Uuid {}

class MockAquariumLocalDataSource extends Mock
    implements AquariumLocalDataSource {}

class MockFishLocalDataSource extends Mock implements FishLocalDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  // Common test data
  final testImageBytes = Uint8List.fromList(List.filled(100, 0xFF));
  final compressedWebP = Uint8List.fromList([
    0x52,
    0x49,
    0x46,
    0x46,
    0x00,
    0x00,
    0x00,
    0x04,
  ]);

  late Directory tempDir;
  late ImageSyncQueue queue;
  late MockImageProcessingService mockImageProcessor;
  late MockDio mockDio;
  late MockUuid mockUuid;
  late MockAquariumLocalDataSource mockAquariumDs;
  late MockFishLocalDataSource mockFishDs;
  late MockAuthLocalDataSource mockAuthDs;

  // Tracks onUploadComplete callback invocations.
  late List<({String entityType, String entityId, String photoKey})>
  uploadCompleted;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(FormData());
    registerFallbackValue(Options());
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('e2e_image_sync_');
    queue = ImageSyncQueue(basePath: tempDir.path);
    await queue.initialize();

    mockImageProcessor = MockImageProcessingService();
    mockDio = MockDio();
    mockUuid = MockUuid();
    mockAquariumDs = MockAquariumLocalDataSource();
    mockFishDs = MockFishLocalDataSource();
    mockAuthDs = MockAuthLocalDataSource();
    uploadCompleted = [];

    // Default mock: compression always succeeds.
    when(
      () => mockImageProcessor.compressToWebP(
        any(),
        quality: any(named: 'quality'),
        maxWidth: any(named: 'maxWidth'),
      ),
    ).thenAnswer(
      (_) async => CompressionResult(
        bytes: compressedWebP,
        originalSize: testImageBytes.length,
        compressedSize: compressedWebP.length,
      ),
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // --- Helpers ---

  ImageUploadService createUploadService({Uuid? uuid}) {
    return ImageUploadService(
      queue: queue,
      imageProcessor: mockImageProcessor,
      dio: mockDio,
      onUploadComplete:
          ({
            required String entityType,
            required String entityId,
            required String photoKey,
          }) async {
            uploadCompleted.add((
              entityType: entityType,
              entityId: entityId,
              photoKey: photoKey,
            ));
          },
      uuid: uuid,
      delayFn: (_) async {}, // No actual delays in tests.
    );
  }

  ChangeTracker createTracker() {
    return ChangeTracker(
      aquariumDs: mockAquariumDs,
      fishDs: mockFishDs,
      authLocalDs: mockAuthDs,
    );
  }

  void setupEmptyMocks() {
    when(() => mockAquariumDs.getUnsyncedAquariums()).thenReturn([]);
    when(() => mockAquariumDs.getDeletedAquariums()).thenReturn([]);
    when(() => mockFishDs.getUnsyncedFish()).thenReturn([]);
    when(() => mockFishDs.getDeletedFish()).thenReturn([]);
    when(() => mockAuthDs.getUnsyncedUser()).thenReturn(null);
  }

  void arrangeDioSuccess({
    required String key,
    required String entityType,
    required String entityId,
  }) {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: {'key': key, 'entity_type': entityType, 'entity_id': entityId},
        statusCode: 201,
        requestOptions: RequestOptions(),
      ),
    );
  }

  // =========================================================================
  // Offline image upload E2E flow
  // =========================================================================
  group('Offline image upload E2E flow', () {
    test('complete aquarium photo lifecycle: queue → upload → sync', () async {
      const entityId = 'aq-001';
      const s3Key = 'aquariums/aq-001/f7a3b2c1.webp';
      final service = createUploadService();
      setupEmptyMocks();

      // --- Phase 1: Offline — queue the image ---
      final localKey = await service.queueUpload(
        entityType: 'aquarium',
        entityId: entityId,
        imageBytes: testImageBytes,
      );

      expect(localKey, startsWith('local://'));

      // Verify compressed file exists on disk.
      final taskId = localKey.substring('local://'.length);
      expect(await queue.fileExists(taskId), isTrue);

      // Verify compression was called with aquarium settings.
      verify(
        () => mockImageProcessor.compressToWebP(
          testImageBytes,
          quality: 80,
          maxWidth: 2048,
        ),
      ).called(1);

      // --- Phase 2: Verify local:// key is excluded from sync ---
      final aquarium = AquariumModel(
        id: entityId,
        userId: 'user-1',
        name: 'Test Aquarium',
        createdAt: DateTime(2025, 6, 15),
        photoKey: localKey,
        synced: false,
      );
      when(() => mockAquariumDs.getUnsyncedAquariums()).thenReturn([aquarium]);

      final tracker = createTracker();
      final changesBeforeUpload = tracker.collectAllChanges();

      expect(changesBeforeUpload, hasLength(1));
      expect(
        changesBeforeUpload.first.data.containsKey('photo_key'),
        isFalse,
        reason: 'local:// keys must not be sent to the server',
      );

      // --- Phase 3: Online — process the queue ---
      arrangeDioSuccess(key: s3Key, entityType: 'aquarium', entityId: entityId);

      await service.processQueue();

      // Verify upload API was called.
      verify(
        () => mockDio.post<Map<String, dynamic>>(
          '/images/upload',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).called(1);

      // Verify onUploadComplete was called with the S3 key.
      expect(uploadCompleted, hasLength(1));
      expect(uploadCompleted.first.entityType, 'aquarium');
      expect(uploadCompleted.first.entityId, entityId);
      expect(uploadCompleted.first.photoKey, s3Key);

      // --- Phase 4: Verify S3 key IS included in sync ---
      aquarium.photoKey = s3Key;
      aquarium.updatedAt = DateTime.now();

      final changesAfterUpload = tracker.collectAllChanges();

      expect(changesAfterUpload, hasLength(1));
      expect(changesAfterUpload.first.data['photo_key'], s3Key);

      // --- Phase 5: Verify queue cleanup ---
      expect(await queue.fileExists(taskId), isFalse);
      final remainingTasks = await queue.readAll();
      expect(remainingTasks, isEmpty);
    });

    test('fish entity follows the same lifecycle', () async {
      const entityId = 'fish-001';
      const s3Key = 'fish/fish-001/c4e82a1f.webp';
      final service = createUploadService();
      setupEmptyMocks();

      // Phase 1: Queue fish photo.
      final localKey = await service.queueUpload(
        entityType: 'fish',
        entityId: entityId,
        imageBytes: testImageBytes,
      );

      expect(localKey, startsWith('local://'));

      // Verify fish compression settings (same as aquarium: 80%, 2048).
      verify(
        () => mockImageProcessor.compressToWebP(
          testImageBytes,
          quality: 80,
          maxWidth: 2048,
        ),
      ).called(1);

      // Phase 2: Verify local:// excluded from fish sync data.
      final fish = FishModel(
        id: entityId,
        aquariumId: 'aq-001',
        speciesId: 'species-001',
        addedAt: DateTime(2025, 6, 15),
        photoKey: localKey,
        synced: false,
      );
      when(() => mockFishDs.getUnsyncedFish()).thenReturn([fish]);

      final tracker = createTracker();
      final changesBefore = tracker.collectAllChanges();

      expect(changesBefore.first.data.containsKey('photo_key'), isFalse);

      // Phase 3: Process queue.
      arrangeDioSuccess(key: s3Key, entityType: 'fish', entityId: entityId);
      await service.processQueue();

      expect(uploadCompleted.first.photoKey, s3Key);

      // Phase 4: Verify S3 key in sync.
      fish.photoKey = s3Key;
      fish.updatedAt = DateTime.now();

      final changesAfter = tracker.collectAllChanges();

      expect(changesAfter.first.data['photo_key'], s3Key);
    });

    test(
      'avatar uses higher quality compression and user-specific sync',
      () async {
        const userId = 'user-001';
        const s3Key = 'avatars/user-001/d5e6f7a8.webp';
        final service = createUploadService();
        setupEmptyMocks();

        // Phase 1: Queue avatar.
        final localKey = await service.queueUpload(
          entityType: 'avatar',
          entityId: userId,
          imageBytes: testImageBytes,
        );

        // Verify avatar compression settings: 90% quality, 512 max.
        verify(
          () => mockImageProcessor.compressToWebP(
            testImageBytes,
            quality: 90,
            maxWidth: 512,
          ),
        ).called(1);

        // Phase 2: Verify local:// excluded from user sync.
        final user = UserModel(
          id: userId,
          email: 'test@example.com',
          createdAt: DateTime(2025, 6, 15),
          avatarKey: localKey,
          synced: false,
        );
        when(() => mockAuthDs.getUnsyncedUser()).thenReturn(user);

        final tracker = createTracker();
        final changesBefore = tracker.collectAllChanges();

        expect(changesBefore, hasLength(1));
        expect(
          changesBefore.first.data.containsKey('avatar_key'),
          isFalse,
          reason: 'local:// avatar keys must not be sent to the server',
        );

        // Phase 3: Process queue.
        arrangeDioSuccess(key: s3Key, entityType: 'avatar', entityId: userId);
        await service.processQueue();

        expect(uploadCompleted.first.photoKey, s3Key);

        // Phase 4: Verify S3 key in user sync data.
        user.avatarKey = s3Key;
        user.synced = false;

        final changesAfter = tracker.collectAllChanges();

        expect(changesAfter.first.data['avatar_key'], s3Key);
      },
    );

    test('multiple entities processed sequentially from queue', () async {
      const uuid1 = 'aaaa1111-2222-3333-4444-555566667777';
      const uuid2 = 'bbbb1111-2222-3333-4444-555566667777';

      var uuidCallCount = 0;
      when(() => mockUuid.v4()).thenAnswer((_) {
        uuidCallCount++;
        return uuidCallCount == 1 ? uuid1 : uuid2;
      });

      final service = createUploadService(uuid: mockUuid);

      // Queue two uploads.
      final localKey1 = await service.queueUpload(
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: testImageBytes,
      );
      final localKey2 = await service.queueUpload(
        entityType: 'fish',
        entityId: 'fish-1',
        imageBytes: testImageBytes,
      );

      expect(localKey1, 'local://$uuid1');
      expect(localKey2, 'local://$uuid2');

      // Both files exist.
      expect(await queue.fileExists(uuid1), isTrue);
      expect(await queue.fileExists(uuid2), isTrue);

      // Process queue — mock Dio to return different S3 keys per call.
      var postCount = 0;
      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {
        postCount++;
        final isFirst = postCount == 1;
        return Response(
          data: {
            'key': isFirst ? 'aquariums/aq-1/aaa.webp' : 'fish/fish-1/bbb.webp',
            'entity_type': isFirst ? 'aquarium' : 'fish',
            'entity_id': isFirst ? 'aq-1' : 'fish-1',
          },
          statusCode: 201,
          requestOptions: RequestOptions(),
        );
      });

      await service.processQueue();

      // Both uploads completed.
      expect(uploadCompleted, hasLength(2));
      expect(uploadCompleted[0].photoKey, 'aquariums/aq-1/aaa.webp');
      expect(uploadCompleted[1].photoKey, 'fish/fish-1/bbb.webp');

      // Both files cleaned up.
      expect(await queue.fileExists(uuid1), isFalse);
      expect(await queue.fileExists(uuid2), isFalse);
      expect(await queue.readAll(), isEmpty);
    });
  });

  // =========================================================================
  // Upload retry on network error
  // =========================================================================
  group('Upload retry on network error', () {
    test('retries on 5xx and succeeds on second attempt', () async {
      final service = createUploadService();

      await service.queueUpload(
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: testImageBytes,
      );

      var postCount = 0;
      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {
        postCount++;
        if (postCount == 1) {
          throw DioException(
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 500,
              requestOptions: RequestOptions(),
            ),
            requestOptions: RequestOptions(),
          );
        }
        return Response(
          data: {
            'key': 'aquariums/aq-1/abc.webp',
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
          },
          statusCode: 201,
          requestOptions: RequestOptions(),
        );
      });

      await service.processQueue();

      // 2 attempts: 1 failed + 1 success.
      verify(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).called(2);

      // Upload succeeded.
      expect(uploadCompleted, hasLength(1));
      expect(uploadCompleted.first.photoKey, 'aquariums/aq-1/abc.webp');

      // Task cleaned up from queue.
      expect(await queue.readAll(), isEmpty);
    });

    test('retries on connection timeout and succeeds', () async {
      final service = createUploadService();

      await service.queueUpload(
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: testImageBytes,
      );

      var postCount = 0;
      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {
        postCount++;
        if (postCount == 1) {
          throw DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(),
          );
        }
        return Response(
          data: {
            'key': 'aquariums/aq-1/abc.webp',
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
          },
          statusCode: 201,
          requestOptions: RequestOptions(),
        );
      });

      await service.processQueue();

      verify(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).called(2);
      expect(uploadCompleted, hasLength(1));
    });

    test('does NOT retry on 4xx — task marked as failed', () async {
      final service = createUploadService();

      await service.queueUpload(
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: testImageBytes,
      );

      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          response: Response(statusCode: 400, requestOptions: RequestOptions()),
          requestOptions: RequestOptions(),
        ),
      );

      await service.processQueue();

      // Only 1 attempt — no retry for 4xx.
      verify(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).called(1);

      // No successful upload.
      expect(uploadCompleted, isEmpty);

      // Task remains in queue as failed.
      final tasks = await queue.readAll();
      expect(tasks, hasLength(1));
      expect(tasks.first.status, ImageUploadStatus.failed);
      expect(tasks.first.retryCount, 1);
    });
  });

  // =========================================================================
  // Queue persistence across app restart
  // =========================================================================
  group('Queue persistence across app restart', () {
    test('pending task survives queue re-initialization', () async {
      final service = createUploadService();

      // Enqueue a task.
      final localKey = await service.queueUpload(
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: testImageBytes,
      );
      final taskId = localKey.substring('local://'.length);

      // Verify task is in queue.
      var tasks = await queue.readAll();
      expect(tasks, hasLength(1));
      expect(tasks.first.entityId, 'aq-1');

      // --- Simulate app restart ---
      // Reset the queue object and re-initialize using the same directory.
      queue.resetForTesting();
      await queue.initialize();

      // Task persists after re-initialization.
      tasks = await queue.readAll();
      expect(tasks, hasLength(1));
      expect(tasks.first.id, taskId);
      expect(tasks.first.entityType, 'aquarium');
      expect(tasks.first.entityId, 'aq-1');
      expect(tasks.first.status, ImageUploadStatus.pending);

      // File persists on disk.
      expect(await queue.fileExists(taskId), isTrue);
    });

    test(
      'task stuck in uploading recovered to pending after restart',
      () async {
        final service = createUploadService();

        await service.queueUpload(
          entityType: 'aquarium',
          entityId: 'aq-1',
          imageBytes: testImageBytes,
        );

        // Dequeue marks the task as uploading (simulates upload in progress).
        final task = await queue.dequeue();
        expect(task, isNotNull);
        expect(task!.status, ImageUploadStatus.uploading);

        // --- Simulate crash during upload ---
        queue.resetForTesting();
        await queue.initialize();

        // Task still has uploading status from the persisted file.
        var tasks = await queue.readAll();
        expect(tasks, hasLength(1));
        expect(tasks.first.status, ImageUploadStatus.uploading);

        // Recover stuck tasks (called during normal initialization).
        final recovered = await queue.recoverStuckTasks();
        expect(recovered, 1);

        // Task is now pending again and can be re-processed.
        tasks = await queue.readAll();
        expect(tasks.first.status, ImageUploadStatus.pending);

        // Process the recovered task.
        arrangeDioSuccess(
          key: 'aquariums/aq-1/abc.webp',
          entityType: 'aquarium',
          entityId: 'aq-1',
        );

        final recoveredService = createUploadService();
        await recoveredService.processQueue();

        expect(uploadCompleted, hasLength(1));
        expect(uploadCompleted.first.photoKey, 'aquariums/aq-1/abc.webp');
        expect(await queue.readAll(), isEmpty);
      },
    );
  });

  // =========================================================================
  // Image display state transitions
  // =========================================================================
  group('Image display state transitions', () {
    test(
      'photoKey transitions through all states: null → local:// → S3 key',
      () async {
        final service = createUploadService();
        setupEmptyMocks();

        // State 1: null photoKey — represents placeholder (no photo).
        final aquarium = AquariumModel(
          id: 'aq-1',
          userId: 'user-1',
          name: 'Test',
          createdAt: DateTime(2025, 6, 15),
          synced: false,
        );
        expect(aquarium.photoKey, isNull);

        // State 2: local:// key — after user takes photo, before upload.
        final localKey = await service.queueUpload(
          entityType: 'aquarium',
          entityId: 'aq-1',
          imageBytes: testImageBytes,
        );
        aquarium.photoKey = localKey;
        expect(aquarium.photoKey, startsWith('local://'));

        // Verify local file exists for Image.file() display.
        final localPath = await service.getLocalImagePath(localKey);
        expect(localPath, isNotNull);
        expect(File(localPath!).existsSync(), isTrue);

        // States 3→4: S3 key — after upload, for CachedNetworkImage display.
        arrangeDioSuccess(
          key: 'aquariums/aq-1/f7a3b.webp',
          entityType: 'aquarium',
          entityId: 'aq-1',
        );
        await service.processQueue();

        aquarium.photoKey = uploadCompleted.first.photoKey;
        expect(aquarium.photoKey, 'aquariums/aq-1/f7a3b.webp');

        // Local file has been cleaned up after successful upload.
        final taskId = localKey.substring('local://'.length);
        expect(await queue.fileExists(taskId), isFalse);
      },
    );

    test('local:// key resolves to correct file path for display', () async {
      final service = createUploadService();

      final localKey = await service.queueUpload(
        entityType: 'fish',
        entityId: 'fish-1',
        imageBytes: testImageBytes,
      );
      final taskId = localKey.substring('local://'.length);

      // getLocalImagePath resolves the local:// key to a file path.
      final path = await service.getLocalImagePath(localKey);
      expect(path, isNotNull);
      expect(path, endsWith('$taskId.webp'));
      expect(File(path!).existsSync(), isTrue);

      // File content matches compressed output.
      final fileBytes = File(path).readAsBytesSync();
      expect(fileBytes, equals(compressedWebP));
    });

    test('non-local:// key returns null from getLocalImagePath', () async {
      final service = createUploadService();

      // S3 keys are not resolvable to local files.
      final path = await service.getLocalImagePath('aquariums/aq-1/f7a3b.webp');
      expect(path, isNull);
    });

    test(
      'ChangeTracker excludes local:// and includes S3 keys for all types',
      () async {
        setupEmptyMocks();
        final tracker = createTracker();

        // Aquarium with local:// key.
        final aquarium = AquariumModel(
          id: 'aq-1',
          userId: 'user-1',
          name: 'Test',
          createdAt: DateTime(2025, 6, 15),
          photoKey: 'local://some-uuid',
          synced: false,
        );
        when(
          () => mockAquariumDs.getUnsyncedAquariums(),
        ).thenReturn([aquarium]);

        // Fish with local:// key.
        final fish = FishModel(
          id: 'fish-1',
          aquariumId: 'aq-1',
          speciesId: 'species-1',
          addedAt: DateTime(2025, 6, 15),
          photoKey: 'local://another-uuid',
          synced: false,
        );
        when(() => mockFishDs.getUnsyncedFish()).thenReturn([fish]);

        // User with local:// avatar key.
        final user = UserModel(
          id: 'user-1',
          email: 'test@example.com',
          createdAt: DateTime(2025, 6, 15),
          avatarKey: 'local://avatar-uuid',
          synced: false,
        );
        when(() => mockAuthDs.getUnsyncedUser()).thenReturn(user);

        // All local:// keys should be excluded.
        var changes = tracker.collectAllChanges();
        expect(changes, hasLength(3));

        for (final change in changes) {
          expect(
            change.data.containsKey('photo_key'),
            isFalse,
            reason:
                '${change.entityType.name} should not include local:// photo_key',
          );
          expect(
            change.data.containsKey('avatar_key'),
            isFalse,
            reason:
                '${change.entityType.name} should not include local:// avatar_key',
          );
        }

        // Now replace with S3 keys.
        aquarium.photoKey = 'aquariums/aq-1/f7a3b.webp';
        fish.photoKey = 'fish/fish-1/c4e82.webp';
        user.avatarKey = 'avatars/user-1/d5e6f.webp';

        changes = tracker.collectAllChanges();

        final aquariumChange = changes.firstWhere(
          (c) => c.entityType == EntityType.aquarium,
        );
        expect(aquariumChange.data['photo_key'], 'aquariums/aq-1/f7a3b.webp');

        final fishChange = changes.firstWhere(
          (c) => c.entityType == EntityType.fish,
        );
        expect(fishChange.data['photo_key'], 'fish/fish-1/c4e82.webp');

        final userChange = changes.firstWhere(
          (c) => c.entityType == EntityType.userProfile,
        );
        expect(userChange.data['avatar_key'], 'avatars/user-1/d5e6f.webp');
      },
    );
  });
}
