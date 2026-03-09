import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:fishfeed/core/constants/species_data.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/presentation/providers/species_provider.dart';
import 'package:fishfeed/presentation/router/app_router.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

/// Shows a modal bottom sheet with aquarium details, fish list, and actions.
///
/// [context] - Build context for showing the modal.
/// [aquariumId] - The ID of the aquarium to display.
/// [onDeleted] - Optional callback invoked after successful deletion.
void showAquariumCardSheet(
  BuildContext context,
  String aquariumId, {
  VoidCallback? onDeleted,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        AquariumCardSheet(aquariumId: aquariumId, onDeleted: onDeleted),
  );
}

/// Bottom sheet displaying aquarium details with fish list and action buttons.
///
/// Shows:
/// - Drag handle indicator
/// - Aquarium photo (or placeholder)
/// - Name, water type (localized), capacity (with "L" suffix), created date
/// - Fish list header with record count
/// - Fish rows: photo, name, quantity badge (if >1), trailing chevron
/// - "+ Add Fish" button
/// - "Edit Aquarium" button (owner only)
/// - "Delete Aquarium" button (destructive, owner only)
class AquariumCardSheet extends ConsumerWidget {
  const AquariumCardSheet({
    super.key,
    required this.aquariumId,
    this.onDeleted,
  });

  /// The ID of the aquarium to display.
  final String aquariumId;

  /// Optional callback invoked after successful deletion.
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aquarium = ref.watch(aquariumByIdProvider(aquariumId));
    final fishList = ref.watch(fishByAquariumIdProvider(aquariumId));
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine ownership: current user is owner if their ID matches aquarium userId
    final isOwner = currentUser != null && aquarium?.userId == currentUser.id;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: aquarium == null
              ? _AquariumNotFoundContent(scrollController: scrollController)
              : _AquariumContent(
                  aquarium: aquarium,
                  fishList: fishList,
                  isOwner: isOwner,
                  scrollController: scrollController,
                  onDeleted: onDeleted,
                ),
        );
      },
    );
  }
}

/// Content displayed when the aquarium is not found.
class _AquariumNotFoundContent extends StatelessWidget {
  const _AquariumNotFoundContent({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      controller: scrollController,
      children: [
        const _DragHandle(),
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(l10n.aquariumNotFound, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}

/// Main content of the aquarium card sheet.
class _AquariumContent extends ConsumerWidget {
  const _AquariumContent({
    required this.aquarium,
    required this.fishList,
    required this.isOwner,
    required this.scrollController,
    this.onDeleted,
  });

  final Aquarium aquarium;
  final List<Fish> fishList;
  final bool isOwner;
  final ScrollController scrollController;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Drag handle
        const _DragHandle(),

        // Aquarium photo
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: EntityImage(
              photoKey: aquarium.photoKey,
              entityType: 'aquarium',
              entityId: aquarium.id,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Aquarium name
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            aquarium.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Aquarium details (water type, capacity, created date)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              // Water type
              _InfoChip(
                icon: Icons.water_drop_outlined,
                label: _localizedWaterType(aquarium.waterType, l10n),
                theme: theme,
              ),
              // Capacity
              if (aquarium.capacity != null)
                _InfoChip(
                  icon: Icons.straighten,
                  label:
                      '${l10n.volume}: ${_formatCapacity(aquarium.capacity!)} L',
                  theme: theme,
                ),
              // Created date
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                label:
                    '${l10n.added}: ${_formatDate(aquarium.createdAt, locale)}',
                theme: theme,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Divider
        const Divider(height: 1),
        const SizedBox(height: 16),

        // Fish list header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            l10n.fishInAquarium(fishList.length),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Fish list
        if (fishList.isEmpty)
          _EmptyFishState()
        else
          ...fishList.map(
            (fish) => _FishRow(
              fish: fish,
              onTap: isOwner
                  ? () {
                      Navigator.pop(context);
                      context.push('/aquarium/fish/${fish.id}/edit');
                    }
                  : null,
            ),
          ),
        const SizedBox(height: 16),

        // Add Fish button (owner only)
        if (isOwner)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('${AppRouter.addFish}?aquariumId=${aquarium.id}');
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.addFish),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        // Family Mode button (available to all members)
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push(
                '/family/${aquarium.id}?name=${Uri.encodeComponent(aquarium.name)}',
              );
            },
            icon: const Icon(Icons.family_restroom, size: 20),
            label: Text(l10n.familyMode),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Owner-only action buttons
        if (isOwner) ...[
          const SizedBox(height: 12),

          // Edit Aquarium button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.tonal(
              onPressed: () {
                Navigator.pop(context);
                context.push('/aquarium/${aquarium.id}/edit');
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.editAquarium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Delete Aquarium button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _DeleteAquariumButton(
              aquarium: aquarium,
              onDeleted: onDeleted,
            ),
          ),
        ],
      ],
    );
  }

