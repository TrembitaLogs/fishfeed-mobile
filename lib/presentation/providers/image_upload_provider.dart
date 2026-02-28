import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/datasources/remote/api_client.dart';
import 'package:fishfeed/data/services/image_sync_queue.dart';
import 'package:fishfeed/data/services/image_upload_service.dart';
import 'package:fishfeed/data/services/image_upload_task.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/services/connectivity/connectivity_service.dart';
import 'package:fishfeed/services/image_processing_service.dart';

// ============ State ============

/// State of the image upload queue for UI consumption.
///
/// Exposes pending/failed counts and processing status so the UI can
/// display upload indicators, badges, or retry buttons.
class ImageUploadQueueStatus {
  const ImageUploadQueueStatus({
    this.pendingCount = 0,
    this.failedCount = 0,
    this.isProcessing = false,
  });

  /// No pending or failed uploads, not processing.
  static const empty = ImageUploadQueueStatus();

  /// Number of uploads waiting to be processed.
  final int pendingCount;

  /// Number of uploads that failed and may be retried.
  final int failedCount;

  /// Whether the queue is currently being processed.
  final bool isProcessing;

  /// Whether there are any pending or failed uploads.
  bool get hasWork => pendingCount > 0 || failedCount > 0;

  /// Creates a copy with the given fields replaced.
  ImageUploadQueueStatus copyWith({
    int? pendingCount,
    int? failedCount,
    bool? isProcessing,
  }) {
    return ImageUploadQueueStatus(
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageUploadQueueStatus &&
        other.pendingCount == pendingCount &&
        other.failedCount == failedCount &&
        other.isProcessing == isProcessing;
  }

  @override
  int get hashCode => Object.hash(pendingCount, failedCount, isProcessing);

  @override
  String toString() =>
      'ImageUploadQueueStatus(pending: $pendingCount, failed: $failedCount, '
      'processing: $isProcessing)';
}

// ============ Notifier ============

/// Manages the image upload queue lifecycle with connectivity awareness.
///
/// Responsibilities:
/// - Initializes [ImageSyncQueue] and recovers stuck tasks on startup
/// - Listens to [ConnectivityService] and triggers [processQueue] when
///   connectivity restores (offline -> online transition)
/// - Tracks queue status (pending/failed counts) for UI consumption
/// - Delegates actual upload work to [ImageUploadService]
///
/// Usage:
/// ```dart
/// // Watch in widget tree to activate upload processing
/// ref.watch(imageUploadNotifierProvider);
///
/// // Queue an upload
/// final localKey = await ref.read(imageUploadNotifierProvider.notifier)
///     .queueUpload(entityType: 'aquarium', entityId: id, imageBytes: bytes);
/// ```
class ImageUploadNotifier extends StateNotifier<ImageUploadQueueStatus> {
  ImageUploadNotifier({
    required ImageSyncQueue queue,
    required ImageUploadService uploadService,
    required ConnectivityService connectivityService,
  }) : _queue = queue,
       _uploadService = uploadService,
       _connectivityService = connectivityService,
       super(ImageUploadQueueStatus.empty);

  final ImageSyncQueue _queue;
  final ImageUploadService _uploadService;
  final ConnectivityService _connectivityService;

  StreamSubscription<bool>? _connectivitySubscription;
  bool _wasOffline = false;
  bool _isInitialized = false;

  /// Whether the notifier has been initialized.
  @visibleForTesting
  bool get isInitialized => _isInitialized;

  /// Initializes the queue and starts connectivity listening.
  ///
  /// Performs crash recovery for tasks stuck in 'uploading' status,
  /// then processes pending uploads if the device is online.
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _queue.initialize();
    await _queue.recoverStuckTasks();
    await _refreshStatus();

    _wasOffline = !_connectivityService.isOnline;
    _connectivitySubscription = _connectivityService.statusStream.listen(
      _onConnectivityChanged,
      onError: (Object error) {
        debugPrint('ImageUploadNotifier: Connectivity stream error: $error');
      },
    );

    _isInitialized = true;

    // Process pending uploads if online
    if (_connectivityService.isOnline) {
      unawaited(processQueue());
    }
  }

