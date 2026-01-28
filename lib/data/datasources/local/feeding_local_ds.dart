import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/feeding_event_model.dart';

/// Data source for managing feeding events in local Hive storage.
///
/// Provides CRUD operations for feeding events with offline-first support.
/// Tracks synchronization status for each event to enable background sync.
///
/// Example:
/// ```dart
/// final feedingDs = FeedingLocalDataSource();
/// await feedingDs.createFeedingEvent(event);
/// final events = feedingDs.getFeedingEvents('aquarium_123');
/// ```
class FeedingLocalDataSource {
  FeedingLocalDataSource({Box<dynamic>? feedingEventsBox})
      : _feedingEventsBox = feedingEventsBox;

  final Box<dynamic>? _feedingEventsBox;

  /// Gets the feeding events box, using the injected box or the default HiveBoxes.
  Box<dynamic> get _feedingEvents =>
      _feedingEventsBox ?? HiveBoxes.feedingEvents;

  // ============ CRUD Operations ============

  /// Creates a new feeding event in local storage.
  ///
  /// [event] - The feeding event model to store.
  /// The event is stored with its [id] as the key.
  Future<void> createFeedingEvent(FeedingEventModel event) async {
    await _feedingEvents.put(event.id, event);
  }

  /// Retrieves all feeding events for a specific aquarium.
  ///
  /// [aquariumId] - The ID of the aquarium to filter by.
  /// Returns a list of feeding events sorted by feeding time (newest first).
  /// Excludes soft-deleted events.
  List<FeedingEventModel> getFeedingEvents(String aquariumId) {
    final events = _feedingEvents.values
        .whereType<FeedingEventModel>()
        .where((event) => event.aquariumId == aquariumId && !event.isDeleted)
        .toList();

    events.sort((a, b) => b.feedingTime.compareTo(a.feedingTime));
    return events;
  }

  /// Retrieves all feeding events for a specific date.
  ///
  /// [date] - The date to filter by (time part is ignored).
  /// Returns a list of feeding events that occurred on the specified date.
  /// Excludes soft-deleted events.
  List<FeedingEventModel> getFeedingEventsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final events = _feedingEvents.values
        .whereType<FeedingEventModel>()
        .where((event) =>
            !event.isDeleted &&
            event.feedingTime.isAfter(startOfDay) &&
            event.feedingTime.isBefore(endOfDay))
        .toList();

