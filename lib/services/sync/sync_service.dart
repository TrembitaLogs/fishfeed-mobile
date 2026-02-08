import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/feeding_log_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/data/datasources/remote/api_client.dart';
import 'package:fishfeed/data/models/sync_metadata_model.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/services/sync/change_tracker.dart';
import 'package:fishfeed/services/sync/conflict_resolver.dart';

/// State of the sync service.
enum SyncState {
  /// No sync operation in progress.
  idle,

  /// Sync operation is currently running.
  syncing,

  /// Last sync operation completed successfully.
  success,

  /// Last sync operation failed with an error.
  error,
}

/// Result of a unified sync operation.
class SyncResult {
  const SyncResult({
    required this.uploadedCount,
    required this.downloadedCount,
    this.conflicts = const [],
    this.deletedLocally = const [],
    this.errors = const [],
    this.hasMore = false,
  });

  /// Number of local changes uploaded to server.
  final int uploadedCount;

  /// Number of server changes downloaded to local.
  final int downloadedCount;

  /// Conflicts that require manual resolution.
  final List<SyncConflict<Map<String, dynamic>>> conflicts;

  /// IDs of entities deleted locally based on server response.
  final List<String> deletedLocally;

  /// Error messages encountered during sync.
  final List<String> errors;

  /// Whether there are more changes to sync (pagination).
  final bool hasMore;

  /// Total number of items processed.
  int get totalProcessed => uploadedCount + downloadedCount;

  /// Whether the sync completed without errors.
  bool get isSuccess => errors.isEmpty;

  @override
  String toString() =>
      'SyncResult(uploaded: $uploadedCount, downloaded: $downloadedCount, '
      'conflicts: ${conflicts.length}, errors: ${errors.length})';
}

/// Configuration for unified sync behavior.
class SyncConfig {
  const SyncConfig({
    this.initialDelay = const Duration(seconds: 1),
    this.maxRetries = 5,
    this.maxDelay = const Duration(seconds: 32),
    this.pageSize = 100,
    this.syncTimeout = const Duration(seconds: 30),
  });

  /// Initial delay before first retry.
  final Duration initialDelay;

  /// Maximum number of retry attempts.
  final int maxRetries;

  /// Maximum delay between retries (cap for exponential backoff).
  final Duration maxDelay;

  /// Number of changes to process in a single request.
  final int pageSize;

  /// Timeout for sync requests.
  final Duration syncTimeout;

  /// Calculates delay for a given retry attempt using exponential backoff.
  Duration getDelayForRetry(int retryCount) {
    final delayMs = initialDelay.inMilliseconds * (1 << retryCount);
    final cappedDelayMs = delayMs.clamp(0, maxDelay.inMilliseconds);
    return Duration(milliseconds: cappedDelayMs);
  }
}

/// Unified sync service for all entities.
///
/// Uses the standard POST /sync endpoint format:
/// Request:  { changes: [...], last_sync_at: "..." }
/// Response: { server_state: {...}, conflicts: [...], sync_token: "..." }
///
/// Features:
/// - Single endpoint for all entity types
/// - Bidirectional sync (push local changes, pull server changes)
/// - Conflict detection and resolution
/// - Delta sync using last_sync_at timestamp
/// - Exponential backoff retry logic
/// - Connectivity awareness
///
/// Example:
/// ```dart
/// final syncService = SyncService(
///   apiClient: apiClient,
///   aquariumDs: aquariumDs,
///   fishDs: fishDs,
///   feedingDs: feedingDs,
/// );
///
/// syncService.startListening();
///
/// // Listen to sync state
/// syncService.stateStream.listen((state) {
///   print('Sync state: $state');
/// });
/// ```
class SyncService {
  SyncService({
    required ApiClient apiClient,
    required AquariumLocalDataSource aquariumDs,
    required FishLocalDataSource fishDs,
    required FeedingLogLocalDataSource feedingLogDs,
    required ScheduleLocalDataSource scheduleDs,
    required AuthLocalDataSource authLocalDs,
    SyncConfig config = const SyncConfig(),
    Connectivity? connectivity,
    Logger? logger,
    ConflictResolver? conflictResolver,
  }) : _apiClient = apiClient,
       _aquariumDs = aquariumDs,
       _fishDs = fishDs,
       _feedingLogDs = feedingLogDs,
       _scheduleDs = scheduleDs,
       _authLocalDs = authLocalDs,
       _config = config,
       _connectivity = connectivity ?? Connectivity(),
       _logger = logger ?? Logger(printer: PrettyPrinter(methodCount: 0)),
       _conflictResolver = conflictResolver ?? ConflictResolver(),
       _changeTracker = ChangeTracker(
         aquariumDs: aquariumDs,
         fishDs: fishDs,
         authLocalDs: authLocalDs,
         feedingLogDs: feedingLogDs,
         newScheduleDs: scheduleDs,
       );

