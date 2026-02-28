import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/core/constants/species_data.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/presentation/providers/species_provider.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';
import 'package:fishfeed/presentation/widgets/common/image_picker_button.dart';
import 'package:fishfeed/services/analytics/analytics_service.dart';

/// Screen for editing an existing fish.
///
/// Allows users to modify the quantity of a fish.
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
  bool _isSaving = false;

  /// Minimum allowed quantity.
  static const int minQuantity = 1;

  /// Maximum allowed quantity.
  static const int maxQuantity = 999;

  Fish? _fish;
  String? _photoKey;
  bool _photoKeyInitialized = false;

  void _initializeFromFish(Fish fish) {
    if (_fish == null) {
      _fish = fish;
      _quantity = fish.quantity;
    }
    if (!_photoKeyInitialized) {
      _photoKey = fish.photoKey;
      _photoKeyInitialized = true;
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

    final updatedFish = Fish(
      id: _fish!.id,
      aquariumId: _fish!.aquariumId,
      speciesId: _fish!.speciesId,
      name: _fish!.name,
      quantity: _quantity,
      notes: _fish!.notes,
      photoKey: _photoKey,
      addedAt: _fish!.addedAt,
      synced: false,
      updatedAt: DateTime.now(),
      serverUpdatedAt: _fish!.serverUpdatedAt,
    );

    final success = await ref
        .read(fishManagementProvider.notifier)
        .updateFish(updatedFish);

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
        context.pop();
      } else {
        _showErrorSnackBar();
      }
    }
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
    final l = AppLocalizations.of(context)!;
    final displayName = customName ?? speciesName;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.set_meal_rounded,
            size: 32,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
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
              const SizedBox(height: 4),
              Text(
                l.editFishDetails,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
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
