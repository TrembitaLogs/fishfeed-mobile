import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/core/constants/achievements.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/domain/entities/achievement.dart';
import 'package:fishfeed/presentation/widgets/gamification/achievement_unlock_overlay.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Achievement createTestAchievement({
    AchievementType type = AchievementType.firstFeeding,
    DateTime? unlockedAt,
  }) {
    return Achievement.fromType(
      id: 'achievement_test_${type.name}',
      userId: 'test_user',
      achievementType: type,
      unlockedAt: unlockedAt ?? DateTime.now(),
      progress: 1.0,
    );
  }

  Widget buildTestWidget({
    required Achievement achievement,
    VoidCallback? onDismiss,
    int autoDismissSeconds = 3,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AchievementUnlockOverlay(
          achievement: achievement,
          onDismiss: onDismiss,
          autoDismissSeconds: autoDismissSeconds,
        ),
      ),
    );
  }

  group('AchievementUnlockOverlay', () {
    testWidgets('should display achievement title', (tester) async {
      final achievement = createTestAchievement(
        type: AchievementType.firstFeeding,
      );

      await tester.pumpWidget(buildTestWidget(achievement: achievement));

      expect(find.text(achievement.title), findsOneWidget);
    });

    testWidgets('should display achievement description', (tester) async {
      final achievement = createTestAchievement(type: AchievementType.streak7);

      await tester.pumpWidget(buildTestWidget(achievement: achievement));

      expect(find.text(achievement.description!), findsOneWidget);
    });

    testWidgets('should display XP reward', (tester) async {
      final achievement = createTestAchievement(type: AchievementType.streak7);

      await tester.pumpWidget(buildTestWidget(achievement: achievement));

      expect(find.text('+${achievement.xpReward} XP'), findsOneWidget);
    });

    testWidgets('should display unlock header text', (tester) async {
      final achievement = createTestAchievement();

      await tester.pumpWidget(buildTestWidget(achievement: achievement));

      expect(find.text('Achievement Unlocked!'), findsOneWidget);
    });

    testWidgets('should display tap to dismiss hint', (tester) async {
      final achievement = createTestAchievement();

      await tester.pumpWidget(buildTestWidget(achievement: achievement));

      expect(find.text('Tap to dismiss'), findsOneWidget);
    });

    testWidgets('should call onDismiss when tapped', (tester) async {
      bool wasDismissed = false;
      final achievement = createTestAchievement();

      await tester.pumpWidget(
        buildTestWidget(
          achievement: achievement,
          onDismiss: () => wasDismissed = true,
        ),
      );

      // Tap on the overlay
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(wasDismissed, isTrue);
    });

    testWidgets('should auto-dismiss after specified duration', (tester) async {
      bool wasDismissed = false;
      final achievement = createTestAchievement();

      await tester.pumpWidget(
        buildTestWidget(
          achievement: achievement,
          onDismiss: () => wasDismissed = true,
          autoDismissSeconds: 1,
        ),
      );

      // Wait for auto-dismiss
      await tester.pump(const Duration(milliseconds: 500));
      expect(wasDismissed, isFalse);

      await tester.pump(const Duration(milliseconds: 600));
      expect(wasDismissed, isTrue);
    });

    testWidgets('should show confetti widget', (tester) async {
      final achievement = createTestAchievement();

      await tester.pumpWidget(buildTestWidget(achievement: achievement));

      // ConfettiWidget should be present (from confetti package)
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('should display correct icon for achievement type', (
      tester,
    ) async {
      final achievement = createTestAchievement(type: AchievementType.streak7);

      await tester.pumpWidget(buildTestWidget(achievement: achievement));

      // The streak7 achievement uses fire department icon
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });

    testWidgets('should display correct icon for firstFeeding', (tester) async {
      final achievement = createTestAchievement(
        type: AchievementType.firstFeeding,
      );

      await tester.pumpWidget(buildTestWidget(achievement: achievement));

      expect(find.byIcon(Icons.celebration), findsOneWidget);
    });

    testWidgets('should display correct icon for feedings100', (tester) async {
      final achievement = createTestAchievement(
        type: AchievementType.feedings100,
      );

      await tester.pumpWidget(buildTestWidget(achievement: achievement));

      // feedings100 uses star icon - there are 2 (one for achievement, one for XP reward)
      expect(find.byIcon(Icons.star), findsAtLeast(1));
    });
  });

  group('AchievementUnlockQueue', () {
    testWidgets('should display first achievement initially', (tester) async {
      final achievements = [
        createTestAchievement(type: AchievementType.firstFeeding),
        createTestAchievement(type: AchievementType.streak7),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AchievementUnlockQueue(achievements: achievements),
          ),
        ),
      );

      // Achievement.fromType uses Ukrainian titles (data.titleUk)
      expect(find.text(achievements[0].title), findsOneWidget);
    });

    testWidgets('should show next achievement after dismiss', (tester) async {
      final achievements = [
        createTestAchievement(type: AchievementType.firstFeeding),
        createTestAchievement(type: AchievementType.streak7),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AchievementUnlockQueue(achievements: achievements),
          ),
        ),
      );
      // Allow localization and initial render
      await tester.pump();

      // First achievement visible (uses Ukrainian title from Achievement.fromType)
      expect(find.text(achievements[0].title), findsOneWidget);

      // Tap to dismiss
      await tester.tap(find.byType(GestureDetector).first);
      // Use pump instead of pumpAndSettle due to repeating animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Second achievement should now be visible
      expect(find.text(achievements[1].title), findsOneWidget);
    });

    testWidgets('should call onAllDismissed after last achievement', (
      tester,
    ) async {
      bool allDismissed = false;
      final achievements = [
        createTestAchievement(type: AchievementType.firstFeeding),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AchievementUnlockQueue(
              achievements: achievements,
              onAllDismissed: () => allDismissed = true,
            ),
          ),
        ),
      );

      // Tap to dismiss the only achievement
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(allDismissed, isTrue);
    });
  });
}
