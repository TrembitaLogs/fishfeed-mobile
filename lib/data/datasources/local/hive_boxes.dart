import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/models/achievement_model.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/feeding_event_model.dart';
import 'package:fishfeed/data/models/feeding_schedule_model.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/data/models/species_model.dart';
import 'package:fishfeed/data/models/streak_model.dart';
import 'package:fishfeed/data/models/subscription_status_adapter.dart';
import 'package:fishfeed/data/models/sync_metadata_model.dart';
import 'package:fishfeed/data/models/user_progress_model.dart';
import 'package:fishfeed/data/models/sync_operation_model.dart';
import 'package:fishfeed/data/models/user_model.dart';
import 'package:fishfeed/data/models/user_settings_model.dart';
import 'package:fishfeed/data/models/water_type_adapter.dart';

/// Hive box names used throughout the application.
///
/// These constants ensure consistent box naming across all local data operations.
abstract final class HiveBoxNames {
  static const String users = 'users';
  static const String aquariums = 'aquariums';
  static const String fish = 'fish';
  static const String feedingEvents = 'feedingEvents';
  static const String species = 'species';
  static const String streaks = 'streaks';
  static const String achievements = 'achievements';
  static const String syncQueue = 'syncQueue';
  static const String appPreferences = 'appPreferences';
  static const String userProgress = 'userProgress';
  static const String subscriptionCache = 'subscriptionCache';
  static const String syncMetadata = 'syncMetadata';
  static const String feedingSchedules = 'feedingSchedules';
}

/// Keys for app preferences stored in the appPreferences box.
abstract final class AppPreferenceKeys {
  static const String onboardingCompleted = 'onboardingCompleted';
  static const String pushToken = 'pushToken';
  static const String pushTokenPlatform = 'pushTokenPlatform';

  // User settings keys
  static const String userSettings = 'userSettings';
  static const String themeMode = 'themeMode';
  static const String notificationsEnabled = 'notificationsEnabled';
  static const String feedingRemindersEnabled = 'feedingRemindersEnabled';
  static const String streakAlertsEnabled = 'streakAlertsEnabled';
  static const String weeklySummaryEnabled = 'weeklySummaryEnabled';
  static const String quietHoursStart = 'quietHoursStart';
  static const String quietHoursEnd = 'quietHoursEnd';
  static const String language = 'language';
}

/// Keys for subscription cache box.
abstract final class SubscriptionCacheKeys {
  static const String cachedStatus = 'cachedStatus';
}

/// Manages Hive database initialization and box access.
///
/// Provides centralized access to all Hive boxes used in the application.
/// Must call [init] before accessing any boxes.
///
/// Example:
/// ```dart
/// await HiveBoxes.init();
/// final usersBox = HiveBoxes.users;
/// ```
class HiveBoxes {
  HiveBoxes._();

  static bool _isInitialized = false;

  /// Whether Hive has been initialized.
  static bool get isInitialized => _isInitialized;

  // Box instances (lazy initialized after init)
  static late Box<dynamic> _usersBox;
  static late Box<dynamic> _aquariumsBox;
  static late Box<dynamic> _fishBox;
  static late Box<dynamic> _feedingEventsBox;
  static late Box<dynamic> _speciesBox;
  static late Box<dynamic> _streaksBox;
  static late Box<dynamic> _achievementsBox;
  static late Box<dynamic> _syncQueueBox;
  static late Box<dynamic> _appPreferencesBox;
  static late Box<dynamic> _userProgressBox;
  static late Box<dynamic> _subscriptionCacheBox;
  static late Box<dynamic> _syncMetadataBox;
  static late Box<dynamic> _feedingSchedulesBox;

  /// Users box for storing user data.
  static Box<dynamic> get users {
    _ensureInitialized();
    return _usersBox;
  }

  /// Aquariums box for storing aquarium data.
  static Box<dynamic> get aquariums {
    _ensureInitialized();
    return _aquariumsBox;
  }

  /// Fish box for storing fish data.
  static Box<dynamic> get fish {
    _ensureInitialized();
    return _fishBox;
  }

  /// Feeding events box for storing feeding records.
  static Box<dynamic> get feedingEvents {
    _ensureInitialized();
    return _feedingEventsBox;
  }

