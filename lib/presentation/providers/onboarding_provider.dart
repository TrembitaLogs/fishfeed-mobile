import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/species.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/services/analytics/analytics_service.dart';

/// Represents a selected species with its quantity for onboarding.
class SpeciesSelection {
  const SpeciesSelection({required this.species, this.quantity = 1});

  final Species species;
  final int quantity;

  SpeciesSelection copyWith({Species? species, int? quantity}) {
    return SpeciesSelection(
      species: species ?? this.species,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpeciesSelection &&
        other.species == species &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => Object.hash(species, quantity);
}

/// Generated feeding schedule entry from onboarding.
class GeneratedScheduleEntry {
  const GeneratedScheduleEntry({
    required this.speciesId,
    required this.speciesName,
    required this.feedingTimes,
    required this.foodType,
    required this.portionGrams,
  });

  final String speciesId;
  final String speciesName;
  final List<String> feedingTimes;
  final FoodType foodType;
  final double portionGrams;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GeneratedScheduleEntry) return false;
    if (speciesId != other.speciesId) return false;
    if (speciesName != other.speciesName) return false;
    if (feedingTimes.length != other.feedingTimes.length) return false;
    for (var i = 0; i < feedingTimes.length; i++) {
      if (feedingTimes[i] != other.feedingTimes[i]) return false;
    }
    if (foodType != other.foodType) return false;
    if (portionGrams != other.portionGrams) return false;
    return true;
  }

  /// Creates a copy with updated fields.
  GeneratedScheduleEntry copyWith({
    String? speciesId,
    String? speciesName,
    List<String>? feedingTimes,
    FoodType? foodType,
    double? portionGrams,
  }) {
    return GeneratedScheduleEntry(
      speciesId: speciesId ?? this.speciesId,
      speciesName: speciesName ?? this.speciesName,
      feedingTimes: feedingTimes ?? this.feedingTimes,
      foodType: foodType ?? this.foodType,
      portionGrams: portionGrams ?? this.portionGrams,
    );
  }

  @override
  int get hashCode => Object.hash(
    speciesId,
    speciesName,
    Object.hashAll(feedingTimes),
    foodType,
    portionGrams,
  );
}

/// State for the onboarding flow.
///
/// Tracks the current step and all user selections through the flow.
/// Flow: Aquarium Name → Species Selection → Quantity → Schedule Preview → Add More?
class OnboardingState {
  const OnboardingState({
    this.currentStep = 0,
    this.currentAquariumId,
    this.currentAquariumName,
    this.currentWaterType = WaterType.freshwater,
    this.currentCapacity,
    this.selectedAquariumId,
    this.createdAquariums = const [],
    this.isCreatingAquarium = false,
    this.selectedSpecies = const [],
    this.generatedSchedule = const [],
    this.isGeneratingSchedule = false,
  });

  /// Current step index (0-4).
  final int currentStep;

  /// UUID of the current aquarium being set up.
  final String? currentAquariumId;

  /// Name of the current aquarium being set up.
  final String? currentAquariumName;

  /// Water type for the current aquarium.
  final WaterType currentWaterType;

  /// Capacity (liters) for the current aquarium.
  final double? currentCapacity;

  /// Aquarium ID selected in add-fish mode.
  final String? selectedAquariumId;

  /// List of aquariums created during this onboarding session.
  final List<Aquarium> createdAquariums;

  /// Whether aquarium creation API call is in progress.
  final bool isCreatingAquarium;

  /// List of selected species with quantities.
  final List<SpeciesSelection> selectedSpecies;

  /// Generated feeding schedule based on selections.
  final List<GeneratedScheduleEntry> generatedSchedule;

  /// Whether schedule generation is in progress.
  final bool isGeneratingSchedule;

  /// Total number of onboarding steps.
  /// 0: Aquarium Name, 1: Species Selection, 2: Quantity, 3: Schedule Preview, 4: Add More?
  static const int totalSteps = 5;

