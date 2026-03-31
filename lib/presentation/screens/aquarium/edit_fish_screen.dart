import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/core/constants/species_data.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/domain/entities/schedule.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/presentation/providers/species_provider.dart';
import 'package:fishfeed/presentation/screens/aquarium/widgets/edit_fish_form_fields.dart';
import 'package:fishfeed/presentation/screens/aquarium/widgets/edit_fish_schedule_section.dart';
import 'package:fishfeed/services/analytics/analytics_service.dart';

/// Screen for editing an existing fish.
///
/// Allows users to modify the quantity, aquarium assignment, and notes of a fish.
/// When only one aquarium exists, the aquarium dropdown is hidden.
/// Changes are persisted via [FishManagementProvider].
class EditFishScreen extends ConsumerStatefulWidget {
  const EditFishScreen({super.key, required this.fishId});

  /// The ID of the fish to edit.
  final String fishId;

  @override
  ConsumerState<EditFishScreen> createState() => _EditFishScreenState();
}

class _EditFishScreenState extends ConsumerState<EditFishScreen> {
  late int _quantity;
  late String _selectedAquariumId;
  TextEditingController? _notesController;
  TextEditingController? _portionHintController;
  bool _isSaving = false;

  /// Minimum allowed quantity.
  static const int minQuantity = 1;

  /// Maximum allowed quantity.
  static const int maxQuantity = 999;

  /// Maximum allowed length for notes.
  static const int maxNotesLength = 500;

  /// Available food types for the dropdown.
  static const List<String> _foodTypes = [
    'flakes',
    'pellets',
    'frozen',
    'live',
    'mixed',
  ];

  Fish? _fish;
  String? _photoKey;
  bool _photoKeyInitialized = false;

  // Schedule state
  List<Schedule> _schedules = [];
  String _selectedFoodType = 'flakes';
  int _selectedIntervalDays = 1;
  List<String> _feedingTimes = [];
  bool _schedulesInitialized = false;

  @override
  void dispose() {
    _notesController?.dispose();
    _portionHintController?.dispose();
    super.dispose();
  }

  void _initializeFromFish(Fish fish) {
    if (_fish == null) {
      _fish = fish;
      _quantity = fish.quantity;
      _selectedAquariumId = fish.aquariumId;
      _notesController = TextEditingController(text: fish.notes);
    }
    if (!_photoKeyInitialized) {
      _photoKey = fish.photoKey;
      _photoKeyInitialized = true;
    }
    if (!_schedulesInitialized) {
      _schedules = ref.read(activeSchedulesForFishProvider(fish.id));
      if (_schedules.isNotEmpty) {
        _selectedFoodType = _schedules.first.foodType;
        _selectedIntervalDays = _schedules.first.intervalDays;
        _feedingTimes = _schedules.map((s) => s.time).toList();
        _portionHintController = TextEditingController(
          text: _schedules.first.portionHint ?? '',
        );
      } else {
        _portionHintController = TextEditingController();
        _feedingTimes = [];
      }
      _schedulesInitialized = true;
    }
  }

  void _incrementQuantity() {
    if (_quantity < maxQuantity) {
      setState(() {
        _quantity++;
      });
    }
  }

  void _decrementQuantity() {
    if (_quantity > minQuantity) {
      setState(() {
        _quantity--;
      });
    }
  }

