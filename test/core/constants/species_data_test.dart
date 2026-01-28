import 'package:fishfeed/core/constants/species_data.dart';
import 'package:fishfeed/domain/entities/species.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpeciesData', () {
    group('defaultSpecies', () {
      test('should have valid default species with all required fields', () {
        const species = SpeciesData.defaultSpecies;

        expect(species.id, equals('default'));
        expect(species.name, equals('Unknown Species'));
        // imageAsset is optional and not set for static species data
        expect(species.feedingFrequency, isNotNull);
        expect(species.foodType, isNotNull);
        expect(species.portionHint, isNotNull);
        expect(species.defaultPortionGrams, isNotNull);
        expect(species.defaultPortionGrams, greaterThan(0));
      });

      test('should have safe feeding parameters for unknown species', () {
        const species = SpeciesData.defaultSpecies;

        expect(species.feedingFrequency, equals('daily'));
        expect(species.foodType, equals(FoodType.flakes));
        expect(species.portionHint, equals(PortionHint.small));
      });
    });

    group('popularSpecies', () {
      test('should contain exactly 6 popular species', () {
        expect(SpeciesData.popularSpecies.length, equals(6));
      });

      test('should contain all expected species', () {
        final speciesIds =
            SpeciesData.popularSpecies.map((s) => s.id).toList();

        expect(speciesIds, contains('guppy'));
        expect(speciesIds, contains('neon_tetra'));
        expect(speciesIds, contains('betta'));
        expect(speciesIds, contains('goldfish'));
        expect(speciesIds, contains('angelfish'));
        expect(speciesIds, contains('molly'));
      });

      test('all species should have non-null required fields', () {
        for (final species in SpeciesData.popularSpecies) {
          expect(species.id, isNotEmpty, reason: 'id should not be empty');
          expect(species.name, isNotEmpty, reason: 'name should not be empty');
          // imageAsset is optional and not set for static species data
          expect(species.feedingFrequency, isNotNull,
              reason: '${species.name} should have feedingFrequency');
          expect(species.foodType, isNotNull,
              reason: '${species.name} should have foodType');
          expect(species.portionHint, isNotNull,
              reason: '${species.name} should have portionHint');
          expect(species.defaultPortionGrams, isNotNull,
              reason: '${species.name} should have defaultPortionGrams');
        }
      });

      test('all species should have valid feedingFrequency values', () {
        const validFrequencies = ['daily', 'twice_daily', 'every_other_day'];

        for (final species in SpeciesData.popularSpecies) {
          expect(
            validFrequencies.contains(species.feedingFrequency),
            isTrue,
            reason:
                '${species.name} has invalid feedingFrequency: ${species.feedingFrequency}',
          );
        }
      });

      test('all species should have positive portion grams', () {
        for (final species in SpeciesData.popularSpecies) {
          expect(
            species.defaultPortionGrams,
            greaterThan(0),
            reason: '${species.name} should have positive defaultPortionGrams',
          );
        }
      });

      test('all species should have valid careLevel values', () {
        const validCareLevels = ['beginner', 'intermediate', 'advanced'];

        for (final species in SpeciesData.popularSpecies) {
          if (species.careLevel != null) {
            expect(
              validCareLevels.contains(species.careLevel),
              isTrue,
              reason:
                  '${species.name} has invalid careLevel: ${species.careLevel}',
            );
          }
        }
      });

      test('all species should have unique IDs', () {
        final ids = SpeciesData.popularSpecies.map((s) => s.id).toList();
        final uniqueIds = ids.toSet();

        expect(uniqueIds.length, equals(ids.length),
            reason: 'Species IDs should be unique');
      });
    });

    group('allSpecies', () {
      test('should contain defaultSpecies and all popularSpecies', () {
        expect(SpeciesData.allSpecies.length,
            equals(SpeciesData.popularSpecies.length + 1));
        expect(SpeciesData.allSpecies, contains(SpeciesData.defaultSpecies));

        for (final species in SpeciesData.popularSpecies) {
          expect(SpeciesData.allSpecies, contains(species));
        }
      });
    });

    group('findById', () {
      test('should return correct species for valid ID', () {
        final guppy = SpeciesData.findById('guppy');
        expect(guppy.id, equals('guppy'));
        expect(guppy.name, equals('Guppy'));
      });

      test('should return defaultSpecies for unknown ID', () {
        final unknown = SpeciesData.findById('unknown_species_123');
        expect(unknown, equals(SpeciesData.defaultSpecies));
      });

      test('should return defaultSpecies for empty ID', () {
        final empty = SpeciesData.findById('');
        expect(empty, equals(SpeciesData.defaultSpecies));
      });
    });

    group('searchByName', () {
      test('should return all popular species for empty query', () {
        final results = SpeciesData.searchByName('');
        expect(results.length, equals(SpeciesData.popularSpecies.length));
      });

      test('should find species by exact name', () {
        final results = SpeciesData.searchByName('Guppy');
        expect(results.length, equals(1));
        expect(results.first.id, equals('guppy'));
      });

      test('should find species by partial name (case-insensitive)', () {
        final results = SpeciesData.searchByName('gold');
        expect(results.length, equals(1));
        expect(results.first.id, equals('goldfish'));
      });

      test('should find multiple species matching query', () {
        // Both "Molly" and "Angelfish" contain 'l'
        final results = SpeciesData.searchByName('l');
        expect(results.length, greaterThanOrEqualTo(2));
      });

      test('should return empty list for non-matching query', () {
        final results = SpeciesData.searchByName('xyz123');
        expect(results, isEmpty);
      });

      test('should be case-insensitive', () {
        final upperResults = SpeciesData.searchByName('BETTA');
        final lowerResults = SpeciesData.searchByName('betta');
        final mixedResults = SpeciesData.searchByName('BeTtA');

        expect(upperResults.length, equals(1));
        expect(lowerResults.length, equals(1));
        expect(mixedResults.length, equals(1));
        expect(upperResults.first.id, equals(lowerResults.first.id));
        expect(upperResults.first.id, equals(mixedResults.first.id));
      });
    });

    group('specific species data', () {
      test('Guppy should have correct feeding parameters', () {
        expect(SpeciesData.guppy.feedingFrequency, equals('twice_daily'));
        expect(SpeciesData.guppy.foodType, equals(FoodType.flakes));
        expect(SpeciesData.guppy.portionHint, equals(PortionHint.small));
        expect(SpeciesData.guppy.careLevel, equals('beginner'));
      });

      test('Betta should use pellets', () {
        expect(SpeciesData.betta.foodType, equals(FoodType.pellets));
        expect(SpeciesData.betta.feedingFrequency, equals('daily'));
      });

      test('Goldfish should have medium portion', () {
        expect(SpeciesData.goldfish.portionHint, equals(PortionHint.medium));
      });

      test('Angelfish should be intermediate care level', () {
        expect(SpeciesData.angelfish.careLevel, equals('intermediate'));
        expect(SpeciesData.angelfish.foodType, equals(FoodType.mixed));
      });
    });
  });
}
