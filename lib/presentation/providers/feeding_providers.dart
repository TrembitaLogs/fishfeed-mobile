import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/di/datasource_providers.dart';
import 'package:fishfeed/core/di/repository_providers.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/domain/entities/streak.dart';
import 'package:fishfeed/domain/repositories/aquarium_repository.dart';
import 'package:fishfeed/domain/repositories/fish_repository.dart';
import 'package:fishfeed/domain/services/feeding_event_generator.dart';
import 'package:fishfeed/domain/usecases/calculate_streak_usecase.dart';
import 'package:fishfeed/presentation/providers/achievement_providers.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/services/analytics/analytics_service.dart';
import 'package:fishfeed/services/feeding/feeding_service.dart';

// ============================================================================
// Today Feedings Provider
// ============================================================================

/// State for today's feedings list.
class TodayFeedingsState {
  const TodayFeedingsState({
    this.feedings = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
  });

  /// List of computed feeding events for today.
  final List<ComputedFeedingEvent> feedings;

  /// Whether data is currently loading (initial load).
  final bool isLoading;

  /// Whether data is being refreshed (pull-to-refresh).
  final bool isRefreshing;

  /// Error message if loading failed.
  final String? error;

  /// Whether state has an error.
  bool get hasError => error != null;

  /// Whether feedings list is empty.
  bool get isEmpty =>
      feedings.isEmpty && !isLoading && !isRefreshing && !hasError;

  /// Count of completed feedings (fed or skipped).
  int get completedCount =>
      feedings.where((f) => f.status == EventStatus.fed).length;

  /// Count of pending feedings.
  int get pendingCount =>
      feedings.where((f) => f.status == EventStatus.pending).length;

  /// Count of overdue/skipped feedings.
  int get missedCount => feedings
      .where(
        (f) =>
            f.status == EventStatus.skipped || f.status == EventStatus.overdue,
      )
      .length;

