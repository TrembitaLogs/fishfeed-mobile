import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/entities/achievement.dart';
import 'package:fishfeed/domain/usecases/achievement_usecase.dart';
import 'package:fishfeed/presentation/providers/achievement_providers.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockAchievementUseCase extends Mock implements AchievementUseCase {}

class MockRef extends Mock implements Ref {}

void main() {
  // Regression guard for Sentry StateError "Tried to use <Notifier> after
  // `dispose` was called". Async notifier methods await, then assign `state`;
  // if the notifier is disposed during the async gap (user leaves the screen /
  // provider invalidated mid-operation) the post-await `state =` throws.
  // Each method must bail out via `if (!mounted) return;` after every await.
  group('Notifier dispose safety (mounted guards)', () {
    test('AchievementsNotifier.loadAchievements does not touch state after '
        'dispose mid-flight', () async {
      final mockUseCase = MockAchievementUseCase();
      final mockRef = MockRef();

      // No current user → userId falls back to 'default_user', which skips the
      // checkAchievements() await so getAllAchievements is the only async gap.
      when(() => mockRef.read(currentUserProvider)).thenReturn(null);

      // The constructor auto-invokes loadAchievements(); let that first call
      // settle immediately (call 1). The explicit call under test (call 2)
      // resolves after a delay so we can dispose while it is suspended.
      var getAllCallCount = 0;
      when(() => mockUseCase.getAllAchievements('default_user')).thenAnswer((
        _,
      ) async {
        getAllCallCount++;
        if (getAllCallCount > 1) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        return const Right<Failure, List<Achievement>>(<Achievement>[]);
      });

      final notifier = AchievementsNotifier(
        achievementUseCase: mockUseCase,
        ref: mockRef,
      );

      // Let the constructor-triggered load finish while still mounted.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Drive the method under test and dispose during its async gap.
      final future = notifier.loadAchievements();
      notifier.dispose();

      // Before the fix, the post-await `state =` in the fold throws, is caught,
      // and the catch block's `state =` throws again, surfacing
      // 'Bad state: Tried to use AchievementsNotifier after `dispose` was
      // called'. With the guards the future completes cleanly.
      await expectLater(future, completes);
    });
  });
}
