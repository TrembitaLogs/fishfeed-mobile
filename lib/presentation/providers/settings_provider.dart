import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';

/// Theme mode options for the app.
enum AppThemeMode {
  system,
  light,
  dark;

  /// Converts to Flutter's ThemeMode.
  ThemeMode toThemeMode() {
    return switch (this) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
  }

  /// Creates from a string value.
  static AppThemeMode fromString(String value) {
    return switch (value) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }

  /// Display label for the theme mode.
  String get label {
    return switch (this) {
      AppThemeMode.system => 'System',
      AppThemeMode.light => 'Light',
      AppThemeMode.dark => 'Dark',
    };
  }
}

/// State for user settings.
///
/// Contains all user-configurable preferences that are persisted locally.
class SettingsState {
  const SettingsState({
    this.themeMode = AppThemeMode.system,
    this.notificationsEnabled = true,
    this.feedingRemindersEnabled = true,
    this.streakAlertsEnabled = true,
    this.weeklySummaryEnabled = true,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.language = 'en',
    this.isLoading = false,
    this.isSaving = false,
  });

  /// Initial settings state with default values.
  const SettingsState.initial()
      : themeMode = AppThemeMode.system,
        notificationsEnabled = true,
        feedingRemindersEnabled = true,
        streakAlertsEnabled = true,
        weeklySummaryEnabled = true,
        quietHoursStart = null,
        quietHoursEnd = null,
        language = 'en',
        isLoading = false,
        isSaving = false;

  /// The current theme mode.
  final AppThemeMode themeMode;

  /// Master toggle for all notifications.
  final bool notificationsEnabled;

  /// Whether feeding reminder notifications are enabled.
  final bool feedingRemindersEnabled;

  /// Whether streak alert notifications are enabled.
  final bool streakAlertsEnabled;

  /// Whether weekly summary notifications are enabled.
  final bool weeklySummaryEnabled;

  /// Quiet hours start time as minutes from midnight.
  /// Null means quiet hours are disabled.
  final int? quietHoursStart;

  /// Quiet hours end time as minutes from midnight.
  /// Null means quiet hours are disabled.
  final int? quietHoursEnd;

  /// Preferred language code (e.g., 'en', 'de').
  final String language;

  /// Whether settings are being loaded.
  final bool isLoading;

  /// Whether settings are being saved.
  final bool isSaving;

  /// Whether quiet hours are enabled.
  bool get quietHoursEnabled => quietHoursStart != null && quietHoursEnd != null;

  /// Formats quiet hours start time as HH:MM.
  String? get quietHoursStartFormatted => _formatMinutes(quietHoursStart);

  /// Formats quiet hours end time as HH:MM.
  String? get quietHoursEndFormatted => _formatMinutes(quietHoursEnd);

  String? _formatMinutes(int? minutes) {
    if (minutes == null) return null;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  /// Creates a copy with updated fields.
  SettingsState copyWith({
    AppThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? feedingRemindersEnabled,
    bool? streakAlertsEnabled,
    bool? weeklySummaryEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
    String? language,
    bool? isLoading,
    bool? isSaving,
    bool clearQuietHours = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      feedingRemindersEnabled: feedingRemindersEnabled ?? this.feedingRemindersEnabled,
      streakAlertsEnabled: streakAlertsEnabled ?? this.streakAlertsEnabled,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      quietHoursStart: clearQuietHours ? null : (quietHoursStart ?? this.quietHoursStart),
      quietHoursEnd: clearQuietHours ? null : (quietHoursEnd ?? this.quietHoursEnd),
      language: language ?? this.language,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingsState &&
        other.themeMode == themeMode &&
        other.notificationsEnabled == notificationsEnabled &&
        other.feedingRemindersEnabled == feedingRemindersEnabled &&
        other.streakAlertsEnabled == streakAlertsEnabled &&
        other.weeklySummaryEnabled == weeklySummaryEnabled &&
        other.quietHoursStart == quietHoursStart &&
        other.quietHoursEnd == quietHoursEnd &&
        other.language == language &&
        other.isLoading == isLoading &&
        other.isSaving == isSaving;
  }

  @override
  int get hashCode => Object.hash(
        themeMode,
        notificationsEnabled,
        feedingRemindersEnabled,
        streakAlertsEnabled,
        weeklySummaryEnabled,
        quietHoursStart,
        quietHoursEnd,
        language,
        isLoading,
        isSaving,
      );
}

/// Notifier for managing user settings state.
///
/// Provides methods for loading, updating, and persisting user settings.
/// All settings are persisted to local storage via Hive.
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState.initial()) {
    _loadSettings();
  }