  /// Species box for storing fish species reference data.
  static Box<dynamic> get species {
    _ensureInitialized();
    return _speciesBox;
  }

  /// Streaks box for storing feeding streak data.
  static Box<dynamic> get streaks {
    _ensureInitialized();
    return _streaksBox;
  }

  /// Achievements box for storing user achievements.
  static Box<dynamic> get achievements {
    _ensureInitialized();
    return _achievementsBox;
  }

  /// Sync queue box for storing offline operations pending synchronization.
  static Box<dynamic> get syncQueue {
    _ensureInitialized();
    return _syncQueueBox;
  }

  /// App preferences box for storing app-level settings.
  static Box<dynamic> get appPreferences {
    _ensureInitialized();
    return _appPreferencesBox;
  }

  /// User progress box for storing XP and level data.
  static Box<dynamic> get userProgress {
    _ensureInitialized();
    return _userProgressBox;
  }

  /// Subscription cache box for storing cached subscription status.
  static Box<dynamic> get subscriptionCache {
    _ensureInitialized();
    return _subscriptionCacheBox;
  }

  /// Sync metadata box for storing sync state information.
  static Box<dynamic> get syncMetadata {
    _ensureInitialized();
    return _syncMetadataBox;
  }

  /// Feeding schedules box for storing feeding schedule data.
  static Box<dynamic> get feedingSchedules {
    _ensureInitialized();
    return _feedingSchedulesBox;
  }

  /// Initializes Hive and opens all required boxes.
  ///
  /// Must be called once before accessing any boxes, typically in main.dart.
  /// Registers all TypeAdapters and opens all application boxes.
  ///
  /// Throws [StateError] if called more than once.
  static Future<void> init() async {
    if (_isInitialized) {
      throw StateError('HiveBoxes.init() has already been called');
    }

    // Initialize Hive for Flutter
    await Hive.initFlutter();

    // Register TypeAdapters (will be added in subsequent tasks)
    _registerAdapters();

    // Open all boxes
    await _openBoxes();

    _isInitialized = true;
  }

  /// Initializes HiveBoxes for testing without calling Hive.initFlutter().
  ///
  /// Use this method in tests after manually initializing Hive with a temp directory.
  /// This method only opens boxes and sets the initialized flag.
  @visibleForTesting
  static Future<void> initForTesting() async {
    if (_isInitialized) {
      throw StateError('HiveBoxes has already been initialized');
    }

    _registerAdapters();
    await _openBoxes();
    _isInitialized = true;
  }

