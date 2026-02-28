import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:fishfeed/core/config/api_config.dart';
import 'package:fishfeed/data/services/image_sync_queue.dart';
import 'package:fishfeed/data/services/image_upload_task.dart';
import 'package:fishfeed/services/image_processing_service.dart';

/// Callback invoked after a successful image upload.
///
/// Receives the [entityType], [entityId], and the S3 [photoKey] returned
/// by the server. The implementation should update the local entity's
/// `photoKey`/`avatarKey` and set `updatedAt = DateTime.now()`.
typedef EntityPhotoKeyUpdater =
    Future<void> Function({
      required String entityType,
      required String entityId,
      required String photoKey,
    });

/// Per-entity-type compression configuration.
///
/// Defines quality and max resolution per PRD:
/// - Avatar: 90% quality, 512×512 max
/// - Aquarium/Fish: 80% quality, 2048×2048 max
class ImageCompressionConfig {
  const ImageCompressionConfig({required this.quality, required this.maxWidth});

  /// WebP encoding quality (0-100).
  final int quality;

  /// Maximum dimension in pixels (width and height).
  final int maxWidth;
}

/// Service for queuing image uploads with compression and offline support.
///
/// Compresses images to WebP format using [ImageProcessingService],
/// stores them in [ImageSyncQueue], and returns `local://` keys
/// for immediate UI display before the actual upload completes.
///
/// Usage:
/// ```dart
/// final localKey = await uploadService.queueUpload(
///   entityType: 'aquarium',
///   entityId: 'abc-123',
///   imageBytes: rawImageBytes,
/// );
/// // localKey == 'local://550e8400-e29b-41d4-a716-446655440000'
/// ```
class ImageUploadService {
  ImageUploadService({
    required ImageSyncQueue queue,
    required ImageProcessingService imageProcessor,
    required Dio dio,
    required EntityPhotoKeyUpdater onUploadComplete,
    Uuid? uuid,
    @visibleForTesting Future<void> Function(Duration)? delayFn,
  }) : _queue = queue,
       _imageProcessor = imageProcessor,
       _dio = dio,
       _onUploadComplete = onUploadComplete,
       _uuid = uuid ?? const Uuid(),
       _delayFn = delayFn ?? Future.delayed;

  final ImageSyncQueue _queue;
  final ImageProcessingService _imageProcessor;
  final Dio _dio;
  final EntityPhotoKeyUpdater _onUploadComplete;
  final Uuid _uuid;
  final Future<void> Function(Duration) _delayFn;

  /// Maximum total attempts per upload (1 initial + maxRetries retries).
  @visibleForTesting
  static int get maxAttempts => ImageUploadTask.maxRetries + 1;

  /// Per-entity-type compression settings.
  static const Map<String, ImageCompressionConfig> compressionSettings = {
    'avatar': ImageCompressionConfig(quality: 90, maxWidth: 512),
    'aquarium': ImageCompressionConfig(quality: 80, maxWidth: 2048),
    'fish': ImageCompressionConfig(quality: 80, maxWidth: 2048),
  };

  /// Compresses an image and enqueues it for upload.
  ///
  /// 1. Validates [entityType] (must be 'aquarium', 'fish', or 'avatar').
  /// 2. Compresses [imageBytes] to WebP using per-type quality and resolution.
  /// 3. Generates a UUID task ID and enqueues to [ImageSyncQueue].
  /// 4. Returns a `local://{taskId}` key for immediate UI display.
  ///
  /// The caller should set this key as the entity's `photoKey`/`avatarKey`
  /// so the UI can display the local image while upload is pending.
  ///
  /// Throws [ArgumentError] if [entityType] is not valid.
  /// Throws [ImageProcessingException] if compression fails.
  /// Throws [StateError] if the queue has not been initialized.
  Future<String> queueUpload({
    required String entityType,
    required String entityId,
    required Uint8List imageBytes,
  }) async {
    if (!ImageUploadTask.validEntityTypes.contains(entityType)) {
      throw ArgumentError.value(
        entityType,
        'entityType',
        'Must be one of: ${ImageUploadTask.validEntityTypes.join(', ')}',
      );
    }

    final config = compressionSettings[entityType]!;

    final result = await _imageProcessor.compressToWebP(
      imageBytes,
      quality: config.quality,
      maxWidth: config.maxWidth,
    );

    final taskId = _uuid.v4();

    await _queue.enqueue(
      taskId: taskId,
      entityType: entityType,
      entityId: entityId,
      imageBytes: result.bytes,
    );

    return 'local://$taskId';
  }

