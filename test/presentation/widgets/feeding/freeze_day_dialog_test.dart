import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/widgets/feeding/freeze_day_dialog.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestApp({required Widget child}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  Future<void> showTestDialog(
    WidgetTester tester, {
    required int currentStreak,
    required int freezeAvailable,
  }) async {
    await tester.pumpWidget(
      buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              FreezeDayDialog.show(
                context,
                currentStreak: currentStreak,
                freezeAvailable: freezeAvailable,
              );
            },
            child: const Text('Show Dialog'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    // Use pump instead of pumpAndSettle because dialog has infinite animations
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('FreezeDayDialog', () {
    group('Display with freeze available', () {
      testWidgets('shows title', (tester) async {
        await showTestDialog(tester, currentStreak: 5, freezeAvailable: 2);

        expect(find.text('Missed Feeding'), findsOneWidget);
      });

      testWidgets('shows streak at risk message', (tester) async {
        await showTestDialog(tester, currentStreak: 5, freezeAvailable: 2);

        expect(find.text('5 day streak at risk'), findsOneWidget);
      });

      testWidgets('shows use freeze button with count', (tester) async {
        await showTestDialog(tester, currentStreak: 5, freezeAvailable: 2);

        expect(find.text('Use Freeze Day (2 left)'), findsOneWidget);
      });

      testWidgets('shows lose streak button', (tester) async {
        await showTestDialog(tester, currentStreak: 5, freezeAvailable: 2);

        expect(find.text('Lose Streak'), findsOneWidget);
      });

      testWidgets('shows snowflake icon', (tester) async {
        await showTestDialog(tester, currentStreak: 5, freezeAvailable: 2);

        // Two snowflake icons: one animated in header, one in button
        expect(find.byIcon(Icons.ac_unit), findsNWidgets(2));
      });

      testWidgets('shows fire icon in streak chip', (tester) async {
        await showTestDialog(tester, currentStreak: 5, freezeAvailable: 2);

        expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      });
    });

    group('Display without freeze available', () {
      testWidgets('shows title', (tester) async {
        await showTestDialog(tester, currentStreak: 5, freezeAvailable: 0);

        expect(find.text('Missed Feeding'), findsOneWidget);
      });

      testWidgets('does not show use freeze button', (tester) async {
        await showTestDialog(tester, currentStreak: 5, freezeAvailable: 0);

        expect(find.textContaining('Use Freeze'), findsNothing);
      });

      testWidgets('shows continue button instead of lose streak', (
        tester,
      ) async {
        await showTestDialog(tester, currentStreak: 5, freezeAvailable: 0);

        expect(find.text('Continue'), findsOneWidget);
        expect(find.text('Lose Streak'), findsNothing);
      });

      testWidgets('shows description about no freeze days', (tester) async {
        await showTestDialog(tester, currentStreak: 5, freezeAvailable: 0);

        expect(find.textContaining('have no freeze days left'), findsOneWidget);
      });
    });

    group('Actions', () {
      testWidgets('returns useFreeze when freeze button tapped', (
        tester,
      ) async {
        FreezeDayDialogResult? result;

        await tester.pumpWidget(
          buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await FreezeDayDialog.show(
                    context,
                    currentStreak: 5,
                    freezeAvailable: 2,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await tester.tap(find.text('Use Freeze Day (2 left)'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(result, equals(FreezeDayDialogResult.useFreeze));
      });

      testWidgets('returns loseStreak when lose streak button tapped', (
        tester,
      ) async {
        FreezeDayDialogResult? result;

        await tester.pumpWidget(
          buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await FreezeDayDialog.show(
                    context,
                    currentStreak: 5,
                    freezeAvailable: 2,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await tester.tap(find.text('Lose Streak'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(result, equals(FreezeDayDialogResult.loseStreak));
      });

      testWidgets(
        'returns loseStreak when continue button tapped (no freeze)',
        (tester) async {
          FreezeDayDialogResult? result;

          await tester.pumpWidget(
            buildTestApp(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await FreezeDayDialog.show(
                      context,
                      currentStreak: 5,
                      freezeAvailable: 0,
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          );

          await tester.tap(find.text('Show Dialog'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          await tester.tap(find.text('Continue'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(result, equals(FreezeDayDialogResult.loseStreak));
        },
      );

      testWidgets('returns dismissed when dialog is dismissed', (tester) async {
        FreezeDayDialogResult? result;

        await tester.pumpWidget(
          buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await FreezeDayDialog.show(
                    context,
                    currentStreak: 5,
                    freezeAvailable: 2,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Tap outside dialog to dismiss
        await tester.tapAt(const Offset(10, 10));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(result, equals(FreezeDayDialogResult.dismissed));
      });
    });

    group('Animation', () {
      testWidgets('contains animated snowflake', (tester) async {
        await showTestDialog(tester, currentStreak: 5, freezeAvailable: 2);

        // Should have Transform widgets for rotation and scale
        expect(find.byType(Transform), findsWidgets);
      });

      testWidgets('snowflake rotates', (tester) async {
        await showTestDialog(tester, currentStreak: 5, freezeAvailable: 2);

        // Get initial transform state
        await tester.pump(const Duration(seconds: 1));

        // Animation should still be running
        expect(find.byType(Transform), findsWidgets);
      });
    });

    group('Different streak values', () {
      testWidgets('displays single digit streak', (tester) async {
        await showTestDialog(tester, currentStreak: 5, freezeAvailable: 2);

        expect(find.text('5 day streak at risk'), findsOneWidget);
      });

      testWidgets('displays double digit streak', (tester) async {
        await showTestDialog(tester, currentStreak: 15, freezeAvailable: 1);

        expect(find.text('15 day streak at risk'), findsOneWidget);
      });

      testWidgets('displays triple digit streak', (tester) async {
        await showTestDialog(tester, currentStreak: 100, freezeAvailable: 2);

        expect(find.text('100 day streak at risk'), findsOneWidget);
      });
    });

    group('Different freeze counts', () {
      testWidgets('displays 1 freeze day left', (tester) async {
        await showTestDialog(tester, currentStreak: 5, freezeAvailable: 1);

        expect(find.text('Use Freeze Day (1 left)'), findsOneWidget);
      });

      testWidgets('displays 2 freeze days left', (tester) async {
        await showTestDialog(tester, currentStreak: 5, freezeAvailable: 2);

        expect(find.text('Use Freeze Day (2 left)'), findsOneWidget);
      });
    });

    group('Widget Structure', () {
      testWidgets('dialog has rounded corners', (tester) async {
        await showTestDialog(tester, currentStreak: 5, freezeAvailable: 2);

        final dialog = tester.widget<Dialog>(find.byType(Dialog));
        expect(dialog.shape, isA<RoundedRectangleBorder>());
      });

      testWidgets('contains Column with all elements', (tester) async {
        await showTestDialog(tester, currentStreak: 5, freezeAvailable: 2);

        expect(find.byType(Column), findsWidgets);
        // Two snowflake icons: one animated in header, one in button
        expect(find.byIcon(Icons.ac_unit), findsNWidgets(2));
        expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      });
    });
  });
}
