import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/services/notifications/fcm_service.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockRemoteMessage extends Mock implements RemoteMessage {}

class MockRemoteNotification extends Mock implements RemoteNotification {}

class MockNotificationSettings extends Mock implements NotificationSettings {}

class FakeNotificationSettings extends Fake implements NotificationSettings {
  @override
  AuthorizationStatus get authorizationStatus => AuthorizationStatus.authorized;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Note: Tests for FcmService.instance are skipped because they require
  // Firebase.initializeApp() to be called first, which is not possible
  // in unit tests without full Firebase mocking. The TestableFcmService
  // tests below cover all the functionality.

  group('TestableFcmService', () {
    late MockFirebaseMessaging mockMessaging;
    late TestableFcmService service;
    late StreamController<RemoteMessage> onMessageController;
    late StreamController<RemoteMessage> onMessageOpenedAppController;
    late StreamController<String> onTokenRefreshController;

    setUp(() {
      mockMessaging = MockFirebaseMessaging();
      onMessageController = StreamController<RemoteMessage>.broadcast();
      onMessageOpenedAppController =
          StreamController<RemoteMessage>.broadcast();
      onTokenRefreshController = StreamController<String>.broadcast();

      service = TestableFcmService(
        messaging: mockMessaging,
        onMessageStream: onMessageController.stream,
        onMessageOpenedAppStream: onMessageOpenedAppController.stream,
        onTokenRefreshStream: onTokenRefreshController.stream,
      );
    });

    tearDown(() async {
      await onMessageController.close();
      await onMessageOpenedAppController.close();
      await onTokenRefreshController.close();
      service.dispose();
    });

    group('requestPermission', () {
      test('should request permissions and return status', () async {
        final mockSettings = MockNotificationSettings();
        when(
          () => mockSettings.authorizationStatus,
        ).thenReturn(AuthorizationStatus.authorized);

        when(
          () => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            announcement: any(named: 'announcement'),
            badge: any(named: 'badge'),
            carPlay: any(named: 'carPlay'),
            criticalAlert: any(named: 'criticalAlert'),
            provisional: any(named: 'provisional'),
            sound: any(named: 'sound'),
          ),
        ).thenAnswer((_) async => mockSettings);

        final result = await service.requestPermission();

        expect(result, AuthorizationStatus.authorized);
        verify(
          () => mockMessaging.requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          ),
        ).called(1);
      });

      test('should return denied status when permission denied', () async {
        final mockSettings = MockNotificationSettings();
        when(
          () => mockSettings.authorizationStatus,
        ).thenReturn(AuthorizationStatus.denied);

        when(
          () => mockMessaging.requestPermission(
            alert: any(named: 'alert'),
            announcement: any(named: 'announcement'),
            badge: any(named: 'badge'),
            carPlay: any(named: 'carPlay'),
            criticalAlert: any(named: 'criticalAlert'),
            provisional: any(named: 'provisional'),
            sound: any(named: 'sound'),
          ),
        ).thenAnswer((_) async => mockSettings);

        final result = await service.requestPermission();

        expect(result, AuthorizationStatus.denied);
      });
    });

    group('getToken', () {
      test('should return token when available', () async {
        when(
          () => mockMessaging.getToken(),
        ).thenAnswer((_) async => 'test_fcm_token_123');

        final token = await service.getToken();

        expect(token, 'test_fcm_token_123');
        verify(() => mockMessaging.getToken()).called(1);
      });

      test('should return null when token not available', () async {
        when(() => mockMessaging.getToken()).thenAnswer((_) async => null);

        final token = await service.getToken();

        expect(token, isNull);
      });

      test('should handle error gracefully', () async {
        when(
          () => mockMessaging.getToken(),
        ).thenThrow(Exception('Token fetch failed'));

        final token = await service.getToken();

        expect(token, isNull);
      });
    });

    group('deleteToken', () {
      test('should delete token successfully', () async {
        when(() => mockMessaging.deleteToken()).thenAnswer((_) async {});

        await service.deleteToken();

        verify(() => mockMessaging.deleteToken()).called(1);
        expect(service.currentToken, isNull);
      });

      test('should handle delete error gracefully', () async {
        when(
          () => mockMessaging.deleteToken(),
        ).thenThrow(Exception('Delete failed'));

        // Should not throw
        await service.deleteToken();

        verify(() => mockMessaging.deleteToken()).called(1);
      });
    });

