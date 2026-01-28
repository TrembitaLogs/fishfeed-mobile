import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/domain/entities/streak.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
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

  Widget buildGoldenWidget({
    required StreakState streakState,
    bool darkMode = false,
  }) {
    return ProviderScope(
      overrides: [
        currentStreakProvider.overrideWith(
          (ref) => _TestStreakNotifier(streakState),
        ),
      ],
      child: MaterialApp(
        theme: darkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: StreakSection(),
              ),
            ),
          ),
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

  group('StreakSection Golden Tests', () {
    testWidgets('streak 0 - new user', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          streakState: StreakState(
            streak: createStreak(
              currentStreak: 0,
              longestStreak: 0,
              freezeAvailable: 2,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/streak_section_0_days.png'),
      );
    });

    testWidgets('streak 7 - first milestone', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          streakState: StreakState(
            streak: createStreak(
              currentStreak: 7,
              longestStreak: 7,
              freezeAvailable: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/streak_section_7_days.png'),
      );
    });

    testWidgets('streak 30 - one month milestone', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          streakState: StreakState(
            streak: createStreak(
              currentStreak: 30,
              longestStreak: 30,
              freezeAvailable: 2,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/streak_section_30_days.png'),
      );
    });

    testWidgets('streak 100 - epic milestone', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          streakState: StreakState(
            streak: createStreak(
              currentStreak: 100,
              longestStreak: 100,
              freezeAvailable: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/streak_section_100_days.png'),
      );
    });

    testWidgets('loading state', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(streakState: const StreakState(isLoading: true)),
      );
      // Don't use pumpAndSettle for shimmer - it animates forever
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/streak_section_loading.png'),
      );
    });

    testWidgets('dark mode - streak 15', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          streakState: StreakState(
            streak: createStreak(
              currentStreak: 15,
              longestStreak: 20,
              freezeAvailable: 1,
            ),
          ),
          darkMode: true,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/streak_section_dark_mode.png'),
      );
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
