import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:fishfeed/presentation/providers/calendar_provider.dart';

void main() {
  group('CalendarState', () {
    test('initial() creates state with today as focused and selected day', () {
      final state = CalendarState.initial();
      final now = DateTime.now();

      expect(isSameDay(state.focusedDay, now), true);
      expect(isSameDay(state.selectedDay, now), true);
      expect(state.calendarFormat, CalendarFormat.month);
    });

    test('copyWith creates new instance with updated values', () {
      final state = CalendarState.initial();
      final newFocusedDay = DateTime(2025, 6, 15);
      final newSelectedDay = DateTime(2025, 6, 20);

      final updated = state.copyWith(
        focusedDay: newFocusedDay,
        selectedDay: newSelectedDay,
        calendarFormat: CalendarFormat.twoWeeks,
      );

      expect(updated.focusedDay, newFocusedDay);
      expect(updated.selectedDay, newSelectedDay);
      expect(updated.calendarFormat, CalendarFormat.twoWeeks);
    });

    test('copyWith preserves unchanged values', () {
      final state = CalendarState(
        focusedDay: DateTime(2025, 1, 15),
        selectedDay: DateTime(2025, 1, 20),
        calendarFormat: CalendarFormat.month,
      );

      final updated = state.copyWith(focusedDay: DateTime(2025, 2, 1));

      expect(updated.focusedDay, DateTime(2025, 2, 1));
      expect(updated.selectedDay, state.selectedDay);
      expect(updated.calendarFormat, state.calendarFormat);
    });
  });

  group('CalendarNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has today as focused and selected day', () {
      final state = container.read(calendarProvider);
      final now = DateTime.now();

      expect(isSameDay(state.focusedDay, now), true);
      expect(isSameDay(state.selectedDay, now), true);
      expect(state.calendarFormat, CalendarFormat.month);
    });

    group('onDaySelected', () {
      test('updates both selectedDay and focusedDay', () {
        final notifier = container.read(calendarProvider.notifier);
        final newSelected = DateTime(2025, 6, 15);
        final newFocused = DateTime(2025, 6, 15);

        notifier.onDaySelected(newSelected, newFocused);

        final state = container.read(calendarProvider);
        expect(isSameDay(state.selectedDay, newSelected), true);
        expect(isSameDay(state.focusedDay, newFocused), true);
      });

      test('does not update state if same day is selected', () {
        final notifier = container.read(calendarProvider.notifier);
        final initialState = container.read(calendarProvider);

        // Select the same day
        notifier.onDaySelected(
          initialState.selectedDay,
          initialState.focusedDay,
        );

        final newState = container.read(calendarProvider);
        // State should be the same instance if no change occurred
        expect(isSameDay(newState.selectedDay, initialState.selectedDay), true);
      });

      test('allows selecting different day in same month', () {
        final notifier = container.read(calendarProvider.notifier);
        final now = DateTime.now();
        final differentDay = DateTime(
          now.year,
          now.month,
          now.day == 15 ? 16 : 15,
        );

        notifier.onDaySelected(differentDay, differentDay);

        final state = container.read(calendarProvider);
        expect(isSameDay(state.selectedDay, differentDay), true);
      });

      test('allows selecting day in different month', () {
        final notifier = container.read(calendarProvider.notifier);
        final now = DateTime.now();
        final nextMonth = DateTime(now.year, now.month + 1, 15);

        notifier.onDaySelected(nextMonth, nextMonth);

        final state = container.read(calendarProvider);
        expect(isSameDay(state.selectedDay, nextMonth), true);
        expect(isSameDay(state.focusedDay, nextMonth), true);
      });
    });

    group('onPageChanged', () {
      test('updates focusedDay', () {
        final notifier = container.read(calendarProvider.notifier);
        final newFocused = DateTime(2025, 8, 1);

        notifier.onPageChanged(newFocused);

        final state = container.read(calendarProvider);
        expect(isSameDay(state.focusedDay, newFocused), true);
      });

      test('does not change selectedDay', () {
        final notifier = container.read(calendarProvider.notifier);
        final initialState = container.read(calendarProvider);
        final newFocused = DateTime(2025, 8, 1);

        notifier.onPageChanged(newFocused);

        final state = container.read(calendarProvider);
        expect(isSameDay(state.selectedDay, initialState.selectedDay), true);
      });
    });

    group('onFormatChanged', () {
      test('updates calendarFormat', () {
        final notifier = container.read(calendarProvider.notifier);

        notifier.onFormatChanged(CalendarFormat.twoWeeks);

        final state = container.read(calendarProvider);
        expect(state.calendarFormat, CalendarFormat.twoWeeks);
      });

      test('does not update if same format', () {
        final notifier = container.read(calendarProvider.notifier);
        final initialState = container.read(calendarProvider);

        notifier.onFormatChanged(CalendarFormat.month);

        final state = container.read(calendarProvider);
        expect(state.calendarFormat, initialState.calendarFormat);
      });
    });

    group('goToToday', () {
      test('sets focusedDay and selectedDay to today', () {
        final notifier = container.read(calendarProvider.notifier);
        final now = DateTime.now();

        // First change to a different date
        notifier.onDaySelected(DateTime(2025, 3, 15), DateTime(2025, 3, 15));

        // Then go to today
        notifier.goToToday();

        final state = container.read(calendarProvider);
        expect(isSameDay(state.focusedDay, now), true);
        expect(isSameDay(state.selectedDay, now), true);
      });
    });

    group('goToMonth', () {
      test('sets focusedDay to specified date', () {
        final notifier = container.read(calendarProvider.notifier);
        final targetDate = DateTime(2025, 12, 1);

        notifier.goToMonth(targetDate);

        final state = container.read(calendarProvider);
        expect(isSameDay(state.focusedDay, targetDate), true);
      });

      test('does not change selectedDay', () {
        final notifier = container.read(calendarProvider.notifier);
        final initialState = container.read(calendarProvider);
        final targetDate = DateTime(2025, 12, 1);

        notifier.goToMonth(targetDate);

        final state = container.read(calendarProvider);
        expect(isSameDay(state.selectedDay, initialState.selectedDay), true);
      });
    });
  });

  group('Derived providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('focusedDayProvider returns focused day from state', () {
      final focusedDay = container.read(focusedDayProvider);
      final state = container.read(calendarProvider);

      expect(isSameDay(focusedDay, state.focusedDay), true);
    });

    test('selectedDayProvider returns selected day from state', () {
      final selectedDay = container.read(selectedDayProvider);
      final state = container.read(calendarProvider);

      expect(isSameDay(selectedDay, state.selectedDay), true);
    });

    test('calendarFormatProvider returns format from state', () {
      final format = container.read(calendarFormatProvider);
      final state = container.read(calendarProvider);

      expect(format, state.calendarFormat);
    });

    test('derived providers update when main state changes', () {
      final notifier = container.read(calendarProvider.notifier);
      final newDate = DateTime(2025, 5, 20);

      notifier.onDaySelected(newDate, newDate);

      final focusedDay = container.read(focusedDayProvider);
      final selectedDay = container.read(selectedDayProvider);

      expect(isSameDay(focusedDay, newDate), true);
      expect(isSameDay(selectedDay, newDate), true);
    });
  });
}
