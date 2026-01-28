import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/widgets/feeding/streak_badge.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({
    required int streak,
    int? previousStreak,
    StreakBadgeSize size = StreakBadgeSize.medium,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: StreakBadge(
            streak: streak,
            previousStreak: previousStreak,
            size: size,
          ),
        ),
      ),
    );
  }

  group('StreakBadge', () {
    group('Display', () {
      testWidgets('displays streak number', (tester) async {
        await tester.pumpWidget(buildTestWidget(streak: 5));

        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('displays zero streak', (tester) async {
        await tester.pumpWidget(buildTestWidget(streak: 0));

        expect(find.text('0'), findsOneWidget);
      });

      testWidgets('displays large streak numbers', (tester) async {
        await tester.pumpWidget(buildTestWidget(streak: 100));

        expect(find.text('100'), findsOneWidget);
      });

      testWidgets('displays fire icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(streak: 5));

        expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      });
    });

    group('Color Changes', () {
      testWidgets('uses amber color for streak < 7', (tester) async {
        await tester.pumpWidget(buildTestWidget(streak: 3));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(StreakBadge),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        final gradient = decoration.gradient as LinearGradient;

        expect(gradient.colors.first, equals(Colors.amber.shade100));
      });

      testWidgets('uses orange color for streak 7-30', (tester) async {
        await tester.pumpWidget(buildTestWidget(streak: 15));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(StreakBadge),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        final gradient = decoration.gradient as LinearGradient;

        expect(gradient.colors.first, equals(Colors.orange.shade100));
      });

      testWidgets('uses red color for streak > 30', (tester) async {
        await tester.pumpWidget(buildTestWidget(streak: 50));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(StreakBadge),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        final gradient = decoration.gradient as LinearGradient;

        expect(gradient.colors.first, equals(Colors.red.shade100));
      });

      testWidgets('streak exactly 7 uses orange', (tester) async {
        await tester.pumpWidget(buildTestWidget(streak: 7));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(StreakBadge),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        final gradient = decoration.gradient as LinearGradient;

        expect(gradient.colors.first, equals(Colors.orange.shade100));
      });

      testWidgets('streak exactly 30 uses orange', (tester) async {
        await tester.pumpWidget(buildTestWidget(streak: 30));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(StreakBadge),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        final gradient = decoration.gradient as LinearGradient;

        expect(gradient.colors.first, equals(Colors.orange.shade100));
      });
    });

    group('Size Variants', () {
      testWidgets('small size renders smaller dimensions', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          streak: 5,
          size: StreakBadgeSize.small,
        ));

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.local_fire_department),
        );

        expect(icon.size, equals(14));
      });

      testWidgets('medium size renders default dimensions', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          streak: 5,
          size: StreakBadgeSize.medium,
        ));

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.local_fire_department),
        );

        expect(icon.size, equals(18));
      });

      testWidgets('large size renders larger dimensions', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          streak: 5,
          size: StreakBadgeSize.large,
        ));

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.local_fire_department),
        );

        expect(icon.size, equals(24));
      });
    });

    group('Tooltip', () {
      testWidgets('has tooltip with correct message', (tester) async {
        await tester.pumpWidget(buildTestWidget(streak: 5));

        expect(find.byType(Tooltip), findsOneWidget);

        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, equals('5 days in a row!'));
      });

      testWidgets('tooltip message updates with streak', (tester) async {
        await tester.pumpWidget(buildTestWidget(streak: 10));

        final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
        expect(tooltip.message, equals('10 days in a row!'));
      });
    });

    group('Animation', () {
      testWidgets('contains Transform.scale for animation', (tester) async {
        await tester.pumpWidget(buildTestWidget(streak: 5));

        expect(find.byType(Transform), findsWidgets);
      });

      testWidgets('animates when streak increases', (tester) async {
        await tester.pumpWidget(buildTestWidget(streak: 5));
        await tester.pumpAndSettle();

        // Update to higher streak
        await tester.pumpWidget(buildTestWidget(streak: 6));

        // Check that animation controller started (widget should be mid-animation)
        await tester.pump(const Duration(milliseconds: 100));

        // The Transform should exist and animation should be running
        expect(find.byType(Transform), findsWidgets);
      });

      testWidgets('animates when previousStreak triggers', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          streak: 10,
          previousStreak: 9,
        ));

        // Animation should be triggered
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(Transform), findsWidgets);
      });
    });

    group('Widget Structure', () {
      testWidgets('contains Container with gradient decoration', (tester) async {
        await tester.pumpWidget(buildTestWidget(streak: 5));

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(StreakBadge),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.decoration, isA<BoxDecoration>());
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.gradient, isA<LinearGradient>());
      });

      testWidgets('contains Row with icon and text', (tester) async {
        await tester.pumpWidget(buildTestWidget(streak: 5));

        expect(find.byType(Row), findsOneWidget);
        expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      });
    });
  });
}