  TodayFeedingsState copyWith({
    List<ComputedFeedingEvent>? feedings,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
  }) {
    return TodayFeedingsState(
      feedings: feedings ?? this.feedings,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing today's feedings state.
///
/// Uses [FeedingEventGenerator] to compute feeding events from schedules and logs.
/// Uses [FeedingService] for marking feedings as fed/skipped.
class TodayFeedingsNotifier extends StateNotifier<TodayFeedingsState> {
  TodayFeedingsNotifier({
    required FeedingEventGenerator feedingEventGenerator,
    required FeedingService feedingService,
    required AquariumRepository aquariumRepository,
    required FishRepository fishRepository,
    required Ref ref,
  }) : _feedingEventGenerator = feedingEventGenerator,
       _feedingService = feedingService,
       _aquariumRepository = aquariumRepository,
       _fishRepository = fishRepository,
       _ref = ref,
       super(const TodayFeedingsState()) {
    loadFeedings();
  }

  final FeedingEventGenerator _feedingEventGenerator;
  final FeedingService _feedingService;
  final AquariumRepository _aquariumRepository;
  final FishRepository _fishRepository;
  final Ref _ref;

  /// Loads today's feedings using FeedingEventGenerator.
  ///
  /// Generates computed events for all user's aquariums for today.
  Future<void> loadFeedings() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get all user's aquariums via repository
      final aquariumsResult = _aquariumRepository.getCachedAquariums();
      final aquariums = aquariumsResult.fold(
        (_) => <Aquarium>[],
        (list) => list,
      );
      final aquariumIds = aquariums.map((a) => a.id).toList();

      if (aquariumIds.isEmpty) {
        state = state.copyWith(feedings: [], isLoading: false);
        return;
      }

      // Build resolver functions for display names and quantity
      final fishNameResolver = _buildFishNameResolver();
      final fishQuantityResolver = _buildFishQuantityResolver();
      final aquariumNameResolver = _buildAquariumNameResolver(aquariums);
      final avatarResolver = _buildAvatarResolver();

      // Generate events for all aquariums for today
      final eventsByAquarium = _feedingEventGenerator
          .generateTodayEventsForAllAquariums(
            aquariumIds: aquariumIds,
            fishNameResolver: fishNameResolver,
            fishQuantityResolver: fishQuantityResolver,
            aquariumNameResolver: aquariumNameResolver,
            avatarResolver: avatarResolver,
          );

      // Flatten all events
      final allEvents = <ComputedFeedingEvent>[];
      for (final events in eventsByAquarium.values) {
        allEvents.addAll(events);
      }

      // Sort by scheduled time
      allEvents.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));

      state = state.copyWith(feedings: allEvents, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load feedings: $e',
      );
    }
  }

  /// Refreshes today's feedings (pull-to-refresh).
  ///
  /// Uses [isRefreshing] instead of [isLoading] to avoid showing shimmer.
  Future<void> refresh() async {
    // Delay state update to avoid modifying provider during build
    await Future<void>.delayed(const Duration(milliseconds: 100));

    try {
      final aquariumsResult = _aquariumRepository.getCachedAquariums();
      final aquariums = aquariumsResult.fold(
        (_) => <Aquarium>[],
        (list) => list,
      );
      final aquariumIds = aquariums.map((a) => a.id).toList();

      if (aquariumIds.isEmpty) {
        state = state.copyWith(feedings: []);
        return;
      }

      final fishNameResolver = _buildFishNameResolver();
      final fishQuantityResolver = _buildFishQuantityResolver();
      final aquariumNameResolver = _buildAquariumNameResolver(aquariums);
      final avatarResolver = _buildAvatarResolver();

      final eventsByAquarium = _feedingEventGenerator
          .generateTodayEventsForAllAquariums(
            aquariumIds: aquariumIds,
            fishNameResolver: fishNameResolver,
            fishQuantityResolver: fishQuantityResolver,
            aquariumNameResolver: aquariumNameResolver,
            avatarResolver: avatarResolver,
          );

      final allEvents = <ComputedFeedingEvent>[];
      for (final events in eventsByAquarium.values) {
        allEvents.addAll(events);
      }

      allEvents.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));

      state = state.copyWith(feedings: allEvents);
    } catch (e) {
      state = state.copyWith(error: 'Failed to refresh feedings: $e');
    }
  }

  /// Marks a feeding as fed.
  ///
  /// Delegates to [FeedingService] which handles:
  /// - Creating FeedingLog
  /// - Adding to sync queue
  /// - Updating streak (increment only)
  Future<void> markAsFed(String scheduleId) async {
    final feeding = state.feedings.firstWhere(
      (f) => f.scheduleId == scheduleId,
      orElse: () => throw StateError('Feeding not found: $scheduleId'),
    );

    final user = _ref.read(currentUserProvider);
    final userId = user?.id ?? 'default_user';

    // Call FeedingService
    final result = await _feedingService.markAsFed(
      scheduleId: scheduleId,
      scheduledFor: feeding.scheduledFor,
      userId: userId,
      userDisplayName: user?.displayName,
    );

    switch (result) {
      case FeedingSuccess(:final streak):
        // Track analytics
        AnalyticsService.instance.trackFeedMarked(
          eventId: scheduleId,
          status: FeedStatus.fed,
        );

        // Refresh to get updated state from generator
        await refresh();

        // Refresh streak provider
        _ref.invalidate(currentStreakProvider);

        // Check and unlock achievements
        _ref.invalidate(checkAchievementsProvider);

        // Track streak analytics if incremented
        if (streak.currentStreak > 0) {
          AnalyticsService.instance.trackStreakIncremented(
            streakCount: streak.currentStreak,
          );
        }

      case FeedingAlreadyDone(:final message):
        // Show conflict - feeding was already marked by another device
        state = state.copyWith(error: message);
    }
  }

  /// Marks a feeding as skipped.
  ///
  /// Note: Skipping does NOT reset streak - streak is only reset
  /// when a full day is missed (detected by client-side break detection
  /// in [CalculateStreakUseCase]).
  Future<void> markAsMissed(String scheduleId) async {
    final feeding = state.feedings.firstWhere(
      (f) => f.scheduleId == scheduleId,
      orElse: () => throw StateError('Feeding not found: $scheduleId'),
    );

    final user = _ref.read(currentUserProvider);
    final userId = user?.id ?? 'default_user';

    // Call FeedingService
    final result = await _feedingService.markAsSkipped(
      scheduleId: scheduleId,
      scheduledFor: feeding.scheduledFor,
      userId: userId,
      userDisplayName: user?.displayName,
    );

    switch (result) {
      case FeedingSuccess():
        // Track analytics
        AnalyticsService.instance.trackFeedMarked(
          eventId: scheduleId,
          status: FeedStatus.missed,
        );

        // Refresh to get updated state from generator
        await refresh();

        // Note: NO streak reset here - break detection runs on loadStreak

        // Notify streak provider to refresh (runs break detection)
        _ref.invalidate(currentStreakProvider);

      case FeedingAlreadyDone(:final message):
        state = state.copyWith(error: message);
    }
  }

  /// Refreshes feedings to reflect updated status.
  ///
  /// Since ComputedFeedingEvent is computed from logs, we refresh
  /// to regenerate events with updated status.
  void updateFeedingStatus(String scheduleId, EventStatus newStatus) {
    // Trigger refresh to regenerate events from updated logs
    refresh();
  }

  /// Clears any error state.
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Builds a resolver for fish display names.
  String? Function(String) _buildFishNameResolver() {
    final allFish = _fishRepository.getAllFish();
    final fishMap = <String, String>{};
    for (final fish in allFish) {
      // Use custom name if available, otherwise use speciesId as fallback
      // (species name should be resolved from species provider if needed)
      fishMap[fish.id] = fish.name ?? 'Fish';
    }
    return (String fishId) => fishMap[fishId];
  }

  /// Builds a resolver for fish quantities.
  int Function(String) _buildFishQuantityResolver() {
    final allFish = _fishRepository.getAllFish();
    final quantityMap = <String, int>{};
    for (final fish in allFish) {
      quantityMap[fish.id] = fish.quantity;
    }
    return (String fishId) => quantityMap[fishId] ?? 1;
  }

  /// Builds a resolver for aquarium display names.
  String? Function(String) _buildAquariumNameResolver(
    List<Aquarium> aquariums,
  ) {
    final aquariumMap = <String, String>{};
    for (final aquarium in aquariums) {
      aquariumMap[aquarium.id] = aquarium.name;
    }
    return (String aquariumId) => aquariumMap[aquariumId];
  }

  /// Builds a resolver for user avatar URLs.
  ///
  /// Currently returns null - in future could resolve from family members cache.
  String? Function(String) _buildAvatarResolver() {
    // TODO: Implement family members avatar resolution
    return (String userId) => null;
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Provider for [FeedingEventGenerator].
final feedingEventGeneratorProvider = Provider<FeedingEventGenerator>((ref) {
  final scheduleDs = ref.watch(scheduleLocalDataSourceProvider);
  final feedingLogDs = ref.watch(feedingLogLocalDataSourceProvider);
  final fishDs = ref.watch(fishLocalDataSourceProvider);

  return FeedingEventGenerator(
    scheduleLocalDs: scheduleDs,
    feedingLogLocalDs: feedingLogDs,
    fishLocalDs: fishDs,
  );
});

/// Provider for today's feedings state.
final todayFeedingsProvider =
    StateNotifierProvider<TodayFeedingsNotifier, TodayFeedingsState>((ref) {
      final generator = ref.watch(feedingEventGeneratorProvider);
      final feedingService = ref.watch(feedingServiceProvider);
      final aquariumRepository = ref.watch(aquariumRepositoryProvider);
      final fishRepository = ref.watch(fishRepositoryProvider);

      return TodayFeedingsNotifier(
        feedingEventGenerator: generator,
        feedingService: feedingService,
        aquariumRepository: aquariumRepository,
        fishRepository: fishRepository,
        ref: ref,
      );
    });

/// Provider for grouped feedings by time period.
///
/// Returns a map with keys: 'morning', 'afternoon', 'evening'.
final groupedFeedingsProvider =
    Provider<Map<String, List<ComputedFeedingEvent>>>((ref) {
      final state = ref.watch(todayFeedingsProvider);
      final feedings = state.feedings;

      final grouped = <String, List<ComputedFeedingEvent>>{
        'morning': [],
        'afternoon': [],
        'evening': [],
      };

      for (final feeding in feedings) {
        final period = _getTimePeriod(feeding.scheduledFor.hour);
        grouped[period]?.add(feeding);
      }

      return grouped;
    });

/// Helper to determine time period from hour.
String _getTimePeriod(int hour) {
  if (hour < 12) {
    return 'morning';
  } else if (hour < 18) {
    return 'afternoon';
  } else {
    return 'evening';
  }
}

/// Provider for feedings filtered by aquarium ID.
///
/// Returns list of today's feedings for a specific aquarium.
///
/// Usage:
/// ```dart
/// final feedings = ref.watch(aquariumFeedingsProvider('aquarium-123'));
/// ```
final aquariumFeedingsProvider =
    Provider.family<List<ComputedFeedingEvent>, String>((ref, aquariumId) {
      final state = ref.watch(todayFeedingsProvider);
      return state.feedings
          .where((feeding) => feeding.aquariumId == aquariumId)
          .toList();
    });

/// Provider for grouped feedings by aquarium ID.
///
/// Returns a map with aquarium IDs as keys and list of feedings as values.
final feedingsGroupedByAquariumProvider =
    Provider<Map<String, List<ComputedFeedingEvent>>>((ref) {
      final state = ref.watch(todayFeedingsProvider);
      final feedings = state.feedings;

      final grouped = <String, List<ComputedFeedingEvent>>{};

      for (final feeding in feedings) {
        grouped.putIfAbsent(feeding.aquariumId, () => []).add(feeding);
      }

      return grouped;
    });

/// Provider for feedings grouped by exact schedule time for a specific aquarium.
///
/// Returns a sorted map where keys are time strings ("09:00", "12:00", "18:00")
/// and values are lists of feedings for that time slot.
///
/// Usage:
/// ```dart
/// final grouped = ref.watch(feedingsGroupedByTimeProvider('aquarium-123'));
/// // {'09:00': [...], '12:00': [...], '18:00': [...]}
/// ```
final feedingsGroupedByTimeProvider =
    Provider.family<Map<String, List<ComputedFeedingEvent>>, String>((
      ref,
      aquariumId,
    ) {
      final feedings = ref.watch(aquariumFeedingsProvider(aquariumId));
      final grouped = <String, List<ComputedFeedingEvent>>{};
      for (final feeding in feedings) {
        grouped.putIfAbsent(feeding.time, () => []).add(feeding);
      }
      // Sort by time key
      final sortedKeys = grouped.keys.toList()..sort();
      return Map.fromEntries(sortedKeys.map((k) => MapEntry(k, grouped[k]!)));
    });

/// Provider for active feeding schedules for a specific fish.
///
/// Queries all schedules from Hive via [ScheduleLocalDataSource],
/// filters to only active schedules for the given fish ID,
/// and sorts them by time of day.
///
/// Usage:
/// ```dart
/// final schedules = ref.watch(activeSchedulesForFishProvider('fish-123'));
/// ```
final activeSchedulesForFishProvider =
    Provider.family<List<ScheduleModel>, String>((ref, fishId) {
      final scheduleDs = ref.watch(scheduleLocalDataSourceProvider);
      return scheduleDs.getByFishId(fishId, activeOnly: true);
    });

/// Aquarium feeding status for the aquarium list screen.
enum AquariumFeedingStatus {
  /// Has overdue/pending feedings that need attention.
  pendingFeeding,

  /// All feedings for today are completed.
  allFed,

  /// Next feeding is scheduled in the future.
  nextAt,
}

/// Provider for aquarium feeding status.
///
/// Returns a record with the status enum and optional next time string.
/// Used by aquarium list screen to show status badges.
///
/// Status logic:
/// - Has overdue feedings (scheduledFor < now, needsAttention) → pendingFeeding
/// - All feedings completed (fed/skipped) → allFed
/// - Has future pending feedings → nextAt with earliest time
/// - No feedings at all → allFed
final aquariumFeedingStatusProvider =
    Provider.family<({AquariumFeedingStatus status, String? nextTime}), String>(
      (ref, aquariumId) {
        final feedings = ref.watch(aquariumFeedingsProvider(aquariumId));

        if (feedings.isEmpty) {
          return (status: AquariumFeedingStatus.allFed, nextTime: null);
        }

        final now = DateTime.now();

        // Check for overdue feedings that need attention
        final overdue = feedings
            .where((f) => f.needsAttention && f.scheduledFor.isBefore(now))
            .toList();
        if (overdue.isNotEmpty) {
          overdue.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
          return (
            status: AquariumFeedingStatus.pendingFeeding,
            nextTime: overdue.first.time,
          );
        }

        // Check for future pending feedings
        final futurePending = feedings
            .where(
              (f) =>
                  f.status == EventStatus.pending &&
                  !f.scheduledFor.isBefore(now),
            )
            .toList();
        if (futurePending.isNotEmpty) {
          futurePending.sort(
            (a, b) => a.scheduledFor.compareTo(b.scheduledFor),
          );
          return (
            status: AquariumFeedingStatus.nextAt,
            nextTime: futurePending.first.time,
          );
        }

        // All feedings are completed
        return (status: AquariumFeedingStatus.allFed, nextTime: null);
      },
    );

// ============================================================================
// Current Streak Provider
// ============================================================================

/// State for current streak.
class StreakState {
  const StreakState({this.streak, this.isLoading = false, this.error});

  /// Current streak data.
  final Streak? streak;

  /// Whether data is currently loading.
  final bool isLoading;

  /// Error message if loading failed.
  final String? error;

  /// Current streak count.
  int get currentStreak => streak?.currentStreak ?? 0;

  /// Longest streak ever achieved.
  int get longestStreak => streak?.longestStreak ?? 0;

  /// Whether streak is active.
  bool get isActive => streak != null && streak!.currentStreak > 0;

  StreakState copyWith({
    Streak? streak,
    bool? isLoading,
    String? error,
    bool clearStreak = false,
  }) {
    return StreakState(
      streak: clearStreak ? null : (streak ?? this.streak),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing current streak state.
///
/// Reads streak from Hive and runs client-side break detection.
/// Mobile is the source of truth for streak state; server is sync-only storage.
class StreakNotifier extends StateNotifier<StreakState> {
  StreakNotifier({
    required StreakLocalDataSource streakDataSource,
    required CalculateStreakUseCase calculateStreakUseCase,
    required Ref ref,
  }) : _streakDataSource = streakDataSource,
       _calculateStreakUseCase = calculateStreakUseCase,
       _ref = ref,
       super(const StreakState()) {
    loadStreak();
  }

  final StreakLocalDataSource _streakDataSource;
  final CalculateStreakUseCase _calculateStreakUseCase;
  final Ref _ref;

  /// Loads the current streak from Hive with break detection.
  ///
  /// After loading the streak, runs [CalculateStreakUseCase] which checks
  /// for missed days and applies freeze or resets the streak accordingly.
  Future<void> loadStreak() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = _ref.read(currentUserProvider)?.id ?? 'default_user';

      // Use CalculateStreakUseCase which handles break detection
      final result = await _calculateStreakUseCase(
        CalculateStreakParams(userId: userId),
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to load streak: $failure',
          );
        },
        (calculationResult) {
          state = state.copyWith(
            streak: calculationResult.streak,
            isLoading: false,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load streak: $e',
      );
    }
  }

  /// Refreshes the streak from Hive.
  Future<void> refresh() async {
    await loadStreak();
  }

  /// Increments the current streak.
  ///
  /// Called automatically when a feeding is marked as fed.
  Future<void> incrementStreak() async {
    try {
      final userId = _ref.read(currentUserProvider)?.id ?? 'default_user';
      final previousStreak = state.streak?.currentStreak ?? 0;
      final updatedModel = await _streakDataSource.incrementStreak(
        userId,
        DateTime.now(),
      );

      state = state.copyWith(streak: updatedModel.toEntity());

      // Track streak analytics
      final newStreak = updatedModel.currentStreak;
      if (previousStreak == 0 && newStreak > 0) {
        AnalyticsService.instance.trackStreakStarted();
      } else if (newStreak > previousStreak) {
        AnalyticsService.instance.trackStreakIncremented(
          streakCount: newStreak,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to increment streak: $e');
    }
  }
}

/// Provider for current streak state.
final currentStreakProvider =
    StateNotifierProvider<StreakNotifier, StreakState>((ref) {
      final streakDs = ref.watch(streakLocalDataSourceProvider);
      final feedingLogDs = ref.watch(feedingLogLocalDataSourceProvider);
      final calculateStreakUseCase = CalculateStreakUseCase(
        streakDataSource: streakDs,
        feedingLogDataSource: feedingLogDs,
      );

      return StreakNotifier(
        streakDataSource: streakDs,
        calculateStreakUseCase: calculateStreakUseCase,
        ref: ref,
      );
    });

/// Provider for just the current streak count.
///
/// Convenience provider for widgets that only need the count.
final currentStreakCountProvider = Provider<int>((ref) {
  return ref.watch(currentStreakProvider).currentStreak;
});

/// Provider for streak active status.
final isStreakActiveProvider = Provider<bool>((ref) {
  return ref.watch(currentStreakProvider).isActive;
});
