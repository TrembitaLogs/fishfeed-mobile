import 'package:intl/intl.dart';

/// Utility class for timezone-aware date/time operations.
///
/// Handles:
/// - UTC conversions for backend sync
/// - Local timezone for display and notifications
/// - Proper date comparison (isSameDay)
/// - DST (Daylight Saving Time) transitions
/// - Midnight crossing for streak calculation
class DateTimeUtils {
  DateTimeUtils._();

  // ============ Date Comparison ============

  /// Checks if two dates represent the same calendar day in local timezone.
  ///
  /// This method normalizes both dates to local timezone before comparison,
  /// ensuring consistent behavior regardless of the original timezone.
  static bool isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;

    final local1 = date1.toLocal();
    final local2 = date2.toLocal();

    return local1.year == local2.year &&
        local1.month == local2.month &&
        local1.day == local2.day;
  }

  /// Checks if the given date is today in local timezone.
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Checks if the given date is yesterday in local timezone.
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Checks if the given date is tomorrow in local timezone.
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(date, tomorrow);
  }

  // ============ Day Boundaries ============

  /// Returns the start of day (00:00:00) for the given date in local timezone.
  static DateTime startOfDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Returns the end of day (23:59:59.999) for the given date in local timezone.
  static DateTime endOfDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day, 23, 59, 59, 999);
  }

  /// Returns the start of today in local timezone.
  static DateTime get todayStart => startOfDay(DateTime.now());

  /// Returns the end of today in local timezone.
  static DateTime get todayEnd => endOfDay(DateTime.now());

  // ============ UTC Conversions ============

  /// Converts a local DateTime to UTC for backend sync.
  ///
  /// Always use UTC when sending data to the backend to ensure
  /// consistent timestamps across different timezones.
  static DateTime toUtc(DateTime local) {
    return local.toUtc();
  }

  /// Converts a UTC DateTime to local for display.
  ///
  /// Always use local time for display to users and for
  /// scheduling notifications.
  static DateTime toLocal(DateTime utc) {
    return utc.toLocal();
  }

  /// Returns the current time in UTC.
  static DateTime get nowUtc => DateTime.now().toUtc();

  /// Returns the current time in local timezone.
  static DateTime get nowLocal => DateTime.now();

  // ============ Streak Calculations ============

  /// Calculates the number of calendar days between two dates.
  ///
  /// This uses local timezone and accounts for DST transitions.
  /// For example, if date1 is Monday and date2 is Wednesday,
  /// this returns 2 (not based on hours).
  static int daysBetween(DateTime date1, DateTime date2) {
    final start = startOfDay(date1);
    final end = startOfDay(date2);
    return end.difference(start).inDays;
  }

  /// Checks if two dates are consecutive calendar days.
  ///
  /// Returns true if date2 is exactly one calendar day after date1.
  static bool areConsecutiveDays(DateTime date1, DateTime date2) {
    return daysBetween(date1, date2) == 1;
  }

  /// Checks if the streak is still valid based on the last feeding date.
  ///
  /// A streak is valid if:
  /// - User fed today (returns true with 0 days until expiry warning)
  /// - User fed yesterday (returns true, need to feed today)
  ///
  /// Returns a record with (isValid, daysUntilExpiry).
  static ({bool isValid, int daysUntilExpiry}) checkStreakValidity(
    DateTime lastFeedingDate,
  ) {
    final daysSinceFeed = daysBetween(lastFeedingDate, DateTime.now());

    if (daysSinceFeed == 0) {
      // Fed today
      return (isValid: true, daysUntilExpiry: 2);
    } else if (daysSinceFeed == 1) {
      // Fed yesterday, need to feed today
      return (isValid: true, daysUntilExpiry: 1);
    } else {
      // Streak is broken
      return (isValid: false, daysUntilExpiry: 0);
    }
  }

  // ============ Midnight Crossing ============

  /// Checks if midnight has crossed since the given time.
  ///
  /// Useful for detecting when the app resumes after being
  /// in background and a new day has started.
  static bool hasMidnightCrossed(DateTime since) {
    final now = DateTime.now();
    return !isSameDay(since, now);
  }

  /// Returns the next midnight in local timezone.
  static DateTime get nextMidnight {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  /// Returns the duration until next midnight.
  static Duration get durationUntilMidnight {
    return nextMidnight.difference(DateTime.now());
  }

  // ============ DST Handling ============

  /// Gets the current timezone offset.
  static Duration get currentTimezoneOffset {
    return DateTime.now().timeZoneOffset;
  }

  /// Gets the timezone name.
  static String get timezoneName {
    return DateTime.now().timeZoneName;
  }

  /// Checks if DST transition happened between two dates.
  ///
  /// This can affect streak calculations and notifications.
  static bool dstTransitionBetween(DateTime date1, DateTime date2) {
    return date1.timeZoneOffset != date2.timeZoneOffset;
  }

  // ============ Formatting ============

  /// Formats a date for display using the given locale.
  ///
  /// Example: "January 15, 2024" or "15. Januar 2024" (DE)
  static String formatDate(DateTime date, String locale) {
    final formatter = DateFormat.yMMMMd(locale);
    return formatter.format(date.toLocal());
  }

  /// Formats a time for display using the given locale.
  ///
  /// Example: "3:30 PM" or "15:30" (24h format for DE)
  static String formatTime(DateTime date, String locale) {
    final formatter = DateFormat.jm(locale);
    return formatter.format(date.toLocal());
  }

  /// Formats a date and time for display using the given locale.
  static String formatDateTime(DateTime date, String locale) {
    final dateFormatter = DateFormat.yMMMd(locale);
    final timeFormatter = DateFormat.jm(locale);
    final localDate = date.toLocal();
    return '${dateFormatter.format(localDate)} ${timeFormatter.format(localDate)}';
  }

  /// Formats a relative date (Today, Yesterday, or date).
  static String formatRelativeDate(
    DateTime date,
    String locale, {
    String? todayLabel,
    String? yesterdayLabel,
  }) {
    if (isToday(date)) {
      return todayLabel ?? 'Today';
    } else if (isYesterday(date)) {
      return yesterdayLabel ?? 'Yesterday';
    } else {
      return formatDate(date, locale);
    }
  }

  // ============ Number Formatting ============

  /// Formats a number using the given locale.
  ///
  /// Example: 1234 -> "1,234" (EN) or "1.234" (DE)
  static String formatNumber(num number, String locale) {
    final formatter = NumberFormat.decimalPattern(locale);
    return formatter.format(number);
  }

  /// Formats a compact number using the given locale.
  ///
  /// Example: 1234 -> "1.2K"
  static String formatCompactNumber(num number, String locale) {
    final formatter = NumberFormat.compact(locale: locale);
    return formatter.format(number);
  }
}
