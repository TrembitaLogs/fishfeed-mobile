import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/schedule_model.dart';

/// Data source for managing feeding schedules in local Hive storage.
///
/// Provides CRUD operations for schedules with offline-first support.
/// Tracks synchronization status for each schedule to enable background sync.
///
/// Example:
/// ```dart
/// final scheduleDs = ScheduleLocalDataSource();
/// await scheduleDs.save(schedule);
/// final schedules = scheduleDs.getByAquariumId('aquarium_123');
/// ```
class ScheduleLocalDataSource {
  ScheduleLocalDataSource({Box<dynamic>? schedulesBox})
    : _schedulesBox = schedulesBox;

  final Box<dynamic>? _schedulesBox;

  /// Gets the schedules box, using the injected box or the default HiveBoxes.
  Box<dynamic> get _schedules => _schedulesBox ?? HiveBoxes.schedules;

  // ============ Read Operations ============

  /// Retrieves all schedules from local storage.
  ///
  /// Returns all stored schedules sorted by creation time (newest first).
  List<ScheduleModel> getAll() {
    final schedules = _schedules.values.whereType<ScheduleModel>().toList();
    schedules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return schedules;
  }

  /// Retrieves a single schedule by its ID.
  ///
  /// [id] - The unique identifier of the schedule.
  /// Returns `null` if no schedule with the given ID exists.
  ScheduleModel? getById(String id) {
    final schedule = _schedules.get(id);
    if (schedule is ScheduleModel) {
      return schedule;
    }
    return null;
  }

  /// Retrieves all schedules for a specific aquarium.
  ///
  /// [aquariumId] - The ID of the aquarium to filter by.
  /// [activeOnly] - If true, returns only active schedules (default: false).
  /// Returns a list of schedules sorted by time of day.
  List<ScheduleModel> getByAquariumId(
    String aquariumId, {
    bool activeOnly = false,
  }) {
    final schedules = _schedules.values
        .whereType<ScheduleModel>()
        .where((s) => s.aquariumId == aquariumId)
        .where((s) => !activeOnly || s.active)
        .toList();

    // Sort by time of day for display
    schedules.sort((a, b) => a.time.compareTo(b.time));
    return schedules;
  }

  /// Retrieves all schedules for a specific fish.
  ///
  /// [fishId] - The ID of the fish to filter by.
  /// [activeOnly] - If true, returns only active schedules (default: false).
  /// Returns a list of schedules sorted by time of day.
  List<ScheduleModel> getByFishId(String fishId, {bool activeOnly = false}) {
    final schedules = _schedules.values
        .whereType<ScheduleModel>()
        .where((s) => s.fishId == fishId)
        .where((s) => !activeOnly || s.active)
        .toList();

    schedules.sort((a, b) => a.time.compareTo(b.time));
    return schedules;
  }

  /// Retrieves all active schedules for a specific aquarium.
  ///
  /// Convenience method equivalent to getByAquariumId with activeOnly=true.
  List<ScheduleModel> getActiveByAquariumId(String aquariumId) {
    return getByAquariumId(aquariumId, activeOnly: true);
  }

  // ============ Write Operations ============

  /// Saves a schedule to local storage.
  ///
  /// [schedule] - The schedule model to store.
  /// Creates a new record or updates an existing one with the same ID.
  Future<void> save(ScheduleModel schedule) async {
    await _schedules.put(schedule.id, schedule);
  }

  /// Saves multiple schedules to local storage in a batch operation.
  ///
  /// [schedules] - List of schedule models to store.
  /// This is more efficient than calling save() multiple times.
  /// Used when server returns multiple schedules (e.g., from /generate endpoint).
  Future<void> saveAll(List<ScheduleModel> schedules) async {
    final Map<String, ScheduleModel> entries = {
      for (final schedule in schedules) schedule.id: schedule,
    };
    await _schedules.putAll(entries);
  }

  /// Updates an existing schedule in local storage.
  ///
  /// [schedule] - The updated schedule model.
  /// Returns `true` if the schedule was updated, `false` if it doesn't exist.
  Future<bool> update(ScheduleModel schedule) async {
    final existing = getById(schedule.id);
    if (existing == null) {
      return false;
    }
    await _schedules.put(schedule.id, schedule);
    return true;
  }

  /// Deletes a schedule from local storage.
  ///
  /// [id] - The unique identifier of the schedule to delete.
  /// Returns `true` if the schedule was deleted, `false` if it didn't exist.
  Future<bool> delete(String id) async {
    final existing = getById(id);
    if (existing == null) {
      return false;
    }
    await _schedules.delete(id);
    return true;
  }

  /// Deletes all schedules for a specific fish.
  ///
  /// [fishId] - The ID of the fish whose schedules should be deleted.
  /// Returns the number of schedules deleted.
  Future<int> deleteByFishId(String fishId) async {
    final schedules = getByFishId(fishId);
    for (final schedule in schedules) {
      await _schedules.delete(schedule.id);
    }
    return schedules.length;
  }

  // ============ Synchronization Methods ============

  /// Retrieves all schedules that haven't been synced to the server.
  ///
  /// Returns schedules where [synced] is `false` or where local changes
  /// are newer than server changes, sorted by update time (oldest first).
  List<ScheduleModel> getUnsynced() {
    final schedules = _schedules.values
        .whereType<ScheduleModel>()
        .where((s) => s.needsSync)
        .toList();

    // Sort by updatedAt (oldest first) to sync in order
    schedules.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return schedules;
  }

  /// Marks a schedule as synced with the server.
  ///
  /// [id] - The unique identifier of the schedule.
  /// [serverTime] - The timestamp from the server.
  /// Returns `true` if updated, `false` if schedule doesn't exist.
  Future<bool> markAsSynced(String id, DateTime serverTime) async {
    final schedule = getById(id);
    if (schedule == null) {
      return false;
    }

    schedule.markAsSynced(serverTime);
    await _schedules.put(id, schedule);
    return true;
  }

  /// Applies a server update to a local schedule.
  ///
  /// Updates local data with server data if server version is newer,
  /// or creates a new schedule if it doesn't exist locally.
  ///
  /// [serverData] - The data from the server in JSON format.
  Future<void> applyServerUpdate(Map<String, dynamic> serverData) async {
    final id = serverData['id'] as String;
    final existing = getById(id);

    final serverUpdatedAt = serverData['updated_at'] != null
        ? DateTime.tryParse(serverData['updated_at'] as String)
        : DateTime.now();

    if (existing != null) {
      // Check if server version is newer
      if (existing.serverUpdatedAt != null &&
          serverUpdatedAt != null &&
          !serverUpdatedAt.isAfter(existing.serverUpdatedAt!)) {
        // Local version is newer or equal, skip
        return;
      }
    }

    // Create or update from server data
    final schedule = ScheduleModel.fromJson(serverData);
    await _schedules.put(schedule.id, schedule);
  }

  /// Returns the count of unsynced schedules.
  int getUnsyncedCount() {
    return _schedules.values
        .whereType<ScheduleModel>()
        .where((s) => s.needsSync)
        .length;
  }

  /// Checks if there are any unsynced schedules.
  bool hasUnsyncedSchedules() {
    return _schedules.values.whereType<ScheduleModel>().any((s) => s.needsSync);
  }

  // ============ Utility Methods ============

  /// Clears all schedules from local storage.
  ///
  /// Use with caution - this permanently deletes all local schedule data.
  Future<void> clearAll() async {
    await _schedules.clear();
  }

  /// Returns the total number of schedules in local storage.
  int getCount() {
    return _schedules.values.whereType<ScheduleModel>().length;
  }
}
