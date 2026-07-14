import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/constants/species_data.dart';
import 'package:fishfeed/core/di/repository_providers.dart';
import 'package:fishfeed/domain/entities/species.dart';
import 'package:fishfeed/domain/repositories/species_repository.dart';
import 'package:fishfeed/presentation/providers/species_provider.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockSpeciesRepository extends Mock implements SpeciesRepository {}

void main() {
  late MockSpeciesRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockSpeciesRepository();

    // Repository returns null for all species (nothing cached)
    when(() => mockRepository.getCachedSpeciesById(any())).thenReturn(null);

    container = ProviderContainer(
      overrides: [speciesRepositoryProvider.overrideWithValue(mockRepository)],
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

  group('Notifier dispose safety (mounted guards)', () {
    test(
      'loadAllSpecies does not set state after dispose (success path)',
      () async {
        // Empty cache forces the loading branch and an awaited API fetch.
        when(() => mockRepository.getCachedSpecies()).thenReturn(<Species>[]);
        when(() => mockRepository.fetchAllSpecies()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return <Species>[];
        });

        final notifier = SpeciesListNotifier(repository: mockRepository);
        // Drain the constructor-triggered load so it settles while mounted and
        // cannot error after dispose; the only in-flight load will be ours.
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Start a fresh load, then dispose during its async gap.
        final future = notifier.loadAllSpecies();
        notifier.dispose();

        // Without the mounted guard after the await, the post-await `state =`
        // throws "Tried to use SpeciesListNotifier after dispose was called",
        // completing the future with an error instead of completing normally.
        await expectLater(future, completes);
      },
    );

    test(
      'loadAllSpecies does not set state after dispose (error/catch path)',
      () async {
        when(() => mockRepository.getCachedSpecies()).thenReturn(<Species>[]);
        when(() => mockRepository.fetchAllSpecies()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          throw Exception('network down');
        });

        final notifier = SpeciesListNotifier(repository: mockRepository);
        // Drain the constructor-triggered load (which also errors) while still
        // mounted so it does not raise an unhandled error after dispose.
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final future = notifier.loadAllSpecies();
        notifier.dispose();

        // Without the guard at the top of the catch block, the post-await
        // `state =` inside catch throws the same "used after dispose" error.
        await expectLater(future, completes);
      },
    );
  });
}
