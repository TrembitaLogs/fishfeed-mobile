/// Repository interface for user settings operations.
///
/// Provides a clean API for managing user preferences following Clean Architecture.
/// All settings are persisted locally.
abstract interface class SettingsRepository {
  /// Gets the current theme mode string.
  String getThemeMode();

  /// Sets the theme mode.
  Future<void> setThemeMode(String mode);

  /// Gets whether notifications are enabled.
  bool getNotificationsEnabled();

  /// Sets whether notifications are enabled.
  Future<void> setNotificationsEnabled(bool enabled);

  /// Gets whether feeding reminders are enabled.
  bool getFeedingRemindersEnabled();

  /// Sets whether feeding reminders are enabled.
  Future<void> setFeedingRemindersEnabled(bool enabled);

  /// Gets whether streak alerts are enabled.
  bool getStreakAlertsEnabled();

  /// Sets whether streak alerts are enabled.
  Future<void> setStreakAlertsEnabled(bool enabled);

  /// Gets whether weekly summary is enabled.
  bool getWeeklySummaryEnabled();

  /// Sets whether weekly summary is enabled.
  Future<void> setWeeklySummaryEnabled(bool enabled);

  /// Gets quiet hours start time as minutes from midnight.
  int? getQuietHoursStart();

  /// Sets quiet hours start time.
  Future<void> setQuietHoursStart(int? minutes);

  /// Gets quiet hours end time as minutes from midnight.
  int? getQuietHoursEnd();

  /// Sets quiet hours end time.
  Future<void> setQuietHoursEnd(int? minutes);

  /// Gets the preferred language code.
  String getLanguage();

  /// Sets the preferred language code.
  Future<void> setLanguage(String languageCode);
}
