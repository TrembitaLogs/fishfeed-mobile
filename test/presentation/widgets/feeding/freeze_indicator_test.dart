import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/widgets/feeding/freeze_indicator.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({
    required int available,
    int total = 2,
    FreezeIndicatorSize size = FreezeIndicatorSize.medium,
    bool showTooltip = true,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: FreezeIndicator(
            available: available,
            total: total,
            size: size,
            showTooltip: showTooltip,
          ),
        ),
      ),
    );
  }

  group('FreezeIndicator', () {
    group('Display', () {
      testWidgets('displays correct number of snowflake icons', (tester) async {
        await tester.pumpWidget(buildTestWidget(available: 2, total: 2));

        expect(find.byIcon(Icons.ac_unit), findsNWidgets(2));
      });

      testWidgets('displays custom total of icons', (tester) async {
        await tester.pumpWidget(buildTestWidget(available: 3, total: 4));

        expect(find.byIcon(Icons.ac_unit), findsNWidgets(3));
        expect(find.byIcon(Icons.ac_unit_outlined), findsNWidgets(1));
      });

      testWidgets('displays zero available freeze days', (tester) async {
        await tester.pumpWidget(buildTestWidget(available: 0, total: 2));

        expect(find.byIcon(Icons.ac_unit_outlined), findsNWidgets(2));
        expect(find.byIcon(Icons.ac_unit), findsNothing);
      });

      testWidgets('displays all available freeze days', (tester) async {
        await tester.pumpWidget(buildTestWidget(available: 2, total: 2));

        expect(find.byIcon(Icons.ac_unit), findsNWidgets(2));
        expect(find.byIcon(Icons.ac_unit_outlined), findsNothing);
      });

      testWidgets('displays partially available freeze days', (tester) async {
        await tester.pumpWidget(buildTestWidget(available: 1, total: 2));

        expect(find.byIcon(Icons.ac_unit), findsNWidgets(1));
        expect(find.byIcon(Icons.ac_unit_outlined), findsNWidgets(1));
      });
    });

    group('Size Variants', () {
      testWidgets('small size renders smaller icons', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(available: 2, size: FreezeIndicatorSize.small),
        );

        final icons = tester.widgetList<Icon>(find.byIcon(Icons.ac_unit));
        for (final icon in icons) {
          expect(icon.size, equals(14));
        }
      });

      testWidgets('medium size renders default icons', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(available: 2, size: FreezeIndicatorSize.medium),
        );

        final icons = tester.widgetList<Icon>(find.byIcon(Icons.ac_unit));
        for (final icon in icons) {
          expect(icon.size, equals(18));
        }
      });

      testWidgets('large size renders larger icons', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(available: 2, size: FreezeIndicatorSize.large),
        );

        final icons = tester.widgetList<Icon>(find.byIcon(Icons.ac_unit));
        for (final icon in icons) {
          expect(icon.size, equals(24));
        }
      });
    });

    group('Tooltip', () {
      testWidgets('has tooltip when showTooltip is true', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(available: 2, showTooltip: true),
        );

        expect(find.byType(Tooltip), findsOneWidget);
      });

      testWidgets('no tooltip when showTooltip is false', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(available: 2, showTooltip: false),
        );

        expect(find.byType(Tooltip), findsNothing);
      });

      testWidgets('tooltip shows plural message for multiple freeze days', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(available: 2));

        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, equals('2 freeze days available'));
      });

      testWidgets('tooltip shows singular message for one freeze day', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(available: 1));

        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, equals('1 freeze day available'));
      });

      testWidgets('tooltip shows no freeze message when none available', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(available: 0));

        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, equals('No freeze days left this month'));
      });
    });

    group('Icon Colors', () {
      testWidgets('active icons have cyan color', (tester) async {
        await tester.pumpWidget(buildTestWidget(available: 2));

        final icons = tester.widgetList<Icon>(find.byIcon(Icons.ac_unit));
        for (final icon in icons) {
          expect(icon.color, equals(Colors.cyan.shade600));
        }
      });

      testWidgets('inactive icons have faded color', (tester) async {
        await tester.pumpWidget(buildTestWidget(available: 0, total: 2));

        final icons = tester.widgetList<Icon>(
          find.byIcon(Icons.ac_unit_outlined),
        );
        for (final icon in icons) {
          // Color should have reduced alpha (using 0.0-1.0 scale)
          expect(icon.color!.a, lessThan(1.0));
        }
      });
    });

    group('Animation', () {
      testWidgets('contains Transform for pulse animation', (tester) async {
        await tester.pumpWidget(buildTestWidget(available: 2));

        expect(find.byType(Transform), findsWidgets);
      });

      testWidgets('triggers animation when available count changes', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(available: 2));
        await tester.pumpAndSettle();

        // Update to lower count
        await tester.pumpWidget(buildTestWidget(available: 1));
        await tester.pump(const Duration(milliseconds: 100));

        // Animation should be running
        expect(find.byType(Transform), findsWidgets);
      });
    });

    group('Widget Structure', () {
      testWidgets('contains Container with border decoration', (tester) async {
        await tester.pumpWidget(buildTestWidget(available: 2));

        final containers = tester.widgetList<Container>(
          find.descendant(
            of: find.byType(FreezeIndicator),
            matching: find.byType(Container),
          ),
        );

        // Find the main container with decoration
        Container? decoratedContainer;
        for (final container in containers) {
          if (container.decoration != null) {
            decoratedContainer = container;
            break;
          }
        }

        expect(decoratedContainer, isNotNull);
        expect(decoratedContainer!.decoration, isA<BoxDecoration>());
      });

      testWidgets('contains Row for horizontal layout', (tester) async {
        await tester.pumpWidget(buildTestWidget(available: 2));

        expect(find.byType(Row), findsOneWidget);
      });
    });
  });
}