  /// Returns localized water type string.
  String _localizedWaterType(WaterType type, AppLocalizations l10n) {
    return switch (type) {
      WaterType.freshwater => l10n.freshwater,
      WaterType.saltwater => l10n.saltwater,
      WaterType.brackish => l10n.brackish,
    };
  }

  /// Formats capacity value, removing trailing zeros.
  String _formatCapacity(double capacity) {
    if (capacity == capacity.roundToDouble()) {
      return capacity.toInt().toString();
    }
    return capacity.toStringAsFixed(1);
  }

  /// Formats a date for display.
  String _formatDate(DateTime date, String locale) {
    return DateFormat('d MMM yyyy', locale).format(date);
  }
}

/// Drag handle indicator at the top of the sheet.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Compact chip displaying an icon and label for aquarium metadata.
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state when aquarium has no fish.
class _EmptyFishState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
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
              l10n.noFishInAquarium,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single fish row in the fish list.
class _FishRow extends ConsumerWidget {
  const _FishRow({required this.fish, this.onTap});

  final Fish fish;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final staticSpecies = SpeciesData.findById(fish.speciesId);
    final displayName = fish.name ?? staticSpecies.name;

    // Try to get species with imageUrl from backend data
    ref.watch(speciesListProvider);
    final species = ref
        .read(speciesListProvider.notifier)
        .findById(fish.speciesId);
    final speciesImageUrl = species?.imageUrl;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: SizedBox(
        width: 40,
        height: 40,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildFishImage(theme, speciesImageUrl),
        ),
      ),
      title: Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: fish.quantity > 1
          ? Text(
              'x${fish.quantity}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  Widget _buildFishImage(ThemeData theme, String? speciesImageUrl) {
    // Fish has its own photo — use EntityImage
    if (fish.photoKey != null && fish.photoKey!.isNotEmpty) {
      return EntityImage(
        photoKey: fish.photoKey,
        entityType: 'fish',
        entityId: fish.id,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8),
      );
    }

    // Fallback to species image from backend
    if (speciesImageUrl != null && speciesImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: speciesImageUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        memCacheWidth: 80,
        memCacheHeight: 80,
        placeholder: (_, __) => _fishPlaceholder(theme),
        errorWidget: (_, __, ___) => _fishPlaceholder(theme),
      );
    }

    // Default placeholder
    return _fishPlaceholder(theme);
  }

  Widget _fishPlaceholder(ThemeData theme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.set_meal_rounded,
        color: theme.colorScheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }
}

/// Destructive delete button with confirmation dialog.
class _DeleteAquariumButton extends ConsumerWidget {
  const _DeleteAquariumButton({required this.aquarium, this.onDeleted});

  final Aquarium aquarium;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return OutlinedButton.icon(
      onPressed: () => _confirmDelete(context, ref),
      icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
      label: Text(l10n.deleteAquarium),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.error,
        side: BorderSide(color: theme.colorScheme.error),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAquariumTitle(aquarium.name)),
        content: Text(l10n.deleteAquariumConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final success = await ref
        .read(userAquariumsProvider.notifier)
        .deleteAquarium(aquarium.id);

    if (!context.mounted) return;

    if (success) {
      // Trigger sync to push deletion to server
      unawaited(ref.read(syncServiceProvider).syncNow());
      Navigator.pop(context);
      onDeleted?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.aquariumDeleted),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToDeleteAquarium),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