  final ApiClient _apiClient;
  final AquariumLocalDataSource _aquariumDs;
  final FishLocalDataSource _fishDs;
  final FeedingLogLocalDataSource _feedingLogDs;
  final ScheduleLocalDataSource _scheduleDs;
  final AuthLocalDataSource _authLocalDs;
  final SyncConfig _config;
  final Connectivity _connectivity;
  final Logger _logger;
  // ignore: unused_field - reserved for local conflict detection
  final ConflictResolver _conflictResolver;
  final ChangeTracker _changeTracker;

  /// Callback invoked when user profile is updated from server sync.
  void Function(User)? onUserProfileUpdated;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _retryTimer;
  bool _isProcessing = false;
  bool _isOnline = true;
  int _currentRetryCount = 0;
  String? _lastError;
  DateTime? _lastSyncTime;

  // Sync state management
  SyncState _currentState = SyncState.idle;
  final StreamController<SyncState> _stateController =
      StreamController<SyncState>.broadcast();

  // Conflict management
  final List<SyncConflict<Map<String, dynamic>>> _pendingConflicts = [];
  final StreamController<SyncConflict<Map<String, dynamic>>>
  _conflictController =
      StreamController<SyncConflict<Map<String, dynamic>>>.broadcast();

  // Feeding conflict stream for auto-resolved feeding_log conflicts (UI toast)
  final StreamController<SyncConflict<Map<String, dynamic>>>
  _feedingConflictController =
      StreamController<SyncConflict<Map<String, dynamic>>>.broadcast();

  /// Stream of sync state changes for UI updates.
  Stream<SyncState> get stateStream => _stateController.stream;

  /// Current sync state.
  SyncState get currentState => _currentState;

  /// Whether the sync service is currently processing.
  bool get isProcessing => _isProcessing;

  /// Whether the device is currently online.
  bool get isOnline => _isOnline;

  /// Whether there are changes waiting to be synced.
  bool get hasPendingChanges => _changeTracker.hasChanges;

  /// Number of pending changes.
  int get pendingChangesCount => _changeTracker.pendingChangesCount;

  /// Alias for pendingChangesCount for backward compatibility.
  int get pendingCount => pendingChangesCount;

  /// Number of unsynced feeding logs.
  int get unsyncedFeedingCount => _feedingLogDs.getUnsyncedCount();

  /// Alias for hasPendingChanges for backward compatibility.
  bool get hasPendingOperations => hasPendingChanges;

  /// Whether there are unsynced feeding events.
  bool get hasUnsyncedFeedings => unsyncedFeedingCount > 0;

  /// Last error message from sync attempt.
  String? get lastError => _lastError;

  /// Last successful sync timestamp.
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Stream of detected conflicts that require manual resolution.
  Stream<SyncConflict<Map<String, dynamic>>> get conflictStream =>
      _conflictController.stream;

  /// Stream of auto-resolved feeding_log conflicts (for UI toast notifications).
  ///
  /// Emits when a feeding_log conflict is automatically resolved by
  /// accepting the server version (e.g., another family member already fed).
  Stream<SyncConflict<Map<String, dynamic>>> get feedingConflictStream =>
      _feedingConflictController.stream;

  /// List of pending conflicts awaiting manual resolution.
  List<SyncConflict<Map<String, dynamic>>> get pendingConflicts =>
      List.unmodifiable(_pendingConflicts);

  /// Whether there are unresolved conflicts.
  bool get hasUnresolvedConflicts => _pendingConflicts.isNotEmpty;

  /// Number of pending conflicts.
  int get pendingConflictCount => _pendingConflicts.length;

  // ============ Lifecycle ============

  /// Starts listening for connectivity changes.
  ///
  /// Automatically triggers sync when connection is restored.
  Future<void> startListening() async {
    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _updateConnectivityStatus(results);

    // Listen for changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Initial sync when online
    if (_isOnline) {
      _logger.i('SyncService: Starting initial sync');
      unawaited(syncAll());
    }
  }

