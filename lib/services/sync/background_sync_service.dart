import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:fishfeed/core/services/secure_storage_service.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/feeding_event_model.dart';

/// Unique name for the periodic background sync task.
const String kBackgroundSyncTaskName = 'fishfeed_background_sync';

/// Task identifier for iOS BGTaskScheduler.
const String kBackgroundSyncTaskIdentifier = 'com.fishfeed.app.backgroundSync';

/// Key for storing the last background sync timestamp.
const String _lastBackgroundSyncKey = 'last_background_sync';

/// Key for storing the background sync error count.
const String _backgroundSyncErrorCountKey = 'background_sync_error_count';

/// Maximum consecutive errors before increasing backoff.
const int _maxConsecutiveErrors = 3;

/// Resolves the base URL based on platform.
/// For physical iOS device uses API_BASE_URL_IOS_DEVICE if set.
String _resolveBaseUrl() {
  final defaultUrl = dotenv.env['API_BASE_URL'] ?? '';
  final iosDeviceUrl = dotenv.env['API_BASE_URL_IOS_DEVICE'];

  if (Platform.isIOS && iosDeviceUrl != null && iosDeviceUrl.isNotEmpty) {
    final isSimulator = Platform.environment.containsKey(
      'SIMULATOR_DEVICE_NAME',
    );
    if (!isSimulator) {
      debugPrint('BackgroundSync: Using iOS device URL');
      return iosDeviceUrl;
    }
  }

  return defaultUrl;
}

/// Frequency for periodic background sync (minimum on Android is 15 minutes).
const Duration kBackgroundSyncFrequency = Duration(minutes: 15);

/// Top-level callback dispatcher for Workmanager.
///
/// This function runs in a separate isolate when the background task executes.
/// It must be a top-level function (not a class method) and annotated with
/// @pragma('vm:entry-point') for Flutter 3.1+ and obfuscated builds.
@pragma('vm:entry-point')
void backgroundSyncCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint('BackgroundSync: Task started - $taskName');

    try {
      // Check connectivity first
      final connectivity = Connectivity();
      final connectivityResults = await connectivity.checkConnectivity();
      final isOnline =
          connectivityResults.isNotEmpty &&
          !connectivityResults.contains(ConnectivityResult.none);

      if (!isOnline) {
        debugPrint('BackgroundSync: Offline, skipping sync');
        return true; // Return true to not reschedule immediately
      }

      // Perform lightweight background sync
      final result = await _performBackgroundSync();

      // Update last sync timestamp on success
      if (result) {
        await _updateLastBackgroundSyncTime();
        await _resetErrorCount();
        debugPrint('BackgroundSync: Sync completed successfully');
      } else {
        await _incrementErrorCount();
        debugPrint('BackgroundSync: Sync completed with failures');
      }

      return true; // Task completed
    } catch (e, stackTrace) {
      debugPrint('BackgroundSync: Error - $e');
      debugPrint('BackgroundSync: StackTrace - $stackTrace');
      await _incrementErrorCount();
      return true; // Return true to prevent immediate retry, use scheduled retry instead
    }
  });
}

