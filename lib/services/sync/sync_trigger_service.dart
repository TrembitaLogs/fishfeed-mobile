import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/services/connectivity/connectivity_service.dart';
import 'package:fishfeed/services/lifecycle/app_lifecycle_service.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

/// Configuration for sync trigger behavior.
class SyncTriggerConfig {
  const SyncTriggerConfig({
    this.resumeDebounce = const Duration(seconds: 5),
    this.cooldownPeriod = const Duration(seconds: 30),
  });

  /// Debounce duration for app resume events.
  ///
  /// Prevents frequent syncs when user rapidly switches apps.
  final Duration resumeDebounce;

  /// Minimum time between automatic syncs.
  ///
  /// Prevents excessive sync operations.
  final Duration cooldownPeriod;
}

/// Centralized manager for all sync triggers.
///
/// Handles automatic sync triggering based on:
/// - App coming to foreground (with debounce)
/// - Connectivity restored (offline -> online)
///
/// Features:
/// - Debounce for rapid app switching (default 5 seconds)
/// - Cooldown period between auto-syncs (default 30 seconds)
/// - Mutex pattern to prevent concurrent syncs
/// - Integrates with AppLifecycleService and ConnectivityService
///
/// Example:
/// ```dart
/// final triggerService = ref.watch(syncTriggerServiceProvider);
/// // Service automatically triggers syncs based on lifecycle/connectivity
/// ```
class SyncTriggerService {
  SyncTriggerService({
    required SyncService syncService,
    required AppLifecycleService lifecycleService,
    required ConnectivityService connectivityService,
    SyncTriggerConfig config = const SyncTriggerConfig(),
  }) : _syncService = syncService,
       _lifecycleService = lifecycleService,
       _connectivityService = connectivityService,
       _config = config;

  final SyncService _syncService;
  final AppLifecycleService _lifecycleService;
  final ConnectivityService _connectivityService;
  final SyncTriggerConfig _config;

  StreamSubscription<LifecycleEventData>? _lifecycleSubscription;
  StreamSubscription<bool>? _connectivitySubscription;

  Timer? _debounceTimer;
  DateTime? _lastAutoSyncTime;
  bool _isSyncing = false;
  bool _isInitialized = false;
  bool _wasOffline = false;

  /// Whether the service is initialized and listening.
  bool get isInitialized => _isInitialized;

  /// Whether a sync is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Time of the last automatic sync.
  DateTime? get lastAutoSyncTime => _lastAutoSyncTime;

  /// Whether cooldown period is active.
  bool get isInCooldown {
    if (_lastAutoSyncTime == null) return false;
    final elapsed = DateTime.now().difference(_lastAutoSyncTime!);
    return elapsed < _config.cooldownPeriod;
  }

