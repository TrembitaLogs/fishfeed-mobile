import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/core/constants/achievements.dart';
import 'package:fishfeed/domain/entities/achievement.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/widgets/gamification/share_card.dart';

void main() {
  group('ShareCard', () {
    late Achievement unlockedAchievement;

    setUp(() {
      unlockedAchievement = Achievement.fromType(
        id: 'test-1',
        userId: 'user-1',
        achievementType: AchievementType.streak7,
        unlockedAt: DateTime(2024, 1, 15),
      );
    });

    testWidgets('displays achievement title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(child: ShareCard(achievement: unlockedAchievement)),
          ),
        ),
      );

      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        find.text(
          unlockedAchievement.achievementType!.localizedTitle(l10n),
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays achievement description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(child: ShareCard(achievement: unlockedAchievement)),
          ),
        ),
      );

      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        find.text(
          unlockedAchievement.achievementType!.localizedDescription(l10n),
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays XP reward', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(child: ShareCard(achievement: unlockedAchievement)),
          ),
        ),
      );

      expect(find.text('+${unlockedAchievement.xpReward} XP'), findsOneWidget);
    });

    testWidgets('displays FishFeed branding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(child: ShareCard(achievement: unlockedAchievement)),
          ),
        ),
      );

      expect(find.text('FishFeed'), findsOneWidget);
    });

    testWidgets('displays ACHIEVEMENT UNLOCKED label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(child: ShareCard(achievement: unlockedAchievement)),
          ),
        ),
      );

      expect(find.text('ACHIEVEMENT UNLOCKED'), findsOneWidget);
    });

    testWidgets('displays formatted unlock date', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(child: ShareCard(achievement: unlockedAchievement)),
          ),
        ),
      );

      // Date is formatted as "Jan 15, 2024"
      expect(find.text('Jan 15, 2024'), findsOneWidget);
    });

    testWidgets('has correct default dimensions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(child: ShareCard(achievement: unlockedAchievement)),
          ),
        ),
      );

      final shareCard = tester.widget<ShareCard>(find.byType(ShareCard));
      expect(shareCard.width, 400);
      expect(shareCard.height, 500);
    });

    testWidgets('respects custom dimensions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: ShareCard(
                achievement: unlockedAchievement,
                width: 450,
                height: 550,
              ),
            ),
          ),
        ),
      );

      final shareCard = tester.widget<ShareCard>(find.byType(ShareCard));
      expect(shareCard.width, 450);
      expect(shareCard.height, 550);
    });

    testWidgets('displays correct icon for achievement type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(child: ShareCard(achievement: unlockedAchievement)),
          ),
        ),
      );

      // streak7 uses local_fire_department icon
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });

    testWidgets('displays star icon for XP badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(child: ShareCard(achievement: unlockedAchievement)),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('displays water_drop icon for branding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(child: ShareCard(achievement: unlockedAchievement)),
          ),
        ),
      );

      expect(find.byIcon(Icons.water_drop), findsOneWidget);
    });

    group('with different achievement types', () {
      testWidgets('renders firstFeeding achievement', (tester) async {
        final achievement = Achievement.fromType(
          id: 'test-1',
          userId: 'user-1',
          achievementType: AchievementType.firstFeeding,
          unlockedAt: DateTime(2024, 1, 1),
        );

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Center(child: ShareCard(achievement: achievement)),
            ),
          ),
        );

        final l10n = lookupAppLocalizations(const Locale('en'));
        expect(
          find.text(achievement.achievementType!.localizedTitle(l10n)),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.celebration), findsOneWidget);
      });

      testWidgets('renders streak100 achievement', (tester) async {
        final achievement = Achievement.fromType(
          id: 'test-2',
          userId: 'user-1',
          achievementType: AchievementType.streak100,
          unlockedAt: DateTime(2024, 6, 1),
        );

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Center(child: ShareCard(achievement: achievement)),
            ),
          ),
        );

        final l10n = lookupAppLocalizations(const Locale('en'));
        expect(
          find.text(achievement.achievementType!.localizedTitle(l10n)),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      });

      testWidgets('renders feedings500 achievement', (tester) async {
        final achievement = Achievement.fromType(
          id: 'test-3',
          userId: 'user-1',
          achievementType: AchievementType.feedings500,
          unlockedAt: DateTime(2024, 12, 25),
        );

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Center(child: ShareCard(achievement: achievement)),
            ),
          ),
        );

        final l10n = lookupAppLocalizations(const Locale('en'));
        expect(
          find.text(achievement.achievementType!.localizedTitle(l10n)),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.stars), findsOneWidget);
      });
    });

    testWidgets('handles achievement without unlocked date', (tester) async {
      final achievement = Achievement.fromType(
        id: 'test-no-date',
        userId: 'user-1',
        achievementType: AchievementType.streak7,
        // No unlockedAt date
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(child: ShareCard(achievement: achievement)),
          ),
        ),
      );

      // Should not crash, just not show the date
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        find.text(achievement.achievementType!.localizedTitle(l10n)),
        findsOneWidget,
      );
    });
  });
}
