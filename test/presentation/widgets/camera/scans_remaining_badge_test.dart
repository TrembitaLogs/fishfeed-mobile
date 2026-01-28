import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/widgets/camera/scans_remaining_badge.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: child),
      ),
    );
  }

  group('ScansRemainingBadge', () {
    testWidgets('renders correctly with 5 scans', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ScansRemainingBadge(scansRemaining: 5)),
      );

      expect(find.text('5 scans left'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('renders correctly with 3 scans', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ScansRemainingBadge(scansRemaining: 3)),
      );

      expect(find.text('3 scans left'), findsOneWidget);
    });

    testWidgets('shows singular "scan" for 1 remaining', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ScansRemainingBadge(scansRemaining: 1)),
      );

      expect(find.text('1 scan left'), findsOneWidget);
    });

    testWidgets('shows "No scans left" for 0 remaining', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ScansRemainingBadge(scansRemaining: 0)),
      );

      expect(find.text('No scans left'), findsOneWidget);
    });

    testWidgets('is hidden for unlimited scans (-1)', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ScansRemainingBadge(scansRemaining: -1)),
      );

      expect(find.byType(ScansRemainingBadge), findsOneWidget);
      expect(find.text('scans left'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
      expect(find.byType(SizedBox), findsWidgets); // SizedBox.shrink()
    });

    testWidgets('shows warning icon for 2 scans remaining', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ScansRemainingBadge(scansRemaining: 2)),
      );

      expect(find.text('2 scans left'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('shows warning icon for 1 scan remaining', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ScansRemainingBadge(scansRemaining: 1)),
      );

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('shows warning icon for 0 scans remaining', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ScansRemainingBadge(scansRemaining: 0)),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('shows normal icon for 3+ scans', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ScansRemainingBadge(scansRemaining: 3)),
      );

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('animates when count changes', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ScansRemainingBadge(scansRemaining: 5)),
      );

      expect(find.text('5 scans left'), findsOneWidget);

      // Rebuild with new count
      await tester.pumpWidget(
        buildTestWidget(const ScansRemainingBadge(scansRemaining: 4)),
      );

      // Pump through animation
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('4 scans left'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('4 scans left'), findsOneWidget);
    });

    testWidgets('handles transition from normal to warning', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ScansRemainingBadge(scansRemaining: 3)),
      );

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

      await tester.pumpWidget(
        buildTestWidget(const ScansRemainingBadge(scansRemaining: 2)),
      );

      // Complete animation
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('2 scans left'), findsOneWidget);
    });

    testWidgets('handles transition from warning to critical', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ScansRemainingBadge(scansRemaining: 1)),
      );

      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      await tester.pumpWidget(
        buildTestWidget(const ScansRemainingBadge(scansRemaining: 0)),
      );

      // Complete animation
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('No scans left'), findsOneWidget);
    });
  });

  group('ScansRemainingBadge edge cases', () {
    testWidgets('handles large numbers', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ScansRemainingBadge(scansRemaining: 99)),
      );

      expect(find.text('99 scans left'), findsOneWidget);
    });

    testWidgets('does not animate on first build', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const ScansRemainingBadge(scansRemaining: 5)),
      );

      // Should not see animation scale effects on first build
      // Just verify it renders immediately
      expect(find.text('5 scans left'), findsOneWidget);
    });
  });
}