  /// Remaining cooldown time, or zero if not in cooldown.
  Duration get remainingCooldown {
    if (_lastAutoSyncTime == null) return Duration.zero;
    final elapsed = DateTime.now().difference(_lastAutoSyncTime!);
    final remaining = _config.cooldownPeriod - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Initializes the service and starts listening for triggers.
  void initialize() {
    if (_isInitialized) return;

    // Track initial connectivity state
    _wasOffline = !_connectivityService.isOnline;

    // Listen for lifecycle events
    _lifecycleSubscription = _lifecycleService.eventStream.listen(
      _onLifecycleEvent,
      onError: (Object error) {
        debugPrint('SyncTriggerService: Lifecycle stream error: $error');
      },
    );

    // Listen for connectivity changes
    _connectivitySubscription = _connectivityService.statusStream.listen(
      _onConnectivityChanged,
      onError: (Object error) {
        debugPrint('SyncTriggerService: Connectivity stream error: $error');
      },
    );

    _isInitialized = true;
    debugPrint('SyncTriggerService: Initialized');
  }

  /// Stops listening and disposes resources.
  void dispose() {
    _lifecycleSubscription?.cancel();
    _lifecycleSubscription = null;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _isInitialized = false;
    debugPrint('SyncTriggerService: Disposed');
  }

  /// Handles lifecycle events.
  void _onLifecycleEvent(LifecycleEventData event) {
    if (event.event == AppLifecycleEvent.resumed) {
      debugPrint('SyncTriggerService: App resumed, scheduling debounced sync');
      _scheduleDebouncedSync();
    }
  }

  /// Handles connectivity changes.
  void _onConnectivityChanged(bool isOnline) {
    if (isOnline && _wasOffline) {
      debugPrint('SyncTriggerService: Connectivity restored, triggering sync');
      _triggerSync(reason: 'connectivity_restored');
    }
    _wasOffline = !isOnline;
  }

  /// Schedules a debounced sync after app resume.
  ///
  /// Cancels any pending debounce timer and starts a new one.
  /// This prevents multiple syncs when user rapidly switches apps.
  void _scheduleDebouncedSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_config.resumeDebounce, () {
      _triggerSync(reason: 'app_resumed');
    });
  }

  /// Triggers a sync if conditions are met.
  ///
  /// Checks:
  /// - Not already syncing (mutex)
  /// - Not in cooldown period
  /// - Device is online
  Future<void> _triggerSync({required String reason}) async {
    // Mutex: prevent concurrent syncs
    if (_isSyncing) {
      debugPrint('SyncTriggerService: Sync already in progress, skipping');
      return;
    }

    // Check cooldown
    if (isInCooldown) {
      debugPrint(
        'SyncTriggerService: In cooldown (${remainingCooldown.inSeconds}s remaining), skipping',
      );
      return;
    }

    // Check connectivity
    if (!_connectivityService.isOnline) {
      debugPrint('SyncTriggerService: Offline, skipping sync');
      return;
    }

    // Note: We always sync even if there's nothing pending locally,
    // because we may need to fetch new data from the server (e.g., after login).
    // The sync service will handle the logic of what to download/upload.

    _isSyncing = true;
    debugPrint('SyncTriggerService: Starting sync (reason: $reason)');

    try {
      final syncedCount = await _syncService.syncAll();
      _lastAutoSyncTime = DateTime.now();
      debugPrint(
        'SyncTriggerService: Sync completed, $syncedCount items synced',
      );
    } catch (e) {
      debugPrint('SyncTriggerService: Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Manually triggers a sync, bypassing cooldown.
  ///
  /// Useful for user-initiated sync actions.
  /// Still respects the mutex (won't sync if already syncing).
  Future<int> syncNow() async {
    if (_isSyncing) {
      debugPrint('SyncTriggerService: Sync already in progress');
      return 0;
    }

    _isSyncing = true;
    debugPrint('SyncTriggerService: Manual sync triggered');

    try {
      final syncedCount = await _syncService.syncNow();
      _lastAutoSyncTime = DateTime.now();
      return syncedCount;
    } finally {
      _isSyncing = false;
    }
  }

  /// Resets the cooldown timer.
  ///
  /// Useful for testing or when you want to force a sync on next trigger.
  void resetCooldown() {
    _lastAutoSyncTime = null;
    debugPrint('SyncTriggerService: Cooldown reset');
  }
}

// ============ Riverpod Providers ============

/// Provider for [SyncTriggerService].
///
/// Automatically initializes the service and disposes on provider dispose.
/// Also listens for authentication state changes to trigger sync after login.
///
/// Usage:
/// ```dart
/// // Just watching this provider is enough to activate sync triggers
/// ref.watch(syncTriggerServiceProvider);
/// ```
final syncTriggerServiceProvider = Provider<SyncTriggerService>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final lifecycleService = ref.watch(appLifecycleServiceProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);

  final service = SyncTriggerService(
    syncService: syncService,
    lifecycleService: lifecycleService,
    connectivityService: connectivityService,
  );

  service.initialize();

  // Listen for authentication state changes to trigger sync after login
  bool wasAuthenticated = false;
  ref.listen<AuthenticationState>(authNotifierProvider, (previous, next) {
    final isNowAuthenticated = next.isAuthenticated;

    // Trigger sync when user just logged in (was not authenticated, now is)
    if (!wasAuthenticated && isNowAuthenticated) {
      debugPrint('SyncTriggerService: User logged in, triggering sync');
      // Use syncNow which bypasses cooldown for immediate data fetch
      service.syncNow();
    }

    wasAuthenticated = isNowAuthenticated;
  });

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for checking if sync trigger is in cooldown.
final syncTriggerCooldownProvider = Provider<bool>((ref) {
  final service = ref.watch(syncTriggerServiceProvider);
  return service.isInCooldown;
});

/// Provider for checking if a triggered sync is in progress.
final isTriggerSyncingProvider = Provider<bool>((ref) {
  final service = ref.watch(syncTriggerServiceProvider);
  return service.isSyncing;
});