  /// Stops listening for connectivity changes.
  void stopListening() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// Disposes the service and releases resources.
  void dispose() {
    stopListening();
    _stateController.close();
    _conflictController.close();
    _feedingConflictController.close();
  }

  void _updateState(SyncState state) {
    _currentState = state;
    _stateController.add(state);
  }

  // ============ Main Sync Methods ============

  /// Performs a full sync: uploads local changes and downloads server changes.
  ///
  /// Returns the total number of items synced (uploaded + downloaded).
  Future<int> syncAll() async {
    final result = await syncAllWithResult();
    return result.totalProcessed;
  }

  /// Performs a full sync and returns detailed result.
  ///
  /// Use this when you need detailed sync information (conflicts, errors, etc.).
  Future<SyncResult> syncAllWithResult() async {
    if (_isProcessing) {
      _logger.d('SyncService: Already processing, skipping');
      return const SyncResult(uploadedCount: 0, downloadedCount: 0);
    }

    if (!_isOnline) {
      _logger.d('SyncService: Offline, skipping sync');
      return const SyncResult(uploadedCount: 0, downloadedCount: 0);
    }

    _isProcessing = true;
    _updateState(SyncState.syncing);
    _lastError = null;

    try {
      final result = await _performSync().timeout(
        _config.syncTimeout,
        onTimeout: () {
          _logger.w('SyncService: Sync timed out');
          throw TimeoutException('Sync timed out');
        },
      );

      if (result.isSuccess) {
        _updateState(SyncState.success);
        _lastSyncTime = DateTime.now();
        _currentRetryCount = 0;
        _logger.i('SyncService: Sync completed - $result');
      } else {
        _lastError = result.errors.join(', ');
        _updateState(SyncState.error);
        _logger.w('SyncService: Sync completed with errors - $result');
        _scheduleRetryIfNeeded();
      }

      return result;
    } catch (e) {
      _lastError = e.toString();
      _updateState(SyncState.error);
      _logger.e('SyncService: Sync failed', error: e);
      _scheduleRetryIfNeeded();
      return SyncResult(
        uploadedCount: 0,
        downloadedCount: 0,
        errors: [e.toString()],
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Performs delta sync using last_sync_at timestamp.
  ///
  /// Only syncs changes since the last successful sync.
  /// Returns the total number of items synced.
  Future<int> syncDelta() async {
    final lastSyncAt = _getSyncMetadata()?.lastSyncAt;
    if (lastSyncAt == null) {
      // No previous sync, do full sync
      return syncAll();
    }

    final result = await _performSync(lastSyncAt: lastSyncAt);
    return result.totalProcessed;
  }

  /// Manually triggers a sync, resetting retry count.
  ///
  /// Returns the total number of items synced.
  Future<int> syncNow() async {
    _currentRetryCount = 0;

    // Refresh connectivity status
    final results = await _connectivity.checkConnectivity();
    _updateConnectivityStatus(results);

    if (!_isOnline) {
      _logger.w('SyncService: Cannot sync, device is offline');
      return 0;
    }

    return syncAll();
  }

  // ============ Core Sync Logic ============

  Future<SyncResult> _performSync({DateTime? lastSyncAt}) async {
    final changes = _changeTracker.collectAllChanges();
    final metadata = _getSyncMetadata();
    final effectiveLastSyncAt = lastSyncAt ?? metadata?.lastSyncAt;

    _logger.i('SyncService: Sending ${changes.length} changes to server');

    // Build request payload
    final payload = {
      'changes': changes.map((c) => c.toJson()).toList(),
      'last_sync_at': effectiveLastSyncAt?.toIso8601String(),
      'page_size': _config.pageSize,
    };

    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/sync',
        data: payload,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Sync failed with status ${response.statusCode}',
        );
      }

      final data = response.data;
      if (data == null) {
        // No data returned, mark all changes as synced
        await _markChangesAsSynced(changes);
        return SyncResult(uploadedCount: changes.length, downloadedCount: 0);
      }

      return await _processSyncResponse(data, changes);
    } on DioException catch (e) {
      _logger.e('SyncService: Network error', error: e);
      return SyncResult(
        uploadedCount: 0,
        downloadedCount: 0,
        errors: [e.message ?? 'Network error'],
      );
    }
  }

