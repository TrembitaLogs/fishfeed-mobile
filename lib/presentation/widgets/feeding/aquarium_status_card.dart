import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';

/// Card widget displaying an aquarium with its feeding status.
///
/// Shows aquarium name, fish count (SUM of quantities), optional volume,
/// and a status badge indicating the current feeding state:
/// - [AquariumFeedingStatus.pendingFeeding]: amber warning with time
/// - [AquariumFeedingStatus.allFed]: green checkmark
/// - [AquariumFeedingStatus.nextAt]: neutral schedule with time
///
/// Tapping navigates to the feeding cards screen for this aquarium.
class AquariumStatusCard extends ConsumerWidget {
  const AquariumStatusCard({
    super.key,
    required this.aquarium,
    required this.feedings,
  });

  /// The aquarium to display.
  final Aquarium aquarium;

  /// Today's feeding events for this aquarium (used to compute fish count).
  final List<ComputedFeedingEvent> feedings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final statusData = ref.watch(aquariumFeedingStatusProvider(aquarium.id));

    // Compute total fish count from unique fish quantities
    final fishQuantityByFishId = <String, int>{};
    for (final feeding in feedings) {
      fishQuantityByFishId.putIfAbsent(
        feeding.fishId,
        () => feeding.fishQuantity,
      );
    }
    final totalFishCount = fishQuantityByFishId.values.fold<int>(
      0,
      (sum, qty) => sum + qty,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/aquarium/${aquarium.id}/feedings'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Aquarium photo
              SizedBox(
                width: 48,
                height: 48,
                child: EntityImage(
                  photoKey: aquarium.photoKey,
                  entityType: 'aquarium',
                  entityId: aquarium.id,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(12),
                  memCacheWidth: 96,
                  memCacheHeight: 96,
                ),
              ),
              const SizedBox(width: 16),
              // Aquarium info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aquarium.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Fish count and optional volume
                    Row(
                      children: [
                        Text(
                          l10n.fishCount(totalFishCount),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (aquarium.capacity != null) ...[
                          Text(
                            ' \u2022 ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${aquarium.capacity!.toStringAsFixed(0)}L',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Status badge
                    _StatusBadge(
                      status: statusData.status,
                      time: statusData.nextTime,
                      l10n: l10n,
                    ),
                  ],
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status badge widget showing the current feeding status for an aquarium.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.time,
    required this.l10n,
  });

  final AquariumFeedingStatus status;
  final String? time;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (
      IconData icon,
      Color bgColor,
      Color fgColor,
      String text,
    ) = switch (status) {
      AquariumFeedingStatus.pendingFeeding => (
        Icons.warning_amber_rounded,
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
        l10n.pendingFeedingAt(time ?? ''),
      ),
      AquariumFeedingStatus.allFed => (
        Icons.check_circle,
        theme.colorScheme.primaryContainer,
        theme.colorScheme.primary,
        l10n.allFedToday,
      ),
      AquariumFeedingStatus.nextAt => (
        Icons.schedule,
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
        l10n.nextFeedingAt(time ?? ''),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
