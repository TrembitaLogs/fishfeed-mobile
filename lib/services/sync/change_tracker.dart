import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/datasources/local/feeding_schedule_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/feeding_event_model.dart';
import 'package:fishfeed/data/models/feeding_schedule_model.dart';
import 'package:fishfeed/data/models/fish_model.dart';

/// Types of entities that can be synced.
enum EntityType {
  aquarium,
  fish,
  event,
  schedule,
  streak,
  achievement,
  progress,
}

/// Operations that can be performed on entities.
enum SyncOperation {
  create,
  update,
  delete,
}

/// Represents a single change to be synced to the server.
///
/// Contains the entity type, ID, operation, data, and timestamp.
class SyncChange {
  const SyncChange({
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.data,
    required this.clientUpdatedAt,
  });

  /// Type of entity being changed.
  final EntityType entityType;

  /// ID of the entity.
  final String entityId;

  /// Operation being performed.
  final SyncOperation operation;

  /// Data payload for the change.
  final Map<String, dynamic> data;

  /// When the change was made locally.
  final DateTime clientUpdatedAt;

  /// Converts this change to JSON for the API.
  Map<String, dynamic> toJson() {
    return {
      'entity_type': entityType.name,
      'entity_id': entityId,
      'operation': operation.name,
      'data': data,
      'client_updated_at': clientUpdatedAt.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'SyncChange(${entityType.name}:$entityId, ${operation.name})';
}

/// Collects local changes from all datasources for synchronization.
///
/// This class is responsible for gathering unsynced, modified, and deleted
/// entities from all local datasources and formatting them into a standard
/// format for the unified sync endpoint.
///
/// Example:
/// ```dart
/// final tracker = ChangeTracker(
///   aquariumDs: aquariumLocalDs,
///   fishDs: fishLocalDs,
///   feedingDs: feedingLocalDs,
///   scheduleDs: scheduleLocalDs,
/// );
///
/// final changes = tracker.collectAllChanges();
/// // Send changes to /sync endpoint
/// ```
class ChangeTracker {
  ChangeTracker({
    required AquariumLocalDataSource aquariumDs,
    required FishLocalDataSource fishDs,
    required FeedingLocalDataSource feedingDs,
    FeedingScheduleLocalDataSource? scheduleDs,
  })  : _aquariumDs = aquariumDs,
        _fishDs = fishDs,
        _feedingDs = feedingDs,
        _scheduleDs = scheduleDs;

  final AquariumLocalDataSource _aquariumDs;
  final FishLocalDataSource _fishDs;
  final FeedingLocalDataSource _feedingDs;
  final FeedingScheduleLocalDataSource? _scheduleDs;

  /// Collects all local changes that need to be synced.
  ///
  /// Returns a list of [SyncChange] objects containing:
  /// - New entities (not yet synced to server)
  /// - Modified entities (updatedAt > serverUpdatedAt)
  /// - Deleted entities (soft deleted but not synced)
  List<SyncChange> collectAllChanges() {
    final changes = <SyncChange>[];

    // Collect aquarium changes
    changes.addAll(_collectAquariumChanges());

    // Collect fish changes
    changes.addAll(_collectFishChanges());

    // Collect feeding event changes
    changes.addAll(_collectFeedingEventChanges());

    // Collect schedule changes
    changes.addAll(_collectScheduleChanges());

    return changes;
  }

  /// Collects changes for a specific entity type.
  List<SyncChange> collectChangesForType(EntityType type) {
    switch (type) {
      case EntityType.aquarium:
        return _collectAquariumChanges();
      case EntityType.fish:
        return _collectFishChanges();
      case EntityType.event:
        return _collectFeedingEventChanges();
      case EntityType.schedule:
        return _collectScheduleChanges();
      case EntityType.streak:
      case EntityType.achievement:
      case EntityType.progress:
        // These are typically server-managed, but can be extended
        return [];
    }
  }

  /// Whether there are any changes that need to be synced.
  bool get hasChanges {
    return _aquariumDs.getUnsyncedAquariums().isNotEmpty ||
        _aquariumDs.getDeletedAquariums().isNotEmpty ||
        _fishDs.getUnsyncedFish().isNotEmpty ||
        _fishDs.getDeletedFish().isNotEmpty ||
        _feedingDs.getUnsyncedEvents().isNotEmpty ||
        _feedingDs.getDeletedEvents().isNotEmpty ||
        (_scheduleDs?.getUnsyncedSchedules().isNotEmpty ?? false);
  }

  /// Returns the count of pending changes.
  int get pendingChangesCount {
    int count = 0;
    count += _aquariumDs.getUnsyncedAquariums().length;
    count += _aquariumDs.getDeletedAquariums().length;
    count += _fishDs.getUnsyncedFish().length;
    count += _fishDs.getDeletedFish().length;
    count += _feedingDs.getUnsyncedEvents().length;
    count += _feedingDs.getDeletedEvents().length;
    count += _scheduleDs?.getUnsyncedSchedules().length ?? 0;
    return count;
  }

  // ============ Aquarium Changes ============

  List<SyncChange> _collectAquariumChanges() {
    final changes = <SyncChange>[];

    // Get unsynced aquariums (new or modified)
    final unsyncedAquariums = _aquariumDs.getUnsyncedAquariums();
    for (final aquarium in unsyncedAquariums) {
      final operation = _determineAquariumOperation(aquarium);
      changes.add(SyncChange(
        entityType: EntityType.aquarium,
        entityId: aquarium.id,
        operation: operation,
        data: _aquariumToSyncData(aquarium),
        clientUpdatedAt: DateTime.now().toUtc(),
      ));
    }

    // Get deleted aquariums
    final deletedAquariums = _aquariumDs.getDeletedAquariums();
    for (final aquarium in deletedAquariums) {
      changes.add(SyncChange(
        entityType: EntityType.aquarium,
        entityId: aquarium.id,
        operation: SyncOperation.delete,
        data: {'deleted_at': aquarium.deletedAt?.toIso8601String()},
        clientUpdatedAt: aquarium.deletedAt ?? DateTime.now(),
      ));
    }

    return changes;
  }

  SyncOperation _determineAquariumOperation(AquariumModel aquarium) {
    // If serverUpdatedAt is null, it's a new entity
    if (aquarium.serverUpdatedAt == null) {
      return SyncOperation.create;
    }
    return SyncOperation.update;
  }

  Map<String, dynamic> _aquariumToSyncData(AquariumModel aquarium) {
    return {
      'id': aquarium.id,
      'owner_id': aquarium.userId,
      'name': aquarium.name,
      'water_type': aquarium.waterType.name,
      'capacity': aquarium.capacity,
      'image_url': aquarium.imageUrl,
    };
  }

  // ============ Fish Changes ============

  List<SyncChange> _collectFishChanges() {
    final changes = <SyncChange>[];

    // Get unsynced fish (new or modified)
    final unsyncedFish = _fishDs.getUnsyncedFish();
    for (final fish in unsyncedFish) {
      final operation = _determineFishOperation(fish);
      changes.add(SyncChange(
        entityType: EntityType.fish,
        entityId: fish.id,
        operation: operation,
        data: _fishToSyncData(fish),
        clientUpdatedAt: DateTime.now().toUtc(),
      ));
    }

    // Get deleted fish
    final deletedFish = _fishDs.getDeletedFish();
    for (final fish in deletedFish) {
      changes.add(SyncChange(
        entityType: EntityType.fish,
        entityId: fish.id,
        operation: SyncOperation.delete,
        data: {'deleted_at': fish.deletedAt?.toIso8601String()},
        clientUpdatedAt: fish.deletedAt ?? DateTime.now(),
      ));
    }

    return changes;
  }

  SyncOperation _determineFishOperation(FishModel fish) {
    if (fish.serverUpdatedAt == null) {
      return SyncOperation.create;
    }
    return SyncOperation.update;
  }

  Map<String, dynamic> _fishToSyncData(FishModel fish) {
    return {
      'id': fish.id,
      'aquarium_id': fish.aquariumId,
      'species_id': fish.speciesId,
      'custom_name': fish.name,
      'quantity': fish.quantity,
    };
  }

  // ============ Feeding Event Changes ============

  List<SyncChange> _collectFeedingEventChanges() {
    final changes = <SyncChange>[];

    // Build set of deleted fish IDs to filter out their events
    final deletedFishIds = _fishDs
        .getDeletedFish()
        .map((f) => f.id)
        .toSet();

    // Get unsynced events (new or modified)
    final unsyncedEvents = _feedingDs.getUnsyncedEvents();
    for (final event in unsyncedEvents) {
      // Skip events for deleted fish - they should not be synced
      if (deletedFishIds.contains(event.fishId)) {
        continue;
      }

      final operation = _determineEventOperation(event);
      changes.add(SyncChange(
        entityType: EntityType.event,
        entityId: event.id,
        operation: operation,
        data: _eventToSyncData(event),
        clientUpdatedAt: DateTime.now().toUtc(),
      ));
    }

    // Get deleted events
    final deletedEvents = _feedingDs.getDeletedEvents();
    for (final event in deletedEvents) {
      changes.add(SyncChange(
        entityType: EntityType.event,
        entityId: event.id,
        operation: SyncOperation.delete,
        data: {'deleted_at': event.deletedAt?.toIso8601String()},
        clientUpdatedAt: event.deletedAt ?? DateTime.now(),
      ));
    }

    return changes;
  }

  SyncOperation _determineEventOperation(FeedingEventModel event) {
    if (event.serverUpdatedAt == null) {
      return SyncOperation.create;
    }
    return SyncOperation.update;
  }

  Map<String, dynamic> _eventToSyncData(FeedingEventModel event) {
    return {
      'id': event.id,
      'aquarium_id': event.aquariumId,
      'fish_id': event.fishId.isNotEmpty ? event.fishId : null,
      'scheduled_at': event.feedingTime.toIso8601String(),
      'status': event.completedBy != null ? 'completed' : 'pending',
      'completed_at': event.completedBy != null
          ? event.feedingTime.toIso8601String()
          : null,
      'completed_by': event.completedBy,
      'notes': event.notes,
    };
  }

  // ============ Schedule Changes ============

  List<SyncChange> _collectScheduleChanges() {
    final scheduleDs = _scheduleDs;
    if (scheduleDs == null) return [];

    final changes = <SyncChange>[];

    // Get unsynced schedules
    final unsyncedSchedules = scheduleDs.getUnsyncedSchedules();
    for (final schedule in unsyncedSchedules) {
      final operation = _determineScheduleOperation(schedule);
      changes.add(SyncChange(
        entityType: EntityType.schedule,
        entityId: schedule.id,
        operation: operation,
        data: schedule.toSyncJson(),
        clientUpdatedAt: DateTime.now().toUtc(),
      ));
    }

    return changes;
  }

  SyncOperation _determineScheduleOperation(FeedingScheduleModel schedule) {
    if (schedule.serverUpdatedAt == null) {
      return SyncOperation.create;
    }
    return SyncOperation.update;
  }
}
