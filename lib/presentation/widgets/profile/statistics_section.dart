import 'package:flutter/material.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/constants/levels.dart';
import 'package:fishfeed/domain/entities/user_statistics.dart';
import 'package:fishfeed/presentation/providers/statistics_provider.dart';

/// Statistics section widget for the profile screen.
///
/// Displays a card with user statistics in a 2x2 grid:
/// - On-time percentage with circular progress indicator
/// - Total feedings count
/// - Days with app
/// - Current level
///
/// Also includes an XP progress bar at the bottom.
class StatisticsSection extends ConsumerWidget {
  const StatisticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsState = ref.watch(statisticsProvider);

    if (statisticsState.isLoading) {
      return const _StatisticsSectionShimmer();
    }

    final statistics = statisticsState.statistics;
    if (statistics == null) {
      return const SizedBox.shrink();
    }

    return _StatisticsSectionContent(statistics: statistics);
  }
}

/// Content widget displaying the statistics.
class _StatisticsSectionContent extends StatelessWidget {
  const _StatisticsSectionContent({required this.statistics});

  final UserStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.statisticsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats grid (2x2)
            Row(
              children: [
                Expanded(
                  child: _OnTimePercentageCard(
                    percentage: statistics.onTimePercentage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.restaurant,
                    iconColor: Colors.green.shade600,
                    value: statistics.totalFeedings.toString(),
                    label: l10n.feedingsLabel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.calendar_today,
                    iconColor: Colors.blue.shade600,
                    value: statistics.daysWithApp.toString(),
                    label: l10n.daysWithApp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LevelCard(
                    level: statistics.currentLevel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // XP Progress bar
            _XpProgressBar(
              progress: statistics.levelProgress,
              xpText: statistics.xpProgressText,
              isMaxLevel: statistics.isMaxLevel,
            ),
          ],
        ),
      ),
    );
  }
}

/// On-time percentage card with circular progress indicator.
class _OnTimePercentageCard extends StatelessWidget {
  const _OnTimePercentageCard({required this.percentage});

  final double percentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final color = _getColorForPercentage(percentage);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 4,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onTimeLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 80) {
      return Colors.green.shade600;
    } else if (percentage >= 50) {
      return Colors.orange.shade600;
    } else {
      return Colors.red.shade600;
    }
  }
}

/// A single stat card displaying an icon, value, and label.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Level card with shield icon and level name.
class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level});

  final UserLevel level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final color = _getColorForLevel(level);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            _getLocalizedLevelName(level, l10n),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.levelLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getLocalizedLevelName(UserLevel level, AppLocalizations l10n) {
    return switch (level) {
      UserLevel.beginnerAquarist => l10n.levelBeginner,
      UserLevel.caretaker => l10n.levelCaretaker,
      UserLevel.fishMaster => l10n.levelMaster,
      UserLevel.aquariumPro => l10n.levelPro,
    };
  }

  Color _getColorForLevel(UserLevel level) {
    return switch (level) {
      UserLevel.aquariumPro => Colors.purple.shade600,
      UserLevel.fishMaster => Colors.orange.shade600,
      UserLevel.caretaker => Colors.blue.shade600,
      UserLevel.beginnerAquarist => Colors.green.shade600,
    };
  }
}

/// XP progress bar with label.
class _XpProgressBar extends StatelessWidget {
  const _XpProgressBar({
    required this.progress,
    required this.xpText,
    required this.isMaxLevel,
  });

  final double progress;
  final String xpText;
  final bool isMaxLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.experienceLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                xpText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isMaxLevel
                        ? Colors.purple.shade600
                        : theme.colorScheme.primary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer loading placeholder for the statistics section.
class _StatisticsSectionShimmer extends StatefulWidget {
  const _StatisticsSectionShimmer();

  @override
  State<_StatisticsSectionShimmer> createState() =>
      _StatisticsSectionShimmerState();
}

class _StatisticsSectionShimmerState extends State<_StatisticsSectionShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShimmerBox(height: 20, width: 100),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildShimmerCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildShimmerCard()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildShimmerCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildShimmerCard()),
              ],
            ),
            const SizedBox(height: 16),
            _buildShimmerBox(height: 60, width: double.infinity),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox({required double height, required double width}) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerCard() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
            ),
          ),
        );
      },
    );
  }
}
