import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/services/sync/conflict_resolver.dart';

part 'feeding_event_model.g.dart';

/// Hive model for [FeedingEvent] entity.
///
/// Stores feeding event data locally with offline sync support.
/// The [synced] field tracks whether this event has been synced to the server.
/// Use [toEntity] and [fromEntity] for domain layer conversion.
@HiveType(typeId: 4)
class FeedingEventModel extends HiveObject {
  FeedingEventModel({
    required this.id,
    required this.fishId,
    required this.aquariumId,
    required this.feedingTime,
    this.speciesId,
    this.amount,
    this.foodType,
    this.notes,
    this.synced = false,
    required this.createdAt,
    this.localId,
    this.completedBy,
    this.completedByName,
    this.completedByAvatar,
    this.updatedAt,
    this.serverUpdatedAt,
    this.conflictStatusValue = 0,
    this.deletedAt,
  });

  /// Creates a model from a domain entity.
  factory FeedingEventModel.fromEntity(FeedingEvent entity) {
    return FeedingEventModel(
      id: entity.id,
      fishId: entity.fishId,
      aquariumId: entity.aquariumId,
      feedingTime: entity.feedingTime,
      speciesId: entity.speciesId,
      amount: entity.amount,
      foodType: entity.foodType,
      notes: entity.notes,
      synced: entity.synced,
      createdAt: entity.createdAt,
      localId: entity.localId,
      completedBy: entity.completedBy,
      completedByName: entity.completedByName,
      completedByAvatar: entity.completedByAvatar,
      updatedAt: entity.updatedAt,
      serverUpdatedAt: entity.serverUpdatedAt,
      conflictStatusValue: entity.conflictStatus.index,
      deletedAt: entity.deletedAt,
    );
  }

  /// Unique identifier for this feeding event.
  @HiveField(0)
  String id;

  /// ID of the fish that was fed.
  @HiveField(1)
  String fishId;

  /// ID of the aquarium where feeding occurred.
  @HiveField(2)
  String aquariumId;

  /// When the feeding took place.
  @HiveField(3)
  DateTime feedingTime;

  /// Amount of food given (in grams or units).
  @HiveField(4)
  double? amount;

  /// Type of food used (e.g., flakes, pellets, live).
  @HiveField(5)
  String? foodType;

  /// Additional notes about the feeding.
  @HiveField(6)
  String? notes;

  /// Whether this event has been synced to the server.
  ///
  /// False by default for offline-first support.
  /// Set to true after successful server synchronization.
  @HiveField(7)
  bool synced;

  /// When this record was created locally.
  @HiveField(8)
  DateTime createdAt;

  /// Local identifier for offline-created events.
  @HiveField(9)
  String? localId;

  /// User ID of who completed the feeding (for family mode).
  @HiveField(10)
  String? completedBy;

  /// Display name of who completed the feeding.
  @HiveField(11)
  String? completedByName;

  /// Avatar URL of who completed the feeding.
  @HiveField(12)
  String? completedByAvatar;

  /// When this record was last updated locally.
  @HiveField(13)
  DateTime? updatedAt;

  /// Timestamp from server indicating when it was last updated there.
  ///
  /// Used for conflict resolution with last-write-wins strategy.
  @HiveField(14)
  DateTime? serverUpdatedAt;

  /// Stored value of [ConflictStatus] enum.
  ///
  /// Use [conflictStatus] getter/setter for type-safe access.
  @HiveField(15)
  int conflictStatusValue;

  /// When this event was soft-deleted on the server.
  ///
  /// Null means the event is not deleted.
  @HiveField(16)
  DateTime? deletedAt;

  /// ID of the species for this feeding event.
  ///
  /// Used when fish_id is not available (e.g., schedule-based events).
  @HiveField(17)
  String? speciesId;

  /// Whether this event has been soft-deleted.
  bool get isDeleted => deletedAt != null;

  /// Current conflict status for this event.
  ConflictStatus get conflictStatus =>
      ConflictStatus.values[conflictStatusValue.clamp(
        0,
        ConflictStatus.values.length - 1,
      )];

  set conflictStatus(ConflictStatus value) => conflictStatusValue = value.index;

  /// Converts this model to a domain entity.
  FeedingEvent toEntity() {
    return FeedingEvent(
      id: id,
      fishId: fishId,
      aquariumId: aquariumId,
      feedingTime: feedingTime,
      speciesId: speciesId,
      amount: amount,
      foodType: foodType,
      notes: notes,
      synced: synced,
      createdAt: createdAt,
      localId: localId,
      completedBy: completedBy,
      completedByName: completedByName,
      completedByAvatar: completedByAvatar,
      updatedAt: updatedAt,
      serverUpdatedAt: serverUpdatedAt,
      conflictStatus: conflictStatus,
      deletedAt: deletedAt,
    );
  }
}
