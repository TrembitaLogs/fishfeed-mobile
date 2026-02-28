import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/data/services/image_upload_task.dart';

void main() {
  group('ImageUploadStatus', () {
    test('toJson returns status name', () {
      expect(ImageUploadStatus.pending.toJson(), 'pending');
      expect(ImageUploadStatus.uploading.toJson(), 'uploading');
      expect(ImageUploadStatus.failed.toJson(), 'failed');
    });

    test('fromJson parses valid status', () {
      expect(ImageUploadStatus.fromJson('pending'), ImageUploadStatus.pending);
      expect(
        ImageUploadStatus.fromJson('uploading'),
        ImageUploadStatus.uploading,
      );
      expect(ImageUploadStatus.fromJson('failed'), ImageUploadStatus.failed);
    });

    test('fromJson returns pending for unknown value', () {
      expect(ImageUploadStatus.fromJson('unknown'), ImageUploadStatus.pending);
    });
  });

  group('ImageUploadTask', () {
    late ImageUploadTask task;
    final testCreatedAt = DateTime(2025, 6, 15, 10, 30);

    setUp(() {
      task = ImageUploadTask(
        id: 'task-uuid-123',
        entityType: 'aquarium',
        entityId: 'aquarium-uuid-456',
        localPath: '/path/to/files/task-uuid-123.webp',
        createdAt: testCreatedAt,
      );
    });

    group('constructor', () {
      test('creates task with default values', () {
        expect(task.id, 'task-uuid-123');
        expect(task.entityType, 'aquarium');
        expect(task.entityId, 'aquarium-uuid-456');
        expect(task.localPath, '/path/to/files/task-uuid-123.webp');
        expect(task.createdAt, testCreatedAt);
        expect(task.status, ImageUploadStatus.pending);
        expect(task.retryCount, 0);
        expect(task.errorMessage, isNull);
      });

      test('creates task with custom values', () {
        final customTask = ImageUploadTask(
          id: 'task-1',
          entityType: 'fish',
          entityId: 'fish-1',
          localPath: '/path/to/file.webp',
          createdAt: testCreatedAt,
          status: ImageUploadStatus.failed,
          retryCount: 3,
          errorMessage: 'Network error',
        );

        expect(customTask.status, ImageUploadStatus.failed);
        expect(customTask.retryCount, 3);
        expect(customTask.errorMessage, 'Network error');
      });
    });

    group('canRetry', () {
      test('returns true when retryCount < maxRetries', () {
        task.retryCount = 4;
        expect(task.canRetry, isTrue);
      });

      test('returns false when retryCount == maxRetries', () {
        task.retryCount = 5;
        expect(task.canRetry, isFalse);
      });

      test('returns false when retryCount > maxRetries', () {
        task.retryCount = 6;
        expect(task.canRetry, isFalse);
      });

      test('returns true for new task with zero retries', () {
        expect(task.canRetry, isTrue);
      });
    });

    group('nextRetryDelay', () {
      test('returns exponential backoff durations', () {
        task.retryCount = 0;
        expect(task.nextRetryDelay, const Duration(seconds: 1));

        task.retryCount = 1;
        expect(task.nextRetryDelay, const Duration(seconds: 2));

        task.retryCount = 2;
        expect(task.nextRetryDelay, const Duration(seconds: 4));

        task.retryCount = 3;
        expect(task.nextRetryDelay, const Duration(seconds: 8));

        task.retryCount = 4;
        expect(task.nextRetryDelay, const Duration(seconds: 16));
      });

      test('caps delay at 16 seconds', () {
        task.retryCount = 5;
        expect(task.nextRetryDelay, const Duration(seconds: 16));

        task.retryCount = 10;
        expect(task.nextRetryDelay, const Duration(seconds: 16));
      });
    });

    group('JSON serialization', () {
      test('toJson produces correct map', () {
        final json = task.toJson();

        expect(json['id'], 'task-uuid-123');
        expect(json['entity_type'], 'aquarium');
        expect(json['entity_id'], 'aquarium-uuid-456');
        expect(json['local_path'], '/path/to/files/task-uuid-123.webp');
        expect(json['created_at'], testCreatedAt.toIso8601String());
        expect(json['status'], 'pending');
        expect(json['retry_count'], 0);
        expect(json['error_message'], isNull);
      });

      test('toJson includes error_message when set', () {
        task.errorMessage = 'Server error';
        final json = task.toJson();

        expect(json['error_message'], 'Server error');
      });

      test('fromJson restores task correctly', () {
        final json = task.toJson();
        final restored = ImageUploadTask.fromJson(json);

        expect(restored.id, task.id);
        expect(restored.entityType, task.entityType);
        expect(restored.entityId, task.entityId);
        expect(restored.localPath, task.localPath);
        expect(restored.createdAt, task.createdAt);
        expect(restored.status, task.status);
        expect(restored.retryCount, task.retryCount);
        expect(restored.errorMessage, task.errorMessage);
      });

      test('fromJson handles failed status with error message', () {
        final json = {
          'id': 'task-1',
          'entity_type': 'fish',
          'entity_id': 'fish-1',
          'local_path': '/path/to/file.webp',
          'created_at': '2025-06-15T10:30:00.000',
          'status': 'failed',
          'retry_count': 3,
          'error_message': 'Timeout',
        };

        final restored = ImageUploadTask.fromJson(json);

        expect(restored.status, ImageUploadStatus.failed);
        expect(restored.retryCount, 3);
        expect(restored.errorMessage, 'Timeout');
      });

      test('fromJson defaults retry_count to 0 when missing', () {
        final json = {
          'id': 'task-1',
          'entity_type': 'avatar',
          'entity_id': 'user-1',
          'local_path': '/path/to/file.webp',
          'created_at': '2025-06-15T10:30:00.000',
          'status': 'pending',
        };

        final restored = ImageUploadTask.fromJson(json);

        expect(restored.retryCount, 0);
      });

      test('roundtrip serialization preserves all fields', () {
        final original = ImageUploadTask(
          id: 'roundtrip-uuid',
          entityType: 'avatar',
          entityId: 'user-42',
          localPath: '/storage/files/roundtrip-uuid.webp',
          createdAt: DateTime(2025, 12, 25, 8, 0, 0),
          status: ImageUploadStatus.uploading,
          retryCount: 2,
          errorMessage: 'Previous error',
        );

        final jsonString = jsonEncode(original.toJson());
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        final restored = ImageUploadTask.fromJson(decoded);

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

    group('encodeList / decodeList', () {
      test('encodes and decodes empty list', () {
        final encoded = ImageUploadTask.encodeList([]);
        final decoded = ImageUploadTask.decodeList(encoded);

        expect(decoded, isEmpty);
      });

      test('encodes and decodes list with multiple tasks', () {
        final tasks = [
          ImageUploadTask(
            id: 'task-1',
            entityType: 'aquarium',
            entityId: 'aq-1',
            localPath: '/path/task-1.webp',
            createdAt: DateTime(2025, 1, 1),
          ),
          ImageUploadTask(
            id: 'task-2',
            entityType: 'fish',
            entityId: 'fish-1',
            localPath: '/path/task-2.webp',
            createdAt: DateTime(2025, 1, 2),
            status: ImageUploadStatus.failed,
            retryCount: 2,
            errorMessage: 'Server error',
          ),
        ];

        final encoded = ImageUploadTask.encodeList(tasks);
        final decoded = ImageUploadTask.decodeList(encoded);

        expect(decoded.length, 2);
        expect(decoded[0].id, 'task-1');
        expect(decoded[0].entityType, 'aquarium');
        expect(decoded[1].id, 'task-2');
        expect(decoded[1].status, ImageUploadStatus.failed);
        expect(decoded[1].retryCount, 2);
        expect(decoded[1].errorMessage, 'Server error');
      });

      test('decodeList returns empty list for null input', () {
        final decoded = ImageUploadTask.decodeList(null);
        expect(decoded, isEmpty);
      });

      test('decodeList returns empty list for empty string', () {
        final decoded = ImageUploadTask.decodeList('');
        expect(decoded, isEmpty);
      });
    });

    group('equality', () {
      test('tasks with same id are equal', () {
        final task1 = ImageUploadTask(
          id: 'same-id',
          entityType: 'aquarium',
          entityId: 'aq-1',
          localPath: '/path/1.webp',
          createdAt: DateTime(2025, 1, 1),
        );
        final task2 = ImageUploadTask(
          id: 'same-id',
          entityType: 'fish',
          entityId: 'fish-1',
          localPath: '/path/2.webp',
          createdAt: DateTime(2025, 1, 2),
        );

        expect(task1, equals(task2));
        expect(task1.hashCode, equals(task2.hashCode));
      });

      test('tasks with different ids are not equal', () {
        final task1 = ImageUploadTask(
          id: 'id-1',
          entityType: 'aquarium',
          entityId: 'aq-1',
          localPath: '/path/1.webp',
          createdAt: DateTime(2025, 1, 1),
        );
        final task2 = ImageUploadTask(
          id: 'id-2',
          entityType: 'aquarium',
          entityId: 'aq-1',
          localPath: '/path/1.webp',
          createdAt: DateTime(2025, 1, 1),
        );

        expect(task1, isNot(equals(task2)));
      });
    });

    group('toString', () {
      test('returns readable representation', () {
        final result = task.toString();

        expect(result, contains('task-uuid-123'));
        expect(result, contains('aquarium/aquarium-uuid-456'));
        expect(result, contains('pending'));
        expect(result, contains('0'));
      });
    });

    group('validEntityTypes', () {
      test('contains all expected types', () {
        expect(
          ImageUploadTask.validEntityTypes,
          containsAll(['aquarium', 'fish', 'avatar']),
        );
        expect(ImageUploadTask.validEntityTypes.length, 3);
      });
    });

    group('maxRetries', () {
      test('is 5', () {
        expect(ImageUploadTask.maxRetries, 5);
      });
    });
  });
}
