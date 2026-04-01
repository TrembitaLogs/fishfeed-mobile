import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/presentation/providers/onboarding_provider.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/screens/onboarding/steps/add_more_aquarium_step.dart';
import 'package:fishfeed/presentation/screens/onboarding/steps/aquarium_name_step.dart';
import 'package:fishfeed/presentation/screens/onboarding/steps/aquarium_selection_step.dart';
import 'package:fishfeed/presentation/screens/onboarding/steps/species_selection_step.dart';
import 'package:fishfeed/presentation/screens/onboarding/steps/quantity_step.dart';
import 'package:fishfeed/presentation/screens/onboarding/steps/schedule_preview_step.dart';
import 'package:fishfeed/services/analytics/analytics_service.dart';
import 'package:fishfeed/presentation/screens/onboarding/widgets/onboarding_navigation.dart';
import 'package:fishfeed/services/notifications/notification_service.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

/// Main onboarding screen with PageView navigation.
///
/// Guides new users through 5 steps (aquarium-first flow):
/// 0. Aquarium name - create aquarium with name
/// 1. Species selection - choose fish species (1-3)
/// 2. Quantity - set quantity for each species
/// 3. Schedule preview - review and confirm generated schedule
/// 4. Add more? - option to add another aquarium or finish
///
/// Uses [OnboardingNotifier] for state management and
/// [PageController] for smooth page transitions.
///
/// When [isAddMode] is true, the screen is used for adding new fish
/// to an existing aquarium (not first-time onboarding).
///
/// When [isAddAquariumMode] is true, the screen is used for adding a new
/// aquarium with fish from an existing home screen (not first-time onboarding).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    super.key,
    this.isAddMode = false,
    this.isAddAquariumMode = false,
    this.aquariumId,
  });

  /// Whether this is "add fish" mode (true) or first-time onboarding (false).
  final bool isAddMode;

  /// Whether this is "add aquarium" mode - creates new aquarium then adds fish.
  /// Similar to full onboarding but without marking onboarding as completed.
  final bool isAddAquariumMode;

  /// Specific aquarium ID to add fish to (for add mode from aquarium edit screen).
  /// If null in add mode, falls back to selectedAquariumIdProvider.
  final String? aquariumId;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  bool _isCompletingOnboarding = false;

  /// Animation duration for page transitions.
  static const _pageTransitionDuration = Duration(milliseconds: 300);

  /// Animation curve for page transitions.
  static const _pageTransitionCurve = Curves.easeInOut;

  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Track onboarding start (only for first-time onboarding)
    if (!widget.isAddMode && !widget.isAddAquariumMode) {
      AnalyticsService.instance.trackOnboardingStart();
    }

    // Set up completion callback and reset state for add mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isAddMode || widget.isAddAquariumMode) {
        // Reset onboarding state to start fresh for adding new fish/aquarium
        ref.read(onboardingNotifierProvider.notifier).reset();

        // Pre-select aquarium if passed via route parameter
        if (widget.isAddMode && widget.aquariumId != null) {
          ref
              .read(onboardingNotifierProvider.notifier)
              .setSelectedAquarium(widget.aquariumId!);
        }
      }
      ref.read(onboardingNotifierProvider.notifier).onComplete = _onComplete;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onComplete() async {
    if (_isCompletingOnboarding) return;

    setState(() {
      _isCompletingOnboarding = true;
    });

    try {
      final state = ref.read(onboardingNotifierProvider);
      final analytics = AnalyticsService.instance;

      // Track schedule generated
      final totalFeedingsPerDay = state.generatedSchedule.fold<int>(
        0,
        (sum, entry) => sum + entry.feedingTimes.length,
      );
      analytics.trackScheduleGenerated(timesPerDay: totalFeedingsPerDay);

      // 1. Request notification permissions (only for first-time onboarding)
      if (!widget.isAddMode && !widget.isAddAquariumMode) {
        analytics.trackNotificationsPermissionPromptShown();
        await NotificationService.instance.initialize();
        final permissionGranted = await NotificationService.instance
            .requestPermissions();
        analytics.trackNotificationsPermissionResult(
          granted: permissionGranted,
        );
      }

      // 2. Get aquarium ID
      String? aquariumId;
      if (widget.isAddMode) {
        // For add mode: use aquarium selected in step 0, or explicit param
        aquariumId = state.selectedAquariumId ?? widget.aquariumId;
      } else {
        // For normal onboarding and addAquariumMode: use currentAquariumId set during aquarium creation
        aquariumId = state.currentAquariumId;
      }

      if (aquariumId == null) {
        debugPrint('Warning: No aquarium ID available for saving fish');
        return;
      }

      // 3. Save fish and schedules to Hive (so they appear in My Aquarium)
      // Schedules are created locally and synced to server (offline-first)
      final speciesIdToFishId = await _saveFish(
        state.selectedSpecies,
        aquariumId,
      );

      // 4. Create schedules from generated schedule entries
      await _saveSchedules(
        generatedSchedule: state.generatedSchedule,
        selectedSpecies: state.selectedSpecies,
        speciesIdToFishId: speciesIdToFishId,
        aquariumId: aquariumId,
      );

      // Track first feed event created (only for first-time onboarding)
      if (!widget.isAddMode && !widget.isAddAquariumMode) {
        analytics.trackFirstFeedEventCreated();
      }

      // 5. Schedule notifications for each feeding time
      // Wrapped in try-catch to prevent notification errors from blocking onboarding
      try {
        await _scheduleNotifications(state.generatedSchedule);
      } catch (e) {
        // Log the error but don't block onboarding completion
        debugPrint('Failed to schedule notifications: $e');
      }

      // 6. Complete flow
      if (widget.isAddMode || widget.isAddAquariumMode) {
        // In add mode or add aquarium mode, sync and go back
        if (mounted) {
          // Sync with backend first - this creates feeding events for new fish
          // Wait for sync to complete so events appear immediately on home screen
          await ref.read(syncServiceProvider).syncNow();

          // Refresh fish list and aquariums list before going back
          ref.invalidate(fishManagementProvider);
          ref.invalidate(fishByAquariumIdProvider(aquariumId));
          ref.invalidate(userAquariumsProvider);
          // Also refresh today's feedings to show new schedule
          // Note: _SyncCompletionRefreshListener will also call refresh()
          ref.invalidate(todayFeedingsProvider);
          context.pop();
        }
      } else {
        // Mark onboarding as completed (also saves to Hive)
        await ref.read(authNotifierProvider.notifier).completeOnboarding();

        // Trigger initial sync in background (don't block navigation)
        unawaited(ref.read(syncServiceProvider).syncAll());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingOnboarding = false;
        });
      }
    }
  }

  /// Saves fish to Hive.
  ///
  /// Always creates a new Fish record for each selection, even if a fish
  /// of the same species already exists. This allows users to have separate
  /// feeding schedules for different groups of the same species.
  ///
  /// To update quantity of an existing fish group, use the edit fish screen.
  ///
  /// Returns a map of speciesId → fishId for schedule creation.
  Future<Map<String, String>> _saveFish(
    List<SpeciesSelection> selections,
    String aquariumId,
  ) async {
    final now = DateTime.now();
    final fishBox = HiveBoxes.fish;
    final speciesIdToFishId = <String, String>{};

    for (final selection in selections) {
      // Always create a new Fish record (allows separate schedules per group)
      final fishId = _uuid.v4();
      final model = FishModel(
        id: fishId,
        aquariumId: aquariumId,
        speciesId: selection.species.id,
        name: selection.species.name,
        quantity: selection.quantity,
        addedAt: now,
      );
      await fishBox.put(model.id, model);

      // Track mapping for schedule creation
      speciesIdToFishId[selection.species.id] = fishId;
    }

    return speciesIdToFishId;
  }

  /// Saves feeding schedules to Hive based on generated schedule entries.
  ///
  /// Creates ScheduleModel for each feeding time in the generated schedule.
  /// Schedules are created locally and synced to server (offline-first).
  Future<void> _saveSchedules({
    required List<GeneratedScheduleEntry> generatedSchedule,
    required List<SpeciesSelection> selectedSpecies,
    required Map<String, String> speciesIdToFishId,
    required String aquariumId,
  }) async {
    final scheduleDs = ref.read(scheduleLocalDataSourceProvider);
    final userId = ref.read(currentUserProvider)?.id ?? 'default_user';
    final now = DateTime.now();

    // Build a map of speciesId → feedingFrequency for intervalDays calculation
    final speciesFrequencyMap = <String, String>{};
    for (final selection in selectedSpecies) {
      speciesFrequencyMap[selection.species.id] =
          selection.species.feedingFrequency ?? 'daily';
    }

    final schedulesToSave = <ScheduleModel>[];

    for (final entry in generatedSchedule) {
      final fishId = speciesIdToFishId[entry.speciesId];
      if (fishId == null) {
        debugPrint(
          'Warning: No fish found for speciesId ${entry.speciesId}, skipping schedule',
        );
        continue;
      }

      // Determine intervalDays from feeding frequency
      final frequency = speciesFrequencyMap[entry.speciesId] ?? 'daily';
      final intervalDays = frequency == 'every_other_day' ? 2 : 1;

      // Create a schedule for each feeding time
      for (final time in entry.feedingTimes) {
        final schedule = ScheduleModel(
          id: _uuid.v4(),
          fishId: fishId,
          aquariumId: aquariumId,
          time: time,
          intervalDays: intervalDays,
          anchorDate: DateTime(now.year, now.month, now.day),
          foodType: entry.foodType.name,
          portionHint: '${entry.portionGrams.toStringAsFixed(1)}g',
          active: true,
          createdAt: now,
          updatedAt: now,
          createdByUserId: userId,
          synced: false, // Will be synced via ChangeTracker
        );
        schedulesToSave.add(schedule);
      }
    }

    // Batch save all schedules
    if (schedulesToSave.isNotEmpty) {
      await scheduleDs.saveAll(schedulesToSave);
      debugPrint('Created ${schedulesToSave.length} feeding schedules locally');
    }
  }

  Future<void> _scheduleNotifications(
    List<GeneratedScheduleEntry> schedule,
  ) async {
    // Merge schedule entries into unified time slots for notifications
    final mergedSlots = _mergeToTimeSlots(schedule);

    for (var i = 0; i < mergedSlots.length; i++) {
      final slot = mergedSlots[i];
      final parts = slot.time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final speciesText = slot.speciesNames.length == 1
          ? slot.speciesNames.first
          : '${slot.speciesNames.length} species';

      final paddedHour = hour.toString().padLeft(2, '0');
      final paddedMinute = minute.toString().padLeft(2, '0');

      final l10n = AppLocalizations.of(context)!;

      await NotificationService.instance.scheduleDailyFeeding(
        id: 1000 + i,
        title: l10n.feedingTimeNotificationTitle,
        body: l10n.feedingTimeNotificationBody(speciesText),
        hour: hour,
        minute: minute,
        payload: 'feeding_daily_${paddedHour}_$paddedMinute',
      );
    }
  }

  /// Merges schedule entries into unified time slots for notifications.
  List<_MergedTimeSlot> _mergeToTimeSlots(
    List<GeneratedScheduleEntry> schedule,
  ) {
    final timeSlotMap = <String, List<String>>{};

    for (final entry in schedule) {
      for (final time in entry.feedingTimes) {
        timeSlotMap.putIfAbsent(time, () => []).add(entry.speciesName);
      }
    }

    final slots = timeSlotMap.entries
        .map((e) => _MergedTimeSlot(time: e.key, speciesNames: e.value))
        .toList();

    // Sort by time
    slots.sort((a, b) => a.time.compareTo(b.time));

    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);

    // Sync PageController with state when step changes externally
    ref.listen<int>(onboardingStepProvider, (previous, next) {
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        _pageController.animateToPage(
          next,
          duration: _pageTransitionDuration,
          curve: _pageTransitionCurve,
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OnboardingProgressIndicator(
              currentStep: state.currentStep,
              totalSteps: _getTotalSteps(),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _getTotalSteps(),
                itemBuilder: (context, index) => _buildStep(index),
              ),
            ),
            OnboardingNavigationButtons(
              isFirstStep: state.isFirstStep,
              isAddFlow: widget.isAddMode || widget.isAddAquariumMode,
              isLoading: _isCompletingOnboarding || state.isCreatingAquarium,
              canProceed: _canProceed(state),
              nextButtonText: _getNextButtonText(state),
              onBack: _onBackPressed,
              onCancel: _onCancelPressed,
              onNext: _onNextPressed,
            ),
          ],
        ),
      ),
    );
  }

  /// Returns total steps based on the mode.
  int _getTotalSteps() {
    if (widget.isAddMode)
      return 4; // Aquarium Selection + Species + Quantity + Schedule
    if (widget.isAddAquariumMode) return 4; // Skip AddMoreAquariumStep
    return OnboardingState.totalSteps;
  }

  Widget _buildStep(int index) {
    // In add mode: aquarium selection → species → quantity → schedule
    if (widget.isAddMode) {
      return switch (index) {
        0 => const AquariumSelectionStep(),
        1 => const SpeciesSelectionStep(),
        2 => const QuantityStep(),
        3 => const SchedulePreviewStep(),
        _ => const SizedBox.shrink(),
      };
    }

    // In add aquarium mode, show 4 steps (skip AddMoreAquariumStep)
    if (widget.isAddAquariumMode) {
      return switch (index) {
        0 => const AquariumNameStep(),
        1 => const SpeciesSelectionStep(),
        2 => const QuantityStep(),
        3 => const SchedulePreviewStep(),
        _ => const SizedBox.shrink(),
      };
    }

    // Full onboarding flow with aquarium-first approach
    return switch (index) {
      0 => const AquariumNameStep(),
      1 => const SpeciesSelectionStep(),
      2 => const QuantityStep(),
      3 => const SchedulePreviewStep(),
      4 => AddMoreAquariumStep(onAddAnotherAquarium: _onAddAnotherAquarium),
      _ => const SizedBox.shrink(),
    };
  }

  /// Determines if user can proceed based on current step and mode.
  ///
  /// In add mode, steps are shifted (no aquarium name step), so we need
  /// to check different conditions based on the actual step being shown.
  bool _canProceed(OnboardingState state) {
    if (widget.isAddMode) {
      // Add mode: 0=Aquarium, 1=Species, 2=Quantity, 3=Schedule
      return switch (state.currentStep) {
        0 => state.selectedAquariumId != null,
        1 => state.selectedSpecies.isNotEmpty,
        2 => state.selectedSpecies.every((s) => s.quantity > 0),
        3 => state.generatedSchedule.isNotEmpty,
        _ => false,
      };
    }

    // Normal onboarding and addAquariumMode use standard canProceed
    return state.canProceed;
  }

  void _onCancelPressed() {
    context.pop();
  }

  String _getNextButtonText(OnboardingState state) {
    // Calculate if we're on the last step based on mode
    final totalSteps = _getTotalSteps();
    final isLast = state.currentStep >= totalSteps - 1;

    if (isLast) {
      return (widget.isAddMode || widget.isAddAquariumMode)
          ? 'Done'
          : 'Get Started';
    }
    return 'Next';
  }

  void _onBackPressed() {
    ref.read(onboardingNotifierProvider.notifier).previousStep();
  }

  Future<void> _onNextPressed() async {
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final state = ref.read(onboardingNotifierProvider);

    // Calculate if we're on the last step based on mode
    final totalSteps = _getTotalSteps();
    final isLast = state.currentStep >= totalSteps - 1;

    if (isLast) {
      notifier.completeOnboarding();
      return;
    }

    // Handle aquarium creation when leaving step 0 (in full onboarding or addAquarium mode)
    if (!widget.isAddMode && state.currentStep == 0) {
      await _createAquariumAndProceed();
      return;
    }

    notifier.nextStep();
  }

  /// Creates aquarium via API and proceeds to next step.
  Future<void> _createAquariumAndProceed() async {
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final state = ref.read(onboardingNotifierProvider);
    final aquariumName = state.currentAquariumName?.trim() ?? '';

    if (aquariumName.isEmpty) return;

    // Set loading state
    notifier.setCreatingAquarium(true);

    try {
      // Create aquarium via provider
      final aquariumsNotifier = ref.read(userAquariumsProvider.notifier);
      final aquarium = await aquariumsNotifier.createAquarium(
        name: aquariumName,
        waterType: state.currentWaterType,
        capacity: state.currentCapacity,
      );

      if (aquarium != null) {
        // Store aquarium ID and add to created list
        notifier.setCurrentAquarium(aquarium.id, aquarium.name);
        notifier.addCreatedAquarium(aquarium);
        notifier.nextStep();
      } else {
        // Show error - aquarium creation failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.failedToCreateAquarium,
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      notifier.setCreatingAquarium(false);
    }
  }

  /// Handles "Add Another Aquarium" action.
  /// Saves fish and feeding schedules for current aquarium before resetting state.
  Future<void> _onAddAnotherAquarium() async {
    final state = ref.read(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final aquariumId = state.currentAquariumId;

    if (aquariumId != null && state.selectedSpecies.isNotEmpty) {
      // Save fish to Hive
      final speciesIdToFishId = await _saveFish(
        state.selectedSpecies,
        aquariumId,
      );

      // Create schedules locally (offline-first)
      await _saveSchedules(
        generatedSchedule: state.generatedSchedule,
        selectedSpecies: state.selectedSpecies,
        speciesIdToFishId: speciesIdToFishId,
        aquariumId: aquariumId,
      );

      // Schedule notifications for this aquarium's feedings
      try {
        await _scheduleNotifications(state.generatedSchedule);
      } catch (e) {
        debugPrint('Failed to schedule notifications: $e');
      }
    }

    // Reset state for new aquarium (keeps createdAquariums list)
    notifier.resetForNewAquarium();
  }
}

/// Merged time slot for notification scheduling.
class _MergedTimeSlot {
  const _MergedTimeSlot({required this.time, required this.speciesNames});

  final String time;
  final List<String> speciesNames;
}
