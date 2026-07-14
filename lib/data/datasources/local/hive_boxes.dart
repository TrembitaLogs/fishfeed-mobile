import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:fishfeed/data/models/achievement_model.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
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
  static const String species = 'species';
  static const String streaks = 'streaks';
  static const String achievements = 'achievements';
  static const String syncQueue = 'syncQueue';
  static const String appPreferences = 'appPreferences';
  static const String userProgress = 'userProgress';
  static const String subscriptionCache = 'subscriptionCache';
  static const String syncMetadata = 'syncMetadata';
  static const String schedules = 'schedules';
  static const String feedingLogs = 'feedingLogs';
}

/// Keys for app preferences stored in the appPreferences box.
abstract final class AppPreferenceKeys {
  static const String onboardingCompleted = 'onboardingCompleted';
  static const String pushToken = 'pushToken';
  static const String pushTokenPlatform = 'pushTokenPlatform';
  static const String deviceId = 'deviceId';

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
  static HiveAesCipher? _cipher;

  /// Secure-storage key under which the Hive AES encryption key is persisted.
  static const String _encryptionKeyName = 'hive_encryption_key';

  /// Secure storage used for the Hive AES encryption key.
  ///
  /// iOS uses `first_unlock` accessibility (matching the auth-token store in
  /// [AuthLocalDataSource]) so the notification-refill background isolate can
  /// read the key while the device is locked — otherwise it would open the AES
  /// boxes without the cipher and corrupt them. Android keeps the plugin default
  /// so the existing key is not orphaned into a different store. Reads ignore
  /// accessibility (the plugin queries by key only), so this never fails to find
  /// a key written under the old default accessibility.
  static const FlutterSecureStorage _keyStorage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Whether Hive has been initialized.
  static bool get isInitialized => _isInitialized;

  // Box instances (lazy initialized after init)
  static late Box<UserModel> _usersBox;
  static late Box<AquariumModel> _aquariumsBox;
  static late Box<FishModel> _fishBox;
  static late Box<SpeciesModel> _speciesBox;
  static late Box<StreakModel> _streaksBox;
  static late Box<AchievementModel> _achievementsBox;
  static late Box<SyncOperationModel> _syncQueueBox;
  static late Box<dynamic> _appPreferencesBox;
  static late Box<UserProgressModel> _userProgressBox;
  static late Box<dynamic> _subscriptionCacheBox;
  static late Box<SyncMetadataModel> _syncMetadataBox;
  static late Box<ScheduleModel> _schedulesBox;
  static late Box<FeedingLogModel> _feedingLogsBox;

  /// Users box for storing user data.
  static Box<UserModel> get users {
    _ensureInitialized();
    return _usersBox;
  }

  /// Aquariums box for storing aquarium data.
  static Box<AquariumModel> get aquariums {
    _ensureInitialized();
    return _aquariumsBox;
  }

  /// Fish box for storing fish data.
  static Box<FishModel> get fish {
    _ensureInitialized();
    return _fishBox;
  }

  /// Species box for storing fish species reference data.
  static Box<SpeciesModel> get species {
    _ensureInitialized();
    return _speciesBox;
  }

  /// Streaks box for storing feeding streak data.
  static Box<StreakModel> get streaks {
    _ensureInitialized();
    return _streaksBox;
  }

  /// Achievements box for storing user achievements.
  static Box<AchievementModel> get achievements {
    _ensureInitialized();
    return _achievementsBox;
  }

  /// Sync queue box for storing offline operations pending synchronization.
  static Box<SyncOperationModel> get syncQueue {
    _ensureInitialized();
    return _syncQueueBox;
  }

  /// App preferences box for storing app-level settings.
  static Box<dynamic> get appPreferences {
    _ensureInitialized();
    return _appPreferencesBox;
  }

  /// User progress box for storing XP and level data.
  static Box<UserProgressModel> get userProgress {
    _ensureInitialized();
    return _userProgressBox;
  }

  /// Subscription cache box for storing cached subscription status.
  static Box<dynamic> get subscriptionCache {
    _ensureInitialized();
    return _subscriptionCacheBox;
  }

  /// Sync metadata box for storing sync state information.
  static Box<SyncMetadataModel> get syncMetadata {
    _ensureInitialized();
    return _syncMetadataBox;
  }

  /// Schedules box for storing new schedule model data (typeId: 24).
  static Box<ScheduleModel> get schedules {
    _ensureInitialized();
    return _schedulesBox;
  }

  /// Feeding logs box for storing feeding log entries (typeId: 25).
  static Box<FeedingLogModel> get feedingLogs {
    _ensureInitialized();
    return _feedingLogsBox;
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

    // Retrieve or generate the Hive encryption key from secure storage
    _cipher = HiveAesCipher(await _getOrCreateEncryptionKey());

    // Register TypeAdapters (will be added in subsequent tasks)
    _registerAdapters();

    // Open all boxes
    await _openBoxes();

    _isInitialized = true;
  }

