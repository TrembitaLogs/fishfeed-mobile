import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/widgets/paywall/trial_banner.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({int trialDays = 7, bool isCompact = false}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: TrialBanner(trialDays: trialDays, isCompact: isCompact),
      ),
    );
  }

  group('TrialBanner', () {
    group('default (non-compact) mode', () {
      testWidgets('renders trial days text', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('7 Days Free'), findsOneWidget);
      });

      testWidgets('renders description text', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(
          find.text('Try all premium features. Cancel anytime.'),
          findsOneWidget,
        );
      });

      testWidgets('renders gift icon', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.byIcon(Icons.card_giftcard), findsOneWidget);
      });

      testWidgets('respects custom trial days', (tester) async {
        await tester.pumpWidget(buildTestWidget(trialDays: 14));

        expect(find.text('14 Days Free'), findsOneWidget);
        expect(find.text('7 Days Free'), findsNothing);
      });

      testWidgets('has correct layout structure', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Should have a Row with icon and Column
        expect(find.byType(Row), findsWidgets);
        expect(find.byType(Column), findsWidgets);
      });
    });

    group('compact mode', () {
      testWidgets('renders compact trial text', (tester) async {
        await tester.pumpWidget(buildTestWidget(isCompact: true));

        expect(find.text('7-day free trial'), findsOneWidget);
      });

      testWidgets('does not show full description in compact mode', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(isCompact: true));

        expect(
          find.text('Try all premium features. Cancel anytime.'),
          findsNothing,
        );
      });

      testWidgets('renders gift icon in compact mode', (tester) async {
        await tester.pumpWidget(buildTestWidget(isCompact: true));

        expect(find.byIcon(Icons.card_giftcard), findsOneWidget);
      });

      testWidgets('respects custom trial days in compact mode', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(trialDays: 14, isCompact: true),
        );

        expect(find.text('14-day free trial'), findsOneWidget);
        expect(find.text('7-day free trial'), findsNothing);
      });
    });

    group('styling', () {
      testWidgets('default mode has gradient background', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        final containerFinder = find.byType(Container).first;
        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.gradient, isNotNull);
        expect(decoration.gradient, isA<LinearGradient>());
      });

      testWidgets('compact mode has simple background', (tester) async {
        await tester.pumpWidget(buildTestWidget(isCompact: true));

        final containerFinder = find.byType(Container).first;
        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.color, isNotNull);
        expect(decoration.gradient, isNull);
      });
    });
  });
}
