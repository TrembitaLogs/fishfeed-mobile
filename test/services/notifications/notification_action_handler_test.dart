import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fishfeed/services/notifications/notification_action_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationActionIds', () {
    test('should have correct fed action ID', () {
      expect(NotificationActionIds.fed, equals('fed'));
    });

    test('should have correct snooze action ID', () {
      expect(NotificationActionIds.snooze, equals('snooze'));
    });
  });

  group('feedingCategoryId', () {
    test('should have correct category ID', () {
      expect(feedingCategoryId, equals('feeding_actions'));
    });
  });

  group('snoozeDuration', () {
    test('should be 15 minutes', () {
      expect(snoozeDuration, equals(const Duration(minutes: 15)));
    });
  });

  group('PendingNotificationAction', () {
    test('should create instance with required fields', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final action = PendingNotificationAction(
        actionId: NotificationActionIds.fed,
        payload: 'feeding_reminder_123',
        timestamp: timestamp,
      );

      expect(action.actionId, equals('fed'));
      expect(action.payload, equals('feeding_reminder_123'));
      expect(action.timestamp, equals(timestamp));
    });

    test('should serialize to JSON correctly', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30);
      final action = PendingNotificationAction(
        actionId: NotificationActionIds.snooze,
        payload: 'feeding_reminder_456',
        timestamp: timestamp,
      );

      final json = action.toJson();

      expect(json['actionId'], equals('snooze'));
      expect(json['payload'], equals('feeding_reminder_456'));
      expect(json['timestamp'], equals('2024-01-15T10:30:00.000'));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'actionId': 'fed',
        'payload': 'feeding_reminder_789',
        'timestamp': '2024-01-15T14:45:00.000',
      };

      final action = PendingNotificationAction.fromJson(json);

      expect(action.actionId, equals('fed'));
      expect(action.payload, equals('feeding_reminder_789'));
      expect(action.timestamp, equals(DateTime(2024, 1, 15, 14, 45)));
    });

    test('should roundtrip through JSON correctly', () {
      final original = PendingNotificationAction(
        actionId: NotificationActionIds.fed,
        payload: 'feeding_reminder_test',
        timestamp: DateTime(2024, 6, 20, 8, 0),
      );

      final json = original.toJson();
      final restored = PendingNotificationAction.fromJson(json);

      expect(restored.actionId, equals(original.actionId));
      expect(restored.payload, equals(original.payload));
      expect(restored.timestamp, equals(original.timestamp));
    });
  });

  group('NotificationActionStorage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('should add pending action', () async {
      final action = PendingNotificationAction(
        actionId: NotificationActionIds.fed,
        payload: 'feeding_reminder_100',
        timestamp: DateTime.now(),
      );

      await NotificationActionStorage.addPendingAction(action);

      final hasPending = await NotificationActionStorage.hasPendingActions();
      expect(hasPending, isTrue);
    });

    test('should retrieve and clear pending actions', () async {
      final action1 = PendingNotificationAction(
        actionId: NotificationActionIds.fed,
        payload: 'feeding_reminder_1',
        timestamp: DateTime(2024, 1, 1, 8, 0),
      );
      final action2 = PendingNotificationAction(
        actionId: NotificationActionIds.snooze,
        payload: 'feeding_reminder_2',
        timestamp: DateTime(2024, 1, 1, 9, 0),
      );

      await NotificationActionStorage.addPendingAction(action1);
      await NotificationActionStorage.addPendingAction(action2);

      final actions =
          await NotificationActionStorage.getAndClearPendingActions();

      expect(actions.length, equals(2));
      expect(actions[0].actionId, equals('fed'));
      expect(actions[0].payload, equals('feeding_reminder_1'));
      expect(actions[1].actionId, equals('snooze'));
      expect(actions[1].payload, equals('feeding_reminder_2'));

      // Should be cleared after retrieval
      final hasPending = await NotificationActionStorage.hasPendingActions();
      expect(hasPending, isFalse);
    });

    test('should return empty list when no pending actions', () async {
      final actions =
          await NotificationActionStorage.getAndClearPendingActions();
      expect(actions, isEmpty);
    });

    test('hasPendingActions should return false when empty', () async {
      final hasPending = await NotificationActionStorage.hasPendingActions();
      expect(hasPending, isFalse);
    });

    test('hasPendingActions should return true after adding action', () async {
      final action = PendingNotificationAction(
        actionId: NotificationActionIds.fed,
        payload: 'test',
        timestamp: DateTime.now(),
      );

      await NotificationActionStorage.addPendingAction(action);

      final hasPending = await NotificationActionStorage.hasPendingActions();
      expect(hasPending, isTrue);
    });
  });

  group('parseEventIdFromPayload', () {
    test('should parse event ID from feeding_reminder payload', () {
      expect(parseEventIdFromPayload('feeding_reminder_123'), equals(123));
    });

    test('should parse event ID from missed_event payload', () {
      expect(parseEventIdFromPayload('missed_event_456'), equals(456));
    });

    test('should parse event ID from confirm_status payload', () {
      expect(parseEventIdFromPayload('confirm_status_789'), equals(789));
    });

    test('should return null for null payload', () {
      expect(parseEventIdFromPayload(null), isNull);
    });

    test('should return null for empty payload', () {
      expect(parseEventIdFromPayload(''), isNull);
    });

    test('should return null for payload without numeric ID', () {
      expect(parseEventIdFromPayload('feeding_reminder_abc'), isNull);
    });

    test('should parse simple numeric payload', () {
      expect(parseEventIdFromPayload('42'), equals(42));
    });
  });

  group('parseScheduledFeedingIdFromPayload', () {
    test('should parse scheduled feeding ID from feeding_reminder payload', () {
      expect(
        parseScheduledFeedingIdFromPayload('feeding_reminder_feed_1'),
        equals('feed_1'),
      );
    });

    test('should parse numeric scheduled feeding ID', () {
      expect(
        parseScheduledFeedingIdFromPayload('feeding_reminder_123'),
        equals('123'),
      );
    });

    test('should return null for null payload', () {
      expect(parseScheduledFeedingIdFromPayload(null), isNull);
    });

    test('should return null for empty payload', () {
      expect(parseScheduledFeedingIdFromPayload(''), isNull);
    });

    test('should return null for non-feeding_reminder payload', () {
      expect(parseScheduledFeedingIdFromPayload('missed_event_123'), isNull);
    });

    test('should handle complex feeding IDs', () {
      expect(
        parseScheduledFeedingIdFromPayload(
          'feeding_reminder_aquarium_1_feed_2',
        ),
        equals('aquarium_1_feed_2'),
      );
    });
  });

  group('parseSchedulePayload', () {
    test('should parse valid schedule payload with UUID', () {
      const payload =
          'schedule_a1b2c3d4-e5f6-7890-abcd-ef1234567890_1705312800000';
      final result = parseSchedulePayload(payload);

      expect(result, isNotNull);
      expect(
        result!.scheduleId,
        equals('a1b2c3d4-e5f6-7890-abcd-ef1234567890'),
      );
      expect(
        result.scheduledFor,
        equals(DateTime.fromMillisecondsSinceEpoch(1705312800000)),
      );
    });

    test('should parse simple schedule ID', () {
      const payload = 'schedule_feed123_1705312800000';
      final result = parseSchedulePayload(payload);

      expect(result, isNotNull);
      expect(result!.scheduleId, equals('feed123'));
    });

    test('should return null for null payload', () {
      expect(parseSchedulePayload(null), isNull);
    });

    test('should return null for non-schedule payload', () {
      expect(parseSchedulePayload('feeding_reminder_123'), isNull);
    });

    test('should return null for schedule payload without timestamp', () {
      expect(parseSchedulePayload('schedule_abc'), isNull);
    });

    test('should return null for empty string', () {
      expect(parseSchedulePayload(''), isNull);
    });
  });

  group('parseDailyPayload', () {
    test('should parse valid daily payload', () {
      const payload = 'feeding_daily_09_30';
      final result = parseDailyPayload(payload);

      expect(result, isNotNull);
      expect(result!.hour, equals(9));
      expect(result.minute, equals(30));
    });

    test('should parse midnight payload', () {
      const payload = 'feeding_daily_00_00';
      final result = parseDailyPayload(payload);

      expect(result, isNotNull);
      expect(result!.hour, equals(0));
      expect(result.minute, equals(0));
    });

    test('should parse late evening payload', () {
      const payload = 'feeding_daily_23_59';
      final result = parseDailyPayload(payload);

      expect(result, isNotNull);
      expect(result!.hour, equals(23));
      expect(result.minute, equals(59));
    });

    test('should return null for null payload', () {
      expect(parseDailyPayload(null), isNull);
    });

    test('should return null for non-daily payload', () {
      expect(parseDailyPayload('feeding_slot_1'), isNull);
    });

    test('should return null for invalid hour', () {
      expect(parseDailyPayload('feeding_daily_25_00'), isNull);
    });

    test('should return null for invalid minute', () {
      expect(parseDailyPayload('feeding_daily_09_61'), isNull);
    });

    test('should return null for non-numeric values', () {
      expect(parseDailyPayload('feeding_daily_ab_cd'), isNull);
    });

    test('should return null for empty string', () {
      expect(parseDailyPayload(''), isNull);
    });
  });
}
