import 'package:flutter/material.dart';
import 'package:fishfeed/l10n/app_localizations.dart';

import 'package:fishfeed/domain/entities/day_feeding_status.dart';

/// Custom calendar day cell with feeding status indicator.
///
/// Displays a day number with a colored dot indicator below,
/// showing the feeding status for that day:
/// - Green: all feedings completed
/// - Red: all feedings missed
/// - Yellow: partial completion
/// - Gray: no data
///
/// Supports visual states for selected day and today's date.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    required this.status,
    this.isSelected = false,
    this.isToday = false,
    this.onTap,
  });

  /// The day to display.
  final DateTime day;

  /// The feeding status for this day.
  final DayFeedingStatus status;

  /// Whether this day is currently selected.
  final bool isSelected;

  /// Whether this day is today.
  final bool isToday;

  /// Callback when the cell is tapped.
  final VoidCallback? onTap;

  /// Status indicator colors meeting WCAG 2.1 AA accessibility standards.
  static const Color colorAllFed = Color(0xFF4CAF50);
  static const Color colorAllMissed = Color(0xFFF44336);
  static const Color colorPartial = Color(0xFFFFC107);
  static const Color colorNoData = Color(0xFF9E9E9E);

  /// Returns the color for the given status.
  static Color getStatusColor(DayFeedingStatus status) {
    return switch (status) {
      DayFeedingStatus.allFed => colorAllFed,
      DayFeedingStatus.allMissed => colorAllMissed,
      DayFeedingStatus.partial => colorPartial,
      DayFeedingStatus.noData => colorNoData,
    };
  }

  /// Returns the accessibility label for the given status.
  static String getStatusLabel(DayFeedingStatus status, AppLocalizations l10n) {
    return switch (status) {
      DayFeedingStatus.allFed => l10n.allFeedingsCompleted,
      DayFeedingStatus.allMissed => l10n.allFeedingsMissed,
      DayFeedingStatus.partial => l10n.someFeedingsCompleted,
      DayFeedingStatus.noData => l10n.noFeedingData,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return RepaintBoundary(
      child: Semantics(
        label: _buildSemanticLabel(l10n),
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getBackgroundColor(colorScheme),
                borderRadius: BorderRadius.circular(8),
                border: isToday && !isSelected
                    ? Border.all(color: colorScheme.primary, width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _getTextColor(colorScheme),
                      fontWeight: isSelected || isToday
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _StatusDot(
                    status: status,
                    isVisible: status != DayFeedingStatus.noData,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    if (isSelected) {
      return colorScheme.primary;
    }
    if (isToday) {
      return colorScheme.primaryContainer.withValues(alpha: 0.3);
    }
    return Colors.transparent;
  }

  Color _getTextColor(ColorScheme colorScheme) {
    if (isSelected) {
      return colorScheme.onPrimary;
    }
    return colorScheme.onSurface;
  }

  String _buildSemanticLabel(AppLocalizations l10n) {
    final dayLabel = '${day.day}';
    final statusLabel = getStatusLabel(status, l10n);
    final selectionLabel = isSelected ? ', selected' : '';
    final todayLabel = isToday ? ', ${l10n.today.toLowerCase()}' : '';

    return '$dayLabel, $statusLabel$selectionLabel$todayLabel';
  }
}

/// Colored dot indicator for feeding status.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status, required this.isVisible});

  final DayFeedingStatus status;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox(height: 6);
    }

    final color = CalendarDayCell.getStatusColor(status);

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
