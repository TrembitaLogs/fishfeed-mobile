import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/sync_operation_model.dart';

/// Data source for managing the sync queue in local Hive storage.
///
/// Provides operations for queueing offline changes and managing their
/// synchronization status. Operations are processed in FIFO order.
///
/// Example:
/// ```dart
/// final syncQueue = SyncQueueDataSource();
/// await syncQueue.addToQueue(operation);
/// final pending = syncQueue.getPendingOperations();
/// ```
class SyncQueueDataSource {
  SyncQueueDataSource({Box<dynamic>? syncQueueBox})
      : _syncQueueBox = syncQueueBox;

  final Box<dynamic>? _syncQueueBox;

  /// Gets the sync queue box, using the injected box or the default HiveBoxes.
  Box<dynamic> get _syncQueue => _syncQueueBox ?? HiveBoxes.syncQueue;

  // ============ Queue Operations ============

  /// Adds a new operation to the sync queue.
  ///
  /// [operation] - The sync operation to add to the queue.
  /// The operation is stored with its [id] as the key.
  Future<void> addToQueue(SyncOperationModel operation) async {
    await _syncQueue.put(operation.id, operation);
  }

  /// Retrieves all operations in the queue.
  ///
  /// Returns all sync operations regardless of status,
  /// sorted by timestamp (oldest first) for FIFO processing.
  List<SyncOperationModel> getQueuedOperations() {
    final operations =
        _syncQueue.values.whereType<SyncOperationModel>().toList();
    operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return operations;
  }

  /// Retrieves all pending operations ready to be synced.
  ///
  /// Returns operations with status [SyncOperationStatus.pending] or
  /// [SyncOperationStatus.failed] (that can still be retried),
  /// sorted by timestamp (oldest first) for FIFO processing.
  List<SyncOperationModel> getPendingOperations() {
    final operations = _syncQueue.values
        .whereType<SyncOperationModel>()
        .where((op) =>
            op.status == SyncOperationStatus.pending ||
            (op.status == SyncOperationStatus.failed && op.canRetry))
        .toList();

    operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return operations;
  }

  /// Retrieves a single operation by its ID.
  ///
  /// [id] - The unique identifier of the operation.
  /// Returns `null` if no operation with the given ID exists.
  SyncOperationModel? getOperationById(String id) {
    final operation = _syncQueue.get(id);
    if (operation is SyncOperationModel) {
      return operation;
    }
    return null;
  }

  /// Retrieves all operations for a specific entity.
  ///
  /// [entityType] - The type of entity (e.g., 'feeding_event').
  /// [entityId] - The ID of the entity.
  /// Returns operations matching both entityType and entityId.
  List<SyncOperationModel> getOperationsForEntity(
    String entityType,
    String entityId,
  ) {
    return _syncQueue.values
        .whereType<SyncOperationModel>()
        .where((op) => op.entityType == entityType && op.entityId == entityId)
        .toList();
  }

  // ============ Status Management ============

  /// Marks an operation as in progress.
  ///
  /// [operationId] - The ID of the operation to update.
  /// Returns `true` if updated, `false` if operation doesn't exist.
  Future<bool> markAsInProgress(String operationId) async {
    final operation = getOperationById(operationId);
    if (operation == null) return false;

    operation.status = SyncOperationStatus.inProgress;
    operation.lastAttempt = DateTime.now();
    await _syncQueue.put(operationId, operation);
    return true;
  }

  /// Marks an operation as successfully completed.
  ///
  /// [operationId] - The ID of the operation to mark as completed.
  /// Returns `true` if updated, `false` if operation doesn't exist.
  Future<bool> markAsCompleted(String operationId) async {
    final operation = getOperationById(operationId);
    if (operation == null) return false;

    operation.status = SyncOperationStatus.completed;
    operation.errorMessage = null;
    await _syncQueue.put(operationId, operation);
    return true;
  }

  /// Marks an operation as failed with an error message.
  ///
  /// [operationId] - The ID of the operation that failed.
  /// [error] - Description of the error that occurred.
  /// Returns `true` if updated, `false` if operation doesn't exist.
  Future<bool> markAsFailed(String operationId, String error) async {
    final operation = getOperationById(operationId);
    if (operation == null) return false;

    operation.status = SyncOperationStatus.failed;
    operation.errorMessage = error;
    await _syncQueue.put(operationId, operation);
    return true;
  }

