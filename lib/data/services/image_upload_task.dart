import 'dart:convert';

/// Status of an image upload task in the queue.
enum ImageUploadStatus {
  /// Task is waiting to be processed.
  pending,

  /// Task is currently being uploaded.
  uploading,

  /// Task failed and may be retried.
  failed;

  /// Converts status to JSON string value.
  String toJson() => name;

  /// Parses status from JSON string value.
  static ImageUploadStatus fromJson(String value) {
    return ImageUploadStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ImageUploadStatus.pending,
    );
  }
}

/// Represents a single image upload task in the queue.
///
/// Each task tracks an image file that needs to be uploaded to the server,
/// along with its associated entity and retry state.
///
/// Example:
/// ```dart
/// final task = ImageUploadTask(
///   id: '550e8400-e29b-41d4-a716-446655440000',
///   entityType: 'aquarium',
///   entityId: 'abc-123',
///   localPath: '/path/to/compressed/image.webp',
///   createdAt: DateTime.now(),
/// );
/// ```
class ImageUploadTask {
  ImageUploadTask({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.localPath,
    required this.createdAt,
    this.status = ImageUploadStatus.pending,
    this.retryCount = 0,
    this.errorMessage,
  });

  /// Creates an [ImageUploadTask] from a JSON map.
  factory ImageUploadTask.fromJson(Map<String, dynamic> json) {
    return ImageUploadTask(
      id: json['id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      localPath: json['local_path'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: ImageUploadStatus.fromJson(json['status'] as String),
      retryCount: json['retry_count'] as int? ?? 0,
      errorMessage: json['error_message'] as String?,
    );
  }

  /// Unique identifier for this task (UUID v4).
  final String id;

  /// Type of entity this image belongs to: 'aquarium', 'fish', or 'avatar'.
  final String entityType;

  /// ID of the entity this image belongs to.
  final String entityId;

  /// Absolute path to the compressed image file in local storage.
  final String localPath;

  /// When this task was created/queued.
  final DateTime createdAt;

  /// Current status of the upload task.
  ImageUploadStatus status;

  /// Number of upload attempts that have failed.
  int retryCount;

  /// Error message from the last failed attempt.
  String? errorMessage;

  /// Maximum number of retry attempts before giving up.
  static const int maxRetries = 5;

  /// Valid entity types for image uploads.
  static const List<String> validEntityTypes = ['aquarium', 'fish', 'avatar'];

  /// Whether this task can be retried.
  bool get canRetry => retryCount < maxRetries;

  /// Calculates the delay before next retry using exponential backoff.
  ///
  /// Returns duration: 1s, 2s, 4s, 8s, 16s (as per PRD retry strategy).
  Duration get nextRetryDelay {
    final seconds = (1 << retryCount).clamp(1, 16);
    return Duration(seconds: seconds);
  }

  /// Converts this task to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'local_path': localPath,
      'created_at': createdAt.toIso8601String(),
      'status': status.toJson(),
      'retry_count': retryCount,
      'error_message': errorMessage,
    };
  }

  /// Encodes a list of tasks to a JSON string.
  static String encodeList(List<ImageUploadTask> tasks) {
    return jsonEncode(tasks.map((task) => task.toJson()).toList());
  }

  /// Decodes a list of tasks from a JSON string.
  ///
  /// Returns an empty list if [jsonString] is null or empty.
  static List<ImageUploadTask> decodeList(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    final list = jsonDecode(jsonString) as List<dynamic>;
    return list
        .map((item) => ImageUploadTask.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  String toString() {
    return 'ImageUploadTask('
        'id: $id, '
        'entity: $entityType/$entityId, '
        'status: ${status.name}, '
        'retries: $retryCount'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageUploadTask && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