  Future<void> _save() async {
    if (_fish == null) return;

    setState(() {
      _isSaving = true;
    });

    final wasAquariumChanged = _selectedAquariumId != _fish!.aquariumId;
    final notesText = _notesController!.text.trim();

    // If local state still holds a local:// key, check whether the background
    // upload already resolved it to an S3 key in Hive.  This avoids
    // overwriting the resolved key with a stale local:// reference.
    var effectivePhotoKey = _photoKey;
    if (effectivePhotoKey != null && effectivePhotoKey.startsWith('local://')) {
      final hiveModel = ref
          .read(fishLocalDataSourceProvider)
          .getFishById(_fish!.id);
      if (hiveModel != null &&
          hiveModel.photoKey != null &&
          !hiveModel.photoKey!.startsWith('local://')) {
        effectivePhotoKey = hiveModel.photoKey;
      }
    }

    final updatedFish = Fish(
      id: _fish!.id,
      aquariumId: _selectedAquariumId,
      speciesId: _fish!.speciesId,
      name: _fish!.name,
      quantity: _quantity,
      notes: notesText.isEmpty ? null : notesText,
      photoKey: effectivePhotoKey,
      addedAt: _fish!.addedAt,
      synced: false,
      updatedAt: DateTime.now(),
      serverUpdatedAt: _fish!.serverUpdatedAt,
    );

    final success = await ref
        .read(fishManagementProvider.notifier)
        .updateFish(updatedFish);

    // Save schedule changes
    if (success) {
      await _saveScheduleChanges();
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        ref
            .read(analyticsServiceProvider)
            .trackFishEdited(
              speciesId: _fish!.speciesId,
              newQuantity: _quantity,
            );

        // If the fish was moved to a different aquarium, invalidate
        // both old and new aquarium fish lists and show a snackbar.
        if (wasAquariumChanged && mounted) {
          ref.invalidate(fishByAquariumIdProvider(_fish!.aquariumId));
          ref.invalidate(fishByAquariumIdProvider(_selectedAquariumId));

          final l = AppLocalizations.of(context)!;
          final newAquarium = ref.read(
            aquariumByIdProvider(_selectedAquariumId),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.fishMovedTo(newAquarium?.name ?? '')),
              action: SnackBarAction(
                label: l.view,
                onPressed: () =>
                    context.go('/aquarium/$_selectedAquariumId/feedings'),
              ),
            ),
          );
        }

