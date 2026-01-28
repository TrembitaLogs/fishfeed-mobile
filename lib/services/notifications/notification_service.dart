import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:fishfeed/presentation/dialogs/notification_permission_dialog.dart';
import 'package:fishfeed/services/analytics/analytics_service.dart';
import 'package:fishfeed/services/notifications/notification_action_handler.dart';
import 'package:fishfeed/services/notifications/notification_permission_service.dart';

/// Background notification action handler.
///
/// This is a top-level function required for handling notification actions
/// when the app is in the background or terminated. Must be annotated with
/// @pragma('vm:entry-point') to prevent tree-shaking.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  if (kDebugMode) {
    print('Background notification action: ${response.actionId}');
    print('Background notification payload: ${response.payload}');
  }

  // Store the action for processing when the app starts
  if (response.actionId != null && response.payload != null) {
    final action = PendingNotificationAction(
      actionId: response.actionId!,
      payload: response.payload!,
      timestamp: DateTime.now(),
    );
    NotificationActionStorage.addPendingAction(action);
  }
}

/// Types of feeding-related notifications.
enum NotificationType {
  /// Reminder at the start of a feeding window.
  feedingReminder,

  /// Notification when a feeding event was missed.
  missedEvent,

  /// Reminder to confirm feeding status.
  confirmStatus,

  /// Warning that freeze day is available to prevent streak loss.
  freezeAvailable,
}

