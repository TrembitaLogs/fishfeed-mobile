import 'package:equatable/equatable.dart';

import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/services/sync/conflict_resolver.dart';

/// Domain entity representing an aquarium.
class Aquarium extends Equatable {
  const Aquarium({
    required this.id,
    required this.userId,
    required this.name,
    this.capacity,
    this.waterType = WaterType.freshwater,
    this.imageUrl,
    required this.createdAt,
    this.synced = false,
    this.updatedAt,
    this.serverUpdatedAt,
    this.deletedAt,
    this.conflictStatus = ConflictStatus.none,
  });

  /// Unique identifier for the aquarium.
  final String id;

  /// ID of the user who owns this aquarium.
  final String userId;

  /// Name of the aquarium.
  final String name;

  /// Capacity in liters. Null if not specified.
  final double? capacity;

  /// Type of water in the aquarium.
  final WaterType waterType;

  /// URL to aquarium image.
  final String? imageUrl;

  /// When the aquarium was created.
  final DateTime createdAt;

  /// Whether this aquarium has been synced to the server.
  final bool synced;

  /// When this record was last updated locally.
  final DateTime? updatedAt;

  /// Timestamp from server indicating when it was last updated there.
  final DateTime? serverUpdatedAt;

  /// When this aquarium was soft-deleted.
  final DateTime? deletedAt;

  /// Current conflict status for this aquarium.
  final ConflictStatus conflictStatus;

  /// Whether this aquarium has been soft-deleted.
  bool get isDeleted => deletedAt != null;

  /// Creates a copy with updated fields.
  Aquarium copyWith({
    String? id,
    String? userId,
    String? name,
    double? capacity,
    WaterType? waterType,
    String? imageUrl,
    DateTime? createdAt,
    bool? synced,
    DateTime? updatedAt,
    DateTime? serverUpdatedAt,
    DateTime? deletedAt,
    ConflictStatus? conflictStatus,
  }) {
    return Aquarium(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      waterType: waterType ?? this.waterType,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      conflictStatus: conflictStatus ?? this.conflictStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        capacity,
        waterType,
        imageUrl,
        createdAt,
        synced,
        updatedAt,
        serverUpdatedAt,
        deletedAt,
        conflictStatus,
      ];
}
