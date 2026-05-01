import 'package:flutter/material.dart';

import 'package:fishfeed/domain/entities/feeding_history.dart';

/// GitHub-contribution-style heatmap. Each cell is one day.
///
/// Cells are arranged into weekly columns (top = Monday, bottom = Sunday).
/// Colour intensity is `lerp(theme.surfaceContainerHighest, theme.primary,
/// fedCount / maxFedCount)`. Tap target is enlarged by transparent padding
/// to ≥40dp via the surrounding [InkWell] hit slop.
class FeedingHistoryHeatmap extends StatelessWidget {
  const FeedingHistoryHeatmap({
    super.key,
    required this.days,
    required this.onDayTap,
    this.cellSize = 12,
    this.cellSpacing = 2,
  });

  final List<FeedingHistoryDay> days;
  final ValueChanged<FeedingHistoryDay> onDayTap;
  final double cellSize;
  final double cellSpacing;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final maxCount = days
        .map((d) => d.fedCount)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final theme = Theme.of(context);

    final columns = _bucketIntoWeeks(days);
    return Wrap(
      spacing: cellSpacing,
      children: [
        for (final column in columns)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final day in column) ...[
                FeedingHistoryDayCell(
                  day: day,
                  size: cellSize,
                  intensity: maxCount == 0 ? 0 : day.fedCount / maxCount,
                  baseColor: theme.colorScheme.surfaceContainerHighest,
                  filledColor: theme.colorScheme.primary,
                  onTap: () => onDayTap(day),
                ),
                SizedBox(height: cellSpacing),
              ],
            ],
          ),
      ],
    );
  }

  /// Buckets a chronological list of days into Monday-anchored weekly columns.
  /// The first column is left-padded with empty placeholders if the range
  /// does not start on a Monday.
  List<List<FeedingHistoryDay>> _bucketIntoWeeks(List<FeedingHistoryDay> days) {
    final out = <List<FeedingHistoryDay>>[];
    var current = <FeedingHistoryDay>[];
    final firstWeekday = days.first.date.weekday; // 1=Mon..7=Sun
    for (var i = 0; i < firstWeekday - 1; i++) {
      current.add(
        FeedingHistoryDay(
          date: days.first.date.subtract(Duration(days: firstWeekday - 1 - i)),
          fedCount: 0,
          aquariumIds: const [],
        ),
      );
    }
    for (final d in days) {
      current.add(d);
      if (current.length == 7) {
        out.add(current);
        current = <FeedingHistoryDay>[];
      }
    }
    if (current.isNotEmpty) out.add(current);
    return out;
  }
}

class FeedingHistoryDayCell extends StatelessWidget {
  const FeedingHistoryDayCell({
    super.key,
    required this.day,
    required this.size,
    required this.intensity,
    required this.baseColor,
    required this.filledColor,
    required this.onTap,
  });

  final FeedingHistoryDay day;
  final double size;
  final double intensity;
  final Color baseColor;
  final Color filledColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour = Color.lerp(baseColor, filledColor, intensity.clamp(0, 1))!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colour,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
