import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/services/migration/migration_service.dart';

/// Provider for [MigrationService].
///
/// Provides singleton access to the migration service for handling
/// legacy 'default' aquariumId data migration.
///
/// Example:
/// ```dart
/// final migrationService = ref.read(migrationServiceProvider);
/// if (migrationService.needsMigration()) {
///   await migrationService.migrateDefaultAquarium();
/// }
/// ```
final migrationServiceProvider = Provider<MigrationService>((ref) {
  return MigrationService(
    aquariumLocalDs: ref.watch(aquariumLocalDataSourceProvider),
    fishLocalDs: ref.watch(fishLocalDataSourceProvider),
    feedingLocalDs: ref.watch(feedingLocalDataSourceProvider),
    authLocalDs: ref.watch(authLocalDataSourceProvider),
  );
});

/// State for migration operations.
sealed class MigrationState {
  const MigrationState();
}

/// Initial state - migration hasn't been checked yet.
class MigrationInitial extends MigrationState {
  const MigrationInitial();
}

/// Checking if migration is needed.
class MigrationChecking extends MigrationState {
  const MigrationChecking();
}

/// Migration is in progress.
class MigrationInProgress extends MigrationState {
  const MigrationInProgress();
}

/// Migration completed successfully or was not needed.
class MigrationCompleted extends MigrationState {
  const MigrationCompleted({this.result});

  final MigrationResult? result;
}

/// Migration failed with an error.
class MigrationFailed extends MigrationState {
  const MigrationFailed({required this.error});

  final MigrationError error;
}

/// Notifier for managing migration state.
class MigrationNotifier extends StateNotifier<MigrationState> {
  MigrationNotifier(this._migrationService) : super(const MigrationInitial());

  final MigrationService _migrationService;

  /// Checks if migration is needed and performs it if necessary.
  ///
  /// This is typically called during app startup.
  /// Runs two migrations in sequence:
  /// 1. Default aquarium migration (legacy 'default' aquariumId → UUID)
  /// 2. Fish ID migration (FeedingEvent.fishId from speciesId → actual fish UUID)
  Future<void> checkAndMigrate() async {
    state = const MigrationChecking();

    MigrationResult? lastResult;

    // Migration 1: Default aquarium migration
    if (_migrationService.needsMigration()) {
      state = const MigrationInProgress();
      final result = await _migrationService.migrateDefaultAquarium();
      if (result is MigrationError) {
        state = MigrationFailed(error: result);
        return;
      }
      lastResult = result;
    }

    // Migration 2: Fish ID migration (speciesId → actual fish UUID)
    if (_migrationService.needsFishIdMigration()) {
      state = const MigrationInProgress();
      final result = await _migrationService.migrateFeedingEventFishIds();
      if (result is MigrationError) {
        state = MigrationFailed(error: result);
        return;
      }
      lastResult = result;
    }

    state = MigrationCompleted(result: lastResult ?? const NoMigrationNeeded());
  }
}

/// Provider for migration state management.
///
/// Use this provider to track migration progress and status.
///
/// Example:
/// ```dart
/// final migrationState = ref.watch(migrationStateProvider);
/// switch (migrationState) {
///   case MigrationInProgress():
///     return CircularProgressIndicator();
///   case MigrationCompleted():
///     return HomeScreen();
///   // ...
/// }
/// ```
final migrationStateProvider =
    StateNotifierProvider<MigrationNotifier, MigrationState>((ref) {
  return MigrationNotifier(ref.watch(migrationServiceProvider));
});
