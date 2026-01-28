import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key for storing notification permission declined status.
const String _permissionDeclinedKey = 'notification_permission_declined';

/// Key for storing the timestamp when permission was declined.
const String _permissionDeclinedAtKey = 'notification_permission_declined_at';

/// Key for storing the count of times user declined permission.
const String _permissionDeclineCountKey = 'notification_permission_decline_count';

/// Result of a permission check operation.
enum NotificationPermissionStatus {
  /// Permission is granted (including provisional on iOS).
  granted,

  /// Permission has not been requested yet.
  notDetermined,

  /// User denied the permission but can still be asked again.
  denied,

  /// User permanently denied the permission.
  permanentlyDenied,

  /// Permission is restricted by the OS (e.g., parental controls on iOS).
  restricted,
}

/// Service for managing notification permission state and fallback mode.
///
/// Handles:
/// - Checking current notification permission status
/// - Storing user's decline decisions for graceful fallback
/// - Determining if app should use in-app reminders instead of push
class NotificationPermissionService {
  NotificationPermissionService._();

  static final NotificationPermissionService _instance =
      NotificationPermissionService._();

  /// Singleton instance of [NotificationPermissionService].
  static NotificationPermissionService get instance => _instance;

  SharedPreferences? _prefs;

  /// Initializes the service with SharedPreferences.
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensures preferences are initialized before use.
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await initialize();
    }
    return _prefs!;
  }

  /// Checks the current notification permission status.
  ///
  /// Returns the appropriate [NotificationPermissionStatus] based on
  /// the platform-specific permission state.
  Future<NotificationPermissionStatus> checkPermission() async {
    final status = await Permission.notification.status;

    if (kDebugMode) {
      print('NotificationPermissionService: Permission status = $status');
    }

    return switch (status) {
      PermissionStatus.granted => NotificationPermissionStatus.granted,
      PermissionStatus.provisional => NotificationPermissionStatus.granted,
      PermissionStatus.denied => NotificationPermissionStatus.denied,
      PermissionStatus.permanentlyDenied =>
        NotificationPermissionStatus.permanentlyDenied,
      PermissionStatus.restricted => NotificationPermissionStatus.restricted,
      PermissionStatus.limited => NotificationPermissionStatus.granted,
    };
  }

  /// Checks if notification permission is currently granted.
  ///
  /// This is a convenience method that returns true if the permission
  /// status is [NotificationPermissionStatus.granted].
  Future<bool> isPermissionGranted() async {
    final status = await checkPermission();
    return status == NotificationPermissionStatus.granted;
  }

  /// Checks if the permission has been permanently denied.
  Future<bool> isPermanentlyDenied() async {
    final status = await checkPermission();
    return status == NotificationPermissionStatus.permanentlyDenied;
  }

  /// Requests the notification permission from the system.
  ///
  /// Returns true if permission was granted, false otherwise.
  /// On iOS, this will show the system permission dialog.
  /// On Android 13+, this will request POST_NOTIFICATIONS permission.
  Future<bool> requestSystemPermission() async {
    final status = await Permission.notification.request();

    if (kDebugMode) {
      print('NotificationPermissionService: Request result = $status');
    }

    return status.isGranted || status.isProvisional || status.isLimited;
  }

  /// Checks if iOS provisional authorization is available.
  ///
  /// Provisional authorization allows "quiet" notifications that appear
  /// in Notification Center but don't show banners or play sounds.
  /// Available on iOS 12+.
  Future<bool> hasProvisionalAuthorization() async {
    if (!Platform.isIOS) return false;

    final status = await Permission.notification.status;
    return status.isProvisional;
  }

  /// Records that the user declined the permission request.
  ///
  /// This information is used to:
  /// - Enable fallback mode (in-app reminders)
  /// - Avoid showing the permission dialog too frequently
  Future<void> recordPermissionDeclined() async {
    final prefs = await _getPrefs();

    await prefs.setBool(_permissionDeclinedKey, true);
    await prefs.setString(
      _permissionDeclinedAtKey,
      DateTime.now().toIso8601String(),
    );

    final currentCount = prefs.getInt(_permissionDeclineCountKey) ?? 0;
    await prefs.setInt(_permissionDeclineCountKey, currentCount + 1);

    if (kDebugMode) {
      print('NotificationPermissionService: Permission declined recorded '
          '(count: ${currentCount + 1})');
    }
  }

  /// Clears the permission declined status.
  ///
  /// Call this when the user grants permission from settings
  /// or explicitly requests to enable notifications again.
  Future<void> clearPermissionDeclined() async {
    final prefs = await _getPrefs();

    await prefs.remove(_permissionDeclinedKey);
    await prefs.remove(_permissionDeclinedAtKey);
    // Keep the decline count for analytics

    if (kDebugMode) {
      print('NotificationPermissionService: Permission declined status cleared');
    }
  }

  /// Checks if the user has previously declined the permission.
  Future<bool> hasUserDeclinedPermission() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_permissionDeclinedKey) ?? false;
  }

  /// Gets the number of times the user has declined the permission.
  Future<int> getDeclineCount() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_permissionDeclineCountKey) ?? 0;
  }

  /// Gets the timestamp when the user last declined the permission.
  Future<DateTime?> getLastDeclinedAt() async {
    final prefs = await _getPrefs();
    final timestamp = prefs.getString(_permissionDeclinedAtKey);
    if (timestamp == null) return null;
    return DateTime.tryParse(timestamp);
  }

  /// Checks if the app should use fallback mode (in-app reminders).
  ///
  /// Fallback mode is enabled when:
  /// - User has explicitly declined the permission dialog, OR
  /// - System permission is permanently denied
  ///
  /// In fallback mode, the app should:
  /// - Show in-app reminders instead of push notifications
  /// - Display a banner prompting to enable notifications
  Future<bool> shouldUseFallbackMode() async {
    // Check if permission is granted
    final isGranted = await isPermissionGranted();
    if (isGranted) {
      // Permission granted, clear any declined status
      await clearPermissionDeclined();
      return false;
    }

    // Check if user declined or permanently denied
    final userDeclined = await hasUserDeclinedPermission();
    final permDenied = await isPermanentlyDenied();

    return userDeclined || permDenied;
  }

  /// Opens the app settings so the user can manually enable notifications.
  ///
  /// Returns true if the settings were opened successfully.
  Future<bool> openSettings() async {
    final opened = await openAppSettings();

    if (kDebugMode) {
      print('NotificationPermissionService: Open settings result = $opened');
    }

    return opened;
  }

  /// Checks if enough time has passed since the last decline to show
  /// the permission dialog again.
  ///
  /// Returns true if:
  /// - User has never declined, OR
  /// - At least [minDaysBetweenPrompts] days have passed since last decline
  Future<bool> canShowPermissionDialog({int minDaysBetweenPrompts = 7}) async {
    final lastDeclined = await getLastDeclinedAt();
    if (lastDeclined == null) return true;

    final daysSinceDecline = DateTime.now().difference(lastDeclined).inDays;
    return daysSinceDecline >= minDaysBetweenPrompts;
  }

  /// Resets all stored permission state.
  ///
  /// Useful for testing or when user explicitly wants to reset preferences.
  Future<void> resetAllState() async {
    final prefs = await _getPrefs();

    await prefs.remove(_permissionDeclinedKey);
    await prefs.remove(_permissionDeclinedAtKey);
    await prefs.remove(_permissionDeclineCountKey);

    if (kDebugMode) {
      print('NotificationPermissionService: All state reset');
    }
  }
}