  void _onConnectivityChanged(bool isOnline) {
    if (isOnline && _wasOffline) {
      debugPrint(
        'ImageUploadNotifier: Connectivity restored, processing queue',
      );
      unawaited(processQueue());
    }
    _wasOffline = !isOnline;
  }

  /// Compresses and enqueues an image for upload.
  ///
  /// Returns a `local://{uuid}` key for immediate UI display.
  /// The caller should set this key as the entity's `photoKey`/`avatarKey`
  /// so the UI can show the local image while upload is pending.
  ///
  /// Throws [ArgumentError] if [entityType] is invalid.
  /// Throws [ImageProcessingException] if compression fails.
  Future<String> queueUpload({
    required String entityType,
    required String entityId,
    required Uint8List imageBytes,
  }) async {
    final localKey = await _uploadService.queueUpload(
      entityType: entityType,
      entityId: entityId,
      imageBytes: imageBytes,
    );
    await _refreshStatus();
    unawaited(processQueue());
    return localKey;
  }

  /// Processes all pending uploads in the queue.
  ///
  /// No-op if already processing. On completion, refreshes the status
  /// so the UI reflects the updated counts.
  Future<void> processQueue() async {
    if (state.isProcessing) return;

    if (!mounted) return;
    state = state.copyWith(isProcessing: true);

    try {
      await _uploadService.processQueue();
    } on Exception catch (e) {
      debugPrint('ImageUploadNotifier: processQueue error: $e');
    } finally {
      if (mounted) {
        state = state.copyWith(isProcessing: false);
      }
      await _refreshStatus();
    }
  }

  /// Retries all eligible failed uploads.
  ///
  /// Only resets tasks where `retryCount < maxRetries`.
  /// Returns the number of tasks that were reset and reprocessed.
  Future<int> retryFailed() async {
    final count = await _uploadService.retryFailed();
    await _refreshStatus();
    return count;
  }

  /// Returns the local file path for a `local://` key.
  ///
  /// Useful for displaying the local image while the upload is pending.
  Future<String?> getLocalImagePath(String localKey) {
    return _uploadService.getLocalImagePath(localKey);
  }

  /// Reads the queue and updates state with current counts.
  Future<void> _refreshStatus() async {
    final tasks = await _queue.readAll();
    final pending = tasks
        .where((t) => t.status == ImageUploadStatus.pending)
        .length;
    final failed = tasks
        .where((t) => t.status == ImageUploadStatus.failed)
        .length;

    if (mounted) {
      state = state.copyWith(pendingCount: pending, failedCount: failed);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    super.dispose();
  }
}

// ============ Entity Photo Key Updater ============

/// Creates an [EntityPhotoKeyUpdater] callback that updates local Hive models
/// after a successful image upload.
///
/// CRITICAL: For aquarium and fish entities, sets `updatedAt = DateTime.now()`
/// to prevent LWW conflicts during the next sync cycle. Without this, the
/// server's `updated_at` (set during upload) would be newer than the client's,
/// causing the server to reject the entire changeset — potentially losing
/// other local changes like name edits.
///
/// For avatar (user), only sets `synced = false` since UserModel does not
/// have an `updatedAt` field.
@visibleForTesting
EntityPhotoKeyUpdater createPhotoKeyUpdater({
  required AquariumLocalDataSource aquariumDs,
  required FishLocalDataSource fishDs,
  required AuthLocalDataSource authDs,
  void Function(String photoKey)? onAvatarKeyUpdated,
}) {
  return ({
    required String entityType,
    required String entityId,
    required String photoKey,
  }) async {
    switch (entityType) {
      case 'aquarium':
        final aquarium = aquariumDs.getAquariumById(entityId);
        if (aquarium != null) {
          aquarium.photoKey = photoKey;
          aquarium.updatedAt = DateTime.now();
          aquarium.synced = false;
          await aquarium.save();
        }
      case 'fish':
        final fish = fishDs.getFishById(entityId);
        if (fish != null) {
          fish.photoKey = photoKey;
          fish.updatedAt = DateTime.now();
          fish.synced = false;
          await fish.save();
        }
      case 'avatar':
        final user = authDs.getCurrentUser();
        if (user != null) {
          user.avatarKey = photoKey;
          user.synced = false;
          await user.save();
        }
        // Notify AuthNotifier so the UI reflects the new S3 key immediately
        // (without requiring an app restart).
        onAvatarKeyUpdated?.call(photoKey);
    }
  };
}

// ============ Riverpod Providers ============

/// Provider for [ImageSyncQueue].
///
/// Provides singleton access to the file-based image upload queue.
/// The queue is initialized lazily when [imageUploadNotifierProvider]
/// is first watched.
final imageSyncQueueProvider = Provider<ImageSyncQueue>((ref) {
  return ImageSyncQueue();
});

/// Provider for [ImageProcessingService].
///
/// Provides singleton access to the image compression service.
final imageProcessingServiceProvider = Provider<ImageProcessingService>((ref) {
  return ImageProcessingService();
});

/// Provider for [ImageUploadService].
///
/// Wires together the queue, image processor, Dio client, and the
/// [EntityPhotoKeyUpdater] callback that updates Hive models after
/// successful uploads.
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  final queue = ref.watch(imageSyncQueueProvider);
  final imageProcessor = ref.watch(imageProcessingServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  final aquariumDs = ref.read(aquariumLocalDataSourceProvider);
  final fishDs = ref.read(fishLocalDataSourceProvider);
  final authDs = ref.read(authLocalDataSourceProvider);
  return ImageUploadService(
    queue: queue,
    imageProcessor: imageProcessor,
    dio: apiClient.dio,
    onUploadComplete: createPhotoKeyUpdater(
      aquariumDs: aquariumDs,
      fishDs: fishDs,
      authDs: authDs,
      onAvatarKeyUpdated: (photoKey) {
        final notifier = ref.read(authNotifierProvider.notifier);
        notifier.updateAvatarKey(photoKey);
      },
    ),
  );
});