  Future<SyncResult> _processSyncResponse(
    Map<String, dynamic> data,
    List<SyncChange> sentChanges,
  ) async {
    int downloadedCount = 0;
    final errors = <String>[];
    final conflicts = <SyncConflict<Map<String, dynamic>>>[];
    final deletedLocally = <String>[];

    // Handle synced changes (our changes that were accepted)
    final syncedIds = _extractSyncedIds(data);
    await _markChangesByIdAsSynced(syncedIds, sentChanges);

    // Purge soft-deleted entities that have been synced to server
    await _purgeSyncedDeletions();

    // Handle server_state - apply server data to local storage
    final serverState = data['server_state'] as Map<String, dynamic>?;
    if (serverState != null) {
      downloadedCount += await _applyServerState(serverState);
    }

    // Handle deleted entities
    final deleted = serverState?['deleted'] as Map<String, dynamic>?;
    if (deleted != null) {
      deletedLocally.addAll(await _applyServerDeletions(deleted));
    }

    // Handle conflicts
    final serverConflicts = data['conflicts'] as List<dynamic>?;
    if (serverConflicts != null) {
      for (final conflictData in serverConflicts) {
        final conflict = _parseConflict(conflictData as Map<String, dynamic>);
        if (conflict != null) {
          // Auto-resolve feeding_log conflicts with server_wins resolution
          if (conflict.entityType == 'feeding_log' &&
              conflict.resolution == ConflictResolution.useServer) {
            await _autoResolveFeedingConflict(conflict);
            conflicts.add(conflict);
          } else {
            // Manual resolution needed
            conflicts.add(conflict);
            _pendingConflicts.add(conflict);
            _conflictController.add(conflict);
          }
        }
      }
    }

    // Save sync token
    final syncToken = data['sync_token'] as String?;
    if (syncToken != null) {
      await _saveSyncMetadata(syncToken: syncToken);
    }

    final hasMore = data['has_more'] as bool? ?? false;

    return SyncResult(
      uploadedCount: syncedIds.length,
      downloadedCount: downloadedCount,
      conflicts: conflicts,
      deletedLocally: deletedLocally,
      errors: errors,
      hasMore: hasMore,
    );
  }

  List<String> _extractSyncedIds(Map<String, dynamic> data) {
    final ids = <String>[];

    // Try synced_ids first (legacy format)
    if (data['synced_ids'] != null) {
      final syncedIds = data['synced_ids'] as List<dynamic>;
      ids.addAll(syncedIds.map((id) => id.toString()));
    }

    // Also check synced_changes (standard format)
    if (data['synced_changes'] != null) {
      final syncedChanges = data['synced_changes'] as List<dynamic>;
      for (final change in syncedChanges) {
        if (change is Map<String, dynamic>) {
          final id = change['entity_id']?.toString();
          if (id != null) ids.add(id);
        }
      }
    }

    return ids;
  }

  // ============ Apply Server State ============

  Future<int> _applyServerState(Map<String, dynamic> serverState) async {
    int appliedCount = 0;

    // Apply aquariums
    final aquariums = serverState['aquariums'] as List<dynamic>?;
    if (aquariums != null) {
      for (final aquariumData in aquariums) {
        await _aquariumDs.applyServerUpdate(
          aquariumData as Map<String, dynamic>,
        );
        appliedCount++;
      }
    }

    // Apply fish
    final fish = serverState['fish'] as List<dynamic>?;
    if (fish != null) {
      for (final fishData in fish) {
        await _fishDs.applyServerUpdate(fishData as Map<String, dynamic>);
        appliedCount++;
      }
    }

    // Apply feeding_logs
    final feedingLogs = serverState['feeding_logs'] as List<dynamic>?;
    if (feedingLogs != null) {
      for (final logData in feedingLogs) {
        await _feedingLogDs.applyServerUpdate(logData as Map<String, dynamic>);
        appliedCount++;
      }
    }

    // Apply schedules
    final schedules = serverState['schedules'] as List<dynamic>?;
    if (schedules != null) {
      for (final scheduleData in schedules) {
        await _scheduleDs.applyServerUpdate(
          scheduleData as Map<String, dynamic>,
        );
        appliedCount++;
      }
    }

    // Apply user_profile (dict, not a list)
    final userProfile = serverState['user_profile'] as Map<String, dynamic>?;
    if (userProfile != null) {
      await _authLocalDs.applyServerProfileUpdate(userProfile);
      final updatedUser = _authLocalDs.getCurrentUser();
      if (updatedUser != null) {
        onUserProfileUpdated?.call(updatedUser.toEntity());
      }
      appliedCount++;
    }

    _logger.d('SyncService: Applied $appliedCount server updates');
    return appliedCount;
  }

