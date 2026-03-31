import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';
import 'package:fishfeed/presentation/widgets/common/image_picker_button.dart';

/// Header displaying the fish species and custom name.
class EditFishHeader extends StatelessWidget {
  const EditFishHeader({super.key, required this.speciesName, this.customName});

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
class EditFishPhotoSection extends StatelessWidget {
  const EditFishPhotoSection({
    super.key,
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
class EditFishQuantityField extends StatelessWidget {
  const EditFishQuantityField({
    super.key,
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
class EditFishAquariumDropdown extends StatelessWidget {
  const EditFishAquariumDropdown({
    super.key,
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
class EditFishNotesField extends StatelessWidget {
  const EditFishNotesField({
    super.key,
    required this.controller,
    required this.maxLength,
  });

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

/// Bottom action buttons for Cancel and Save.
class EditFishActionButtons extends StatelessWidget {
  const EditFishActionButtons({
    super.key,
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
class EditFishNotFoundState extends StatelessWidget {
  const EditFishNotFoundState({super.key});

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
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.goBack),
            ),
          ],
        ),
      ),
    );
  }
}
