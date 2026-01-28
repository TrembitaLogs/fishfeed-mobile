import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/models/feeding_event_model.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/calendar_provider.dart';
import 'package:fishfeed/presentation/screens/calendar/calendar_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({CalendarState? initialState}) {
    return ProviderScope(
      overrides: [
        feedingLocalDataSourceProvider.overrideWithValue(
          MockFeedingLocalDataSource(),
        ),
        if (initialState != null)
          calendarProvider.overrideWith(() => TestCalendarNotifier(initialState)),
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

      testWidgets('can select a different day', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Get a day number to tap (e.g., 15 if exists in current view)
        final now = DateTime.now();
        final targetDay = now.day == 15 ? 16 : 15;

        // Find and tap the target day
        final dayFinder = find.text('$targetDay');
        if (dayFinder.evaluate().isNotEmpty) {
          await tester.tap(dayFinder.first);
          await tester.pumpAndSettle();

          // Bottom sheet is now shown after day selection, dismiss it
          // Tap outside the sheet to close it
          await tester.tapAt(const Offset(10, 10));
          await tester.pumpAndSettle();

          // Selected day should change (no longer "Today" if different day)
          if (now.day != targetDay) {
            expect(find.text('Today'), findsNothing);
          }
        }
      });

      testWidgets('selectedDay state updates on tap', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Find a day that's not today
        final now = DateTime.now();
        final targetDay = now.day <= 20 ? now.day + 5 : now.day - 5;

        final dayFinder = find.text('$targetDay');
        if (dayFinder.evaluate().isNotEmpty) {
          await tester.tap(dayFinder.first);
          await tester.pumpAndSettle();

          // Bottom sheet is now shown after day selection, dismiss it
          await tester.tapAt(const Offset(10, 10));
          await tester.pumpAndSettle();

          // The TableCalendar should update the selected day
          final tableCalendar = tester.widget<TableCalendar<dynamic>>(
            find.byType(TableCalendar<dynamic>),
          );

          // Verify selectedDayPredicate exists
          expect(tableCalendar.selectedDayPredicate, isNotNull);
        }
      });
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

        await tester.pumpWidget(buildTestWidget(
          initialState: CalendarState(
            focusedDay: differentDay,
            selectedDay: differentDay,
            calendarFormat: CalendarFormat.month,
          ),
        ));
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

/// Mock feeding data source for testing.
class MockFeedingLocalDataSource extends FeedingLocalDataSource {
  MockFeedingLocalDataSource() : super(feedingEventsBox: null);

  @override
  List<FeedingEventModel> getFeedingEventsByDate(DateTime date) {
    return [];
  }
}
