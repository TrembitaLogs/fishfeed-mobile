import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

/// State for the calendar view.
class CalendarState {
  const CalendarState({
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
  });

  /// Creates initial calendar state with today as focused and selected day.
  factory CalendarState.initial() {
    final now = DateTime.now();
    return CalendarState(
      focusedDay: now,
      selectedDay: now,
      calendarFormat: CalendarFormat.month,
    );
  }

  /// The day currently in focus (determines which month is displayed).
  final DateTime focusedDay;

  /// The currently selected day.
  final DateTime selectedDay;

  /// The current calendar display format.
  final CalendarFormat calendarFormat;

  /// Creates a copy with updated values.
  CalendarState copyWith({
    DateTime? focusedDay,
    DateTime? selectedDay,
    CalendarFormat? calendarFormat,
  }) {
    return CalendarState(
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      calendarFormat: calendarFormat ?? this.calendarFormat,
    );
  }
}

/// Notifier for managing calendar state.
///
/// Handles day selection, page changes, and format changes.
class CalendarNotifier extends Notifier<CalendarState> {
  @override
  CalendarState build() {
    return CalendarState.initial();
  }

  /// Handles day selection from the calendar.
  ///
  /// Updates both selected and focused day when user taps a day.
  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(state.selectedDay, selectedDay)) {
      state = state.copyWith(selectedDay: selectedDay, focusedDay: focusedDay);
    }
  }

  /// Handles page change (swipe between months).
  ///
  /// Updates the focused day to keep calendar in sync with displayed month.
  void onPageChanged(DateTime focusedDay) {
    state = state.copyWith(focusedDay: focusedDay);
  }

  /// Changes the calendar display format.
  void onFormatChanged(CalendarFormat format) {
    if (state.calendarFormat != format) {
      state = state.copyWith(calendarFormat: format);
    }
  }

  /// Navigates to today's date.
  void goToToday() {
    final now = DateTime.now();
    state = state.copyWith(focusedDay: now, selectedDay: now);
  }

  /// Navigates to a specific month.
  void goToMonth(DateTime date) {
    state = state.copyWith(focusedDay: date);
  }
}

/// Provider for calendar state management.
///
/// Usage:
/// ```dart
/// // Watch state
/// final calendarState = ref.watch(calendarProvider);
///
/// // Select a day
/// ref.read(calendarProvider.notifier).onDaySelected(selectedDay, focusedDay);
///
/// // Handle page change
/// ref.read(calendarProvider.notifier).onPageChanged(focusedDay);
/// ```
final calendarProvider = NotifierProvider<CalendarNotifier, CalendarState>(
  CalendarNotifier.new,
);

/// Provider for the currently focused day.
final focusedDayProvider = Provider<DateTime>((ref) {
  return ref.watch(calendarProvider.select((s) => s.focusedDay));
});

/// Provider for the currently selected day.
final selectedDayProvider = Provider<DateTime>((ref) {
  return ref.watch(calendarProvider.select((s) => s.selectedDay));
});

/// Provider for the current calendar format.
final calendarFormatProvider = Provider<CalendarFormat>((ref) {
  return ref.watch(calendarProvider.select((s) => s.calendarFormat));
});
