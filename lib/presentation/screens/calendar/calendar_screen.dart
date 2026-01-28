import 'package:flutter/material.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:fishfeed/presentation/providers/calendar_data_provider.dart';
import 'package:fishfeed/presentation/providers/calendar_provider.dart';
import 'package:fishfeed/presentation/widgets/calendar/calendar_day_cell.dart';
import 'package:fishfeed/presentation/widgets/calendar/day_detail_sheet.dart';
import 'package:fishfeed/presentation/widgets/common/error_state_widget.dart';

/// Calendar screen displaying a monthly calendar view.
///
/// Features:
/// - Monthly calendar view with TableCalendar widget
/// - Swipe navigation between months
/// - Day selection with visual feedback
/// - Styled header with month name and navigation arrows
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarProvider);
    // Watch calendarDataProvider to rebuild when data changes
    final calendarDataState = ref.watch(calendarDataProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Load data for the focused month
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calendarDataProvider.notifier).loadMonth(
            calendarState.focusedDay.year,
            calendarState.focusedDay.month,
          );
    });

    return Column(
      children: [
        TableCalendar<dynamic>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: calendarState.focusedDay,
          calendarFormat: calendarState.calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(calendarState.selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            ref
                .read(calendarProvider.notifier)
                .onDaySelected(selectedDay, focusedDay);
            showDayDetailSheet(context, selectedDay);
          },
          onPageChanged: (focusedDay) {
            ref.read(calendarProvider.notifier).onPageChanged(focusedDay);
          },
          onFormatChanged: (format) {
            ref.read(calendarProvider.notifier).onFormatChanged(format);
          },
          startingDayOfWeek: StartingDayOfWeek.monday,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
          },
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ) ??
                const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: colorScheme.primary,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: colorScheme.primary,
            ),
            headerPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ) ??
                const TextStyle(),
            weekendStyle: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ) ??
                const TextStyle(),
          ),
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            cellMargin: EdgeInsets.all(2),
          ),
          calendarBuilders: CalendarBuilders<dynamic>(
            defaultBuilder: (context, day, focusedDay) {
              return CalendarDayCell(
                day: day,
                status: ref
                    .read(calendarDataProvider.notifier)
                    .getDayStatus(day),
                isSelected: false,
                isToday: false,
              );
            },
            selectedBuilder: (context, day, focusedDay) {
              return CalendarDayCell(
                day: day,
                status: ref
                    .read(calendarDataProvider.notifier)
                    .getDayStatus(day),
                isSelected: true,
                isToday: isSameDay(day, DateTime.now()),
              );
            },
            todayBuilder: (context, day, focusedDay) {
              final isSelected = isSameDay(calendarState.selectedDay, day);
              return CalendarDayCell(
                day: day,
                status: ref
                    .read(calendarDataProvider.notifier)
                    .getDayStatus(day),
                isSelected: isSelected,
                isToday: true,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (calendarDataState.hasError)
          Expanded(
            child: ErrorStateWidget(
              title: l10n.errorStateGenericTitle,
              description: calendarDataState.error ?? l10n.errorStateGenericDescription,
              onRetry: () async => ref.read(calendarDataProvider.notifier).refresh(),
              retryLabel: l10n.errorStateTryAgain,
            ),
          )
        else
          _SelectedDayInfo(
            selectedDay: calendarState.selectedDay,
            isLoading: calendarDataState.isLoading,
          ),
      ],
    );
  }
}

/// Widget displaying information about the selected day.
class _SelectedDayInfo extends StatelessWidget {
  const _SelectedDayInfo({
    required this.selectedDay,
    this.isLoading = false,
  });

  final DateTime selectedDay;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatSelectedDate(selectedDay),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (isLoading)
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.loading,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            else
              Text(
                l10n.emptyStateCalendarDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatSelectedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) {
      return 'Today';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (selected == yesterday) {
      return 'Yesterday';
    }

    final tomorrow = today.add(const Duration(days: 1));
    if (selected == tomorrow) {
      return 'Tomorrow';
    }

    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];

    return '$weekday, $month ${date.day}';
  }
}

