import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/core/constants/species_data.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/presentation/router/app_router.dart';
import 'package:fishfeed/presentation/screens/aquarium/widgets/aquarium_edit_widgets.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

/// Screen for editing an existing aquarium.
///
/// Allows users to rename the aquarium, manage fish, and delete the aquarium.
class AquariumEditScreen extends ConsumerStatefulWidget {
  const AquariumEditScreen({super.key, required this.aquariumId});

  /// The ID of the aquarium to edit.
  final String aquariumId;

  @override
  ConsumerState<AquariumEditScreen> createState() => _AquariumEditScreenState();
}

class _AquariumEditScreenState extends ConsumerState<AquariumEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _capacityController;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _initialName;
  double? _initialCapacity;
  WaterType? _initialWaterType;
  WaterType? _selectedWaterType;
  Timer? _autoSaveTimer;

  static const _autoSaveDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _capacityController = TextEditingController();
    _nameController.addListener(_onFieldChanged);
    _capacityController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _nameController.removeListener(_onFieldChanged);
    _capacityController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    // Trigger rebuild to show/hide save button
    setState(() {});

    // Schedule auto-save with debounce
    _autoSaveTimer?.cancel();
    if (_hasChanges) {
      _autoSaveTimer = Timer(_autoSaveDelay, _autoSave);
    }
  }

  Future<void> _autoSave() async {
    if (!_hasChanges || _isSaving) return;
    await _saveChanges(showSuccessSnackbar: true);
  }

  void _initializeFromAquarium({
    required String name,
    required WaterType waterType,
    required double? capacity,
  }) {
    if (_initialName == null) {
      _initialName = name;
      _nameController.text = name;
      _initialWaterType = waterType;
      _selectedWaterType = waterType;
      _initialCapacity = capacity;
      if (capacity != null) {
        // Format: remove trailing zeros for clean display
        _capacityController.text = capacity == capacity.roundToDouble()
            ? capacity.toInt().toString()
            : capacity.toString();
      }
    }
  }

  bool get _hasNameChanged =>
      _initialName != null && _nameController.text.trim() != _initialName;

  bool get _hasWaterTypeChanged =>
      _initialWaterType != null && _selectedWaterType != _initialWaterType;

  bool get _hasCapacityChanged {
    final currentText = _capacityController.text.trim();
    if (_initialCapacity == null && currentText.isEmpty) return false;
    if (_initialCapacity == null && currentText.isNotEmpty) return true;
    if (_initialCapacity != null && currentText.isEmpty) return true;
    final parsed = double.tryParse(currentText);
    return parsed != _initialCapacity;
  }

  bool get _hasChanges =>
      _hasNameChanged || _hasWaterTypeChanged || _hasCapacityChanged;

  void _onWaterTypeChanged(WaterType type) {
    setState(() {
      _selectedWaterType = type;
    });

    // Schedule auto-save with debounce
    _autoSaveTimer?.cancel();
    if (_hasChanges) {
      _autoSaveTimer = Timer(_autoSaveDelay, _autoSave);
    }
  }

  Future<void> _saveChanges({bool showSuccessSnackbar = false}) async {
    if (!_hasChanges) return;

    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty || trimmedName.length > 50) return;

    // Parse capacity
    final capacityText = _capacityController.text.trim();
    final capacity = capacityText.isNotEmpty
        ? double.tryParse(capacityText)
        : null;

    // Cancel auto-save timer since we're saving now
    _autoSaveTimer?.cancel();

    setState(() {
      _isSaving = true;
    });

    final result = await ref
        .read(userAquariumsProvider.notifier)
        .updateAquarium(
          aquariumId: widget.aquariumId,
          name: trimmedName,
          waterType: _selectedWaterType,
          capacity: capacity,
        );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (result != null) {
        _initialName = trimmedName;
        _initialWaterType = _selectedWaterType;
        _initialCapacity = capacity;
        // Trigger sync to push changes to server
        unawaited(ref.read(syncServiceProvider).syncNow());
        if (showSuccessSnackbar) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.aquariumUpdated),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToUpdateAquarium),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteAquarium(String aquariumName) async {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteAquariumTitle(aquariumName)),
        content: Text(l.deleteAquariumConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(l.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    final success = await ref
        .read(userAquariumsProvider.notifier)
        .deleteAquarium(widget.aquariumId);

    if (mounted) {
      if (success) {
        // Trigger sync to push deletion to server
        unawaited(ref.read(syncServiceProvider).syncNow());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.aquariumDeleted),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go(AppRouter.home);
      } else {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.failedToDeleteAquarium),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToEditFish(String fishId) {
    context.push('/aquarium/fish/$fishId/edit');
  }

  Future<void> _deleteFish(Fish fish) async {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final species = SpeciesData.findById(fish.speciesId);
    final displayName = fish.name ?? species.name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteFishTitle(displayName)),
        content: Text(l.confirmDeleteFish),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(l.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Use direct deletion provider that works regardless of selected aquarium
      final result = await ref.read(deleteFishByIdProvider(fish.id).future);
      if (result && mounted) {
        // Refresh the fish list for this aquarium
        ref.invalidate(fishByAquariumIdProvider(widget.aquariumId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.fishDeletedSuccessfully),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.failedToSaveChanges),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removePhoto(String? currentPhotoKey) async {
    if (currentPhotoKey == null) return;

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

    if (confirmed != true || !mounted) return;

    await ref
        .read(userAquariumsProvider.notifier)
        .updateAquarium(aquariumId: widget.aquariumId, clearPhotoKey: true);
    unawaited(ref.read(syncServiceProvider).syncNow());
  }

  void _addFish() {
    context.push('${AppRouter.addFish}?aquariumId=${widget.aquariumId}');
  }

  @override
  Widget build(BuildContext context) {
    final aquarium = ref.watch(aquariumByIdProvider(widget.aquariumId));
    final l = AppLocalizations.of(context)!;

    if (aquarium == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.editAquarium)),
        body: const AquariumNotFoundState(),
      );
    }

    _initializeFromAquarium(
      name: aquarium.name,
      waterType: aquarium.waterType,
      capacity: aquarium.capacity,
    );

    // Get fish for this aquarium directly from local storage
    final aquariumFish = ref.watch(fishByAquariumIdProvider(widget.aquariumId));

    return Scaffold(
      appBar: AppBar(title: Text(l.editAquarium)),
      body: _isDeleting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Aquarium Photo Section
                  AquariumPhotoSection(
                    aquariumId: aquarium.id,
                    photoKey: aquarium.photoKey,
                    onImageSelected: (localKey) async {
                      await ref
                          .read(userAquariumsProvider.notifier)
                          .updateAquarium(
                            aquariumId: widget.aquariumId,
                            photoKey: localKey,
                          );
                      unawaited(ref.read(syncServiceProvider).syncNow());
                    },
                    onRemovePhoto: () => _removePhoto(aquarium.photoKey),
                  ),
                  const SizedBox(height: 24),
                  // Aquarium Details Section (Name, Water Type, Volume)
                  AquariumDetailsSection(
                    nameController: _nameController,
                    capacityController: _capacityController,
                    selectedWaterType:
                        _selectedWaterType ?? WaterType.freshwater,
                    isSaving: _isSaving,
                    hasChanged: _hasChanges,
                    onSave: () => _saveChanges(showSuccessSnackbar: true),
                    onWaterTypeChanged: _onWaterTypeChanged,
                  ),
                  const SizedBox(height: 24),
                  // Fish Section
                  AquariumFishSection(
                    fish: aquariumFish,
                    onEditFish: _navigateToEditFish,
                    onDeleteFish: _deleteFish,
                    onAddFish: _addFish,
                  ),
                  const SizedBox(height: 32),
                  // Delete Aquarium Button
                  AquariumDeleteButton(
                    onDelete: () => _deleteAquarium(aquarium.name),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