  /// Reads the existing Hive AES encryption key from secure storage.
  ///
  /// Returns null if no key has been persisted yet, or if secure storage is
  /// currently inaccessible. NEVER generates or writes a key — callers that
  /// must not risk orphaning existing encrypted data (e.g. background isolates)
  /// use this instead of [_getOrCreateEncryptionKey].
  static Future<List<int>?> _readEncryptionKey() async {
    try {
      final encoded = await _keyStorage.read(key: _encryptionKeyName);
      if (encoded == null) {
        return null;
      }
      return base64Url.decode(encoded);
    } catch (_) {
      // Secure storage can throw (e.g. the iOS keychain is inaccessible while
      // the device is locked) rather than returning null. Treat that like a
      // missing key so callers hit the documented null path — a clean abort —
      // instead of an opaque platform error.
      return null;
    }
  }

  /// Retrieves the Hive AES encryption key from secure storage,
  /// generating a new one on first launch.
  static Future<List<int>> _getOrCreateEncryptionKey() async {
    final existing = await _readEncryptionKey();
    if (existing != null) {
      // Migrate keys persisted under the old plugin-default (whenUnlocked)
      // accessibility to first_unlock, so the background isolate can read the
      // key while the device is locked. Idempotent: once migrated, the write is
      // a cheap in-place update. Runs only in the main (foreground) isolate.
      await _keyStorage.write(
        key: _encryptionKeyName,
        value: base64UrlEncode(existing),
      );
      return existing;
    }

    final key = Hive.generateSecureKey();
    await _keyStorage.write(
      key: _encryptionKeyName,
      value: base64UrlEncode(key),
    );
    return key;
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

  /// Initializes HiveBoxes for a background isolate (e.g., Workmanager task).
  ///
  /// Registers only the adapters needed for notification orchestration
  /// (AquariumModel, FishModel, ScheduleModel) and opens the corresponding
  /// boxes. Called after [Hive.initFlutter] in the background isolate.
  ///
  /// No-op if already initialized (safe to call multiple times in same isolate).
  static Future<void> initForBackgroundIsolate() async {
    if (_isInitialized) return;

    // Register adapters required by the notification orchestrator.
    // Each check guards against duplicate registration across hot restarts.
    if (!Hive.isAdapterRegistered(WaterTypeAdapter().typeId)) {
      Hive.registerAdapter(WaterTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(AquariumModelAdapter().typeId)) {
      Hive.registerAdapter(AquariumModelAdapter());
    }
    if (!Hive.isAdapterRegistered(FishModelAdapter().typeId)) {
      Hive.registerAdapter(FishModelAdapter());
    }
    if (!Hive.isAdapterRegistered(ScheduleModelAdapter().typeId)) {
      Hive.registerAdapter(ScheduleModelAdapter());
    }

    // Retrieve the SAME AES key the main isolate persisted so these boxes are
    // opened WITH their cipher. Opening the AES-encrypted aquariums/fish/
    // schedules boxes without the cipher makes Hive's crash recovery truncate
    // them to empty, wiping the user's aquarium locally (identical to the
    // retired feeding-log background sync). NEVER generate a key here: if it is
    // unavailable (e.g. secure storage locked), aborting is safe — the caller
    // treats a thrown error as a failed refill — whereas a new key would orphan
    // all existing encrypted data.
    final key = await _readEncryptionKey();
    if (key == null) {
      throw StateError(
        'Hive encryption key unavailable in background isolate; aborting to '
        'avoid corrupting the encrypted boxes.',
      );
    }
    _cipher = HiveAesCipher(key);

    // Open only the boxes used by the orchestrator datasources, WITH the cipher.
    _aquariumsBox = await Hive.openBox<AquariumModel>(
      HiveBoxNames.aquariums,
      encryptionCipher: _cipher,
    );
    _fishBox = await Hive.openBox<FishModel>(
      HiveBoxNames.fish,
      encryptionCipher: _cipher,
    );
    _schedulesBox = await Hive.openBox<ScheduleModel>(
      HiveBoxNames.schedules,
      encryptionCipher: _cipher,
    );

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

    // Register additional model adapters (typeId: 5-7)
    if (!Hive.isAdapterRegistered(StreakModelAdapter().typeId)) {
      Hive.registerAdapter(StreakModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AchievementModelAdapter().typeId)) {
      Hive.registerAdapter(AchievementModelAdapter());
    }
    if (!Hive.isAdapterRegistered(SpeciesModelAdapter().typeId)) {
      Hive.registerAdapter(SpeciesModelAdapter());
    }
    if (!Hive.isAdapterRegistered(FoodTypeModelAdapter().typeId)) {
      Hive.registerAdapter(FoodTypeModelAdapter());
    }
    if (!Hive.isAdapterRegistered(PortionHintModelAdapter().typeId)) {
      Hive.registerAdapter(PortionHintModelAdapter());
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

    // Register schedule model adapter (typeId: 24)
    if (!Hive.isAdapterRegistered(ScheduleModelAdapter().typeId)) {
      Hive.registerAdapter(ScheduleModelAdapter());
    }

    // Register feeding log model adapter (typeId: 25)
    if (!Hive.isAdapterRegistered(FeedingLogModelAdapter().typeId)) {
      Hive.registerAdapter(FeedingLogModelAdapter());
    }
  }

  /// Opens all Hive boxes with AES encryption.
  static Future<void> _openBoxes() async {
    _usersBox = await Hive.openBox<UserModel>(
      HiveBoxNames.users,
      encryptionCipher: _cipher,
    );
    _aquariumsBox = await Hive.openBox<AquariumModel>(
      HiveBoxNames.aquariums,
      encryptionCipher: _cipher,
    );
    _fishBox = await Hive.openBox<FishModel>(
      HiveBoxNames.fish,
      encryptionCipher: _cipher,
    );
    _speciesBox = await Hive.openBox<SpeciesModel>(
      HiveBoxNames.species,
      encryptionCipher: _cipher,
    );
    _streaksBox = await Hive.openBox<StreakModel>(
      HiveBoxNames.streaks,
      encryptionCipher: _cipher,
    );
    _achievementsBox = await Hive.openBox<AchievementModel>(
      HiveBoxNames.achievements,
      encryptionCipher: _cipher,
    );
    _syncQueueBox = await Hive.openBox<SyncOperationModel>(
      HiveBoxNames.syncQueue,
      encryptionCipher: _cipher,
    );
    _appPreferencesBox = await Hive.openBox(
      HiveBoxNames.appPreferences,
      encryptionCipher: _cipher,
    );
    _userProgressBox = await Hive.openBox<UserProgressModel>(
      HiveBoxNames.userProgress,
      encryptionCipher: _cipher,
    );
    _subscriptionCacheBox = await Hive.openBox(
      HiveBoxNames.subscriptionCache,
      encryptionCipher: _cipher,
    );
    _syncMetadataBox = await Hive.openBox<SyncMetadataModel>(
      HiveBoxNames.syncMetadata,
      encryptionCipher: _cipher,
    );
    _schedulesBox = await Hive.openBox<ScheduleModel>(
      HiveBoxNames.schedules,
      encryptionCipher: _cipher,
    );
    _feedingLogsBox = await Hive.openBox<FeedingLogModel>(
      HiveBoxNames.feedingLogs,
      encryptionCipher: _cipher,
    );
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
      _speciesBox.clear(),
      _streaksBox.clear(),
      _achievementsBox.clear(),
      _syncQueueBox.clear(),
      _appPreferencesBox.clear(),
      _userProgressBox.clear(),
      _subscriptionCacheBox.clear(),
      _syncMetadataBox.clear(),
      _schedulesBox.clear(),
      _feedingLogsBox.clear(),
    ]);
  }

  /// Clears user-specific data on logout.
  ///
  /// Clears fish, aquariums, streaks, achievements, sync queue,
  /// user progress, schedules, feeding logs, and resets onboarding status.
  /// Preserves app settings (theme, language, notifications) and species cache.
  static Future<void> clearUserData() async {
    _ensureInitialized();

    await Future.wait([
      _usersBox.clear(),
      _aquariumsBox.clear(),
      _fishBox.clear(),
      _streaksBox.clear(),
      _achievementsBox.clear(),
      _syncQueueBox.clear(),
      _userProgressBox.clear(),
      _subscriptionCacheBox.clear(),
      _syncMetadataBox.clear(),
      _schedulesBox.clear(),
      _feedingLogsBox.clear(),
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

  /// Gets the device ID, generating one if it doesn't exist.
  ///
  /// The device ID is a stable UUID generated once per device installation.
  /// Used for conflict detection in family mode when multiple devices
  /// log the same feeding event.
  ///
  /// Returns the existing device ID or generates a new one.
  static Future<String> getDeviceId() async {
    _ensureInitialized();
    var deviceId =
        _appPreferencesBox.get(AppPreferenceKeys.deviceId) as String?;

    if (deviceId == null) {
      // Generate a new UUID for this device
      deviceId = _generateUuid();
      await _appPreferencesBox.put(AppPreferenceKeys.deviceId, deviceId);
    }

    return deviceId;
  }

  /// Generates a UUID v4 string.
  static String _generateUuid() {
    return const Uuid().v4();
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
