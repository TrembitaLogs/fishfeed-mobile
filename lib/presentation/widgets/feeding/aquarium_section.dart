import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/scheduled_feeding.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/widgets/feeding/feeding_card.dart';

/// Section widget displaying an aquarium header with its feedings.
///
/// Shows aquarium name with icon and fish count in header,
/// followed by list of FeedingCard widgets for each feeding.
class AquariumSection extends StatelessWidget {
  const AquariumSection({
    super.key,
    required this.aquarium,
    required this.feedings,
    required this.onMarkAsFed,
    required this.onMarkAsMissed,
  });

  /// The aquarium to display.
  final Aquarium aquarium;

  /// List of feedings for this aquarium.
  final List<ScheduledFeeding> feedings;

  /// Callback when feeding is marked as fed.
  final void Function(String feedingId) onMarkAsFed;

  /// Callback when feeding is marked as missed.
  final void Function(String feedingId) onMarkAsMissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Aquarium header
        _AquariumHeader(aquarium: aquarium, feedingsCount: feedings.length),
        // Feedings list or empty state
        if (feedings.isEmpty)
          _EmptyFeedingsState(theme: theme, l10n: l10n)
        else
          ...feedings.map(
            (feeding) => FeedingCard(
              feeding: feeding,
              onMarkAsFed: onMarkAsFed,
              onMarkAsMissed: onMarkAsMissed,
            ),
          ),
      ],
    );
  }
}

/// Header for aquarium section showing name and icon.
class _AquariumHeader extends StatelessWidget {
  const _AquariumHeader({required this.aquarium, required this.feedingsCount});

  final Aquarium aquarium;
  final int feedingsCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.water_drop_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
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
                if (feedingsCount > 0)
                  Text(
                    '$feedingsCount feeding${feedingsCount == 1 ? '' : 's'} today',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/aquarium/${aquarium.id}/edit'),
            icon: Icon(
              Icons.settings_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Edit aquarium',
          ),
        ],
      ),
    );
  }
}

/// Empty state when aquarium has no feedings for today.
class _EmptyFeedingsState extends StatelessWidget {
  const _EmptyFeedingsState({required this.theme, required this.l10n});

  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 20,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.noFeedingsScheduled,
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