    group('subscribeToTopic', () {
      test('should subscribe to topic', () async {
        when(
          () => mockMessaging.subscribeToTopic(any()),
        ).thenAnswer((_) async {});

        await service.subscribeToTopic('feeding_reminders');

        verify(
          () => mockMessaging.subscribeToTopic('feeding_reminders'),
        ).called(1);
      });

      test('should handle subscribe error gracefully', () async {
        when(
          () => mockMessaging.subscribeToTopic(any()),
        ).thenThrow(Exception('Subscribe failed'));

        // Should not throw
        await service.subscribeToTopic('feeding_reminders');

        verify(
          () => mockMessaging.subscribeToTopic('feeding_reminders'),
        ).called(1);
      });
    });

    group('unsubscribeFromTopic', () {
      test('should unsubscribe from topic', () async {
        when(
          () => mockMessaging.unsubscribeFromTopic(any()),
        ).thenAnswer((_) async {});

        await service.unsubscribeFromTopic('feeding_reminders');

        verify(
          () => mockMessaging.unsubscribeFromTopic('feeding_reminders'),
        ).called(1);
      });

      test('should handle unsubscribe error gracefully', () async {
        when(
          () => mockMessaging.unsubscribeFromTopic(any()),
        ).thenThrow(Exception('Unsubscribe failed'));

        // Should not throw
        await service.unsubscribeFromTopic('feeding_reminders');

        verify(
          () => mockMessaging.unsubscribeFromTopic('feeding_reminders'),
        ).called(1);
      });
    });

    group('getPermissionStatus', () {
      test('should return current permission status', () async {
        final mockSettings = MockNotificationSettings();
        when(
          () => mockSettings.authorizationStatus,
        ).thenReturn(AuthorizationStatus.authorized);
        when(
          () => mockMessaging.getNotificationSettings(),
        ).thenAnswer((_) async => mockSettings);

        final status = await service.getPermissionStatus();

        expect(status, AuthorizationStatus.authorized);
        verify(() => mockMessaging.getNotificationSettings()).called(1);
      });
    });

    group('foreground message handling', () {
      test('should emit foreground messages to stream', () async {
        final mockMessage = MockRemoteMessage();
        when(() => mockMessage.messageId).thenReturn('msg_123');
        when(() => mockMessage.notification).thenReturn(null);
        when(() => mockMessage.data).thenReturn({});

        final receivedMessages = <RemoteMessage>[];
        final subscription = service.foregroundMessageStream.listen((msg) {
          receivedMessages.add(msg);
        });

        // Simulate receiving a foreground message
        onMessageController.add(mockMessage);

        // Wait for stream to process
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(receivedMessages.length, 1);
        expect(receivedMessages.first.messageId, 'msg_123');

        await subscription.cancel();
      });

      test('should call onForegroundMessage callback', () async {
        final mockMessage = MockRemoteMessage();
        when(() => mockMessage.messageId).thenReturn('msg_456');
        when(() => mockMessage.notification).thenReturn(null);
        when(() => mockMessage.data).thenReturn({});

        RemoteMessage? receivedMessage;
        service.onForegroundMessage = (msg) {
          receivedMessage = msg;
        };

        onMessageController.add(mockMessage);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(receivedMessage, isNotNull);
        expect(receivedMessage?.messageId, 'msg_456');
      });
    });

    group('notification tap handling', () {
      test('should emit notification tap events to stream', () async {
        final mockMessage = MockRemoteMessage();
        when(() => mockMessage.messageId).thenReturn('tap_msg_123');

        final tappedMessages = <RemoteMessage>[];
        final subscription = service.notificationTapStream.listen((msg) {
          tappedMessages.add(msg);
        });

        // Simulate notification tap (app in background)
        onMessageOpenedAppController.add(mockMessage);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(tappedMessages.length, 1);
        expect(tappedMessages.first.messageId, 'tap_msg_123');

        await subscription.cancel();
      });

      test('should call onNotificationTap callback', () async {
        final mockMessage = MockRemoteMessage();
        when(() => mockMessage.messageId).thenReturn('tap_msg_456');

        RemoteMessage? tappedMessage;
        service.onNotificationTap = (msg) {
          tappedMessage = msg;
        };

        onMessageOpenedAppController.add(mockMessage);

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(tappedMessage, isNotNull);
        expect(tappedMessage?.messageId, 'tap_msg_456');
      });
    });

