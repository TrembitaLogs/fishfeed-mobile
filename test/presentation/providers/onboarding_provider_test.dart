import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/core/constants/species_data.dart';
import 'package:fishfeed/domain/entities/species.dart';
import 'package:fishfeed/presentation/providers/onboarding_provider.dart';

void main() {
  group('OnboardingState', () {
    test('initial state should have currentStep 0 and empty selections', () {
      const state = OnboardingState();

      expect(state.currentStep, 0);
      expect(state.selectedSpecies, isEmpty);
      expect(state.generatedSchedule, isEmpty);
      expect(state.isGeneratingSchedule, false);
    });

    test('canProceed should be false when no aquarium name on step 0', () {
      const state = OnboardingState();

      expect(state.canProceed, false);
    });

    test('canProceed should be true when aquarium name set on step 0', () {
      const state = OnboardingState(
        currentAquariumName: 'My Aquarium',
      );

      expect(state.canProceed, true);
    });

    test('canProceed should be true when species selected on step 1', () {
      const state = OnboardingState(
        currentStep: 1,
        selectedSpecies: [
          SpeciesSelection(species: SpeciesData.guppy),
        ],
      );

      expect(state.canProceed, true);
    });

    test('canProceed should be true when quantities set on step 2', () {
      const state = OnboardingState(
        currentStep: 2,
        selectedSpecies: [
          SpeciesSelection(species: SpeciesData.guppy, quantity: 3),
        ],
      );

      expect(state.canProceed, true);
    });

    test('canProceed should be true when schedule generated on step 3', () {
      const state = OnboardingState(
        currentStep: 3,
        generatedSchedule: [
          GeneratedScheduleEntry(
            speciesId: 'guppy',
            speciesName: 'Guppy',
            feedingTimes: ['08:00', '18:00'],
            foodType: FoodType.flakes,
            portionGrams: 0.6,
          ),
        ],
      );

      expect(state.canProceed, true);
    });

    test('canProceed should always be true on step 4 (add more)', () {
      const state = OnboardingState(currentStep: 4);

      expect(state.canProceed, true);
    });

    test('canGoBack should be false on first step', () {
      const state = OnboardingState();

      expect(state.canGoBack, false);
      expect(state.isFirstStep, true);
    });

    test('canGoBack should be true on second step', () {
      const state = OnboardingState(currentStep: 1);

      expect(state.canGoBack, true);
      expect(state.isFirstStep, false);
    });

    test('isLastStep should be true on step 4', () {
      const state = OnboardingState(currentStep: 4);

      expect(state.isLastStep, true);
    });

    test('isLastStep should be false on step 3', () {
      const state = OnboardingState(currentStep: 3);

      expect(state.isLastStep, false);
    });

    test('copyWith should update specified fields', () {
      const state = OnboardingState();
      final updated = state.copyWith(currentStep: 1);

      expect(updated.currentStep, 1);
      expect(updated.selectedSpecies, isEmpty);
    });

    test('equality should work correctly', () {
      const state1 = OnboardingState();
      const state2 = OnboardingState();
      const state3 = OnboardingState(currentStep: 1);

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });
  });

  group('SpeciesSelection', () {
    test('default quantity should be 1', () {
      const selection = SpeciesSelection(species: SpeciesData.guppy);

      expect(selection.quantity, 1);
    });

    test('copyWith should update quantity', () {
      const selection = SpeciesSelection(species: SpeciesData.guppy);
      final updated = selection.copyWith(quantity: 5);

      expect(updated.quantity, 5);
      expect(updated.species, SpeciesData.guppy);
    });

    test('equality should work correctly', () {
      const selection1 = SpeciesSelection(species: SpeciesData.guppy);
      const selection2 = SpeciesSelection(species: SpeciesData.guppy);
      const selection3 =
          SpeciesSelection(species: SpeciesData.guppy, quantity: 2);

      expect(selection1, equals(selection2));
      expect(selection1, isNot(equals(selection3)));
    });
  });

  group('GeneratedScheduleEntry', () {
    test('equality should work correctly', () {
      const entry1 = GeneratedScheduleEntry(
        speciesId: 'guppy',
        speciesName: 'Guppy',
        feedingTimes: ['08:00', '18:00'],
        foodType: FoodType.flakes,
        portionGrams: 0.6,
      );
      const entry2 = GeneratedScheduleEntry(
        speciesId: 'guppy',
        speciesName: 'Guppy',
        feedingTimes: ['08:00', '18:00'],
        foodType: FoodType.flakes,
        portionGrams: 0.6,
      );
      const entry3 = GeneratedScheduleEntry(
        speciesId: 'betta',
        speciesName: 'Betta',
        feedingTimes: ['09:00'],
        foodType: FoodType.pellets,
        portionGrams: 0.4,
      );

      expect(entry1, equals(entry2));
      expect(entry1, isNot(equals(entry3)));
    });

    test('copyWith should update feeding times', () {
      const entry = GeneratedScheduleEntry(
        speciesId: 'guppy',
        speciesName: 'Guppy',
        feedingTimes: ['08:00', '18:00'],
        foodType: FoodType.flakes,
        portionGrams: 0.6,
      );

      final updated = entry.copyWith(feedingTimes: ['09:00', '19:00']);

      expect(updated.feedingTimes, ['09:00', '19:00']);
      expect(updated.speciesId, 'guppy');
      expect(updated.speciesName, 'Guppy');
      expect(updated.foodType, FoodType.flakes);
      expect(updated.portionGrams, 0.6);
    });

    test('copyWith should preserve other fields when updating one', () {
      const entry = GeneratedScheduleEntry(
        speciesId: 'guppy',
        speciesName: 'Guppy',
        feedingTimes: ['08:00'],
        foodType: FoodType.flakes,
        portionGrams: 0.6,
      );

      final updated = entry.copyWith(portionGrams: 1.0);

      expect(updated.portionGrams, 1.0);
      expect(updated.feedingTimes, ['08:00']);
      expect(updated.speciesId, 'guppy');
    });
  });

  group('OnboardingNotifier', () {
    late OnboardingNotifier notifier;

    setUp(() {
      notifier = OnboardingNotifier();
    });

    test('initial state should be OnboardingState()', () {
      expect(notifier.state, const OnboardingState());
    });

    group('navigation', () {
      test('nextStep should increment currentStep', () {
        notifier.nextStep();

        expect(notifier.state.currentStep, 1);
      });

      test('nextStep should not exceed totalSteps - 1', () {
        notifier.goToStep(4);
        notifier.nextStep();

        expect(notifier.state.currentStep, 4);
      });

      test('previousStep should decrement currentStep', () {
        notifier.goToStep(2);
        notifier.previousStep();

        expect(notifier.state.currentStep, 1);
      });

      test('previousStep should not go below 0', () {
        notifier.previousStep();

        expect(notifier.state.currentStep, 0);
      });

      test('goToStep should set specific step', () {
        notifier.goToStep(2);

        expect(notifier.state.currentStep, 2);
      });

      test('goToStep should ignore invalid steps', () {
        notifier.goToStep(-1);
        expect(notifier.state.currentStep, 0);

        notifier.goToStep(6);
        expect(notifier.state.currentStep, 0);
      });
    });

    group('species selection', () {
      test('addSpecies should add species to selection', () {
        notifier.addSpecies(SpeciesData.guppy);

        expect(notifier.state.selectedSpecies.length, 1);
        expect(notifier.state.selectedSpecies.first.species, SpeciesData.guppy);
      });

      test('addSpecies should not add duplicate species', () {
        notifier.addSpecies(SpeciesData.guppy);
        notifier.addSpecies(SpeciesData.guppy);

        expect(notifier.state.selectedSpecies.length, 1);
      });

      test('addSpecies should not exceed 3 species', () {
        notifier.addSpecies(SpeciesData.guppy);
        notifier.addSpecies(SpeciesData.betta);
        notifier.addSpecies(SpeciesData.goldfish);
        notifier.addSpecies(SpeciesData.molly);

        expect(notifier.state.selectedSpecies.length, 3);
      });

      test('removeSpecies should remove species by id', () {
        notifier.addSpecies(SpeciesData.guppy);
        notifier.addSpecies(SpeciesData.betta);
        notifier.removeSpecies('guppy');

        expect(notifier.state.selectedSpecies.length, 1);
        expect(notifier.state.selectedSpecies.first.species, SpeciesData.betta);
      });

      test('toggleSpecies should add if not selected', () {
        notifier.toggleSpecies(SpeciesData.guppy);

        expect(notifier.state.selectedSpecies.length, 1);
      });

      test('toggleSpecies should remove if already selected', () {
        notifier.addSpecies(SpeciesData.guppy);
        notifier.toggleSpecies(SpeciesData.guppy);

        expect(notifier.state.selectedSpecies, isEmpty);
      });
    });

    group('quantity', () {
      test('updateQuantity should update species quantity', () {
        notifier.addSpecies(SpeciesData.guppy);
        notifier.updateQuantity('guppy', 5);

        expect(notifier.state.selectedSpecies.first.quantity, 5);
      });

      test('updateQuantity should not allow quantity below 1', () {
        notifier.addSpecies(SpeciesData.guppy);
        notifier.updateQuantity('guppy', 0);

        expect(notifier.state.selectedSpecies.first.quantity, 1);
      });

      test('updateQuantity should not affect other species', () {
        notifier.addSpecies(SpeciesData.guppy);
        notifier.addSpecies(SpeciesData.betta);
        notifier.updateQuantity('guppy', 5);

        expect(notifier.state.selectedSpecies[0].quantity, 5);
        expect(notifier.state.selectedSpecies[1].quantity, 1);
      });

      test('updateQuantity should allow max quantity of 50', () {
        notifier.addSpecies(SpeciesData.guppy);
        notifier.updateQuantity('guppy', 50);

        expect(notifier.state.selectedSpecies.first.quantity, 50);
      });

      test('updateQuantity should allow quantities up to 50', () {
        notifier.addSpecies(SpeciesData.guppy);
        notifier.updateQuantity('guppy', 25);

        expect(notifier.state.selectedSpecies.first.quantity, 25);
      });
    });

    group('schedule', () {
      test('setGeneratedSchedule should set schedule and clear loading', () {
        notifier.setGeneratingSchedule(true);
        notifier.setGeneratedSchedule([
          const GeneratedScheduleEntry(
            speciesId: 'guppy',
            speciesName: 'Guppy',
            feedingTimes: ['08:00', '18:00'],
            foodType: FoodType.flakes,
            portionGrams: 0.6,
          ),
        ]);

        expect(notifier.state.generatedSchedule.length, 1);
        expect(notifier.state.isGeneratingSchedule, false);
      });

      test('setGeneratingSchedule should update loading state', () {
        notifier.setGeneratingSchedule(true);

        expect(notifier.state.isGeneratingSchedule, true);
      });

      test('updateFeedingTime should update first feeding time', () {
        notifier.setGeneratedSchedule([
          const GeneratedScheduleEntry(
            speciesId: 'guppy',
            speciesName: 'Guppy',
            feedingTimes: ['08:00', '18:00'],
            foodType: FoodType.flakes,
            portionGrams: 0.6,
          ),
        ]);

        notifier.updateFeedingTime('guppy', 0, '09:30');

        expect(notifier.state.generatedSchedule.first.feedingTimes[0], '09:30');
        expect(notifier.state.generatedSchedule.first.feedingTimes[1], '18:00');
      });

      test('updateFeedingTime should update second feeding time', () {
        notifier.setGeneratedSchedule([
          const GeneratedScheduleEntry(
            speciesId: 'guppy',
            speciesName: 'Guppy',
            feedingTimes: ['08:00', '18:00'],
            foodType: FoodType.flakes,
            portionGrams: 0.6,
          ),
        ]);

        notifier.updateFeedingTime('guppy', 1, '19:00');

        expect(notifier.state.generatedSchedule.first.feedingTimes[0], '08:00');
        expect(notifier.state.generatedSchedule.first.feedingTimes[1], '19:00');
      });

      test('updateFeedingTime should only update correct species', () {
        notifier.setGeneratedSchedule([
          const GeneratedScheduleEntry(
            speciesId: 'guppy',
            speciesName: 'Guppy',
            feedingTimes: ['08:00', '18:00'],
            foodType: FoodType.flakes,
            portionGrams: 0.6,
          ),
          const GeneratedScheduleEntry(
            speciesId: 'betta',
            speciesName: 'Betta',
            feedingTimes: ['09:00'],
            foodType: FoodType.pellets,
            portionGrams: 0.4,
          ),
        ]);

        notifier.updateFeedingTime('guppy', 0, '07:00');

        expect(notifier.state.generatedSchedule[0].feedingTimes[0], '07:00');
        expect(notifier.state.generatedSchedule[1].feedingTimes[0], '09:00');
      });

      test('updateFeedingTime should ignore invalid time index', () {
        notifier.setGeneratedSchedule([
          const GeneratedScheduleEntry(
            speciesId: 'guppy',
            speciesName: 'Guppy',
            feedingTimes: ['08:00'],
            foodType: FoodType.flakes,
            portionGrams: 0.6,
          ),
        ]);

        notifier.updateFeedingTime('guppy', 5, '12:00');

        expect(notifier.state.generatedSchedule.first.feedingTimes.length, 1);
        expect(notifier.state.generatedSchedule.first.feedingTimes[0], '08:00');
      });

      test('updateFeedingTime should ignore unknown species', () {
        notifier.setGeneratedSchedule([
          const GeneratedScheduleEntry(
            speciesId: 'guppy',
            speciesName: 'Guppy',
            feedingTimes: ['08:00'],
            foodType: FoodType.flakes,
            portionGrams: 0.6,
          ),
        ]);

        notifier.updateFeedingTime('unknown', 0, '12:00');

        expect(notifier.state.generatedSchedule.first.feedingTimes[0], '08:00');
      });
    });

    group('completion', () {
      test('completeOnboarding should call onComplete callback', () {
        var called = false;
        notifier.onComplete = () => called = true;

        notifier.completeOnboarding();

        expect(called, true);
      });

      test('reset should clear all state', () {
        notifier.addSpecies(SpeciesData.guppy);
        notifier.goToStep(2);
        notifier.setGeneratedSchedule([
          const GeneratedScheduleEntry(
            speciesId: 'guppy',
            speciesName: 'Guppy',
            feedingTimes: ['08:00'],
            foodType: FoodType.flakes,
            portionGrams: 0.3,
          ),
        ]);

        notifier.reset();

        expect(notifier.state, const OnboardingState());
      });
    });

    group('selectedSpecies getter', () {
      test('should return current selections', () {
        notifier.addSpecies(SpeciesData.guppy);
        notifier.addSpecies(SpeciesData.betta);

        expect(notifier.selectedSpecies.length, 2);
      });
    });
  });
}