/// Performs the actual background sync operation.
///
/// This is a lightweight sync that:
/// - Initializes Hive in the background isolate
/// - Gets auth token from secure storage
/// - Syncs only unsynced feeding events
/// - Uses silent error handling (no UI)
Future<bool> _performBackgroundSync() async {
  debugPrint('BackgroundSync: Performing lightweight sync');

  try {
    // 1. Initialize Hive in background isolate
    await _initializeHiveForBackground();

    // 2. Get unsynced feeding events
    final feedingEventsBox = await Hive.openBox<dynamic>(
      HiveBoxNames.feedingEvents,
    );
    final unsyncedEvents = feedingEventsBox.values
        .whereType<FeedingEventModel>()
        .where((event) => !event.synced)
        .toList();

    if (unsyncedEvents.isEmpty) {
      debugPrint('BackgroundSync: No unsynced events, skipping');
      await feedingEventsBox.close();
      return true;
    }

    debugPrint(
      'BackgroundSync: Found ${unsyncedEvents.length} unsynced events',
    );

    // 3. Get auth token from secure storage
    const secureStorage = FlutterSecureStorage();
    final accessToken = await secureStorage.read(
      key: SecureStorageKeys.accessToken,
    );

    if (accessToken == null || accessToken.isEmpty) {
      debugPrint('BackgroundSync: No auth token, skipping sync');
      await feedingEventsBox.close();
      return false;
    }

    // 4. Create Dio client and POST to /sync
    final baseUrl = _resolveBaseUrl();
    if (baseUrl.isEmpty) {
      debugPrint('BackgroundSync: No API base URL configured');
      await feedingEventsBox.close();
      return false;
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ),
    );

    // 5. Prepare payload (lightweight - only essential fields)
    final payload = unsyncedEvents.map((e) => _feedingEventToJson(e)).toList();

    final response = await dio.post<Map<String, dynamic>>(
      '/sync',
      data: {
        'events': payload,
        'client_timestamp': DateTime.now().toIso8601String(),
      },
    );

    // 6. Process response and mark events as synced
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      final syncedIds = <String>[];

      // Handle explicit synced_ids from server
      if (data != null && data['synced_ids'] != null) {
        final ids = (data['synced_ids'] as List<dynamic>)
            .map((id) => id.toString())
            .toList();
        syncedIds.addAll(ids);
      } else {
        // No explicit synced_ids, assume all synced
        syncedIds.addAll(unsyncedEvents.map((e) => e.id));
      }

      // Mark events as synced in Hive
      for (final id in syncedIds) {
        final event = feedingEventsBox.get(id);
        if (event is FeedingEventModel) {
          event.synced = true;
          await feedingEventsBox.put(id, event);
        }
      }

      debugPrint('BackgroundSync: Synced ${syncedIds.length} events');
      await feedingEventsBox.close();
      return true;
    } else {
      debugPrint(
        'BackgroundSync: Sync failed with status ${response.statusCode}',
      );
      await feedingEventsBox.close();
      return false;
    }
  } on DioException catch (e) {
    debugPrint('BackgroundSync: Network error - ${e.message}');
    return false;
  } catch (e) {
    debugPrint('BackgroundSync: Error during sync - $e');
    return false;
  }
}

/// Initializes Hive for background isolate.
///
/// Background isolates don't share memory with the main isolate,
/// so we need to re-register adapters and initialize Hive.
Future<void> _initializeHiveForBackground() async {
  // Initialize Hive (safe to call multiple times)
  await Hive.initFlutter();

  // Register FeedingEventModel adapter if not registered
  if (!Hive.isAdapterRegistered(FeedingEventModelAdapter().typeId)) {
    Hive.registerAdapter(FeedingEventModelAdapter());
  }
}

/// Converts a FeedingEventModel to JSON for API sync.
Map<String, dynamic> _feedingEventToJson(FeedingEventModel event) {
  return {
    'id': event.id,
    'local_id': event.localId,
    'fish_id': event.fishId,
    'aquarium_id': event.aquariumId,
    'feeding_time': event.feedingTime.toIso8601String(),
    'amount': event.amount,
    'food_type': event.foodType,
    'notes': event.notes,
    'created_at': event.createdAt.toIso8601String(),
    'updated_at': event.updatedAt?.toIso8601String(),
    'completed_by': event.completedBy,
    'completed_by_name': event.completedByName,
    'completed_by_avatar': event.completedByAvatar,
  };
}

/// Updates the last background sync timestamp in SharedPreferences.
Future<void> _updateLastBackgroundSyncTime() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastBackgroundSyncKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  } catch (e) {
    debugPrint('BackgroundSync: Failed to update last sync time - $e');
  }
}

/// Increments the consecutive error count.
Future<void> _incrementErrorCount() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_backgroundSyncErrorCountKey) ?? 0;
    await prefs.setInt(_backgroundSyncErrorCountKey, currentCount + 1);
  } catch (e) {
    debugPrint('BackgroundSync: Failed to increment error count - $e');
  }
}

/// Resets the consecutive error count.
Future<void> _resetErrorCount() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_backgroundSyncErrorCountKey, 0);
  } catch (e) {
    debugPrint('BackgroundSync: Failed to reset error count - $e');
  }
}

/// Service for managing background sync registration and status.
///
/// This service handles:
/// - Workmanager initialization
/// - Periodic task registration
/// - Tracking background sync status
///
/// Example:
/// ```dart
/// // Initialize in main.dart
/// await BackgroundSyncService.instance.initialize();
///
/// // Register periodic sync
/// await BackgroundSyncService.instance.registerPeriodicSync();
/// ```
class BackgroundSyncService {
  BackgroundSyncService._();

