import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/feeding_log_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/data/models/schedule_model.dart';

/// Types of entities that can be synced.
enum EntityType {
  aquarium,
  fish,
  feedingLog,
  newSchedule,
  streak,
  achievement,
  progress,
  userProfile;

  /// Returns the server-expected snake_case entity type string.
  String get jsonValue {
    return switch (this) {
      EntityType.feedingLog => 'feeding_log',
      EntityType.newSchedule => 'schedule',
      EntityType.userProfile => 'user_profile',
      _ => name,
    };
  }
}

/// Operations that can be performed on entities.
enum SyncOperation { create, update, delete }

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
      'entity_type': entityType.jsonValue,
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
///   feedingLogDs: feedingLogLocalDs,
///   newScheduleDs: scheduleLocalDs,
/// );
///
/// final changes = tracker.collectAllChanges();
/// // Send changes to /sync endpoint
/// ```
class ChangeTracker {
  ChangeTracker({
    required AquariumLocalDataSource aquariumDs,
    required FishLocalDataSource fishDs,
    required AuthLocalDataSource authLocalDs,
    FeedingLogLocalDataSource? feedingLogDs,
    ScheduleLocalDataSource? newScheduleDs,
  }) : _aquariumDs = aquariumDs,
       _fishDs = fishDs,
       _authLocalDs = authLocalDs,
       _feedingLogDs = feedingLogDs,
       _newScheduleDs = newScheduleDs;

  final AquariumLocalDataSource _aquariumDs;
  final FishLocalDataSource _fishDs;
  final AuthLocalDataSource _authLocalDs;
  final FeedingLogLocalDataSource? _feedingLogDs;
  final ScheduleLocalDataSource? _newScheduleDs;

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

    // Collect feeding log changes
    changes.addAll(_collectFeedingLogChanges());

    // Collect schedule changes
    changes.addAll(_collectNewScheduleChanges());

    // Collect user profile changes
    changes.addAll(_collectUserProfileChanges());

