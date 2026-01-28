import 'package:equatable/equatable.dart';

import 'package:fishfeed/domain/entities/feeding_status.dart';

/// Domain entity representing a scheduled feeding for Today View.
///
/// Combines schedule information with completion status for display
/// in the home screen's Today View.
class ScheduledFeeding extends Equatable {
  const ScheduledFeeding({
    required this.id,
    required this.scheduledTime,
    required this.aquariumId,
    required this.aquariumName,
    this.fishId,
    this.fishName,
    this.speciesName,
    required this.status,
    this.foodType,
    this.portionGrams,
    this.completedAt,
    this.completedBy,
    this.completedByName,
    this.completedByAvatar,
  });

  /// Unique identifier for this scheduled feeding.
  final String id;

  /// Scheduled time for this feeding.
  final DateTime scheduledTime;

  /// ID of the aquarium for this feeding.
  final String aquariumId;

  /// Name of the aquarium for display.
  final String aquariumName;

  /// ID of the specific fish (optional, can be whole aquarium).
  final String? fishId;

  /// Name of the fish for display.
  final String? fishName;

  /// Species name for display.
  final String? speciesName;

  /// Current status of this feeding.
  final FeedingStatus status;

  /// Type of food for this feeding.
  final String? foodType;

  /// Portion size in grams.
  final double? portionGrams;

  /// When the feeding was marked as completed (if fed).
  final DateTime? completedAt;

  /// User ID of who completed the feeding (for family mode).
  final String? completedBy;

  /// Display name of who completed the feeding.
  final String? completedByName;

  /// Avatar URL of who completed the feeding.
  final String? completedByAvatar;

  /// Display name for the feeding target.
  ///
  /// Returns fish name if available, otherwise aquarium name.
  String get displayName {
    if (fishName != null && fishName!.isNotEmpty) {
      return fishName!;
    }
    if (speciesName != null && speciesName!.isNotEmpty) {
      return speciesName!;
    }
    return aquariumName;
  }

  /// Time period of the day for grouping.
  ///
  /// Returns 'morning' (before 12:00), 'afternoon' (12:00-18:00),
  /// or 'evening' (after 18:00).
  String get timePeriod {
    final hour = scheduledTime.hour;
    if (hour < 12) {
      return 'morning';
    } else if (hour < 18) {
      return 'afternoon';
    } else {
      return 'evening';
    }
  }

  /// Creates a copy with updated fields.
  ScheduledFeeding copyWith({
    String? id,
    DateTime? scheduledTime,
    String? aquariumId,
    String? aquariumName,
    String? fishId,
    String? fishName,
    String? speciesName,
    FeedingStatus? status,
    String? foodType,
    double? portionGrams,
    DateTime? completedAt,
    String? completedBy,
    String? completedByName,
    String? completedByAvatar,
  }) {
    return ScheduledFeeding(
      id: id ?? this.id,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      aquariumId: aquariumId ?? this.aquariumId,
      aquariumName: aquariumName ?? this.aquariumName,
      fishId: fishId ?? this.fishId,
      fishName: fishName ?? this.fishName,
      speciesName: speciesName ?? this.speciesName,
      status: status ?? this.status,
      foodType: foodType ?? this.foodType,
      portionGrams: portionGrams ?? this.portionGrams,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      completedByName: completedByName ?? this.completedByName,
      completedByAvatar: completedByAvatar ?? this.completedByAvatar,
    );
  }

  @override
  List<Object?> get props => [
        id,
        scheduledTime,
        aquariumId,
        aquariumName,
        fishId,
        fishName,
        speciesName,
        status,
        foodType,
        portionGrams,
        completedAt,
        completedBy,
        completedByName,
        completedByAvatar,
      ];
}
