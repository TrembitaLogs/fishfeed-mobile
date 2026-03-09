import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';

/// Data source for managing feeding logs in local Hive storage.
///
/// Provides CRUD operations for feeding logs with offline-first support.
/// FeedingLog is immutable - once created, it cannot be edited or deleted.
///
/// Example:
/// ```dart
/// final logDs = FeedingLogLocalDataSource();
/// await logDs.save(log);
/// final logs = logDs.getByDateRange(from, to);
/// ```
class FeedingLogLocalDataSource {
  FeedingLogLocalDataSource({Box<dynamic>? feedingLogsBox})
    : _feedingLogsBox = feedingLogsBox;

  final Box<dynamic>? _feedingLogsBox;

  /// Gets the feeding logs box, using the injected box or the default HiveBoxes.
  Box<dynamic> get _feedingLogs => _feedingLogsBox ?? HiveBoxes.feedingLogs;

  // ============ Read Operations ============

  /// Retrieves all feeding logs from local storage.
  ///
  /// Returns all stored logs sorted by scheduledFor (newest first).
  List<FeedingLogModel> getAll() {
    final logs = _feedingLogs.values.whereType<FeedingLogModel>().toList();
    logs.sort((a, b) => b.scheduledFor.compareTo(a.scheduledFor));
    return logs;
  }

  /// Retrieves a single feeding log by its ID.
  ///
  /// [id] - The unique identifier of the log.
  /// Returns `null` if no log with the given ID exists.
  FeedingLogModel? getById(String id) {
    final log = _feedingLogs.get(id);
    if (log is FeedingLogModel) {
      return log;
    }
    return null;
  }

  /// Retrieves feeding logs within a date range.
  ///
  /// [from] - Start date (inclusive).
  /// [to] - End date (inclusive).
  /// Returns logs where scheduledFor is within the range, sorted by scheduledFor.
  List<FeedingLogModel> getByDateRange(DateTime from, DateTime to) {
    final startOfFrom = DateTime(from.year, from.month, from.day);
    final endOfTo = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);

    final logs = _feedingLogs.values
        .whereType<FeedingLogModel>()
        .where(
          (log) =>
              !log.scheduledFor.isBefore(startOfFrom) &&
              !log.scheduledFor.isAfter(endOfTo),
        )
        .toList();