  /// Registers all Hive TypeAdapters.
  ///
  /// TypeAdapters are registered in a specific order to ensure
  /// dependencies between models are properly handled.
  /// Enum adapters are registered first, then nested models,
  /// then main models.
  static void _registerAdapters() {
    // Register enum adapters first (typeId: 11-12)
    if (!Hive.isAdapterRegistered(WaterTypeAdapter().typeId)) {
      Hive.registerAdapter(WaterTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(SubscriptionTierAdapter().typeId)) {
      Hive.registerAdapter(SubscriptionTierAdapter());
    }

    // Register subscription adapters (typeId: 13-14)
    // SubscriptionStatusAdapter must be registered after SubscriptionTierAdapter
    if (!Hive.isAdapterRegistered(SubscriptionStatusAdapter().typeId)) {
      Hive.registerAdapter(SubscriptionStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(
      CachedSubscriptionStatusModelAdapter().typeId,
    )) {
      Hive.registerAdapter(CachedSubscriptionStatusModelAdapter());
    }

    // Register nested model adapters (typeId: 3)
    if (!Hive.isAdapterRegistered(UserSettingsModelAdapter().typeId)) {
      Hive.registerAdapter(UserSettingsModelAdapter());
    }

    // Register main model adapters (typeId: 0-2)
    if (!Hive.isAdapterRegistered(UserModelAdapter().typeId)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AquariumModelAdapter().typeId)) {
      Hive.registerAdapter(AquariumModelAdapter());
    }
    if (!Hive.isAdapterRegistered(FishModelAdapter().typeId)) {
      Hive.registerAdapter(FishModelAdapter());
    }

    // Register additional model adapters (typeId: 4-7)
    if (!Hive.isAdapterRegistered(FeedingEventModelAdapter().typeId)) {
      Hive.registerAdapter(FeedingEventModelAdapter());
    }
    if (!Hive.isAdapterRegistered(StreakModelAdapter().typeId)) {
      Hive.registerAdapter(StreakModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AchievementModelAdapter().typeId)) {
      Hive.registerAdapter(AchievementModelAdapter());
    }
    if (!Hive.isAdapterRegistered(SpeciesModelAdapter().typeId)) {
      Hive.registerAdapter(SpeciesModelAdapter());
    }

    // Register sync queue adapters (typeId: 8, 20-21)
    if (!Hive.isAdapterRegistered(SyncOperationTypeAdapter().typeId)) {
      Hive.registerAdapter(SyncOperationTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(SyncOperationStatusAdapter().typeId)) {
      Hive.registerAdapter(SyncOperationStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(SyncOperationModelAdapter().typeId)) {
      Hive.registerAdapter(SyncOperationModelAdapter());
    }

    // Register user progress adapter (typeId: 10)
    if (!Hive.isAdapterRegistered(UserProgressModelAdapter().typeId)) {
      Hive.registerAdapter(UserProgressModelAdapter());
    }

    // Register sync metadata adapter (typeId: 22)
    if (!Hive.isAdapterRegistered(SyncMetadataModelAdapter().typeId)) {
      Hive.registerAdapter(SyncMetadataModelAdapter());
    }

    // Register feeding schedule adapter (typeId: 23)
    if (!Hive.isAdapterRegistered(FeedingScheduleModelAdapter().typeId)) {
      Hive.registerAdapter(FeedingScheduleModelAdapter());
    }
  }

  /// Opens all Hive boxes.
  static Future<void> _openBoxes() async {
    _usersBox = await Hive.openBox(HiveBoxNames.users);
    _aquariumsBox = await Hive.openBox(HiveBoxNames.aquariums);
    _fishBox = await Hive.openBox(HiveBoxNames.fish);
    _feedingEventsBox = await Hive.openBox(HiveBoxNames.feedingEvents);
    _speciesBox = await Hive.openBox(HiveBoxNames.species);
    _streaksBox = await Hive.openBox(HiveBoxNames.streaks);
    _achievementsBox = await Hive.openBox(HiveBoxNames.achievements);
    _syncQueueBox = await Hive.openBox(HiveBoxNames.syncQueue);
    _appPreferencesBox = await Hive.openBox(HiveBoxNames.appPreferences);
    _userProgressBox = await Hive.openBox(HiveBoxNames.userProgress);
    _subscriptionCacheBox = await Hive.openBox(HiveBoxNames.subscriptionCache);
    _syncMetadataBox = await Hive.openBox(HiveBoxNames.syncMetadata);
    _feedingSchedulesBox = await Hive.openBox(HiveBoxNames.feedingSchedules);
  }

  /// Ensures Hive has been initialized before accessing boxes.
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'HiveBoxes has not been initialized. Call HiveBoxes.init() first.',
      );
    }
  }

  /// Closes all open boxes and resets initialization state.
  ///
  /// Useful for testing or when the app needs to fully reset local storage.
  static Future<void> close() async {
    if (!_isInitialized) return;

    await Hive.close();
    _isInitialized = false;
  }

  /// Clears all data from all boxes.
  ///
  /// Use with caution - this permanently deletes all local data.
  static Future<void> clearAll() async {
    _ensureInitialized();

    await Future.wait([
      _usersBox.clear(),
      _aquariumsBox.clear(),
      _fishBox.clear(),
      _feedingEventsBox.clear(),
      _speciesBox.clear(),
      _streaksBox.clear(),
      _achievementsBox.clear(),
      _syncQueueBox.clear(),
      _appPreferencesBox.clear(),
      _userProgressBox.clear(),
      _subscriptionCacheBox.clear(),
      _syncMetadataBox.clear(),
      _feedingSchedulesBox.clear(),
    ]);
  }

