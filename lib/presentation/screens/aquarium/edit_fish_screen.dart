import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/core/constants/species_data.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/presentation/providers/species_provider.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';
import 'package:fishfeed/presentation/widgets/common/image_picker_button.dart';
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
  List<ScheduleModel> _schedules = [];
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
    final existingTimes = <String, ScheduleModel>{
      for (final s in _schedules) s.time: s,
    };

    // Update existing schedules and add new ones
    for (final time in _feedingTimes) {
      if (existingTimes.containsKey(time)) {
        // Update existing schedule
        final schedule = existingTimes[time]!;
        final updated = schedule.copyWith(
          foodType: _selectedFoodType,
          portionHint: effectivePortionHint,
          intervalDays: _selectedIntervalDays,
        );
        updated.markAsModified();
        await scheduleDs.update(updated);
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
      final deactivated = removed.copyWith(active: false);
      deactivated.markAsModified();
      await scheduleDs.update(deactivated);
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
        body: const _FishNotFoundState(),
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
                    _FishHeader(
                      speciesName: speciesName,
                      customName: fish.name,
                    ),
                    const SizedBox(height: 24),
                    _FishPhotoSection(
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
                    _QuantityField(
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
                      _AquariumDropdown(
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
                      _FoodTypeDropdown(
                        selectedFoodType: _selectedFoodType,
                        foodTypes: _foodTypes,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedFoodType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                      _PortionHintField(controller: _portionHintController!),
                      const SizedBox(height: 32),
                      _IntervalSelector(
                        selectedIntervalDays: _selectedIntervalDays,
                        onChanged: (value) {
                          setState(() => _selectedIntervalDays = value);
                        },
                      ),
                      const SizedBox(height: 32),
                      _FeedingTimesSection(
                        times: _feedingTimes,
                        onAddTime: _addFeedingTime,
                        onRemoveTime: _removeFeedingTime,
                      ),
                    ],
                    const SizedBox(height: 32),
                    _NotesField(
                      controller: _notesController!,
                      maxLength: maxNotesLength,
                    ),
                  ],
                ),
              ),
            ),
            _ActionButtons(
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

/// Header displaying the fish species and custom name.
class _FishHeader extends StatelessWidget {
  const _FishHeader({required this.speciesName, this.customName});

  final String speciesName;
  final String? customName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = customName ?? speciesName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (customName != null) ...[
          const SizedBox(height: 4),
          Text(
            speciesName,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Section for displaying and editing fish photo.
///
/// Shows (in order of priority):
/// 1. User-uploaded photo (via [photoKey])
/// 2. Species reference image (via [speciesImageUrl])
/// 3. Placeholder icon
class _FishPhotoSection extends StatelessWidget {
  const _FishPhotoSection({
    required this.fishId,
    required this.speciesId,
    required this.photoKey,
    required this.speciesImageUrl,
    required this.onImageSelected,
    required this.onRemovePhoto,
  });

  final String fishId;
  final String speciesId;
  final String? photoKey;
  final String? speciesImageUrl;
  final ValueChanged<String> onImageSelected;
  final VoidCallback onRemovePhoto;

  Widget _buildImageContent(ThemeData theme) {
    // Priority 1: User-uploaded photo
    if (photoKey != null && photoKey!.isNotEmpty) {
      return EntityImage(
        photoKey: photoKey,
        entityType: 'fish',
        entityId: fishId,
        width: 120,
        height: 120,
        borderRadius: BorderRadius.circular(12),
      );
    }

    // Priority 2: Species reference image
    if (speciesImageUrl != null && speciesImageUrl!.isNotEmpty) {
      final placeholder = Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            Icons.set_meal_rounded,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );

      return SizedBox(
        width: 120,
        height: 120,
        child: CachedNetworkImage(
          imageUrl: speciesImageUrl!,
          cacheKey: 'species_$speciesId',
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          placeholder: (_, __) => placeholder,
          errorWidget: (_, __, ___) => placeholder,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
        ),
      );
    }

    // Priority 3: Placeholder icon
    return EntityImage(
      photoKey: null,
      entityType: 'fish',
      entityId: fishId,
      width: 120,
      height: 120,
      borderRadius: BorderRadius.circular(12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.choosePhoto,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: ImagePickerButton(
            entityType: 'fish',
            entityId: fishId,
            onImageSelected: onImageSelected,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImageContent(theme),
            ),
          ),
        ),
        if (photoKey != null) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: onRemovePhoto,
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: theme.colorScheme.error,
              ),
              label: Text(l.imageDeleteButton),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Quantity selector with +/- buttons.
class _QuantityField extends StatelessWidget {
  const _QuantityField({
    required this.quantity,
    this.onIncrement,
    this.onDecrement,
  });

  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.fishQuantity,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton.outlined(
              onPressed: onDecrement,
              icon: const Icon(Icons.remove),
              iconSize: 24,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
            SizedBox(
              width: 80,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton.filled(
              onPressed: onIncrement,
              icon: const Icon(Icons.add),
              iconSize: 24,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ],
        ),
      ],
    );
  }
}

/// Dropdown for selecting which aquarium the fish belongs to.
class _AquariumDropdown extends StatelessWidget {
  const _AquariumDropdown({
    required this.selectedAquariumId,
    required this.aquariums,
    required this.onChanged,
  });

  final String selectedAquariumId;
  final List<Aquarium> aquariums;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.aquarium,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: selectedAquariumId,
          decoration: InputDecoration(
            labelText: l.aquarium,
            prefixIcon: const Icon(Icons.water),
            border: const OutlineInputBorder(),
          ),
          items: aquariums
              .map((aq) => DropdownMenuItem(value: aq.id, child: Text(aq.name)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Text field for adding notes about the fish.
class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller, required this.maxLength});

  final TextEditingController controller;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.notes,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l.notes,
            hintText: l.addNotes,
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
          ),
          maxLines: 4,
          maxLength: maxLength,
          textInputAction: TextInputAction.newline,
        ),
      ],
    );
  }
}

