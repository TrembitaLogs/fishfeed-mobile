import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Environment variable keys for PostHog configuration.
abstract final class PostHogEnvKeys {
  static const String apiKey = 'POSTHOG_API_KEY';
  static const String host = 'POSTHOG_HOST';
}

/// Analytics event names as constants from PRD.
abstract final class AnalyticsEvents {
  // Onboarding events
  static const String firstOpen = 'first_open';
  static const String onboardingStart = 'onboarding_start';
  static const String onboardingQuickStartSelected =
      'onboarding_quick_start_selected';
  static const String fishAddStarted = 'fish_add_started';
  static const String fishAddMethodSelected = 'fish_add_method_selected';
  static const String fishAdded = 'fish_added';
  static const String scheduleGenerated = 'schedule_generated';
  static const String scheduleEdited = 'schedule_edited';
  static const String notificationsPermissionPromptShown =
      'notifications_permission_prompt_shown';
  static const String notificationsPermissionResult =
      'notifications_permission_result';
  static const String firstFeedEventCreated = 'first_feed_event_created';

  // Core Loop events
  static const String feedEventShown = 'feed_event_shown';
  static const String feedMarked = 'feed_marked';
  static const String feedEventAutoMissed = 'feed_event_auto_missed';
  static const String feedUndo = 'feed_undo';

  // Notifications events
  static const String pushSent = 'push_sent';
  static const String pushOpened = 'push_opened';
  static const String appOpenFromPush = 'app_open_from_push';
  static const String notificationSettingsChanged =
      'notification_settings_changed';

  // Gamification events
  static const String streakStarted = 'streak_started';
  static const String streakIncremented = 'streak_incremented';
  static const String streakBroken = 'streak_broken';
  static const String freezeUsed = 'freeze_used';
  static const String achievementUnlocked = 'achievement_unlocked';
  static const String shareInitiated = 'share_initiated';
  static const String shareCompleted = 'share_completed';

  // Fish Management events
  static const String myAquariumOpened = 'my_aquarium_opened';
  static const String fishEdited = 'fish_edited';
  static const String fishDeleted = 'fish_deleted';

  // AI Camera events
  static const String aiScanStarted = 'ai_scan_started';
  static const String aiScanResult = 'ai_scan_result';
  static const String aiScanConfirmed = 'ai_scan_confirmed';
  static const String aiScanCorrected = 'ai_scan_corrected';
  static const String aiScanFailed = 'ai_scan_failed';
  static const String freeScansRemainingShown = 'free_scans_remaining_shown';

  // Family events
  static const String familyInviteSent = 'family_invite_sent';
  static const String familyInviteAccepted = 'family_invite_accepted';
  static const String familyMemberAdded = 'family_member_added';
  static const String feedMarkedByFamily = 'feed_marked_by_family';

  // Monetization events
  static const String paywallShown = 'paywall_shown';
  static const String paywallDismissed = 'paywall_dismissed';
  static const String subscriptionStarted = 'subscription_started';
  static const String subscriptionRenewed = 'subscription_renewed';
  static const String subscriptionCanceled = 'subscription_canceled';
  static const String adImpression = 'ad_impression';
  static const String adClicked = 'ad_clicked';
  static const String removeAdsPurchase = 'remove_ads_purchase';
}

/// Analytics event parameters as constants.
abstract final class AnalyticsParams {
  // Common
  static const String source = 'source';
  static const String action = 'action';
  static const String success = 'success';
  static const String reason = 'reason';
  static const String timestamp = 'timestamp';

  // Onboarding
  static const String method = 'method';
  static const String speciesId = 'species_id';
  static const String speciesName = 'species_name';
  static const String fishCount = 'fish_count';
  static const String newQuantity = 'new_quantity';
  static const String timesPerDay = 'times_per_day';
  static const String granted = 'granted';

  // Core Loop
  static const String eventId = 'event_id';
  static const String status = 'status';
  static const String isFirstTime = 'is_first_time';
  static const String aquariumId = 'aquarium_id';

  // Notifications
  static const String notificationType = 'notification_type';
  static const String settingName = 'setting_name';
  static const String settingValue = 'setting_value';

  // Gamification
  static const String streakCount = 'streak_count';
  static const String achievementType = 'achievement_type';
  static const String achievementId = 'achievement_id';
  static const String shareMethod = 'share_method';
  static const String freezeDaysRemaining = 'freeze_days_remaining';

