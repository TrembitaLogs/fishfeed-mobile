import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/presentation/providers/settings_provider.dart';
import 'package:fishfeed/presentation/screens/settings/notification_settings_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestFonts();
  });

  tearDownAll(() {
    teardownTestFonts();
  });

  Widget buildTestWidget({
    SettingsState? initialSettings,
  }) {
    final settings = initialSettings ?? const SettingsState.initial();
    return wrapForTesting(
      child: const NotificationSettingsScreen(),
      overrides: [
        ...getWidgetTestOverrides(currentUser: testUser),
        settingsNotifierProvider.overrideWith(
          (ref) => _TestSettingsNotifier(settings),
        ),
      ],
    );
  }

  group('NotificationSettingsScreen', () {
    group('master toggle', () {
      testWidgets('renders enable notifications toggle', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Enable Notifications'), findsOneWidget);
        expect(
            find.text('Receive feeding reminders and alerts'), findsOneWidget);
      });

      testWidgets('master toggle is on by default', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final switchFinder = find.byType(Switch).first;
        final switchWidget = tester.widget<Switch>(switchFinder);

        expect(switchWidget.value, isTrue);
      });

      testWidgets('shows disabled message when master toggle is off',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          initialSettings: const SettingsState(
            notificationsEnabled: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('All notifications are disabled'), findsOneWidget);
      });

      testWidgets('tapping master toggle updates state', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Find the first SwitchListTile (master toggle)
        final switchTile = find.byType(SwitchListTile).first;
        await tester.tap(switchTile);
        await tester.pumpAndSettle();

        // The subtitle should change to disabled message
        expect(find.text('All notifications are disabled'), findsOneWidget);
      });
    });

    group('notification types section', () {
      testWidgets('renders section header', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Notification Types'), findsOneWidget);
      });

      testWidgets('renders feeding reminders toggle', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Feeding Reminders'), findsOneWidget);
        expect(
            find.text('Get notified when it\'s time to feed'), findsOneWidget);
      });

      testWidgets('renders streak alerts toggle', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Streak Alerts'), findsOneWidget);
        expect(
            find.text('Warnings when your streak is at risk'), findsOneWidget);
      });

      testWidgets('renders weekly summary toggle', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Weekly Summary'), findsOneWidget);
        expect(find.text('Weekly feeding activity overview'), findsOneWidget);
      });

      testWidgets('individual toggles are disabled when master is off',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          initialSettings: const SettingsState(
            notificationsEnabled: false,
          ),
        ));
        await tester.pumpAndSettle();

        // Find all SwitchListTiles (master + 3 individual + quiet hours = 5)
        final switches = tester.widgetList<Switch>(find.byType(Switch));

        // Skip master toggle (first), check that others are disabled
        var switchIndex = 0;
        for (final switchWidget in switches) {
          if (switchIndex > 0 && switchIndex < 4) {
            // Individual notification toggles should be disabled
            expect(switchWidget.onChanged, isNull,
                reason: 'Switch at index $switchIndex should be disabled');
          }
          switchIndex++;
        }
      });

      testWidgets('individual toggles work when master is on', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Find Feeding Reminders tile (second SwitchListTile)
        final feedingToggle = find.byType(SwitchListTile).at(1);
        await tester.tap(feedingToggle);
        await tester.pumpAndSettle();

        // The toggle should have changed
        final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
        expect(switches[1].value, isFalse);
      });
    });

    group('quiet hours section', () {
      testWidgets('renders section header', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Quiet Hours'), findsOneWidget);
      });

      testWidgets('renders enable quiet hours toggle', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Enable Quiet Hours'), findsOneWidget);
        expect(find.text('Mute notifications during specified hours'),
            findsOneWidget);
      });

      testWidgets('quiet hours toggle is off by default', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Find the quiet hours toggle (5th SwitchListTile - after master + 3 individual)
        final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
        // Master (0), Feeding (1), Streak (2), Weekly (3), Quiet Hours (4)
        expect(switches[4].value, isFalse);
      });

      testWidgets('time pickers not visible when quiet hours disabled',
          (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('From'), findsNothing);
        expect(find.text('To'), findsNothing);
      });

      testWidgets('time pickers visible when quiet hours enabled',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          initialSettings: const SettingsState(
            notificationsEnabled: true,
            quietHoursStart: 22 * 60, // 22:00
            quietHoursEnd: 8 * 60, // 08:00
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.text('From'), findsOneWidget);
        expect(find.text('To'), findsOneWidget);
        expect(find.text('22:00'), findsOneWidget);
        expect(find.text('08:00'), findsOneWidget);
      });

      testWidgets('enabling quiet hours shows time pickers with defaults',
          (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Find and tap quiet hours toggle
        final quietHoursToggle = find.byType(SwitchListTile).at(4);
        await tester.tap(quietHoursToggle);
        await tester.pumpAndSettle();

        // Time pickers should appear with default values
        expect(find.text('From'), findsOneWidget);
        expect(find.text('To'), findsOneWidget);
        expect(find.text('22:00'), findsOneWidget);
        expect(find.text('08:00'), findsOneWidget);
      });

      testWidgets('quiet hours section disabled when master toggle off',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          initialSettings: const SettingsState(
            notificationsEnabled: false,
          ),
        ));
        await tester.pumpAndSettle();

        // Find quiet hours toggle switch
        final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
        // Master (0), Feeding (1), Streak (2), Weekly (3), Quiet Hours (4)
        expect(switches[4].onChanged, isNull);
      });

      testWidgets('tapping time picker button shows time picker dialog',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          initialSettings: const SettingsState(
            notificationsEnabled: true,
            quietHoursStart: 22 * 60,
            quietHoursEnd: 8 * 60,
          ),
        ));
        await tester.pumpAndSettle();

        // Tap the "From" time picker button
        await tester.tap(find.text('22:00'));
        await tester.pumpAndSettle();

        // Time picker dialog should appear
        expect(find.byType(TimePickerDialog), findsOneWidget);
      });
    });

    group('info text', () {
      testWidgets('renders info text about preferences', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(
          find.text(
              'Notification preferences are saved locally and will be synced with your account when online.'),
          findsOneWidget,
        );
      });
    });

    group('icons', () {
      testWidgets('shows notifications_active icon when enabled',
          (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      });

      testWidgets('shows notifications_off icon when disabled', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          initialSettings: const SettingsState(
            notificationsEnabled: false,
          ),
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.notifications_off), findsOneWidget);
      });

      testWidgets('shows correct icons for notification types', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.restaurant), findsOneWidget);
        expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
        expect(find.byIcon(Icons.summarize), findsOneWidget);
        expect(find.byIcon(Icons.bedtime), findsOneWidget);
      });
    });

    group('app bar', () {
      testWidgets('renders Notifications title', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Notifications'), findsOneWidget);
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
