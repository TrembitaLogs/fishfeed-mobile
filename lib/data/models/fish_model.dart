import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/services/sync/conflict_resolver.dart';

part 'fish_model.g.dart';

/// Hive model for [Fish] entity.
///
/// Stores fish data locally with offline support.
/// Use [toEntity] and [fromEntity] for domain layer conversion.
@HiveType(typeId: 2)
class FishModel extends HiveObject {
  FishModel({
    required this.id,
    required this.aquariumId,
    required this.speciesId,
    this.name,
    this.quantity = 1,
    this.notes,
    required this.addedAt,
    this.synced = false,
    this.updatedAt,
    this.serverUpdatedAt,
    this.deletedAt,
    this.conflictStatusValue = 0,
    this.photoKey,
  });

  /// Creates a model from a domain entity.
  factory FishModel.fromEntity(Fish entity) {
    return FishModel(
      id: entity.id,
      aquariumId: entity.aquariumId,
      speciesId: entity.speciesId,
      name: entity.name,
      quantity: entity.quantity,
      notes: entity.notes,
      addedAt: entity.addedAt,
      synced: entity.synced,
      updatedAt: entity.updatedAt,
      serverUpdatedAt: entity.serverUpdatedAt,
      deletedAt: entity.deletedAt,
      conflictStatusValue: entity.conflictStatus.index,
      photoKey: entity.photoKey,
    );
  }

  /// Unique identifier for this fish record.
  @HiveField(0)
  String id;

  /// ID of the aquarium containing this fish.
  @HiveField(1)
  String aquariumId;

  /// ID of the species from the species database.
  @HiveField(2)
  String speciesId;

  /// Custom name for the fish (optional).
  @HiveField(3)
  String? name;

  /// Number of fish of this type.
  @HiveField(4)
  int quantity;

  /// Additional notes about this fish.
  @HiveField(5)
  String? notes;

  /// When the fish was added to the aquarium.
  @HiveField(6)
  DateTime addedAt;

  /// Whether this fish has been synced to the server.
  @HiveField(7, defaultValue: false)
  bool synced;

  /// When this record was last updated locally.
  @HiveField(8)
  DateTime? updatedAt;

  /// Timestamp from server indicating when it was last updated there.
  ///
  /// Used for conflict resolution with last-write-wins strategy.
  @HiveField(9)
  DateTime? serverUpdatedAt;

  /// When this fish was soft-deleted.
  ///
  /// Null means the fish is not deleted.
  @HiveField(10)
  DateTime? deletedAt;

  /// Stored value of [ConflictStatus] enum.
  ///
  /// Use [conflictStatus] getter/setter for type-safe access.
  @HiveField(11, defaultValue: 0)
  int conflictStatusValue;

  /// S3 object key for fish photo (e.g. "fish/{id}/{uuid}.webp").
  @HiveField(12)
  String? photoKey;

  /// Whether this fish has been soft-deleted.
  bool get isDeleted => deletedAt != null;

  /// Current conflict status for this fish.
  ConflictStatus get conflictStatus =>
      ConflictStatus.values[conflictStatusValue.clamp(
        0,
        ConflictStatus.values.length - 1,
      )];

  set conflictStatus(ConflictStatus value) => conflictStatusValue = value.index;

  /// Whether this fish needs to be synced (modified locally after last server sync).
  bool get needsSync =>
      !synced ||
      (updatedAt != null &&
          serverUpdatedAt != null &&
          updatedAt!.isAfter(serverUpdatedAt!));

  /// Converts this model to a domain entity.
  Fish toEntity() {
    return Fish(
      id: id,
      aquariumId: aquariumId,
      speciesId: speciesId,
      name: name,
      quantity: quantity,
      notes: notes,
      photoKey: photoKey,
      addedAt: addedAt,
      synced: synced,
      updatedAt: updatedAt,
      serverUpdatedAt: serverUpdatedAt,
      deletedAt: deletedAt,
      conflictStatus: conflictStatus,
    );
  }

  /// Converts this model to JSON for sync.
  Map<String, dynamic> toSyncJson() {
    return {
      'id': id,
      'aquarium_id': aquariumId,
      'species_id': speciesId,
      'custom_name': name,
      'quantity': quantity,
      'notes': notes,
      'photo_key': photoKey != null && !photoKey!.startsWith('local://')
          ? photoKey
          : null,
    };
  }
}