  // AI Camera
  static const String confidence = 'confidence';
  static const String detectedSpeciesId = 'detected_species_id';
  static const String correctedSpeciesId = 'corrected_species_id';
  static const String errorMessage = 'error_message';
  static const String scansRemaining = 'scans_remaining';

  // Monetization
  static const String paywallSource = 'paywall_source';
  static const String plan = 'plan';
  static const String price = 'price';
  static const String currency = 'currency';
  static const String adType = 'ad_type';
  static const String adPlacement = 'ad_placement';
  static const String isPremium = 'is_premium';
}

/// Paywall source for analytics tracking.
enum PaywallSource {
  aiCameraCapture,
  aiCameraLimit,
  settings,
  premiumFeature,
  familyLimit,
  adsRemoval,
}

/// Fish add method for analytics tracking.
enum FishAddMethod { manual, aiCamera }

/// Feed status for analytics tracking.
enum FeedStatus { fed, missed, skipped }

/// Ad type for analytics tracking.
enum AdType { banner, interstitial, rewarded }

/// Service for tracking analytics events with PostHog.
///
/// Implements singleton pattern for consistent tracking across the app.
/// All events follow the PRD analytics specification.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService _instance = AnalyticsService._();

  /// Singleton instance of AnalyticsService.
  static AnalyticsService get instance => _instance;

  final Posthog _posthog = Posthog();
  bool _isInitialized = false;

  /// Whether PostHog has been initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes PostHog SDK.
  ///
  /// Must be called before any tracking methods.
  /// Uses API key from environment variables.
  /// Skips initialization if API key is not provided.
  Future<void> initialize({String? appVersion}) async {
    final apiKey = dotenv.env[PostHogEnvKeys.apiKey];

    if (apiKey == null || apiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[Analytics] PostHog API key not configured, skipping initialization',
        );
      }
      return;
    }

    try {
      final config = PostHogConfig(apiKey);

      // Configure host (default: https://us.i.posthog.com)
      final host = dotenv.env[PostHogEnvKeys.host];
      if (host != null && host.isNotEmpty) {
        config.host = host;
      }

      // Enable debug mode in development
      config.debug = kDebugMode;

      // Configure event batching
      config.flushAt = 20;
      config.maxQueueSize = 1000;
      config.maxBatchSize = 50;
      config.flushInterval = const Duration(seconds: 30);

      // Feature flags configuration
      config.sendFeatureFlagEvents = true;
      config.preloadFeatureFlags = true;

      // Privacy settings - only track identified users
      config.optOut = false;
      config.personProfiles = PostHogPersonProfiles.identifiedOnly;

      // Lifecycle events
      config.captureApplicationLifecycleEvents = true;

      // Initialize PostHog
      await _posthog.setup(config);

      _isInitialized = true;

      // Register super properties
      await _registerSuperProperties(appVersion: appVersion);

      if (kDebugMode) {
        debugPrint('[Analytics] PostHog initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Failed to initialize PostHog: $e');
      }
    }
  }

  /// Registers super properties that will be sent with every event.
  Future<void> _registerSuperProperties({String? appVersion}) async {
    if (!_isInitialized) return;

    // Platform
    await _posthog.register('platform', Platform.operatingSystem);

    // App version
    if (appVersion != null) {
      await _posthog.register('app_version', appVersion);
    }

    // Environment
    await _posthog.register(
      'environment',
      kDebugMode ? 'development' : 'production',
    );
  }

  /// Identifies user with their properties.
  ///
  /// Call this after user authentication.
  Future<void> identify({
    required String userId,
    String? email,
    String? subscriptionStatus,
    int? freeAiScansRemaining,
    Map<String, dynamic>? additionalProperties,
  }) async {
    if (!_isInitialized) {
      _logEvent('identify', {'user_id': userId});
      return;
    }

    final properties = <String, Object>{
      if (email != null) 'email': email,
      if (subscriptionStatus != null) 'subscription_status': subscriptionStatus,
      if (freeAiScansRemaining != null)
        'free_ai_scans_remaining': freeAiScansRemaining,
      if (additionalProperties != null)
        for (final entry in additionalProperties.entries)
          if (entry.value != null) entry.key: entry.value as Object,
    };

    await _posthog.identify(
      userId: userId,
      userProperties: properties,
      userPropertiesSetOnce: {
        'first_seen_at': DateTime.now().toIso8601String(),
      },
    );

    if (kDebugMode) {
      debugPrint('[Analytics] User identified: $userId');
    }
  }

  /// Resets user identity on logout.
  Future<void> reset() async {
    if (!_isInitialized) return;

    await _posthog.reset();

    if (kDebugMode) {
      debugPrint('[Analytics] User reset');
    }
  }

  // ============================================================
  // ONBOARDING EVENTS
  // ============================================================

  /// Tracks first app open.
  void trackFirstOpen() {
    _capture(AnalyticsEvents.firstOpen);
  }

  /// Tracks onboarding start.
  void trackOnboardingStart() {
    _capture(AnalyticsEvents.onboardingStart);
  }

  /// Tracks quick start option selection in onboarding.
  void trackOnboardingQuickStartSelected() {
    _capture(AnalyticsEvents.onboardingQuickStartSelected);
  }

  /// Tracks fish add flow start.
  void trackFishAddStarted({required String aquariumId}) {
    _capture(AnalyticsEvents.fishAddStarted, {
      AnalyticsParams.aquariumId: aquariumId,
    });
  }

  /// Tracks fish add method selection.
  void trackFishAddMethodSelected({required FishAddMethod method}) {
    _capture(AnalyticsEvents.fishAddMethodSelected, {
      AnalyticsParams.method: method.name,
    });
  }

  /// Tracks fish added to aquarium.
  void trackFishAdded({
    required String speciesId,
    required String speciesName,
    required int fishCount,
    required FishAddMethod method,
  }) {
    _capture(AnalyticsEvents.fishAdded, {
      AnalyticsParams.speciesId: speciesId,
      AnalyticsParams.speciesName: speciesName,
      AnalyticsParams.fishCount: fishCount,
      AnalyticsParams.method: method.name,
    });
  }

  /// Tracks feeding schedule generation.
  void trackScheduleGenerated({required int timesPerDay}) {
    _capture(AnalyticsEvents.scheduleGenerated, {
      AnalyticsParams.timesPerDay: timesPerDay,
    });
  }

  /// Tracks schedule edit.
  void trackScheduleEdited({required int newTimesPerDay}) {
    _capture(AnalyticsEvents.scheduleEdited, {
      AnalyticsParams.timesPerDay: newTimesPerDay,
    });
  }

  /// Tracks notification permission prompt shown.
  void trackNotificationsPermissionPromptShown() {
    _capture(AnalyticsEvents.notificationsPermissionPromptShown);
  }

  /// Tracks notification permission result.
  void trackNotificationsPermissionResult({required bool granted}) {
    _capture(AnalyticsEvents.notificationsPermissionResult, {
      AnalyticsParams.granted: granted,
    });
  }

  /// Tracks first feed event creation.
  void trackFirstFeedEventCreated() {
    _capture(AnalyticsEvents.firstFeedEventCreated);
  }

  // ============================================================
  // CORE LOOP EVENTS
  // ============================================================

  /// Tracks feed event shown to user.
  void trackFeedEventShown({required String eventId}) {
    _capture(AnalyticsEvents.feedEventShown, {
      AnalyticsParams.eventId: eventId,
    });
  }

  /// Tracks feed marked (fed/missed).
  void trackFeedMarked({
    required String eventId,
    required FeedStatus status,
    bool isFirstTime = false,
  }) {
    _capture(AnalyticsEvents.feedMarked, {
      AnalyticsParams.eventId: eventId,
      AnalyticsParams.status: status.name,
      AnalyticsParams.isFirstTime: isFirstTime,
    });
  }

  /// Tracks feed event auto-missed.
  void trackFeedEventAutoMissed({required String eventId}) {
    _capture(AnalyticsEvents.feedEventAutoMissed, {
      AnalyticsParams.eventId: eventId,
    });
  }

  /// Tracks feed undo action.
  void trackFeedUndo({
    required String eventId,
    required FeedStatus previousStatus,
  }) {
    _capture(AnalyticsEvents.feedUndo, {
      AnalyticsParams.eventId: eventId,
      AnalyticsParams.status: previousStatus.name,
    });
  }

  // ============================================================
  // NOTIFICATIONS EVENTS
  // ============================================================

  /// Tracks push notification sent.
  void trackPushSent({required String notificationType}) {
    _capture(AnalyticsEvents.pushSent, {
      AnalyticsParams.notificationType: notificationType,
    });
  }

  /// Tracks push notification opened.
  void trackPushOpened({required String notificationType}) {
    _capture(AnalyticsEvents.pushOpened, {
      AnalyticsParams.notificationType: notificationType,
    });
  }

  /// Tracks app opened from push notification.
  void trackAppOpenFromPush({required String notificationType}) {
    _capture(AnalyticsEvents.appOpenFromPush, {
      AnalyticsParams.notificationType: notificationType,
    });
  }

  /// Tracks notification settings change.
  void trackNotificationSettingsChanged({
    required String settingName,
    required bool newValue,
  }) {
    _capture(AnalyticsEvents.notificationSettingsChanged, {
      AnalyticsParams.settingName: settingName,
      AnalyticsParams.settingValue: newValue,
    });
  }

  // ============================================================
  // GAMIFICATION EVENTS
  // ============================================================

  /// Tracks streak started.
  void trackStreakStarted() {
    _capture(AnalyticsEvents.streakStarted);
  }

  /// Tracks streak incremented.
  void trackStreakIncremented({required int streakCount}) {
    _capture(AnalyticsEvents.streakIncremented, {
      AnalyticsParams.streakCount: streakCount,
    });
  }

  /// Tracks streak broken.
  void trackStreakBroken({required int previousStreak}) {
    _capture(AnalyticsEvents.streakBroken, {
      AnalyticsParams.streakCount: previousStreak,
    });
  }

  /// Tracks freeze day used.
  void trackFreezeUsed({required int freezeDaysRemaining}) {
    _capture(AnalyticsEvents.freezeUsed, {
      AnalyticsParams.freezeDaysRemaining: freezeDaysRemaining,
    });
  }

  /// Tracks achievement unlocked.
  void trackAchievementUnlocked({
    required String achievementId,
    required String achievementType,
  }) {
    _capture(AnalyticsEvents.achievementUnlocked, {
      AnalyticsParams.achievementId: achievementId,
      AnalyticsParams.achievementType: achievementType,
    });
  }

  /// Tracks share initiated.
  void trackShareInitiated({String? shareMethod}) {
    _capture(AnalyticsEvents.shareInitiated, {
      if (shareMethod != null) AnalyticsParams.shareMethod: shareMethod,
    });
  }

  /// Tracks share completed.
  void trackShareCompleted({String? shareMethod}) {
    _capture(AnalyticsEvents.shareCompleted, {
      if (shareMethod != null) AnalyticsParams.shareMethod: shareMethod,
    });
  }

  // ============================================================
  // AI CAMERA EVENTS
  // ============================================================

  /// Tracks AI scan started.
  void trackAiScanStarted({
    required int scansRemaining,
    required bool isPremium,
  }) {
    _capture(AnalyticsEvents.aiScanStarted, {
      AnalyticsParams.scansRemaining: scansRemaining,
      AnalyticsParams.isPremium: isPremium,
    });
  }

  /// Tracks AI scan result.
  void trackAiScanResult({
    required bool success,
    String? detectedSpeciesId,
    double? confidence,
  }) {
    _capture(AnalyticsEvents.aiScanResult, {
      AnalyticsParams.success: success,
      if (detectedSpeciesId != null)
        AnalyticsParams.detectedSpeciesId: detectedSpeciesId,
      if (confidence != null) AnalyticsParams.confidence: confidence,
    });
  }

  /// Tracks AI scan confirmed by user.
  void trackAiScanConfirmed({required String speciesId}) {
    _capture(AnalyticsEvents.aiScanConfirmed, {
      AnalyticsParams.speciesId: speciesId,
    });
  }

  /// Tracks AI scan corrected by user.
  void trackAiScanCorrected({
    required String detectedSpeciesId,
    required String correctedSpeciesId,
  }) {
    _capture(AnalyticsEvents.aiScanCorrected, {
      AnalyticsParams.detectedSpeciesId: detectedSpeciesId,
      AnalyticsParams.correctedSpeciesId: correctedSpeciesId,
    });
  }

  /// Tracks AI scan failed.
  void trackAiScanFailed({required String reason}) {
    _capture(AnalyticsEvents.aiScanFailed, {AnalyticsParams.reason: reason});
  }

  /// Tracks free scans remaining shown to user.
  void trackFreeScansRemainingShown({required int scansRemaining}) {
    _capture(AnalyticsEvents.freeScansRemainingShown, {
      AnalyticsParams.scansRemaining: scansRemaining,
    });
  }

  // ============================================================
  // FISH MANAGEMENT EVENTS
  // ============================================================

  /// Tracks My Aquarium screen opened.
  void trackMyAquariumOpened() {
    _capture(AnalyticsEvents.myAquariumOpened);
  }

  /// Tracks fish edited.
  void trackFishEdited({required String speciesId, required int newQuantity}) {
    _capture(AnalyticsEvents.fishEdited, {
      AnalyticsParams.speciesId: speciesId,
      AnalyticsParams.newQuantity: newQuantity,
    });
  }

  /// Tracks fish deleted.
  void trackFishDeleted({required String speciesId}) {
    _capture(AnalyticsEvents.fishDeleted, {
      AnalyticsParams.speciesId: speciesId,
    });
  }

  // ============================================================
  // FAMILY EVENTS
  // ============================================================

  /// Tracks family invite sent.
  void trackFamilyInviteSent({required String aquariumId}) {
    _capture(AnalyticsEvents.familyInviteSent, {
      AnalyticsParams.aquariumId: aquariumId,
    });
  }

  /// Tracks family invite accepted.
  void trackFamilyInviteAccepted({required String aquariumId}) {
    _capture(AnalyticsEvents.familyInviteAccepted, {
      AnalyticsParams.aquariumId: aquariumId,
    });
  }

  /// Tracks family member added.
  void trackFamilyMemberAdded({required String aquariumId}) {
    _capture(AnalyticsEvents.familyMemberAdded, {
      AnalyticsParams.aquariumId: aquariumId,
    });
  }

  /// Tracks feed marked by family member.
  void trackFeedMarkedByFamily({
    required String eventId,
    required FeedStatus status,
  }) {
    _capture(AnalyticsEvents.feedMarkedByFamily, {
      AnalyticsParams.eventId: eventId,
      AnalyticsParams.status: status.name,
    });
  }

  // ============================================================
  // MONETIZATION EVENTS
  // ============================================================

  /// Tracks paywall shown.
  void trackPaywallShown({
    required PaywallSource source,
    int? scansRemaining,
    bool? isPremium,
  }) {
    _capture(AnalyticsEvents.paywallShown, {
      AnalyticsParams.paywallSource: source.name,
      if (scansRemaining != null)
        AnalyticsParams.scansRemaining: scansRemaining,
      if (isPremium != null) AnalyticsParams.isPremium: isPremium,
    });
  }

  /// Tracks paywall dismissed.
  void trackPaywallDismissed({required PaywallSource source}) {
    _capture(AnalyticsEvents.paywallDismissed, {
      AnalyticsParams.paywallSource: source.name,
    });
  }

  /// Tracks subscription started.
  void trackSubscriptionStarted({
    required String plan,
    double? price,
    String? currency,
  }) {
    _capture(AnalyticsEvents.subscriptionStarted, {
      AnalyticsParams.plan: plan,
      if (price != null) AnalyticsParams.price: price,
      if (currency != null) AnalyticsParams.currency: currency,
    });
  }

  /// Tracks subscription renewed.
  void trackSubscriptionRenewed({required String plan}) {
    _capture(AnalyticsEvents.subscriptionRenewed, {AnalyticsParams.plan: plan});
  }

  /// Tracks subscription canceled.
  void trackSubscriptionCanceled({required String plan}) {
    _capture(AnalyticsEvents.subscriptionCanceled, {
      AnalyticsParams.plan: plan,
    });
  }

  /// Tracks ad impression.
  void trackAdImpression({required AdType adType, String? placement}) {
    _capture(AnalyticsEvents.adImpression, {
      AnalyticsParams.adType: adType.name,
      if (placement != null) AnalyticsParams.adPlacement: placement,
    });
  }

  /// Tracks ad clicked.
  void trackAdClicked({required AdType adType, String? placement}) {
    _capture(AnalyticsEvents.adClicked, {
      AnalyticsParams.adType: adType.name,
      if (placement != null) AnalyticsParams.adPlacement: placement,
    });
  }

  /// Tracks remove ads purchase.
  void trackRemoveAdsPurchase({double? price, String? currency}) {
    _capture(AnalyticsEvents.removeAdsPurchase, {
      if (price != null) AnalyticsParams.price: price,
      if (currency != null) AnalyticsParams.currency: currency,
    });
  }

  // ============================================================
  // PRIVATE METHODS
  // ============================================================

  /// Captures an event with optional properties.
  void _capture(String eventName, [Map<String, Object>? properties]) {
    if (!_isInitialized) {
      _logEvent(eventName, properties ?? {});
      return;
    }

    _posthog.capture(eventName: eventName, properties: properties);

    if (kDebugMode) {
      debugPrint('[Analytics] Event: $eventName ${properties ?? ''}');
    }
  }

  /// Logs event to console when PostHog is not initialized.
  void _logEvent(String eventName, Map<String, Object> properties) {
    if (kDebugMode) {
      debugPrint('[Analytics] (not initialized) $eventName: $properties');
    }
  }
}

/// Provider for the AnalyticsService singleton.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService.instance;
});