  Future<List<String>> _applyServerDeletions(
    Map<String, dynamic> deleted,
  ) async {
    final deletedIds = <String>[];

    // Delete aquariums
    final deletedAquariums = deleted['aquariums'] as List<dynamic>?;
    if (deletedAquariums != null) {
      for (final id in deletedAquariums) {
        final idStr = id.toString();
        await _aquariumDs.deleteAquarium(idStr);
        deletedIds.add(idStr);
      }
    }

    // Delete fish
    final deletedFish = deleted['fish'] as List<dynamic>?;
    if (deletedFish != null) {
      for (final id in deletedFish) {
        final idStr = id.toString();
        // Note: Associated feeding logs will remain as orphans but are
        // linked by fishId which no longer exists. This is acceptable
        // as the logs are historical records.
        await _fishDs.deleteFish(idStr);
        deletedIds.add(idStr);
      }
    }

    // Delete feeding_logs
    final deletedFeedingLogs = deleted['feeding_logs'] as List<dynamic>?;
    if (deletedFeedingLogs != null) {
      for (final id in deletedFeedingLogs) {
        final idStr = id.toString();
        // FeedingLog is immutable, but we can still remove it from local storage
        // This is a server-side deletion that we need to reflect locally
        _logger.d('SyncService: Server deleted feeding_log $idStr');
        deletedIds.add(idStr);
      }
    }

    // Delete schedules
    final deletedSchedules = deleted['schedules'] as List<dynamic>?;
    if (deletedSchedules != null) {
      for (final id in deletedSchedules) {
        final idStr = id.toString();
        await _scheduleDs.delete(idStr);
        deletedIds.add(idStr);
      }
    }

    _logger.d('SyncService: Deleted ${deletedIds.length} entities locally');
    return deletedIds;
  }

  // ============ Mark Changes as Synced ============

  Future<void> _markChangesAsSynced(List<SyncChange> changes) async {
    final now = DateTime.now();

    for (final change in changes) {
      switch (change.entityType) {
        case EntityType.aquarium:
          await _aquariumDs.markAsSynced(change.entityId, now);
        case EntityType.fish:
          await _fishDs.markAsSynced(change.entityId, now);
        case EntityType.feedingLog:
          await _feedingLogDs.markAsSynced(change.entityId, now);
        case EntityType.newSchedule:
          await _scheduleDs.markAsSynced(change.entityId, now);
        case EntityType.userProfile:
          await _authLocalDs.markUserSynced(now);
        case EntityType.streak:
        case EntityType.achievement:
        case EntityType.progress:
          // Handle in future
          break;
      }
    }
  }

  Future<void> _markChangesByIdAsSynced(
    List<String> ids,
    List<SyncChange> changes,
  ) async {
    final idSet = ids.toSet();
    final now = DateTime.now();

    for (final change in changes) {
      if (!idSet.contains(change.entityId)) continue;

      switch (change.entityType) {
        case EntityType.aquarium:
          await _aquariumDs.markAsSynced(change.entityId, now);
        case EntityType.fish:
          await _fishDs.markAsSynced(change.entityId, now);
        case EntityType.feedingLog:
          await _feedingLogDs.markAsSynced(change.entityId, now);
        case EntityType.newSchedule:
          await _scheduleDs.markAsSynced(change.entityId, now);
        case EntityType.userProfile:
          await _authLocalDs.markUserSynced(now);
        case EntityType.streak:
        case EntityType.achievement:
        case EntityType.progress:
          break;
      }
    }
  }

  /// Purges soft-deleted entities that have been synced to server.
  ///
  /// This permanently removes entities from local storage after
  /// DELETE operations have been confirmed by the server.
  Future<void> _purgeSyncedDeletions() async {
    // Purge synced soft-deleted aquariums
    await _aquariumDs.purgeSyncedDeletions();

    // Purge synced soft-deleted fish
    await _fishDs.purgeSyncedDeletions();

    _logger.d('SyncService: Purged synced deletions');
  }

