import 'package:fishfeed/domain/entities/species.dart';

/// Static database of popular fish species for onboarding.
///
/// Contains predefined species with feeding parameters for quick setup.
abstract final class SpeciesData {
  /// Default species for users who don't know their fish species.
  /// Uses universal safe feeding parameters.
  static const Species defaultSpecies = Species(
    id: 'default',
    name: 'Unknown Species',
    feedingFrequency: 'daily',
    foodType: FoodType.flakes,
    portionHint: PortionHint.small,
    defaultPortionGrams: 0.5,
    optimalTemperature: 25.0,
    careLevel: 'beginner',
  );

  /// Guppy - small, colorful, beginner-friendly fish.
  static const Species guppy = Species(
    id: 'guppy',
    name: 'Guppy',
    feedingFrequency: 'twice_daily',
    foodType: FoodType.flakes,
    portionHint: PortionHint.small,
    defaultPortionGrams: 0.3,
    optimalTemperature: 24.0,
    careLevel: 'beginner',
  );

  /// Neon Tetra - small schooling fish with vibrant colors.
  static const Species neonTetra = Species(
    id: 'neon_tetra',
    name: 'Neon Tetra',
    feedingFrequency: 'twice_daily',
    foodType: FoodType.flakes,
    portionHint: PortionHint.small,
    defaultPortionGrams: 0.2,
    optimalTemperature: 24.0,
    careLevel: 'beginner',
  );

  /// Betta - beautiful fighting fish, prefers solitary life.
  static const Species betta = Species(
    id: 'betta',
    name: 'Betta',
    feedingFrequency: 'daily',
    foodType: FoodType.pellets,
    portionHint: PortionHint.small,
    defaultPortionGrams: 0.4,
    optimalTemperature: 26.0,
    careLevel: 'beginner',
  );

  /// Goldfish - classic cold-water fish.
  static const Species goldfish = Species(
    id: 'goldfish',
    name: 'Goldfish',
    feedingFrequency: 'twice_daily',
    foodType: FoodType.flakes,
    portionHint: PortionHint.medium,
    defaultPortionGrams: 1.0,
    optimalTemperature: 20.0,
    careLevel: 'beginner',
  );

  /// Angelfish - elegant freshwater fish.
  static const Species angelfish = Species(
    id: 'angelfish',
    name: 'Angelfish',
    feedingFrequency: 'twice_daily',
    foodType: FoodType.mixed,
    portionHint: PortionHint.medium,
    defaultPortionGrams: 0.8,
    optimalTemperature: 26.0,
    careLevel: 'intermediate',
  );

  /// Molly - versatile livebearing fish.
  static const Species molly = Species(
    id: 'molly',
    name: 'Molly',
    feedingFrequency: 'twice_daily',
    foodType: FoodType.flakes,
    portionHint: PortionHint.small,
    defaultPortionGrams: 0.4,
    optimalTemperature: 25.0,
    careLevel: 'beginner',
  );

  /// List of all popular species for onboarding selection.
  static const List<Species> popularSpecies = [
    guppy,
    neonTetra,
    betta,
    goldfish,
    angelfish,
    molly,
  ];

  /// All species including default.
  static const List<Species> allSpecies = [
    defaultSpecies,
    ...popularSpecies,
  ];

  /// Finds a species by its ID.
  /// Returns [defaultSpecies] if not found.
  static Species findById(String id) {
    return allSpecies.firstWhere(
      (species) => species.id == id,
      orElse: () => defaultSpecies,
    );
  }

  /// Searches species by name (case-insensitive).
  static List<Species> searchByName(String query) {
    if (query.isEmpty) {
      return popularSpecies;
    }
    final lowerQuery = query.toLowerCase();
    return popularSpecies
        .where((species) => species.name.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
