import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import 'package:fishfeed/services/notifications/notification_service.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockAndroidFlutterLocalNotificationsPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class MockIOSFlutterLocalNotificationsPlugin extends Mock
    implements IOSFlutterLocalNotificationsPlugin {}

class FakeInitializationSettings extends Fake
    implements InitializationSettings {}

class FakeNotificationDetails extends Fake implements NotificationDetails {}

class FakeTZDateTime extends Fake implements tz.TZDateTime {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz_data.initializeTimeZones();
    registerFallbackValue(FakeInitializationSettings());
    registerFallbackValue(FakeNotificationDetails());
    registerFallbackValue(FakeTZDateTime());
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
    registerFallbackValue(UILocalNotificationDateInterpretation.absoluteTime);
  });

  group('NotificationService', () {
    group('constants', () {
      test('should have correct feeding channel ID', () {
        expect(
          NotificationService.feedingChannelId,
          equals('feeding_reminders'),
        );
      });

      test('should have correct feeding channel name', () {
        expect(
          NotificationService.feedingChannelName,
          equals('Feeding Reminders'),
        );
      });

      test('should have correct feeding channel description', () {
        expect(
          NotificationService.feedingChannelDescription,
          equals('Notifications for scheduled fish feeding times'),
        );
      });

      test('should have correct missed channel ID', () {
        expect(NotificationService.missedChannelId, equals('missed_events'));
      });

      test('should have correct missed channel name', () {
        expect(NotificationService.missedChannelName, equals('Missed Events'));
      });

      test('should have correct missed channel description', () {
        expect(
          NotificationService.missedChannelDescription,
          equals('Notifications for missed feeding events'),
        );
      });

      test('should have correct confirm channel ID', () {
        expect(NotificationService.confirmChannelId, equals('confirm_status'));
      });

      test('should have correct confirm channel name', () {
        expect(
          NotificationService.confirmChannelName,
          equals('Status Confirmations'),
        );
      });

      test('should have correct confirm channel description', () {
        expect(
          NotificationService.confirmChannelDescription,
          equals('Reminders to confirm feeding status'),
        );
      });

      test('should have 24 hour throttle duration for missed events', () {
        expect(
          NotificationService.missedEventThrottleDuration,
          equals(const Duration(hours: 24)),
        );
      });
    });

    group('singleton', () {
      test('should return same instance', () {
        final instance1 = NotificationService.instance;
        final instance2 = NotificationService.instance;

        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('isInitialized', () {
      test('should have isInitialized getter', () {
        final service = NotificationService.instance;
        // Just verify the getter exists and returns a bool
        expect(service.isInitialized, isA<bool>());
      });
    });
  });

  group('NotificationService with mock plugin', () {
    late MockFlutterLocalNotificationsPlugin mockPlugin;
    late TestableNotificationService service;

    setUp(() {
      mockPlugin = MockFlutterLocalNotificationsPlugin();
      service = TestableNotificationService(mockPlugin);
    });

    tearDown(() {
      reset(mockPlugin);
    });

    group('initialize', () {
      test('should initialize plugin with correct settings', () async {
        when(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).thenAnswer((_) async => true);

        await service.initialize();

        verify(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).called(1);
        expect(service.isInitialized, isTrue);
      });

      test('should not reinitialize if already initialized', () async {
        when(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).thenAnswer((_) async => true);

        await service.initialize();
        await service.initialize();

        verify(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).called(1);
      });
    });

    group('cancelNotification', () {
      test('should cancel notification by id', () async {
        when(() => mockPlugin.cancel(any())).thenAnswer((_) async {});

        await service.cancelNotification(123);

        verify(() => mockPlugin.cancel(123)).called(1);
      });
    });

    group('cancelAllNotifications', () {
      test('should cancel all notifications', () async {
        when(() => mockPlugin.cancelAll()).thenAnswer((_) async {});

        await service.cancelAllNotifications();

        verify(() => mockPlugin.cancelAll()).called(1);
      });
    });

    group('getPendingNotifications', () {
      test('should return pending notification requests', () async {
        final pendingRequests = [
          const PendingNotificationRequest(1, 'Title 1', 'Body 1', 'payload1'),
          const PendingNotificationRequest(2, 'Title 2', 'Body 2', 'payload2'),
        ];

        when(
          () => mockPlugin.pendingNotificationRequests(),
        ).thenAnswer((_) async => pendingRequests);

        final result = await service.getPendingNotifications();

        expect(result, equals(pendingRequests));
        expect(result.length, equals(2));
      });

      test('should return empty list when no pending notifications', () async {
        when(
          () => mockPlugin.pendingNotificationRequests(),
        ).thenAnswer((_) async => []);

        final result = await service.getPendingNotifications();

        expect(result, isEmpty);
      });
    });

    group('requestPermissions', () {
      test('Android should request notifications permission', () async {
        final mockAndroidPlugin = MockAndroidFlutterLocalNotificationsPlugin();

        when(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >(),
        ).thenReturn(mockAndroidPlugin);
        when(
          () => mockAndroidPlugin.requestNotificationsPermission(),
        ).thenAnswer((_) async => true);

        await service.initialize();
        final result = await service.requestAndroidPermissions();

        expect(result, isTrue);
        verify(
          () => mockAndroidPlugin.requestNotificationsPermission(),
        ).called(1);
      });

      test('Android should return false if plugin not available', () async {
        when(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >(),
        ).thenReturn(null);

        await service.initialize();
        final result = await service.requestAndroidPermissions();

        expect(result, isFalse);
      });

      test('iOS should request all permissions', () async {
        final mockIOSPlugin = MockIOSFlutterLocalNotificationsPlugin();

        when(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >(),
        ).thenReturn(mockIOSPlugin);
        when(
          () => mockIOSPlugin.requestPermissions(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
          ),
        ).thenAnswer((_) async => true);

        await service.initialize();
        final result = await service.requestIOSPermissions();

        expect(result, isTrue);
        verify(
          () => mockIOSPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ),
        ).called(1);
      });

      test('iOS should return false if plugin not available', () async {
        when(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >(),
        ).thenReturn(null);

        await service.initialize();
        final result = await service.requestIOSPermissions();

        expect(result, isFalse);
      });
    });
  });

  group('Notification text generation', () {
    test('single species should use species name', () {
      final text = generateSpeciesText(['Goldfish']);
      expect(text, equals('Goldfish'));
    });

    test('multiple species should use count', () {
      final text = generateSpeciesText(['Goldfish', 'Betta', 'Neon']);
      expect(text, equals('3 species'));
    });

    test('two species should use count', () {
      final text = generateSpeciesText(['Goldfish', 'Betta']);
      expect(text, equals('2 species'));
    });
  });

  group('NotificationType', () {
    test('should have feedingReminder type', () {
      expect(NotificationType.feedingReminder, isNotNull);
      expect(NotificationType.feedingReminder.name, equals('feedingReminder'));
    });

    test('should have missedEvent type', () {
      expect(NotificationType.missedEvent, isNotNull);
      expect(NotificationType.missedEvent.name, equals('missedEvent'));
    });

    test('should have confirmStatus type', () {
      expect(NotificationType.confirmStatus, isNotNull);
      expect(NotificationType.confirmStatus.name, equals('confirmStatus'));
    });

    test('should have freezeAvailable type', () {
      expect(NotificationType.freezeAvailable, isNotNull);
      expect(NotificationType.freezeAvailable.name, equals('freezeAvailable'));
    });

    test('should have exactly 4 types', () {
      expect(NotificationType.values.length, equals(4));
    });
  });

  group('Scheduled notifications with mock plugin', () {
    late MockFlutterLocalNotificationsPlugin mockPlugin;
    late TestableNotificationServiceV2 service;

    setUp(() {
      tz.setLocalLocation(tz.getLocation('UTC'));
      mockPlugin = MockFlutterLocalNotificationsPlugin();
      service = TestableNotificationServiceV2(mockPlugin);
    });

    tearDown(() {
      reset(mockPlugin);
      service.clearAllThrottleRecords();
    });

    group('scheduleFeeding', () {
      test('should schedule feeding notification for future time', () async {
        when(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            uiLocalNotificationDateInterpretation: any(
              named: 'uiLocalNotificationDateInterpretation',
            ),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});

        await service.initialize();
        final futureTime = DateTime.now().add(const Duration(hours: 1));

        await service.scheduleFeeding(
          time: futureTime,
          fishName: 'Goldfish',
          eventId: 123,
        );

        verify(
          () => mockPlugin.zonedSchedule(
            1231, // eventId * 10 + 1
            'Feeding time!',
            'Time to feed Goldfish!',
            any(),
            any(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'feeding_reminder_123',
          ),
        ).called(1);
      });

      test('should not schedule feeding notification for past time', () async {
        when(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).thenAnswer((_) async => true);

        await service.initialize();
        final pastTime = DateTime.now().subtract(const Duration(hours: 1));

        await service.scheduleFeeding(
          time: pastTime,
          fishName: 'Goldfish',
          eventId: 123,
        );

        verifyNever(
          () => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            uiLocalNotificationDateInterpretation: any(
              named: 'uiLocalNotificationDateInterpretation',
            ),
            payload: any(named: 'payload'),
          ),
        );
      });
    });

    group('scheduleMissedReminder', () {
      test('should schedule missed notification for future time', () async {
        when(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            uiLocalNotificationDateInterpretation: any(
              named: 'uiLocalNotificationDateInterpretation',
            ),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});

        await service.initialize();
        final futureTime = DateTime.now().add(const Duration(hours: 1));

        final result = await service.scheduleMissedReminder(
          time: futureTime,
          fishName: 'Betta',
          eventId: 456,
        );

        expect(result, isTrue);
        verify(
          () => mockPlugin.zonedSchedule(
            4562, // eventId * 10 + 2
            'Missed event',
            'Missed event for Betta',
            any(),
            any(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'missed_event_456',
          ),
        ).called(1);
      });

      test('should return false for past time', () async {
        when(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).thenAnswer((_) async => true);

        await service.initialize();
        final pastTime = DateTime.now().subtract(const Duration(hours: 1));

        final result = await service.scheduleMissedReminder(
          time: pastTime,
          fishName: 'Betta',
          eventId: 456,
        );

        expect(result, isFalse);
      });

      test('should throttle missed notifications within 24 hours', () async {
        when(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            uiLocalNotificationDateInterpretation: any(
              named: 'uiLocalNotificationDateInterpretation',
            ),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});

        await service.initialize();
        final futureTime = DateTime.now().add(const Duration(hours: 1));

        // First call should succeed
        final result1 = await service.scheduleMissedReminder(
          time: futureTime,
          fishName: 'Betta',
          eventId: 789,
        );
        expect(result1, isTrue);

        // Second call with same eventId should be throttled
        final result2 = await service.scheduleMissedReminder(
          time: futureTime.add(const Duration(minutes: 30)),
          fishName: 'Betta',
          eventId: 789,
        );
        expect(result2, isFalse);

        // Only one zonedSchedule call should have been made
        verify(
          () => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            uiLocalNotificationDateInterpretation: any(
              named: 'uiLocalNotificationDateInterpretation',
            ),
            payload: any(named: 'payload'),
          ),
        ).called(1);
      });

      test('should allow missed notifications for different events', () async {
        when(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            uiLocalNotificationDateInterpretation: any(
              named: 'uiLocalNotificationDateInterpretation',
            ),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});

        await service.initialize();
        final futureTime = DateTime.now().add(const Duration(hours: 1));

        // First event
        final result1 = await service.scheduleMissedReminder(
          time: futureTime,
          fishName: 'Betta',
          eventId: 100,
        );
        expect(result1, isTrue);

        // Different event should succeed
        final result2 = await service.scheduleMissedReminder(
          time: futureTime,
          fishName: 'Goldfish',
          eventId: 200,
        );
        expect(result2, isTrue);

        verify(
          () => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            uiLocalNotificationDateInterpretation: any(
              named: 'uiLocalNotificationDateInterpretation',
            ),
            payload: any(named: 'payload'),
          ),
        ).called(2);
      });
    });

    group('scheduleConfirmationReminder', () {
      test(
        'should schedule confirmation notification for future time',
        () async {
          when(
            () => mockPlugin.initialize(
              any(),
              onDidReceiveNotificationResponse: any(
                named: 'onDidReceiveNotificationResponse',
              ),
            ),
          ).thenAnswer((_) async => true);
          when(
            () => mockPlugin.zonedSchedule(
              any(),
              any(),
              any(),
              any(),
              any(),
              androidScheduleMode: any(named: 'androidScheduleMode'),
              uiLocalNotificationDateInterpretation: any(
                named: 'uiLocalNotificationDateInterpretation',
              ),
              payload: any(named: 'payload'),
            ),
          ).thenAnswer((_) async {});

          await service.initialize();
          final futureTime = DateTime.now().add(const Duration(minutes: 15));

          await service.scheduleConfirmationReminder(
            time: futureTime,
            eventId: 555,
          );

          verify(
            () => mockPlugin.zonedSchedule(
              5553, // eventId * 10 + 3
              'Confirm status',
              'Confirm feeding status',
              any(),
              any(),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              payload: 'confirm_status_555',
            ),
          ).called(1);
        },
      );

      test(
        'should not schedule confirmation notification for past time',
        () async {
          when(
            () => mockPlugin.initialize(
              any(),
              onDidReceiveNotificationResponse: any(
                named: 'onDidReceiveNotificationResponse',
              ),
            ),
          ).thenAnswer((_) async => true);

          await service.initialize();
          final pastTime = DateTime.now().subtract(const Duration(minutes: 15));

          await service.scheduleConfirmationReminder(
            time: pastTime,
            eventId: 555,
          );

          verifyNever(
            () => mockPlugin.zonedSchedule(
              any(),
              any(),
              any(),
              any(),
              any(),
              androidScheduleMode: any(named: 'androidScheduleMode'),
              uiLocalNotificationDateInterpretation: any(
                named: 'uiLocalNotificationDateInterpretation',
              ),
              payload: any(named: 'payload'),
            ),
          );
        },
      );
    });

    group('cancelScheduledNotification', () {
      test('should cancel all notification types for an event', () async {
        when(() => mockPlugin.cancel(any())).thenAnswer((_) async {});

        await service.cancelScheduledNotification(42);

        // Should cancel feeding reminder (42 * 10 + 1 = 421)
        verify(() => mockPlugin.cancel(421)).called(1);
        // Should cancel missed event (42 * 10 + 2 = 422)
        verify(() => mockPlugin.cancel(422)).called(1);
        // Should cancel confirm status (42 * 10 + 3 = 423)
        verify(() => mockPlugin.cancel(423)).called(1);
      });
    });

    group('throttle mechanism', () {
      test('clearAllThrottleRecords should clear all records', () async {
        when(
          () => mockPlugin.initialize(
            any(),
            onDidReceiveNotificationResponse: any(
              named: 'onDidReceiveNotificationResponse',
            ),
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockPlugin.zonedSchedule(
            any(),
            any(),
            any(),
            any(),
            any(),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            uiLocalNotificationDateInterpretation: any(
              named: 'uiLocalNotificationDateInterpretation',
            ),
            payload: any(named: 'payload'),
          ),
        ).thenAnswer((_) async {});

        await service.initialize();
        final futureTime = DateTime.now().add(const Duration(hours: 1));

        // Schedule a missed notification to create a throttle record
        await service.scheduleMissedReminder(
          time: futureTime,
          fishName: 'Fish',
          eventId: 999,
        );

        // Clear all records
        service.clearAllThrottleRecords();

        // Should be able to schedule again for the same event
        final result = await service.scheduleMissedReminder(
          time: futureTime.add(const Duration(minutes: 30)),
          fishName: 'Fish',
          eventId: 999,
        );

        expect(result, isTrue);
      });
    });
  });
}

