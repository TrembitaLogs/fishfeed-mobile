import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/services/notifications/notification_service.dart';

/// Callback type for fetching remote feeding events from the server.
///
/// [aquariumId] - The aquarium to fetch feedings for.
/// [since] - Fetch events created/updated after this timestamp.
/// Returns list of feeding events or throws on error.
typedef FetchRemoteFeedingsCallback = Future<List<FeedingEvent>> Function({
  required String aquariumId,
  required DateTime since,
});

/// Callback type for handling new feeding events from other family members.
///
/// [event] - The new feeding event.
/// Returns true if the event was processed successfully.
typedef OnFamilyFeedingCallback = Future<void> Function(FeedingEvent event);

/// Callback type for showing in-app toast notifications.
///
/// [message] - The message to display.
typedef ShowToastCallback = void Function(String message);

/// Configuration for FamilySyncService.
class FamilySyncConfig {
  const FamilySyncConfig({
    this.pollingInterval = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 5),
  });

  /// Interval between polling requests (default: 30 seconds).
  final Duration pollingInterval;

  /// Maximum number of consecutive failures before stopping polling.
  final int maxRetries;

  /// Delay between retries after a failure.
  final Duration retryDelay;
}

/// Service for synchronizing family feeding events in real-time.
///
/// Implements periodic polling (MVP) with infrastructure for WebSocket (v2).
/// Handles:
/// - Polling for new feeding events from family members
/// - Cancelling local notifications when another user feeds
/// - Showing in-app toasts for family feeding events
/// - Graceful offline handling
///
/// Example:
/// ```dart
/// final familySyncService = FamilySyncService(
///   currentUserId: 'user123',
///   fetchRemoteFeedings: (aquariumId, since) async {
///     return await api.getFeedings(aquariumId, since);
///   },
///   onFamilyFeeding: (event) async {
///     // Update local state with new feeding
///   },
///   showToast: (message) {
///     // Show in-app toast
///   },
/// );
///
/// familySyncService.startPolling(aquariumId: 'aq1');
/// ```
class FamilySyncService with WidgetsBindingObserver {
  FamilySyncService({
    required String currentUserId,
    required FetchRemoteFeedingsCallback fetchRemoteFeedings,
    required OnFamilyFeedingCallback onFamilyFeeding,
    required ShowToastCallback showToast,
    FamilySyncConfig config = const FamilySyncConfig(),
    Connectivity? connectivity,
    NotificationService? notificationService,
  })  : _currentUserId = currentUserId,
        _fetchRemoteFeedings = fetchRemoteFeedings,
        _onFamilyFeeding = onFamilyFeeding,
        _showToast = showToast,
        _config = config,
        _connectivity = connectivity ?? Connectivity(),
        _notificationService = notificationService ?? NotificationService.instance;

  final String _currentUserId;
  final FetchRemoteFeedingsCallback _fetchRemoteFeedings;
  final OnFamilyFeedingCallback _onFamilyFeeding;
  final ShowToastCallback _showToast;
  final FamilySyncConfig _config;
  final Connectivity _connectivity;
  final NotificationService _notificationService;

  // Polling state
  Timer? _pollingTimer;
  String? _activeAquariumId;
  DateTime? _lastSyncTime;
  int _consecutiveFailures = 0;
  bool _isPolling = false;

  // Connectivity state
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  bool _isAppActive = true;

  // Processed events tracking (to avoid duplicates)
  final Set<String> _processedEventIds = {};

  // Event stream for external listeners
  final StreamController<FamilyFeedingEvent> _eventController =
      StreamController<FamilyFeedingEvent>.broadcast();

  /// Stream of family feeding events for external listeners.
  Stream<FamilyFeedingEvent> get familyFeedingEvents => _eventController.stream;

  /// Whether polling is currently active.
  bool get isPolling => _isPolling;

  /// Whether the service is online.
  bool get isOnline => _isOnline;

  /// The aquarium currently being synced.
  String? get activeAquariumId => _activeAquariumId;

  // ============ Lifecycle ============

