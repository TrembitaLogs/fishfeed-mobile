import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/domain/repositories/settings_repository.dart';
import 'package:fishfeed/presentation/providers/settings_provider.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingsRepository();

    // Synchronous getters read by the constructor's _loadSettings().
    when(() => mockRepository.getThemeMode()).thenReturn('system');
    when(() => mockRepository.getNotificationsEnabled()).thenReturn(true);
    when(() => mockRepository.getFeedingRemindersEnabled()).thenReturn(true);
    when(() => mockRepository.getStreakAlertsEnabled()).thenReturn(true);
    when(() => mockRepository.getWeeklySummaryEnabled()).thenReturn(true);
    when(() => mockRepository.getQuietHoursStart()).thenReturn(null);
    when(() => mockRepository.getQuietHoursEnd()).thenReturn(null);
    when(() => mockRepository.getLanguage()).thenReturn('en');

    // Async setters resolve immediately by default.
    when(() => mockRepository.setThemeMode(any())).thenAnswer((_) async {});
    when(
      () => mockRepository.setNotificationsEnabled(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepository.setFeedingRemindersEnabled(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepository.setStreakAlertsEnabled(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepository.setWeeklySummaryEnabled(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepository.setQuietHoursStart(any()),
    ).thenAnswer((_) async {});
    when(() => mockRepository.setQuietHoursEnd(any())).thenAnswer((_) async {});
    when(() => mockRepository.setLanguage(any())).thenAnswer((_) async {});
  });

  group('SettingsNotifier basic behavior', () {
    test('loads settings from repository on construction', () {
      final notifier = SettingsNotifier(repository: mockRepository);
      addTearDown(notifier.dispose);

      expect(notifier.state.themeMode, AppThemeMode.system);
      expect(notifier.state.language, 'en');
      expect(notifier.state.isLoading, false);
    });

    test('setThemeMode persists and updates state', () async {
      final notifier = SettingsNotifier(repository: mockRepository);
      addTearDown(notifier.dispose);

      await notifier.setThemeMode(AppThemeMode.dark);

      expect(notifier.state.themeMode, AppThemeMode.dark);
      expect(notifier.state.isSaving, false);
      verify(() => mockRepository.setThemeMode('dark')).called(1);
    });

    test('setQuietHours persists both start and end', () async {
      final notifier = SettingsNotifier(repository: mockRepository);
      addTearDown(notifier.dispose);

      await notifier.setQuietHours(startMinutes: 60, endMinutes: 120);

      expect(notifier.state.quietHoursStart, 60);
      expect(notifier.state.quietHoursEnd, 120);
      expect(notifier.state.isSaving, false);
      verify(() => mockRepository.setQuietHoursStart(60)).called(1);
      verify(() => mockRepository.setQuietHoursEnd(120)).called(1);
    });
  });

  // Reproduces the "used after dispose" bug class: each setter persists via the
  // repository (await), then writes `state = ...` afterwards. If the notifier is
  // disposed during that await gap, the post-await `state =` throws
  // "Bad state: Tried to use SettingsNotifier after dispose was called".
  // A `if (!mounted) return;` guard before the post-await state write fixes it.
  group('Notifier dispose safety (mounted guards)', () {
    test('setThemeMode does not throw when disposed mid-await', () async {
      when(() => mockRepository.setThemeMode(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      final notifier = SettingsNotifier(repository: mockRepository);
      final future = notifier.setThemeMode(AppThemeMode.dark);
      notifier.dispose();

      await expectLater(future, completes);
    });

    test(
      'setNotificationsEnabled does not throw when disposed mid-await',
      () async {
        when(() => mockRepository.setNotificationsEnabled(any())).thenAnswer((
          _,
        ) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });

        final notifier = SettingsNotifier(repository: mockRepository);
        final future = notifier.setNotificationsEnabled(false);
        notifier.dispose();

        await expectLater(future, completes);
      },
    );

    test(
      'setFeedingRemindersEnabled does not throw when disposed mid-await',
      () async {
        when(() => mockRepository.setFeedingRemindersEnabled(any())).thenAnswer(
          (_) async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          },
        );

        final notifier = SettingsNotifier(repository: mockRepository);
        final future = notifier.setFeedingRemindersEnabled(false);
        notifier.dispose();

        await expectLater(future, completes);
      },
    );

    test(
      'setStreakAlertsEnabled does not throw when disposed mid-await',
      () async {
        when(() => mockRepository.setStreakAlertsEnabled(any())).thenAnswer((
          _,
        ) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });

        final notifier = SettingsNotifier(repository: mockRepository);
        final future = notifier.setStreakAlertsEnabled(false);
        notifier.dispose();

        await expectLater(future, completes);
      },
    );

    test(
      'setWeeklySummaryEnabled does not throw when disposed mid-await',
      () async {
        when(() => mockRepository.setWeeklySummaryEnabled(any())).thenAnswer((
          _,
        ) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });

        final notifier = SettingsNotifier(repository: mockRepository);
        final future = notifier.setWeeklySummaryEnabled(false);
        notifier.dispose();

        await expectLater(future, completes);
      },
    );

    test('setQuietHours does not throw when disposed mid-await', () async {
      when(() => mockRepository.setQuietHoursStart(any())).thenAnswer((
        _,
      ) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      when(() => mockRepository.setQuietHoursEnd(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      final notifier = SettingsNotifier(repository: mockRepository);
      final future = notifier.setQuietHours(startMinutes: 60, endMinutes: 120);
      notifier.dispose();

      await expectLater(future, completes);
    });

    test('setLanguage does not throw when disposed mid-await', () async {
      when(() => mockRepository.setLanguage(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      final notifier = SettingsNotifier(repository: mockRepository);
      final future = notifier.setLanguage('de');
      notifier.dispose();

      await expectLater(future, completes);
    });
  });
}