  /// Loads settings from local storage.
  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);

    try {
      final themeMode = AppThemeMode.fromString(HiveBoxes.getThemeMode());
      final notificationsEnabled = HiveBoxes.getNotificationsEnabled();
      final feedingRemindersEnabled = HiveBoxes.getFeedingRemindersEnabled();
      final streakAlertsEnabled = HiveBoxes.getStreakAlertsEnabled();
      final weeklySummaryEnabled = HiveBoxes.getWeeklySummaryEnabled();
      final quietHoursStart = HiveBoxes.getQuietHoursStart();
      final quietHoursEnd = HiveBoxes.getQuietHoursEnd();
      final language = HiveBoxes.getLanguage();

      state = SettingsState(
        themeMode: themeMode,
        notificationsEnabled: notificationsEnabled,
        feedingRemindersEnabled: feedingRemindersEnabled,
        streakAlertsEnabled: streakAlertsEnabled,
        weeklySummaryEnabled: weeklySummaryEnabled,
        quietHoursStart: quietHoursStart,
        quietHoursEnd: quietHoursEnd,
        language: language,
        isLoading: false,
        isSaving: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Updates the theme mode.
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (state.themeMode == mode) return;

    state = state.copyWith(themeMode: mode, isSaving: true);
    await HiveBoxes.setThemeMode(mode.name);
    state = state.copyWith(isSaving: false);
  }

  /// Updates the master notifications toggle.
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (state.notificationsEnabled == enabled) return;

    state = state.copyWith(notificationsEnabled: enabled, isSaving: true);
    await HiveBoxes.setNotificationsEnabled(enabled);
    state = state.copyWith(isSaving: false);
  }

  /// Updates the feeding reminders toggle.
  Future<void> setFeedingRemindersEnabled(bool enabled) async {
    if (state.feedingRemindersEnabled == enabled) return;

    state = state.copyWith(feedingRemindersEnabled: enabled, isSaving: true);
    await HiveBoxes.setFeedingRemindersEnabled(enabled);
    state = state.copyWith(isSaving: false);
  }

  /// Updates the streak alerts toggle.
  Future<void> setStreakAlertsEnabled(bool enabled) async {
    if (state.streakAlertsEnabled == enabled) return;

    state = state.copyWith(streakAlertsEnabled: enabled, isSaving: true);
    await HiveBoxes.setStreakAlertsEnabled(enabled);
    state = state.copyWith(isSaving: false);
  }

  /// Updates the weekly summary toggle.
  Future<void> setWeeklySummaryEnabled(bool enabled) async {
    if (state.weeklySummaryEnabled == enabled) return;

    state = state.copyWith(weeklySummaryEnabled: enabled, isSaving: true);
    await HiveBoxes.setWeeklySummaryEnabled(enabled);
    state = state.copyWith(isSaving: false);
  }

  /// Updates the quiet hours.
  ///
  /// Pass null for both to disable quiet hours.
  Future<void> setQuietHours({int? startMinutes, int? endMinutes}) async {
    if (state.quietHoursStart == startMinutes && state.quietHoursEnd == endMinutes) {
      return;
    }

    state = state.copyWith(
      quietHoursStart: startMinutes,
      quietHoursEnd: endMinutes,
      isSaving: true,
      clearQuietHours: startMinutes == null && endMinutes == null,
    );

    await Future.wait([
      HiveBoxes.setQuietHoursStart(startMinutes),
      HiveBoxes.setQuietHoursEnd(endMinutes),
    ]);

    state = state.copyWith(isSaving: false);
  }

  /// Disables quiet hours.
  Future<void> disableQuietHours() async {
    await setQuietHours(startMinutes: null, endMinutes: null);
  }

  /// Updates the preferred language.
  Future<void> setLanguage(String languageCode) async {
    if (state.language == languageCode) return;

    state = state.copyWith(language: languageCode, isSaving: true);
    await HiveBoxes.setLanguage(languageCode);
    state = state.copyWith(isSaving: false);
  }

  /// Reloads settings from storage.
  Future<void> reload() async {
    await _loadSettings();
  }
}

/// Provider for [SettingsNotifier].
final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

/// Provider for the current theme mode.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsNotifierProvider).themeMode.toThemeMode();
});

/// Provider for the current app theme mode enum.
final appThemeModeProvider = Provider<AppThemeMode>((ref) {
  return ref.watch(settingsNotifierProvider).themeMode;
});

/// Provider for whether notifications are enabled.
final notificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsNotifierProvider).notificationsEnabled;
});

/// Provider for the current language.
final languageProvider = Provider<String>((ref) {
  return ref.watch(settingsNotifierProvider).language;
});

/// Provider for settings loading state.
final settingsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(settingsNotifierProvider).isLoading;
});

/// Provider for settings saving state.
final settingsSavingProvider = Provider<bool>((ref) {
  return ref.watch(settingsNotifierProvider).isSaving;
});
