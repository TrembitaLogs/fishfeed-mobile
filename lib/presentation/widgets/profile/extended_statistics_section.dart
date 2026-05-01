import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/core/utils/premium_gate.dart';
import 'package:fishfeed/services/analytics/analytics_service.dart';
import 'package:fishfeed/domain/entities/feeding_history.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/feeding_history_provider.dart';
import 'package:fishfeed/presentation/widgets/feeding_history/feeding_history_aquarium_strip.dart';
import 'package:fishfeed/presentation/widgets/feeding_history/feeding_history_empty_state.dart';
import 'package:fishfeed/presentation/widgets/feeding_history/feeding_history_heatmap.dart';
import 'package:fishfeed/presentation/widgets/feeding_history/feeding_history_insights_row.dart';
import 'package:fishfeed/presentation/widgets/premium/premium_chip.dart';

/// Extended statistics section for premium users.
///
/// Shows the last 30 days of feeding history for premium users,
/// or a blurred preview with upgrade CTA for free users. The detail
/// screen exposes longer ranges (7d / 30d / 6m) via its range chips.
class ExtendedStatisticsSection extends ConsumerWidget {
  const ExtendedStatisticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(
      featureAccessProvider(PremiumFeature.extendedStatistics),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(hasAccess: hasAccess),
          const SizedBox(height: 12),
          if (hasAccess)
            const _PremiumStatsContent()
          else
            const _LockedStatsPreview(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.hasAccess});

  final bool hasAccess;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Icon(Icons.trending_up, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          l10n.feedingHistoryTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        if (!hasAccess) const PremiumChip(size: PremiumChipSize.tiny),
        const Spacer(),
        Text(
          hasAccess ? l10n.feedingHistoryRange30d : l10n.feedingHistoryRange7d,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LockedStatsPreview extends StatelessWidget {
  const _LockedStatsPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => context.push('/paywall'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Blurred background content
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 120, child: _LockedHeatmapPreview()),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: l10n.feedingHistoryTotalFeedings,
                          value: '—',
                        ),
                        _StatItem(
                          label: l10n.feedingHistoryLongestStreak,
                          value: '—',
                        ),
                        _StatItem(
                          label: l10n.feedingHistoryBestDayOfWeek,
                          value: '—',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Upgrade overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.amber.shade200,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 24,
                        color: Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.feedingHistoryLockedTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.feedingHistoryLockedCta,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.amber.shade800,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedHeatmapPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 2,
      children: List.generate(
        12,
        (i) => Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            5,
            (j) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(
                    alpha: ((i + j) % 4) / 4 + 0.1,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: value == '—' ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PremiumStatsContent extends ConsumerWidget {
  const _PremiumStatsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncHistory = ref.watch(
      feedingHistoryProvider(
        const FeedingHistoryQuery(range: FeedingHistoryRange.thirtyDays),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: asyncHistory.when(
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => SizedBox(
          height: 120,
          child: Center(
            child: Text(AppLocalizations.of(context)!.errorGeneric),
          ),
        ),
        data: (history) {
          if (history.totalFedCount == 0) {
            return FeedingHistoryEmptyState(
              onCtaTap: () => GoRouter.of(context).go('/'),
            );
          }
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AnalyticsService.instance.trackFeedingHistoryOpened(
                range: 'thirtyDays',
                entryPoint: 'profile_section_tap',
              );
              GoRouter.of(context).push('/profile/feeding-history');
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FeedingHistoryHeatmap(
                  days: history.days,
                  onDayTap: (day) {
                    AnalyticsService.instance.trackFeedingHistoryOpened(
                      range: 'thirtyDays',
                      entryPoint: 'heatmap_cell_tap',
                    );
                    GoRouter.of(context).push(
                      '/profile/feeding-history?date='
                      '${day.date.toIso8601String()}',
                    );
                  },
                ),
                if (history.aquariumBreakdown.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FeedingHistoryAquariumStrip(
                    breakdown: history.aquariumBreakdown,
                    onChipTap: (id) {
                      AnalyticsService.instance.trackFeedingHistoryOpened(
                        range: 'thirtyDays',
                        entryPoint: 'sparkline_chip',
                      );
                      GoRouter.of(
                        context,
                      ).push('/profile/feeding-history?aquarium_id=$id');
                    },
                  ),
                ],
                const SizedBox(height: 12),
                FeedingHistoryInsightsRow(
                  totalFedCount: history.totalFedCount,
                  streakDays: history.currentStreak,
                  streakLabel: StreakLabel.current,
                  bestDayOfWeek: history.bestDayOfWeek,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
