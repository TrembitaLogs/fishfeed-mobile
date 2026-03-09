import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/domain/entities/species.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/presentation/providers/species_provider.dart';
import 'package:fishfeed/presentation/router/app_router.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';

/// Shows the fish card bottom sheet for a feeding event.
///
/// Displays detailed fish information including photo, species,
/// feeding schedule, and action buttons (mark as fed, edit, delete).
void showFishCardSheet(BuildContext context, ComputedFeedingEvent event) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FishCardSheet(feedingEvent: event),
  );
}

/// Bottom sheet displaying detailed fish information from a feeding event.
///
/// Content:
/// - Large fish photo (priority: user photo -> species reference -> placeholder)
/// - Fish name + species scientific name
/// - Details: quantity, aquarium, food type, portion, time, added date, notes
/// - Feeding schedule section with interval and active times
/// - Mark as Fed button (hidden when already fed)
/// - Edit Fish button
/// - Delete Fish button (hidden for non-owners)
class FishCardSheet extends ConsumerWidget {
  const FishCardSheet({super.key, required this.feedingEvent});

  /// The feeding event providing context for this fish card.
  final ComputedFeedingEvent feedingEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Resolve fish data
    final fish = ref.watch(fishByIdProvider(feedingEvent.fishId));
    final aquarium = ref.watch(aquariumByIdProvider(feedingEvent.aquariumId));
    final currentUser = ref.watch(currentUserProvider);
    final isOwner = currentUser != null && aquarium?.userId == currentUser.id;

    // Resolve species — use speciesListProvider for sync access
    // (speciesByIdProvider is async and may show placeholder during loading)
    ref.watch(speciesListProvider);
    final Species? species = fish != null
        ? ref.read(speciesListProvider.notifier).findById(fish.speciesId)
        : null;

    // Resolve active schedules for this fish
    final activeSchedules = ref.watch(
      activeSchedulesForFishProvider(feedingEvent.fishId),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Fish photo
              Center(
                child: _FishPhoto(
                  fish: fish,
                  fishId: feedingEvent.fishId,
                  species: species,
                ),
              ),
              const SizedBox(height: 16),

              // Fish name + species
              Center(
                child: Column(
                  children: [
                    Text(
                      feedingEvent.fishName ?? l10n.fishDetails,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (species != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        species.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Details section
              _DetailRow(
                icon: Icons.tag,
                label: l10n.fishQuantity,
                value: '${feedingEvent.fishQuantity}',
                theme: theme,
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.water_drop_outlined,
                label: l10n.aquarium,
                value: feedingEvent.aquariumName ?? '',
                theme: theme,
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.restaurant,
                label: l10n.foodType,
                value: feedingEvent.foodType,
                theme: theme,
              ),
              if (feedingEvent.portionHint != null) ...[
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.lightbulb_outline,
                  label: l10n.portionHintLabel,
                  value: feedingEvent.portionHint!,
                  theme: theme,
                ),
              ],
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.schedule,
                label: l10n.scheduledTime,
                value: feedingEvent.time,
                theme: theme,
              ),
              if (fish != null) ...[
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: l10n.added,
                  value: DateFormat.yMMMd().format(fish.addedAt),
                  theme: theme,
                ),
                if (fish.notes != null && fish.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.notes,
                    label: l10n.notes,
                    value: fish.notes!,
                    theme: theme,
                  ),
                ],
              ],

              // Feeding schedule section
              if (activeSchedules.isNotEmpty) ...[
                const SizedBox(height: 24),
                _FeedingScheduleSection(
                  schedules: activeSchedules,
                  theme: theme,
                  l10n: l10n,
                ),
              ],
              const SizedBox(height: 32),

              // Action buttons
              if (!feedingEvent.isCompleted)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _markAsFed(context, ref),
                    icon: const Icon(Icons.check),
                    label: Text(l10n.markAsFedButton),
                  ),
                ),
              if (!feedingEvent.isCompleted) const SizedBox(height: 12),