        context.pop();
      } else {
        _showErrorSnackBar();
      }
    }
  }

  Future<void> _saveScheduleChanges() async {
    if (_schedules.isEmpty && _feedingTimes.isEmpty) return;

    final scheduleDs = ref.read(scheduleLocalDataSourceProvider);
    final portionHint = _portionHintController?.text.trim();
    final effectivePortionHint = portionHint != null && portionHint.isNotEmpty
        ? portionHint
        : null;

    // Build a set of times that currently exist in schedules
    final existingTimes = <String, Schedule>{
      for (final s in _schedules) s.time: s,
    };

    // Update existing schedules and add new ones
    for (final time in _feedingTimes) {
      if (existingTimes.containsKey(time)) {
        // Update existing schedule via datasource (fetch Hive object by ID)
        final schedule = existingTimes[time]!;
        final hiveModel = scheduleDs.getById(schedule.id);
        if (hiveModel != null) {
          final updated = hiveModel.copyWith(
            foodType: _selectedFoodType,
            portionHint: effectivePortionHint,
            intervalDays: _selectedIntervalDays,
          );
          updated.markAsModified();
          await scheduleDs.update(updated);
        }
        existingTimes.remove(time);
      } else {
        // Add new schedule for this time
        final now = DateTime.now();
        final newSchedule = ScheduleModel(
          id: '${_fish!.id}_${time.replaceAll(':', '')}',
          fishId: _fish!.id,
          aquariumId: _selectedAquariumId,
          time: time,
          intervalDays: _selectedIntervalDays,
          anchorDate: now,
          foodType: _selectedFoodType,
          portionHint: effectivePortionHint,
          active: true,
          createdAt: now,
          updatedAt: now,
          createdByUserId: '',
          synced: false,
        );
        await scheduleDs.save(newSchedule);
      }
    }

    // Deactivate removed schedules
    for (final removed in existingTimes.values) {
      final hiveModel = scheduleDs.getById(removed.id);
      if (hiveModel != null) {
        final deactivated = hiveModel.copyWith(active: false);
        deactivated.markAsModified();
        await scheduleDs.update(deactivated);
      }
    }

    // Invalidate feeding providers to refresh UI
    ref.invalidate(activeSchedulesForFishProvider(_fish!.id));
  }

  Future<void> _addFeedingTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}';
      if (!_feedingTimes.contains(timeStr)) {
        setState(() {
          _feedingTimes.add(timeStr);
          _feedingTimes.sort();
        });
      }
    }
  }

  void _removeFeedingTime(String time) {
    setState(() {
      _feedingTimes.remove(time);
    });
  }

  Future<void> _removePhoto() async {
    if (_photoKey == null) return;

    final l = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.imageDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l.imageDeleteButton),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _photoKey = null);
    }
  }

  void _showErrorSnackBar() {
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.failedToSaveChanges)));
  }

  void _cancel() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // Load fish directly from local storage by ID
    final fish = ref.watch(fishByIdProvider(widget.fishId));

    if (fish == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.editFish)),
        body: const EditFishNotFoundState(),
      );
    }

    _initializeFromFish(fish);
    // Watch species list for reactive updates when data refreshes from API
    ref.watch(speciesListProvider);
    final species = ref
        .read(speciesListProvider.notifier)
        .findById(fish.speciesId);
    final speciesImageUrl = species?.imageUrl;
    final speciesName =
        species?.name ?? SpeciesData.findById(fish.speciesId).name;

    // Get active (non-deleted) aquariums for the dropdown
    final allAquariums = ref.watch(aquariumsListProvider);
    final activeAquariums = allAquariums
        .where((aq) => aq.deletedAt == null)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l.editFish)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EditFishHeader(
                      speciesName: speciesName,
                      customName: fish.name,
                    ),
                    const SizedBox(height: 24),
                    EditFishPhotoSection(
                      fishId: fish.id,
                      speciesId: fish.speciesId,
                      photoKey: _photoKey,
                      speciesImageUrl: speciesImageUrl,
                      onImageSelected: (localKey) {
                        setState(() => _photoKey = localKey);
                      },
                      onRemovePhoto: () => _removePhoto(),
                    ),
                    const SizedBox(height: 32),
                    EditFishQuantityField(
                      quantity: _quantity,
                      onIncrement: _quantity < maxQuantity
                          ? _incrementQuantity
                          : null,
                      onDecrement: _quantity > minQuantity
                          ? _decrementQuantity
                          : null,
                    ),
                    if (activeAquariums.length > 1) ...[
                      const SizedBox(height: 32),
                      EditFishAquariumDropdown(
                        selectedAquariumId: _selectedAquariumId,
                        aquariums: activeAquariums,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedAquariumId = value);
                          }
                        },
                      ),
                    ],
                    if (_schedulesInitialized) ...[
                      const SizedBox(height: 32),
                      EditFishFoodTypeDropdown(
                        selectedFoodType: _selectedFoodType,
                        foodTypes: _foodTypes,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedFoodType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                      EditFishPortionHintField(
                        controller: _portionHintController!,
                      ),
                      const SizedBox(height: 32),
                      EditFishIntervalSelector(
                        selectedIntervalDays: _selectedIntervalDays,
                        onChanged: (value) {
                          setState(() => _selectedIntervalDays = value);
                        },
                      ),
                      const SizedBox(height: 32),
                      EditFishFeedingTimesSection(
                        times: _feedingTimes,
                        onAddTime: _addFeedingTime,
                        onRemoveTime: _removeFeedingTime,
                      ),
                    ],
                    const SizedBox(height: 32),
                    EditFishNotesField(
                      controller: _notesController!,
                      maxLength: maxNotesLength,
                    ),
                  ],
                ),
              ),
            ),
            EditFishActionButtons(
              isSaving: _isSaving,
              onSave: _save,
              onCancel: _cancel,
            ),
          ],
        ),
      ),
    );
  }
}
