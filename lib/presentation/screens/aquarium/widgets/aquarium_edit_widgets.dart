import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/core/constants/species_data.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';
import 'package:fishfeed/presentation/widgets/common/app_text_field.dart';
import 'package:fishfeed/presentation/widgets/common/image_picker_button.dart';

/// Section for displaying and editing aquarium photo.
class AquariumPhotoSection extends StatelessWidget {
  const AquariumPhotoSection({
    super.key,
    required this.aquariumId,
    required this.photoKey,
    required this.onImageSelected,
    required this.onRemovePhoto,
  });

  final String aquariumId;
  final String? photoKey;
  final ValueChanged<String> onImageSelected;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ImagePickerButton(
              entityType: 'aquarium',
              entityId: aquariumId,
              onImageSelected: onImageSelected,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: EntityImage(
                  photoKey: photoKey,
                  entityType: 'aquarium',
                  entityId: aquariumId,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (photoKey != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
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
            ],
          ],
        ),
      ),
    );
  }
}

/// Section for editing aquarium details: name, water type, and volume.
class AquariumDetailsSection extends StatelessWidget {
  const AquariumDetailsSection({
    super.key,
    required this.nameController,
    required this.capacityController,
    required this.selectedWaterType,
    required this.isSaving,
    required this.hasChanged,
    required this.onSave,
    required this.onWaterTypeChanged,
  });

  final TextEditingController nameController;
  final TextEditingController capacityController;
  final WaterType selectedWaterType;
  final bool isSaving;
  final bool hasChanged;
  final VoidCallback onSave;
  final ValueChanged<WaterType> onWaterTypeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aquarium Name
            Text(
              l.aquariumName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: nameController,
                    hint: l.aquariumNameHint,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onSave(),
                  ),
                ),
                if (hasChanged) ...[
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: isSaving ? null : onSave,
                    icon: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Water Type
            Text(
              l.waterType,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<WaterType>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: WaterType.freshwater,
                    label: Text(l.freshwater),
                  ),
                  ButtonSegment(
                    value: WaterType.saltwater,
                    label: Text(l.saltwater),
                  ),
                  ButtonSegment(
                    value: WaterType.brackish,
                    label: Text(l.brackish),
                  ),
                ],
                selected: {selectedWaterType},
                onSelectionChanged: (selected) =>
                    onWaterTypeChanged(selected.first),
              ),
            ),
            const SizedBox(height: 20),

            // Volume
            Text(
              l.volume,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: capacityController,
              decoration: InputDecoration(hintText: l.volume, suffixText: 'L'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Section displaying fish list with management options.
class AquariumFishSection extends StatelessWidget {
  const AquariumFishSection({
    super.key,
    required this.fish,
    required this.onEditFish,
    required this.onDeleteFish,
    required this.onAddFish,
  });

  final List<Fish> fish;
  final void Function(String fishId) onEditFish;
  final void Function(Fish fish) onDeleteFish;
  final VoidCallback onAddFish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.fishInAquarium(fish.length),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddFish,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l.addFish),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (fish.isEmpty)
              _EmptyFishState(onAddFish: onAddFish)
            else
              ...fish.map(
                (f) => _FishListTile(
                  fish: f,
                  onEdit: () => onEditFish(f.id),
                  onDelete: () => onDeleteFish(f),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FishListTile extends StatelessWidget {
  const _FishListTile({
    required this.fish,
    required this.onEdit,
    required this.onDelete,
  });

  final Fish fish;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final species = SpeciesData.findById(fish.speciesId);
    final displayName = fish.name ?? species.name;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.set_meal_rounded,
          color: theme.colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        'x${fish.quantity}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: PopupMenuButton<_FishAction>(
        icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
        onSelected: (action) {
          switch (action) {
            case _FishAction.edit:
              onEdit();
              break;
            case _FishAction.delete:
              onDelete();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _FishAction.edit,
            child: Row(
              children: [
                const Icon(Icons.edit_outlined),
                const SizedBox(width: 12),
                Text(l.edit),
              ],
            ),
          ),
          PopupMenuItem(
            value: _FishAction.delete,
            child: Row(
              children: [
                Icon(Icons.delete_outlined, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Text(
                  l.delete,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
            ),
          ),
        ],
      ),
      onTap: onEdit,
    );
  }
}

class _EmptyFishState extends StatelessWidget {
  const _EmptyFishState({required this.onAddFish});

  final VoidCallback onAddFish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.pets_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              l.noFishInAquarium,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.addFishToAquarium,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Delete aquarium button with destructive styling.
class AquariumDeleteButton extends StatelessWidget {
  const AquariumDeleteButton({super.key, required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onDelete,
        icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
        label: Text(l.deleteAquarium),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(color: theme.colorScheme.error),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

/// State shown when aquarium is not found.
class AquariumNotFoundState extends StatelessWidget {
  const AquariumNotFoundState({super.key});

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
            Text(l.aquariumNotFound, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              l.aquariumNotFoundDescription,
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

enum _FishAction { edit, delete }