/// Dropdown for selecting the food type.
class _FoodTypeDropdown extends StatelessWidget {
  const _FoodTypeDropdown({
    required this.selectedFoodType,
    required this.foodTypes,
    required this.onChanged,
  });

  final String selectedFoodType;
  final List<String> foodTypes;
  final ValueChanged<String?> onChanged;

  String _localizedFoodType(AppLocalizations l, String type) {
    switch (type) {
      case 'flakes':
        return l.foodTypeFlakes;
      case 'pellets':
        return l.foodTypePellets;
      case 'frozen':
        return l.foodTypeFrozen;
      case 'live':
        return l.foodTypeLive;
      case 'mixed':
        return l.foodTypeMixed;
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.foodType,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: selectedFoodType,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.restaurant),
            border: const OutlineInputBorder(),
          ),
          items: foodTypes
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(_localizedFoodType(l, type)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Text field for portion hint.
class _PortionHintField extends StatelessWidget {
  const _PortionHintField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.portionHintLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lightbulb_outline),
            hintText: l.portionHintPlaceholder,
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

/// Selector for feeding interval (daily, every other day, weekly).
class _IntervalSelector extends StatelessWidget {
  const _IntervalSelector({
    required this.selectedIntervalDays,
    required this.onChanged,
  });

  final int selectedIntervalDays;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.feedingInterval,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 1, label: Text(l.intervalDaily)),
              ButtonSegment(value: 2, label: Text(l.everyOtherDay)),
              ButtonSegment(value: 7, label: Text(l.intervalWeekly)),
            ],
            selected: {selectedIntervalDays},
            onSelectionChanged: (selected) => onChanged(selected.first),
          ),
        ),
      ],
    );
  }
}

/// Section for managing feeding times.
class _FeedingTimesSection extends StatelessWidget {
  const _FeedingTimesSection({
    required this.times,
    required this.onAddTime,
    required this.onRemoveTime,
  });

  final List<String> times;
  final VoidCallback onAddTime;
  final ValueChanged<String> onRemoveTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.feedingTimes,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: onAddTime,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.addFeedingTime),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (times.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '—',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: times.map((time) {
              return Chip(
                avatar: Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                label: Text(time),
                onDeleted: () => onRemoveTime(time),
                deleteIconColor: theme.colorScheme.onSurfaceVariant,
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              );
            }).toList(),
          ),
      ],
    );
  }
}

/// Bottom action buttons for Cancel and Save.
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
  });

  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: isSaving ? null : onCancel,
                child: Text(l.cancel),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: isSaving ? null : onSave,
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// State shown when fish is not found.
class _FishNotFoundState extends StatelessWidget {
  const _FishNotFoundState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(l.fishNotFound, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              l.fishNotFoundDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: Text(l.goBack),
            ),
          ],
        ),
      ),
    );
  }
}
