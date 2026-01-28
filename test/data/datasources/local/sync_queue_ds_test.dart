import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/local/sync_queue_ds.dart';
import 'package:fishfeed/data/models/sync_operation_model.dart';

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  late MockBox mockSyncQueueBox;
  late SyncQueueDataSource syncQueueDs;

  setUp(() {
    mockSyncQueueBox = MockBox();
    syncQueueDs = SyncQueueDataSource(syncQueueBox: mockSyncQueueBox);
  });

  SyncOperationModel createTestOperation({
    String id = 'op_1',
    SyncOperationType operationType = SyncOperationType.create,
    String entityType = 'feeding_event',
    String entityId = 'entity_1',
    String payload = '{"data": "test"}',
    DateTime? timestamp,
    int retryCount = 0,
    SyncOperationStatus status = SyncOperationStatus.pending,
    String? errorMessage,
  }) {
    return SyncOperationModel(
      id: id,
      operationType: operationType,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      timestamp: timestamp ?? DateTime(2025, 6, 15, 10, 0),
      retryCount: retryCount,
      status: status,
      errorMessage: errorMessage,
    );
  }

  group('Queue Operations', () {
    group('addToQueue', () {
      test('should add operation to Hive box', () async {
        final operation = createTestOperation();
        when(() => mockSyncQueueBox.put(any<dynamic>(), any<dynamic>()))
            .thenAnswer((_) async {});

        await syncQueueDs.addToQueue(operation);

        verify(() => mockSyncQueueBox.put('op_1', operation)).called(1);
      });
    });

    group('getQueuedOperations', () {
      test('should return all operations sorted by timestamp (oldest first)',
          () {
        final newerOp = createTestOperation(
          id: 'op_1',
          timestamp: DateTime(2025, 6, 15, 12, 0),
        );
        final olderOp = createTestOperation(
          id: 'op_2',
          timestamp: DateTime(2025, 6, 15, 8, 0),
        );

        when(() => mockSyncQueueBox.values).thenReturn([newerOp, olderOp]);

        final result = syncQueueDs.getQueuedOperations();

        expect(result.length, 2);
        expect(result[0].id, 'op_2'); // older first
        expect(result[1].id, 'op_1');
      });

      test('should return empty list when queue is empty', () {
        when(() => mockSyncQueueBox.values).thenReturn([]);

        final result = syncQueueDs.getQueuedOperations();

        expect(result, isEmpty);
      });
    });

    group('getPendingOperations', () {
      test('should return only pending operations', () {
        final pendingOp = createTestOperation(
          id: 'op_1',
          status: SyncOperationStatus.pending,
        );
        final completedOp = createTestOperation(
          id: 'op_2',
          status: SyncOperationStatus.completed,
        );
        final inProgressOp = createTestOperation(
          id: 'op_3',
          status: SyncOperationStatus.inProgress,
        );

        when(() => mockSyncQueueBox.values)
            .thenReturn([pendingOp, completedOp, inProgressOp]);

        final result = syncQueueDs.getPendingOperations();

        expect(result.length, 1);
        expect(result[0].id, 'op_1');
      });

      test('should include retryable failed operations', () {
        final pendingOp = createTestOperation(
          id: 'op_1',
          status: SyncOperationStatus.pending,
        );
        final failedRetryable = createTestOperation(
          id: 'op_2',
          status: SyncOperationStatus.failed,
          retryCount: 2, // can still retry
        );
        final failedMaxRetries = createTestOperation(
          id: 'op_3',
          status: SyncOperationStatus.failed,
          retryCount: 5, // exceeded max retries
        );

        when(() => mockSyncQueueBox.values)
            .thenReturn([pendingOp, failedRetryable, failedMaxRetries]);

        final result = syncQueueDs.getPendingOperations();

        expect(result.length, 2);
        expect(result.map((e) => e.id), containsAll(['op_1', 'op_2']));
        expect(result.map((e) => e.id), isNot(contains('op_3')));
      });

      test('should return operations sorted by timestamp (FIFO)', () {
        final newerPending = createTestOperation(
          id: 'op_1',
          status: SyncOperationStatus.pending,
          timestamp: DateTime(2025, 6, 15, 12, 0),
        );
        final olderPending = createTestOperation(
          id: 'op_2',
          status: SyncOperationStatus.pending,
          timestamp: DateTime(2025, 6, 15, 8, 0),
        );

        when(() => mockSyncQueueBox.values)
            .thenReturn([newerPending, olderPending]);

        final result = syncQueueDs.getPendingOperations();

        expect(result[0].id, 'op_2'); // older first (FIFO)
        expect(result[1].id, 'op_1');
      });
    });

    group('getOperationById', () {
      test('should return operation when exists', () {
        final operation = createTestOperation();
        when(() => mockSyncQueueBox.get('op_1')).thenReturn(operation);

        final result = syncQueueDs.getOperationById('op_1');

        expect(result, operation);
        expect(result?.id, 'op_1');
      });

      test('should return null when operation does not exist', () {
        when(() => mockSyncQueueBox.get('op_1')).thenReturn(null);

        final result = syncQueueDs.getOperationById('op_1');

        expect(result, isNull);
      });

      test('should return null when stored value is not SyncOperationModel',
          () {
        when(() => mockSyncQueueBox.get('op_1')).thenReturn('invalid');

        final result = syncQueueDs.getOperationById('op_1');

        expect(result, isNull);
      });
    });

    group('getOperationsForEntity', () {
      test('should return operations for specific entity', () {
        final op1 = createTestOperation(
          id: 'op_1',
          entityType: 'feeding_event',
          entityId: 'entity_1',
        );
        final op2 = createTestOperation(
          id: 'op_2',
          entityType: 'feeding_event',
          entityId: 'entity_2',
        );
        final op3 = createTestOperation(
          id: 'op_3',
          entityType: 'aquarium',
          entityId: 'entity_1',
        );

        when(() => mockSyncQueueBox.values).thenReturn([op1, op2, op3]);

        final result =
            syncQueueDs.getOperationsForEntity('feeding_event', 'entity_1');

        expect(result.length, 1);
        expect(result[0].id, 'op_1');
      });
    });
  });

  group('Status Management', () {
    group('markAsInProgress', () {
      test('should mark operation as in progress', () async {
        final operation = createTestOperation(status: SyncOperationStatus.pending);
        when(() => mockSyncQueueBox.get('op_1')).thenReturn(operation);
        when(() => mockSyncQueueBox.put(any<dynamic>(), any<dynamic>()))
            .thenAnswer((_) async {});

        final result = await syncQueueDs.markAsInProgress('op_1');

        expect(result, isTrue);
        expect(operation.status, SyncOperationStatus.inProgress);
        expect(operation.lastAttempt, isNotNull);
        verify(() => mockSyncQueueBox.put('op_1', operation)).called(1);
      });

      test('should return false when operation does not exist', () async {
        when(() => mockSyncQueueBox.get('op_1')).thenReturn(null);

        final result = await syncQueueDs.markAsInProgress('op_1');

        expect(result, isFalse);
        verifyNever(() => mockSyncQueueBox.put(any<dynamic>(), any<dynamic>()));
      });
    });

    group('markAsCompleted', () {
      test('should mark operation as completed', () async {
        final operation = createTestOperation(
          status: SyncOperationStatus.inProgress,
          errorMessage: 'previous error',
        );
        when(() => mockSyncQueueBox.get('op_1')).thenReturn(operation);
        when(() => mockSyncQueueBox.put(any<dynamic>(), any<dynamic>()))
            .thenAnswer((_) async {});

        final result = await syncQueueDs.markAsCompleted('op_1');

        expect(result, isTrue);
        expect(operation.status, SyncOperationStatus.completed);
        expect(operation.errorMessage, isNull);
        verify(() => mockSyncQueueBox.put('op_1', operation)).called(1);
      });

      test('should return false when operation does not exist', () async {
        when(() => mockSyncQueueBox.get('op_1')).thenReturn(null);

        final result = await syncQueueDs.markAsCompleted('op_1');

        expect(result, isFalse);
      });
    });

    group('markAsFailed', () {
      test('should mark operation as failed with error message', () async {
        final operation = createTestOperation(status: SyncOperationStatus.inProgress);
        when(() => mockSyncQueueBox.get('op_1')).thenReturn(operation);
        when(() => mockSyncQueueBox.put(any<dynamic>(), any<dynamic>()))
            .thenAnswer((_) async {});

        final result = await syncQueueDs.markAsFailed('op_1', 'Network error');

        expect(result, isTrue);
        expect(operation.status, SyncOperationStatus.failed);
        expect(operation.errorMessage, 'Network error');
        verify(() => mockSyncQueueBox.put('op_1', operation)).called(1);
      });

      test('should return false when operation does not exist', () async {
        when(() => mockSyncQueueBox.get('op_1')).thenReturn(null);

        final result = await syncQueueDs.markAsFailed('op_1', 'error');

        expect(result, isFalse);
      });
    });

    group('incrementRetryCount', () {
      test('should increment retry count and reset status to pending',
          () async {
        final operation = createTestOperation(
          status: SyncOperationStatus.failed,
          retryCount: 2,
        );
        when(() => mockSyncQueueBox.get('op_1')).thenReturn(operation);
        when(() => mockSyncQueueBox.put(any<dynamic>(), any<dynamic>()))
            .thenAnswer((_) async {});

        final result = await syncQueueDs.incrementRetryCount('op_1');

        expect(result, isTrue);
        expect(operation.retryCount, 3);
        expect(operation.status, SyncOperationStatus.pending);
      });

      test('should not reset status when max retries exceeded', () async {
        final operation = createTestOperation(
          status: SyncOperationStatus.failed,
          retryCount: 4, // will become 5 which is max
        );
        when(() => mockSyncQueueBox.get('op_1')).thenReturn(operation);
        when(() => mockSyncQueueBox.put(any<dynamic>(), any<dynamic>()))
            .thenAnswer((_) async {});

        await syncQueueDs.incrementRetryCount('op_1');

        expect(operation.retryCount, 5);
        expect(operation.status, SyncOperationStatus.failed);
      });

      test('should return false when operation does not exist', () async {
        when(() => mockSyncQueueBox.get('op_1')).thenReturn(null);

        final result = await syncQueueDs.incrementRetryCount('op_1');

        expect(result, isFalse);
      });
    });

    group('resetForRetry', () {
      test('should reset failed operation to pending', () async {
        final operation = createTestOperation(
          status: SyncOperationStatus.failed,
          retryCount: 2,
        );
        when(() => mockSyncQueueBox.get('op_1')).thenReturn(operation);
        when(() => mockSyncQueueBox.put(any<dynamic>(), any<dynamic>()))
            .thenAnswer((_) async {});

        final result = await syncQueueDs.resetForRetry('op_1');

        expect(result, isTrue);
        expect(operation.status, SyncOperationStatus.pending);
      });

      test('should return false when max retries exceeded', () async {
        final operation = createTestOperation(
          status: SyncOperationStatus.failed,
          retryCount: 5,
        );
        when(() => mockSyncQueueBox.get('op_1')).thenReturn(operation);

        final result = await syncQueueDs.resetForRetry('op_1');

        expect(result, isFalse);
      });

      test('should return false when operation does not exist', () async {
        when(() => mockSyncQueueBox.get('op_1')).thenReturn(null);

        final result = await syncQueueDs.resetForRetry('op_1');

        expect(result, isFalse);
      });
    });
  });

  group('Cleanup Operations', () {
    group('removeOperation', () {
      test('should remove operation when exists', () async {
        final operation = createTestOperation();
        when(() => mockSyncQueueBox.get('op_1')).thenReturn(operation);
        when(() => mockSyncQueueBox.delete(any<dynamic>())).thenAnswer((_) async {});

        final result = await syncQueueDs.removeOperation('op_1');

        expect(result, isTrue);
        verify(() => mockSyncQueueBox.delete('op_1')).called(1);
      });

      test('should return false when operation does not exist', () async {
        when(() => mockSyncQueueBox.get('op_1')).thenReturn(null);

        final result = await syncQueueDs.removeOperation('op_1');

        expect(result, isFalse);
        verifyNever(() => mockSyncQueueBox.delete(any<dynamic>()));
      });
    });

    group('clearCompletedOperations', () {
      test('should remove all completed operations', () async {
        final completedOp1 = createTestOperation(
          id: 'op_1',
          status: SyncOperationStatus.completed,
        );
        final completedOp2 = createTestOperation(
          id: 'op_2',
          status: SyncOperationStatus.completed,
        );
        final pendingOp = createTestOperation(
          id: 'op_3',
          status: SyncOperationStatus.pending,
        );

        when(() => mockSyncQueueBox.values)
            .thenReturn([completedOp1, completedOp2, pendingOp]);
        when(() => mockSyncQueueBox.delete(any<dynamic>())).thenAnswer((_) async {});

        final result = await syncQueueDs.clearCompletedOperations();

        expect(result, 2);
        verify(() => mockSyncQueueBox.delete('op_1')).called(1);
        verify(() => mockSyncQueueBox.delete('op_2')).called(1);
        verifyNever(() => mockSyncQueueBox.delete('op_3'));
      });

      test('should return 0 when no completed operations', () async {
        final pendingOp = createTestOperation(status: SyncOperationStatus.pending);
        when(() => mockSyncQueueBox.values).thenReturn([pendingOp]);

        final result = await syncQueueDs.clearCompletedOperations();

        expect(result, 0);
        verifyNever(() => mockSyncQueueBox.delete(any<dynamic>()));
      });
    });

    group('clearFailedOperations', () {
      test('should remove only failed operations that exceeded max retries',
          () async {
        final failedMaxRetries = createTestOperation(
          id: 'op_1',
          status: SyncOperationStatus.failed,
          retryCount: 5,
        );
        final failedCanRetry = createTestOperation(
          id: 'op_2',
          status: SyncOperationStatus.failed,
          retryCount: 2,
        );
        final pendingOp = createTestOperation(
          id: 'op_3',
          status: SyncOperationStatus.pending,
        );

        when(() => mockSyncQueueBox.values)
            .thenReturn([failedMaxRetries, failedCanRetry, pendingOp]);
        when(() => mockSyncQueueBox.delete(any<dynamic>())).thenAnswer((_) async {});

        final result = await syncQueueDs.clearFailedOperations();

        expect(result, 1);
        verify(() => mockSyncQueueBox.delete('op_1')).called(1);
        verifyNever(() => mockSyncQueueBox.delete('op_2'));
        verifyNever(() => mockSyncQueueBox.delete('op_3'));
      });
    });

    group('clearAll', () {
      test('should clear all operations from box', () async {
        when(() => mockSyncQueueBox.clear()).thenAnswer((_) async => 0);

        await syncQueueDs.clearAll();

        verify(() => mockSyncQueueBox.clear()).called(1);
      });
    });
  });

  group('Query Operations', () {
    group('getQueueSize', () {
      test('should return total number of operations', () {
        final op1 = createTestOperation(id: 'op_1');
        final op2 = createTestOperation(id: 'op_2');
        final op3 = createTestOperation(id: 'op_3');

        when(() => mockSyncQueueBox.values).thenReturn([op1, op2, op3]);

        final result = syncQueueDs.getQueueSize();

        expect(result, 3);
      });

      test('should return 0 when queue is empty', () {
        when(() => mockSyncQueueBox.values).thenReturn([]);

        final result = syncQueueDs.getQueueSize();

        expect(result, 0);
      });
    });

    group('getPendingCount', () {
      test('should return count of pending operations only', () {
        final pendingOp1 = createTestOperation(
          id: 'op_1',
          status: SyncOperationStatus.pending,
        );
        final pendingOp2 = createTestOperation(
          id: 'op_2',
          status: SyncOperationStatus.pending,
        );
        final completedOp = createTestOperation(
          id: 'op_3',
          status: SyncOperationStatus.completed,
        );

        when(() => mockSyncQueueBox.values)
            .thenReturn([pendingOp1, pendingOp2, completedOp]);

        final result = syncQueueDs.getPendingCount();

        expect(result, 2);
      });
    });

    group('getFailedCount', () {
      test('should return count of failed operations', () {
        final failedOp1 = createTestOperation(
          id: 'op_1',
          status: SyncOperationStatus.failed,
        );
        final failedOp2 = createTestOperation(
          id: 'op_2',
          status: SyncOperationStatus.failed,
        );
        final pendingOp = createTestOperation(
          id: 'op_3',
          status: SyncOperationStatus.pending,
        );

        when(() => mockSyncQueueBox.values)
            .thenReturn([failedOp1, failedOp2, pendingOp]);

        final result = syncQueueDs.getFailedCount();

        expect(result, 2);
      });
    });

    group('hasPendingOperations', () {
      test('should return true when has pending operations', () {
        final pendingOp = createTestOperation(status: SyncOperationStatus.pending);
        when(() => mockSyncQueueBox.values).thenReturn([pendingOp]);

        final result = syncQueueDs.hasPendingOperations();

        expect(result, isTrue);
      });

      test('should return true when has retryable failed operations', () {
        final failedOp = createTestOperation(
          status: SyncOperationStatus.failed,
          retryCount: 2,
        );
        when(() => mockSyncQueueBox.values).thenReturn([failedOp]);

        final result = syncQueueDs.hasPendingOperations();

        expect(result, isTrue);
      });

      test('should return false when only completed and max-retried operations',
          () {
        final completedOp = createTestOperation(
          id: 'op_1',
          status: SyncOperationStatus.completed,
        );
        final failedMaxRetries = createTestOperation(
          id: 'op_2',
          status: SyncOperationStatus.failed,
          retryCount: 5,
        );

        when(() => mockSyncQueueBox.values)
            .thenReturn([completedOp, failedMaxRetries]);

        final result = syncQueueDs.hasPendingOperations();

        expect(result, isFalse);
      });

      test('should return false when queue is empty', () {
        when(() => mockSyncQueueBox.values).thenReturn([]);

        final result = syncQueueDs.hasPendingOperations();

        expect(result, isFalse);
      });
    });

    group('getOperationsByStatus', () {
      test('should return operations filtered by status', () {
        final pendingOp = createTestOperation(
          id: 'op_1',
          status: SyncOperationStatus.pending,
        );
        final completedOp = createTestOperation(
          id: 'op_2',
          status: SyncOperationStatus.completed,
        );

        when(() => mockSyncQueueBox.values).thenReturn([pendingOp, completedOp]);

        final result =
            syncQueueDs.getOperationsByStatus(SyncOperationStatus.pending);

        expect(result.length, 1);
        expect(result[0].id, 'op_1');
      });
    });

    group('getOperationsByEntityType', () {
      test('should return operations filtered by entity type', () {
        final feedingOp = createTestOperation(
          id: 'op_1',
          entityType: 'feeding_event',
        );
        final aquariumOp = createTestOperation(
          id: 'op_2',
          entityType: 'aquarium',
        );

        when(() => mockSyncQueueBox.values).thenReturn([feedingOp, aquariumOp]);

        final result = syncQueueDs.getOperationsByEntityType('feeding_event');

        expect(result.length, 1);
        expect(result[0].id, 'op_1');
      });
    });
  });

  group('SyncOperationModel', () {
    group('canRetry', () {
      test('should return true when retryCount < maxRetries', () {
        final operation = createTestOperation(retryCount: 4);
        expect(operation.canRetry, isTrue);
      });

      test('should return false when retryCount >= maxRetries', () {
        final operation = createTestOperation(retryCount: 5);
        expect(operation.canRetry, isFalse);
      });
    });

    group('nextRetryDelay', () {
      test('should return exponential backoff delay', () {
        expect(
          createTestOperation(retryCount: 0).nextRetryDelay,
          const Duration(seconds: 1),
        );
        expect(
          createTestOperation(retryCount: 1).nextRetryDelay,
          const Duration(seconds: 2),
        );
        expect(
          createTestOperation(retryCount: 2).nextRetryDelay,
          const Duration(seconds: 4),
        );
        expect(
          createTestOperation(retryCount: 3).nextRetryDelay,
          const Duration(seconds: 8),
        );
        expect(
          createTestOperation(retryCount: 4).nextRetryDelay,
          const Duration(seconds: 16),
        );
      });

      test('should cap delay at 300 seconds', () {
        final operation = createTestOperation(retryCount: 10);
        expect(operation.nextRetryDelay, const Duration(seconds: 300));
      });
    });

    group('toString', () {
      test('should return readable string representation', () {
        final operation = createTestOperation(
          id: 'test_op',
          operationType: SyncOperationType.update,
          entityType: 'fish',
          entityId: 'fish_123',
          status: SyncOperationStatus.failed,
          retryCount: 2,
        );

        final result = operation.toString();

        expect(result, contains('test_op'));
        expect(result, contains('update'));
        expect(result, contains('fish/fish_123'));
        expect(result, contains('failed'));
        expect(result, contains('2'));
      });
    });
  });
}