  /// Clears user-specific data on logout.
  ///
  /// Clears fish, feeding events, aquariums, streaks, achievements,
  /// sync queue, user progress, and resets onboarding status.
  /// Preserves app settings (theme, language, notifications) and species cache.
  static Future<void> clearUserData() async {
    _ensureInitialized();

    await Future.wait([
      _usersBox.clear(),
      _aquariumsBox.clear(),
      _fishBox.clear(),
      _feedingEventsBox.clear(),
      _streaksBox.clear(),
      _achievementsBox.clear(),
      _syncQueueBox.clear(),
      _userProgressBox.clear(),
      _subscriptionCacheBox.clear(),
      _syncMetadataBox.clear(),
      _feedingSchedulesBox.clear(),
    ]);

    // Reset onboarding so user goes through it again
    await setOnboardingCompleted(false);
  }

  /// Gets the onboarding completion status from app preferences.
  static bool getOnboardingCompleted() {
    _ensureInitialized();
    return _appPreferencesBox.get(
          AppPreferenceKeys.onboardingCompleted,
          defaultValue: false,
        )
        as bool;
  }

  /// Sets the onboarding completion status in app preferences.
  static Future<void> setOnboardingCompleted(bool completed) async {
    _ensureInitialized();
    await _appPreferencesBox.put(
      AppPreferenceKeys.onboardingCompleted,
      completed,
    );
  }

  /// Gets the stored push token from app preferences.
  ///
  /// Returns null if no token is stored.
  static String? getPushToken() {
    _ensureInitialized();
    return _appPreferencesBox.get(AppPreferenceKeys.pushToken) as String?;
  }

  /// Gets the stored push token platform from app preferences.
  ///
  /// Returns null if no platform is stored.
  static String? getPushTokenPlatform() {
    _ensureInitialized();
    return _appPreferencesBox.get(AppPreferenceKeys.pushTokenPlatform)
        as String?;
  }

  /// Saves the push token and platform to app preferences.
  static Future<void> setPushToken(String token, String platform) async {
    _ensureInitialized();
    await Future.wait([
      _appPreferencesBox.put(AppPreferenceKeys.pushToken, token),
      _appPreferencesBox.put(AppPreferenceKeys.pushTokenPlatform, platform),
    ]);
  }

  /// Clears the stored push token from app preferences.
  static Future<void> clearPushToken() async {
    _ensureInitialized();
    await Future.wait([
      _appPreferencesBox.delete(AppPreferenceKeys.pushToken),
      _appPreferencesBox.delete(AppPreferenceKeys.pushTokenPlatform),
    ]);
  }

  /// Gets the cached subscription status.
  ///
  /// Returns null if no cached status exists.
  static CachedSubscriptionStatusModel? getCachedSubscriptionStatus() {
    _ensureInitialized();
    return _subscriptionCacheBox.get(SubscriptionCacheKeys.cachedStatus)
        as CachedSubscriptionStatusModel?;
  }

  /// Saves the subscription status to cache.
  ///
  /// [status] - The subscription status to cache.
  /// [ttlMinutes] - Time-to-live in minutes (default: 60).
  static Future<void> setCachedSubscriptionStatus(
    SubscriptionStatus status, {
    int ttlMinutes = 60,
  }) async {
    _ensureInitialized();
    final cached = CachedSubscriptionStatusModel(
      status: status,
      cachedAt: DateTime.now(),
      ttlMinutes: ttlMinutes,
    );
    await _subscriptionCacheBox.put(SubscriptionCacheKeys.cachedStatus, cached);
  }

  /// Clears the cached subscription status.
  static Future<void> clearCachedSubscriptionStatus() async {
    _ensureInitialized();
    await _subscriptionCacheBox.delete(SubscriptionCacheKeys.cachedStatus);
  }

  // ============================================================
  // User Settings Methods
  // ============================================================

  /// Gets the theme mode setting.
  ///
  /// Returns: 'system', 'light', or 'dark'. Defaults to 'system'.
  static String getThemeMode() {
    _ensureInitialized();
    return _appPreferencesBox.get(
          AppPreferenceKeys.themeMode,
          defaultValue: 'system',
        )
        as String;
  }

