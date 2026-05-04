import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _kMigrationFlagKey = 'schedule_id_migration_v1_done';

/// Strict UUID v4 / v1 / v5 syntactic check (8-4-4-4-12 hex pattern).
/// Server-side Pydantic accepts any UUID variant; we mirror that.
bool isValidUuidV4(String value) {
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
    Uuid uuid = const Uuid(),
  }) : _scheduleDs = scheduleDs,
       _prefs = prefs,
       _uuid = uuid;

  final ScheduleLocalDataSource _scheduleDs;
  final SharedPreferences _prefs;
  final Uuid _uuid;

  Future<MigrationResult> run() async {
    if (_prefs.getBool(_kMigrationFlagKey) ?? false) {
      return const NoMigrationNeeded();
    }

    try {
      var repaired = 0;
      var skippedSynced = 0;

      for (final schedule in _scheduleDs.getAll()) {
        if (isValidUuidV4(schedule.id)) {
          continue;
        }
        if (schedule.serverUpdatedAt != null) {
          // Should never happen — server rejects non-UUID with 422.
          // Guard against double-create; leave the record alone.
          skippedSynced++;
          continue;
        }

        final newId = _uuid.v4();
        final replacement = ScheduleModel(
          id: newId,
          fishId: schedule.fishId,
          aquariumId: schedule.aquariumId,
          time: schedule.time,
          intervalDays: schedule.intervalDays,
          anchorDate: schedule.anchorDate,
          foodType: schedule.foodType,
          portionHint: schedule.portionHint,
          active: schedule.active,
          createdAt: schedule.createdAt,
          updatedAt: schedule.updatedAt,
          createdByUserId: schedule.createdByUserId,
          synced: false,
          serverUpdatedAt: null,
        );

        await _scheduleDs.delete(schedule.id);
        await _scheduleDs.save(replacement);
        repaired++;
      }

      await _prefs.setBool(_kMigrationFlagKey, true);

      return MigrationSuccess(
        repairedCount: repaired,
        skippedAlreadySyncedCount: skippedSynced,
      );
    } catch (e) {
      return MigrationError(
        message: 'ScheduleIdMigration failed: $e',
        error: e,
      );
    }
  }
}