  // ============ Conflict Handling ============

  SyncConflict<Map<String, dynamic>>? _parseConflict(
    Map<String, dynamic> conflictData,
  ) {
    try {
      final entityId = conflictData['entity_id']?.toString();
      final entityType = conflictData['entity_type']?.toString();

      if (entityId == null || entityType == null) {
        return null;
      }

      // Format 1: server_data + resolution (feeding_log conflicts)
      // e.g., {"entity_type": "feeding_log", "entity_id": "...",
      //        "resolution": "server_wins", "server_data": {...}}
      final serverData = conflictData['server_data'] as Map<String, dynamic>?;
      final resolutionStr = conflictData['resolution']?.toString();

      if (serverData != null && resolutionStr == 'server_wins') {
        final serverUpdatedAt =
            DateTime.tryParse(
              serverData['acted_at']?.toString() ??
                  serverData['updated_at']?.toString() ??
                  '',
            ) ??
            DateTime.now();

        return SyncConflict<Map<String, dynamic>>(
          entityId: entityId,
          entityType: entityType,
          localVersion: const <String, dynamic>{},
          serverVersion: serverData,
          localUpdatedAt: DateTime.now(),
          serverUpdatedAt: serverUpdatedAt,
          resolution: ConflictResolution.useServer,
        );
      }

      // Format 2: local_version + server_version (standard conflicts)
      final localVersion =
          conflictData['local_version'] as Map<String, dynamic>?;
      final serverVersion =
          conflictData['server_version'] as Map<String, dynamic>?;

      if (localVersion == null || serverVersion == null) {
        return null;
      }

      final localUpdatedAt =
          DateTime.tryParse(
            conflictData['local_updated_at']?.toString() ?? '',
          ) ??
          DateTime.now();
      final serverUpdatedAt =
          DateTime.tryParse(
            conflictData['server_updated_at']?.toString() ?? '',
          ) ??
          DateTime.now();

      return SyncConflict<Map<String, dynamic>>(
        entityId: entityId,
        entityType: entityType,
        localVersion: localVersion,
        serverVersion: serverVersion,
        localUpdatedAt: localUpdatedAt,
        serverUpdatedAt: serverUpdatedAt,
        resolution: ConflictResolution.requireManual,
      );
    } catch (e) {
      _logger.e('SyncService: Failed to parse conflict', error: e);
      return null;
    }
  }

  /// Auto-resolves a feeding_log conflict by accepting the server version.
  ///
  /// This handles the case where another family member already marked
  /// the same feeding. The local optimistic log is deleted and replaced
  /// with the server's version.
  Future<void> _autoResolveFeedingConflict(
    SyncConflict<Map<String, dynamic>> conflict,
  ) async {
    _logger.i(
      'SyncService: Auto-resolving feeding_log conflict ${conflict.entityId}',
    );

    // Delete the local optimistic log
    await _feedingLogDs.delete(conflict.entityId);

    // Apply the server version
    if (conflict.serverVersion.isNotEmpty) {
      await _feedingLogDs.applyServerUpdate(conflict.serverVersion);
    }

    // Emit on feeding conflict stream for UI toast notification
    _feedingConflictController.add(conflict);
  }

  /// Resolves a conflict by keeping the local version.
  Future<bool> resolveConflictWithLocal(String conflictId) async {
    final index = _pendingConflicts.indexWhere((c) => c.entityId == conflictId);
    if (index == -1) return false;

    _pendingConflicts.removeAt(index);
    _logger.i('SyncService: Resolved conflict $conflictId with local version');

    // Trigger re-sync to push local version
    unawaited(syncAll());
    return true;
  }

  /// Resolves a conflict by accepting the server version.
  Future<bool> resolveConflictWithServer(String conflictId) async {
    final index = _pendingConflicts.indexWhere((c) => c.entityId == conflictId);
    if (index == -1) return false;

    final conflict = _pendingConflicts.removeAt(index);
    _logger.i('SyncService: Resolved conflict $conflictId with server version');

    // Apply server version
    await _applyConflictServerVersion(conflict);
    return true;
  }

