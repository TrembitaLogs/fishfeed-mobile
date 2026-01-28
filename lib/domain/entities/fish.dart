import 'package:equatable/equatable.dart';

import 'package:fishfeed/services/sync/conflict_resolver.dart';

/// Domain entity representing a fish in an aquarium.
class Fish extends Equatable {
  const Fish({
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
    this.conflictStatus = ConflictStatus.none,
  });

  /// Unique identifier for this fish record.
  final String id;

  /// ID of the aquarium containing this fish.
  final String aquariumId;

  /// ID of the species from the species database.
  final String speciesId;

  /// Custom name for the fish (optional).
  final String? name;

  /// Number of fish of this type.
  final int quantity;

  /// Additional notes about this fish.
  final String? notes;

  /// When the fish was added to the aquarium.
  final DateTime addedAt;

  /// Whether this fish has been synced to the server.
  final bool synced;

  /// When this record was last updated locally.
  final DateTime? updatedAt;

  /// Timestamp from server indicating when it was last updated there.
  final DateTime? serverUpdatedAt;

  /// When this fish was soft-deleted.
  final DateTime? deletedAt;

  /// Current conflict status for this fish.
  final ConflictStatus conflictStatus;

  /// Whether this fish has been soft-deleted.
  bool get isDeleted => deletedAt != null;

  /// Creates a copy with updated fields.
  Fish copyWith({
    String? id,
    String? aquariumId,
    String? speciesId,
    String? name,
    int? quantity,
    String? notes,
    DateTime? addedAt,
    bool? synced,
    DateTime? updatedAt,
    DateTime? serverUpdatedAt,
    DateTime? deletedAt,
    ConflictStatus? conflictStatus,
  }) {
    return Fish(
      id: id ?? this.id,
      aquariumId: aquariumId ?? this.aquariumId,
      speciesId: speciesId ?? this.speciesId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      addedAt: addedAt ?? this.addedAt,
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
        aquariumId,
        speciesId,
        name,
        quantity,
        notes,
        addedAt,
        synced,
        updatedAt,
        serverUpdatedAt,
        deletedAt,
        conflictStatus,
      ];
}
