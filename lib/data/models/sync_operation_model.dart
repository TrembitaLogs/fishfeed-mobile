import 'package:hive_flutter/hive_flutter.dart';

part 'sync_operation_model.g.dart';

/// Type of synchronization operation.
///
/// Defines what kind of CRUD operation needs to be synced to the server.
@HiveType(typeId: 20)
enum SyncOperationType {
  /// Create a new entity on the server.
  @HiveField(0)
  create,

  /// Update an existing entity on the server.
  @HiveField(1)
  update,

  /// Delete an entity from the server.
  @HiveField(2)
  delete,
}

/// Status of a sync operation in the queue.
///
/// Tracks the current state of the operation as it moves through the sync process.
@HiveType(typeId: 21)
enum SyncOperationStatus {
  /// Operation is waiting to be processed.
  @HiveField(0)
  pending,

  /// Operation is currently being processed.
  @HiveField(1)
  inProgress,

  /// Operation completed successfully.
  @HiveField(2)
  completed,

  /// Operation failed and may be retried.
  @HiveField(3)
  failed,
}

/// Hive model for storing sync operations in the queue.
///
/// Represents an offline operation that needs to be synchronized
/// with the server when connectivity is restored.
///
/// Example:
/// ```dart
/// final operation = SyncOperationModel(
///   id: uuid.v4(),
///   operationType: SyncOperationType.create,
///   entityType: 'feeding_event',
///   entityId: 'event_123',
///   payload: '{"fishId": "fish_1", "amount": 5.0}',
///   timestamp: DateTime.now(),
/// );
/// ```
@HiveType(typeId: 8)
class SyncOperationModel extends HiveObject {
  SyncOperationModel({
    required this.id,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.timestamp,
    this.retryCount = 0,
    this.status = SyncOperationStatus.pending,
    this.errorMessage,
    this.lastAttempt,
  });

  /// Unique identifier for this sync operation.
  @HiveField(0)
  String id;

  /// Type of operation (create, update, delete).
  @HiveField(1)
  SyncOperationType operationType;

  /// Type of entity being synced (e.g., 'feeding_event', 'aquarium', 'fish').
  @HiveField(2)
  String entityType;

  /// ID of the entity being synced.
  @HiveField(3)
  String entityId;

  /// JSON-encoded payload containing the entity data.
  ///
  /// For create/update operations, contains the full entity data.
  /// For delete operations, may be empty or contain metadata.
  @HiveField(4)
  String payload;

  /// When this operation was created/queued.
  @HiveField(5)
  DateTime timestamp;

  /// Number of times this operation has been retried.
  @HiveField(6)
  int retryCount;

  /// Current status of the operation.
  @HiveField(7)
  SyncOperationStatus status;

  /// Error message from the last failed attempt.
  @HiveField(8)
  String? errorMessage;

  /// Timestamp of the last sync attempt.
  @HiveField(9)
  DateTime? lastAttempt;

  /// Maximum number of retry attempts before giving up.
  static const int maxRetries = 5;

  /// Whether this operation can be retried.
  bool get canRetry => retryCount < maxRetries;

  /// Calculates the delay before next retry using exponential backoff.
  ///
  /// Returns duration in seconds: 2^retryCount (1s, 2s, 4s, 8s, 16s, ...).
  /// Capped at 5 minutes (300 seconds).
  Duration get nextRetryDelay {
    final seconds = (1 << retryCount).clamp(1, 300);
    return Duration(seconds: seconds);
  }

  @override
  String toString() {
    return 'SyncOperationModel('
        'id: $id, '
        'type: $operationType, '
        'entity: $entityType/$entityId, '
        'status: $status, '
        'retries: $retryCount'
        ')';
  }
}