/// Service for managing local notifications.
///
/// Handles initialization, permission requests, and scheduling
/// of feeding reminder notifications.
class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();

  /// Singleton instance of [NotificationService].
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Notification channel ID for feeding reminders.
  static const String feedingChannelId = 'feeding_reminders';

  /// Notification channel name for feeding reminders.
  static const String feedingChannelName = 'Feeding Reminders';

  /// Notification channel description.
  static const String feedingChannelDescription =
      'Notifications for scheduled fish feeding times';

  /// Notification channel ID for missed events.
  static const String missedChannelId = 'missed_events';

  /// Notification channel name for missed events.
  static const String missedChannelName = 'Missed Events';

  /// Notification channel description for missed events.
  static const String missedChannelDescription =
      'Notifications for missed feeding events';

  /// Notification channel ID for status confirmations.
  static const String confirmChannelId = 'confirm_status';

  /// Notification channel name for status confirmations.
  static const String confirmChannelName = 'Status Confirmations';

  /// Notification channel description for status confirmations.
  static const String confirmChannelDescription =
      'Reminders to confirm feeding status';

  /// Notification channel ID for freeze day warnings.
  static const String freezeChannelId = 'freeze_available';

  /// Notification channel name for freeze day warnings.
  static const String freezeChannelName = 'Freeze Day Alerts';

  /// Notification channel description for freeze day warnings.
  static const String freezeChannelDescription =
      'Alerts when streak is at risk and freeze day is available';

  /// Tracks the last notification time per type and event for throttling.
  ///
  /// Key format: "${notificationType.name}_$eventId"
  final Map<String, DateTime> _lastNotificationTimes = {};

  /// Duration for throttling missed event notifications (1 per day).
  static const Duration missedEventThrottleDuration = Duration(hours: 24);

  /// Callback for handling notification actions in foreground.
  ///
  /// Set this to process fed/snooze actions when app is in foreground.
  void Function(String actionId, String? payload)? onActionReceived;

  /// Initializes the notification service.
  ///
  /// Must be called before any other notification methods.
  /// Typically called during app startup.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_getLocalTimeZone()));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS notification categories with action buttons
    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          feedingCategoryId,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              NotificationActionIds.fed,
              'Fed ✓',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              NotificationActionIds.snooze,
              'Snooze 15m',
            ),
          ],
          options: <DarwinNotificationCategoryOption>{
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
          },
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    _isInitialized = true;
  }

  /// Gets the local timezone identifier.
  String _getLocalTimeZone() {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;

      // Map common offsets to timezone names
      // This is a simplified approach; production apps might use a more robust solution
      if (offset.inHours == 2) return 'Europe/Kiev';
      if (offset.inHours == 0) return 'UTC';
      if (offset.inHours == -5) return 'America/New_York';
      if (offset.inHours == -8) return 'America/Los_Angeles';

      return 'UTC';
    } catch (_) {
      return 'UTC';
    }
  }

  /// Handles notification tap and action events in foreground.
  void _onNotificationResponse(NotificationResponse response) {
    if (kDebugMode) {
      print('Notification response: ${response.notificationResponseType}');
      print('Notification actionId: ${response.actionId}');
      print('Notification payload: ${response.payload}');
    }

    final actionId = response.actionId;
    final payload = response.payload;

    // Track push notification opened
    final notificationType = _extractNotificationTypeFromPayload(payload);
    AnalyticsService.instance.trackPushOpened(notificationType: notificationType);

    // Handle notification actions (Fed/Snooze buttons)
    if (actionId != null && actionId.isNotEmpty) {
      _handleNotificationAction(actionId, payload);
      return;
    }

    // Handle regular notification tap (no action button)
    // This is when user taps on the notification body itself
    if (response.notificationResponseType ==
        NotificationResponseType.selectedNotification) {
      // Track app open from push
      AnalyticsService.instance.trackAppOpenFromPush(notificationType: notificationType);
      // Navigate to relevant screen based on payload
      // This will be handled by the app's navigation system
      if (kDebugMode) {
        print('Notification tapped, payload: $payload');
      }
    }
  }

  /// Extracts notification type from payload string.
  String _extractNotificationTypeFromPayload(String? payload) {
    if (payload == null) return 'unknown';
    if (payload.startsWith('feeding_reminder')) return 'feeding_reminder';
    if (payload.startsWith('missed_event')) return 'missed_event';
    if (payload.startsWith('confirm_status')) return 'confirm_status';
    if (payload.startsWith('freeze_warning')) return 'freeze_warning';
    if (payload.startsWith('feeding')) return 'feeding';
    return 'unknown';
  }

  /// Handles notification action button taps.
  void _handleNotificationAction(String actionId, String? payload) {
    if (kDebugMode) {
      print('Handling action: $actionId with payload: $payload');
    }

    // Notify listeners about the action
    onActionReceived?.call(actionId, payload);

    // Handle snooze action internally (reschedule notification)
    if (actionId == NotificationActionIds.snooze && payload != null) {
      _handleSnoozeAction(payload);
    }
  }

  /// Handles the snooze action by rescheduling the notification.
  Future<void> _handleSnoozeAction(String payload) async {
    final eventId = parseEventIdFromPayload(payload);
    if (eventId == null) {
      if (kDebugMode) {
        print('Could not parse eventId from payload: $payload');
      }
      return;
    }

    // Reschedule the notification for 15 minutes from now
    final snoozeTime = DateTime.now().add(snoozeDuration);

    await scheduleFeeding(
      time: snoozeTime,
      fishName: 'your fish', // Generic name for snoozed notification
      eventId: eventId,
    );

    if (kDebugMode) {
      print('Snoozed notification for eventId $eventId until $snoozeTime');
    }
  }

  /// Requests notification permissions from the user.
  ///
  /// Returns `true` if permissions were granted, `false` otherwise.
  Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (Platform.isAndroid) {
      return await _requestAndroidPermissions();
    } else if (Platform.isIOS) {
      return await _requestIOSPermissions();
    }

    return false;
  }

  Future<bool> _requestAndroidPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return false;

    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<bool> _requestIOSPermissions() async {
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin == null) return false;

    final granted = await iosPlugin.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return granted ?? false;
  }

  /// Requests notification permission with an explanation dialog.
  ///
  /// This method provides a better UX by:
  /// 1. Checking if permission is already granted (returns early if yes)
  /// 2. Showing a dialog explaining why notifications are needed
  /// 3. Only requesting system permission if user agrees
  /// 4. Recording user's decision for graceful fallback
  ///
  /// [context] - BuildContext needed to show the dialog.
  ///
  /// Returns `true` if permission was granted, `false` otherwise.
  /// If the user declines, the app should enable fallback mode
  /// (in-app reminders instead of push notifications).
  Future<bool> requestPermissionWithExplanation(BuildContext context) async {
    final permissionService = NotificationPermissionService.instance;

    // Check if already granted
    final isGranted = await permissionService.isPermissionGranted();
    if (isGranted) {
      if (kDebugMode) {
        print('NotificationService: Permission already granted');
      }
      return true;
    }

    // Check if permanently denied - need to go to settings
    final isPermanentlyDenied = await permissionService.isPermanentlyDenied();
    if (isPermanentlyDenied) {
      if (kDebugMode) {
        print('NotificationService: Permission permanently denied, '
            'user needs to enable in settings');
      }
      await permissionService.recordPermissionDeclined();
      return false;
    }

    // Show explanation dialog
    if (!context.mounted) return false;

    final dialogResult = await NotificationPermissionDialog.show(context);

    if (dialogResult == NotificationPermissionDialogResult.later) {
      // User chose "Later" - record and enable fallback mode
      await permissionService.recordPermissionDeclined();
      if (kDebugMode) {
        print('NotificationService: User chose to skip notifications');
      }
      return false;
    }

    // User chose to enable - request system permission
    final granted = await permissionService.requestSystemPermission();

    if (granted) {
      // Clear any previous declined status
      await permissionService.clearPermissionDeclined();
      if (kDebugMode) {
        print('NotificationService: Permission granted by user');
      }
    } else {
      // User denied at system level
      await permissionService.recordPermissionDeclined();
      if (kDebugMode) {
        print('NotificationService: Permission denied at system level');
      }
    }

    return granted;
  }

  /// Checks if notifications should use fallback mode (in-app reminders).
  ///
  /// Returns `true` if:
  /// - User explicitly declined the permission dialog
  /// - System permission is permanently denied
  ///
  /// In fallback mode, the app should:
  /// - Skip scheduling push notifications
  /// - Show in-app reminder UI instead
  /// - Display a banner prompting to enable notifications
  Future<bool> shouldUseFallbackMode() async {
    return NotificationPermissionService.instance.shouldUseFallbackMode();
  }

  /// Schedules a daily feeding reminder notification.
  ///
  /// [id] - Unique notification ID.
  /// [title] - Notification title.
  /// [body] - Notification body text.
  /// [hour] - Hour of the day (0-23).
  /// [minute] - Minute of the hour (0-59).
  /// [payload] - Optional payload data for handling taps.
  Future<void> scheduleDailyFeeding({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final scheduledTime = _nextInstanceOfTime(hour, minute);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          feedingChannelId,
          feedingChannelName,
          channelDescription: feedingChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Calculates the next instance of a specific time.
  ///
  /// If the time has already passed today, returns tomorrow's time.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Schedules multiple feeding reminders from a list of time strings.
  ///
  /// [times] - List of times in "HH:mm" format.
  /// [speciesNames] - List of species names being fed.
  /// [baseId] - Starting notification ID (subsequent IDs will be baseId + index).
  Future<void> scheduleFeedingReminders({
    required List<String> times,
    required List<String> speciesNames,
    int baseId = 1000,
  }) async {
    final speciesText = speciesNames.length == 1
        ? speciesNames.first
        : '${speciesNames.length} species';

    for (var i = 0; i < times.length; i++) {
      final time = times[i];
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      await scheduleDailyFeeding(
        id: baseId + i,
        title: 'Feeding Time!',
        body: 'Time to feed your $speciesText',
        hour: hour,
        minute: minute,
        payload: 'feeding_$i',
      );
    }
  }

  /// Cancels a specific notification by ID.
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  /// Gets all pending notification requests.
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  /// Schedules a one-time feeding reminder notification.
  ///
  /// [time] - The exact DateTime when the notification should appear.
  /// [fishName] - Name of the fish/aquarium to display in the notification.
  /// [eventId] - Unique identifier for this feeding event.
  /// [title] - Localized notification title (optional, defaults to English).
  /// [body] - Localized notification body (optional, defaults to English with fishName).
  Future<void> scheduleFeeding({
    required DateTime time,
    required String fishName,
    required int eventId,
    String? title,
    String? body,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Don't schedule notifications in the past
    if (time.isBefore(DateTime.now())) {
      return;
    }

    final scheduledTime = tz.TZDateTime.from(time, tz.local);

    await _plugin.zonedSchedule(
      _generateNotificationId(NotificationType.feedingReminder, eventId),
      title ?? 'Feeding Time!',
      body ?? 'Time to feed $fishName!',
      scheduledTime,
      _getNotificationDetails(NotificationType.feedingReminder),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'feeding_reminder_$eventId',
    );
  }

  /// Schedules a missed event notification.
  ///
  /// [time] - The exact DateTime when the notification should appear.
  /// [fishName] - Name of the fish/aquarium to display in the notification.
  /// [eventId] - Unique identifier for this feeding event.
  /// [title] - Localized notification title (optional, defaults to English).
  /// [body] - Localized notification body (optional, defaults to English with fishName).
  ///
  /// This notification is throttled to maximum 1 per day per event.
  /// Returns `true` if the notification was scheduled, `false` if throttled.
  Future<bool> scheduleMissedReminder({
    required DateTime time,
    required String fishName,
    required int eventId,
    String? title,
    String? body,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check throttle - max 1 missed notification per day per event
    if (_isThrottled(NotificationType.missedEvent, eventId)) {
      return false;
    }

    // Don't schedule notifications in the past
    if (time.isBefore(DateTime.now())) {
      return false;
    }

    final scheduledTime = tz.TZDateTime.from(time, tz.local);

    await _plugin.zonedSchedule(
      _generateNotificationId(NotificationType.missedEvent, eventId),
      title ?? 'Missed Feeding',
      body ?? 'Missed feeding for $fishName',
      scheduledTime,
      _getNotificationDetails(NotificationType.missedEvent),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'missed_event_$eventId',
    );

    // Record the notification time for throttling
    _recordNotificationTime(NotificationType.missedEvent, eventId);

    return true;
  }

  /// Schedules a confirmation reminder notification.
  ///
  /// [time] - The exact DateTime when the notification should appear.
  /// [eventId] - Unique identifier for this feeding event.
  /// [title] - Localized notification title (optional, defaults to English).
  /// [body] - Localized notification body (optional, defaults to English).
  ///
  /// The notification will prompt the user to confirm the feeding status.
  Future<void> scheduleConfirmationReminder({
    required DateTime time,
    required int eventId,
    String? title,
    String? body,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Don't schedule notifications in the past
    if (time.isBefore(DateTime.now())) {
      return;
    }

    final scheduledTime = tz.TZDateTime.from(time, tz.local);

    await _plugin.zonedSchedule(
      _generateNotificationId(NotificationType.confirmStatus, eventId),
      title ?? 'Confirm Status',
      body ?? 'Please confirm the feeding status',
      scheduledTime,
      _getNotificationDetails(NotificationType.confirmStatus),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'confirm_status_$eventId',
    );
  }

  /// Schedules a freeze day warning notification.
  ///
  /// [time] - The exact DateTime when the notification should appear.
  /// [streakCount] - Current streak count to show in the notification.
  /// [freezeCount] - Number of freeze days available.
  /// [title] - Localized notification title (optional, defaults to English).
  /// [body] - Localized notification body (optional, defaults to English).
  ///
  /// This notification warns the user that their streak is at risk
  /// and they have freeze days available to protect it.
  /// Should be scheduled 2 hours before the end of the day.
  Future<void> scheduleFreezeWarning({
    required DateTime time,
    required int streakCount,
    required int freezeCount,
    String? title,
    String? body,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Don't schedule notifications in the past
    if (time.isBefore(DateTime.now())) {
      return;
    }

    // Don't schedule if no freeze available
    if (freezeCount <= 0) {
      return;
    }

    final scheduledTime = tz.TZDateTime.from(time, tz.local);

    // Use streak count as unique ID for this type of notification
    final notificationId =
        _generateNotificationId(NotificationType.freezeAvailable, streakCount);

    final defaultBody = 'You have $freezeCount freeze day${freezeCount > 1 ? 's' : ''} available to protect your $streakCount day streak!';

    await _plugin.zonedSchedule(
      notificationId,
      title ?? 'Streak at Risk!',
      body ?? defaultBody,
      scheduledTime,
      _getNotificationDetails(NotificationType.freezeAvailable),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'freeze_warning_$streakCount',
    );
  }

  /// Cancels any scheduled freeze warning notification.
  Future<void> cancelFreezeWarning(int streakCount) async {
    await _plugin.cancel(
      _generateNotificationId(NotificationType.freezeAvailable, streakCount),
    );
  }

  /// Cancels all scheduled notifications for a specific event.
  ///
  /// [eventId] - The event identifier used when scheduling notifications.
  ///
  /// Cancels feeding reminder, missed event, and confirmation notifications
  /// for the given event.
  Future<void> cancelScheduledNotification(int eventId) async {
    await Future.wait([
      _plugin.cancel(
          _generateNotificationId(NotificationType.feedingReminder, eventId)),
      _plugin.cancel(
          _generateNotificationId(NotificationType.missedEvent, eventId)),
      _plugin.cancel(
          _generateNotificationId(NotificationType.confirmStatus, eventId)),
    ]);

    // Clear throttle records for this event
    _clearThrottleRecords(eventId);
  }

  /// Generates a unique notification ID based on type and event ID.
  ///
  /// Uses different ranges for each notification type to avoid collisions:
  /// - feedingReminder: eventId * 10 + 1
  /// - missedEvent: eventId * 10 + 2
  /// - confirmStatus: eventId * 10 + 3
  /// - freezeAvailable: eventId * 10 + 4
  int _generateNotificationId(NotificationType type, int eventId) {
    final baseId = eventId * 10;
    return switch (type) {
      NotificationType.feedingReminder => baseId + 1,
      NotificationType.missedEvent => baseId + 2,
      NotificationType.confirmStatus => baseId + 3,
      NotificationType.freezeAvailable => baseId + 4,
    };
  }

  /// Android notification actions for feeding reminders.
  static const List<AndroidNotificationAction> _feedingActions = [
    AndroidNotificationAction(
      NotificationActionIds.fed,
      'Fed ✓',
      showsUserInterface: false,
      cancelNotification: true,
    ),
    AndroidNotificationAction(
      NotificationActionIds.snooze,
      'Snooze 15m',
      showsUserInterface: false,
      cancelNotification: true,
    ),
  ];

  /// Returns notification details based on the notification type.
  NotificationDetails _getNotificationDetails(NotificationType type) {
    return switch (type) {
      NotificationType.feedingReminder => const NotificationDetails(
          android: AndroidNotificationDetails(
            feedingChannelId,
            feedingChannelName,
            channelDescription: feedingChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            category: AndroidNotificationCategory.reminder,
            actions: _feedingActions,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            categoryIdentifier: feedingCategoryId,
          ),
        ),
      NotificationType.missedEvent => const NotificationDetails(
          android: AndroidNotificationDetails(
            missedChannelId,
            missedChannelName,
            channelDescription: missedChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            category: AndroidNotificationCategory.reminder,
            actions: _feedingActions,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            categoryIdentifier: feedingCategoryId,
          ),
        ),
      NotificationType.confirmStatus => const NotificationDetails(
          android: AndroidNotificationDetails(
            confirmChannelId,
            confirmChannelName,
            channelDescription: confirmChannelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
            category: AndroidNotificationCategory.reminder,
            actions: _feedingActions,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
            categoryIdentifier: feedingCategoryId,
          ),
        ),
      NotificationType.freezeAvailable => const NotificationDetails(
          android: AndroidNotificationDetails(
            freezeChannelId,
            freezeChannelName,
            channelDescription: freezeChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
    };
  }

  /// Checks if a notification is throttled.
  ///
  /// Returns `true` if the notification should be suppressed.
  bool _isThrottled(NotificationType type, int eventId) {
    final key = _throttleKey(type, eventId);
    final lastTime = _lastNotificationTimes[key];

    if (lastTime == null) {
      return false;
    }

    final throttleDuration = switch (type) {
      NotificationType.missedEvent => missedEventThrottleDuration,
      _ => Duration.zero,
    };

    return DateTime.now().difference(lastTime) < throttleDuration;
  }

  /// Records the current time for throttling purposes.
  void _recordNotificationTime(NotificationType type, int eventId) {
    final key = _throttleKey(type, eventId);
    _lastNotificationTimes[key] = DateTime.now();
  }

  /// Clears throttle records for a specific event.
  void _clearThrottleRecords(int eventId) {
    for (final type in NotificationType.values) {
      _lastNotificationTimes.remove(_throttleKey(type, eventId));
    }
  }

  /// Generates a throttle key for the given type and event.
  String _throttleKey(NotificationType type, int eventId) {
    return '${type.name}_$eventId';
  }

  /// Clears all throttle records.
  ///
  /// Useful for testing or when resetting the notification state.
  void clearAllThrottleRecords() {
    _lastNotificationTimes.clear();
  }

  /// Shows an instant notification immediately.
  ///
  /// Used for displaying FCM foreground messages as local notifications.
  ///
  /// [id] - Unique notification ID.
  /// [title] - Notification title.
  /// [body] - Notification body text.
  /// [payload] - Optional payload data for handling taps.
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          feedingChannelId,
          feedingChannelName,
          channelDescription: feedingChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }
}
