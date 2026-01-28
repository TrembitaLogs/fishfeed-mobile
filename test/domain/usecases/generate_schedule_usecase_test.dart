import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/domain/entities/species.dart';
import 'package:fishfeed/domain/usecases/generate_schedule_usecase.dart';
import 'package:fishfeed/presentation/providers/onboarding_provider.dart';

void main() {
  late GenerateScheduleUseCase useCase;

  setUp(() {
    useCase = const GenerateScheduleUseCase();
  });

  group('GenerateScheduleUseCase', () {
    group('call', () {
      test('should return empty list when no species selected', () {
        final result = useCase(
          const GenerateScheduleParams(speciesSelections: []),
        );

        expect(result, isEmpty);
      });

      test(
        'should generate schedule for single species with daily feeding',
        () {
          const species = Species(
            id: 'guppy',
            name: 'Guppy',
            feedingFrequency: 'daily',
            foodType: FoodType.flakes,
            defaultPortionGrams: 0.5,
          );

          final result = useCase(
            const GenerateScheduleParams(
              speciesSelections: [
                SpeciesSelection(species: species, quantity: 2),
              ],
            ),
          );

          expect(result.length, 1);
          expect(result[0].speciesId, 'guppy');
          expect(result[0].speciesName, 'Guppy');
          expect(result[0].feedingTimes.length, 1);
          expect(result[0].feedingTimes[0], '09:00');
          expect(result[0].foodType, FoodType.flakes);
          expect(result[0].portionGrams, 1.0); // 0.5 * 2
        },
      );

      test('should generate schedule for species with twice_daily feeding', () {
        const species = Species(
          id: 'betta',
          name: 'Betta',
          feedingFrequency: 'twice_daily',
          foodType: FoodType.pellets,
          defaultPortionGrams: 0.3,
        );

        final result = useCase(
          const GenerateScheduleParams(
            speciesSelections: [
              SpeciesSelection(species: species, quantity: 1),
            ],
          ),
        );

        expect(result.length, 1);
        expect(result[0].feedingTimes.length, 2);
        expect(result[0].feedingTimes[0], '08:00');
        expect(result[0].feedingTimes[1], '20:00');
        expect(result[0].portionGrams, 0.3);
      });

      test(
        'should generate schedule for species with three_times_daily feeding',
        () {
          const species = Species(
            id: 'goldfish',
            name: 'Goldfish',
            feedingFrequency: 'three_times_daily',
            foodType: FoodType.flakes,
            defaultPortionGrams: 1.0,
          );

          final result = useCase(
            const GenerateScheduleParams(
              speciesSelections: [
                SpeciesSelection(species: species, quantity: 3),
              ],
            ),
          );

          expect(result.length, 1);
          expect(result[0].feedingTimes.length, 3);
          expect(result[0].feedingTimes[0], '08:00');
          expect(result[0].feedingTimes[1], '14:00');
          expect(result[0].feedingTimes[2], '20:00');
          expect(result[0].portionGrams, 3.0);
        },
      );

      test('should handle multiple species', () {
        const guppy = Species(
          id: 'guppy',
          name: 'Guppy',
          feedingFrequency: 'daily',
          foodType: FoodType.flakes,
          defaultPortionGrams: 0.5,
        );

        const betta = Species(
          id: 'betta',
          name: 'Betta',
          feedingFrequency: 'twice_daily',
          foodType: FoodType.pellets,
          defaultPortionGrams: 0.3,
        );

        final result = useCase(
          const GenerateScheduleParams(
            speciesSelections: [
              SpeciesSelection(species: guppy, quantity: 2),
              SpeciesSelection(species: betta, quantity: 1),
            ],
          ),
        );

        expect(result.length, 2);
        expect(result[0].speciesId, 'guppy');
        expect(result[1].speciesId, 'betta');
      });

      test('should use default portion when defaultPortionGrams is null', () {
        const species = Species(
          id: 'unknown',
          name: 'Unknown Fish',
          feedingFrequency: 'daily',
          portionHint: PortionHint.medium,
        );

        final result = useCase(
          const GenerateScheduleParams(
            speciesSelections: [
              SpeciesSelection(species: species, quantity: 1),
            ],
          ),
        );

        expect(result[0].portionGrams, 0.5); // medium = 0.5g
      });

      test('should use small portion hint correctly', () {
        const species = Species(
          id: 'small-fish',
          name: 'Small Fish',
          feedingFrequency: 'daily',
          portionHint: PortionHint.small,
        );

        final result = useCase(
          const GenerateScheduleParams(
            speciesSelections: [
              SpeciesSelection(species: species, quantity: 1),
            ],
          ),
        );

        expect(result[0].portionGrams, 0.3); // small = 0.3g
      });

      test('should use large portion hint correctly', () {
        const species = Species(
          id: 'large-fish',
          name: 'Large Fish',
          feedingFrequency: 'daily',
          portionHint: PortionHint.large,
        );

        final result = useCase(
          const GenerateScheduleParams(
            speciesSelections: [
              SpeciesSelection(species: species, quantity: 1),
            ],
          ),
        );

        expect(result[0].portionGrams, 1.0); // large = 1.0g
      });

      test('should default to flakes when foodType is null', () {
        const species = Species(
          id: 'fish',
          name: 'Fish',
          feedingFrequency: 'daily',
        );

        final result = useCase(
          const GenerateScheduleParams(
            speciesSelections: [
              SpeciesSelection(species: species, quantity: 1),
            ],
          ),
        );

        expect(result[0].foodType, FoodType.flakes);
      });

      test('should default to daily feeding when feedingFrequency is null', () {
        const species = Species(id: 'fish', name: 'Fish');

        final result = useCase(
          const GenerateScheduleParams(
            speciesSelections: [
              SpeciesSelection(species: species, quantity: 1),
            ],
          ),
        );

        expect(result[0].feedingTimes.length, 1);
        expect(result[0].feedingTimes[0], '09:00');
      });

      test('should handle every_other_day as single daily feeding', () {
        const species = Species(
          id: 'fish',
          name: 'Fish',
          feedingFrequency: 'every_other_day',
        );

        final result = useCase(
          const GenerateScheduleParams(
            speciesSelections: [
              SpeciesSelection(species: species, quantity: 1),
            ],
          ),
        );

        expect(result[0].feedingTimes.length, 1);
        expect(result[0].feedingTimes[0], '09:00');
      });
    });

    group('mergeToTimeSlots', () {
      test('should merge species with same feeding time', () {
        const guppy = Species(
          id: 'guppy',
          name: 'Guppy',
          feedingFrequency: 'twice_daily',
          foodType: FoodType.flakes,
          defaultPortionGrams: 0.5,
        );

        const betta = Species(
          id: 'betta',
          name: 'Betta',
          feedingFrequency: 'twice_daily',
          foodType: FoodType.pellets,
          defaultPortionGrams: 0.3,
        );

        final schedule = useCase(
          const GenerateScheduleParams(
            speciesSelections: [
              SpeciesSelection(species: guppy, quantity: 1),
              SpeciesSelection(species: betta, quantity: 1),
            ],
          ),
        );

        final mergedSlots = useCase.mergeToTimeSlots(schedule);

        // Both have 08:00 and 20:00 feeding times
        expect(mergedSlots.length, 2);
        expect(mergedSlots[0].time, '08:00');
        expect(mergedSlots[0].species.length, 2);
        expect(mergedSlots[1].time, '20:00');
        expect(mergedSlots[1].species.length, 2);
      });

      test('should separate species with different feeding times', () {
        const guppy = Species(
          id: 'guppy',
          name: 'Guppy',
          feedingFrequency: 'daily', // 09:00
          foodType: FoodType.flakes,
          defaultPortionGrams: 0.5,
        );

        const betta = Species(
          id: 'betta',
          name: 'Betta',
          feedingFrequency: 'twice_daily', // 08:00, 20:00
          foodType: FoodType.pellets,
          defaultPortionGrams: 0.3,
        );

        final schedule = useCase(
          const GenerateScheduleParams(
            speciesSelections: [
              SpeciesSelection(species: guppy, quantity: 1),
              SpeciesSelection(species: betta, quantity: 1),
            ],
          ),
        );

        final mergedSlots = useCase.mergeToTimeSlots(schedule);

        // Three different times: 08:00, 09:00, 20:00
        expect(mergedSlots.length, 3);
        expect(mergedSlots[0].time, '08:00');
        expect(mergedSlots[0].species.length, 1);
        expect(mergedSlots[0].species[0].speciesId, 'betta');
        expect(mergedSlots[1].time, '09:00');
        expect(mergedSlots[1].species.length, 1);
        expect(mergedSlots[1].species[0].speciesId, 'guppy');
        expect(mergedSlots[2].time, '20:00');
        expect(mergedSlots[2].species.length, 1);
        expect(mergedSlots[2].species[0].speciesId, 'betta');
      });

      test('should sort merged slots by time', () {
        const guppy = Species(
          id: 'guppy',
          name: 'Guppy',
          feedingFrequency: 'three_times_daily', // 08:00, 14:00, 20:00
          foodType: FoodType.flakes,
          defaultPortionGrams: 0.5,
        );

        final schedule = useCase(
          const GenerateScheduleParams(
            speciesSelections: [SpeciesSelection(species: guppy, quantity: 1)],
          ),
        );

        final mergedSlots = useCase.mergeToTimeSlots(schedule);

        expect(mergedSlots.length, 3);
        expect(mergedSlots[0].time, '08:00');
        expect(mergedSlots[1].time, '14:00');
        expect(mergedSlots[2].time, '20:00');
      });

      test('should return empty list for empty schedule', () {
        final mergedSlots = useCase.mergeToTimeSlots([]);

        expect(mergedSlots, isEmpty);
      });
    });
  });
}
