import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/app.dart';
import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/services/analytics/analytics_service.dart';
import 'package:fishfeed/services/migration/migration_service.dart';
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

      // Initialize analytics (PostHog)
      await AnalyticsService.instance.initialize(appVersion: '1.0.0');

      // Initialize notification service
      await NotificationService.instance.initialize();

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

/// Runs data migration if needed.
///
/// Migrates fish and feeding events from legacy 'default' aquariumId
/// to a proper UUID-based aquarium. This is a one-time migration for
/// users upgrading from older versions.
Future<void> _runMigrationIfNeeded() async {
  final migrationService = MigrationService(
    aquariumLocalDs: AquariumLocalDataSource(),
    fishLocalDs: FishLocalDataSource(),
    feedingLocalDs: FeedingLocalDataSource(),
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