  /// Whether user can proceed to next step.
  bool get canProceed {
    return switch (currentStep) {
      0 =>
        currentAquariumName != null && currentAquariumName!.trim().isNotEmpty,
      1 => selectedSpecies.isNotEmpty,
      2 => selectedSpecies.every((s) => s.quantity > 0),
      3 => generatedSchedule.isNotEmpty,
      4 => true, // Always can proceed from "Add More?" step
      _ => false,
    };
  }

  /// Whether user can go back.
  bool get canGoBack => currentStep > 0;

  /// Whether this is the last step.
  bool get isLastStep => currentStep == totalSteps - 1;

  /// Whether this is the first step.
  bool get isFirstStep => currentStep == 0;

  OnboardingState copyWith({
    int? currentStep,
    String? currentAquariumId,
    String? currentAquariumName,
    WaterType? currentWaterType,
    double? Function()? currentCapacity,
    String? Function()? selectedAquariumId,
    List<Aquarium>? createdAquariums,
    bool? isCreatingAquarium,
    List<SpeciesSelection>? selectedSpecies,
    List<GeneratedScheduleEntry>? generatedSchedule,
    bool? isGeneratingSchedule,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      currentAquariumId: currentAquariumId ?? this.currentAquariumId,
      currentAquariumName: currentAquariumName ?? this.currentAquariumName,
      currentWaterType: currentWaterType ?? this.currentWaterType,
      currentCapacity: currentCapacity != null
          ? currentCapacity()
          : this.currentCapacity,
      selectedAquariumId: selectedAquariumId != null
          ? selectedAquariumId()
          : this.selectedAquariumId,
      createdAquariums: createdAquariums ?? this.createdAquariums,
      isCreatingAquarium: isCreatingAquarium ?? this.isCreatingAquarium,
      selectedSpecies: selectedSpecies ?? this.selectedSpecies,
      generatedSchedule: generatedSchedule ?? this.generatedSchedule,
      isGeneratingSchedule: isGeneratingSchedule ?? this.isGeneratingSchedule,
    );
  }

  /// Creates a copy with null aquarium fields (for clearing).
  OnboardingState clearCurrentAquarium() {
    return OnboardingState(
      currentStep: currentStep,
      currentAquariumId: null,
      currentAquariumName: null,
      currentWaterType: WaterType.freshwater,
      createdAquariums: createdAquariums,
      isCreatingAquarium: isCreatingAquarium,
      selectedSpecies: selectedSpecies,
      generatedSchedule: generatedSchedule,
      isGeneratingSchedule: isGeneratingSchedule,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OnboardingState) return false;
    if (currentStep != other.currentStep) return false;
    if (currentAquariumId != other.currentAquariumId) return false;
    if (currentAquariumName != other.currentAquariumName) return false;
    if (currentWaterType != other.currentWaterType) return false;
    if (currentCapacity != other.currentCapacity) return false;
    if (selectedAquariumId != other.selectedAquariumId) return false;
    if (isCreatingAquarium != other.isCreatingAquarium) return false;
    if (createdAquariums.length != other.createdAquariums.length) return false;
    for (var i = 0; i < createdAquariums.length; i++) {
      if (createdAquariums[i] != other.createdAquariums[i]) return false;
    }
    if (selectedSpecies.length != other.selectedSpecies.length) return false;
    for (var i = 0; i < selectedSpecies.length; i++) {
      if (selectedSpecies[i] != other.selectedSpecies[i]) return false;
    }
    if (generatedSchedule.length != other.generatedSchedule.length)
      return false;
    for (var i = 0; i < generatedSchedule.length; i++) {
      if (generatedSchedule[i] != other.generatedSchedule[i]) return false;
    }
    if (isGeneratingSchedule != other.isGeneratingSchedule) return false;
    return true;
  }

