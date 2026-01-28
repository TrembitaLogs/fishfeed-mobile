import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/presentation/providers/settings_provider.dart';
import 'package:fishfeed/presentation/screens/settings/appearance_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestFonts();
  });

  tearDownAll(() {
    teardownTestFonts();
  });

  Widget buildTestWidget({SettingsState? initialSettings}) {
    final settings = initialSettings ?? const SettingsState.initial();
    return wrapForTesting(
      child: const AppearanceScreen(),
      overrides: [
        ...getWidgetTestOverrides(currentUser: testUser),
        settingsNotifierProvider.overrideWith(
          (ref) => _TestSettingsNotifier(settings),
        ),
      ],
    );
  }

  group('AppearanceScreen', () {
    group('app bar', () {
      testWidgets('renders Appearance title', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Appearance'), findsOneWidget);
      });
    });

    group('theme section', () {
      testWidgets('renders Theme section header', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Theme'), findsOneWidget);
      });

      testWidgets('renders SegmentedButton with three options', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(SegmentedButton<AppThemeMode>), findsOneWidget);
        expect(find.text('System'), findsOneWidget);
        expect(find.text('Light Mode'), findsOneWidget);
        expect(find.text('Dark Mode'), findsOneWidget);
      });

      testWidgets('System theme is selected by default', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final segmentedButton = tester.widget<SegmentedButton<AppThemeMode>>(
          find.byType(SegmentedButton<AppThemeMode>),
        );

        expect(segmentedButton.selected, {AppThemeMode.system});
      });

      testWidgets('shows correct description for System theme', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(
          find.text('Automatically matches your device settings'),
          findsOneWidget,
        );
      });

      testWidgets('tapping Light selects light theme', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Light Mode'));
        await tester.pumpAndSettle();

        final segmentedButton = tester.widget<SegmentedButton<AppThemeMode>>(
          find.byType(SegmentedButton<AppThemeMode>),
        );

        expect(segmentedButton.selected, {AppThemeMode.light});
      });

      testWidgets('shows correct description for Light theme', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            initialSettings: const SettingsState(themeMode: AppThemeMode.light),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Always use light theme'), findsOneWidget);
      });

      testWidgets('tapping Dark selects dark theme', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Dark Mode'));
        await tester.pumpAndSettle();

        final segmentedButton = tester.widget<SegmentedButton<AppThemeMode>>(
          find.byType(SegmentedButton<AppThemeMode>),
        );

        expect(segmentedButton.selected, {AppThemeMode.dark});
      });

      testWidgets('shows correct description for Dark theme', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            initialSettings: const SettingsState(themeMode: AppThemeMode.dark),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Always use dark theme'), findsOneWidget);
      });

      testWidgets('shows theme icons', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.brightness_auto), findsOneWidget);
        expect(find.byIcon(Icons.light_mode), findsOneWidget);
        expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      });
    });

    group('language section', () {
      testWidgets('renders Language section header', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Language'), findsOneWidget);
      });

      testWidgets('renders language tile with English by default', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('English'), findsAtLeastNWidgets(1));
      });

      testWidgets('renders language icon', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.language), findsOneWidget);
      });

      testWidgets('tapping language tile opens bottom sheet', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Find and tap the language tile (ListTile with language icon)
        final languageTile = find.ancestor(
          of: find.byIcon(Icons.language),
          matching: find.byType(ListTile),
        );
        await tester.tap(languageTile);
        await tester.pumpAndSettle();

        // Bottom sheet should appear with language options
        expect(find.text('German'), findsOneWidget);
        expect(find.text('Deutsch'), findsAtLeastNWidgets(1));
      });

      testWidgets('selecting German in bottom sheet updates language', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Open bottom sheet
        final languageTile = find.ancestor(
          of: find.byIcon(Icons.language),
          matching: find.byType(ListTile),
        );
        await tester.tap(languageTile);
        await tester.pumpAndSettle();

        // Tap German option
        await tester.tap(find.text('German'));
        await tester.pumpAndSettle();

        // Bottom sheet should close and language should update
        // The tile should now show German
        expect(find.text('German'), findsAtLeastNWidgets(1));
      });

      testWidgets('shows check icon for selected language in bottom sheet', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Open bottom sheet
        final languageTile = find.ancestor(
          of: find.byIcon(Icons.language),
          matching: find.byType(ListTile),
        );
        await tester.tap(languageTile);
        await tester.pumpAndSettle();

        // English should have check icon (selected)
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        // German should have circle outline (not selected)
        expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
      });

      testWidgets('shows German when language is set to de', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(initialSettings: const SettingsState(language: 'de')),
        );
        await tester.pumpAndSettle();

        expect(find.text('German'), findsOneWidget);
        expect(find.text('Deutsch'), findsOneWidget);
      });
    });

    group('theme persistence', () {
      testWidgets('loads saved theme mode on startup', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            initialSettings: const SettingsState(themeMode: AppThemeMode.dark),
          ),
        );
        await tester.pumpAndSettle();

        final segmentedButton = tester.widget<SegmentedButton<AppThemeMode>>(
          find.byType(SegmentedButton<AppThemeMode>),
        );

        expect(segmentedButton.selected, {AppThemeMode.dark});
      });

      testWidgets('loads saved language on startup', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(initialSettings: const SettingsState(language: 'de')),
        );
        await tester.pumpAndSettle();

        expect(find.text('German'), findsOneWidget);
      });
    });
  });
}

/// Test implementation of SettingsNotifier for testing.
///
/// Uses StateNotifier directly to avoid HiveBoxes initialization.
class _TestSettingsNotifier extends StateNotifier<SettingsState>
    implements SettingsNotifier {
  _TestSettingsNotifier(super.initialState);

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
  }

  @override
  Future<void> setFeedingRemindersEnabled(bool enabled) async {
    state = state.copyWith(feedingRemindersEnabled: enabled);
  }

  @override
  Future<void> setStreakAlertsEnabled(bool enabled) async {
    state = state.copyWith(streakAlertsEnabled: enabled);
  }

  @override
  Future<void> setWeeklySummaryEnabled(bool enabled) async {
    state = state.copyWith(weeklySummaryEnabled: enabled);
  }

  @override
  Future<void> setQuietHours({int? startMinutes, int? endMinutes}) async {
    state = state.copyWith(
      quietHoursStart: startMinutes,
      quietHoursEnd: endMinutes,
      clearQuietHours: startMinutes == null && endMinutes == null,
    );
  }

  @override
  Future<void> disableQuietHours() async {
    state = state.copyWith(clearQuietHours: true);
  }

  @override
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    state = state.copyWith(language: languageCode);
  }

  @override
  Future<void> reload() async {}
}
