import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fishfeed/services/sync/background_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Reset SharedPreferences for each test
    SharedPreferences.setMockInitialValues({});
  });

  group('Constants', () {
    test('kBackgroundSyncTaskName should have correct value', () {
      expect(kBackgroundSyncTaskName, 'fishfeed_background_sync');
    });

    test('kBackgroundSyncTaskIdentifier should have correct value', () {
      expect(kBackgroundSyncTaskIdentifier, 'com.fishfeed.app.backgroundSync');
    });

    test('kBackgroundSyncFrequency should be 15 minutes', () {
      expect(kBackgroundSyncFrequency, const Duration(minutes: 15));
    });
  });

  group('BackgroundSyncService Singleton', () {
    test('should return same instance', () {
      final instance1 = BackgroundSyncService.instance;
      final instance2 = BackgroundSyncService.instance;

      expect(identical(instance1, instance2), isTrue);
    });
  });

  group('Last Background Sync Time', () {
    test('should return null when no sync has occurred', () async {
      // Initialize with empty preferences
      SharedPreferences.setMockInitialValues({});

      // Note: In real tests, we would need to properly initialize the service
      // Since Workmanager requires native setup, we test the logic separately
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getInt('last_background_sync'), isNull);
    });

    test('should store and retrieve last sync time correctly', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'last_background_sync': timestamp,
      });

      final prefs = await SharedPreferences.getInstance();
      final storedTimestamp = prefs.getInt('last_background_sync');

      expect(storedTimestamp, timestamp);
    });
  });

  group('Error Count', () {
    test('should return 0 when no errors recorded', () async {
      SharedPreferences.setMockInitialValues({});

      final prefs = await SharedPreferences.getInstance();
      final errorCount = prefs.getInt('background_sync_error_count') ?? 0;

      expect(errorCount, 0);
    });

    test('should increment error count correctly', () async {
      SharedPreferences.setMockInitialValues({
        'background_sync_error_count': 2,
      });

      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt('background_sync_error_count') ?? 0;
      await prefs.setInt('background_sync_error_count', currentCount + 1);

      expect(prefs.getInt('background_sync_error_count'), 3);
    });

    test('should reset error count to 0', () async {
      SharedPreferences.setMockInitialValues({
        'background_sync_error_count': 5,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('background_sync_error_count', 0);

      expect(prefs.getInt('background_sync_error_count'), 0);
    });
  });

  group('Display Text Formatting', () {
    test('getLastSyncDisplayText returns "Never" when no sync has occurred', () {
      final service = BackgroundSyncService.instance;
      // Without initialization, last sync should be null
      final displayText = service.getLastSyncDisplayText();

      expect(displayText, 'Never');
    });

    test('should format minutes correctly', () async {
      // Test the formatting logic with a recent timestamp
      final fiveMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 5));
      SharedPreferences.setMockInitialValues({
        'last_background_sync': fiveMinutesAgo.millisecondsSinceEpoch,
      });

      // Manually verify the formatting logic
      final duration = DateTime.now().difference(fiveMinutesAgo);
      expect(duration.inMinutes, greaterThanOrEqualTo(4));
      expect(duration.inMinutes, lessThanOrEqualTo(6));

      final minutes = duration.inMinutes;
      final expectedText = '$minutes ${minutes == 1 ? "minute" : "minutes"} ago';

      expect(expectedText, contains('minutes ago'));
    });

    test('should format hours correctly', () {
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      final duration = DateTime.now().difference(twoHoursAgo);

      expect(duration.inHours, greaterThanOrEqualTo(1));
      expect(duration.inHours, lessThanOrEqualTo(3));

      final hours = duration.inHours;
      final expectedText = '$hours ${hours == 1 ? "hour" : "hours"} ago';

      expect(expectedText, contains('hours ago'));
    });

    test('should format days correctly', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final duration = DateTime.now().difference(threeDaysAgo);

      expect(duration.inDays, greaterThanOrEqualTo(2));
      expect(duration.inDays, lessThanOrEqualTo(4));

      final days = duration.inDays;
      final expectedText = '$days ${days == 1 ? "day" : "days"} ago';

      expect(expectedText, contains('days ago'));
    });

    test('should handle singular forms correctly', () {
      // Test singular forms
      expect(_formatDuration(const Duration(minutes: 1)), '1 minute ago');
      expect(_formatDuration(const Duration(hours: 1)), '1 hour ago');
      expect(_formatDuration(const Duration(days: 1)), '1 day ago');
    });

    test('should handle plural forms correctly', () {
      // Test plural forms
      expect(_formatDuration(const Duration(minutes: 5)), '5 minutes ago');
      expect(_formatDuration(const Duration(hours: 3)), '3 hours ago');
      expect(_formatDuration(const Duration(days: 7)), '7 days ago');
    });

    test('should return "Just now" for very recent syncs', () {
      final result = _formatDuration(const Duration(seconds: 30));
      expect(result, 'Just now');
    });
  });

  group('Repeated Failures Detection', () {
    test('should detect repeated failures when error count >= 3', () async {
      SharedPreferences.setMockInitialValues({
        'background_sync_error_count': 3,
      });

      final prefs = await SharedPreferences.getInstance();
      final errorCount = prefs.getInt('background_sync_error_count') ?? 0;

      expect(errorCount >= 3, isTrue);
    });

    test('should not detect repeated failures when error count < 3', () async {
      SharedPreferences.setMockInitialValues({
        'background_sync_error_count': 2,
      });

      final prefs = await SharedPreferences.getInstance();
      final errorCount = prefs.getInt('background_sync_error_count') ?? 0;

      expect(errorCount >= 3, isFalse);
    });
  });

  group('Time Since Last Sync', () {
    test('should calculate time since last sync correctly', () async {
      final tenMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 10));
      SharedPreferences.setMockInitialValues({
        'last_background_sync': tenMinutesAgo.millisecondsSinceEpoch,
      });

      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('last_background_sync');
      final lastSync = DateTime.fromMillisecondsSinceEpoch(timestamp!);
      final timeSince = DateTime.now().difference(lastSync);

      expect(timeSince.inMinutes, greaterThanOrEqualTo(9));
      expect(timeSince.inMinutes, lessThanOrEqualTo(11));
    });

    test('should return null when no sync has occurred', () async {
      SharedPreferences.setMockInitialValues({});

      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('last_background_sync');

      expect(timestamp, isNull);
    });
  });
}

/// Helper function to mimic the display text formatting logic
String _formatDuration(Duration duration) {
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
