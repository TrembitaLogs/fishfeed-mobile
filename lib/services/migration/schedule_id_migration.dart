import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kMigrationFlagKey = 'schedule_id_migration_v1_done';

/// Strict UUID v4 / v1 / v5 syntactic check (8-4-4-4-12 hex pattern).
/// Server-side Pydantic accepts any UUID variant; we mirror that.
bool isValidUuidV4(String value) {
  // 36 chars total, lowercase or uppercase hex, dashes at the right spots.
  final re = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  return re.hasMatch(value);
}

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
