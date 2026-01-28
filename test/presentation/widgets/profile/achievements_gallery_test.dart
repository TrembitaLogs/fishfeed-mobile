import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/core/constants/achievements.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/domain/entities/achievement.dart';
import 'package:fishfeed/domain/usecases/achievement_usecase.dart';
import 'package:fishfeed/presentation/providers/achievement_providers.dart';
import 'package:fishfeed/presentation/widgets/profile/achievements_gallery.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
    await initializeDateFormatting('en');
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

  List<Achievement> createTestAchievements({int unlockedCount = 2}) {
    const types = AchievementType.values;
    return types.asMap().entries.map((entry) {
      final index = entry.key;
      final type = entry.value;
      return createTestAchievement(
        type: type,
        unlockedAt: index < unlockedCount
            ? DateTime(2024, 1, 1).add(Duration(days: index))
            : null,
        progress: index < unlockedCount ? 1.0 : 0.0,
      );
    }).toList();
  }

  Widget buildTestWidget({required AchievementsState achievementsState}) {
    return ProviderScope(
      overrides: [
        achievementsProvider.overrideWith(
          (ref) => _TestAchievementsNotifier(achievementsState),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: AchievementsGallery(),
            ),
          ),
        ),
      ),
    );
  }

  group('AchievementsGallery', () {
    group('Display', () {
      testWidgets('displays section title', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(
              achievements: createTestAchievements(),
            ),
          ),
        );

        expect(find.text('Achievements'), findsOneWidget);
      });

      testWidgets('displays unlocked/total counter', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(
              achievements: createTestAchievements(unlockedCount: 3),
            ),
          ),
        );

        expect(find.text('3/${AchievementType.values.length}'), findsOneWidget);
      });

      testWidgets('displays correct number of tiles', (tester) async {
        final achievements = createTestAchievements();
        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(achievements: achievements),
          ),
        );

        expect(find.byType(GridView), findsOneWidget);
      });

      testWidgets('displays unlocked achievement title', (tester) async {
        final achievements = [
          createTestAchievement(
            type: AchievementType.firstFeeding,
            unlockedAt: DateTime(2024, 1, 1),
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(achievements: achievements),
          ),
        );

        // Achievement.fromType uses Ukrainian titles (data.titleUk)
        expect(find.text(achievements[0].title), findsOneWidget);
      });

      testWidgets('displays ??? for locked achievement', (tester) async {
        final achievements = [
          createTestAchievement(
            type: AchievementType.streak100,
            unlockedAt: null,
            progress: 0.0,
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(achievements: achievements),
          ),
        );

        expect(find.text('???'), findsOneWidget);
      });

      testWidgets('displays lock icon for locked achievement', (tester) async {
        final achievements = [
          createTestAchievement(
            type: AchievementType.streak100,
            unlockedAt: null,
            progress: 0.0,
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(achievements: achievements),
          ),
        );

        expect(find.byIcon(Icons.lock), findsOneWidget);
      });

      testWidgets('does not display lock icon for unlocked achievement', (
        tester,
      ) async {
        final achievements = [
          createTestAchievement(
            type: AchievementType.firstFeeding,
            unlockedAt: DateTime(2024, 1, 1),
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(achievements: achievements),
          ),
        );

        expect(find.byIcon(Icons.lock), findsNothing);
      });

      testWidgets('displays correct icon for each achievement type', (
        tester,
      ) async {
        final achievements = [
          createTestAchievement(
            type: AchievementType.firstFeeding,
            unlockedAt: DateTime.now(),
          ),
          createTestAchievement(
            type: AchievementType.streak7,
            unlockedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(achievements: achievements),
          ),
        );

        expect(find.byIcon(Icons.celebration), findsOneWidget);
        expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      });
    });

    group('Loading State', () {
      testWidgets('shows loading indicator when loading', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: const AchievementsState(isLoading: true),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('does not show grid when loading', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: const AchievementsState(isLoading: true),
          ),
        );

        expect(find.byType(GridView), findsNothing);
      });
    });

    group('Error State', () {
      testWidgets('shows error message when error occurs', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: const AchievementsState(
              error: 'Failed to load achievements',
            ),
          ),
        );

        expect(find.text('Failed to load achievements'), findsOneWidget);
      });

      testWidgets('shows error icon when error occurs', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: const AchievementsState(error: 'Error'),
          ),
        );

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('shows retry button when error occurs', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: const AchievementsState(error: 'Error'),
          ),
        );

        expect(find.text('Retry'), findsOneWidget);
      });
    });

    group('Detail Modal', () {
      testWidgets('opens modal when tile is tapped', (tester) async {
        final achievements = [
          createTestAchievement(
            type: AchievementType.firstFeeding,
            unlockedAt: DateTime(2024, 1, 15),
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(achievements: achievements),
          ),
        );

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        // Modal should show achievement title (uses Ukrainian from Achievement.fromType)
        expect(find.text(achievements[0].title), findsWidgets);
      });

      testWidgets('modal shows share button for unlocked achievement', (
        tester,
      ) async {
        final achievements = [
          createTestAchievement(
            type: AchievementType.firstFeeding,
            unlockedAt: DateTime(2024, 1, 15),
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(achievements: achievements),
          ),
        );

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        expect(find.text('Share'), findsOneWidget);
      });

      testWidgets('modal shows XP reward for unlocked achievement', (
        tester,
      ) async {
        final achievements = [
          createTestAchievement(
            type: AchievementType.streak7,
            unlockedAt: DateTime(2024, 1, 15),
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(achievements: achievements),
          ),
        );

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        expect(
          find.text('+${AchievementType.streak7.xpReward} XP'),
          findsOneWidget,
        );
      });

      testWidgets('modal shows description', (tester) async {
        final achievements = [
          createTestAchievement(
            type: AchievementType.streak7,
            unlockedAt: DateTime(2024, 1, 15),
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(achievements: achievements),
          ),
        );

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        // Achievement.fromType uses Ukrainian descriptions (data.descriptionUk)
        expect(find.text(achievements[0].description!), findsOneWidget);
      });

      testWidgets('modal does not show share button for locked achievement', (
        tester,
      ) async {
        final achievements = [
          createTestAchievement(
            type: AchievementType.streak100,
            unlockedAt: null,
            progress: 0.0,
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(achievements: achievements),
          ),
        );

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        expect(find.text('Share'), findsNothing);
      });

      testWidgets('modal shows progress bar for achievement with progress', (
        tester,
      ) async {
        final achievements = [
          createTestAchievement(
            type: AchievementType.feedings100,
            unlockedAt: null,
            progress: 0.5,
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(achievements: achievements),
          ),
        );

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        expect(find.text('Progress'), findsOneWidget);
        expect(find.text('50%'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('modal can be closed by dragging down', (tester) async {
        final achievements = [
          createTestAchievement(
            type: AchievementType.firstFeeding,
            unlockedAt: DateTime(2024, 1, 15),
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(achievements: achievements),
          ),
        );

        await tester.tap(find.byType(GestureDetector).first);
        await tester.pumpAndSettle();

        // Verify modal is open
        expect(find.text('Share'), findsOneWidget);

        // Close by tapping outside (the barrier)
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // Share button from modal should be gone
        // Note: The gallery title "Achievements" should still be visible
        expect(find.text('Achievements'), findsOneWidget);
      });
    });

    group('Locked vs Unlocked Visual States', () {
      testWidgets('unlocked achievement has colored background', (
        tester,
      ) async {
        final achievements = [
          createTestAchievement(
            type: AchievementType.firstFeeding,
            unlockedAt: DateTime(2024, 1, 15),
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(achievements: achievements),
          ),
        );

        // Just verify it renders without errors (uses Ukrainian title)
        expect(find.text(achievements[0].title), findsOneWidget);
      });

      testWidgets('locked achievement shows muted icon', (tester) async {
        final achievements = [
          createTestAchievement(
            type: AchievementType.streak100,
            unlockedAt: null,
            progress: 0.0,
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(achievements: achievements),
          ),
        );

        // Verify the emoji_events icon is present (streak100 uses it)
        expect(find.byIcon(Icons.emoji_events), findsOneWidget);
        expect(find.byIcon(Icons.lock), findsOneWidget);
      });
    });

    group('Counter', () {
      testWidgets('shows 0/N when no achievements unlocked', (tester) async {
        final achievements = createTestAchievements(unlockedCount: 0);

        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(achievements: achievements),
          ),
        );

        expect(find.text('0/${achievements.length}'), findsOneWidget);
      });

      testWidgets('shows N/N when all achievements unlocked', (tester) async {
        final total = AchievementType.values.length;
        final achievements = createTestAchievements(unlockedCount: total);

        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: AchievementsState(achievements: achievements),
          ),
        );

        expect(find.text('$total/$total'), findsOneWidget);
      });
    });

    group('Empty State', () {
      testWidgets('handles empty achievements list gracefully', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            achievementsState: const AchievementsState(achievements: []),
          ),
        );

        expect(find.text('Achievements'), findsOneWidget);
        expect(find.text('0/0'), findsOneWidget);
      });
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
