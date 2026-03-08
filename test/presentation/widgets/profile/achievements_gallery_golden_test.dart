@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/core/constants/achievements.dart';
import 'package:fishfeed/domain/entities/achievement.dart';
import 'package:fishfeed/domain/usecases/achievement_usecase.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/achievement_providers.dart';
import 'package:fishfeed/presentation/widgets/profile/achievements_gallery.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
    await initializeDateFormatting('uk');
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Achievement createTestAchievement({
    required AchievementType type,
    DateTime? unlockedAt,
    double progress = 0.0,
  }) {
    return Achievement.fromType(
      id: 'achievement_test_${type.name}',
      userId: 'test_user',
      achievementType: type,
      unlockedAt: unlockedAt,
      progress: unlockedAt != null ? 1.0 : progress,
    );
  }

  List<Achievement> createAllAchievements({
    int unlockedCount = 0,
    double lockedProgress = 0.0,
  }) {
    return AchievementConstants.orderedAchievements.asMap().entries.map((
      entry,
    ) {
      final index = entry.key;
      final type = entry.value;
      return createTestAchievement(
        type: type,
        unlockedAt: index < unlockedCount
            ? DateTime(2024, 1, 1).add(Duration(days: index))
            : null,
        progress: index < unlockedCount ? 1.0 : lockedProgress,
      );
    }).toList();
  }

  Widget buildGoldenWidget({
    required AchievementsState achievementsState,
    bool darkMode = false,
  }) {
    return ProviderScope(
      overrides: [
        achievementsProvider.overrideWith(
          (ref) => _TestAchievementsNotifier(achievementsState),
        ),
      ],
      child: MaterialApp(
        theme: darkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: 400,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: AchievementsGallery(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('AchievementsGallery Golden Tests', () {
    testWidgets('all locked achievements', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          achievementsState: AchievementsState(
            achievements: createAllAchievements(unlockedCount: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/achievements_gallery_all_locked.png'),
      );
    });

    testWidgets('first achievement unlocked', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          achievementsState: AchievementsState(
            achievements: createAllAchievements(unlockedCount: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/achievements_gallery_one_unlocked.png'),
      );
    });

    testWidgets('three achievements unlocked', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          achievementsState: AchievementsState(
            achievements: createAllAchievements(unlockedCount: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/achievements_gallery_three_unlocked.png'),
      );
    });

    testWidgets('all achievements unlocked', (tester) async {
      final allUnlocked = AchievementConstants.orderedAchievements.length;
      await tester.pumpWidget(
        buildGoldenWidget(
          achievementsState: AchievementsState(
            achievements: createAllAchievements(unlockedCount: allUnlocked),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/achievements_gallery_all_unlocked.png'),
      );
    });

    testWidgets('loading state', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          achievementsState: const AchievementsState(isLoading: true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/achievements_gallery_loading.png'),
      );
    });

    testWidgets('error state', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          achievementsState: const AchievementsState(
            error: 'Failed to load achievements',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/achievements_gallery_error.png'),
      );
    });

    testWidgets('dark mode - three unlocked', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          achievementsState: AchievementsState(
            achievements: createAllAchievements(unlockedCount: 3),
          ),
          darkMode: true,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/achievements_gallery_dark_mode.png'),
      );
    });

    testWidgets('with progress on locked achievements', (tester) async {
      await tester.pumpWidget(
        buildGoldenWidget(
          achievementsState: AchievementsState(
            achievements: createAllAchievements(
              unlockedCount: 2,
              lockedProgress: 0.5,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/achievements_gallery_with_progress.png'),
      );
    });
  });
}

/// Test-only AchievementsNotifier that returns a fixed state.
class _TestAchievementsNotifier extends AchievementsNotifier {
  _TestAchievementsNotifier(this._initialState)
    : super(achievementUseCase: _MockAchievementUseCase(), ref: _MockRef());

  final AchievementsState _initialState;

  @override
  AchievementsState get state => _initialState;

  @override
  set state(AchievementsState value) {
    // No-op for tests
  }

  @override
  Future<void> loadAchievements() async {
    // No-op for tests
  }

  @override
  Future<void> refresh() async {
    // No-op for tests
  }
}

/// Minimal mock for AchievementUseCase.
class _MockAchievementUseCase extends Mock implements AchievementUseCase {}

/// Minimal mock for Ref.
class _MockRef extends Mock implements Ref {}
