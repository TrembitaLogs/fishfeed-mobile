import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fishfeed/services/notifications/notification_orchestrator.dart';
import 'package:fishfeed/services/notifications/notification_service.dart';
import 'package:fishfeed/services/notifications/planned_alarm.dart';

/// SharedPreferences key for the v2 migration flag.
const String kNotificationMigrationV2Key = 'notification_migration_v2_done';

/// One-shot migration that cancels old daily-repeat alarms and rebuilds the
/// system from current Hive state via the orchestrator.
///
/// Idempotent: subsequent calls (after the first success) are no-ops.
///
/// Errors do NOT block app startup — they're captured to Sentry and the flag
/// is NOT set, so a future launch retries.
Future<void> runNotificationMigrationV2({
  required NotificationOrchestrator orchestrator,
  required NotificationService notificationService,
  SharedPreferences? prefs,
}) async {
  final preferences = prefs ?? await SharedPreferences.getInstance();
  if (preferences.getBool(kNotificationMigrationV2Key) ?? false) {
    return; // Already migrated.
  }

  await Sentry.addBreadcrumb(
    Breadcrumb(category: 'notif', message: 'migration-v2-start'),
  );

  try {
    await notificationService.cancelAllNotifications();
    final result = await orchestrator.reconcile(
      reason: ReconcileReason.migration,
    );
    if (result.isSuccess) {
      await preferences.setBool(kNotificationMigrationV2Key, true);
      await Sentry.addBreadcrumb(
        Breadcrumb(
          category: 'notif',
          message: 'migration-v2-done',
          data: {'added': result.added},
        ),
      );
    } else {
      await Sentry.captureException(
        result.error ?? Exception('Migration reconcile failed'),
        withScope: (scope) {
          scope.setTag('migration', 'notification_v2');
        },
      );
    }
  } catch (e, st) {
    await Sentry.captureException(
      e,
      stackTrace: st,
      withScope: (scope) {
        scope.setTag('migration', 'notification_v2');
      },
    );
  }
}