    events.sort((a, b) => b.feedingTime.compareTo(a.feedingTime));
    return events;
  }

  /// Retrieves a single feeding event by its ID.
  ///
  /// [id] - The unique identifier of the feeding event.
  /// Returns `null` if no event with the given ID exists.
  FeedingEventModel? getFeedingEventById(String id) {
    final event = _feedingEvents.get(id);
    if (event is FeedingEventModel) {
      return event;
    }
    return null;
  }

  /// Retrieves a single feeding event by its local ID.
  ///
  /// [localId] - The local identifier used in UI.
  /// Returns `null` if no event with the given localId exists.
  FeedingEventModel? getFeedingEventByLocalId(String localId) {
    return _feedingEvents.values
        .whereType<FeedingEventModel>()
        .where((event) => event.localId == localId || event.id == localId)
        .firstOrNull;
  }

  /// Updates an existing feeding event in local storage.
  ///
  /// [event] - The updated feeding event model.
  /// Returns `true` if the event was updated, `false` if it doesn't exist.
  Future<bool> updateFeedingEvent(FeedingEventModel event) async {
    final existing = getFeedingEventById(event.id);
    if (existing == null) {
      return false;
    }
    await _feedingEvents.put(event.id, event);
    return true;
  }

  /// Deletes a feeding event from local storage.
  ///
  /// [id] - The unique identifier of the event to delete.
  /// Returns `true` if the event was deleted, `false` if it didn't exist.
  Future<bool> deleteFeedingEvent(String id) async {
    final existing = getFeedingEventById(id);
    if (existing == null) {
      return false;
    }
    await _feedingEvents.delete(id);
    return true;
  }

  /// Soft deletes all feeding events for a specific fish.
  ///
  /// [fishId] - The ID of the fish whose events should be soft-deleted.
  /// Soft-deleted events will be synced as DELETE operations to the server.
  /// Returns the number of events soft-deleted.
  Future<int> deleteEventsByFishId(String fishId) async {
    final events = _feedingEvents.values
        .whereType<FeedingEventModel>()
        .where((e) => e.fishId == fishId && !e.isDeleted)
        .toList();

    final now = DateTime.now();
    for (final event in events) {
      event.deletedAt = now;
      event.updatedAt = now;
      event.synced = false;
      await event.save();
    }

    return events.length;
  }

  /// Retrieves all feeding events regardless of aquarium.
  ///
  /// Returns all stored feeding events sorted by feeding time (newest first).
  /// Excludes soft-deleted events.
  List<FeedingEventModel> getAllFeedingEvents() {
    final events = _feedingEvents.values
        .whereType<FeedingEventModel>()
        .where((event) => !event.isDeleted)
        .toList();
    events.sort((a, b) => b.feedingTime.compareTo(a.feedingTime));
    return events;
  }

  // ============ Synchronization Methods ============

  /// Retrieves all feeding events that haven't been synced to the server.
  ///
  /// Returns events where [synced] is `false`, sorted by creation time (oldest first)
  /// to ensure events are synced in the order they were created.
  /// Excludes soft-deleted events since they don't need to be synced.
  List<FeedingEventModel> getUnsyncedEvents() {
    final events = _feedingEvents.values
        .whereType<FeedingEventModel>()
        .where((event) => !event.synced && !event.isDeleted)
        .toList();

    // Sort by createdAt (oldest first) to sync in order
    events.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return events;
  }

  /// Marks a single feeding event as synced.
  ///
  /// [id] - The unique identifier of the event to mark as synced.
  /// Returns `true` if the event was updated, `false` if it doesn't exist.
  Future<bool> markAsSynced(String id) async {
    final event = getFeedingEventById(id);
    if (event == null) {
      return false;
    }

    event.synced = true;
    await _feedingEvents.put(id, event);
    return true;
  }

  /// Marks multiple feeding events as synced.
  ///
  /// [ids] - List of event IDs to mark as synced.
  /// Returns the number of events that were successfully marked as synced.
  Future<int> markMultipleAsSynced(List<String> ids) async {
    int count = 0;
    for (final id in ids) {
      final success = await markAsSynced(id);
      if (success) count++;
    }
    return count;
  }

  /// Marks a feeding event as unsynced (for offline modifications).
  ///
  /// [id] - The unique identifier of the event to mark as unsynced.
  /// Returns `true` if the event was updated, `false` if it doesn't exist.
  Future<bool> markAsUnsynced(String id) async {
    final event = getFeedingEventById(id);
    if (event == null) {
      return false;
    }

    event.synced = false;
    await _feedingEvents.put(id, event);
    return true;
  }

  /// Returns the count of unsynced feeding events.
  ///
  /// Excludes soft-deleted events since they don't need to be synced.
  int getUnsyncedCount() {
    return _feedingEvents.values
        .whereType<FeedingEventModel>()
        .where((event) => !event.synced && !event.isDeleted)
        .length;
  }

  /// Saves a feeding event (creates or updates).
  ///
  /// [event] - The feeding event model to save.
  /// This is a convenience method that handles both create and update.
  Future<void> saveEvent(FeedingEventModel event) async {
    await _feedingEvents.put(event.id, event);
  }

  /// Alias for getFeedingEventById for consistency with other datasources.
  FeedingEventModel? getEventById(String id) => getFeedingEventById(id);

  /// Checks if an event already exists for a specific aquarium and time.
  ///
  /// [aquariumId] - The ID of the aquarium.
  /// [feedingTime] - The exact feeding time to check.
  /// Returns `true` if an event exists for this aquarium and time.
  bool hasEventForTime(String aquariumId, DateTime feedingTime) {
    return _feedingEvents.values
        .whereType<FeedingEventModel>()
        .where((event) =>
            !event.isDeleted &&
            event.aquariumId == aquariumId &&
            event.feedingTime.year == feedingTime.year &&
            event.feedingTime.month == feedingTime.month &&
            event.feedingTime.day == feedingTime.day &&
            event.feedingTime.hour == feedingTime.hour &&
            event.feedingTime.minute == feedingTime.minute)
        .isNotEmpty;
  }

  /// Gets all events for a specific aquarium at a specific time.
  ///
  /// [aquariumId] - The ID of the aquarium.
  /// [feedingTime] - The exact feeding time to check.
  /// Returns list of events matching the aquarium and time.
  List<FeedingEventModel> getEventsForTime(String aquariumId, DateTime feedingTime) {
    return _feedingEvents.values
        .whereType<FeedingEventModel>()
        .where((event) =>
            !event.isDeleted &&
            event.aquariumId == aquariumId &&
            event.feedingTime.year == feedingTime.year &&
            event.feedingTime.month == feedingTime.month &&
            event.feedingTime.day == feedingTime.day &&
            event.feedingTime.hour == feedingTime.hour &&
            event.feedingTime.minute == feedingTime.minute)
        .toList();
  }

  // ============ Sync Methods ============

  /// Retrieves all soft-deleted events.
  ///
  /// These events need to be synced as deletions to the server.
  List<FeedingEventModel> getDeletedEvents() {
    return _feedingEvents.values
        .whereType<FeedingEventModel>()
        .where((event) => event.isDeleted)
        .toList();
  }

  /// Soft deletes an event.
  ///
  /// Sets deletedAt to current time instead of removing from storage.
  /// This allows syncing the deletion to the server.
  Future<void> softDelete(String id) async {
    final event = getFeedingEventById(id);
    if (event == null) return;

    event.deletedAt = DateTime.now();
    event.updatedAt = DateTime.now();
    event.synced = false;
    await event.save();
  }

  /// Applies a server update to a local event.
  ///
  /// Updates local data with server data if server version is newer.
  /// [serverData] - The data from the server.
  Future<void> applyServerUpdate(Map<String, dynamic> serverData) async {
    final id = serverData['id'] as String;
    final existing = getFeedingEventById(id);

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

      // Update existing event
      if (serverData['feeding_time'] != null || serverData['scheduled_at'] != null) {
        final timeStr = (serverData['feeding_time'] ?? serverData['scheduled_at']) as String?;
        if (timeStr != null) {
          final parsedTime = DateTime.tryParse(timeStr);
          if (parsedTime != null) {
            existing.feedingTime = parsedTime;
          }
        }
      }
      if (serverData['completed_by'] != null) {
        existing.completedBy = serverData['completed_by'] as String?;
      }
      if (serverData['completed_by_name'] != null) {
        existing.completedByName = serverData['completed_by_name'] as String?;
      }
      if (serverData['completed_by_avatar'] != null) {
        existing.completedByAvatar = serverData['completed_by_avatar'] as String?;
      }
      if (serverData['notes'] != null) {
        existing.notes = serverData['notes'] as String?;
      }
      if (serverData['species_id'] != null) {
        existing.speciesId = serverData['species_id'] as String?;
      }
      existing.synced = true;
      existing.serverUpdatedAt = serverUpdatedAt;
      existing.updatedAt = serverUpdatedAt;
      await existing.save();
    } else {
      // Create new event from server data
      final feedingTimeStr = (serverData['feeding_time'] ?? serverData['scheduled_at']) as String?;
      final feedingTime = feedingTimeStr != null
          ? DateTime.tryParse(feedingTimeStr) ?? DateTime.now()
          : DateTime.now();

      final event = FeedingEventModel(
        id: id,
        fishId: serverData['fish_id'] as String? ?? '',
        aquariumId: serverData['aquarium_id'] as String? ?? '',
        feedingTime: feedingTime,
        speciesId: serverData['species_id'] as String?,
        synced: true,
        createdAt: serverData['created_at'] != null
            ? DateTime.tryParse(serverData['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
        completedBy: serverData['completed_by'] as String?,
        completedByName: serverData['completed_by_name'] as String?,
        completedByAvatar: serverData['completed_by_avatar'] as String?,
        notes: serverData['notes'] as String?,
        serverUpdatedAt: serverUpdatedAt,
        updatedAt: serverUpdatedAt,
      );
      await saveEvent(event);
    }
  }

  /// Permanently removes soft-deleted events that have been synced.
  ///
  /// Call this after confirming deletions have been synced to the server.
  Future<void> purgeSyncedDeletions() async {
    final deleted = getDeletedEvents().where((e) => e.synced).toList();
    for (final event in deleted) {
      await _feedingEvents.delete(event.id);
    }
  }

  /// Deletes an event permanently by ID.
  ///
  /// Alias for deleteFeedingEvent for consistency with UnifiedSyncService.
  Future<bool> deleteEvent(String id) => deleteFeedingEvent(id);

  /// Permanently deletes all feeding events for a specific fish.
  ///
  /// [fishId] - The ID of the fish whose events should be hard-deleted.
  /// Use this when the server has already deleted the fish and its events,
  /// so we don't need to sync the deletions.
  /// Returns the number of events deleted.
  Future<int> hardDeleteEventsByFishId(String fishId) async {
    final events = _feedingEvents.values
        .whereType<FeedingEventModel>()
        .where((e) => e.fishId == fishId)
        .toList();

    for (final event in events) {
      await _feedingEvents.delete(event.id);
    }

    return events.length;
  }

  // ============ Utility Methods ============

  /// Clears all feeding events from local storage.
  ///
  /// Use with caution - this permanently deletes all local feeding data.
  Future<void> clearAll() async {
    await _feedingEvents.clear();
  }

  /// Deletes all feeding events for a specific aquarium.
  ///
  /// [aquariumId] - The ID of the aquarium whose events should be deleted.
  /// Returns the number of events deleted.
  Future<int> deleteEventsByAquarium(String aquariumId) async {
    final events = getFeedingEvents(aquariumId);
    for (final event in events) {
      await _feedingEvents.delete(event.id);
    }
    return events.length;
  }
}
