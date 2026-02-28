import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import 'package:fishfeed/data/services/image_sync_queue.dart';
import 'package:fishfeed/data/services/image_upload_service.dart';
import 'package:fishfeed/data/services/image_upload_task.dart';
import 'package:fishfeed/services/image_processing_service.dart';

// --- Mocks ---

class MockImageSyncQueue extends Mock implements ImageSyncQueue {}

class MockImageProcessingService extends Mock
    implements ImageProcessingService {}

class MockUuid extends Mock implements Uuid {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockImageSyncQueue mockQueue;
  late MockImageProcessingService mockImageProcessor;
  late MockUuid mockUuid;
  late MockDio mockDio;
  late ImageUploadService service;

  // Tracks calls to onUploadComplete.
  late List<({String entityType, String entityId, String photoKey})>
  uploadCompleteCallLog;

  Future<void> mockOnUploadComplete({
    required String entityType,
    required String entityId,
    required String photoKey,
  }) async {
    uploadCompleteCallLog.add((
      entityType: entityType,
      entityId: entityId,
      photoKey: photoKey,
    ));
  }

  const testTaskId = '550e8400-e29b-41d4-a716-446655440000';
  final testImageBytes = Uint8List.fromList([
    0xFF,
    0xD8,
    0xFF,
    0xE0,
    0x00,
    0x10,
  ]);
  final compressedBytes = Uint8List.fromList([
    0x52,
    0x49,
    0x46,
    0x46,
    0x00,
    0x04,
  ]);

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(FormData());
    registerFallbackValue(Options());
  });

  setUp(() {
    mockQueue = MockImageSyncQueue();
    mockImageProcessor = MockImageProcessingService();
    mockUuid = MockUuid();
    mockDio = MockDio();
    uploadCompleteCallLog = [];

    when(() => mockUuid.v4()).thenReturn(testTaskId);

    service = ImageUploadService(
      queue: mockQueue,
      imageProcessor: mockImageProcessor,
      dio: mockDio,
      onUploadComplete: mockOnUploadComplete,
      uuid: mockUuid,
      delayFn: (_) async {}, // No-op delay for tests.
    );
  });

  /// Sets up default mocks for a successful queueUpload flow.
  void arrangeSuccessfulUpload({
    String entityType = 'aquarium',
    String entityId = 'aq-1',
  }) {
    when(
      () => mockImageProcessor.compressToWebP(
        any(),
        quality: any(named: 'quality'),
        maxWidth: any(named: 'maxWidth'),
      ),
    ).thenAnswer(
      (_) async => CompressionResult(
        bytes: compressedBytes,
        originalSize: testImageBytes.length,
        compressedSize: compressedBytes.length,
      ),
    );

    when(
      () => mockQueue.enqueue(
        taskId: any(named: 'taskId'),
        entityType: any(named: 'entityType'),
        entityId: any(named: 'entityId'),
        imageBytes: any(named: 'imageBytes'),
      ),
    ).thenAnswer(
      (_) async => ImageUploadTask(
        id: testTaskId,
        entityType: entityType,
        entityId: entityId,
        localPath: '/fake/path/$testTaskId.webp',
        createdAt: DateTime(2025, 6, 15),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // queueUpload
  // ---------------------------------------------------------------------------
  group('queueUpload', () {
    test('returns local:// key in format local://uuid', () async {
      arrangeSuccessfulUpload();

      final result = await service.queueUpload(
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: testImageBytes,
      );

      expect(result, 'local://$testTaskId');
      expect(result, startsWith('local://'));
      // Verify the part after local:// looks like a UUID.
      final uuidPart = result.substring('local://'.length);
      expect(uuidPart, hasLength(36)); // Standard UUID format.
      expect(
        uuidPart,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test(
      'calls compressToWebP with correct per-type settings for aquarium',
      () async {
        arrangeSuccessfulUpload(entityType: 'aquarium');

        await service.queueUpload(
          entityType: 'aquarium',
          entityId: 'aq-1',
          imageBytes: testImageBytes,
        );

        verify(
          () => mockImageProcessor.compressToWebP(
            testImageBytes,
            quality: 80,
            maxWidth: 2048,
          ),
        ).called(1);
      },
    );

    test(
      'calls compressToWebP with correct per-type settings for fish',
      () async {
        arrangeSuccessfulUpload(entityType: 'fish');

        await service.queueUpload(
          entityType: 'fish',
          entityId: 'fish-1',
          imageBytes: testImageBytes,
        );

        verify(
          () => mockImageProcessor.compressToWebP(
            testImageBytes,
            quality: 80,
            maxWidth: 2048,
          ),
        ).called(1);
      },
    );

    test(
      'calls compressToWebP with correct per-type settings for avatar',
      () async {
        arrangeSuccessfulUpload(entityType: 'avatar');

        await service.queueUpload(
          entityType: 'avatar',
          entityId: 'user-1',
          imageBytes: testImageBytes,
        );

        verify(
          () => mockImageProcessor.compressToWebP(
            testImageBytes,
            quality: 90,
            maxWidth: 512,
          ),
        ).called(1);
      },
    );

    test('calls ImageSyncQueue.enqueue with compressed bytes', () async {
      arrangeSuccessfulUpload();

      await service.queueUpload(
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: testImageBytes,
      );

      verify(
        () => mockQueue.enqueue(
          taskId: testTaskId,
          entityType: 'aquarium',
          entityId: 'aq-1',
          imageBytes: compressedBytes,
        ),
      ).called(1);
    });

    test('passes generated UUID as taskId to enqueue', () async {
      const customUuid = 'custom-uuid-1234-5678-abcdef012345';
      when(() => mockUuid.v4()).thenReturn(customUuid);

      arrangeSuccessfulUpload();

      final result = await service.queueUpload(
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: testImageBytes,
      );

      expect(result, 'local://$customUuid');
      verify(
        () => mockQueue.enqueue(
          taskId: customUuid,
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          imageBytes: any(named: 'imageBytes'),
        ),
      ).called(1);
    });

    test('throws ArgumentError for invalid entityType', () async {
      expect(
        () => service.queueUpload(
          entityType: 'invalid',
          entityId: 'x',
          imageBytes: testImageBytes,
        ),
        throwsA(
          isA<ArgumentError>().having((e) => e.name, 'name', 'entityType'),
        ),
      );

      // Verify no calls were made to compression or queue.
      verifyNever(
        () => mockImageProcessor.compressToWebP(
          any(),
          quality: any(named: 'quality'),
          maxWidth: any(named: 'maxWidth'),
        ),
      );
      verifyNever(
        () => mockQueue.enqueue(
          taskId: any(named: 'taskId'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          imageBytes: any(named: 'imageBytes'),
        ),
      );
    });

    test('throws ArgumentError for empty entityType', () async {
      expect(
        () => service.queueUpload(
          entityType: '',
          entityId: 'x',
          imageBytes: testImageBytes,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('propagates ImageProcessingException from compressToWebP', () async {
      when(
        () => mockImageProcessor.compressToWebP(
          any(),
          quality: any(named: 'quality'),
          maxWidth: any(named: 'maxWidth'),
        ),
      ).thenThrow(const ImageProcessingException('Failed to decode'));

      expect(
        () => service.queueUpload(
          entityType: 'aquarium',
          entityId: 'aq-1',
          imageBytes: testImageBytes,
        ),
        throwsA(isA<ImageProcessingException>()),
      );
    });

    test('propagates StateError from uninitialized queue', () async {
      when(
        () => mockImageProcessor.compressToWebP(
          any(),
          quality: any(named: 'quality'),
          maxWidth: any(named: 'maxWidth'),
        ),
      ).thenAnswer(
        (_) async => CompressionResult(
          bytes: compressedBytes,
          originalSize: testImageBytes.length,
          compressedSize: compressedBytes.length,
        ),
      );

      when(
        () => mockQueue.enqueue(
          taskId: any(named: 'taskId'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          imageBytes: any(named: 'imageBytes'),
        ),
      ).thenThrow(StateError('ImageSyncQueue has not been initialized.'));

      expect(
        () => service.queueUpload(
          entityType: 'aquarium',
          entityId: 'aq-1',
          imageBytes: testImageBytes,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getLocalImagePath
  // ---------------------------------------------------------------------------
  group('getLocalImagePath', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('upload_service_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'returns correct path for valid local:// key with existing file',
      () async {
        // Create a real file at the expected path.
        final filePath = '${tempDir.path}/$testTaskId.webp';
        File(filePath).writeAsBytesSync(compressedBytes);

        when(
          () => mockQueue.getFilePath(testTaskId),
        ).thenAnswer((_) async => filePath);

        final result = await service.getLocalImagePath('local://$testTaskId');

        expect(result, filePath);
      },
    );

    test('returns null when file does not exist', () async {
      final filePath = '${tempDir.path}/nonexistent.webp';

      when(
        () => mockQueue.getFilePath(testTaskId),
      ).thenAnswer((_) async => filePath);

      final result = await service.getLocalImagePath('local://$testTaskId');

      expect(result, isNull);
    });

    test('returns null for key without local:// prefix', () async {
      final result = await service.getLocalImagePath(
        'aquariums/abc/f7a3b.webp',
      );

      expect(result, isNull);
      // Should not call queue at all.
      verifyNever(() => mockQueue.getFilePath(any()));
    });

    test('returns null for empty key after local:// prefix', () async {
      final result = await service.getLocalImagePath('local://');

      expect(result, isNull);
      verifyNever(() => mockQueue.getFilePath(any()));
    });

    test('returns null for key with only local:// (no task ID)', () async {
      final result = await service.getLocalImagePath('local://');

      expect(result, isNull);
    });

    test('extracts correct taskId from local:// key', () async {
      const taskId = 'abc-def-123-456';
      final filePath = '${tempDir.path}/$taskId.webp';
      File(filePath).writeAsBytesSync(compressedBytes);

      when(
        () => mockQueue.getFilePath(taskId),
      ).thenAnswer((_) async => filePath);

      final result = await service.getLocalImagePath('local://$taskId');

      expect(result, filePath);
      verify(() => mockQueue.getFilePath(taskId)).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // compressionSettings
  // ---------------------------------------------------------------------------
  group('compressionSettings', () {
    test('has settings for all valid entity types', () {
      for (final type in ImageUploadTask.validEntityTypes) {
        expect(
          ImageUploadService.compressionSettings.containsKey(type),
          isTrue,
          reason: 'Missing compression settings for "$type"',
        );
      }
    });

    test('avatar has quality 90 and maxWidth 512', () {
      final config = ImageUploadService.compressionSettings['avatar']!;
      expect(config.quality, 90);
      expect(config.maxWidth, 512);
    });

    test('aquarium has quality 80 and maxWidth 2048', () {
      final config = ImageUploadService.compressionSettings['aquarium']!;
      expect(config.quality, 80);
      expect(config.maxWidth, 2048);
    });

    test('fish has quality 80 and maxWidth 2048', () {
      final config = ImageUploadService.compressionSettings['fish']!;
      expect(config.quality, 80);
      expect(config.maxWidth, 2048);
    });
  });

  // ---------------------------------------------------------------------------
  // ImageCompressionConfig
  // ---------------------------------------------------------------------------
  group('ImageCompressionConfig', () {
    test('stores quality and maxWidth', () {
      const config = ImageCompressionConfig(quality: 95, maxWidth: 1024);
      expect(config.quality, 95);
      expect(config.maxWidth, 1024);
    });
  });

  // ---------------------------------------------------------------------------
  // processQueue
  // ---------------------------------------------------------------------------
  group('processQueue', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('process_queue_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    /// Creates a real file and returns an [ImageUploadTask] pointing to it.
    ImageUploadTask createTaskWithFile({
      String id = testTaskId,
      String entityType = 'aquarium',
      String entityId = 'aq-1',
    }) {
      final filePath = '${tempDir.path}/$id.webp';
      File(filePath).writeAsBytesSync(compressedBytes);
      return ImageUploadTask(
        id: id,
        entityType: entityType,
        entityId: entityId,
        localPath: filePath,
        createdAt: DateTime(2025, 6, 15),
      );
    }

    /// Mocks a successful Dio POST response with a given S3 key.
    void arrangeDioSuccess({String key = 'aquariums/aq-1/f7a3b2c1.webp'}) {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'key': key, 'entity_type': 'aquarium', 'entity_id': 'aq-1'},
          statusCode: 201,
          requestOptions: RequestOptions(),
        ),
      );
    }

    /// Mocks Dio POST to throw a DioException with the given status code.
    void arrangeDioError({
      int? statusCode,
      DioExceptionType type = DioExceptionType.badResponse,
    }) {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          type: type,
          response: statusCode != null
              ? Response(
                  statusCode: statusCode,
                  requestOptions: RequestOptions(),
                )
              : null,
          requestOptions: RequestOptions(),
        ),
      );
    }

    test('exits immediately when queue is empty', () async {
      when(() => mockQueue.dequeue()).thenAnswer((_) async => null);

      await service.processQueue();

      verify(() => mockQueue.dequeue()).called(1);
      verifyNever(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      );
    });

    test('processes single task successfully', () async {
      final task = createTaskWithFile();
      arrangeDioSuccess();
      when(() => mockQueue.markComplete(any())).thenAnswer((_) async => true);

      // First dequeue returns task, second returns null.
      var dequeueCount = 0;
      when(() => mockQueue.dequeue()).thenAnswer((_) async {
        dequeueCount++;
        return dequeueCount == 1 ? task : null;
      });

      await service.processQueue();

      // Verify upload was called.
      verify(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).called(1);

      // Verify onUploadComplete was called with correct params.
      expect(uploadCompleteCallLog, hasLength(1));
      expect(uploadCompleteCallLog.first.entityType, 'aquarium');
      expect(uploadCompleteCallLog.first.entityId, 'aq-1');
      expect(
        uploadCompleteCallLog.first.photoKey,
        'aquariums/aq-1/f7a3b2c1.webp',
      );

      // Verify markComplete was called.
      verify(() => mockQueue.markComplete(testTaskId)).called(1);
    });

    test('processes multiple tasks until queue is empty', () async {
      final task1 = createTaskWithFile(id: 'task-1', entityId: 'aq-1');
      final task2 = createTaskWithFile(id: 'task-2', entityId: 'aq-2');

      arrangeDioSuccess();
      when(() => mockQueue.markComplete(any())).thenAnswer((_) async => true);

      var dequeueCount = 0;
      when(() => mockQueue.dequeue()).thenAnswer((_) async {
        dequeueCount++;
        return switch (dequeueCount) {
          1 => task1,
          2 => task2,
          _ => null,
        };
      });

      await service.processQueue();

      expect(uploadCompleteCallLog, hasLength(2));
      verify(() => mockQueue.markComplete('task-1')).called(1);
      verify(() => mockQueue.markComplete('task-2')).called(1);
    });

    test('calls markFailed on upload failure', () async {
      final task = createTaskWithFile();
      arrangeDioError(statusCode: 400);
      when(
        () => mockQueue.markFailed(any(), any()),
      ).thenAnswer((_) async => true);

      var dequeueCount = 0;
      when(() => mockQueue.dequeue()).thenAnswer((_) async {
        dequeueCount++;
        return dequeueCount == 1 ? task : null;
      });

      await service.processQueue();

      // Should not call onUploadComplete or markComplete.
      expect(uploadCompleteCallLog, isEmpty);
      verifyNever(() => mockQueue.markComplete(any()));

      // Should call markFailed with the error.
      verify(() => mockQueue.markFailed(testTaskId, any())).called(1);
    });

    test('continues processing after a failed task', () async {
      final failTask = createTaskWithFile(id: 'fail-task');
      final successTask = createTaskWithFile(
        id: 'success-task',
        entityId: 'aq-2',
      );

      when(
        () => mockQueue.markFailed(any(), any()),
      ).thenAnswer((_) async => true);
      when(() => mockQueue.markComplete(any())).thenAnswer((_) async => true);

      var dequeueCount = 0;
      when(() => mockQueue.dequeue()).thenAnswer((_) async {
        dequeueCount++;
        return switch (dequeueCount) {
          1 => failTask,
          2 => successTask,
          _ => null,
        };
      });

      // First call fails (400), second succeeds.
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
              statusCode: 400,
              requestOptions: RequestOptions(),
            ),
            requestOptions: RequestOptions(),
          );
        }
        return Response(
          data: {
            'key': 'aquariums/aq-2/abc.webp',
            'entity_type': 'aquarium',
            'entity_id': 'aq-2',
          },
          statusCode: 201,
          requestOptions: RequestOptions(),
        );
      });

      await service.processQueue();

      verify(() => mockQueue.markFailed('fail-task', any())).called(1);
      verify(() => mockQueue.markComplete('success-task')).called(1);
      expect(uploadCompleteCallLog, hasLength(1));
    });

    test('calls markFailed when onUploadComplete throws', () async {
      final task = createTaskWithFile();
      arrangeDioSuccess();
      when(
        () => mockQueue.markFailed(any(), any()),
      ).thenAnswer((_) async => true);

      var dequeueCount = 0;
      when(() => mockQueue.dequeue()).thenAnswer((_) async {
        dequeueCount++;
        return dequeueCount == 1 ? task : null;
      });

      // Use a service with a failing onUploadComplete.
      final failingService = ImageUploadService(
        queue: mockQueue,
        imageProcessor: mockImageProcessor,
        dio: mockDio,
        onUploadComplete:
            ({
              required String entityType,
              required String entityId,
              required String photoKey,
            }) async {
              throw Exception('DB update failed');
            },
        uuid: mockUuid,
        delayFn: (_) async {},
      );

      await failingService.processQueue();

      verify(() => mockQueue.markFailed(testTaskId, any())).called(1);
      verifyNever(() => mockQueue.markComplete(any()));
    });
  });

  // ---------------------------------------------------------------------------
  // _uploadToServer retry logic
  // ---------------------------------------------------------------------------
  group('retry logic', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('retry_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    ImageUploadTask createTaskWithFile({
      String id = testTaskId,
      String entityType = 'aquarium',
      String entityId = 'aq-1',
    }) {
      final filePath = '${tempDir.path}/$id.webp';
      File(filePath).writeAsBytesSync(compressedBytes);
      return ImageUploadTask(
        id: id,
        entityType: entityType,
        entityId: entityId,
        localPath: filePath,
        createdAt: DateTime(2025, 6, 15),
      );
    }

    test(
      'retries on 500 server error and succeeds on second attempt',
      () async {
        final task = createTaskWithFile();
        when(() => mockQueue.markComplete(any())).thenAnswer((_) async => true);

        var dequeueCount = 0;
        when(() => mockQueue.dequeue()).thenAnswer((_) async {
          dequeueCount++;
          return dequeueCount == 1 ? task : null;
        });

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
              'key': 'aquariums/aq-1/f7a3b.webp',
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
        verify(() => mockQueue.markComplete(testTaskId)).called(1);
      },
    );

    test('retries on connection timeout error', () async {
      final task = createTaskWithFile();
      when(() => mockQueue.markComplete(any())).thenAnswer((_) async => true);

      var dequeueCount = 0;
      when(() => mockQueue.dequeue()).thenAnswer((_) async {
        dequeueCount++;
        return dequeueCount == 1 ? task : null;
      });

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
            'key': 'aquariums/aq-1/f7a3b.webp',
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
      verify(() => mockQueue.markComplete(testTaskId)).called(1);
    });

    test('retries on connection error', () async {
      final task = createTaskWithFile();
      when(() => mockQueue.markComplete(any())).thenAnswer((_) async => true);

      var dequeueCount = 0;
      when(() => mockQueue.dequeue()).thenAnswer((_) async {
        dequeueCount++;
        return dequeueCount == 1 ? task : null;
      });

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
            type: DioExceptionType.connectionError,
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
      verify(() => mockQueue.markComplete(testTaskId)).called(1);
    });

    test('does NOT retry on 400 client error', () async {
      final task = createTaskWithFile();
      when(
        () => mockQueue.markFailed(any(), any()),
      ).thenAnswer((_) async => true);

      var dequeueCount = 0;
      when(() => mockQueue.dequeue()).thenAnswer((_) async {
        dequeueCount++;
        return dequeueCount == 1 ? task : null;
      });

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
      verify(() => mockQueue.markFailed(testTaskId, any())).called(1);
    });

    test('does NOT retry on 403 forbidden error', () async {
      final task = createTaskWithFile();
      when(
        () => mockQueue.markFailed(any(), any()),
      ).thenAnswer((_) async => true);

      var dequeueCount = 0;
      when(() => mockQueue.dequeue()).thenAnswer((_) async {
        dequeueCount++;
        return dequeueCount == 1 ? task : null;
      });

      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          response: Response(statusCode: 403, requestOptions: RequestOptions()),
          requestOptions: RequestOptions(),
        ),
      );

      await service.processQueue();

      verify(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).called(1);
      verify(() => mockQueue.markFailed(testTaskId, any())).called(1);
    });

    test('does NOT retry on 413 content too large error', () async {
      final task = createTaskWithFile();
      when(
        () => mockQueue.markFailed(any(), any()),
      ).thenAnswer((_) async => true);

      var dequeueCount = 0;
      when(() => mockQueue.dequeue()).thenAnswer((_) async {
        dequeueCount++;
        return dequeueCount == 1 ? task : null;
      });

      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          response: Response(statusCode: 413, requestOptions: RequestOptions()),
          requestOptions: RequestOptions(),
        ),
      );

      await service.processQueue();

      verify(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test(
      'exhausts all ${ImageUploadTask.maxRetries + 1} attempts on persistent '
      '5xx then markFailed',
      () async {
        final task = createTaskWithFile();
        when(
          () => mockQueue.markFailed(any(), any()),
        ).thenAnswer((_) async => true);

        var dequeueCount = 0;
        when(() => mockQueue.dequeue()).thenAnswer((_) async {
          dequeueCount++;
          return dequeueCount == 1 ? task : null;
        });

        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 502,
              requestOptions: RequestOptions(),
            ),
            requestOptions: RequestOptions(),
          ),
        );

        await service.processQueue();

        // 1 initial + 5 retries = 6 total attempts.
        verify(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).called(ImageUploadService.maxAttempts);
        verify(() => mockQueue.markFailed(testTaskId, any())).called(1);
      },
    );

    test('verifies correct exponential backoff delays', () async {
      final task = createTaskWithFile();
      when(
        () => mockQueue.markFailed(any(), any()),
      ).thenAnswer((_) async => true);

      var dequeueCount = 0;
      when(() => mockQueue.dequeue()).thenAnswer((_) async {
        dequeueCount++;
        return dequeueCount == 1 ? task : null;
      });

      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          response: Response(statusCode: 500, requestOptions: RequestOptions()),
          requestOptions: RequestOptions(),
        ),
      );

      // Track delays.
      final recordedDelays = <Duration>[];
      final delayTrackingService = ImageUploadService(
        queue: mockQueue,
        imageProcessor: mockImageProcessor,
        dio: mockDio,
        onUploadComplete: mockOnUploadComplete,
        uuid: mockUuid,
        delayFn: (duration) async {
          recordedDelays.add(duration);
        },
      );

      await delayTrackingService.processQueue();

      // 5 delays between 6 attempts: 1s, 2s, 4s, 8s, 16s.
      expect(recordedDelays, hasLength(ImageUploadTask.maxRetries));
      expect(recordedDelays[0], const Duration(seconds: 1));
      expect(recordedDelays[1], const Duration(seconds: 2));
      expect(recordedDelays[2], const Duration(seconds: 4));
      expect(recordedDelays[3], const Duration(seconds: 8));
      expect(recordedDelays[4], const Duration(seconds: 16));
    });

    test('posts to correct endpoint with multipart form data', () async {
      final task = createTaskWithFile();
      when(() => mockQueue.markComplete(any())).thenAnswer((_) async => true);

      var dequeueCount = 0;
      when(() => mockQueue.dequeue()).thenAnswer((_) async {
        dequeueCount++;
        return dequeueCount == 1 ? task : null;
      });

      String? capturedEndpoint;
      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((invocation) async {
        capturedEndpoint = invocation.positionalArguments[0] as String;
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

      expect(capturedEndpoint, '/images/upload');
    });
  });

  // ---------------------------------------------------------------------------
  // retryFailed
  // ---------------------------------------------------------------------------
  group('retryFailed', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('retry_failed_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    ImageUploadTask createTaskWithFile({
      required String id,
      ImageUploadStatus status = ImageUploadStatus.pending,
      int retryCount = 0,
      String entityType = 'aquarium',
      String entityId = 'aq-1',
    }) {
      final filePath = '${tempDir.path}/$id.webp';
      File(filePath).writeAsBytesSync(compressedBytes);
      return ImageUploadTask(
        id: id,
        entityType: entityType,
        entityId: entityId,
        localPath: filePath,
        createdAt: DateTime(2025, 6, 15),
        status: status,
        retryCount: retryCount,
      );
    }

    test('resets eligible failed tasks and returns count', () async {
      final failedTask = createTaskWithFile(
        id: 'failed-1',
        status: ImageUploadStatus.failed,
        retryCount: 1,
      );
      final pendingTask = createTaskWithFile(id: 'pending-1');

      when(
        () => mockQueue.readAll(),
      ).thenAnswer((_) async => [failedTask, pendingTask]);
      when(() => mockQueue.writeAll(any())).thenAnswer((_) async {});

      // processQueue will be called after reset — mock empty dequeue.
      when(() => mockQueue.dequeue()).thenAnswer((_) async => null);

      final resetCount = await service.retryFailed();

      expect(resetCount, 1);
      verify(() => mockQueue.writeAll(any())).called(1);
    });

    test('does not reset tasks that exhausted all retries', () async {
      final exhaustedTask = createTaskWithFile(
        id: 'exhausted-1',
        status: ImageUploadStatus.failed,
        retryCount: ImageUploadTask.maxRetries, // canRetry == false
      );

      when(() => mockQueue.readAll()).thenAnswer((_) async => [exhaustedTask]);

      final resetCount = await service.retryFailed();

      expect(resetCount, 0);
      // Should NOT write or process since nothing was reset.
      verifyNever(() => mockQueue.writeAll(any()));
    });

    test('does not process queue when no tasks were reset', () async {
      when(() => mockQueue.readAll()).thenAnswer((_) async => []);

      final resetCount = await service.retryFailed();

      expect(resetCount, 0);
      verifyNever(() => mockQueue.dequeue());
    });

    test('calls processQueue after resetting tasks', () async {
      final failedTask = createTaskWithFile(
        id: 'retry-me',
        status: ImageUploadStatus.failed,
        retryCount: 2,
      );

      when(() => mockQueue.readAll()).thenAnswer((_) async => [failedTask]);
      when(() => mockQueue.writeAll(any())).thenAnswer((_) async {});
      when(() => mockQueue.dequeue()).thenAnswer((_) async => null);

      await service.retryFailed();

      // processQueue was called (verified by dequeue being called).
      verify(() => mockQueue.dequeue()).called(1);
    });

    test('resets multiple failed tasks', () async {
      final failed1 = createTaskWithFile(
        id: 'f1',
        status: ImageUploadStatus.failed,
        retryCount: 0,
      );
      final failed2 = createTaskWithFile(
        id: 'f2',
        status: ImageUploadStatus.failed,
        retryCount: 3,
      );
      final exhausted = createTaskWithFile(
        id: 'f3',
        status: ImageUploadStatus.failed,
        retryCount: ImageUploadTask.maxRetries,
      );

      when(
        () => mockQueue.readAll(),
      ).thenAnswer((_) async => [failed1, failed2, exhausted]);
      when(() => mockQueue.writeAll(any())).thenAnswer((_) async {});
      when(() => mockQueue.dequeue()).thenAnswer((_) async => null);

      final resetCount = await service.retryFailed();

      // f1 and f2 are retryable, f3 is exhausted.
      expect(resetCount, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // maxAttempts
  // ---------------------------------------------------------------------------
  group('maxAttempts', () {
    test('equals maxRetries + 1', () {
      expect(ImageUploadService.maxAttempts, ImageUploadTask.maxRetries + 1);
    });

    test('is 6 (1 initial + 5 retries)', () {
      expect(ImageUploadService.maxAttempts, 6);
    });
  });
}
