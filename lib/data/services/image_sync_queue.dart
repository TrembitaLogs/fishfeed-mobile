import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:fishfeed/data/services/image_upload_task.dart';

/// Queue for managing pending image upload tasks with file-based persistence.
///
/// Stores task metadata as a JSON file and compressed image files
/// in a dedicated directory under `applicationSupportDirectory/image_queue/`.
///
/// Structure:
/// ```
/// applicationSupportDirectory/
/// └── image_queue/
///     ├── queue.json     # Task metadata (list of ImageUploadTask)
///     └── files/         # Compressed image files ({uuid}.webp)
/// ```
///
/// Provides CRUD operations for managing upload tasks:
/// - [enqueue] — adds a new task with its image file
/// - [dequeue] — retrieves the next pending task for processing
/// - [markComplete] — removes a completed task and its file
/// - [markFailed] — records a failure with error details
/// - [recoverStuckTasks] — recovers tasks stuck in 'uploading' after a crash
class ImageSyncQueue {
  /// Creates an [ImageSyncQueue].
  ///
  /// Optionally accepts a [basePath] for testing purposes.
  /// If not provided, uses `getApplicationSupportDirectory()`.
  ImageSyncQueue({@visibleForTesting String? basePath})
    : _testBasePath = basePath;

  static const String _queueDirName = 'image_queue';
  static const String _queueFileName = 'queue.json';
  static const String _filesDirName = 'files';

  final String? _testBasePath;
  String? _cachedBasePath;
  bool _isInitialized = false;

  /// Whether the queue has been initialized (directories created).
  bool get isInitialized => _isInitialized;

  /// Resolves the base path for queue storage.
  ///
  /// Uses [_testBasePath] if provided (for testing), otherwise
  /// falls back to `getApplicationSupportDirectory()`.
  Future<String> get basePath async {
    if (_cachedBasePath != null) {
      return _cachedBasePath!;
    }

    if (_testBasePath != null) {
      _cachedBasePath = _testBasePath;
    } else {
      final dir = await getApplicationSupportDirectory();
      _cachedBasePath = dir.path;
    }

    return _cachedBasePath!;
  }

  /// Path to the queue directory (e.g., `.../image_queue/`).
  Future<String> get queueDirPath async {
    final base = await basePath;
    return '$base/$_queueDirName';
  }

  /// Path to the queue JSON file (e.g., `.../image_queue/queue.json`).
  Future<String> get queueFilePath async {
    final dir = await queueDirPath;
    return '$dir/$_queueFileName';
  }

  /// Path to the files directory (e.g., `.../image_queue/files/`).
  Future<String> get filesDirPath async {
    final dir = await queueDirPath;
    return '$dir/$_filesDirName';
  }

  /// Initializes the queue by creating required directories.
  ///
  /// Creates `image_queue/` and `image_queue/files/` directories
  /// atomically. Safe to call multiple times — subsequent calls are no-ops.
  ///
  /// Must be called before any read/write operations.
  Future<void> initialize() async {
    if (_isInitialized) return;

    final filesDir = Directory(await filesDirPath);
    // Creating files/ dir also creates image_queue/ parent.
    await filesDir.create(recursive: true);

    // Clean up partial atomic writes from a previous crash.
    // The write-then-rename pattern in writeAll() may leave a .tmp file
    // if the app was killed between writeAsString and rename.
    final queuePath = await queueFilePath;
    final tempFile = File('$queuePath.tmp');
    if (tempFile.existsSync()) {
      await tempFile.delete();
    }

    // Ensure queue.json exists with empty array if it doesn't.
    final queueFile = File(queuePath);
    if (!queueFile.existsSync()) {
      await queueFile.writeAsString('[]');
    }

    _isInitialized = true;
  }

  /// Reads all tasks from the queue JSON file.
  ///
  /// Returns an empty list if the file doesn't exist or is empty.
  /// Throws [StateError] if the queue has not been initialized.
  Future<List<ImageUploadTask>> readAll() async {
    _ensureInitialized();

    final file = File(await queueFilePath);
    if (!file.existsSync()) {
      return [];
    }

    final content = await file.readAsString();
    return ImageUploadTask.decodeList(content);
  }

  /// Writes the full task list to the queue JSON file.
  ///
  /// Uses write-then-rename pattern for atomicity — the file is never
  /// in a partially-written state, which protects against app crashes.
  /// Overwrites the existing file contents with the serialized [tasks].
  /// Throws [StateError] if the queue has not been initialized.
  Future<void> writeAll(List<ImageUploadTask> tasks) async {
    _ensureInitialized();

    final queuePath = await queueFilePath;
    final content = ImageUploadTask.encodeList(tasks);

    // Atomic write: write to temp file, then rename.
    final tempFile = File('$queuePath.tmp');
    await tempFile.writeAsString(content, flush: true);
    await tempFile.rename(queuePath);
  }

  /// Checks if a compressed image file exists for the given [taskId].
  Future<bool> fileExists(String taskId) async {
    _ensureInitialized();

    final path = await getFilePath(taskId);
    return File(path).existsSync();
  }

  /// Returns the expected file path for a task's compressed image.
  ///
  /// The file path follows the pattern: `image_queue/files/{taskId}.webp`.
  Future<String> getFilePath(String taskId) async {
    final dir = await filesDirPath;
    return '$dir/$taskId.webp';
  }

