import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/data/services/image_sync_queue.dart';
import 'package:fishfeed/data/services/image_upload_task.dart';

void main() {
  late Directory tempDir;
  late ImageSyncQueue queue;

  /// Fake image bytes (not real WebP, sufficient for file I/O tests).
  final fakeImageBytes = Uint8List.fromList([0x52, 0x49, 0x46, 0x46]);

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('image_sync_queue_crud_');
    queue = ImageSyncQueue(basePath: tempDir.path);
    await queue.initialize();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // ---------------------------------------------------------------------------
  // enqueue
  // ---------------------------------------------------------------------------
  group('enqueue', () {
    test('creates task and saves image file', () async {
      final task = await queue.enqueue(
        taskId: 'task-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );

      expect(task.id, 'task-1');
      expect(task.entityType, 'aquarium');
      expect(task.entityId, 'aq-1');
      expect(task.status, ImageUploadStatus.pending);
      expect(task.retryCount, 0);
      expect(task.errorMessage, isNull);

      // File should exist.
      final fileExists = await queue.fileExists('task-1');
      expect(fileExists, isTrue);

      // File contents should match.
      final filePath = await queue.getFilePath('task-1');
      final savedBytes = await File(filePath).readAsBytes();
      expect(savedBytes, fakeImageBytes);
    });

    test('task appears in readAll()', () async {
      await queue.enqueue(
        taskId: 'task-1',
        entityType: 'fish',
        entityId: 'fish-1',
        imageBytes: fakeImageBytes,
      );

      final tasks = await queue.readAll();
      expect(tasks.length, 1);
      expect(tasks[0].id, 'task-1');
      expect(tasks[0].entityType, 'fish');
    });

    test('sets localPath to files directory', () async {
      final task = await queue.enqueue(
        taskId: 'task-1',
        entityType: 'avatar',
        entityId: 'user-1',
        imageBytes: fakeImageBytes,
      );

      final expectedPath = await queue.getFilePath('task-1');
      expect(task.localPath, expectedPath);
    });

    test('accepts custom createdAt for testing', () async {
      final customTime = DateTime(2025, 3, 15, 12, 0);
      final task = await queue.enqueue(
        taskId: 'task-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
        createdAt: customTime,
      );

      expect(task.createdAt, customTime);
    });

    test('supports multiple enqueues', () async {
      await queue.enqueue(
        taskId: 'task-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );
      await queue.enqueue(
        taskId: 'task-2',
        entityType: 'fish',
        entityId: 'fish-1',
        imageBytes: fakeImageBytes,
      );

      final tasks = await queue.readAll();
      expect(tasks.length, 2);
      expect(tasks[0].id, 'task-1');
      expect(tasks[1].id, 'task-2');

      final count = await queue.fileCount;
      expect(count, 2);
    });

    test('throws ArgumentError for invalid entityType', () async {
      expect(
        () => queue.enqueue(
          taskId: 'task-1',
          entityType: 'invalid_type',
          entityId: 'x',
          imageBytes: fakeImageBytes,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Must be one of'),
          ),
        ),
      );
    });

    test('throws StateError for duplicate taskId', () async {
      await queue.enqueue(
        taskId: 'task-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );

      expect(
        () => queue.enqueue(
          taskId: 'task-1',
          entityType: 'fish',
          entityId: 'fish-1',
          imageBytes: fakeImageBytes,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('already exists'),
          ),
        ),
      );
    });

    test('throws StateError before initialization', () {
      final uninitQueue = ImageSyncQueue(basePath: tempDir.path);
      uninitQueue.resetForTesting();

      expect(
        () => uninitQueue.enqueue(
          taskId: 'task-1',
          entityType: 'aquarium',
          entityId: 'aq-1',
          imageBytes: fakeImageBytes,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // dequeue
  // ---------------------------------------------------------------------------
  group('dequeue', () {
    test('returns oldest pending task', () async {
      await queue.enqueue(
        taskId: 'task-newer',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
        createdAt: DateTime(2025, 6, 15, 12, 0),
      );
      await queue.enqueue(
        taskId: 'task-older',
        entityType: 'fish',
        entityId: 'fish-1',
        imageBytes: fakeImageBytes,
        createdAt: DateTime(2025, 6, 15, 10, 0),
      );

      final task = await queue.dequeue();
      expect(task, isNotNull);
      expect(task!.id, 'task-older');
    });

    test('marks dequeued task as uploading', () async {
      await queue.enqueue(
        taskId: 'task-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );

      final task = await queue.dequeue();
      expect(task!.status, ImageUploadStatus.uploading);

      // Verify persistence.
      final tasks = await queue.readAll();
      expect(tasks[0].status, ImageUploadStatus.uploading);
    });

    test('returns null when no pending tasks', () async {
      final task = await queue.dequeue();
      expect(task, isNull);
    });

    test('skips failed and uploading tasks', () async {
      // Enqueue then manually set statuses via writeAll.
      await queue.enqueue(
        taskId: 'task-failed',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
        createdAt: DateTime(2025, 1, 1),
      );
      await queue.enqueue(
        taskId: 'task-uploading',
        entityType: 'fish',
        entityId: 'fish-1',
        imageBytes: fakeImageBytes,
        createdAt: DateTime(2025, 1, 2),
      );
      await queue.enqueue(
        taskId: 'task-pending',
        entityType: 'avatar',
        entityId: 'user-1',
        imageBytes: fakeImageBytes,
        createdAt: DateTime(2025, 1, 3),
      );

      // Modify statuses.
      final tasks = await queue.readAll();
      tasks[0].status = ImageUploadStatus.failed;
      tasks[1].status = ImageUploadStatus.uploading;
      await queue.writeAll(tasks);

      final dequeued = await queue.dequeue();
      expect(dequeued, isNotNull);
      expect(dequeued!.id, 'task-pending');
    });

    test('sequential dequeues return different tasks', () async {
      await queue.enqueue(
        taskId: 'task-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
        createdAt: DateTime(2025, 1, 1),
      );
      await queue.enqueue(
        taskId: 'task-2',
        entityType: 'fish',
        entityId: 'fish-1',
        imageBytes: fakeImageBytes,
        createdAt: DateTime(2025, 1, 2),
      );

      final first = await queue.dequeue();
      final second = await queue.dequeue();
      final third = await queue.dequeue();

      expect(first!.id, 'task-1');
      expect(second!.id, 'task-2');
      expect(third, isNull);
    });

    test('throws StateError before initialization', () {
      final uninitQueue = ImageSyncQueue(basePath: tempDir.path);
      uninitQueue.resetForTesting();

      expect(() => uninitQueue.dequeue(), throwsA(isA<StateError>()));
    });
  });

  // ---------------------------------------------------------------------------
  // markComplete
  // ---------------------------------------------------------------------------
  group('markComplete', () {
    test('removes task from queue', () async {
      await queue.enqueue(
        taskId: 'task-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );

      final result = await queue.markComplete('task-1');
      expect(result, isTrue);

      final tasks = await queue.readAll();
      expect(tasks, isEmpty);
    });

    test('deletes associated image file', () async {
      await queue.enqueue(
        taskId: 'task-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );

      await queue.markComplete('task-1');

      final exists = await queue.fileExists('task-1');
      expect(exists, isFalse);
    });

    test('returns false when taskId not found', () async {
      final result = await queue.markComplete('nonexistent');
      expect(result, isFalse);
    });

    test('preserves other tasks', () async {
      await queue.enqueue(
        taskId: 'task-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );
      await queue.enqueue(
        taskId: 'task-2',
        entityType: 'fish',
        entityId: 'fish-1',
        imageBytes: fakeImageBytes,
      );

      await queue.markComplete('task-1');

      final tasks = await queue.readAll();
      expect(tasks.length, 1);
      expect(tasks[0].id, 'task-2');

      // task-2 file should still exist.
      final exists = await queue.fileExists('task-2');
      expect(exists, isTrue);
    });

    test('works even if image file was already deleted', () async {
      await queue.enqueue(
        taskId: 'task-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );

      // Delete file manually first.
      await queue.deleteFile('task-1');

      // Should still succeed (remove queue entry).
      final result = await queue.markComplete('task-1');
      expect(result, isTrue);

      final tasks = await queue.readAll();
      expect(tasks, isEmpty);
    });

    test('throws StateError before initialization', () {
      final uninitQueue = ImageSyncQueue(basePath: tempDir.path);
      uninitQueue.resetForTesting();

      expect(
        () => uninitQueue.markComplete('task-1'),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // markFailed
  // ---------------------------------------------------------------------------
  group('markFailed', () {
    test('sets status to failed and records error', () async {
      await queue.enqueue(
        taskId: 'task-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );

      final result = await queue.markFailed('task-1', 'Network error');
      expect(result, isTrue);

      final tasks = await queue.readAll();
      expect(tasks[0].status, ImageUploadStatus.failed);
      expect(tasks[0].retryCount, 1);
      expect(tasks[0].errorMessage, 'Network error');
    });

    test('increments retryCount on each failure', () async {
      await queue.enqueue(
        taskId: 'task-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );

      await queue.markFailed('task-1', 'Error 1');
      await queue.markFailed('task-1', 'Error 2');
      await queue.markFailed('task-1', 'Error 3');

      final tasks = await queue.readAll();
      expect(tasks[0].retryCount, 3);
      expect(tasks[0].errorMessage, 'Error 3');
    });

    test('returns false when taskId not found', () async {
      final result = await queue.markFailed('nonexistent', 'Error');
      expect(result, isFalse);
    });

    test('preserves other task fields', () async {
      final createdAt = DateTime(2025, 3, 15, 10, 0);
      await queue.enqueue(
        taskId: 'task-1',
        entityType: 'fish',
        entityId: 'fish-42',
        imageBytes: fakeImageBytes,
        createdAt: createdAt,
      );

      await queue.markFailed('task-1', 'Server 500');

      final tasks = await queue.readAll();
      final task = tasks[0];
      expect(task.id, 'task-1');
      expect(task.entityType, 'fish');
      expect(task.entityId, 'fish-42');
      expect(task.createdAt, createdAt);
    });

    test('does not delete image file', () async {
      await queue.enqueue(
        taskId: 'task-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );

      await queue.markFailed('task-1', 'Error');

      final exists = await queue.fileExists('task-1');
      expect(exists, isTrue);
    });

    test('throws StateError before initialization', () {
      final uninitQueue = ImageSyncQueue(basePath: tempDir.path);
      uninitQueue.resetForTesting();

      expect(
        () => uninitQueue.markFailed('task-1', 'Error'),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getPending
  // ---------------------------------------------------------------------------
  group('getPending', () {
    test('returns only pending tasks', () async {
      await queue.enqueue(
        taskId: 'task-pending-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
        createdAt: DateTime(2025, 1, 2),
      );
      await queue.enqueue(
        taskId: 'task-pending-2',
        entityType: 'fish',
        entityId: 'fish-1',
        imageBytes: fakeImageBytes,
        createdAt: DateTime(2025, 1, 1),
      );
      await queue.enqueue(
        taskId: 'task-failed',
        entityType: 'avatar',
        entityId: 'user-1',
        imageBytes: fakeImageBytes,
        createdAt: DateTime(2025, 1, 3),
      );

      // Set one task to failed.
      await queue.markFailed('task-failed', 'Error');

      final pending = await queue.getPending();
      expect(pending.length, 2);
      expect(pending[0].id, 'task-pending-2'); // Oldest first.
      expect(pending[1].id, 'task-pending-1');
    });

    test('returns empty list when no pending tasks', () async {
      await queue.enqueue(
        taskId: 'task-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );
      await queue.markFailed('task-1', 'Error');

      final pending = await queue.getPending();
      expect(pending, isEmpty);
    });

    test('returns sorted by createdAt (oldest first)', () async {
      await queue.enqueue(
        taskId: 'task-c',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
        createdAt: DateTime(2025, 3, 1),
      );
      await queue.enqueue(
        taskId: 'task-a',
        entityType: 'fish',
        entityId: 'fish-1',
        imageBytes: fakeImageBytes,
        createdAt: DateTime(2025, 1, 1),
      );
      await queue.enqueue(
        taskId: 'task-b',
        entityType: 'avatar',
        entityId: 'user-1',
        imageBytes: fakeImageBytes,
        createdAt: DateTime(2025, 2, 1),
      );

      final pending = await queue.getPending();
      expect(pending[0].id, 'task-a');
      expect(pending[1].id, 'task-b');
      expect(pending[2].id, 'task-c');
    });

    test('throws StateError before initialization', () {
      final uninitQueue = ImageSyncQueue(basePath: tempDir.path);
      uninitQueue.resetForTesting();

      expect(() => uninitQueue.getPending(), throwsA(isA<StateError>()));
    });
  });

  // ---------------------------------------------------------------------------
  // recoverStuckTasks
  // ---------------------------------------------------------------------------
  group('recoverStuckTasks', () {
    test('resets uploading tasks to pending', () async {
      await queue.enqueue(
        taskId: 'task-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );
      await queue.enqueue(
        taskId: 'task-2',
        entityType: 'fish',
        entityId: 'fish-1',
        imageBytes: fakeImageBytes,
      );

      // Simulate: both tasks were being uploaded when app crashed.
      final tasks = await queue.readAll();
      tasks[0].status = ImageUploadStatus.uploading;
      tasks[1].status = ImageUploadStatus.uploading;
      await queue.writeAll(tasks);

      final recoveredCount = await queue.recoverStuckTasks();
      expect(recoveredCount, 2);

      final recovered = await queue.readAll();
      expect(recovered[0].status, ImageUploadStatus.pending);
      expect(recovered[1].status, ImageUploadStatus.pending);
    });

    test('does not affect pending tasks', () async {
      await queue.enqueue(
        taskId: 'task-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );

      final recoveredCount = await queue.recoverStuckTasks();
      expect(recoveredCount, 0);

      final tasks = await queue.readAll();
      expect(tasks[0].status, ImageUploadStatus.pending);
    });

    test('does not affect failed tasks', () async {
      await queue.enqueue(
        taskId: 'task-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );
      await queue.markFailed('task-1', 'Error');

      final recoveredCount = await queue.recoverStuckTasks();
      expect(recoveredCount, 0);

      final tasks = await queue.readAll();
      expect(tasks[0].status, ImageUploadStatus.failed);
    });

    test('mixed statuses: only recovers uploading', () async {
      await queue.enqueue(
        taskId: 'task-pending',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );
      await queue.enqueue(
        taskId: 'task-uploading',
        entityType: 'fish',
        entityId: 'fish-1',
        imageBytes: fakeImageBytes,
      );
      await queue.enqueue(
        taskId: 'task-failed',
        entityType: 'avatar',
        entityId: 'user-1',
        imageBytes: fakeImageBytes,
      );

      // Set statuses.
      final tasks = await queue.readAll();
      tasks[1].status = ImageUploadStatus.uploading;
      tasks[2].status = ImageUploadStatus.failed;
      await queue.writeAll(tasks);

      final recoveredCount = await queue.recoverStuckTasks();
      expect(recoveredCount, 1);

      final recovered = await queue.readAll();
      expect(recovered[0].status, ImageUploadStatus.pending); // was pending.
      expect(recovered[1].status, ImageUploadStatus.pending); // was uploading.
      expect(recovered[2].status, ImageUploadStatus.failed); // unchanged.
    });

    test('returns 0 when queue is empty', () async {
      final recoveredCount = await queue.recoverStuckTasks();
      expect(recoveredCount, 0);
    });

    test('throws StateError before initialization', () {
      final uninitQueue = ImageSyncQueue(basePath: tempDir.path);
      uninitQueue.resetForTesting();

      expect(() => uninitQueue.recoverStuckTasks(), throwsA(isA<StateError>()));
    });
  });

  // ---------------------------------------------------------------------------
  // Atomic write safety
  // ---------------------------------------------------------------------------
  group('Atomic write', () {
    test('no temp file remains after successful write', () async {
      await queue.enqueue(
        taskId: 'task-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );

      final queuePath = await queue.queueFilePath;
      final tempFile = File('$queuePath.tmp');
      expect(tempFile.existsSync(), isFalse);
    });

    test('initialize cleans up leftover temp file', () async {
      // Simulate a crash: leave a .tmp file behind.
      final queuePath = await queue.queueFilePath;
      final tempFile = File('$queuePath.tmp');
      await tempFile.writeAsString('[{"id":"stale"}]');
      expect(tempFile.existsSync(), isTrue);

      // Re-initialize (simulates app restart).
      final newQueue = ImageSyncQueue(basePath: tempDir.path);
      await newQueue.initialize();

      expect(tempFile.existsSync(), isFalse);

      // Original queue.json should be unaffected.
      final tasks = await newQueue.readAll();
      expect(tasks, isEmpty); // The original was [], not stale data.
    });
  });

  // ---------------------------------------------------------------------------
  // Full lifecycle (integration)
  // ---------------------------------------------------------------------------
  group('Full lifecycle', () {
    test('enqueue -> dequeue -> markComplete', () async {
      // Enqueue.
      final enqueued = await queue.enqueue(
        taskId: 'lifecycle-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );
      expect(enqueued.status, ImageUploadStatus.pending);

      // Dequeue.
      final dequeued = await queue.dequeue();
      expect(dequeued!.id, 'lifecycle-1');
      expect(dequeued.status, ImageUploadStatus.uploading);

      // Complete.
      final completed = await queue.markComplete('lifecycle-1');
      expect(completed, isTrue);

      // Queue should be empty, file deleted.
      final tasks = await queue.readAll();
      expect(tasks, isEmpty);
      final exists = await queue.fileExists('lifecycle-1');
      expect(exists, isFalse);
    });

    test('enqueue -> dequeue -> markFailed -> recover -> dequeue', () async {
      await queue.enqueue(
        taskId: 'lifecycle-2',
        entityType: 'fish',
        entityId: 'fish-1',
        imageBytes: fakeImageBytes,
      );

      // First attempt: dequeue and fail.
      final first = await queue.dequeue();
      expect(first!.status, ImageUploadStatus.uploading);

      await queue.markFailed('lifecycle-2', 'Network timeout');

      // No pending tasks (task is failed).
      final pending = await queue.getPending();
      expect(pending, isEmpty);

      // Recover (simulates app restart recovery).
      final recovered = await queue.recoverStuckTasks();
      expect(recovered, 0); // It's failed, not uploading.

      // Manually reset to pending (would be done by processQueue logic).
      final tasks = await queue.readAll();
      tasks[0].status = ImageUploadStatus.pending;
      await queue.writeAll(tasks);

      // Second attempt.
      final second = await queue.dequeue();
      expect(second!.id, 'lifecycle-2');
      expect(second.retryCount, 1); // Preserved from first failure.

      // File should still exist.
      final exists = await queue.fileExists('lifecycle-2');
      expect(exists, isTrue);
    });

    test('crash recovery: uploading tasks become pending', () async {
      await queue.enqueue(
        taskId: 'crash-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );

      // Dequeue (sets to uploading).
      await queue.dequeue();

      // Simulate crash: create new queue instance.
      final recoveredQueue = ImageSyncQueue(basePath: tempDir.path);
      await recoveredQueue.initialize();
      final count = await recoveredQueue.recoverStuckTasks();
      expect(count, 1);

      // Task should be dequeue-able again.
      final task = await recoveredQueue.dequeue();
      expect(task, isNotNull);
      expect(task!.id, 'crash-1');
    });

    test('persistence: enqueued tasks survive instance recreation', () async {
      await queue.enqueue(
        taskId: 'persist-1',
        entityType: 'aquarium',
        entityId: 'aq-1',
        imageBytes: fakeImageBytes,
      );
      await queue.enqueue(
        taskId: 'persist-2',
        entityType: 'fish',
        entityId: 'fish-1',
        imageBytes: fakeImageBytes,
      );

      // New instance.
      final newQueue = ImageSyncQueue(basePath: tempDir.path);
      await newQueue.initialize();

      final tasks = await newQueue.readAll();
      expect(tasks.length, 2);
      expect(tasks[0].id, 'persist-1');
      expect(tasks[1].id, 'persist-2');

      // Files should also persist.
      expect(await newQueue.fileExists('persist-1'), isTrue);
      expect(await newQueue.fileExists('persist-2'), isTrue);
    });
  });
}