  static final BackgroundSyncService _instance = BackgroundSyncService._();

  /// Singleton instance of [BackgroundSyncService].
  static BackgroundSyncService get instance => _instance;

  bool _isInitialized = false;
  SharedPreferences? _prefs;

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes Workmanager with the callback dispatcher.
  ///
  /// Must be called before [registerPeriodicSync].
  /// Should be called in main() after WidgetsFlutterBinding.ensureInitialized().
  Future<void> initialize({bool isInDebugMode = false}) async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();

    await Workmanager().initialize(
      backgroundSyncCallbackDispatcher,
      isInDebugMode: isInDebugMode,
    );

    _isInitialized = true;
    debugPrint('BackgroundSyncService: Initialized');
  }

  /// Registers the periodic background sync task.
  ///
  /// On Android: Uses WorkManager with 15-minute minimum frequency.
  /// On iOS: Uses BGTaskScheduler (requires additional native setup).
  ///
  /// The task will only run when network is available.
  Future<void> registerPeriodicSync() async {
    if (!_isInitialized) {
      debugPrint(
        'BackgroundSyncService: Not initialized, call initialize() first',
      );
      return;
    }

    await Workmanager().registerPeriodicTask(
      kBackgroundSyncTaskName,
      kBackgroundSyncTaskName,
      frequency: kBackgroundSyncFrequency,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 5),
    );

    debugPrint(
      'BackgroundSyncService: Periodic sync registered '
      '(frequency: ${kBackgroundSyncFrequency.inMinutes} minutes)',
    );
  }

  /// Cancels the periodic background sync task.
  Future<void> cancelPeriodicSync() async {
    await Workmanager().cancelByUniqueName(kBackgroundSyncTaskName);
    debugPrint('BackgroundSyncService: Periodic sync cancelled');
  }

  /// Cancels all registered background tasks.
  Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    debugPrint('BackgroundSyncService: All tasks cancelled');
  }

  /// Triggers an immediate one-off background sync.
  ///
  /// Useful for testing or when user wants to force a sync.
  Future<void> triggerImmediateSync() async {
    if (!_isInitialized) {
      debugPrint('BackgroundSyncService: Not initialized');
      return;
    }

    await Workmanager().registerOneOffTask(
      '${kBackgroundSyncTaskName}_immediate_${DateTime.now().millisecondsSinceEpoch}',
      kBackgroundSyncTaskName,
      constraints: Constraints(networkType: NetworkType.connected),
    );

    debugPrint('BackgroundSyncService: Immediate sync triggered');
  }

  /// Gets the last background sync time.
  ///
  /// Returns null if no sync has been performed yet.
  DateTime? getLastBackgroundSyncTime() {
    final timestamp = _prefs?.getInt(_lastBackgroundSyncKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Gets the time since the last background sync.
  ///
  /// Returns null if no sync has been performed yet.
  Duration? getTimeSinceLastSync() {
    final lastSync = getLastBackgroundSyncTime();
    if (lastSync == null) return null;
    return DateTime.now().difference(lastSync);
  }

  /// Gets the consecutive error count from background syncs.
  int getConsecutiveErrorCount() {
    return _prefs?.getInt(_backgroundSyncErrorCountKey) ?? 0;
  }

  /// Whether background sync is experiencing repeated failures.
  bool get hasRepeatedFailures =>
      getConsecutiveErrorCount() >= _maxConsecutiveErrors;

  /// Formats the last sync time for display.
  ///
  /// Returns a human-readable string like "5 minutes ago" or "Never".
  String getLastSyncDisplayText() {
    final lastSync = getLastBackgroundSyncTime();
    if (lastSync == null) return 'Never';

    final duration = DateTime.now().difference(lastSync);

    if (duration.inMinutes < 1) {
      return 'Just now';
    } else if (duration.inMinutes < 60) {
      final minutes = duration.inMinutes;
      return '$minutes ${minutes == 1 ? "minute" : "minutes"} ago';
    } else if (duration.inHours < 24) {
      final hours = duration.inHours;
      return '$hours ${hours == 1 ? "hour" : "hours"} ago';
    } else {
      final days = duration.inDays;
      return '$days ${days == 1 ? "day" : "days"} ago';
    }
  }
}
