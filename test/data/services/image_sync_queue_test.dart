import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/data/services/image_sync_queue.dart';
import 'package:fishfeed/data/services/image_upload_task.dart';

void main() {
  late Directory tempDir;
  late ImageSyncQueue queue;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('image_sync_queue_test_');
    queue = ImageSyncQueue(basePath: tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  ImageUploadTask createTestTask({
    String id = 'task-1',
    String entityType = 'aquarium',
    String entityId = 'aq-1',
    String localPath = '/path/to/file.webp',
    DateTime? createdAt,
    ImageUploadStatus status = ImageUploadStatus.pending,
    int retryCount = 0,
    String? errorMessage,
  }) {
    return ImageUploadTask(
      id: id,
      entityType: entityType,
      entityId: entityId,
      localPath: localPath,
      createdAt: createdAt ?? DateTime(2025, 6, 15, 10, 0),
      status: status,
      retryCount: retryCount,
      errorMessage: errorMessage,
    );
  }

  group('Initialization', () {
    test('isInitialized is false before initialize()', () {
      expect(queue.isInitialized, isFalse);
    });

    test('initialize() creates required directories', () async {
      await queue.initialize();

      expect(queue.isInitialized, isTrue);

      final queueDir = Directory('${tempDir.path}/image_queue');
      expect(queueDir.existsSync(), isTrue);

      final filesDir = Directory('${tempDir.path}/image_queue/files');
      expect(filesDir.existsSync(), isTrue);
    });

    test('initialize() creates empty queue.json', () async {
      await queue.initialize();

      final queueFile = File('${tempDir.path}/image_queue/queue.json');
      expect(queueFile.existsSync(), isTrue);

      final content = queueFile.readAsStringSync();
      expect(content, '[]');
    });

    test('initialize() is idempotent (safe to call multiple times)', () async {
      await queue.initialize();
      await queue.initialize(); // second call should be a no-op

      expect(queue.isInitialized, isTrue);
      final queueFile = File('${tempDir.path}/image_queue/queue.json');
      expect(queueFile.readAsStringSync(), '[]');
    });

    test('initialize() does not overwrite existing queue.json', () async {
      // Pre-create the file with existing data.
      final queueDir = Directory('${tempDir.path}/image_queue');
      await queueDir.create(recursive: true);
      final filesDir = Directory('${tempDir.path}/image_queue/files');
      await filesDir.create(recursive: true);

      final queueFile = File('${tempDir.path}/image_queue/queue.json');
      await queueFile.writeAsString('[{"id":"existing"}]');

      // Now initialize — it should not overwrite.
      // Reset the queue to simulate fresh start.
      queue.resetForTesting();
      queue = ImageSyncQueue(basePath: tempDir.path);
      await queue.initialize();

      expect(queueFile.readAsStringSync(), '[{"id":"existing"}]');
    });
  });

  group('Path resolution', () {
    test('basePath returns provided test path', () async {
      final path = await queue.basePath;
      expect(path, tempDir.path);
    });

    test('queueDirPath includes image_queue directory', () async {
      final path = await queue.queueDirPath;
      expect(path, '${tempDir.path}/image_queue');
    });

    test('queueFilePath includes queue.json', () async {
      final path = await queue.queueFilePath;
      expect(path, '${tempDir.path}/image_queue/queue.json');
    });

    test('filesDirPath includes files directory', () async {
      final path = await queue.filesDirPath;
      expect(path, '${tempDir.path}/image_queue/files');
    });
  });

  group('Read/Write operations', () {
    setUp(() async {
      await queue.initialize();
    });

    test('readAll returns empty list from fresh queue', () async {
      final tasks = await queue.readAll();
      expect(tasks, isEmpty);
    });

    test('writeAll and readAll roundtrip single task', () async {
      final task = createTestTask();
      await queue.writeAll([task]);

      final tasks = await queue.readAll();
      expect(tasks.length, 1);
      expect(tasks[0].id, 'task-1');
      expect(tasks[0].entityType, 'aquarium');
      expect(tasks[0].entityId, 'aq-1');
    });

    test('writeAll and readAll roundtrip multiple tasks', () async {
      final tasks = [
        createTestTask(id: 'task-1', entityType: 'aquarium'),
        createTestTask(
          id: 'task-2',
          entityType: 'fish',
          entityId: 'fish-1',
          status: ImageUploadStatus.failed,
          retryCount: 2,
          errorMessage: 'Network error',
        ),
        createTestTask(
          id: 'task-3',
          entityType: 'avatar',
          entityId: 'user-1',
          status: ImageUploadStatus.uploading,
        ),
      ];

      await queue.writeAll(tasks);
      final restored = await queue.readAll();

      expect(restored.length, 3);
      expect(restored[0].id, 'task-1');
      expect(restored[1].id, 'task-2');
      expect(restored[1].status, ImageUploadStatus.failed);
      expect(restored[1].retryCount, 2);
      expect(restored[1].errorMessage, 'Network error');
      expect(restored[2].id, 'task-3');
      expect(restored[2].status, ImageUploadStatus.uploading);
    });

    test('writeAll overwrites existing data', () async {
      await queue.writeAll([createTestTask(id: 'old-task')]);
      await queue.writeAll([createTestTask(id: 'new-task')]);

      final tasks = await queue.readAll();
      expect(tasks.length, 1);
      expect(tasks[0].id, 'new-task');
    });

    test('writeAll with empty list clears queue', () async {
      await queue.writeAll([createTestTask()]);
      await queue.writeAll([]);

      final tasks = await queue.readAll();
      expect(tasks, isEmpty);
    });

    test('readAll preserves task field values after persistence', () async {
      final original = ImageUploadTask(
        id: 'persist-test',
        entityType: 'fish',
        entityId: 'fish-42',
        localPath: '/storage/files/persist-test.webp',
        createdAt: DateTime(2025, 12, 25, 8, 15, 30),
        status: ImageUploadStatus.failed,
        retryCount: 4,
        errorMessage: 'Connection refused',
      );

      await queue.writeAll([original]);
      final restored = (await queue.readAll()).first;

      expect(restored.id, original.id);
      expect(restored.entityType, original.entityType);
      expect(restored.entityId, original.entityId);
      expect(restored.localPath, original.localPath);
      expect(restored.createdAt, original.createdAt);
      expect(restored.status, original.status);
      expect(restored.retryCount, original.retryCount);
      expect(restored.errorMessage, original.errorMessage);
    });
  });

  group('File operations', () {
    setUp(() async {
      await queue.initialize();
    });

    test('getFilePath returns correct path format', () async {
      final path = await queue.getFilePath('abc-def-123');
      expect(path, '${tempDir.path}/image_queue/files/abc-def-123.webp');
    });

    test('fileExists returns false when file does not exist', () async {
      final exists = await queue.fileExists('nonexistent');
      expect(exists, isFalse);
    });

    test('fileExists returns true when file exists', () async {
      final path = await queue.getFilePath('test-file');
      await File(path).writeAsBytes([1, 2, 3]);

      final exists = await queue.fileExists('test-file');
      expect(exists, isTrue);
    });

    test('deleteFile returns false when file does not exist', () async {
      final deleted = await queue.deleteFile('nonexistent');
      expect(deleted, isFalse);
    });

    test('deleteFile removes existing file and returns true', () async {
      final path = await queue.getFilePath('to-delete');
      await File(path).writeAsBytes([1, 2, 3]);

      final deleted = await queue.deleteFile('to-delete');
      expect(deleted, isTrue);
      expect(File(path).existsSync(), isFalse);
    });

    test('fileCount returns 0 for empty files directory', () async {
      final count = await queue.fileCount;
      expect(count, 0);
    });

    test('fileCount returns correct count', () async {
      final filesDir = await queue.filesDirPath;
      await File('$filesDir/file1.webp').writeAsBytes([1]);
      await File('$filesDir/file2.webp').writeAsBytes([2]);
      await File('$filesDir/file3.webp').writeAsBytes([3]);

      final count = await queue.fileCount;
      expect(count, 3);
    });
  });

  group('State guard', () {
    test('readAll throws StateError before initialization', () async {
      expect(
        () => queue.readAll(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('not been initialized'),
          ),
        ),
      );
    });

    test('writeAll throws StateError before initialization', () async {
      expect(() => queue.writeAll([]), throwsA(isA<StateError>()));
    });

    test('fileExists throws StateError before initialization', () async {
      expect(() => queue.fileExists('task-1'), throwsA(isA<StateError>()));
    });

    test('deleteFile throws StateError before initialization', () async {
      expect(() => queue.deleteFile('task-1'), throwsA(isA<StateError>()));
    });

    test('fileCount throws StateError before initialization', () async {
      expect(() => queue.fileCount, throwsA(isA<StateError>()));
    });
  });

  group('Persistence across instances', () {
    test('data persists after creating new instance', () async {
      await queue.initialize();
      await queue.writeAll([
        createTestTask(id: 'persist-1'),
        createTestTask(id: 'persist-2'),
      ]);

      // Simulate "restart" by creating new instance with same path.
      final newQueue = ImageSyncQueue(basePath: tempDir.path);
      await newQueue.initialize();

      final tasks = await newQueue.readAll();
      expect(tasks.length, 2);
      expect(tasks[0].id, 'persist-1');
      expect(tasks[1].id, 'persist-2');
    });

    test('files persist after creating new instance', () async {
      await queue.initialize();
      final path = await queue.getFilePath('persistent-file');
      await File(path).writeAsBytes([10, 20, 30]);

      final newQueue = ImageSyncQueue(basePath: tempDir.path);
      await newQueue.initialize();

      final exists = await newQueue.fileExists('persistent-file');
      expect(exists, isTrue);
    });
  });

  group('resetForTesting', () {
    test('resets initialized state', () async {
      await queue.initialize();
      expect(queue.isInitialized, isTrue);

      queue.resetForTesting();
      expect(queue.isInitialized, isFalse);
    });
  });
}
