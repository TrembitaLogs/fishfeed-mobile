import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/datasources/local/user_progress_local_ds.dart';
import 'package:fishfeed/domain/entities/achievement.dart';
import 'package:fishfeed/domain/usecases/achievement_usecase.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';

// ============================================================================
// Use Case Provider
// ============================================================================

/// Provider for [UserProgressLocalDataSource].
final userProgressLocalDataSourceProvider =
    Provider<UserProgressLocalDataSource>((ref) {
      return UserProgressLocalDataSource();
    });

/// Provider for [AchievementUseCase].
///
/// Provides singleton access to achievement use case for checking
/// and unlocking achievements.
final achievementUseCaseProvider = Provider<AchievementUseCase>((ref) {
  return AchievementUseCase(
    achievementDataSource: ref.watch(achievementLocalDataSourceProvider),
    feedingDataSource: ref.watch(feedingLocalDataSourceProvider),
    streakDataSource: ref.watch(streakLocalDataSourceProvider),
    progressDataSource: ref.watch(userProgressLocalDataSourceProvider),
  );
});

// ============================================================================
// Achievement State
// ============================================================================

/// State for achievements list.
class AchievementsState {
  const AchievementsState({
    this.achievements = const [],
    this.isLoading = false,
    this.error,
  });

  /// List of all achievements.
  final List<Achievement> achievements;

  /// Whether data is currently loading.
  final bool isLoading;

  /// Error message if loading failed.
  final String? error;

  /// Whether state has an error.
  bool get hasError => error != null;

  /// Count of unlocked achievements.
  int get unlockedCount => achievements.where((a) => a.isUnlocked).length;

  /// Total count of achievements.
  int get totalCount => achievements.length;

  /// Progress towards completing all achievements (0.0 to 1.0).
  double get overallProgress =>
      totalCount > 0 ? unlockedCount / totalCount : 0.0;

  AchievementsState copyWith({
    List<Achievement>? achievements,
    bool? isLoading,
    String? error,
  }) {
    return AchievementsState(
      achievements: achievements ?? this.achievements,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing achievements state.
class AchievementsNotifier extends StateNotifier<AchievementsState> {
  AchievementsNotifier({
    required AchievementUseCase achievementUseCase,
    required Ref ref,
  }) : _achievementUseCase = achievementUseCase,
       _ref = ref,
       super(const AchievementsState()) {
    loadAchievements();
  }

  final AchievementUseCase _achievementUseCase;
  final Ref _ref;

  /// Loads all achievements for the current user.
  Future<void> loadAchievements() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = _ref.read(currentUserProvider)?.id ?? 'default_user';
      final result = await _achievementUseCase.getAllAchievements(userId);

      result.fold(
        (failure) {
          state = state.copyWith(isLoading: false, error: failure.message);
        },
        (achievements) {
          state = state.copyWith(achievements: achievements, isLoading: false);
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load achievements: $e',
      );
    }
  }

  /// Checks and unlocks any pending achievements.
  ///
  /// Returns newly unlocked achievements.
  Future<List<Achievement>> checkAchievements() async {
    try {
      final userId = _ref.read(currentUserProvider)?.id ?? 'default_user';
      final result = await _achievementUseCase.checkAchievements(userId);

      return result.fold((failure) => [], (checkResult) {
        if (checkResult.hasUnlocked) {
          // Reload achievements to update state
          loadAchievements();
        }
        return checkResult.newlyUnlocked;
      });
    } catch (e) {
      return [];
    }
  }

  /// Refreshes achievements.
  Future<void> refresh() async {
    await loadAchievements();
  }

  /// Clears any error state.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Provider for achievements state.
final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, AchievementsState>((ref) {
      final achievementUseCase = ref.watch(achievementUseCaseProvider);

      return AchievementsNotifier(
        achievementUseCase: achievementUseCase,
        ref: ref,
      );
    });

/// Provider for all achievements as an async value.
///
/// Useful for simple async loading in widgets.
final allAchievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final userId = ref.read(currentUserProvider)?.id ?? 'default_user';
  final achievementUseCase = ref.watch(achievementUseCaseProvider);

  final result = await achievementUseCase.getAllAchievements(userId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (achievements) => achievements,
  );
});

/// Provider for unlocked achievements only.
final unlockedAchievementsProvider = FutureProvider<List<Achievement>>((
  ref,
) async {
  final userId = ref.read(currentUserProvider)?.id ?? 'default_user';
  final achievementUseCase = ref.watch(achievementUseCaseProvider);

  final result = await achievementUseCase.getUnlockedAchievements(userId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (achievements) => achievements,
  );
});

/// Provider for unlocked achievements count.
final unlockedAchievementsCountProvider = Provider<int>((ref) {
  final state = ref.watch(achievementsProvider);
  return state.unlockedCount;
});

/// Provider for total achievements count.
final totalAchievementsCountProvider = Provider<int>((ref) {
  final achievementUseCase = ref.watch(achievementUseCaseProvider);
  return achievementUseCase.getTotalCount();
});

/// Provider that checks achievements when invalidated.
///
/// Use this to trigger achievement checking after feeding events.
final checkAchievementsProvider = FutureProvider<List<Achievement>>((
  ref,
) async {
  final notifier = ref.read(achievementsProvider.notifier);
  return notifier.checkAchievements();
});
