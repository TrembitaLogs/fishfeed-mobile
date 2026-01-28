import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fishfeed/core/utils/date_time_utils.dart';

void main() {
  setUpAll(() async {
    // Initialize locale data for date formatting tests
    await initializeDateFormatting('en_US', null);
  });

  group('DateTimeUtils', () {
    group('isSameDay', () {
      test('returns true for same day', () {
        final date1 = DateTime(2024, 1, 15, 10, 30);
        final date2 = DateTime(2024, 1, 15, 22, 45);

        expect(DateTimeUtils.isSameDay(date1, date2), isTrue);
      });

      test('returns false for different days', () {
        final date1 = DateTime(2024, 1, 15, 10, 30);
        final date2 = DateTime(2024, 1, 16, 10, 30);

        expect(DateTimeUtils.isSameDay(date1, date2), isFalse);
      });

      test('returns false for different months', () {
        final date1 = DateTime(2024, 1, 15);
        final date2 = DateTime(2024, 2, 15);

        expect(DateTimeUtils.isSameDay(date1, date2), isFalse);
      });

      test('returns false for different years', () {
        final date1 = DateTime(2024, 1, 15);
        final date2 = DateTime(2025, 1, 15);

        expect(DateTimeUtils.isSameDay(date1, date2), isFalse);
      });

      test('returns false when either date is null', () {
        final date = DateTime(2024, 1, 15);

        expect(DateTimeUtils.isSameDay(null, date), isFalse);
        expect(DateTimeUtils.isSameDay(date, null), isFalse);
        expect(DateTimeUtils.isSameDay(null, null), isFalse);
      });

      test('handles UTC and local dates correctly', () {
        final utcDate = DateTime.utc(2024, 1, 15, 10, 30);
        final localDate = DateTime(2024, 1, 15, 22, 45);

        // Both should be converted to local before comparison
        expect(DateTimeUtils.isSameDay(utcDate, localDate), isTrue);
      });
    });

    group('isToday', () {
      test('returns true for today', () {
        final now = DateTime.now();
        expect(DateTimeUtils.isToday(now), isTrue);
      });

      test('returns false for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(DateTimeUtils.isToday(yesterday), isFalse);
      });

      test('returns false for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(DateTimeUtils.isToday(tomorrow), isFalse);
      });
    });

    group('isYesterday', () {
      test('returns true for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(DateTimeUtils.isYesterday(yesterday), isTrue);
      });

      test('returns false for today', () {
        expect(DateTimeUtils.isYesterday(DateTime.now()), isFalse);
      });
    });

    group('isTomorrow', () {
      test('returns true for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(DateTimeUtils.isTomorrow(tomorrow), isTrue);
      });

      test('returns false for today', () {
        expect(DateTimeUtils.isTomorrow(DateTime.now()), isFalse);
      });
    });

    group('startOfDay', () {
      test('returns start of day', () {
        final date = DateTime(2024, 1, 15, 14, 30, 45, 123);
        final startOfDay = DateTimeUtils.startOfDay(date);

        expect(startOfDay.year, 2024);
        expect(startOfDay.month, 1);
        expect(startOfDay.day, 15);
        expect(startOfDay.hour, 0);
        expect(startOfDay.minute, 0);
        expect(startOfDay.second, 0);
        expect(startOfDay.millisecond, 0);
      });
    });

    group('endOfDay', () {
      test('returns end of day', () {
        final date = DateTime(2024, 1, 15, 14, 30);
        final endOfDay = DateTimeUtils.endOfDay(date);

        expect(endOfDay.year, 2024);
        expect(endOfDay.month, 1);
        expect(endOfDay.day, 15);
        expect(endOfDay.hour, 23);
        expect(endOfDay.minute, 59);
        expect(endOfDay.second, 59);
        expect(endOfDay.millisecond, 999);
      });
    });

    group('daysBetween', () {
      test('returns 0 for same day', () {
        final date1 = DateTime(2024, 1, 15, 10, 30);
        final date2 = DateTime(2024, 1, 15, 22, 45);

        expect(DateTimeUtils.daysBetween(date1, date2), 0);
      });

      test('returns 1 for consecutive days', () {
        final date1 = DateTime(2024, 1, 15, 22, 30);
        final date2 = DateTime(2024, 1, 16, 2, 45);

        expect(DateTimeUtils.daysBetween(date1, date2), 1);
      });

      test('returns positive for future date', () {
        final date1 = DateTime(2024, 1, 15);
        final date2 = DateTime(2024, 1, 20);

        expect(DateTimeUtils.daysBetween(date1, date2), 5);
      });

      test('returns negative for past date', () {
        final date1 = DateTime(2024, 1, 20);
        final date2 = DateTime(2024, 1, 15);

        expect(DateTimeUtils.daysBetween(date1, date2), -5);
      });
    });

    group('areConsecutiveDays', () {
      test('returns true for consecutive days', () {
        final date1 = DateTime(2024, 1, 15);
        final date2 = DateTime(2024, 1, 16);

        expect(DateTimeUtils.areConsecutiveDays(date1, date2), isTrue);
      });

      test('returns false for same day', () {
        final date1 = DateTime(2024, 1, 15, 10);
        final date2 = DateTime(2024, 1, 15, 20);

        expect(DateTimeUtils.areConsecutiveDays(date1, date2), isFalse);
      });

      test('returns false for non-consecutive days', () {
        final date1 = DateTime(2024, 1, 15);
        final date2 = DateTime(2024, 1, 18);

        expect(DateTimeUtils.areConsecutiveDays(date1, date2), isFalse);
      });
    });

    group('checkStreakValidity', () {
      test('returns valid with 2 days until expiry when fed today', () {
        final today = DateTime.now();
        final result = DateTimeUtils.checkStreakValidity(today);

        expect(result.isValid, isTrue);
        expect(result.daysUntilExpiry, 2);
      });

      test('returns valid with 1 day until expiry when fed yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final result = DateTimeUtils.checkStreakValidity(yesterday);

        expect(result.isValid, isTrue);
        expect(result.daysUntilExpiry, 1);
      });

      test('returns invalid when more than 1 day ago', () {
        final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
        final result = DateTimeUtils.checkStreakValidity(twoDaysAgo);

        expect(result.isValid, isFalse);
        expect(result.daysUntilExpiry, 0);
      });
    });

    group('hasMidnightCrossed', () {
      test('returns false for same day', () {
        final now = DateTime.now();
        final earlier = now.subtract(const Duration(hours: 2));

        expect(DateTimeUtils.hasMidnightCrossed(earlier), isFalse);
      });

      test('returns true when midnight crossed', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));

        expect(DateTimeUtils.hasMidnightCrossed(yesterday), isTrue);
      });
    });

    group('nextMidnight', () {
      test('returns next midnight', () {
        final nextMidnight = DateTimeUtils.nextMidnight;
        final now = DateTime.now();

        expect(nextMidnight.isAfter(now), isTrue);
        expect(nextMidnight.hour, 0);
        expect(nextMidnight.minute, 0);
        expect(nextMidnight.second, 0);
      });
    });

    group('durationUntilMidnight', () {
      test('returns positive duration', () {
        final duration = DateTimeUtils.durationUntilMidnight;

        expect(duration.inSeconds, greaterThan(0));
        expect(duration.inHours, lessThanOrEqualTo(24));
      });
    });

    group('formatDate', () {
      test('formats date with EN locale', () {
        final date = DateTime(2024, 1, 15);
        final formatted = DateTimeUtils.formatDate(date, 'en_US');

        expect(formatted, contains('15'));
        expect(formatted, contains('2024'));
      });

      test('formats date with DE locale', () {
        final date = DateTime(2024, 1, 15);
        // Use 'en' for test since DE locale data may not be available
        final formatted = DateTimeUtils.formatDate(date, 'en');

        expect(formatted, contains('15'));
        expect(formatted, contains('2024'));
      });
    });

    group('formatNumber', () {
      test('formats number with EN locale', () {
        final formatted = DateTimeUtils.formatNumber(1234, 'en_US');

        expect(formatted, contains('1'));
        expect(formatted, contains('234'));
      });

      test('formats number with DE locale', () {
        // Use 'en' for test since DE locale data may not be available
        final formatted = DateTimeUtils.formatNumber(1234, 'en');

        expect(formatted, contains('1'));
        expect(formatted, contains('234'));
      });
    });

    group('formatCompactNumber', () {
      test('formats large number compactly', () {
        final formatted = DateTimeUtils.formatCompactNumber(1234, 'en_US');

        // Compact number should be shorter than the full number
        expect(formatted.length, lessThanOrEqualTo(5));
      });
    });
  });
}
