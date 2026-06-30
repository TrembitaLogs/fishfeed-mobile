import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/services/notifications/notification_orchestrator.dart';
import 'package:fishfeed/services/notifications/notification_permission_service.dart';
import 'package:fishfeed/services/notifications/notification_service.dart';
import 'package:fishfeed/services/notifications/planned_alarm.dart'
    show ReconcileReason;

/// Unique name for the (now retired) periodic background sync task.
///
/// Kept so existing installs can cancel any still-scheduled instance; see
/// [BackgroundSyncService.initialize].
const String kBackgroundSyncTaskName = 'fishfeed_background_sync';

/// Task identifier for iOS BGTaskScheduler.
const String kBackgroundSyncTaskIdentifier = 'com.fishfeed.app.backgroundSync';

/// Workmanager unique name for the daily notification refill task.
const String kNotificationRefillTaskName = 'notificationRefill';

/// Workmanager task identifier (matches Info.plist BGTaskSchedulerPermittedIdentifiers
/// on iOS).
const String kNotificationRefillTaskIdentifier =
    'com.fishfeed.app.notificationRefill';

/// Frequency for periodic background sync (minimum on Android is 15 minutes).
const Duration kBackgroundSyncFrequency = Duration(minutes: 15);

/// Key for storing the last background sync timestamp.
const String _lastBackgroundSyncKey = 'last_background_sync';

/// Key for storing the background sync error count.
const String _backgroundSyncErrorCountKey = 'background_sync_error_count';

/// Maximum consecutive errors before increasing backoff.
const int _maxConsecutiveErrors = 3;

/// Top-level callback dispatcher for Workmanager.
///
/// This function runs in a separate isolate when the background task executes.
/// It must be a top-level function (not a class method) and annotated with
/// @pragma('vm:entry-point') for Flutter 3.1+ and obfuscated builds.
@pragma('vm:entry-point')
void backgroundSyncCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint('BackgroundSync: Task started - $taskName');

    // Route to notification refill if this is the refill task.
    if (taskName == kNotificationRefillTaskName) {
      return await _performNotificationRefill();
    }

    // The legacy background feeding-log sync was removed: it opened the
    // main-isolate-owned, AES-encrypted feedingLogs Hive box from this
    // background isolate (in plaintext, without the cipher), which corrupted
    // the box to a 0-byte file and lost fed-status across restarts. It also
    // POSTed a legacy {feeding_logs:[...]} envelope the modern backend ignores
    // while marking logs synced without server confirmation. Feeding-log sync
    // now runs exclusively through the foreground SyncService (modern
    // {changes:[...]} contract, single isolate). Any feeding-sync task still
    // scheduled on an existing install is a harmless no-op here and is also
    // cancelled on the next app launch in BackgroundSyncService.initialize.
    debugPrint(
      'BackgroundSync: feeding-log background sync retired; handled by the '
      'foreground SyncService. No-op.',
    );
    return true;
  });
}

/// Top-level helper for the notification refill background task.
///
/// Runs in a separate isolate. Bootstraps Hive + minimal services and
/// triggers an orchestrator reconcile to refresh the rolling 7-day window.
Future<bool> _performNotificationRefill() async {
  try {
    // Initialize Hive in this isolate.
    await Hive.initFlutter();
    await HiveBoxes.initForBackgroundIsolate();

    // Initialize the notification plugin.
    await NotificationService.instance.initialize();

    // Construct orchestrator directly — no Riverpod in this isolate.
    final orchestrator = NotificationOrchestrator(
      scheduleDs: ScheduleLocalDataSource(),
      fishDs: FishLocalDataSource(),
      aquariumDs: AquariumLocalDataSource(),
      notificationService: NotificationService.instance,
      permissionService: NotificationPermissionService.instance,
    );

    final result = await orchestrator.reconcile(
      reason: ReconcileReason.dailyRefill,
    );

    debugPrint(
      'NotificationRefill: success=${result.isSuccess} added=${result.added} '
      'cancelled=${result.cancelled} kept=${result.kept}',
    );

    return result.isSuccess;
  } catch (e, st) {
    debugPrint('NotificationRefill: error: $e\n$st');
    return false;
  }
}

/// Service for managing background sync registration and status.
///
/// This service handles:
/// - Workmanager initialization
/// - Periodic notification-refill task registration
/// - Retiring the legacy feeding-log background sync task
/// - Tracking background sync status
///
/// Example:
/// ```dart
/// // Initialize in main.dart
/// await BackgroundSyncService.instance.initialize();
///
/// // Register the daily notification refill
/// await BackgroundSyncService.instance.registerPeriodicNotificationRefill();
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
  /// Must be called before [registerPeriodicNotificationRefill].
  /// Should be called in main() after WidgetsFlutterBinding.ensureInitialized().
  Future<void> initialize({bool isInDebugMode = false}) async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();

    await Workmanager().initialize(
      backgroundSyncCallbackDispatcher,
      isInDebugMode: isInDebugMode,
    );

    // Retire the legacy feeding-log background sync on existing installs. That
    // task opened the feedingLogs Hive box from a background isolate and
    // corrupted it to a 0-byte file. Feeding-log sync is now foreground-only
    // (SyncService). Cancelling here stops any previously-scheduled instance.
    try {
      await Workmanager().cancelByUniqueName(kBackgroundSyncTaskName);
    } catch (e) {
      debugPrint('BackgroundSync: Failed to cancel legacy sync task - $e');
    }

    _isInitialized = true;
    debugPrint('BackgroundSyncService: Initialized');
  }

  /// Registers the daily notification refill periodic task.
  ///
  /// Runs every 24 hours regardless of network connectivity to refresh the
  /// rolling 7-day notification window for users who don't open the app.
  /// On iOS the identifier must match Info.plist BGTaskSchedulerPermittedIdentifiers.
  Future<void> registerPeriodicNotificationRefill() async {
    if (!_isInitialized) {
      debugPrint(
        'BackgroundSyncService: Not initialized, call initialize() first',
      );
      return;
    }

    await Workmanager().registerPeriodicTask(
      kNotificationRefillTaskName,
      kNotificationRefillTaskName,
      frequency: const Duration(hours: 24),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    debugPrint(
      'BackgroundSyncService: Periodic notification refill registered '
      '(frequency: 24 hours)',
    );
  }

  /// Cancels the legacy periodic background sync task.
  Future<void> cancelPeriodicSync() async {
    await Workmanager().cancelByUniqueName(kBackgroundSyncTaskName);
    debugPrint('BackgroundSyncService: Periodic sync cancelled');
  }

  /// Cancels all registered background tasks.
  Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    debugPrint('BackgroundSyncService: All tasks cancelled');
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
