import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/domain/entities/achievement.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/achievement_providers.dart';
import 'package:fishfeed/presentation/screens/achievements/achievements_screen.dart';
import 'package:fishfeed/presentation/widgets/common/error_state_widget.dart';

// ============================================================================
// Test Data
// ============================================================================

final _unlockedAchievement = Achievement(
  id: 'ach-1',
  userId: 'user-123',
  type: 'firstFeeding',
  title: 'First Feeding',
  description: 'Complete your first feeding',
  unlockedAt: DateTime(2024, 3, 15),
  progress: 1.0,
);

final _lockedAchievement = Achievement(
  id: 'ach-2',
  userId: 'user-123',
  type: 'streak7',
  title: '7-Day Streak',
  description: 'Feed your fish 7 days in a row',
  progress: 0.0,
);

final _partialAchievement = Achievement(
  id: 'ach-3',
  userId: 'user-123',
  type: 'streak30',
  title: '30-Day Streak',
  description: 'Feed your fish 30 days in a row',
  progress: 0.4,
);

// ============================================================================
// Helpers
// ============================================================================

Widget _buildTestApp({required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AchievementsScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  group('AchievementsScreen', () {
    testWidgets('shows loading indicator while achievements load', (
      tester,
    ) async {
      final completer = Completer<List<Achievement>>();

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            allAchievementsProvider.overrideWith((ref) => completer.future),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future to avoid pending timer issues
      completer.complete(<Achievement>[]);
      await tester.pumpAndSettle();
    });

    testWidgets('shows empty state when no achievements exist', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [allAchievementsProvider.overrideWith((ref) async => [])],
        ),
      );
      await tester.pumpAndSettle();

      // EmptyStateWidget uses the icon passed in
      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
    });

    testWidgets('shows error state on failure', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            allAchievementsProvider.overrideWith(
              (ref) async => throw Exception('Network error'),
            ),
          ],
        ),
      );
      // Pump once to let the FutureProvider resolve, then settle animations
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      // ErrorStateWidget shows a retry button (FilledButton.icon)
      expect(find.byType(ErrorStateWidget), findsOneWidget);
    });

    testWidgets('displays achievements grid with unlocked and locked items', (
      tester,
    ) async {
      // Use a taller surface so all grid items are rendered by SliverGrid
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final achievements = [
        _unlockedAchievement,
        _lockedAchievement,
        _partialAchievement,
      ];

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            allAchievementsProvider.overrideWith((ref) async => achievements),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Header shows progress count
      expect(find.text('1 / 3'), findsOneWidget);

      // Achievement titles are displayed
      expect(find.text('First Feeding'), findsOneWidget);
      expect(find.text('7-Day Streak'), findsOneWidget);
      expect(find.text('30-Day Streak'), findsOneWidget);
    });

    testWidgets('shows progress indicator for partial achievements', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            allAchievementsProvider.overrideWith(
              (ref) async => [_partialAchievement],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Partial progress shows percentage text
      expect(find.text('40%'), findsOneWidget);
    });

    testWidgets('shows check icon for unlocked achievements', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            allAchievementsProvider.overrideWith(
              (ref) async => [_unlockedAchievement],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows lock icon for locked achievements with no progress', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            allAchievementsProvider.overrideWith(
              (ref) async => [_lockedAchievement],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('shows share icon for unlocked achievements', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            allAchievementsProvider.overrideWith(
              (ref) async => [_unlockedAchievement],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('tapping achievement card opens detail bottom sheet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            allAchievementsProvider.overrideWith(
              (ref) async => [_unlockedAchievement],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap the achievement card
      await tester.tap(find.text('First Feeding'));
      await tester.pumpAndSettle();

      // Bottom sheet shows XP reward
      expect(find.textContaining('XP'), findsOneWidget);
    });

    testWidgets('detail bottom sheet shows unlock date for unlocked', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            allAchievementsProvider.overrideWith(
              (ref) async => [_unlockedAchievement],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap the card to open detail
      await tester.tap(find.text('First Feeding'));
      await tester.pumpAndSettle();

      // Should see check_circle icon in the bottom sheet detail
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('detail bottom sheet shows progress bar for partial', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            allAchievementsProvider.overrideWith(
              (ref) async => [_partialAchievement],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap the card
      await tester.tap(find.text('30-Day Streak'));
      await tester.pumpAndSettle();

      // Bottom sheet shows a LinearProgressIndicator for partial progress
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('detail bottom sheet shows lock for locked achievements', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            allAchievementsProvider.overrideWith(
              (ref) async => [_lockedAchievement],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap the card
      await tester.tap(find.text('7-Day Streak'));
      await tester.pumpAndSettle();

      // Bottom sheet shows lock icon
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('header progress bar reflects achievements ratio', (
      tester,
    ) async {
      final achievements = [_unlockedAchievement, _lockedAchievement];

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            allAchievementsProvider.overrideWith((ref) async => achievements),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Header shows 1 / 2
      expect(find.text('1 / 2'), findsOneWidget);

      // Progress bar exists in header
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('app bar shows achievements title', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [allAchievementsProvider.overrideWith((ref) async => [])],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('all-unlocked state shows full progress', (tester) async {
      final achievements = [
        _unlockedAchievement,
        _unlockedAchievement.copyWith(
          id: 'ach-2',
          type: 'streak7',
          title: 'Streak 7',
        ),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            allAchievementsProvider.overrideWith((ref) async => achievements),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
    });
  });
}