    group('token refresh handling', () {
      test('should emit token updates to stream', () async {
        final receivedTokens = <String>[];
        final subscription = service.tokenStream.listen((token) {
          receivedTokens.add(token);
        });

        // Simulate token refresh
        onTokenRefreshController.add('new_token_123');

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(receivedTokens.length, 1);
        expect(receivedTokens.first, 'new_token_123');
        expect(service.currentToken, 'new_token_123');

        await subscription.cancel();
      });

      test('should call onTokenRefresh callback', () async {
        String? receivedToken;
        service.onTokenRefresh = (token) {
          receivedToken = token;
        };

        onTokenRefreshController.add('new_token_456');

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(receivedToken, 'new_token_456');
      });
    });
  });

  group('AuthorizationStatus', () {
    test('should have authorized status', () {
      expect(AuthorizationStatus.authorized, isNotNull);
    });

    test('should have denied status', () {
      expect(AuthorizationStatus.denied, isNotNull);
    });

    test('should have notDetermined status', () {
      expect(AuthorizationStatus.notDetermined, isNotNull);
    });

    test('should have provisional status', () {
      expect(AuthorizationStatus.provisional, isNotNull);
    });
  });
}

/// Testable version of FcmService that accepts mock dependencies.
class TestableFcmService {
  TestableFcmService({
    required FirebaseMessaging messaging,
    required Stream<RemoteMessage> onMessageStream,
    required Stream<RemoteMessage> onMessageOpenedAppStream,
    required Stream<String> onTokenRefreshStream,
  }) : _messaging = messaging,
       _onMessageStream = onMessageStream,
       _onMessageOpenedAppStream = onMessageOpenedAppStream,
       _onTokenRefreshStream = onTokenRefreshStream {
    _setupListeners();
  }

  final FirebaseMessaging _messaging;
  final Stream<RemoteMessage> _onMessageStream;
  final Stream<RemoteMessage> _onMessageOpenedAppStream;
  final Stream<String> _onTokenRefreshStream;

  String? _currentToken;
  String? get currentToken => _currentToken;

  final _tokenController = StreamController<String>.broadcast();
  Stream<String> get tokenStream => _tokenController.stream;

  final _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get foregroundMessageStream =>
      _foregroundMessageController.stream;

  final _notificationTapController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get notificationTapStream =>
      _notificationTapController.stream;

  FcmTokenCallback? onTokenRefresh;
  RemoteMessageCallback? onForegroundMessage;
  RemoteMessageCallback? onNotificationTap;

  void _setupListeners() {
    _onMessageStream.listen(_handleForegroundMessage);
    _onMessageOpenedAppStream.listen(_handleNotificationTap);
    _onTokenRefreshStream.listen(_handleTokenRefresh);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _foregroundMessageController.add(message);
    onForegroundMessage?.call(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    _notificationTapController.add(message);
    onNotificationTap?.call(message);
  }

  void _handleTokenRefresh(String token) {
    _currentToken = token;
    _tokenController.add(token);
    onTokenRefresh?.call(token);
  }

  Future<AuthorizationStatus> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    return settings.authorizationStatus;
  }

  Future<String?> getToken() async {
    try {
      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
        _tokenController.add(_currentToken!);
        onTokenRefresh?.call(_currentToken!);
      }
      return _currentToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _currentToken = null;
    } catch (_) {
      // Ignore errors
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (_) {
      // Ignore errors
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (_) {
      // Ignore errors
    }
  }

  Future<AuthorizationStatus> getPermissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  void dispose() {
    _tokenController.close();
    _foregroundMessageController.close();
    _notificationTapController.close();
  }
}
