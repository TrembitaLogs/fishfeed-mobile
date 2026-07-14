import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/domain/entities/user_statistics.dart';
import 'package:fishfeed/domain/usecases/calculate_statistics_usecase.dart';
import 'package:fishfeed/presentation/providers/statistics_provider.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockCalculateStatisticsUseCase extends Mock
    implements CalculateStatisticsUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(const CalculateStatisticsParams(userId: 'fallback'));
  });

  // Regression guard for Sentry StateError "Tried to use StatisticsNotifier
  // after `dispose` was called". Async notifier methods await, then assign
  // `state`; if the notifier is disposed during the async gap (user leaves the
  // screen / provider invalidated mid-operation) the post-await `state =`
  // throws. Each method must bail out via `if (!mounted) return;` after the
  // await.
  group('Notifier dispose safety (mounted guards)', () {
    late MockCalculateStatisticsUseCase mockUseCase;

    setUp(() {
      mockUseCase = MockCalculateStatisticsUseCase();
    });

    /// Stubs the use case so the constructor's auto-load resolves immediately
    /// (call #1) while the method under test (call #2) resolves only after a
    /// delay, giving the test a window to dispose the notifier mid-flight.
    void stubImmediateThenDelayed() {
      var callCount = 0;
      when(() => mockUseCase.call(any())).thenAnswer((_) async {
        callCount++;
        if (callCount > 1) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        return Right(UserStatistics.empty());
      });
    }

    test(
      'loadStatistics does not touch state after dispose mid-flight',
      () async {
        stubImmediateThenDelayed();

        final notifier = StatisticsNotifier(
          calculateStatisticsUseCase: mockUseCase,
          userId: 'user_1',
        );

        // Let the constructor's auto-load (call #1) settle before disposing.
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // loadStatistics() awaits the delayed use case (call #2) before touching
        // state. Capture the future, then dispose while it is suspended.
        final future = notifier.loadStatistics();
        notifier.dispose();

        // Must complete without throwing StateError-after-dispose.
        await expectLater(future, completes);
      },
    );

    test('refresh does not touch state after dispose mid-flight', () async {
      stubImmediateThenDelayed();

      final notifier = StatisticsNotifier(
        calculateStatisticsUseCase: mockUseCase,
        userId: 'user_1',
      );

      // Let the constructor's auto-load (call #1) settle before disposing.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // refresh() delegates to loadStatistics(), which awaits the delayed use
      // case (call #2). Capture the future, then dispose while it is suspended.
      final future = notifier.refresh();
      notifier.dispose();

      await expectLater(future, completes);
    });
  });
}