    return changes;
  }

  /// Collects changes for a specific entity type.
  List<SyncChange> collectChangesForType(EntityType type) {
    switch (type) {
      case EntityType.aquarium:
        return _collectAquariumChanges();
      case EntityType.fish:
        return _collectFishChanges();
      case EntityType.feedingLog:
        return _collectFeedingLogChanges();
      case EntityType.newSchedule:
        return _collectNewScheduleChanges();
      case EntityType.userProfile:
        return _collectUserProfileChanges();
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
        (_feedingLogDs?.hasUnsyncedLogs() ?? false) ||
        (_newScheduleDs?.hasUnsyncedSchedules() ?? false) ||
        _authLocalDs.getUnsyncedUser() != null;
  }

  /// Returns the count of pending changes.
  int get pendingChangesCount {
    int count = 0;
    count += _aquariumDs.getUnsyncedAquariums().length;
    count += _aquariumDs.getDeletedAquariums().length;
    count += _fishDs.getUnsyncedFish().length;
    count += _fishDs.getDeletedFish().length;
    count += _feedingLogDs?.getUnsyncedCount() ?? 0;
    count += _newScheduleDs?.getUnsyncedCount() ?? 0;
    if (_authLocalDs.getUnsyncedUser() != null) count++;
    return count;
  }

  // ============ Aquarium Changes ============

  List<SyncChange> _collectAquariumChanges() {
    final changes = <SyncChange>[];

    // Get unsynced aquariums (new or modified)
    final unsyncedAquariums = _aquariumDs.getUnsyncedAquariums();
    for (final aquarium in unsyncedAquariums) {
      final operation = _determineAquariumOperation(aquarium);
      changes.add(
        SyncChange(
          entityType: EntityType.aquarium,
          entityId: aquarium.id,
          operation: operation,
          data: _aquariumToSyncData(aquarium),
          clientUpdatedAt: DateTime.now().toUtc(),
        ),
      );
    }

    // Get deleted aquariums
    final deletedAquariums = _aquariumDs.getDeletedAquariums();
    for (final aquarium in deletedAquariums) {
      changes.add(
        SyncChange(
          entityType: EntityType.aquarium,
          entityId: aquarium.id,
          operation: SyncOperation.delete,
          data: {'deleted_at': aquarium.deletedAt?.toIso8601String()},
          clientUpdatedAt: aquarium.deletedAt ?? DateTime.now(),
        ),
      );
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
    final data = <String, dynamic>{
      'id': aquarium.id,
      'owner_id': aquarium.userId,
      'name': aquarium.name,
      'water_type': aquarium.waterType.name,
      'capacity': aquarium.capacity,
    };
    // Only include photo_key if it's an S3 key (not a local:// reference
    // to a file pending upload)
    if (_shouldSyncImageKey(aquarium.photoKey)) {
      data['photo_key'] = aquarium.photoKey;
    }
    return data;
  }

  // ============ Fish Changes ============

  List<SyncChange> _collectFishChanges() {
    final changes = <SyncChange>[];

    // Get unsynced fish (new or modified)
    final unsyncedFish = _fishDs.getUnsyncedFish();
    for (final fish in unsyncedFish) {
      final operation = _determineFishOperation(fish);
      changes.add(
        SyncChange(
          entityType: EntityType.fish,
          entityId: fish.id,
          operation: operation,
          data: _fishToSyncData(fish),
          clientUpdatedAt: DateTime.now().toUtc(),
        ),
      );
    }

    // Get deleted fish
    final deletedFish = _fishDs.getDeletedFish();
    for (final fish in deletedFish) {
      changes.add(
        SyncChange(
          entityType: EntityType.fish,
          entityId: fish.id,
          operation: SyncOperation.delete,
          data: {'deleted_at': fish.deletedAt?.toIso8601String()},
          clientUpdatedAt: fish.deletedAt ?? DateTime.now(),
        ),
      );
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
    final data = <String, dynamic>{
      'id': fish.id,
      'aquarium_id': fish.aquariumId,
      'species_id': fish.speciesId,
      'custom_name': fish.name,
      'quantity': fish.quantity,
    };
    // Only include photo_key if it's an S3 key (not a local:// reference
    // to a file pending upload)
    if (_shouldSyncImageKey(fish.photoKey)) {
      data['photo_key'] = fish.photoKey;
    }
    return data;
  }

  // ============ Feeding Log Changes ============

  List<SyncChange> _collectFeedingLogChanges() {
    final feedingLogDs = _feedingLogDs;
    if (feedingLogDs == null) return [];

    final changes = <SyncChange>[];

    // Get unsynced feeding logs
    final unsyncedLogs = feedingLogDs.getUnsynced();
    for (final log in unsyncedLogs) {
      // FeedingLog is immutable and only created (never updated or deleted)
      changes.add(
        SyncChange(
          entityType: EntityType.feedingLog,
          entityId: log.id,
          operation: SyncOperation.create,
          data: log.toSyncJson(),
          clientUpdatedAt: log.createdAt,
        ),
      );
    }

    return changes;
  }

  // ============ Schedule Changes ============

  List<SyncChange> _collectNewScheduleChanges() {
    final newScheduleDs = _newScheduleDs;
    if (newScheduleDs == null) return [];

    final changes = <SyncChange>[];

    // Get unsynced schedules
    final unsyncedSchedules = newScheduleDs.getUnsynced();
    for (final schedule in unsyncedSchedules) {
      final operation = _determineNewScheduleOperation(schedule);
      changes.add(
        SyncChange(
          entityType: EntityType.newSchedule,
          entityId: schedule.id,
          operation: operation,
          data: schedule.toSyncJson(),
          clientUpdatedAt: schedule.updatedAt,
        ),
      );
    }

    return changes;
  }

  SyncOperation _determineNewScheduleOperation(ScheduleModel schedule) {
    if (schedule.serverUpdatedAt == null) {
      return SyncOperation.create;
    }
    return SyncOperation.update;
  }

  // ============ User Profile Changes ============

  List<SyncChange> _collectUserProfileChanges() {
    final user = _authLocalDs.getUnsyncedUser();
    if (user == null) return [];

    return [
      SyncChange(
        entityType: EntityType.userProfile,
        entityId: user.id,
        operation: SyncOperation.update,
        data: user.toSyncJson(),
        clientUpdatedAt: DateTime.now().toUtc(),
      ),
    ];
  }

  /// Returns true if the image key should be included in sync data.
  ///
  /// Keys with the `local://` prefix represent files that are pending
  /// upload to S3 and must never be sent to the server. Only non-null
  /// S3 object keys are synced.
  static bool _shouldSyncImageKey(String? key) {
    return key != null && !key.startsWith('local://');
  }
}
