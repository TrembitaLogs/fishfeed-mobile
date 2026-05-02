import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/services/notifications/notification_orchestrator.dart';
import 'package:fishfeed/services/notifications/notification_permission_service.dart';
import 'package:fishfeed/services/notifications/notification_service.dart';

/// Provider exposing the singleton [NotificationOrchestrator].
///
/// The orchestrator is lifecycle-scoped to the app — one instance for the
/// entire process. Triggers (edit screens, family sync, lifecycle observer,
/// migrate) all read from this provider.
final notificationOrchestratorProvider = Provider<NotificationOrchestrator>((
  ref,
) {
  return NotificationOrchestrator(
    scheduleDs: ref.read(scheduleLocalDataSourceProvider),
    fishDs: ref.read(fishLocalDataSourceProvider),
    aquariumDs: ref.read(aquariumLocalDataSourceProvider),
    notificationService: NotificationService.instance,
    permissionService: NotificationPermissionService.instance,
  );
});