    logs.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return logs;
  }

  /// Retrieves feeding logs for a specific schedule.
  ///
  /// [scheduleId] - The ID of the schedule.
  /// Returns logs for the schedule, sorted by scheduledFor (newest first).
  List<FeedingLogModel> getByScheduleId(String scheduleId) {
    final logs = _feedingLogs.values
        .whereType<FeedingLogModel>()
        .where((log) => log.scheduleId == scheduleId)
        .toList();

    logs.sort((a, b) => b.scheduledFor.compareTo(a.scheduledFor));
    return logs;
  }

  /// Retrieves feeding logs for a specific aquarium.
  ///
  /// [aquariumId] - The ID of the aquarium.
  /// Returns logs for the aquarium, sorted by scheduledFor (newest first).
  List<FeedingLogModel> getByAquariumId(String aquariumId) {
    final logs = _feedingLogs.values
        .whereType<FeedingLogModel>()
        .where((log) => log.aquariumId == aquariumId)
        .toList();

    logs.sort((a, b) => b.scheduledFor.compareTo(a.scheduledFor));
    return logs;
  }

  /// Retrieves feeding logs for a specific aquarium within a date range.
  ///
  /// [aquariumId] - The ID of the aquarium.
  /// [from] - Start date (inclusive).
  /// [to] - End date (inclusive).
  /// Returns logs matching both criteria, sorted by scheduledFor.
  List<FeedingLogModel> getByAquariumIdAndDateRange(
    String aquariumId,
    DateTime from,
    DateTime to,
  ) {
    final startOfFrom = DateTime(from.year, from.month, from.day);
    final endOfTo = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);

    final logs = _feedingLogs.values
        .whereType<FeedingLogModel>()
        .where(
          (log) =>
              log.aquariumId == aquariumId &&
              !log.scheduledFor.isBefore(startOfFrom) &&
              !log.scheduledFor.isAfter(endOfTo),
        )
        .toList();

    logs.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return logs;
  }

  /// Checks if a log exists for a specific schedule and date.
  ///
  /// [scheduleId] - The ID of the schedule.
  /// [date] - The date to check.
  /// Returns `true` if a log exists for this schedule on this date.
  bool hasLogForScheduleAndDate(String scheduleId, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);

    return _feedingLogs.values.whereType<FeedingLogModel>().any((log) {
      final logDateOnly = DateTime(
        log.scheduledFor.year,
        log.scheduledFor.month,
        log.scheduledFor.day,
      );
      return log.scheduleId == scheduleId && logDateOnly == dateOnly;
    });
  }

  /// Gets a log for a specific schedule and date if it exists.
  ///
  /// [scheduleId] - The ID of the schedule.
  /// [date] - The date to check.
  /// Returns the log if found, null otherwise.
  FeedingLogModel? getLogForScheduleAndDate(String scheduleId, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);

    return _feedingLogs.values.whereType<FeedingLogModel>().where((log) {
      final logDateOnly = DateTime(
        log.scheduledFor.year,
        log.scheduledFor.month,
        log.scheduledFor.day,
      );
      return log.scheduleId == scheduleId && logDateOnly == dateOnly;
    }).firstOrNull;
  }

  // ============ Write Operations ============

  /// Saves a feeding log to local storage.
  ///
  /// [log] - The feeding log model to store.
  /// Creates a new record with the log's ID as the key.
  Future<void> save(FeedingLogModel log) async {
    await _feedingLogs.put(log.id, log);
  }

  /// Saves multiple feeding logs to local storage in a batch operation.
  ///
  /// [logs] - List of feeding log models to store.
  Future<void> saveAll(List<FeedingLogModel> logs) async {
    final Map<String, FeedingLogModel> entries = {
      for (final log in logs) log.id: log,
    };
    await _feedingLogs.putAll(entries);
  }

  // ============ Synchronization Methods ============

  /// Retrieves all feeding logs that haven't been synced to the server.
  ///
  /// Returns logs where [synced] is `false`, sorted by creation time (oldest first).
  List<FeedingLogModel> getUnsynced() {
    final logs = _feedingLogs.values
        .whereType<FeedingLogModel>()
        .where((log) => !log.synced)
        .toList();

    // Sort by createdAt (oldest first) to sync in order
    logs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return logs;
  }

  /// Marks a feeding log as synced with the server.
  ///
  /// [id] - The unique identifier of the log.
  /// [serverTime] - The timestamp from the server.
  /// Returns `true` if updated, `false` if log doesn't exist.
  Future<bool> markAsSynced(String id, DateTime serverTime) async {
    final log = getById(id);
    if (log == null) {
      return false;
    }

    final updatedLog = log.copyWith(synced: true, serverUpdatedAt: serverTime);
    await _feedingLogs.put(id, updatedLog);
    return true;
  }

  /// Applies a server update to local storage.
  ///
  /// FeedingLog is mostly immutable (first-write-wins), but we backfill
  /// [actedByUserName] when the server provides it and the local copy
  /// doesn't have it yet. This handles logs synced before the backend
  /// started returning the feeder's display name.
  ///
  /// [serverData] - The data from the server in JSON format.
  Future<void> applyServerUpdate(Map<String, dynamic> serverData) async {
    final id = serverData['id'] as String;
    final existing = getById(id);

    if (existing == null) {
      final log = FeedingLogModel.fromJson(serverData);
      await _feedingLogs.put(log.id, log);
    } else if (existing.actedByUserName == null) {
      // Backfill feeder display name if missing locally
      final serverName = serverData['acted_by_user_name'] as String?;
      if (serverName != null) {
        final updated = existing.copyWith(actedByUserName: serverName);
        await _feedingLogs.put(id, updated);
      }
    }
  }

  /// Returns the count of unsynced logs.
  int getUnsyncedCount() {
    return _feedingLogs.values
        .whereType<FeedingLogModel>()
        .where((log) => !log.synced)
        .length;
  }

  /// Checks if there are any unsynced logs.
  bool hasUnsyncedLogs() {
    return _feedingLogs.values.whereType<FeedingLogModel>().any(
      (log) => !log.synced,
    );
  }

  /// Deletes a single feeding log by its ID.
  ///
  /// [id] - The unique identifier of the log to delete.
  /// Returns `true` if deleted, `false` if no log with the given ID exists.
  Future<bool> delete(String id) async {
    if (!_feedingLogs.containsKey(id)) return false;
    await _feedingLogs.delete(id);
    return true;
  }

  // ============ Utility Methods ============

  /// Clears all feeding logs from local storage.
  ///
  /// Use with caution - this permanently deletes all local log data.
  Future<void> clearAll() async {
    await _feedingLogs.clear();
  }

  /// Returns the total number of logs in local storage.
  int getCount() {
    return _feedingLogs.values.whereType<FeedingLogModel>().length;
  }

  /// Builds a lookup map for O(1) access to logs by schedule and date.
  ///
  /// Key format: '$scheduleId|$year-$month-$day'
  /// Used by FeedingEventGenerator for efficient status determination.
  Map<String, FeedingLogModel> buildLookupMap(List<FeedingLogModel> logs) {
    final map = <String, FeedingLogModel>{};
    for (final log in logs) {
      final dateKey =
          '${log.scheduledFor.year}-'
          '${log.scheduledFor.month.toString().padLeft(2, '0')}-'
          '${log.scheduledFor.day.toString().padLeft(2, '0')}';
      final key = '${log.scheduleId}|$dateKey';
      map[key] = log;
    }
    return map;
  }
}
