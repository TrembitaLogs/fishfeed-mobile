import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/domain/entities/species.dart';

part 'species_model.g.dart';

/// Hive adapter for [FoodType] enum.
@HiveType(typeId: 26)
enum FoodTypeModel {
  @HiveField(0)
  flakes,
  @HiveField(1)
  pellets,
  @HiveField(2)
  live,
  @HiveField(3)
  frozen,
  @HiveField(4)
  mixed,
}

/// Hive adapter for [PortionHint] enum.
@HiveType(typeId: 27)
enum PortionHintModel {
  @HiveField(0)
  small,
  @HiveField(1)
  medium,
  @HiveField(2)
  large,
}

/// Extension to convert between domain and model enums.
extension FoodTypeModelExtension on FoodTypeModel {
  FoodType toEntity() {
    switch (this) {
      case FoodTypeModel.flakes:
        return FoodType.flakes;
      case FoodTypeModel.pellets:
        return FoodType.pellets;
      case FoodTypeModel.live:
        return FoodType.live;
      case FoodTypeModel.frozen:
        return FoodType.frozen;
      case FoodTypeModel.mixed:
        return FoodType.mixed;
    }
  }

  static FoodTypeModel fromEntity(FoodType entity) {
    switch (entity) {
      case FoodType.flakes:
        return FoodTypeModel.flakes;
      case FoodType.pellets:
        return FoodTypeModel.pellets;
      case FoodType.live:
        return FoodTypeModel.live;
      case FoodType.frozen:
        return FoodTypeModel.frozen;
      case FoodType.mixed:
        return FoodTypeModel.mixed;
    }
  }
}

/// Extension to convert between domain and model enums.
extension PortionHintModelExtension on PortionHintModel {
  PortionHint toEntity() {
    switch (this) {
      case PortionHintModel.small:
        return PortionHint.small;
      case PortionHintModel.medium:
        return PortionHint.medium;
      case PortionHintModel.large:
        return PortionHint.large;
    }
  }

  static PortionHintModel fromEntity(PortionHint entity) {
    switch (entity) {
      case PortionHint.small:
        return PortionHintModel.small;
      case PortionHint.medium:
        return PortionHintModel.medium;
      case PortionHint.large:
        return PortionHintModel.large;
    }
  }
}

/// Hive model for [Species] entity.
///
/// Stores fish species reference data locally.
/// Use [toEntity] and [fromEntity] for domain layer conversion.
@HiveType(typeId: 7)
class SpeciesModel extends HiveObject {
  SpeciesModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.feedingFrequency,
    this.foodType,
    this.portionHint,
    this.defaultPortionGrams,
    this.optimalTemperature,
    this.careLevel,
  });

  /// Creates a model from a domain entity.
  factory SpeciesModel.fromEntity(Species entity) {
    return SpeciesModel(
      id: entity.id,
      name: entity.name,
      imageUrl: entity.imageUrl,
      feedingFrequency: entity.feedingFrequency,
      foodType: entity.foodType != null
          ? FoodTypeModelExtension.fromEntity(entity.foodType!)
          : null,
      portionHint: entity.portionHint != null
          ? PortionHintModelExtension.fromEntity(entity.portionHint!)
          : null,
      defaultPortionGrams: entity.defaultPortionGrams,
      optimalTemperature: entity.optimalTemperature,
      careLevel: entity.careLevel,
    );
  }

  /// Unique identifier for this species.
  @HiveField(0)
  String id;

  /// Common name of the species.
  @HiveField(1)
  String name;

  /// Recommended feeding frequency (e.g., 'twice_daily', 'daily', 'every_other_day').
  @HiveField(2)
  String? feedingFrequency;

  /// Optimal water temperature in Celsius.
  @HiveField(3)
  double? optimalTemperature;

  /// Care difficulty level (e.g., 'beginner', 'intermediate', 'advanced').
  @HiveField(4)
  String? careLevel;

  // HiveField(5) was imageAsset — removed, index reserved.

  /// Type of food recommended for this species.
  @HiveField(6)
  FoodTypeModel? foodType;

  /// Suggested portion size hint.
  @HiveField(7)
  PortionHintModel? portionHint;

  /// Default portion size in grams.
  @HiveField(8)
  double? defaultPortionGrams;

  /// URL to the image for this species (remote).
  @HiveField(9)
  String? imageUrl;

  /// Converts this model to a domain entity.
  Species toEntity() {
    return Species(
      id: id,
      name: name,
      imageUrl: imageUrl,
      feedingFrequency: feedingFrequency,
      foodType: foodType?.toEntity(),
      portionHint: portionHint?.toEntity(),
      defaultPortionGrams: defaultPortionGrams,
      optimalTemperature: optimalTemperature,
      careLevel: careLevel,
    );
  }
}
