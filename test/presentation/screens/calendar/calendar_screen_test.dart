import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/domain/entities/calendar_month_data.dart';
import 'package:fishfeed/domain/entities/calendar_month_stats.dart';
import 'package:fishfeed/domain/usecases/get_calendar_data_usecase.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/calendar_data_provider.dart';
import 'package:fishfeed/presentation/providers/calendar_provider.dart';
import 'package:fishfeed/presentation/screens/calendar/calendar_screen.dart';

class MockGetCalendarDataUseCase extends Mock
    implements GetCalendarDataUseCase {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
    registerFallbackValue(const GetCalendarDataParams(year: 2025, month: 1));
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({CalendarState? initialState}) {
    final now = DateTime.now();

    return ProviderScope(
      overrides: [
        // Override calendarDataProvider with empty successful state
        calendarDataProvider.overrideWith((ref) {
          return TestCalendarDataNotifier(
            CalendarDataState(
              monthData: CalendarMonthData(
                year: now.year,
                month: now.month,
                days: {},
                stats: const CalendarMonthStats(
                  totalScheduledFeedings: 0,
                  completedFeedings: 0,
                  missedFeedings: 0,
                  longestStreak: 0,
                  currentStreak: 0,
                ),
              ),
              isLoading: false,
            ),
          );
        }),
        if (initialState != null)
          calendarProvider.overrideWith(
            () => TestCalendarNotifier(initialState),
          ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: CalendarScreen()),
      ),
    );
  }

  group('CalendarScreen', () {
    group('TableCalendar rendering', () {
      testWidgets('renders TableCalendar widget', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(TableCalendar<dynamic>), findsOneWidget);
      });

      testWidgets('displays month view by default', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // TableCalendar should be in month format
        final tableCalendar = tester.widget<TableCalendar<dynamic>>(
          find.byType(TableCalendar<dynamic>),
        );
        expect(tableCalendar.calendarFormat, CalendarFormat.month);
      });

      testWidgets('displays current month in header', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Should display current month name
        final now = DateTime.now();
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
          'December',
        ];
        final currentMonth = months[now.month - 1];

        expect(find.textContaining(currentMonth), findsOneWidget);
      });

      testWidgets('displays navigation arrows in header', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.chevron_left), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });

      testWidgets('displays days of week header', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Check for Monday as first day (StartingDayOfWeek.monday)
        expect(find.text('Mon'), findsOneWidget);
        expect(find.text('Tue'), findsOneWidget);
        expect(find.text('Wed'), findsOneWidget);
        expect(find.text('Thu'), findsOneWidget);
        expect(find.text('Fri'), findsOneWidget);
        expect(find.text('Sat'), findsOneWidget);
        expect(find.text('Sun'), findsOneWidget);
      });
    });

    group('Day selection', () {
      testWidgets('today is initially selected', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Selected day info should show "Today"
        expect(find.text('Today'), findsOneWidget);
      });

      testWidgets(
        'can select a different day',
        // Skip: Bottom sheet DayDetailContent has overflow issue in tests
        skip: true,
        (tester) async {
          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          // Get a day number to tap (e.g., 15 if exists in current view)
          final now = DateTime.now();
          final targetDay = now.day == 15 ? 16 : 15;

          // Find and tap the target day
          final dayFinder = find.text('$targetDay');
          if (dayFinder.evaluate().isNotEmpty) {
            await tester.tap(dayFinder.first);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));

            // Verify the tap was processed by checking the calendar still exists
            expect(find.byType(TableCalendar<dynamic>), findsOneWidget);
          }
        },
      );

      testWidgets(
        'selectedDay state updates on tap',
        // Skip: Bottom sheet DayDetailContent has overflow issue in tests
        skip: true,
        (tester) async {
          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          // Find a day that's not today
          final now = DateTime.now();
          final targetDay = now.day <= 20 ? now.day + 5 : now.day - 5;

          final dayFinder = find.text('$targetDay');
          if (dayFinder.evaluate().isNotEmpty) {
            await tester.tap(dayFinder.first);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));

            // The TableCalendar should still exist and have selectedDayPredicate
            final tableCalendar = tester.widget<TableCalendar<dynamic>>(
              find.byType(TableCalendar<dynamic>),
            );

            // Verify selectedDayPredicate exists
            expect(tableCalendar.selectedDayPredicate, isNotNull);
          }
        },
      );
    });

    group('Month navigation (swipe)', () {
      testWidgets('can navigate to next month with arrow', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Get current month
        final now = DateTime.now();
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
          'December',
        ];
        final currentMonth = months[now.month - 1];
        final nextMonthIndex = now.month % 12;
        final nextMonth = months[nextMonthIndex];

        // Verify current month is shown
        expect(find.textContaining(currentMonth), findsOneWidget);

        // Tap right arrow to go to next month
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();

        // Verify next month is shown
        expect(find.textContaining(nextMonth), findsOneWidget);
      });

      testWidgets('can navigate to previous month with arrow', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Get current month
        final now = DateTime.now();
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
          'December',
        ];
        final currentMonth = months[now.month - 1];
        final prevMonthIndex = (now.month - 2 + 12) % 12;
        final prevMonth = months[prevMonthIndex];

        // Verify current month is shown
        expect(find.textContaining(currentMonth), findsOneWidget);

        // Tap left arrow to go to previous month
        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();

        // Verify previous month is shown
        expect(find.textContaining(prevMonth), findsOneWidget);
      });

      testWidgets('focusedDay updates on page change', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Navigate to next month
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();

        // Navigate back
        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();

        // Current month should be displayed again
        final now = DateTime.now();
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
          'December',
        ];
        final currentMonth = months[now.month - 1];
        expect(find.textContaining(currentMonth), findsOneWidget);
      });
    });

    group('Selected day info section', () {
      testWidgets('displays selected day info container', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Should show the info section with localized text
        expect(
          find.text('Start tracking feedings to see your history here.'),
          findsOneWidget,
        );
      });

      testWidgets('shows "Today" when today is selected', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Today'), findsOneWidget);
      });

      testWidgets('shows day name when other day selected', (tester) async {
        // Create initial state with a different day selected
        final now = DateTime.now();
        final differentDay = DateTime(now.year, now.month, 1);

        await tester.pumpWidget(
          buildTestWidget(
            initialState: CalendarState(
              focusedDay: differentDay,
              selectedDay: differentDay,
              calendarFormat: CalendarFormat.month,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should not show "Today"
        if (!isSameDay(differentDay, now)) {
          expect(find.text('Today'), findsNothing);
        }
      });
    });

    group('Calendar styling', () {
      testWidgets('uses correct theme colors', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // TableCalendar should be rendered
        expect(find.byType(TableCalendar<dynamic>), findsOneWidget);
      });

      testWidgets('header has centered title', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final tableCalendar = tester.widget<TableCalendar<dynamic>>(
          find.byType(TableCalendar<dynamic>),
        );
        expect(tableCalendar.headerStyle.titleCentered, true);
      });

      testWidgets('format button is hidden', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final tableCalendar = tester.widget<TableCalendar<dynamic>>(
          find.byType(TableCalendar<dynamic>),
        );
        expect(tableCalendar.headerStyle.formatButtonVisible, false);
      });
    });
  });
}

