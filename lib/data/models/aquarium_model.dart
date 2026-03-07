import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/services/sync/conflict_resolver.dart';

part 'aquarium_model.g.dart';

/// Hive model for [Aquarium] entity.
///
/// Stores aquarium data locally with offline support.
/// Use [toEntity] and [fromEntity] for domain layer conversion.
@HiveType(typeId: 1)
class AquariumModel extends HiveObject {
  AquariumModel({
    required this.id,
    required this.userId,
    required this.name,
    this.capacity,
    this.waterType = WaterType.freshwater,
    this.photoKey,
    required this.createdAt,
    this.synced = false,
    this.updatedAt,
    this.serverUpdatedAt,
    this.deletedAt,
    this.conflictStatusValue = 0,
  });

  /// Creates a model from a domain entity.
  factory AquariumModel.fromEntity(Aquarium entity) {
    return AquariumModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      capacity: entity.capacity,
      waterType: entity.waterType,
      photoKey: entity.photoKey,
      createdAt: entity.createdAt,
      synced: entity.synced,
      updatedAt: entity.updatedAt,
      serverUpdatedAt: entity.serverUpdatedAt,
      deletedAt: entity.deletedAt,
      conflictStatusValue: entity.conflictStatus.index,
    );
  }

  /// Unique identifier for the aquarium.
  @HiveField(0)
  String id;

  /// ID of the user who owns this aquarium.
  @HiveField(1)
  String userId;

  /// Name of the aquarium.
  @HiveField(2)
  String name;

  /// Capacity in liters. Null if not specified.
  @HiveField(3)
  double? capacity;

  /// Type of water in the aquarium.
  @HiveField(4)
  WaterType waterType;

  /// S3 object key for aquarium photo (e.g. "aquariums/{id}/{uuid}.webp").
  @HiveField(5)
  String? photoKey;

  /// When the aquarium was created.
  @HiveField(6)
  DateTime createdAt;

  /// Whether this aquarium has been synced to the server.
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

  /// When this aquarium was soft-deleted.
  ///
  /// Null means the aquarium is not deleted.
  @HiveField(10)
  DateTime? deletedAt;

  /// Stored value of [ConflictStatus] enum.
  ///
  /// Use [conflictStatus] getter/setter for type-safe access.
  @HiveField(11, defaultValue: 0)
  int conflictStatusValue;

  /// Whether this aquarium has been soft-deleted.
  bool get isDeleted => deletedAt != null;

  /// Current conflict status for this aquarium.
  ConflictStatus get conflictStatus =>
      ConflictStatus.values[conflictStatusValue.clamp(
        0,
        ConflictStatus.values.length - 1,
      )];

  set conflictStatus(ConflictStatus value) => conflictStatusValue = value.index;

  /// Whether this aquarium needs to be synced (modified locally after last server sync).
  bool get needsSync =>
      !synced ||
      (updatedAt != null &&
          serverUpdatedAt != null &&
          updatedAt!.isAfter(serverUpdatedAt!));

  /// Converts this model to a domain entity.
  Aquarium toEntity() {
    return Aquarium(
      id: id,
      userId: userId,
      name: name,
      capacity: capacity,
      waterType: waterType,
      photoKey: photoKey,
      createdAt: createdAt,
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
      'name': name,
      'capacity': capacity,
      'water_type': waterType.name,
      'photo_key': photoKey != null && !photoKey!.startsWith('local://')
          ? photoKey
          : null,
    };
  }
}