  /// Increments the retry count for a failed operation.
  ///
  /// [operationId] - The ID of the operation to retry.
  /// Also resets status to pending if the operation can be retried.
  /// Returns `true` if updated, `false` if operation doesn't exist.
  Future<bool> incrementRetryCount(String operationId) async {
    final operation = getOperationById(operationId);
    if (operation == null) return false;

    operation.retryCount++;
    if (operation.canRetry) {
      operation.status = SyncOperationStatus.pending;
    }
    await _syncQueue.put(operationId, operation);
    return true;
  }

  /// Resets an operation for retry (sets status to pending).
  ///
  /// [operationId] - The ID of the operation to reset.
  /// Returns `true` if updated, `false` if operation doesn't exist or can't retry.
  Future<bool> resetForRetry(String operationId) async {
    final operation = getOperationById(operationId);
    if (operation == null || !operation.canRetry) return false;

    operation.status = SyncOperationStatus.pending;
    await _syncQueue.put(operationId, operation);
    return true;
  }

  // ============ Cleanup Operations ============

  /// Removes a single operation from the queue.
  ///
  /// [operationId] - The ID of the operation to remove.
  /// Returns `true` if removed, `false` if operation didn't exist.
  Future<bool> removeOperation(String operationId) async {
    final exists = getOperationById(operationId) != null;
    if (!exists) return false;

    await _syncQueue.delete(operationId);
    return true;
  }

  /// Removes all completed operations from the queue.
  ///
  /// Returns the number of operations cleared.
  Future<int> clearCompletedOperations() async {
    final completed = _syncQueue.values
        .whereType<SyncOperationModel>()
        .where((op) => op.status == SyncOperationStatus.completed)
        .toList();

    for (final op in completed) {
      await _syncQueue.delete(op.id);
    }

    return completed.length;
  }

  /// Removes all failed operations that have exceeded max retries.
  ///
  /// Returns the number of operations cleared.
  Future<int> clearFailedOperations() async {
    final failed = _syncQueue.values
        .whereType<SyncOperationModel>()
        .where(
            (op) => op.status == SyncOperationStatus.failed && !op.canRetry)
        .toList();

    for (final op in failed) {
      await _syncQueue.delete(op.id);
    }

    return failed.length;
  }

  /// Clears all operations from the queue.
  ///
  /// Use with caution - this removes all pending sync operations.
  Future<void> clearAll() async {
    await _syncQueue.clear();
  }

  // ============ Query Operations ============

  /// Returns the total number of operations in the queue.
  int getQueueSize() {
    return _syncQueue.values.whereType<SyncOperationModel>().length;
  }

  /// Returns the number of pending operations.
  int getPendingCount() {
    return _syncQueue.values
        .whereType<SyncOperationModel>()
        .where((op) => op.status == SyncOperationStatus.pending)
        .length;
  }

  /// Returns the number of failed operations.
  int getFailedCount() {
    return _syncQueue.values
        .whereType<SyncOperationModel>()
        .where((op) => op.status == SyncOperationStatus.failed)
        .length;
  }

  /// Checks if there are any pending operations.
  bool hasPendingOperations() {
    return _syncQueue.values
        .whereType<SyncOperationModel>()
        .any((op) =>
            op.status == SyncOperationStatus.pending ||
            (op.status == SyncOperationStatus.failed && op.canRetry));
  }

  /// Gets operations by status.
  ///
  /// [status] - The status to filter by.
  /// Returns operations with the specified status, sorted by timestamp.
  List<SyncOperationModel> getOperationsByStatus(SyncOperationStatus status) {
    final operations = _syncQueue.values
        .whereType<SyncOperationModel>()
        .where((op) => op.status == status)
        .toList();

    operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return operations;
  }

  /// Gets operations by entity type.
  ///
  /// [entityType] - The entity type to filter by (e.g., 'feeding_event').
  /// Returns operations for the specified entity type, sorted by timestamp.
  List<SyncOperationModel> getOperationsByEntityType(String entityType) {
    final operations = _syncQueue.values
        .whereType<SyncOperationModel>()
        .where((op) => op.entityType == entityType)
        .toList();

    operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return operations;
  }
}
