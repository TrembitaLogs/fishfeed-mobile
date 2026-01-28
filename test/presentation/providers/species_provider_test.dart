import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/constants/species_data.dart';
import 'package:fishfeed/data/datasources/local/species_local_ds.dart';
import 'package:fishfeed/presentation/providers/species_provider.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockSpeciesLocalDataSource extends Mock
    implements SpeciesLocalDataSource {}

void main() {
  late MockSpeciesLocalDataSource mockLocalDs;
  late ProviderContainer container;

  setUp(() {
    mockLocalDs = MockSpeciesLocalDataSource();

    // Local DS returns null for all species (nothing cached)
    when(() => mockLocalDs.getSpeciesById(any())).thenReturn(null);

    container = ProviderContainer(
      overrides: [
        speciesLocalDataSourceProvider.overrideWithValue(mockLocalDs),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('speciesNameByIdProvider', () {
    test('returns "Fish" for default species id', () {
      final name = container.read(speciesNameByIdProvider('default'));
      expect(name, equals(SpeciesData.defaultSpecies.name));
    });

    test('returns species name for known hardcoded species', () {
      final name = container.read(speciesNameByIdProvider('guppy'));
      expect(name, equals('Guppy'));
    });

    test('does not return default species name for unknown id', () {
      final name = container.read(speciesNameByIdProvider('bristlenose-pleco'));
      expect(name, isNot(equals(SpeciesData.defaultSpecies.name)));
    });

    test('returns formatted name for hyphen-separated id', () {
      final name = container.read(speciesNameByIdProvider('bristlenose-pleco'));
      expect(name, equals('Bristlenose Pleco'));
    });

    test('returns formatted name for underscore-separated id', () {
      final name = container.read(speciesNameByIdProvider('neon_tetra'));
      expect(name, equals('Neon Tetra'));
    });

    test('returns "Feeding" for empty species id', () {
      final name = container.read(speciesNameByIdProvider(''));
      expect(name, equals('Feeding'));
    });
  });
}
