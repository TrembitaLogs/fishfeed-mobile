import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/domain/entities/user_statistics.dart';
import 'package:fishfeed/domain/usecases/calculate_statistics_usecase.dart';
import 'package:fishfeed/presentation/providers/achievement_providers.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';

/// State for user statistics.
class StatisticsState {
  const StatisticsState({
    this.statistics,
    this.isLoading = false,
    this.error,
  });

  /// The calculated statistics.
  final UserStatistics? statistics;

  /// Whether statistics are currently loading.
  final bool isLoading;

  /// Error message if loading failed.
  final String? error;

  /// Whether statistics are available.
  bool get hasData => statistics != null;

  /// Whether there is an error.
  bool get hasError => error != null;

  StatisticsState copyWith({
    UserStatistics? statistics,
    bool? isLoading,
    String? error,
  }) {
    return StatisticsState(
      statistics: statistics ?? this.statistics,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing user statistics.
///
/// Loads and caches statistics calculated from feeding events
/// and user progress data.
class StatisticsNotifier extends StateNotifier<StatisticsState> {
  StatisticsNotifier({
    required CalculateStatisticsUseCase calculateStatisticsUseCase,
    required String? userId,
  })  : _calculateStatisticsUseCase = calculateStatisticsUseCase,
        _userId = userId,
        super(const StatisticsState()) {
    // Load statistics on initialization if user is logged in
    if (_userId != null) {
      loadStatistics();
    }
  }

  final CalculateStatisticsUseCase _calculateStatisticsUseCase;
  final String? _userId;

  /// Loads user statistics from local data sources.
  Future<void> loadStatistics() async {
    if (_userId == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'User not logged in',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _calculateStatisticsUseCase(
      CalculateStatisticsParams(userId: _userId),
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (statistics) {
        state = state.copyWith(
          statistics: statistics,
          isLoading: false,
        );
      },
    );
  }

  /// Refreshes statistics data.
  Future<void> refresh() async {
    await loadStatistics();
  }
}

/// Provider for [CalculateStatisticsUseCase].
final calculateStatisticsUseCaseProvider =
    Provider<CalculateStatisticsUseCase>((ref) {
  final feedingDs = ref.watch(feedingLocalDataSourceProvider);
  final userProgressDs = ref.watch(userProgressLocalDataSourceProvider);
  return CalculateStatisticsUseCase(
    feedingDataSource: feedingDs,
    userProgressDataSource: userProgressDs,
  );
});

/// Provider for user statistics state and notifier.
///
/// Automatically loads statistics when user is logged in.
///
/// Usage:
/// ```dart
/// final statisticsState = ref.watch(statisticsProvider);
/// if (statisticsState.hasData) {
///   final stats = statisticsState.statistics!;
///   print('Total feedings: ${stats.totalFeedings}');
/// }
/// ```
final statisticsProvider =
    StateNotifierProvider<StatisticsNotifier, StatisticsState>((ref) {
  final useCase = ref.watch(calculateStatisticsUseCaseProvider);
  final user = ref.watch(currentUserProvider);
  return StatisticsNotifier(
    calculateStatisticsUseCase: useCase,
    userId: user?.id,
  );
});