  /// Sets the theme mode setting.
  static Future<void> setThemeMode(String mode) async {
    _ensureInitialized();
    await _appPreferencesBox.put(AppPreferenceKeys.themeMode, mode);
  }

  /// Gets whether notifications are enabled.
  static bool getNotificationsEnabled() {
    _ensureInitialized();
    return _appPreferencesBox.get(
          AppPreferenceKeys.notificationsEnabled,
          defaultValue: true,
        )
        as bool;
  }

  /// Sets whether notifications are enabled.
  static Future<void> setNotificationsEnabled(bool enabled) async {
    _ensureInitialized();
    await _appPreferencesBox.put(
      AppPreferenceKeys.notificationsEnabled,
      enabled,
    );
  }

  /// Gets whether feeding reminders are enabled.
  static bool getFeedingRemindersEnabled() {
    _ensureInitialized();
    return _appPreferencesBox.get(
          AppPreferenceKeys.feedingRemindersEnabled,
          defaultValue: true,
        )
        as bool;
  }

  /// Sets whether feeding reminders are enabled.
  static Future<void> setFeedingRemindersEnabled(bool enabled) async {
    _ensureInitialized();
    await _appPreferencesBox.put(
      AppPreferenceKeys.feedingRemindersEnabled,
      enabled,
    );
  }

  /// Gets whether streak alerts are enabled.
  static bool getStreakAlertsEnabled() {
    _ensureInitialized();
    return _appPreferencesBox.get(
          AppPreferenceKeys.streakAlertsEnabled,
          defaultValue: true,
        )
        as bool;
  }

  /// Sets whether streak alerts are enabled.
  static Future<void> setStreakAlertsEnabled(bool enabled) async {
    _ensureInitialized();
    await _appPreferencesBox.put(
      AppPreferenceKeys.streakAlertsEnabled,
      enabled,
    );
  }

  /// Gets whether weekly summary is enabled.
  static bool getWeeklySummaryEnabled() {
    _ensureInitialized();
    return _appPreferencesBox.get(
          AppPreferenceKeys.weeklySummaryEnabled,
          defaultValue: true,
        )
        as bool;
  }

  /// Sets whether weekly summary is enabled.
  static Future<void> setWeeklySummaryEnabled(bool enabled) async {
    _ensureInitialized();
    await _appPreferencesBox.put(
      AppPreferenceKeys.weeklySummaryEnabled,
      enabled,
    );
  }

  /// Gets the quiet hours start time as minutes from midnight.
  ///
  /// Returns null if not set.
  static int? getQuietHoursStart() {
    _ensureInitialized();
    return _appPreferencesBox.get(AppPreferenceKeys.quietHoursStart) as int?;
  }

  /// Sets the quiet hours start time as minutes from midnight.
  static Future<void> setQuietHoursStart(int? minutes) async {
    _ensureInitialized();
    if (minutes == null) {
      await _appPreferencesBox.delete(AppPreferenceKeys.quietHoursStart);
    } else {
      await _appPreferencesBox.put(AppPreferenceKeys.quietHoursStart, minutes);
    }
  }

  /// Gets the quiet hours end time as minutes from midnight.
  ///
  /// Returns null if not set.
  static int? getQuietHoursEnd() {
    _ensureInitialized();
    return _appPreferencesBox.get(AppPreferenceKeys.quietHoursEnd) as int?;
  }

  /// Sets the quiet hours end time as minutes from midnight.
  static Future<void> setQuietHoursEnd(int? minutes) async {
    _ensureInitialized();
    if (minutes == null) {
      await _appPreferencesBox.delete(AppPreferenceKeys.quietHoursEnd);
    } else {
      await _appPreferencesBox.put(AppPreferenceKeys.quietHoursEnd, minutes);
    }
  }

  /// Gets the preferred language code.
  ///
  /// Returns 'en' by default.
  static String getLanguage() {
    _ensureInitialized();
    return _appPreferencesBox.get(
          AppPreferenceKeys.language,
          defaultValue: 'en',
        )
        as String;
  }

  /// Sets the preferred language code.
  static Future<void> setLanguage(String languageCode) async {
    _ensureInitialized();
    await _appPreferencesBox.put(AppPreferenceKeys.language, languageCode);
  }
}
