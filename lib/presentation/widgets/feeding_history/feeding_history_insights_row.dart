import 'package:flutter/material.dart';

import 'package:fishfeed/l10n/app_localizations.dart';

class FeedingHistoryInsightsRow extends StatelessWidget {
  const FeedingHistoryInsightsRow({
    super.key,
    required this.totalFedCount,
    required this.longestStreak,
    required this.bestDayOfWeek,
  });

  final int totalFedCount;
  final int longestStreak;

  /// 1=Mon..7=Sun. Null when no data.
  final int? bestDayOfWeek;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _Card(label: l10n.feedingHistoryTotalFeedings, value: '$totalFedCount'),
        _Card(label: l10n.feedingHistoryLongestStreak, value: '$longestStreak'),
        _Card(
          label: l10n.feedingHistoryBestDayOfWeek,
          value: _weekdayLabel(l10n, bestDayOfWeek),
        ),
      ],
    );
  }

  String _weekdayLabel(AppLocalizations l10n, int? weekday) {
    switch (weekday) {
      case DateTime.monday:
        return l10n.feedingHistoryWeekdayMonFull;
      case DateTime.tuesday:
        return l10n.feedingHistoryWeekdayTueFull;
      case DateTime.wednesday:
        return l10n.feedingHistoryWeekdayWedFull;
      case DateTime.thursday:
        return l10n.feedingHistoryWeekdayThuFull;
      case DateTime.friday:
        return l10n.feedingHistoryWeekdayFriFull;
      case DateTime.saturday:
        return l10n.feedingHistoryWeekdaySatFull;
      case DateTime.sunday:
        return l10n.feedingHistoryWeekdaySunFull;
      default:
        return '—'; // em dash
    }
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
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
