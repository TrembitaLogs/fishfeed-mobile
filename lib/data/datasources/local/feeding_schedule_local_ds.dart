import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/feeding_schedule_model.dart';

/// Data source for managing feeding schedule records in local Hive storage.
///
/// Provides CRUD operations for feeding schedules with offline-first support.
/// Schedules are associated with aquariums and define feeding times.
class FeedingScheduleLocalDataSource {
  FeedingScheduleLocalDataSource({Box<dynamic>? scheduleBox})
    : _scheduleBox = scheduleBox;

  final Box<dynamic>? _scheduleBox;

  /// Gets the schedule box, using the injected box or the default HiveBoxes.
  Box<dynamic> get _schedules => _scheduleBox ?? HiveBoxes.feedingSchedules;

  // ============ CRUD Operations ============

  /// Retrieves all schedules from local storage.
  List<FeedingScheduleModel> getAllSchedules() {
    return _schedules.values.whereType<FeedingScheduleModel>().toList();
  }

  /// Retrieves a single schedule by its ID.
  FeedingScheduleModel? getScheduleById(String id) {
    final schedule = _schedules.get(id);
    if (schedule is FeedingScheduleModel) {
      return schedule;
    }
    return null;
  }

  /// Retrieves the schedule for a specific aquarium.
  ///
  /// Each aquarium typically has one schedule.
  FeedingScheduleModel? getScheduleByAquariumId(String aquariumId) {
    return _schedules.values
        .whereType<FeedingScheduleModel>()
        .where((s) => s.aquariumId == aquariumId)
        .firstOrNull;
  }

  /// Saves a new schedule to local storage.
  Future<void> saveSchedule(FeedingScheduleModel schedule) async {
    await _schedules.put(schedule.id, schedule);
  }

  /// Updates an existing schedule in local storage.
  ///
  /// Returns `true` if the schedule was updated, `false` if it doesn't exist.
  Future<bool> updateSchedule(FeedingScheduleModel schedule) async {
    final existing = getScheduleById(schedule.id);
    if (existing == null) {
      return false;
    }
    schedule.markAsModified();
    await _schedules.put(schedule.id, schedule);
    return true;
  }

  /// Deletes a schedule from local storage.
  ///
  /// Returns `true` if the schedule was deleted, `false` if it didn't exist.
  Future<bool> deleteSchedule(String id) async {
    final existing = getScheduleById(id);
    if (existing == null) {
      return false;
    }
    await _schedules.delete(id);
    return true;
  }

  // ============ Sync Methods ============

  /// Retrieves all unsynced schedules.
  List<FeedingScheduleModel> getUnsyncedSchedules() {
    return _schedules.values
        .whereType<FeedingScheduleModel>()
        .where((s) => s.needsSync)
        .toList();
  }

  /// Marks a schedule as synced with the server.
  Future<void> markAsSynced(String id, DateTime serverUpdatedAt) async {
    final schedule = getScheduleById(id);
    if (schedule == null) return;

    schedule.markAsSynced(serverUpdatedAt);
    await schedule.save();
  }

  /// Applies a server update to a local schedule.
  Future<void> applyServerUpdate(Map<String, dynamic> serverData) async {
    final id = serverData['id'] as String;
    final existing = getScheduleById(id);

    final serverUpdatedAt = serverData['updated_at'] != null
        ? DateTime.tryParse(serverData['updated_at'] as String)
        : DateTime.now();

    if (existing != null) {
      // Check if server version is newer
      if (existing.serverUpdatedAt != null &&
          serverUpdatedAt != null &&
          !serverUpdatedAt.isAfter(existing.serverUpdatedAt!)) {
        return;
      }

      // Update existing schedule
      existing.timesPerDay =
          serverData['times_per_day'] as int? ?? existing.timesPerDay;
      existing.scheduledTimes =
          (serverData['scheduled_times'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          existing.scheduledTimes;
      existing.foodType =
          serverData['food_type'] as String? ?? existing.foodType;
      existing.portionHint = serverData['portion_hint'] as String?;
      existing.synced = true;
      existing.serverUpdatedAt = serverUpdatedAt;
      existing.updatedAt = serverUpdatedAt;
      await existing.save();
    } else {
      // Create new schedule from server data
      final schedule = FeedingScheduleModel.fromJson(serverData);
      await saveSchedule(schedule);
    }
  }

  // ============ Utility Methods ============

  /// Clears all schedules from local storage.
  Future<void> clearAll() async {
    await _schedules.clear();
  }

  /// Deletes schedules for a specific aquarium.
  Future<void> deleteSchedulesByAquariumId(String aquariumId) async {
    final schedules = _schedules.values
        .whereType<FeedingScheduleModel>()
        .where((s) => s.aquariumId == aquariumId)
        .toList();
    for (final schedule in schedules) {
      await _schedules.delete(schedule.id);
    }
  }
}
