import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:fishfeed/app.dart';
import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/services/analytics/analytics_service.dart';
import 'package:fishfeed/services/migration/migration_service.dart';
import 'package:fishfeed/services/notifications/fcm_service.dart';
import 'package:fishfeed/services/notifications/notification_action_handler.dart';
import 'package:fishfeed/services/notifications/notification_service.dart';
import 'package:fishfeed/services/purchase/purchase_service.dart';
import 'package:fishfeed/services/sentry/sentry_service.dart';
import 'package:fishfeed/services/sync/background_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Sentry for error tracking
  // This wraps the app initialization to capture any startup errors
  await SentryService.instance.initialize(
    appRunner: () async {
      // Initialize local storage
      await HiveBoxes.init();

      // Run data migration if needed (from 'default' aquariumId to UUID)
      await _runMigrationIfNeeded();

      // Get app version from package info
      final packageInfo = await PackageInfo.fromPlatform();

      // Initialize analytics (PostHog)
      await AnalyticsService.instance.initialize(
        appVersion: packageInfo.version,
      );

      // Initialize Firebase
      await Firebase.initializeApp();

      // Initialize notification service
      try {
        await NotificationService.instance.initialize();
      } catch (e) {
        debugPrint('NotificationService init failed: $e');
      }

      // Check if app was launched from a notification action (cold start).
      // onDidReceiveNotificationResponse does not fire for launch actions,
      // so we must check launch details explicitly.
      await _handleNotificationLaunch();

      // Initialize FCM for remote push notifications
      await FcmService.instance.initialize();

      // Initialize purchase service (RevenueCat)
      await PurchaseService.instance.initialize();

      // Initialize background sync service (Workmanager)
      await BackgroundSyncService.instance.initialize(
        isInDebugMode: kDebugMode,
      );
      await BackgroundSyncService.instance.registerPeriodicSync();

      runApp(const ProviderScope(child: FishFeedApp()));
    },
  );
}

/// Checks if the app was launched from a notification action button.
///
/// When the user taps "Fed" on a notification while the app is terminated,
/// [getNotificationAppLaunchDetails] is the only reliable way to capture
/// the action. Stores it in [NotificationActionStorage] for processing
/// by [_NotificationActionListener] once the widget tree is ready.
Future<void> _handleNotificationLaunch() async {
  try {
    final details = await NotificationService.instance
        .getNotificationAppLaunchDetails();

    if (details == null || !details.didNotificationLaunchApp) return;

    final response = details.notificationResponse;
    if (response == null) return;

    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId == null ||
        actionId.isEmpty ||
        actionId != NotificationActionIds.fed ||
        payload == null) {
      return;
    }

    await NotificationActionStorage.addPendingAction(
      PendingNotificationAction(
        actionId: actionId,
        payload: payload,
        timestamp: DateTime.now(),
      ),
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('_handleNotificationLaunch error: $e');
    }
  }
}

/// Runs data migration if needed.
///
/// Migrates fish and feeding events from legacy 'default' aquariumId
/// to a proper UUID-based aquarium. This is a one-time migration for
/// users upgrading from older versions.
Future<void> _runMigrationIfNeeded() async {
  final migrationService = MigrationService(
    aquariumLocalDs: AquariumLocalDataSource(),
    fishLocalDs: FishLocalDataSource(),
    authLocalDs: AuthLocalDataSource(),
  );

  if (migrationService.needsMigration()) {
    final result = await migrationService.migrateDefaultAquarium();

    if (result is MigrationSuccess) {
      debugPrint(
        'Migration completed: ${result.migratedFishCount} fish, '
        '${result.migratedEventsCount} events migrated to '
        'aquarium "${result.newAquariumName}"',
      );
    } else if (result is MigrationError) {
      debugPrint('Migration failed: ${result.message}');
    }
  }
}