  /// Deletes the compressed image file for the given [taskId].
  ///
  /// Returns `true` if the file was deleted, `false` if it didn't exist.
  Future<bool> deleteFile(String taskId) async {
    _ensureInitialized();

    final path = await getFilePath(taskId);
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
      return true;
    }
    return false;
  }

  /// Returns the number of files in the files directory.
  Future<int> get fileCount async {
    _ensureInitialized();

    final dir = Directory(await filesDirPath);
    if (!dir.existsSync()) return 0;

    return dir.listSync().whereType<File>().length;
  }

  // --- CRUD Operations ---

  /// Adds a new image upload task to the queue.
  ///
  /// Saves [imageBytes] as a WebP file in `files/{taskId}.webp`,
  /// then atomically adds the task entry to `queue.json`.
  ///
  /// The file is written first — if it fails, the queue remains unchanged.
  /// If the queue write fails after the file is saved, the file becomes
  /// orphaned but the queue stays consistent.
  ///
  /// Returns the created [ImageUploadTask].
  ///
  /// Throws [StateError] if the queue has not been initialized,
  /// or if a task with [taskId] already exists.
  /// Throws [ArgumentError] if [entityType] is not valid.
  Future<ImageUploadTask> enqueue({
    required String taskId,
    required String entityType,
    required String entityId,
    required Uint8List imageBytes,
    @visibleForTesting DateTime? createdAt,
  }) async {
    _ensureInitialized();

    if (!ImageUploadTask.validEntityTypes.contains(entityType)) {
      throw ArgumentError.value(
        entityType,
        'entityType',
        'Must be one of: ${ImageUploadTask.validEntityTypes.join(', ')}',
      );
    }

    final tasks = await readAll();
    if (tasks.any((t) => t.id == taskId)) {
      throw StateError('Task with id "$taskId" already exists in the queue.');
    }

    // Save file first — if this fails, queue remains unchanged.
    final filePath = await getFilePath(taskId);
    await File(filePath).writeAsBytes(imageBytes, flush: true);

    final task = ImageUploadTask(
      id: taskId,
      entityType: entityType,
      entityId: entityId,
      localPath: filePath,
      createdAt: createdAt ?? DateTime.now(),
    );

    tasks.add(task);
    await writeAll(tasks);

    return task;
  }

  /// Returns the next pending task and marks it as uploading.
  ///
  /// Tasks are dequeued in FIFO order (oldest [createdAt] first).
  /// Returns `null` if no pending tasks are available.
  ///
  /// Throws [StateError] if the queue has not been initialized.
  Future<ImageUploadTask?> dequeue() async {
    _ensureInitialized();

    final tasks = await readAll();

    // Find the oldest pending task.
    ImageUploadTask? candidate;
    for (final task in tasks) {
      if (task.status == ImageUploadStatus.pending) {
        if (candidate == null || task.createdAt.isBefore(candidate.createdAt)) {
          candidate = task;
        }
      }
    }

    if (candidate == null) return null;

    candidate.status = ImageUploadStatus.uploading;
    await writeAll(tasks);

    return candidate;
  }

  /// Marks a task as completed and cleans up its resources.
  ///
  /// Removes the task entry from `queue.json` and deletes the associated
  /// image file from `files/`. The queue is written first — if file deletion
  /// fails, the task is already removed from the queue.
  ///
  /// Returns `true` if the task was found and removed, `false` otherwise.
  ///
  /// Throws [StateError] if the queue has not been initialized.
  Future<bool> markComplete(String taskId) async {
    _ensureInitialized();

    final tasks = await readAll();
    final initialLength = tasks.length;
    tasks.removeWhere((t) => t.id == taskId);

    if (tasks.length == initialLength) {
      return false;
    }

    await writeAll(tasks);
    await deleteFile(taskId);

    return true;
  }

  /// Records a task failure with error details.
  ///
  /// Increments [ImageUploadTask.retryCount], sets [errorMessage],
  /// and changes status to [ImageUploadStatus.failed].
  ///
  /// Returns `true` if the task was found and updated, `false` otherwise.
  ///
  /// Throws [StateError] if the queue has not been initialized.
  Future<bool> markFailed(String taskId, String error) async {
    _ensureInitialized();

    final tasks = await readAll();

    ImageUploadTask? target;
    for (final task in tasks) {
      if (task.id == taskId) {
        target = task;
        break;
      }
    }

    if (target == null) return false;

    target.status = ImageUploadStatus.failed;
    target.retryCount++;
    target.errorMessage = error;

    await writeAll(tasks);

    return true;
  }

  /// Returns all tasks with [ImageUploadStatus.pending] status.
  ///
  /// Results are sorted by [ImageUploadTask.createdAt] (oldest first).
  ///
  /// Throws [StateError] if the queue has not been initialized.
  Future<List<ImageUploadTask>> getPending() async {
    _ensureInitialized();

    final tasks = await readAll();
    return tasks.where((t) => t.status == ImageUploadStatus.pending).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Recovers tasks stuck in 'uploading' status after an app crash.
  ///
  /// Resets all tasks with [ImageUploadStatus.uploading] back to
  /// [ImageUploadStatus.pending] so they can be retried.
  ///
  /// Should be called during queue initialization or app startup.
  /// Returns the number of recovered tasks.
  ///
  /// Throws [StateError] if the queue has not been initialized.
  Future<int> recoverStuckTasks() async {
    _ensureInitialized();

    final tasks = await readAll();
    var recoveredCount = 0;

    for (final task in tasks) {
      if (task.status == ImageUploadStatus.uploading) {
        task.status = ImageUploadStatus.pending;
        recoveredCount++;
      }
    }

    if (recoveredCount > 0) {
      await writeAll(tasks);
    }

    return recoveredCount;
  }

  /// Ensures the queue has been initialized before I/O operations.
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'ImageSyncQueue has not been initialized. '
        'Call initialize() first.',
      );
    }
  }

  /// Resets the initialized flag. Only for testing purposes.
  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
    _cachedBasePath = null;
  }
}
