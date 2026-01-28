import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:fishfeed/services/notifications/notification_service.dart';

/// Background message handler for FCM.
///
/// Must be a top-level function (not a class method) to work with
/// Firebase Messaging background handling.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background isolate
  await Firebase.initializeApp();

  if (kDebugMode) {
    print('FCM background message: ${message.messageId}');
    print('FCM background data: ${message.data}');
  }

  // Background messages with notification payload are automatically displayed
  // by the system. Data-only messages can be processed here if needed.
}

/// Callback type for handling FCM tokens.
typedef FcmTokenCallback = void Function(String token);

/// Callback type for handling remote messages.
typedef RemoteMessageCallback = void Function(RemoteMessage message);

/// Service for managing Firebase Cloud Messaging (FCM).
///
/// Handles FCM initialization, token management, and message handling
/// for foreground, background, and terminated app states.
class FcmService {
  FcmService._();

  static final FcmService _instance = FcmService._();

  /// Singleton instance of [FcmService].
  static FcmService get instance => _instance;

  /// Lazy-initialized FirebaseMessaging instance.
  /// Only accessed after Firebase.initializeApp() is called.
  FirebaseMessaging? _messaging;
  FirebaseMessaging get _getMessaging =>
      _messaging ??= FirebaseMessaging.instance;

  bool _isInitialized = false;

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Current FCM token, if available.
  String? _currentToken;

  /// Gets the current FCM token.
  String? get currentToken => _currentToken;

  /// Stream controller for FCM token updates.
  final _tokenController = StreamController<String>.broadcast();

  /// Stream of FCM token updates.
  Stream<String> get tokenStream => _tokenController.stream;

  /// Stream controller for foreground messages.
  final _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();

  /// Stream of foreground messages.
  Stream<RemoteMessage> get foregroundMessageStream =>
      _foregroundMessageController.stream;

  /// Stream controller for notification tap events.
  final _notificationTapController =
      StreamController<RemoteMessage>.broadcast();

  /// Stream of notification tap events.
  Stream<RemoteMessage> get notificationTapStream =>
      _notificationTapController.stream;

  /// Callback for when a new FCM token is received.
  FcmTokenCallback? onTokenRefresh;

  /// Callback for when a foreground message is received.
  RemoteMessageCallback? onForegroundMessage;

  /// Callback for when a notification is tapped.
  RemoteMessageCallback? onNotificationTap;

  /// Initializes the FCM service.
  ///
  /// Must be called after Firebase.initializeApp() and before any other
  /// FCM operations.
  ///
  /// [showForegroundNotifications] - Whether to display notifications
  /// when app is in foreground (default: true).
  Future<void> initialize({bool showForegroundNotifications = true}) async {
    if (_isInitialized) return;

    try {
      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);

      // Configure foreground notification presentation (iOS)
      await _getMessaging.setForegroundNotificationPresentationOptions(
        alert: showForegroundNotifications,
        badge: true,
        sound: true,
      );

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Listen for notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a terminated state via notification
      await _checkInitialMessage();

      // Get initial token
      await _fetchToken();

      // Listen for token refresh
      _getMessaging.onTokenRefresh.listen(_handleTokenRefresh);

      _isInitialized = true;

      if (kDebugMode) {
        print('FCM Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FCM Service initialization failed: $e');
      }
      // Don't rethrow - allow app to continue without FCM
    }
  }

  /// Fetches the current FCM token.
  Future<String?> _fetchToken() async {
    try {
      // On iOS, we need APNS token first
      if (Platform.isIOS) {
        final apnsToken = await _getMessaging.getAPNSToken();
        if (apnsToken == null) {
          if (kDebugMode) {
            print('APNS token not available yet');
          }
          return null;
        }
      }

      _currentToken = await _getMessaging.getToken();

      if (_currentToken != null) {
        _tokenController.add(_currentToken!);
        onTokenRefresh?.call(_currentToken!);

        if (kDebugMode) {
          print('FCM Token: $_currentToken');
        }
      }

      return _currentToken;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching FCM token: $e');
      }
      return null;
    }
  }

  /// Handles token refresh events.
  void _handleTokenRefresh(String token) {
    _currentToken = token;
    _tokenController.add(token);
    onTokenRefresh?.call(token);

    if (kDebugMode) {
      print('FCM Token refreshed: $token');
    }
  }

  /// Handles foreground messages.
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('FCM foreground message: ${message.messageId}');
      print('FCM notification: ${message.notification?.title}');
      print('FCM data: ${message.data}');
    }

    _foregroundMessageController.add(message);
    onForegroundMessage?.call(message);

    // Show local notification for foreground messages on Android
    // (iOS handles this via setForegroundNotificationPresentationOptions)
    if (Platform.isAndroid && message.notification != null) {
      _showLocalNotification(message);
    }
  }

  /// Shows a local notification for a remote message.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final notificationService = NotificationService.instance;
    if (!notificationService.isInitialized) {
      await notificationService.initialize();
    }

    await notificationService.showInstantNotification(
      id: message.hashCode,
      title: notification.title ?? 'Notification',
      body: notification.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// Handles notification tap events (app in background).
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('FCM notification tapped (background): ${message.messageId}');
    }

    _notificationTapController.add(message);
    onNotificationTap?.call(message);
  }

  /// Checks if app was opened from a terminated state via notification.
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _getMessaging.getInitialMessage();

    if (initialMessage != null) {
      if (kDebugMode) {
        print(
          'FCM notification tapped (terminated): ${initialMessage.messageId}',
        );
      }

      // Delay to ensure listeners are set up
      Future.delayed(const Duration(milliseconds: 100), () {
        _notificationTapController.add(initialMessage);
        onNotificationTap?.call(initialMessage);
      });
    }
  }

  /// Requests notification permissions.
  ///
  /// Returns the authorization status after the request.
  Future<AuthorizationStatus> requestPermission() async {
    final settings = await _getMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('FCM permission status: ${settings.authorizationStatus}');
    }

    // After permission is granted, try to get token again if we don't have one
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      if (_currentToken == null) {
        await _fetchToken();
      }
    }

    return settings.authorizationStatus;
  }

  /// Gets the current FCM token.
  ///
  /// Returns null if FCM is not initialized or token is not available.
  Future<String?> getToken() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_currentToken != null) {
      return _currentToken;
    }

    return _fetchToken();
  }

  /// Deletes the current FCM token.
  ///
  /// Use this when user logs out to stop receiving notifications.
  Future<void> deleteToken() async {
    try {
      await _getMessaging.deleteToken();
      _currentToken = null;

      if (kDebugMode) {
        print('FCM token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting FCM token: $e');
      }
    }
  }

  /// Subscribes to a topic.
  ///
  /// [topic] - The topic name to subscribe to.
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _getMessaging.subscribeToTopic(topic);

      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic $topic: $e');
      }
    }
  }

  /// Unsubscribes from a topic.
  ///
  /// [topic] - The topic name to unsubscribe from.
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _getMessaging.unsubscribeFromTopic(topic);

      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic $topic: $e');
      }
    }
  }

  /// Checks the current notification permission status.
  Future<AuthorizationStatus> getPermissionStatus() async {
    final settings = await _getMessaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  /// Disposes of the service resources.
  ///
  /// Call this when the service is no longer needed.
  void dispose() {
    _tokenController.close();
    _foregroundMessageController.close();
    _notificationTapController.close();
  }
}