/// Provider for [ImageUploadNotifier].
///
/// Manages the full image upload lifecycle:
/// - Initializes queue and recovers stuck tasks on startup
/// - Processes pending uploads when connectivity restores
/// - Tracks queue status (pending/failed counts) for UI
///
/// Watch this provider in the widget tree to activate upload processing.
///
/// Example:
/// ```dart
/// // In a widget tree listener (e.g., app.dart):
/// ref.watch(imageUploadNotifierProvider);
///
/// // To queue an upload from a screen:
/// final notifier = ref.read(imageUploadNotifierProvider.notifier);
/// final localKey = await notifier.queueUpload(
///   entityType: 'aquarium',
///   entityId: aquariumId,
///   imageBytes: compressedBytes,
/// );
/// ```
final imageUploadNotifierProvider =
    StateNotifierProvider<ImageUploadNotifier, ImageUploadQueueStatus>((ref) {
      final queue = ref.watch(imageSyncQueueProvider);
      final uploadService = ref.watch(imageUploadServiceProvider);
      final connectivityService = ref.watch(connectivityServiceProvider);

      final notifier = ImageUploadNotifier(
        queue: queue,
        uploadService: uploadService,
        connectivityService: connectivityService,
      );

      // Initialize asynchronously — recovers stuck tasks and processes queue
      notifier.initialize();

      ref.onDispose(() => notifier.dispose());

      return notifier;
    });

// ============ Convenience Providers ============

/// Number of pending image uploads in the queue.
final pendingUploadsCountProvider = Provider<int>((ref) {
  return ref.watch(imageUploadNotifierProvider).pendingCount;
});

/// Number of failed image uploads in the queue.
final failedUploadsCountProvider = Provider<int>((ref) {
  return ref.watch(imageUploadNotifierProvider).failedCount;
});

/// Whether image uploads are currently being processed.
final isUploadingImagesProvider = Provider<bool>((ref) {
  return ref.watch(imageUploadNotifierProvider).isProcessing;
});

/// Provides the local file path for a `local://` key.
///
/// Used by [EntityImage] to display a locally compressed image while the
/// upload is still pending. Returns `null` if the task is not found in the
/// queue (e.g., after cleanup or crash recovery).
///
/// Auto-disposed when no longer watched (e.g., widget unmounted or
/// [photoKey] changed from `local://` to an S3 key after upload).
final localImagePathProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, localKey) async {
      final notifier = ref.read(imageUploadNotifierProvider.notifier);
      return notifier.getLocalImagePath(localKey);
    });
