import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/domain/repositories/settings_repository.dart';

/// Implementation of [SettingsRepository] backed by Hive local storage.
class SettingsRepositoryImpl implements SettingsRepository {
  @override
  String getThemeMode() => HiveBoxes.getThemeMode();

  @override
  Future<void> setThemeMode(String mode) => HiveBoxes.setThemeMode(mode);

  @override
  bool getNotificationsEnabled() => HiveBoxes.getNotificationsEnabled();

  @override
  Future<void> setNotificationsEnabled(bool enabled) =>
      HiveBoxes.setNotificationsEnabled(enabled);

  @override
  bool getFeedingRemindersEnabled() => HiveBoxes.getFeedingRemindersEnabled();

  @override
  Future<void> setFeedingRemindersEnabled(bool enabled) =>
      HiveBoxes.setFeedingRemindersEnabled(enabled);

  @override
  bool getStreakAlertsEnabled() => HiveBoxes.getStreakAlertsEnabled();

  @override
  Future<void> setStreakAlertsEnabled(bool enabled) =>
      HiveBoxes.setStreakAlertsEnabled(enabled);

  @override
  bool getWeeklySummaryEnabled() => HiveBoxes.getWeeklySummaryEnabled();

  @override
  Future<void> setWeeklySummaryEnabled(bool enabled) =>
      HiveBoxes.setWeeklySummaryEnabled(enabled);

  @override
  int? getQuietHoursStart() => HiveBoxes.getQuietHoursStart();

  @override
  Future<void> setQuietHoursStart(int? minutes) =>
      HiveBoxes.setQuietHoursStart(minutes);

  @override
  int? getQuietHoursEnd() => HiveBoxes.getQuietHoursEnd();

  @override
  Future<void> setQuietHoursEnd(int? minutes) =>
      HiveBoxes.setQuietHoursEnd(minutes);

  @override
  String getLanguage() => HiveBoxes.getLanguage();

  @override
  Future<void> setLanguage(String languageCode) =>
      HiveBoxes.setLanguage(languageCode);
}

/// Provider for [SettingsRepository].
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});