/// Helper function to test species text generation logic
String generateSpeciesText(List<String> speciesNames) {
  return speciesNames.length == 1
      ? speciesNames.first
      : '${speciesNames.length} species';
}

/// Testable version of NotificationService that accepts a mock plugin.
class TestableNotificationService {
  TestableNotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );

    _isInitialized = true;
  }

  Future<bool> requestAndroidPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return false;

    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<bool> requestIOSPermissions() async {
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosPlugin == null) return false;

    final granted = await iosPlugin.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return granted ?? false;
  }

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
          NotificationService.feedingChannelId,
          NotificationService.feedingChannelName,
          channelDescription: NotificationService.feedingChannelDescription,
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

  Future<void> scheduleFeedingReminders({
    required List<String> times,
    required List<String> speciesNames,
    int baseId = 1000,
  }) async {
    final speciesText = generateSpeciesText(speciesNames);

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

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }
}

/// Testable version of NotificationService V2 with scheduled notification methods.
class TestableNotificationServiceV2 {
  TestableNotificationServiceV2(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;
  final Map<String, DateTime> _lastNotificationTimes = {};

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );

    _isInitialized = true;
  }

  Future<void> scheduleFeeding({
    required DateTime time,
    required String fishName,
    required int eventId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (time.isBefore(DateTime.now())) {
      return;
    }

    final scheduledTime = tz.TZDateTime.from(time, tz.local);

    await _plugin.zonedSchedule(
      _generateNotificationId(NotificationType.feedingReminder, eventId),
      'Feeding time!',
      'Time to feed $fishName!',
      scheduledTime,
      _getNotificationDetails(NotificationType.feedingReminder),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'feeding_reminder_$eventId',
    );
  }

  Future<bool> scheduleMissedReminder({
    required DateTime time,
    required String fishName,
    required int eventId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isThrottled(NotificationType.missedEvent, eventId)) {
      return false;
    }

    if (time.isBefore(DateTime.now())) {
      return false;
    }

    final scheduledTime = tz.TZDateTime.from(time, tz.local);

    await _plugin.zonedSchedule(
      _generateNotificationId(NotificationType.missedEvent, eventId),
      'Missed event',
      'Missed event for $fishName',
      scheduledTime,
      _getNotificationDetails(NotificationType.missedEvent),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'missed_event_$eventId',
    );

    _recordNotificationTime(NotificationType.missedEvent, eventId);

    return true;
  }

  Future<void> scheduleConfirmationReminder({
    required DateTime time,
    required int eventId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (time.isBefore(DateTime.now())) {
      return;
    }

    final scheduledTime = tz.TZDateTime.from(time, tz.local);

    await _plugin.zonedSchedule(
      _generateNotificationId(NotificationType.confirmStatus, eventId),
      'Confirm status',
      'Confirm feeding status',
      scheduledTime,
      _getNotificationDetails(NotificationType.confirmStatus),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'confirm_status_$eventId',
    );
  }

  Future<void> cancelScheduledNotification(int eventId) async {
    await Future.wait([
      _plugin.cancel(
        _generateNotificationId(NotificationType.feedingReminder, eventId),
      ),
      _plugin.cancel(
        _generateNotificationId(NotificationType.missedEvent, eventId),
      ),
      _plugin.cancel(
        _generateNotificationId(NotificationType.confirmStatus, eventId),
      ),
    ]);

    _clearThrottleRecords(eventId);
  }

  int _generateNotificationId(NotificationType type, int eventId) {
    final baseId = eventId * 10;
    return switch (type) {
      NotificationType.feedingReminder => baseId + 1,
      NotificationType.missedEvent => baseId + 2,
      NotificationType.confirmStatus => baseId + 3,
      NotificationType.freezeAvailable => baseId + 4,
    };
  }

  NotificationDetails _getNotificationDetails(NotificationType type) {
    return switch (type) {
      NotificationType.feedingReminder => const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationService.feedingChannelId,
          NotificationService.feedingChannelName,
          channelDescription: NotificationService.feedingChannelDescription,
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
      NotificationType.missedEvent => const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationService.missedChannelId,
          NotificationService.missedChannelName,
          channelDescription: NotificationService.missedChannelDescription,
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
      NotificationType.confirmStatus => const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationService.confirmChannelId,
          NotificationService.confirmChannelName,
          channelDescription: NotificationService.confirmChannelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
      NotificationType.freezeAvailable => const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationService.freezeChannelId,
          NotificationService.freezeChannelName,
          channelDescription: NotificationService.freezeChannelDescription,
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
    };
  }

  bool _isThrottled(NotificationType type, int eventId) {
    final key = _throttleKey(type, eventId);
    final lastTime = _lastNotificationTimes[key];

    if (lastTime == null) {
      return false;
    }

    final throttleDuration = switch (type) {
      NotificationType.missedEvent =>
        NotificationService.missedEventThrottleDuration,
      _ => Duration.zero,
    };

    return DateTime.now().difference(lastTime) < throttleDuration;
  }

  void _recordNotificationTime(NotificationType type, int eventId) {
    final key = _throttleKey(type, eventId);
    _lastNotificationTimes[key] = DateTime.now();
  }

  void _clearThrottleRecords(int eventId) {
    for (final type in NotificationType.values) {
      _lastNotificationTimes.remove(_throttleKey(type, eventId));
    }
  }

  String _throttleKey(NotificationType type, int eventId) {
    return '${type.name}_$eventId';
  }

  void clearAllThrottleRecords() {
    _lastNotificationTimes.clear();
  }
}
