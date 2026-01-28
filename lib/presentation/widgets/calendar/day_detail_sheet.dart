import 'package:flutter/material.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/domain/entities/day_feeding_status.dart';
import 'package:fishfeed/domain/entities/feeding_status.dart';
import 'package:fishfeed/domain/entities/scheduled_feeding.dart';
import 'package:fishfeed/presentation/providers/day_detail_provider.dart';
import 'package:fishfeed/presentation/widgets/calendar/calendar_day_cell.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';
import 'package:fishfeed/presentation/widgets/common/loading_indicator.dart';
import 'package:fishfeed/presentation/widgets/feeding/status_indicator.dart';

/// Shows a modal bottom sheet with day feeding details.
///
/// [context] - Build context for showing the modal.
/// [date] - The date to show details for.
///
/// Example:
/// ```dart
/// await showDayDetailSheet(context, selectedDate);
/// ```
Future<void> showDayDetailSheet(BuildContext context, DateTime date) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DayDetailSheet(date: date),
  );
}

/// Bottom sheet displaying feeding details for a specific day.
///
/// Features:
/// - Draggable scrollable sheet with snap points
/// - Header with date and overall day status
/// - List of feedings with time and status indicators
/// - Loading indicator during data fetch
/// - Empty state when no feedings exist
/// - Swipe down to close
class DayDetailSheet extends ConsumerWidget {
  const DayDetailSheet({
    super.key,
    required this.date,
  });

  /// The date to display details for.
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dayDetailProvider(date));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              _DragHandle(colorScheme: colorScheme),
              // Header
              _DayDetailHeader(
                date: date,
                status: state.dayStatus,
                completedCount: state.completedCount,
                totalCount: state.feedings.length,
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: _DayDetailContent(
                  state: state,
                  scrollController: scrollController,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Drag handle indicator at the top of the sheet.
class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Header showing date and overall day status.
class _DayDetailHeader extends StatelessWidget {
  const _DayDetailHeader({
    required this.date,
    required this.status,
    required this.completedCount,
    required this.totalCount,
  });

  final DateTime date;
  final DayFeedingStatus status;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final statusColor = CalendarDayCell.getStatusColor(status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          // Date info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(date, l10n),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusText(status, completedCount, totalCount, l10n),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Status indicator
          if (status != DayFeedingStatus.noData)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getStatusLabel(status, l10n),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) {
      return l10n.today;
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (selected == yesterday) {
      return l10n.yesterday;
    }

    final tomorrow = today.add(const Duration(days: 1));
    if (selected == tomorrow) {
      return l10n.tomorrow;
    }

    final weekdays = [
      l10n.monday,
      l10n.tuesday,
      l10n.wednesday,
      l10n.thursday,
      l10n.friday,
      l10n.saturday,
      l10n.sunday,
    ];
    final months = [
      l10n.monthJan,
      l10n.monthFeb,
      l10n.monthMar,
      l10n.monthApr,
      l10n.monthMay,
      l10n.monthJun,
      l10n.monthJul,
      l10n.monthAug,
      l10n.monthSep,
      l10n.monthOct,
      l10n.monthNov,
      l10n.monthDec,
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    return '$weekday, $month ${date.day}';
  }

  String _getStatusText(DayFeedingStatus status, int completed, int total, AppLocalizations l10n) {
    if (status == DayFeedingStatus.noData || total == 0) {
      return l10n.noFeedingsScheduled;
    }
    return l10n.feedingsCompleted(completed, total);
  }

  String _getStatusLabel(DayFeedingStatus status, AppLocalizations l10n) {
    return switch (status) {
      DayFeedingStatus.allFed => l10n.statusComplete,
      DayFeedingStatus.allMissed => l10n.statusMissed,
      DayFeedingStatus.partial => l10n.statusPartial,
      DayFeedingStatus.noData => l10n.statusNoData,
    };
  }
}

/// Content area showing feedings list or states.
class _DayDetailContent extends StatelessWidget {
  const _DayDetailContent({
    required this.state,
    required this.scrollController,
  });

  final DayDetailState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (state.isLoading) {
      return LoadingIndicator(message: l10n.loadingFeedings);
    }

    if (state.hasError) {
      return _ErrorState(error: state.error!);
    }

    if (state.isEmpty) {
      return const _EmptyState();
    }

    return _FeedingsList(
      feedings: state.feedings,
      scrollController: scrollController,
    );
  }
}

/// Empty state when no feedings exist for the day.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noFeedingsScheduled,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noFeedingData,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state when loading fails.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// List of feedings for the day.
class _FeedingsList extends StatelessWidget {
  const _FeedingsList({
    required this.feedings,
    required this.scrollController,
  });

  final List<ScheduledFeeding> feedings;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: feedings.length,
      itemBuilder: (context, index) {
        return _FeedingListItem(feeding: feedings[index]);
      },
    );
  }
}

/// Single feeding item in the list.
class _FeedingListItem extends StatelessWidget {
  const _FeedingListItem({required this.feeding});

  final ScheduledFeeding feeding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = StatusIndicator.getStatusColor(feeding.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Status indicator
          StatusIndicator(
            status: feeding.status,
            size: StatusIndicatorSize.small,
          ),
          const SizedBox(width: 12),
          // Feeding info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feeding.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: feeding.status == FeedingStatus.fed
                        ? TextDecoration.lineThrough
                        : null,
                    color: feeding.status == FeedingStatus.fed
                        ? colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feeding.aquariumName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                // Fed by attribution (only for completed feedings with user info)
                if (feeding.status == FeedingStatus.fed &&
                    feeding.completedByName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppCachedAvatar(
                        imageUrl: feeding.completedByAvatar,
                        radius: 7,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        feeding.completedByName!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Time and food type
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(feeding.scheduledTime),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              if (feeding.foodType != null)
                Text(
                  feeding.foodType!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
