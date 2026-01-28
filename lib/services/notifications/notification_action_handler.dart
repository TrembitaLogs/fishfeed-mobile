import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Action identifiers for notification buttons.
abstract final class NotificationActionIds {
  /// Action ID for marking feeding as done.
  static const String fed = 'fed';

  /// Action ID for snoozing the reminder.
  static const String snooze = 'snooze';
}

/// iOS notification category identifier for feeding reminders.
const String feedingCategoryId = 'feeding_actions';

/// Duration to snooze notifications.
const Duration snoozeDuration = Duration(minutes: 15);

/// SharedPreferences key for pending notification actions.
const String _pendingActionsKey = 'pending_notification_actions';

/// Represents a pending notification action to be processed when app starts.
class PendingNotificationAction {
  const PendingNotificationAction({
    required this.actionId,
    required this.payload,
    required this.timestamp,
  });

  factory PendingNotificationAction.fromJson(Map<String, dynamic> json) {
    return PendingNotificationAction(
      actionId: json['actionId'] as String,
      payload: json['payload'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// The action that was taken (fed or snooze).
  final String actionId;

  /// The notification payload containing event info.
  final String payload;

  /// When the action was taken.
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'actionId': actionId,
        'payload': payload,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Handles notification action storage and retrieval for background processing.
///
/// When a notification action is triggered in the background (app terminated),
/// we can't directly access repositories. Instead, we store the action in
/// SharedPreferences and process it when the app starts.
class NotificationActionStorage {
  NotificationActionStorage._();

  /// Adds a pending action to be processed later.
  ///
  /// Called from the background isolate when an action is triggered
  /// while the app is terminated.
  static Future<void> addPendingAction(PendingNotificationAction action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJson = prefs.getString(_pendingActionsKey);

      List<Map<String, dynamic>> actions = [];
      if (existingJson != null) {
        final decoded = jsonDecode(existingJson) as List<dynamic>;
        actions = decoded.cast<Map<String, dynamic>>();
      }

      actions.add(action.toJson());
      await prefs.setString(_pendingActionsKey, jsonEncode(actions));

      if (kDebugMode) {
        print('NotificationActionStorage: Added pending action ${action.actionId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationActionStorage: Error adding pending action: $e');
      }
    }
  }

  /// Retrieves and clears all pending actions.
  ///
  /// Should be called during app initialization to process
  /// any actions that occurred while the app was terminated.
  static Future<List<PendingNotificationAction>> getAndClearPendingActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJson = prefs.getString(_pendingActionsKey);

      if (existingJson == null) {
        return [];
      }

      final decoded = jsonDecode(existingJson) as List<dynamic>;
      final actions = decoded
          .cast<Map<String, dynamic>>()
          .map(PendingNotificationAction.fromJson)
          .toList();

      // Clear after reading
      await prefs.remove(_pendingActionsKey);

      if (kDebugMode) {
        print('NotificationActionStorage: Retrieved ${actions.length} pending actions');
      }

      return actions;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationActionStorage: Error getting pending actions: $e');
      }
      return [];
    }
  }

  /// Checks if there are any pending actions without clearing them.
  static Future<bool> hasPendingActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJson = prefs.getString(_pendingActionsKey);
      return existingJson != null && existingJson.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

/// Parses the event ID from a notification payload.
///
/// Payloads follow the format: "feeding_reminder_{eventId}" or similar.
/// Returns null if the payload doesn't contain a valid event ID.
int? parseEventIdFromPayload(String? payload) {
  if (payload == null || payload.isEmpty) {
    return null;
  }

  // Extract the last segment after underscore which should be the event ID
  final parts = payload.split('_');
  if (parts.isEmpty) {
    return null;
  }

  return int.tryParse(parts.last);
}

/// Parses the scheduled feeding ID from a notification payload.
///
/// Returns the full ID string (e.g., "feed_1") for use with marking feedings.
String? parseScheduledFeedingIdFromPayload(String? payload) {
  if (payload == null || payload.isEmpty) {
    return null;
  }

  // Payload format: "feeding_reminder_{scheduledFeedingId}"
  // We need to extract scheduledFeedingId which might be "feed_1", etc.
  if (payload.startsWith('feeding_reminder_')) {
    return payload.replaceFirst('feeding_reminder_', '');
  }

  return null;
}