  /// Initializes the service and starts observing app lifecycle.
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    _startConnectivityMonitoring();
  }

  /// Disposes the service and releases resources.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopPolling();
    _connectivitySubscription?.cancel();
    _eventController.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasActive = _isAppActive;
    _isAppActive = state == AppLifecycleState.resumed;

    if (kDebugMode) {
      debugPrint('FamilySyncService: App lifecycle changed to $state');
    }

    // Resume polling when app becomes active
    if (!wasActive && _isAppActive && _activeAquariumId != null) {
      _resumePolling();
    }

    // Pause polling when app goes to background
    if (wasActive && !_isAppActive) {
      _pausePolling();
    }
  }

  // ============ Connectivity ============

  void _startConnectivityMonitoring() {
    _connectivity.checkConnectivity().then(_updateConnectivityStatus);
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _updateConnectivityStatus(results);

    if (kDebugMode) {
      debugPrint('FamilySyncService: Connectivity changed - online: $_isOnline');
    }

    // Resume polling when connection restored
    if (!wasOnline && _isOnline && _activeAquariumId != null && _isAppActive) {
      _resumePolling();
    }

    // Pause polling when offline
    if (wasOnline && !_isOnline) {
      _pausePolling();
    }
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  // ============ Polling Control ============

  /// Starts polling for a specific aquarium.
  ///
  /// [aquariumId] - The aquarium to monitor for family feeding events.
  void startPolling({required String aquariumId}) {
    if (_activeAquariumId == aquariumId && _isPolling) {
      debugPrint('FamilySyncService: Already polling for $aquariumId');
      return;
    }

    // Stop existing polling if different aquarium
    if (_activeAquariumId != null && _activeAquariumId != aquariumId) {
      stopPolling();
    }

    _activeAquariumId = aquariumId;
    _lastSyncTime = DateTime.now().subtract(const Duration(minutes: 5));
    _consecutiveFailures = 0;
    _isPolling = true;

    if (kDebugMode) {
      debugPrint('FamilySyncService: Starting polling for $aquariumId');
    }

    // Initial fetch
    _fetchAndProcessFeedings();

    // Start periodic polling
    _pollingTimer = Timer.periodic(_config.pollingInterval, (_) {
      _fetchAndProcessFeedings();
    });
  }

  /// Stops all polling.
  void stopPolling() {
    if (kDebugMode) {
      debugPrint('FamilySyncService: Stopping polling');
    }

    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    _activeAquariumId = null;
    _consecutiveFailures = 0;
  }

  void _pausePolling() {
    if (kDebugMode) {
      debugPrint('FamilySyncService: Pausing polling');
    }

    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
  }

  void _resumePolling() {
    if (_activeAquariumId == null) return;

    if (kDebugMode) {
      debugPrint('FamilySyncService: Resuming polling for $_activeAquariumId');
    }

    _isPolling = true;
    _consecutiveFailures = 0;

    // Immediate fetch after resume
    _fetchAndProcessFeedings();

    // Restart timer
    _pollingTimer = Timer.periodic(_config.pollingInterval, (_) {
      _fetchAndProcessFeedings();
    });
  }

  // ============ Fetching & Processing ============

  Future<void> _fetchAndProcessFeedings() async {
    if (!_isOnline || !_isAppActive || _activeAquariumId == null) {
      return;
    }

    try {
      final events = await _fetchRemoteFeedings(
        aquariumId: _activeAquariumId!,
        since: _lastSyncTime ?? DateTime.now().subtract(const Duration(minutes: 5)),
      );

      _consecutiveFailures = 0;
      _lastSyncTime = DateTime.now();

      await _processNewEvents(events);
    } catch (e) {
      _consecutiveFailures++;

      if (kDebugMode) {
        debugPrint('FamilySyncService: Fetch failed ($_consecutiveFailures): $e');
      }

      // Stop polling after max retries
      if (_consecutiveFailures >= _config.maxRetries) {
        if (kDebugMode) {
          debugPrint('FamilySyncService: Max retries reached, stopping polling');
        }
        _pausePolling();

        // Schedule retry after delay
        Future.delayed(_config.retryDelay, () {
          if (_activeAquariumId != null && _isOnline && _isAppActive) {
            _resumePolling();
          }
        });
      }
    }
  }

  Future<void> _processNewEvents(List<FeedingEvent> events) async {
    for (final event in events) {
      // Skip already processed events
      if (_processedEventIds.contains(event.id)) {
        continue;
      }

      // Skip own events
      if (event.completedBy == _currentUserId) {
        _processedEventIds.add(event.id);
        continue;
      }

      // Process family member's feeding
      await _handleFamilyFeeding(event);
      _processedEventIds.add(event.id);

      // Keep processed set size reasonable
      if (_processedEventIds.length > 1000) {
        final toRemove = _processedEventIds.take(500).toList();
        _processedEventIds.removeAll(toRemove);
      }
    }
  }

  Future<void> _handleFamilyFeeding(FeedingEvent event) async {
    if (kDebugMode) {
      debugPrint('FamilySyncService: Processing family feeding from ${event.completedByName}');
    }

    // 1. Cancel any pending local notification for this feeding
    await _cancelNotificationForFeeding(event);

    // 2. Show in-app toast
    final userName = event.completedByName ?? 'Family member';
    _showToast('Feeding completed: $userName');

    // 3. Notify external callback
    await _onFamilyFeeding(event);

    // 4. Emit event for listeners
    _eventController.add(FamilyFeedingEvent(
      event: event,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _cancelNotificationForFeeding(FeedingEvent event) async {
    // Generate notification ID from feeding event
    // This matches the logic in NotificationService
    final eventIdHash = event.localId?.hashCode ?? event.id.hashCode;
    final notificationEventId = eventIdHash.abs() % 100000;

    if (kDebugMode) {
      debugPrint('FamilySyncService: Cancelling notification for event $notificationEventId');
    }

    await _notificationService.cancelScheduledNotification(notificationEventId);
  }

  // ============ Manual Sync ============

  /// Triggers an immediate sync.
  ///
  /// Use this when user manually refreshes or after marking a feeding.
  Future<void> syncNow() async {
    if (_activeAquariumId == null) return;

    if (kDebugMode) {
      debugPrint('FamilySyncService: Manual sync triggered');
    }

    await _fetchAndProcessFeedings();
  }

  /// Clears processed events cache.
  ///
  /// Call this when switching aquariums or users.
  void clearCache() {
    _processedEventIds.clear();
    _lastSyncTime = null;
  }

  // ============ Conflict Resolution ============

  /// Resolves conflicts when multiple users feed simultaneously.
  ///
  /// Returns the winning event based on timestamp (first one wins).
  FeedingEvent? resolveConflict(List<FeedingEvent> conflictingEvents) {
    if (conflictingEvents.isEmpty) return null;
    if (conflictingEvents.length == 1) return conflictingEvents.first;

    // Sort by feeding time - earliest wins
    final sorted = List<FeedingEvent>.from(conflictingEvents)
      ..sort((a, b) => a.feedingTime.compareTo(b.feedingTime));

    final winner = sorted.first;

    if (kDebugMode) {
      debugPrint(
        'FamilySyncService: Conflict resolved - winner: ${winner.completedByName} '
        'at ${winner.feedingTime}',
      );
    }

    return winner;
  }

  /// Checks if a feeding conflicts with existing events.
  ///
  /// [newEvent] - The new feeding to check.
  /// [existingEvents] - List of existing feedings for the same schedule.
  /// [conflictWindow] - Time window for detecting conflicts (default: 5 minutes).
  bool hasConflict(
    FeedingEvent newEvent,
    List<FeedingEvent> existingEvents, {
    Duration conflictWindow = const Duration(minutes: 5),
  }) {
    for (final existing in existingEvents) {
      final timeDiff = newEvent.feedingTime.difference(existing.feedingTime).abs();
      if (timeDiff <= conflictWindow) {
        return true;
      }
    }
    return false;
  }

  // ============ WebSocket Preparation (v2) ============

  /// Placeholder for WebSocket connection.
  ///
  /// Will be implemented in v2 to replace polling.
  // ignore: unused_element
  Future<void> _connectWebSocket() async {
    // TODO: Implement WebSocket connection for v2
    // - Connect to wss://api.fishfeed.app/ws
    // - Subscribe to aquarium channel
    // - Handle real-time feeding events
  }

  /// Placeholder for WebSocket disconnection.
  // ignore: unused_element
  void _disconnectWebSocket() {
    // TODO: Implement WebSocket disconnection for v2
  }
}

/// Event wrapper for family feeding notifications.
class FamilyFeedingEvent {
  const FamilyFeedingEvent({
    required this.event,
    required this.timestamp,
  });

  /// The feeding event from a family member.
  final FeedingEvent event;

  /// When this event was received.
  final DateTime timestamp;
}