  Future<void> _applyConflictServerVersion(
    SyncConflict<Map<String, dynamic>> conflict,
  ) async {
    final serverData = conflict.serverVersion;
    final serverUpdatedAt = DateTime.tryParse(
      serverData['updated_at']?.toString() ?? '',
    );

    switch (conflict.entityType) {
      case 'aquarium':
        await _aquariumDs.applyServerUpdate(serverData);
        if (serverUpdatedAt != null) {
          await _aquariumDs.markAsSynced(conflict.entityId, serverUpdatedAt);
        }
      case 'fish':
        await _fishDs.applyServerUpdate(serverData);
        if (serverUpdatedAt != null) {
          await _fishDs.markAsSynced(conflict.entityId, serverUpdatedAt);
        }
      case 'schedule':
        await _scheduleDs.applyServerUpdate(serverData);
        if (serverUpdatedAt != null) {
          await _scheduleDs.markAsSynced(conflict.entityId, serverUpdatedAt);
        }
      case 'feeding_log':
        await _feedingLogDs.applyServerUpdate(serverData);
        if (serverUpdatedAt != null) {
          await _feedingLogDs.markAsSynced(conflict.entityId, serverUpdatedAt);
        }
    }
  }

  // ============ Sync Metadata ============

  SyncMetadataModel? _getSyncMetadata() {
    final box = HiveBoxes.syncMetadata;
    return box.get('default');
  }

  Future<void> _saveSyncMetadata({String? syncToken}) async {
    final box = HiveBoxes.syncMetadata;
    var metadata = box.get('default');

    if (metadata == null) {
      metadata = SyncMetadataModel();
      await box.put('default', metadata);
    }

    metadata.lastSyncAt = DateTime.now().toUtc();
    if (syncToken != null) {
      metadata.syncToken = syncToken;
    }
    await metadata.save();
  }

  // ============ Migration V2 ============

  // ============ Retry Logic ============

  void _scheduleRetryIfNeeded() {
    _retryTimer?.cancel();

    if (!_isOnline) return;
    if (!hasPendingChanges) return;
    if (_currentRetryCount >= _config.maxRetries) {
      _logger.w('SyncService: Max retries reached');
      return;
    }

    final delay = _config.getDelayForRetry(_currentRetryCount);
    _currentRetryCount++;

    _logger.i(
      'SyncService: Scheduling retry $_currentRetryCount/${_config.maxRetries} '
      'in ${delay.inSeconds}s',
    );

    _retryTimer = Timer(delay, () {
      if (_isOnline && hasPendingChanges) {
        syncAll();
      }
    });
  }

  // ============ Connectivity ============

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _updateConnectivityStatus(results);

    _logger.i('SyncService: Connectivity changed - online: $_isOnline');

    if (!wasOnline && _isOnline && hasPendingChanges) {
      _logger.i('SyncService: Connection restored, starting sync');
      _currentRetryCount = 0;
      unawaited(syncAll());
    }
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    _isOnline =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }
}

// ============ Riverpod Providers ============

/// Provider for SyncService.
///
/// Usage:
/// ```dart
/// final syncService = ref.watch(syncServiceProvider);
/// await syncService.syncNow();
/// ```
final syncServiceProvider = Provider<SyncService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final aquariumDs = ref.watch(aquariumLocalDataSourceProvider);
  final fishDs = ref.watch(fishLocalDataSourceProvider);
  final feedingLogDs = ref.watch(feedingLogLocalDataSourceProvider);
  final scheduleDs = ref.watch(scheduleLocalDataSourceProvider);
  final authLocalDs = ref.watch(authLocalDataSourceProvider);

  final service = SyncService(
    apiClient: apiClient,
    aquariumDs: aquariumDs,
    fishDs: fishDs,
    feedingLogDs: feedingLogDs,
    scheduleDs: scheduleDs,
    authLocalDs: authLocalDs,
  );

  service.startListening();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for current unified sync state.
final syncStateProvider = StreamProvider<SyncState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return _syncStateStreamWithInitial(syncService);
});

Stream<SyncState> _syncStateStreamWithInitial(SyncService syncService) async* {
  yield syncService.currentState;
  await for (final state in syncService.stateStream) {
    yield state;
  }
}

/// Provider for checking if unified sync is in progress.
final isSyncingProvider = Provider<bool>((ref) {
  final asyncState = ref.watch(syncStateProvider);
  return asyncState.when(
    data: (state) => state == SyncState.syncing,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for pending changes count.
final pendingSyncCountProvider = Provider<int>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.pendingChangesCount;
});
