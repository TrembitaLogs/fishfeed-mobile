import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/domain/entities/day_feeding_status.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/widgets/calendar/calendar_day_cell.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({
    required DateTime day,
    required DayFeedingStatus status,
    bool isSelected = false,
    bool isToday = false,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 48,
            height: 48,
            child: CalendarDayCell(
              day: day,
              status: status,
              isSelected: isSelected,
              isToday: isToday,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }

  group('CalendarDayCell', () {
    group('Day Display', () {
      testWidgets('displays correct day number', (tester) async {
        final day = DateTime(2024, 1, 15);
        await tester.pumpWidget(
          buildTestWidget(day: day, status: DayFeedingStatus.noData),
        );

        expect(find.text('15'), findsOneWidget);
      });

      testWidgets('displays single digit day correctly', (tester) async {
        final day = DateTime(2024, 1, 5);
        await tester.pumpWidget(
          buildTestWidget(day: day, status: DayFeedingStatus.noData),
        );

        expect(find.text('5'), findsOneWidget);
      });
    });

    group('Status Colors', () {
      test('getStatusColor returns green for allFed', () {
        expect(
          CalendarDayCell.getStatusColor(DayFeedingStatus.allFed),
          equals(CalendarDayCell.colorAllFed),
        );
      });

      test('getStatusColor returns red for allMissed', () {
        expect(
          CalendarDayCell.getStatusColor(DayFeedingStatus.allMissed),
          equals(CalendarDayCell.colorAllMissed),
        );
      });

      test('getStatusColor returns yellow for partial', () {
        expect(
          CalendarDayCell.getStatusColor(DayFeedingStatus.partial),
          equals(CalendarDayCell.colorPartial),
        );
      });

      test('getStatusColor returns gray for noData', () {
        expect(
          CalendarDayCell.getStatusColor(DayFeedingStatus.noData),
          equals(CalendarDayCell.colorNoData),
        );
      });
    });

    group('Status Dot Indicator', () {
      testWidgets('shows green dot for allFed status', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            day: DateTime(2024, 1, 15),
            status: DayFeedingStatus.allFed,
          ),
        );

        final dotFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
              (widget.decoration as BoxDecoration).color ==
                  CalendarDayCell.colorAllFed,
        );

        expect(dotFinder, findsOneWidget);
      });

      testWidgets('shows red dot for allMissed status', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            day: DateTime(2024, 1, 15),
            status: DayFeedingStatus.allMissed,
          ),
        );

        final dotFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
              (widget.decoration as BoxDecoration).color ==
                  CalendarDayCell.colorAllMissed,
        );

        expect(dotFinder, findsOneWidget);
      });

      testWidgets('shows yellow dot for partial status', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            day: DateTime(2024, 1, 15),
            status: DayFeedingStatus.partial,
          ),
        );

        final dotFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
              (widget.decoration as BoxDecoration).color ==
                  CalendarDayCell.colorPartial,
        );

        expect(dotFinder, findsOneWidget);
      });

      testWidgets('hides dot for noData status', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            day: DateTime(2024, 1, 15),
            status: DayFeedingStatus.noData,
          ),
        );

        final dotFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
              (widget.decoration as BoxDecoration).color != null,
        );

        expect(dotFinder, findsNothing);
      });
    });

    group('Selection State', () {
      testWidgets('shows primary background when selected', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            day: DateTime(2024, 1, 15),
            status: DayFeedingStatus.allFed,
            isSelected: true,
          ),
        );

        final containerFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  AppTheme.lightTheme.colorScheme.primary,
        );

        expect(containerFinder, findsOneWidget);
      });

      testWidgets('shows transparent background when not selected', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            day: DateTime(2024, 1, 15),
            status: DayFeedingStatus.allFed,
            isSelected: false,
            isToday: false,
          ),
        );

        final containerFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.transparent,
        );

        expect(containerFinder, findsOneWidget);
      });
    });

    group('Today State', () {
      testWidgets('shows border when today but not selected', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            day: DateTime(2024, 1, 15),
            status: DayFeedingStatus.noData,
            isToday: true,
            isSelected: false,
          ),
        );

        final containerFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).border != null,
        );

        expect(containerFinder, findsOneWidget);
      });

      testWidgets('hides border when today and selected', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            day: DateTime(2024, 1, 15),
            status: DayFeedingStatus.noData,
            isToday: true,
            isSelected: true,
          ),
        );

        final containerFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).border == null &&
              (widget.decoration as BoxDecoration).color ==
                  AppTheme.lightTheme.colorScheme.primary,
        );

        expect(containerFinder, findsOneWidget);
      });
    });

    group('Interaction', () {
      testWidgets('calls onTap when tapped', (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          buildTestWidget(
            day: DateTime(2024, 1, 15),
            status: DayFeedingStatus.allFed,
            onTap: () => tapped = true,
          ),
        );

        await tester.tap(find.byType(CalendarDayCell));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('contains InkWell for tap feedback', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            day: DateTime(2024, 1, 15),
            status: DayFeedingStatus.allFed,
          ),
        );

        expect(find.byType(InkWell), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('getStatusLabel returns correct labels', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            day: DateTime(2024, 1, 15),
            status: DayFeedingStatus.allFed,
          ),
        );
        await tester.pumpAndSettle();

        // Access l10n from widget context
        final context = tester.element(find.byType(CalendarDayCell));
        final l10n = AppLocalizations.of(context)!;

        expect(
          CalendarDayCell.getStatusLabel(DayFeedingStatus.allFed, l10n),
          equals('All feedings completed'),
        );
        expect(
          CalendarDayCell.getStatusLabel(DayFeedingStatus.allMissed, l10n),
          equals('All feedings missed'),
        );
        expect(
          CalendarDayCell.getStatusLabel(DayFeedingStatus.partial, l10n),
          equals('Some feedings completed'),
        );
        expect(
          CalendarDayCell.getStatusLabel(DayFeedingStatus.noData, l10n),
          equals('No feeding data'),
        );
      });

      testWidgets('has Semantics widget with label', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            day: DateTime(2024, 1, 15),
            status: DayFeedingStatus.allFed,
          ),
        );

        final semanticsFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label != null &&
              widget.properties.label!.contains('15'),
        );

        expect(semanticsFinder, findsOneWidget);
      });

      testWidgets('semantic label includes day and status', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            day: DateTime(2024, 1, 15),
            status: DayFeedingStatus.allFed,
          ),
        );

        final semanticsFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label != null &&
              widget.properties.label!.contains('15') &&
              widget.properties.label!.contains('All feedings completed'),
        );

        expect(semanticsFinder, findsOneWidget);
      });

      testWidgets('semantic label includes selected state', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            day: DateTime(2024, 1, 15),
            status: DayFeedingStatus.allFed,
            isSelected: true,
          ),
        );

        final semanticsFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label != null &&
              widget.properties.label!.contains('selected'),
        );

        expect(semanticsFinder, findsOneWidget);
      });

      testWidgets('semantic label includes today state', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            day: DateTime(2024, 1, 15),
            status: DayFeedingStatus.allFed,
            isToday: true,
          ),
        );

        final semanticsFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label != null &&
              widget.properties.label!.contains('today'),
        );

        expect(semanticsFinder, findsOneWidget);
      });
    });

    group('Color Constants', () {
      test('colorAllFed is correct green value', () {
        expect(CalendarDayCell.colorAllFed, equals(const Color(0xFF4CAF50)));
      });

      test('colorAllMissed is correct red value', () {
        expect(CalendarDayCell.colorAllMissed, equals(const Color(0xFFF44336)));
      });

      test('colorPartial is correct yellow value', () {
        expect(CalendarDayCell.colorPartial, equals(const Color(0xFFFFC107)));
      });

      test('colorNoData is correct gray value', () {
        expect(CalendarDayCell.colorNoData, equals(const Color(0xFF9E9E9E)));
      });
    });
  });
}