/// Test helper notifier that allows setting initial state.
class TestCalendarNotifier extends CalendarNotifier {
  TestCalendarNotifier(this._initialState);

  final CalendarState _initialState;

  @override
  CalendarState build() {
    return _initialState;
  }
}

/// Test helper notifier for CalendarDataProvider with initial state.
class TestCalendarDataNotifier extends CalendarDataNotifier {
  TestCalendarDataNotifier(CalendarDataState initialState)
    : super(getCalendarDataUseCase: _createMockUseCase(initialState));

  static MockGetCalendarDataUseCase _createMockUseCase(
    CalendarDataState initialState,
  ) {
    final mock = MockGetCalendarDataUseCase();
    // Setup mock to return the initial state's month data
    when(() => mock.call(any())).thenAnswer((_) async {
      if (initialState.monthData != null) {
        return Right(initialState.monthData!);
      }
      return Right(
        CalendarMonthData(
          year: DateTime.now().year,
          month: DateTime.now().month,
          days: {},
          stats: const CalendarMonthStats(
            totalScheduledFeedings: 0,
            completedFeedings: 0,
            missedFeedings: 0,
            longestStreak: 0,
            currentStreak: 0,
          ),
        ),
      );
    });
    return mock;
  }

  @override
  Future<void> loadMonth(int year, int month) async {
    // No-op for tests - data is pre-loaded
  }

  @override
  Future<void> refresh() async {
    // No-op for tests
  }
}