              if (isOwner) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _editFish(context),
                    icon: const Icon(Icons.edit),
                    label: Text(l10n.editFishButton),
                  ),
                ),
              ],

              if (isOwner) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _deleteFish(context, ref, l10n),
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    label: Text(l10n.deleteFish),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
              // Bottom padding for safe area
              SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  /// Marks the feeding event as fed and closes the sheet.
  void _markAsFed(BuildContext context, WidgetRef ref) {
    ref.read(todayFeedingsProvider.notifier).markAsFed(feedingEvent.scheduleId);
    Navigator.pop(context);
  }

  /// Navigates to the edit fish screen.
  void _editFish(BuildContext context) {
    Navigator.pop(context);
    context.push(
      AppRouter.editFish.replaceFirst(':fishId', feedingEvent.fishId),
    );
  }

  /// Shows delete confirmation and performs the delete with schedule cleanup.
  Future<void> _deleteFish(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteFishConfirm),
        content: Text(l10n.deleteFishBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;

      // Soft delete the fish
      await ref
          .read(fishManagementProvider.notifier)
          .deleteFish(feedingEvent.fishId);

      // Deactivate related schedules locally for immediate UI update
      final scheduleDs = ref.read(scheduleLocalDataSourceProvider);
      final schedules = scheduleDs.getByFishId(feedingEvent.fishId);
      for (final schedule in schedules) {
        if (schedule.active) {
          final deactivated = schedule.copyWith(active: false);
          deactivated.markAsModified();
          await scheduleDs.update(deactivated);
        }
      }

      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }
}

/// Displays the fish photo with priority fallback chain.
///
/// Priority: user photo (via photoKey) -> species reference image -> placeholder.
class _FishPhoto extends StatelessWidget {
  const _FishPhoto({
    required this.fish,
    required this.fishId,
    required this.species,
  });

  /// The fish entity, or null if not found.
  final Fish? fish;

  /// The ID of the fish.
  final String fishId;

  /// The resolved species, or null if not yet loaded.
  final Species? species;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double photoSize = 200;
    final borderRadius = BorderRadius.circular(16);

    // Priority 1: User-uploaded photo
    if (fish != null && fish!.photoKey != null && fish!.photoKey!.isNotEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: EntityImage(
          photoKey: fish!.photoKey,
          entityType: 'fish',
          entityId: fishId,
          width: photoSize,
          height: photoSize,
          borderRadius: borderRadius,
        ),
      );
    }

    // Priority 2: Species reference image
    if (species != null &&
        species!.imageUrl != null &&
        species!.imageUrl!.isNotEmpty) {
      final placeholder = Container(
        width: photoSize,
        height: photoSize,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius,
        ),
        child: Center(
          child: Icon(
            Icons.set_meal_rounded,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );

      return ClipRRect(
        borderRadius: borderRadius,
        child: CachedNetworkImage(
          imageUrl: species!.imageUrl!,
          cacheKey: 'species_${species!.id}',
          width: photoSize,
          height: photoSize,
          fit: BoxFit.cover,
          placeholder: (_, __) => placeholder,
          errorWidget: (_, __, ___) => placeholder,
          fadeInDuration: const Duration(milliseconds: 300),
          fadeOutDuration: const Duration(milliseconds: 300),
        ),
      );
    }

    // Priority 3: Placeholder
    return Container(
      width: photoSize,
      height: photoSize,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.set_meal_rounded,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A labeled detail row with icon, label, and value.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Section showing feeding schedule information.
///
/// Displays the feeding interval (Daily, Weekly, or Every N days)
/// and all active schedule times.
class _FeedingScheduleSection extends StatelessWidget {
  const _FeedingScheduleSection({
    required this.schedules,
    required this.theme,
    required this.l10n,
  });

  final List<ScheduleModel> schedules;
  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // Use interval from first schedule as representative
    final intervalDays = schedules.first.intervalDays;
    final intervalLabel = _formatInterval(intervalDays);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.feedingSchedule,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // Interval display
        Row(
          children: [
            Icon(Icons.repeat, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              intervalLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Active schedule times
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: schedules.map((schedule) {
            return Chip(
              avatar: Icon(
                Icons.access_time,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              label: Text(schedule.time),
              visualDensity: VisualDensity.compact,
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Formats the interval days into a human-readable label.
  String _formatInterval(int intervalDays) {
    if (intervalDays == 1) {
      return l10n.intervalDaily;
    } else if (intervalDays == 7) {
      return l10n.intervalWeekly;
    } else {
      return l10n.intervalEveryNDays(intervalDays);
    }
  }
}