  @override
  int get hashCode => Object.hash(
    currentStep,
    currentAquariumId,
    currentAquariumName,
    currentWaterType,
    currentCapacity,
    selectedAquariumId,
    Object.hashAll(createdAquariums),
    isCreatingAquarium,
    Object.hashAll(selectedSpecies),
    Object.hashAll(generatedSchedule),
    isGeneratingSchedule,
  );
}

/// Notifier for managing onboarding state.
///
/// Provides methods for navigating between steps and updating selections.
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  /// Callback triggered when onboarding is completed.
  void Function()? onComplete;

  /// Navigate to next step if possible.
  void nextStep() {
    if (state.currentStep < OnboardingState.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Navigate to previous step if possible.
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Navigate to a specific step.
  void goToStep(int step) {
    if (step >= 0 && step < OnboardingState.totalSteps) {
      state = state.copyWith(currentStep: step);
    }
  }

  // ============================================================================
  // Aquarium Management Methods
  // ============================================================================

  /// Set the aquarium name for current setup.
  void setAquariumName(String name) {
    state = state.copyWith(currentAquariumName: name);
  }

  /// Set the water type for current aquarium setup.
  void setWaterType(WaterType waterType) {
    state = state.copyWith(currentWaterType: waterType);
  }

  /// Set the capacity for current aquarium setup.
  void setCapacity(double? capacity) {
    state = state.copyWith(currentCapacity: () => capacity);
  }

  /// Set selected aquarium ID for add-fish mode.
  void setSelectedAquarium(String id) {
    state = state.copyWith(selectedAquariumId: () => id);
  }

  /// Set creating aquarium loading state.
  void setCreatingAquarium(bool isCreating) {
    state = state.copyWith(isCreatingAquarium: isCreating);
  }

  /// Set current aquarium after creation.
  ///
  /// [id] - UUID of the created aquarium.
  /// [name] - Name of the aquarium.
  void setCurrentAquarium(String id, String name) {
    state = state.copyWith(
      currentAquariumId: id,
      currentAquariumName: name,
      isCreatingAquarium: false,
    );
  }

  /// Add a created aquarium to the list.
  void addCreatedAquarium(Aquarium aquarium) {
    state = state.copyWith(
      createdAquariums: [...state.createdAquariums, aquarium],
    );
  }

  /// Reset state for adding another aquarium.
  ///
  /// Clears selected species and schedule but keeps the list of created aquariums.
  void resetForNewAquarium() {
    state = OnboardingState(
      currentStep: 0,
      currentAquariumId: null,
      currentAquariumName: null,
      currentWaterType: WaterType.freshwater,
      createdAquariums: state.createdAquariums,
      isCreatingAquarium: false,
      selectedSpecies: const [],
      generatedSchedule: const [],
      isGeneratingSchedule: false,
    );
  }

  /// Get the current aquarium ID.
  String? get currentAquariumId => state.currentAquariumId;

  /// Get the current aquarium name.
  String? get currentAquariumName => state.currentAquariumName;

  /// Get list of created aquariums.
  List<Aquarium> get createdAquariums => state.createdAquariums;

  // ============================================================================
  // Species Management Methods
  // ============================================================================

  /// Add a species to selection.
  void addSpecies(Species species) {
    if (selectedSpecies.length >= 3) return;
    if (selectedSpecies.any((s) => s.species.id == species.id)) return;

    final newSelection = SpeciesSelection(species: species);
    state = state.copyWith(
      selectedSpecies: [...state.selectedSpecies, newSelection],
    );

    // Track fish added analytics event
    AnalyticsService.instance.trackFishAdded(
      speciesId: species.id,
      speciesName: species.name,
      fishCount: 1,
      method: FishAddMethod.manual,
    );
  }

  /// Remove a species from selection.
  void removeSpecies(String speciesId) {
    state = state.copyWith(
      selectedSpecies: state.selectedSpecies
          .where((s) => s.species.id != speciesId)
          .toList(),
    );
  }

  /// Toggle species selection.
  void toggleSpecies(Species species) {
    if (selectedSpecies.any((s) => s.species.id == species.id)) {
      removeSpecies(species.id);
    } else {
      addSpecies(species);
    }
  }

  /// Update quantity for a species.
  void updateQuantity(String speciesId, int quantity) {
    if (quantity < 1) return;

    state = state.copyWith(
      selectedSpecies: state.selectedSpecies.map((s) {
        if (s.species.id == speciesId) {
          return s.copyWith(quantity: quantity);
        }
        return s;
      }).toList(),
    );
  }

  /// Get list of selected species.
  List<SpeciesSelection> get selectedSpecies => state.selectedSpecies;

  // ============================================================================
  // Schedule Management Methods
  // ============================================================================

  /// Set generated schedule.
  void setGeneratedSchedule(List<GeneratedScheduleEntry> schedule) {
    state = state.copyWith(
      generatedSchedule: schedule,
      isGeneratingSchedule: false,
    );
  }

  /// Mark schedule generation as in progress.
  void setGeneratingSchedule(bool isGenerating) {
    state = state.copyWith(isGeneratingSchedule: isGenerating);
  }

  /// Update a specific feeding time for a species.
  ///
  /// [speciesId] - The species to update.
  /// [timeIndex] - Index of the feeding time to update (0-based).
  /// [newTime] - New time in "HH:mm" format.
  void updateFeedingTime(String speciesId, int timeIndex, String newTime) {
    final updatedSchedule = state.generatedSchedule.map((entry) {
      if (entry.speciesId == speciesId &&
          timeIndex < entry.feedingTimes.length) {
        final newTimes = List<String>.from(entry.feedingTimes);
        newTimes[timeIndex] = newTime;
        return entry.copyWith(feedingTimes: newTimes);
      }
      return entry;
    }).toList();

    state = state.copyWith(generatedSchedule: updatedSchedule);
  }

  // ============================================================================
  // Completion Methods
  // ============================================================================

  /// Complete onboarding and trigger callback.
  void completeOnboarding() {
    onComplete?.call();
  }

  /// Reset onboarding state to initial.
  void reset() {
    state = const OnboardingState();
  }
}

/// Provider for [OnboardingNotifier].
///
/// Usage:
/// ```dart
/// final onboardingNotifier = ref.watch(onboardingNotifierProvider.notifier);
/// onboardingNotifier.nextStep();
/// ```
final onboardingNotifierProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
      return OnboardingNotifier();
    });