  /// Returns the local file path for a `local://` key.
  ///
  /// Parses the task ID from [localKey] (format: `local://{uuid}`)
  /// and returns the file path from the queue if the file exists.
  ///
  /// Returns `null` if:
  /// - [localKey] does not start with `local://`
  /// - The task ID is empty
  /// - The file does not exist on disk
  Future<String?> getLocalImagePath(String localKey) async {
    if (!localKey.startsWith('local://')) {
      return null;
    }

    final taskId = localKey.substring('local://'.length);
    if (taskId.isEmpty) {
      return null;
    }

    final filePath = await _queue.getFilePath(taskId);
    final file = File(filePath);
    if (await file.exists()) {
      return filePath;
    }

    return null;
  }

  /// Processes all pending uploads in the queue.
  ///
  /// Dequeues tasks one by one and uploads each to the server.
  /// On success, calls [_onUploadComplete] to update the local entity
  /// and marks the task as complete. On failure, marks the task as failed.
  ///
  /// Exits when no more pending tasks are available.
  Future<void> processQueue() async {
    while (true) {
      final task = await _queue.dequeue();
      if (task == null) break;

      try {
        final key = await _uploadToServer(task);
        await _onUploadComplete(
          entityType: task.entityType,
          entityId: task.entityId,
          photoKey: key,
        );
        await _queue.markComplete(task.id);
      } on Exception catch (e) {
        await _queue.markFailed(task.id, e.toString());
      }
    }
  }

  /// Uploads an image to the server with exponential backoff retry.
  ///
  /// Makes up to 6 total attempts (1 initial + 5 retries) for retryable
  /// errors (network errors, 5xx). Non-retryable errors (4xx) are
  /// rethrown immediately.
  ///
  /// Backoff delays between retries: 1s, 2s, 4s, 8s, 16s.
  ///
  /// Returns the S3 object key from the server response.
  Future<String> _uploadToServer(ImageUploadTask task) async {
    final totalAttempts = maxAttempts;

    for (var attempt = 0; attempt < totalAttempts; attempt++) {
      if (attempt > 0) {
        final delay = Duration(seconds: 1 << (attempt - 1));
        debugPrint(
          'Image upload retry $attempt/${ImageUploadTask.maxRetries} '
          'for task ${task.id}, waiting ${delay.inSeconds}s',
        );
        await _delayFn(delay);
      }

      try {
        return await _doUpload(task);
      } on DioException catch (e) {
        final isLastAttempt = attempt + 1 >= totalAttempts;
        if (!_isRetryableError(e) || isLastAttempt) {
          rethrow;
        }
      }
    }

    // Unreachable: the loop always returns or rethrows.
    throw StateError('Upload retry loop exited unexpectedly');
  }

  /// Performs the actual multipart upload HTTP call.
  Future<String> _doUpload(ImageUploadTask task) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        task.localPath,
        filename: '${task.id}.webp',
        contentType: DioMediaType.parse('image/webp'),
      ),
      'entity_type': task.entityType,
      'entity_id': task.entityId,
    });

    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.imageUpload,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return response.data!['key'] as String;
  }

  /// Whether a [DioException] represents a transient error worth retrying.
  ///
  /// Retryable: network/timeout errors and 5xx server errors.
  /// Not retryable: 4xx client errors (bad request, forbidden, etc.).
  static bool _isRetryableError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        break;
    }

    final statusCode = e.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return true;
    }

    return false;
  }

  /// Resets eligible failed tasks to pending and reprocesses the queue.
  ///
  /// Only resets tasks where [ImageUploadTask.canRetry] is `true`
  /// (i.e., `retryCount < maxRetries`). Tasks that have exhausted
  /// all retry cycles remain in failed state.
  ///
  /// Returns the number of tasks that were reset.
  Future<int> retryFailed() async {
    final tasks = await _queue.readAll();
    var resetCount = 0;

    for (final task in tasks) {
      if (task.status == ImageUploadStatus.failed && task.canRetry) {
        task.status = ImageUploadStatus.pending;
        resetCount++;
      }
    }

    if (resetCount > 0) {
      await _queue.writeAll(tasks);
      await processQueue();
    }

    return resetCount;
  }
}
