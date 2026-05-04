import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kMigrationFlagKey = 'schedule_id_migration_v1_done';

sealed class MigrationResult {
  const MigrationResult();
}

class NoMigrationNeeded extends MigrationResult {
  const NoMigrationNeeded();
}

class MigrationSuccess extends MigrationResult {
  const MigrationSuccess({
    required this.repairedCount,
    required this.skippedAlreadySyncedCount,
  });

  final int repairedCount;
  final int skippedAlreadySyncedCount;
}

class MigrationError extends MigrationResult {
  const MigrationError({required this.message, required this.error});

  final String message;
  final Object error;
}

class ScheduleIdMigration {
  ScheduleIdMigration({
    required ScheduleLocalDataSource scheduleDs,
    required SharedPreferences prefs,
  }) : _scheduleDs = scheduleDs,
       _prefs = prefs;

  // ignore: unused_field — will be used in Task 2 (repair logic)
  final ScheduleLocalDataSource _scheduleDs;
  final SharedPreferences _prefs;

  Future<MigrationResult> run() async {
    if (_prefs.getBool(_kMigrationFlagKey) ?? false) {
      return const NoMigrationNeeded();
    }
    // implemented in next tasks
    return const NoMigrationNeeded();
  }
}
