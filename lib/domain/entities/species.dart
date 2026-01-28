import 'package:equatable/equatable.dart';

/// Food type for fish species.
enum FoodType {
  flakes,
  pellets,
  live,
  frozen,
  mixed,
}

/// Portion size hint for feeding.
enum PortionHint {
  small,
  medium,
  large,
}

/// Domain entity representing a fish species.
///
/// Contains reference data about different fish species including
/// care requirements and feeding information.
class Species extends Equatable {
  const Species({
    required this.id,
    required this.name,
    this.imageAsset,
    this.imageUrl,
    this.feedingFrequency,
    this.foodType,
    this.portionHint,
    this.defaultPortionGrams,
    this.optimalTemperature,
    this.careLevel,
  });

  /// Unique identifier for this species.
  final String id;

  /// Common name of the species.
  final String name;

  /// Path to the image asset for this species (local).
  final String? imageAsset;

  /// URL to the image for this species (remote).
  final String? imageUrl;

  /// Recommended feeding frequency (e.g., 'twice_daily', 'daily', 'every_other_day').
  final String? feedingFrequency;

  /// Type of food recommended for this species.
  final FoodType? foodType;

  /// Suggested portion size hint.
  final PortionHint? portionHint;

  /// Default portion size in grams.
  final double? defaultPortionGrams;

  /// Optimal water temperature in Celsius.
  final double? optimalTemperature;

  /// Care difficulty level (e.g., 'beginner', 'intermediate', 'advanced').
  final String? careLevel;

  /// Creates a copy with updated fields.
  Species copyWith({
    String? id,
    String? name,
    String? imageAsset,
    String? imageUrl,
    String? feedingFrequency,
    FoodType? foodType,
    PortionHint? portionHint,
    double? defaultPortionGrams,
    double? optimalTemperature,
    String? careLevel,
  }) {
    return Species(
      id: id ?? this.id,
      name: name ?? this.name,
      imageAsset: imageAsset ?? this.imageAsset,
      imageUrl: imageUrl ?? this.imageUrl,
      feedingFrequency: feedingFrequency ?? this.feedingFrequency,
      foodType: foodType ?? this.foodType,
      portionHint: portionHint ?? this.portionHint,
      defaultPortionGrams: defaultPortionGrams ?? this.defaultPortionGrams,
      optimalTemperature: optimalTemperature ?? this.optimalTemperature,
      careLevel: careLevel ?? this.careLevel,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        imageAsset,
        imageUrl,
        feedingFrequency,
        foodType,
        portionHint,
        defaultPortionGrams,
        optimalTemperature,
        careLevel,
      ];
}
