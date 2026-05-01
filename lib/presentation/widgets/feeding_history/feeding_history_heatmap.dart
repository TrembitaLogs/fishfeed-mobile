import 'package:flutter/material.dart';

import 'package:fishfeed/domain/entities/feeding_history.dart';

/// GitHub-contribution-style heatmap. Each cell is one day.
///
/// Layout: rows represent weeks (oldest at top), columns represent the seven
/// days of the week (Monday at the left, Sunday at the right). Cell size
/// scales with the available width so the seven columns fill the parent
/// horizontally. Colour intensity is `lerp(theme.surfaceContainerHighest,
/// theme.primary, fedCount / maxFedCount)`. The tap target is enlarged to
/// ≥40dp by [FeedingHistoryDayCell] when the cell would otherwise render
/// smaller than the Material minimum hit size.
class FeedingHistoryHeatmap extends StatelessWidget {
  const FeedingHistoryHeatmap({
    super.key,
    required this.days,
    required this.onDayTap,
    this.cellSpacing = 2,
    this.minCellSize = 16,
    this.maxCellSize = 48,
  });

  final List<FeedingHistoryDay> days;
  final ValueChanged<FeedingHistoryDay> onDayTap;
  final double cellSpacing;

  /// Lower bound for the per-cell visual size. Used when the parent is so
  /// narrow that a width-derived cell would be unreadable.
  final double minCellSize;

  /// Upper bound for the per-cell visual size. Prevents giant cells when
  /// the parent is much wider than the seven-column grid needs.
  final double maxCellSize;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final maxCount = days
        .map((d) => d.fedCount)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final theme = Theme.of(context);

    final rows = _bucketIntoWeeks(days);

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : maxCellSize * 7 + cellSpacing * 6;
        final byWidth = (available - cellSpacing * 6) / 7;
        final cellSize = byWidth.clamp(minCellSize, maxCellSize);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var ri = 0; ri < rows.length; ri++) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var di = 0; di < rows[ri].length; di++) ...[
                    FeedingHistoryDayCell(
                      day: rows[ri][di],
                      size: cellSize,
                      intensity: maxCount == 0
                          ? 0
                          : rows[ri][di].fedCount / maxCount,
                      baseColor: theme.colorScheme.surfaceContainerHighest,
                      filledColor: theme.colorScheme.primary,
                      onTap: () => onDayTap(rows[ri][di]),
                    ),
                    if (di < rows[ri].length - 1) SizedBox(width: cellSpacing),
                  ],
                ],
              ),
              if (ri < rows.length - 1) SizedBox(height: cellSpacing),
            ],
          ],
        );
      },
    );
  }

  /// Buckets a chronological list of days into Monday-anchored weekly groups.
  /// The first group is left-padded with empty placeholders if the range
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
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(2),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: SizedBox(
          width: size < 40 ? 40 : size,
          height: size < 40 ? 40 : size,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: colour,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
