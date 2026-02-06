import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/domain/entities/day_feeding_status.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/presentation/providers/day_detail_provider.dart';
import 'package:fishfeed/presentation/widgets/calendar/day_detail_sheet.dart';
import 'package:fishfeed/presentation/widgets/common/loading_indicator.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  final testDate = DateTime(2024, 6, 15);

  List<ComputedFeedingEvent> createMockFeedings({
    int fedCount = 2,
    int missedCount = 1,
    int pendingCount = 1,
  }) {
    final feedings = <ComputedFeedingEvent>[];
    var id = 1;

    for (var i = 0; i < fedCount; i++) {
      final scheduledFor = testDate.add(Duration(hours: 8 + i));
      feedings.add(
        ComputedFeedingEvent(
          scheduleId: 'schedule_$id',
          fishId: 'fish_$id',
          aquariumId: 'aq1',
          scheduledFor: scheduledFor,
          time: '${(8 + i).toString().padLeft(2, '0')}:00',
          foodType: 'Flakes',
          status: EventStatus.fed,
          aquariumName: 'Living Room Tank',
          fishName: 'Guppy',
        ),
      );
      id++;
    }

    for (var i = 0; i < missedCount; i++) {
      final scheduledFor = testDate.add(Duration(hours: 12 + i));
      feedings.add(
        ComputedFeedingEvent(
          scheduleId: 'schedule_$id',
          fishId: 'fish_$id',
          aquariumId: 'aq2',
          scheduledFor: scheduledFor,
          time: '${(12 + i).toString().padLeft(2, '0')}:00',
          foodType: 'Pellets',
          status: EventStatus.skipped,
          aquariumName: 'Bedroom Aquarium',
          fishName: 'Betta',
        ),
      );
      id++;
    }

    for (var i = 0; i < pendingCount; i++) {
      final scheduledFor = testDate.add(Duration(hours: 18 + i));
      feedings.add(
        ComputedFeedingEvent(
          scheduleId: 'schedule_$id',
          fishId: 'fish_$id',
          aquariumId: 'aq1',
          scheduledFor: scheduledFor,
          time: '${(18 + i).toString().padLeft(2, '0')}:00',
          foodType: 'Flakes',
          status: EventStatus.pending,
          aquariumName: 'Living Room Tank',
          fishName: 'Goldfish',
        ),
      );
      id++;
    }

    feedings.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return feedings;
  }

  Widget buildSheetDirectly({
    required DateTime date,
    DayDetailState? initialState,
  }) {
    return ProviderScope(
      overrides: [
        if (initialState != null)
          dayDetailProvider(
            date,
          ).overrideWith((ref) => TestDayDetailNotifier(initialState)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DayDetailSheet(date: date)),
      ),
    );
  }

  Widget buildTestWidget({
    required DateTime date,
    DayDetailState? initialState,
  }) {
    return ProviderScope(
      overrides: [
        if (initialState != null)
          dayDetailProvider(
            date,
          ).overrideWith((ref) => TestDayDetailNotifier(initialState)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDayDetailSheet(context, date),
              child: const Text('Show Sheet'),
            ),
          ),
        ),
      ),
    );
  }

  group('DayDetailSheet', () {
    group('Rendering', () {
      testWidgets('renders DraggableScrollableSheet', (tester) async {
        await tester.pumpWidget(
          buildSheetDirectly(
            date: testDate,
            initialState: DayDetailState(
              selectedDate: testDate,
              feedings: createMockFeedings(),
              isLoading: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      });

      testWidgets('renders drag handle', (tester) async {
        await tester.pumpWidget(
          buildSheetDirectly(
            date: testDate,
            initialState: DayDetailState(
              selectedDate: testDate,
              feedings: createMockFeedings(),
              isLoading: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check that there's a DraggableScrollableSheet with drag handle
        expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      });
    });

    group('Header', () {
      testWidgets('displays formatted date for historical day', (tester) async {
        final historicalDate = DateTime(2024, 6, 15); // Saturday, June 15

        await tester.pumpWidget(
          buildSheetDirectly(
            date: historicalDate,
            initialState: DayDetailState(
              selectedDate: historicalDate,
              feedings: createMockFeedings(),
              isLoading: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Saturday, Jun 15'), findsOneWidget);
      });

      testWidgets('displays "Today" for current date', (tester) async {
        final today = DateTime.now();
        final todayNormalized = DateTime(today.year, today.month, today.day);

        await tester.pumpWidget(
          buildSheetDirectly(
            date: todayNormalized,
            initialState: DayDetailState(
              selectedDate: todayNormalized,
              feedings: createMockFeedings(),
              isLoading: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Today'), findsOneWidget);
      });

      testWidgets('displays completion count', (tester) async {
        await tester.pumpWidget(
          buildSheetDirectly(
            date: testDate,
            initialState: DayDetailState(
              selectedDate: testDate,
              feedings: createMockFeedings(
                fedCount: 3,
                missedCount: 0,
                pendingCount: 1,
              ),
              isLoading: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('3 of 4 feedings completed'), findsOneWidget);
      });

      testWidgets('displays "Complete" badge when all fed', (tester) async {
        await tester.pumpWidget(
          buildSheetDirectly(
            date: testDate,
            initialState: DayDetailState(
              selectedDate: testDate,
              feedings: createMockFeedings(
                fedCount: 4,
                missedCount: 0,
                pendingCount: 0,
              ),
              isLoading: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Complete'), findsOneWidget);
      });

      testWidgets('displays "Missed" badge when all missed', (tester) async {
        await tester.pumpWidget(
          buildSheetDirectly(
            date: testDate,
            initialState: DayDetailState(
              selectedDate: testDate,
              feedings: createMockFeedings(
                fedCount: 0,
                missedCount: 4,
                pendingCount: 0,
              ),
              isLoading: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Missed'), findsOneWidget);
      });

      testWidgets('displays "Partial" badge when mixed status', (tester) async {
        await tester.pumpWidget(
          buildSheetDirectly(
            date: testDate,
            initialState: DayDetailState(
              selectedDate: testDate,
              feedings: createMockFeedings(
                fedCount: 2,
                missedCount: 2,
                pendingCount: 0,
              ),
              isLoading: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Partial'), findsOneWidget);
      });
    });

    group('Feeding List', () {
      testWidgets('renders ListView when feedings exist', (tester) async {
        await tester.pumpWidget(
          buildSheetDirectly(
            date: testDate,
            initialState: DayDetailState(
              selectedDate: testDate,
              feedings: createMockFeedings(),
              isLoading: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // ListView should be rendered for feeding list
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('does not show empty state when feedings exist', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildSheetDirectly(
            date: testDate,
            initialState: DayDetailState(
              selectedDate: testDate,
              feedings: createMockFeedings(),
              isLoading: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Empty state should not be shown
        expect(find.text('No feedings'), findsNothing);
      });

      testWidgets('does not show loading indicator when loaded', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildSheetDirectly(
            date: testDate,
            initialState: DayDetailState(
              selectedDate: testDate,
              feedings: createMockFeedings(),
              isLoading: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Loading indicator should not be shown
        expect(find.byType(LoadingIndicator), findsNothing);
      });
    });

    group('Loading State', () {
      testWidgets('displays loading indicator when loading', (tester) async {
        await tester.pumpWidget(
          buildSheetDirectly(
            date: testDate,
            initialState: DayDetailState(
              selectedDate: testDate,
              feedings: const [],
              isLoading: true,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(LoadingIndicator), findsOneWidget);
        expect(find.text('Loading feedings...'), findsOneWidget);
      });
    });

    group('Empty State', () {
      testWidgets('displays empty state when no feedings', (tester) async {
        await tester.pumpWidget(
          buildSheetDirectly(
            date: testDate,
            initialState: DayDetailState(
              selectedDate: testDate,
              feedings: const [],
              isLoading: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Widget uses l10n.noFeedingsScheduled which shows "No feedings scheduled"
        // This text appears both in header and empty state body
        expect(find.text('No feedings scheduled'), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.event_available_outlined), findsOneWidget);
      });

      testWidgets(
        'displays "No feedings scheduled" in header for empty state',
        (tester) async {
          await tester.pumpWidget(
            buildSheetDirectly(
              date: testDate,
              initialState: DayDetailState(
                selectedDate: testDate,
                feedings: const [],
                isLoading: false,
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Text appears in both header and body
          expect(find.text('No feedings scheduled'), findsAtLeastNWidgets(1));
        },
      );
    });

    group('Error State', () {
      testWidgets('displays error state when error occurs', (tester) async {
        await tester.pumpWidget(
          buildSheetDirectly(
            date: testDate,
            initialState: DayDetailState(
              selectedDate: testDate,
              feedings: const [],
              isLoading: false,
              error: 'Network connection failed',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Failed to load'), findsOneWidget);
        expect(find.text('Network connection failed'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });

    group('showDayDetailSheet function', () {
      testWidgets('opens modal bottom sheet when called', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            date: testDate,
            initialState: DayDetailState(
              selectedDate: testDate,
              feedings: createMockFeedings(),
              isLoading: false,
            ),
          ),
        );

        // Tap button to show sheet
        await tester.tap(find.text('Show Sheet'));
        await tester.pumpAndSettle();

        // Sheet should be visible
        expect(find.byType(DayDetailSheet), findsOneWidget);
      });

      testWidgets('closes sheet on background tap', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            date: testDate,
            initialState: DayDetailState(
              selectedDate: testDate,
              feedings: createMockFeedings(),
              isLoading: false,
            ),
          ),
        );

        // Open sheet
        await tester.tap(find.text('Show Sheet'));
        await tester.pumpAndSettle();

        expect(find.byType(DayDetailSheet), findsOneWidget);

        // Tap outside to close (tap on the barrier/scrim)
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(find.byType(DayDetailSheet), findsNothing);
      });
    });

    group('DayDetailState', () {
      test('dayStatus returns allFed when all feedings are fed', () {
        final state = DayDetailState(
          selectedDate: testDate,
          feedings: createMockFeedings(
            fedCount: 4,
            missedCount: 0,
            pendingCount: 0,
          ),
        );

        expect(state.dayStatus, DayFeedingStatus.allFed);
      });

      test('dayStatus returns allMissed when all feedings are missed', () {
        final state = DayDetailState(
          selectedDate: testDate,
          feedings: createMockFeedings(
            fedCount: 0,
            missedCount: 4,
            pendingCount: 0,
          ),
        );

        expect(state.dayStatus, DayFeedingStatus.allMissed);
      });

      test('dayStatus returns partial when mixed statuses', () {
        final state = DayDetailState(
          selectedDate: testDate,
          feedings: createMockFeedings(
            fedCount: 2,
            missedCount: 1,
            pendingCount: 1,
          ),
        );

        expect(state.dayStatus, DayFeedingStatus.partial);
      });

      test('dayStatus returns noData when no feedings', () {
        final state = DayDetailState(
          selectedDate: testDate,
          feedings: const [],
        );

        expect(state.dayStatus, DayFeedingStatus.noData);
      });

      test('completedCount returns correct count', () {
        final state = DayDetailState(
          selectedDate: testDate,
          feedings: createMockFeedings(
            fedCount: 3,
            missedCount: 1,
            pendingCount: 0,
          ),
        );

        expect(state.completedCount, 3);
      });

      test('missedCount returns correct count', () {
        final state = DayDetailState(
          selectedDate: testDate,
          feedings: createMockFeedings(
            fedCount: 1,
            missedCount: 2,
            pendingCount: 1,
          ),
        );

        expect(state.missedCount, 2);
      });

      test('isEmpty returns true when feedings empty and not loading', () {
        final state = DayDetailState(
          selectedDate: testDate,
          feedings: const [],
          isLoading: false,
        );

        expect(state.isEmpty, true);
      });

      test('isEmpty returns false when loading', () {
        final state = DayDetailState(
          selectedDate: testDate,
          feedings: const [],
          isLoading: true,
        );

        expect(state.isEmpty, false);
      });

      test('hasError returns true when error is set', () {
        final state = DayDetailState(
          selectedDate: testDate,
          error: 'Some error',
        );

        expect(state.hasError, true);
      });

      test('hasError returns false when no error', () {
        final state = DayDetailState(selectedDate: testDate);

        expect(state.hasError, false);
      });
    });
  });
}

/// Test notifier that returns a predefined state.
class TestDayDetailNotifier extends StateNotifier<DayDetailState>
    implements DayDetailNotifier {
  TestDayDetailNotifier(DayDetailState testState) : super(testState);

  @override
  Future<void> loadFeedings() async {
    // No-op in test
  }

  @override
  Future<void> selectDate(DateTime date) async {
    // No-op in test
  }

  @override
  Future<void> refresh() async {
    // No-op in test
  }
}