/// Provider for current onboarding step.
final onboardingStepProvider = Provider<int>((ref) {
  return ref.watch(onboardingNotifierProvider.select((s) => s.currentStep));
});

/// Provider for selected species list.
final selectedSpeciesProvider = Provider<List<SpeciesSelection>>((ref) {
  return ref.watch(onboardingNotifierProvider.select((s) => s.selectedSpecies));
});

/// Provider for whether user can proceed to next step.
final canProceedProvider = Provider<bool>((ref) {
  return ref.watch(onboardingNotifierProvider.select((s) => s.canProceed));
});

/// Provider for species search query.
final speciesSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for current aquarium ID during onboarding.
final currentOnboardingAquariumIdProvider = Provider<String?>((ref) {
  return ref.watch(onboardingNotifierProvider.select((s) => s.currentAquariumId));
});

/// Provider for current aquarium name during onboarding.
final currentOnboardingAquariumNameProvider = Provider<String?>((ref) {
  return ref.watch(onboardingNotifierProvider.select((s) => s.currentAquariumName));
});

/// Provider for list of created aquariums during onboarding.
final createdAquariumsProvider = Provider<List<Aquarium>>((ref) {
  return ref.watch(onboardingNotifierProvider.select((s) => s.createdAquariums));
});

/// Provider for aquarium creation loading state.
final isCreatingAquariumProvider = Provider<bool>((ref) {
  return ref.watch(onboardingNotifierProvider.select((s) => s.isCreatingAquarium));
});
