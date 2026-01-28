import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/domain/entities/streak.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/widgets/profile/streak_section.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({required StreakState streakState}) {
    return ProviderScope(
      overrides: [
        currentStreakProvider.overrideWith((ref) {
          return _TestStreakNotifier(streakState);
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(child: StreakSection()),
        ),
      ),
    );
  }

  Streak createStreak({
    int currentStreak = 0,
    int longestStreak = 0,
    int freezeAvailable = 2,
  }) {
    return Streak(
      id: 'test_streak',
      userId: 'test_user',
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      freezeAvailable: freezeAvailable,
    );
  }

  group('StreakSection', () {
    group('Display', () {
      testWidgets('displays correct current streak value', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            streakState: StreakState(streak: createStreak(currentStreak: 5)),
          ),
        );

        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('displays correct longest streak value', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            streakState: StreakState(
              streak: createStreak(currentStreak: 5, longestStreak: 15),
            ),
          ),
        );

        expect(find.text('15'), findsOneWidget);
      });

      testWidgets('displays correct freeze days count', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            streakState: StreakState(streak: createStreak(freezeAvailable: 1)),
          ),
        );

        expect(find.text('1'), findsOneWidget);
      });

      testWidgets('displays all three stat labels', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(streakState: StreakState(streak: createStreak())),
        );

        expect(find.text('Current streak'), findsOneWidget);
        expect(find.text('Best'), findsOneWidget);
        expect(find.text('Freeze'), findsOneWidget);
      });

      testWidgets('displays section title', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(streakState: StreakState(streak: createStreak())),
        );

        expect(find.text('Streak'), findsOneWidget);
      });

      testWidgets('displays icons for all stat cards', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(streakState: StreakState(streak: createStreak())),
        );

        // Flame icon appears twice (title + stat card)
        expect(find.byIcon(Icons.local_fire_department), findsNWidgets(2));
        expect(find.byIcon(Icons.emoji_events), findsOneWidget);
        expect(find.byIcon(Icons.ac_unit), findsOneWidget);
      });
    });

    group('Loading State', () {
      testWidgets('shows shimmer when loading', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(streakState: const StreakState(isLoading: true)),
        );

        // Should not find stat values
        expect(find.text('Current streak'), findsNothing);

        // Should find shimmer containers (grey background)
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color ==
                    Colors.grey.shade200,
          ),
          findsOneWidget,
        );
      });

      testWidgets('does not show content when loading', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(streakState: const StreakState(isLoading: true)),
        );

        expect(find.text('Current streak'), findsNothing);
        expect(find.byIcon(Icons.emoji_events), findsNothing);
      });
    });

    group('Null Streak State', () {
      testWidgets('renders nothing when streak is null', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(streakState: const StreakState()),
        );

        expect(find.byType(SizedBox), findsWidgets);
        expect(find.text('Streak'), findsNothing);
      });
    });

    group('Gradient Colors', () {
      testWidgets('uses amber gradient for streak < 7', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            streakState: StreakState(streak: createStreak(currentStreak: 3)),
          ),
        );

        final containers = tester.widgetList<Container>(find.byType(Container));

        final gradientContainer = containers.firstWhere(
          (c) =>
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).gradient is LinearGradient &&
              (c.decoration as BoxDecoration).borderRadius != null,
          orElse: () => Container(),
        );

        final gradient =
            (gradientContainer.decoration as BoxDecoration).gradient
                as LinearGradient;
        expect(gradient.colors.first, equals(Colors.amber.shade300));
      });

      testWidgets('uses orange gradient for streak >= 7', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            streakState: StreakState(streak: createStreak(currentStreak: 15)),
          ),
        );

        final containers = tester.widgetList<Container>(find.byType(Container));

        final gradientContainer = containers.firstWhere(
          (c) =>
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).gradient is LinearGradient &&
              (c.decoration as BoxDecoration).borderRadius != null,
          orElse: () => Container(),
        );

        final gradient =
            (gradientContainer.decoration as BoxDecoration).gradient
                as LinearGradient;
        expect(gradient.colors.first, equals(Colors.orange.shade400));
      });

      testWidgets('uses red gradient for streak >= 30', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            streakState: StreakState(streak: createStreak(currentStreak: 50)),
          ),
        );

        final containers = tester.widgetList<Container>(find.byType(Container));

        final gradientContainer = containers.firstWhere(
          (c) =>
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).gradient is LinearGradient &&
              (c.decoration as BoxDecoration).borderRadius != null,
          orElse: () => Container(),
        );

        final gradient =
            (gradientContainer.decoration as BoxDecoration).gradient
                as LinearGradient;
        expect(gradient.colors.first, equals(Colors.red.shade400));
      });
    });

    group('Glow Effect', () {
      testWidgets('has glow effect when streak >= 7', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            streakState: StreakState(streak: createStreak(currentStreak: 10)),
          ),
        );

        final containers = tester.widgetList<Container>(find.byType(Container));

        final glowContainer = containers.firstWhere(
          (c) =>
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).boxShadow != null &&
              (c.decoration as BoxDecoration).boxShadow!.isNotEmpty,
          orElse: () => Container(),
        );

        final boxShadow =
            (glowContainer.decoration as BoxDecoration).boxShadow!.first;
        expect(boxShadow.blurRadius, equals(12));
      });

      testWidgets('no glow effect when streak < 7', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            streakState: StreakState(streak: createStreak(currentStreak: 3)),
          ),
        );

        final containers = tester.widgetList<Container>(find.byType(Container));

        final glowContainers = containers.where(
          (c) =>
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).boxShadow != null &&
              (c.decoration as BoxDecoration).boxShadow!.isNotEmpty,
        );

        expect(glowContainers, isEmpty);
      });
    });

    group('Milestone Badges', () {
      testWidgets('shows 7 days badge when streak >= 7', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            streakState: StreakState(streak: createStreak(currentStreak: 10)),
          ),
        );

        expect(find.text('7 days'), findsOneWidget);
        expect(find.byIcon(Icons.bolt), findsOneWidget);
      });

      testWidgets('shows 30 days badge when streak >= 30', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            streakState: StreakState(streak: createStreak(currentStreak: 45)),
          ),
        );

        expect(find.text('30 days'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('shows 100 days badge when streak >= 100', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            streakState: StreakState(streak: createStreak(currentStreak: 150)),
          ),
        );

        expect(find.text('100 days'), findsOneWidget);
        expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
      });

      testWidgets('no badge when streak < 7', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            streakState: StreakState(streak: createStreak(currentStreak: 3)),
          ),
        );

        expect(find.text('7 days'), findsNothing);
        expect(find.text('30 days'), findsNothing);
        expect(find.text('100 days'), findsNothing);
      });
    });

    group('Freeze Info Dialog', () {
      testWidgets('shows freeze info dialog on tap', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            streakState: StreakState(streak: createStreak(freezeAvailable: 2)),
          ),
        );

        // Find and tap the freeze card (the one with info icon)
        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Freeze Days'), findsOneWidget);
      });

      testWidgets('dialog shows correct freeze days info', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            streakState: StreakState(streak: createStreak(freezeAvailable: 1)),
          ),
        );

        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();

        expect(find.text('Available freeze days: 1'), findsOneWidget);
        expect(find.text('You get 2 freeze days per month'), findsOneWidget);
      });

      testWidgets('dialog can be dismissed', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(streakState: StreakState(streak: createStreak())),
        );

        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.tap(find.text('Got it'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('Animated Counter', () {
      testWidgets('current streak has AnimatedSwitcher', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            streakState: StreakState(streak: createStreak(currentStreak: 5)),
          ),
        );

        expect(find.byType(AnimatedSwitcher), findsOneWidget);
      });
    });
  });
}

/// Test-only StreakNotifier that returns a fixed state.
class _TestStreakNotifier extends StreakNotifier {
  _TestStreakNotifier(this._initialState)
    : super(streakDataSource: _MockStreakLocalDataSource(), ref: _MockRef());

  final StreakState _initialState;

  @override
  StreakState get state => _initialState;

  @override
  set state(StreakState value) {
    // No-op for tests
  }

  @override
  Future<void> loadStreak() async {
    // No-op for tests
  }
}

/// Minimal mock for StreakLocalDataSource.
class _MockStreakLocalDataSource extends Mock
    implements StreakLocalDataSource {}

/// Minimal mock for Ref.
class _MockRef extends Mock implements Ref {}
