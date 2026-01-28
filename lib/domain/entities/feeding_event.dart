import 'package:equatable/equatable.dart';

import 'package:fishfeed/services/sync/conflict_resolver.dart';

/// Domain entity representing a feeding event.
///
/// Tracks when fish were fed, including amount, food type, and sync status.
class FeedingEvent extends Equatable {
  const FeedingEvent({
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
    this.conflictStatus = ConflictStatus.none,
    this.deletedAt,
  });

  /// Whether this event has been soft-deleted.
  bool get isDeleted => deletedAt != null;

  /// Unique identifier for this feeding event.
  final String id;

  /// ID of the fish that was fed.
  final String fishId;

  /// ID of the aquarium where feeding occurred.
  final String aquariumId;

  /// When the feeding took place.
  final DateTime feedingTime;

  /// ID of the species for this feeding event.
  ///
  /// Used when fish_id is not available (e.g., schedule-based events).
  final String? speciesId;

  /// Amount of food given (in grams or units).
  final double? amount;

  /// Type of food used (e.g., flakes, pellets, live).
  final String? foodType;

  /// Additional notes about the feeding.
  final String? notes;

  /// Whether this event has been synced to the server.
  ///
  /// False by default for offline-first support.
  final bool synced;

  /// When this record was created locally.
  final DateTime createdAt;

  /// Local identifier for offline-created events.
  final String? localId;

  /// User ID of who completed the feeding (for family mode).
  final String? completedBy;

  /// Display name of who completed the feeding.
  final String? completedByName;

  /// Avatar URL of who completed the feeding.
  final String? completedByAvatar;

  /// When this record was last updated locally.
  final DateTime? updatedAt;

  /// Timestamp from server indicating when it was last updated there.
  ///
  /// Used for conflict resolution with last-write-wins strategy.
  final DateTime? serverUpdatedAt;

  /// Current conflict status for this event.
  ///
  /// Tracks whether there's an unresolved conflict with server data.
  final ConflictStatus conflictStatus;

  /// When this event was soft-deleted on the server.
  ///
  /// Null means the event is not deleted.
  final DateTime? deletedAt;

  /// Creates a copy with updated fields.
  FeedingEvent copyWith({
    String? id,
    String? fishId,
    String? aquariumId,
    DateTime? feedingTime,
    String? speciesId,
    double? amount,
    String? foodType,
    String? notes,
    bool? synced,
    DateTime? createdAt,
    String? localId,
    String? completedBy,
    String? completedByName,
    String? completedByAvatar,
    DateTime? updatedAt,
    DateTime? serverUpdatedAt,
    ConflictStatus? conflictStatus,
    DateTime? deletedAt,
  }) {
    return FeedingEvent(
      id: id ?? this.id,
      fishId: fishId ?? this.fishId,
      aquariumId: aquariumId ?? this.aquariumId,
      feedingTime: feedingTime ?? this.feedingTime,
      speciesId: speciesId ?? this.speciesId,
      amount: amount ?? this.amount,
      foodType: foodType ?? this.foodType,
      notes: notes ?? this.notes,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
      localId: localId ?? this.localId,
      completedBy: completedBy ?? this.completedBy,
      completedByName: completedByName ?? this.completedByName,
      completedByAvatar: completedByAvatar ?? this.completedByAvatar,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      conflictStatus: conflictStatus ?? this.conflictStatus,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fishId,
    aquariumId,
    feedingTime,
    speciesId,
    amount,
    foodType,
    notes,
    synced,
    createdAt,
    localId,
    completedBy,
    completedByName,
    completedByAvatar,
    updatedAt,
    serverUpdatedAt,
    conflictStatus,
    deletedAt,
  ];
}
