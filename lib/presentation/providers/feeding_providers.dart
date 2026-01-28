import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/domain/entities/feeding_status.dart';
import 'package:fishfeed/domain/entities/scheduled_feeding.dart';
import 'package:fishfeed/domain/entities/streak.dart';
import 'package:fishfeed/domain/usecases/mark_feeding_usecase.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/species_provider.dart';
import 'package:fishfeed/services/analytics/analytics_service.dart';

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

  /// List of scheduled feedings for today.
  final List<ScheduledFeeding> feedings;

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

  /// Count of completed feedings.
  int get completedCount =>
      feedings.where((f) => f.status == FeedingStatus.fed).length;

  /// Count of pending feedings.
  int get pendingCount =>
      feedings.where((f) => f.status == FeedingStatus.pending).length;

  /// Count of missed feedings.
  int get missedCount =>
      feedings.where((f) => f.status == FeedingStatus.missed).length;

  TodayFeedingsState copyWith({
    List<ScheduledFeeding>? feedings,
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
/// Integrates with [MarkFeedingUseCase] for marking feedings as fed/missed.
/// Updates streak automatically when feedings are marked.
class TodayFeedingsNotifier extends StateNotifier<TodayFeedingsState> {
  TodayFeedingsNotifier({
    required FeedingLocalDataSource feedingDataSource,
    required FishLocalDataSource fishDataSource,
    required AquariumLocalDataSource aquariumDataSource,
    required StreakLocalDataSource streakDataSource,
    required MarkFeedingUseCase markFeedingUseCase,
    required Ref ref,
  }) : _feedingDataSource = feedingDataSource,
       _fishDataSource = fishDataSource,
       _aquariumDataSource = aquariumDataSource,
       _streakDataSource = streakDataSource,
       _markFeedingUseCase = markFeedingUseCase,
       _ref = ref,
       super(const TodayFeedingsState()) {
    loadFeedings();
  }

  final FeedingLocalDataSource _feedingDataSource;
  final FishLocalDataSource _fishDataSource;
  final AquariumLocalDataSource _aquariumDataSource;
  final StreakLocalDataSource _streakDataSource;
  final MarkFeedingUseCase _markFeedingUseCase;
  final Ref _ref;

  /// Loads today's feedings.
  ///
  /// Generates schedule based on user's fish and species,
  /// then cross-references with completed FeedingEvents.
  Future<void> loadFeedings() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get today's completed feeding events from Hive
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayEvents = _feedingDataSource.getFeedingEventsByDate(today);

      // Create a map of COMPLETED feeding IDs to their event data for lookup
      // Only events with completedBy set are actually completed
      final completedEventsMap = <String, _CompletedEventInfo>{};
      for (final event in todayEvents) {
        // Only add to completed map if event was actually marked as fed
        if (event.completedBy != null) {
          final key = event.localId ?? event.id;
          completedEventsMap[key] = _CompletedEventInfo(
            completedBy: event.completedBy,
            completedByName: event.completedByName,
            completedByAvatar: event.completedByAvatar,
          );
        }
      }

      // Generate mock schedule for now
      // In production, this would come from user's fish/species data
      final mockFeedings = _generateTodaySchedule(
        today,
        completedEventsMap,
        now,
      );

      // Sort by scheduled time
      mockFeedings.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

      state = state.copyWith(feedings: mockFeedings, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load feedings: $e',
      );
    }
  }

  /// Generates today's feeding schedule based on user's fish and feeding events.
  ///
  /// Reads scheduled feeding events from Hive and maps them to user's fish.
  /// Events for deleted fish are filtered out.
  List<ScheduledFeeding> _generateTodaySchedule(
    DateTime today,
    Map<String, _CompletedEventInfo> completedEventsMap,
    DateTime now,
  ) {
    // Get all feeding events scheduled for today
    final todayEvents = _feedingDataSource.getFeedingEventsByDate(today);

    // Get all aquariums to map names by ID
    final aquariums = _aquariumDataSource.getAllAquariums();
    final aquariumMap = <String, String>{};
    for (final aquarium in aquariums) {
      aquariumMap[aquarium.id] = aquarium.name;
    }

    // Get all user's fish - keyed by fish ID (getAllFish already filters deleted)
    final allFish = _fishDataSource.getAllFish();
    final fishByIdMap = <String, FishModel>{};
    for (final fish in allFish) {
      fishByIdMap[fish.id] = fish;
    }

    final scheduleList = <ScheduledFeeding>[];

    for (final event in todayEvents) {
      // Look up fish by actual fish ID (may be null for aquarium-level events)
      final fish = event.fishId.isNotEmpty ? fishByIdMap[event.fishId] : null;

      // Get species data for display name
      String speciesName;
      String? fishId;
      if (fish != null) {
        // Event linked to specific fish - use fish's custom name or species name
        speciesName =
            fish.name ?? _ref.read(speciesNameByIdProvider(fish.speciesId));
        fishId = fish.id;
      } else if (event.speciesId != null && event.speciesId!.isNotEmpty) {
        // No fish linked, but we have species_id from server
        speciesName = _ref.read(speciesNameByIdProvider(event.speciesId!));
        fishId = null;
      } else {
        // Aquarium-level event (no specific fish or species) - use food type as name
        speciesName = event.foodType ?? 'Feeding';
        fishId = null;
      }

      // Get aquarium name from map or use default
      final aquariumName = aquariumMap[event.aquariumId] ?? 'My Aquarium';

      final feeding = _createScheduledFeeding(
        id: event.localId ?? event.id,
        time: event.feedingTime,
        aquariumId: event.aquariumId,
        aquariumName: aquariumName,
        speciesName: speciesName,
        foodType: event.foodType ?? 'Flakes',
        portionGrams: event.amount ?? 0.5,
        completedEventsMap: completedEventsMap,
        now: now,
        fishId: fishId,
      );

      scheduleList.add(feeding);
    }

    return scheduleList;
  }

  /// Creates a scheduled feeding with appropriate status.
  ScheduledFeeding _createScheduledFeeding({
    required String id,
    required DateTime time,
    required String aquariumId,
    required String aquariumName,
    required String speciesName,
    required String foodType,
    required double portionGrams,
    required Map<String, _CompletedEventInfo> completedEventsMap,
    required DateTime now,
    String? fishId,
  }) {
    FeedingStatus status;
    DateTime? completedAt;
    String? completedBy;
    String? completedByName;
    String? completedByAvatar;

    final eventInfo = completedEventsMap[id];
    if (eventInfo != null) {
      status = FeedingStatus.fed;
      completedAt = now;
      completedBy = eventInfo.completedBy;
      completedByName = eventInfo.completedByName;
      completedByAvatar = eventInfo.completedByAvatar;
    } else if (time.isBefore(now)) {
      status = FeedingStatus.missed;
    } else {
      status = FeedingStatus.pending;
    }

    return ScheduledFeeding(
      id: id,
      scheduledTime: time,
      aquariumId: aquariumId,
      aquariumName: aquariumName,
      fishId: fishId,
      speciesName: speciesName,
      status: status,
      foodType: foodType,
      portionGrams: portionGrams,
      completedAt: completedAt,
      completedBy: completedBy,
      completedByName: completedByName,
      completedByAvatar: completedByAvatar,
    );
  }

  /// Refreshes today's feedings (pull-to-refresh).
  ///
  /// Uses [isRefreshing] instead of [isLoading] to avoid showing shimmer.
  Future<void> refresh() async {
    // Delay state update to avoid modifying provider during build
    await Future<void>.delayed(const Duration(milliseconds: 100));

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayEvents = _feedingDataSource.getFeedingEventsByDate(today);

      final completedEventsMap = <String, _CompletedEventInfo>{};
      for (final event in todayEvents) {
        if (event.completedBy != null) {
          final key = event.localId ?? event.id;
          completedEventsMap[key] = _CompletedEventInfo(
            completedBy: event.completedBy,
            completedByName: event.completedByName,
            completedByAvatar: event.completedByAvatar,
          );
        }
      }

      final feedings = _generateTodaySchedule(today, completedEventsMap, now);
      feedings.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

      state = state.copyWith(feedings: feedings);
    } catch (e) {
      state = state.copyWith(error: 'Failed to refresh feedings: $e');
    }
  }

  /// Marks a feeding as fed.
  ///
  /// Updates the existing feeding event in Hive with completion info
  /// and refreshes the UI state.
  Future<void> markAsFed(String feedingId) async {
    final feeding = state.feedings.firstWhere(
      (f) => f.id == feedingId,
      orElse: () => throw StateError('Feeding not found: $feedingId'),
    );

    final user = _ref.read(currentUserProvider);
    final userId = user?.id ?? 'default_user';
    final now = DateTime.now();

    // Update existing feeding event in Hive with completion info
    // feedingId is localId from UI, so search by localId
    final existingEvent = _feedingDataSource.getFeedingEventByLocalId(
      feedingId,
    );
    if (existingEvent != null) {
      existingEvent.completedBy = userId;
      existingEvent.completedByName = user?.displayName;
      existingEvent.completedByAvatar = user?.avatarUrl;
      existingEvent.synced = false; // Mark for re-sync
      existingEvent.updatedAt = now;
      await _feedingDataSource.updateFeedingEvent(existingEvent);

      // Track feed marked analytics event
      AnalyticsService.instance.trackFeedMarked(
        eventId: feedingId,
        status: FeedStatus.fed,
      );

      // Update local state with user attribution
      final updatedFeedings = state.feedings.map((f) {
        if (f.id == feedingId) {
          return f.copyWith(
            status: FeedingStatus.fed,
            completedAt: now,
            completedBy: userId,
            completedByName: user?.displayName,
            completedByAvatar: user?.avatarUrl,
          );
        }
        return f;
      }).toList();

      state = state.copyWith(feedings: updatedFeedings);

      // Notify streak provider to refresh
      _ref.invalidate(currentStreakProvider);
      return;
    }

    // Fallback: create new event via MarkFeedingUseCase if no existing event
    final result = await _markFeedingUseCase(
      MarkFeedingParams(
        scheduledFeedingId: feedingId,
        newStatus: FeedingStatus.fed,
        userId: userId,
        aquariumId: feeding.aquariumId,
        fishId: feeding.fishId,
        amount: feeding.portionGrams,
        foodType: feeding.foodType,
        userDisplayName: user?.displayName,
        userAvatarUrl: user?.avatarUrl,
      ),
    );

    result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
      },
      (markResult) {
        // Track feed marked analytics event
        AnalyticsService.instance.trackFeedMarked(
          eventId: feedingId,
          status: FeedStatus.fed,
        );

        // Update local state with user attribution
        final updatedFeedings = state.feedings.map((f) {
          if (f.id == feedingId) {
            return f.copyWith(
              status: FeedingStatus.fed,
              completedAt: now,
              completedBy: userId,
              completedByName: user?.displayName,
              completedByAvatar: user?.avatarUrl,
            );
          }
          return f;
        }).toList();

        state = state.copyWith(feedings: updatedFeedings);

        // Notify streak provider to refresh
        _ref.invalidate(currentStreakProvider);
      },
    );
  }

  /// Marks a feeding as missed (or reverts a completed feeding).
  ///
  /// If the feeding was previously completed, clears completion info
  /// and marks for re-sync. Also resets the streak.
  Future<void> markAsMissed(String feedingId) async {
    final feeding = state.feedings.firstWhere(
      (f) => f.id == feedingId,
      orElse: () => throw StateError('Feeding not found: $feedingId'),
    );

    final userId = _ref.read(currentUserProvider)?.id ?? 'default_user';
    final now = DateTime.now();

    // Update existing feeding event in Hive - clear completion info
    // feedingId is localId from UI, so search by localId
    final existingEvent = _feedingDataSource.getFeedingEventByLocalId(
      feedingId,
    );
    if (existingEvent != null) {
      // Clear completion info to revert status to pending
      existingEvent.completedBy = null;
      existingEvent.completedByName = null;
      existingEvent.completedByAvatar = null;
      existingEvent.synced = false; // Mark for re-sync
      existingEvent.updatedAt = now;
      await _feedingDataSource.updateFeedingEvent(existingEvent);

      // Track feed marked analytics event
      AnalyticsService.instance.trackFeedMarked(
        eventId: feedingId,
        status: FeedStatus.missed,
      );

      // Update local state - show as missed in UI
      final updatedFeedings = state.feedings.map((f) {
        if (f.id == feedingId) {
          return f.copyWith(
            status: FeedingStatus.missed,
            completedAt: null,
            completedBy: null,
            completedByName: null,
            completedByAvatar: null,
          );
        }
        return f;
      }).toList();

      state = state.copyWith(feedings: updatedFeedings);

      // Reset streak for missed feeding
      await _streakDataSource.resetStreak(userId);

      // Notify streak provider to refresh
      _ref.invalidate(currentStreakProvider);
      return;
    }

    // Fallback: use MarkFeedingUseCase if no existing event
    final result = await _markFeedingUseCase(
      MarkFeedingParams(
        scheduledFeedingId: feedingId,
        newStatus: FeedingStatus.missed,
        userId: userId,
        aquariumId: feeding.aquariumId,
        fishId: feeding.fishId,
      ),
    );

    result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
      },
      (markResult) {
        // Track feed marked analytics event
        AnalyticsService.instance.trackFeedMarked(
          eventId: feedingId,
          status: FeedStatus.missed,
        );

        // Update local state
        final updatedFeedings = state.feedings.map((f) {
          if (f.id == feedingId) {
            return f.copyWith(status: FeedingStatus.missed);
          }
          return f;
        }).toList();

        state = state.copyWith(feedings: updatedFeedings);

        // Notify streak provider to refresh
        _ref.invalidate(currentStreakProvider);
      },
    );
  }

  /// Updates the status of a feeding locally without use case.
  ///
  /// Used for quick UI updates when use case is not needed.
  void updateFeedingStatus(String feedingId, FeedingStatus newStatus) {
    final updatedFeedings = state.feedings.map((feeding) {
      if (feeding.id == feedingId) {
        return feeding.copyWith(
          status: newStatus,
          completedAt: newStatus == FeedingStatus.fed ? DateTime.now() : null,
        );
      }
      return feeding;
    }).toList();

    state = state.copyWith(feedings: updatedFeedings);
  }

  /// Clears any error state.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for [MarkFeedingUseCase].
final markFeedingUseCaseProvider = Provider<MarkFeedingUseCase>((ref) {
  final feedingDs = ref.watch(feedingLocalDataSourceProvider);
  final streakDs = ref.watch(streakLocalDataSourceProvider);
  final syncQueueDs = ref.watch(syncQueueDataSourceProvider);

  return MarkFeedingUseCase(
    feedingDataSource: feedingDs,
    streakDataSource: streakDs,
    syncQueueDataSource: syncQueueDs,
  );
});

/// Provider for today's feedings state.
final todayFeedingsProvider =
    StateNotifierProvider<TodayFeedingsNotifier, TodayFeedingsState>((ref) {
      final feedingDs = ref.watch(feedingLocalDataSourceProvider);
      final fishDs = ref.watch(fishLocalDataSourceProvider);
      final aquariumDs = ref.watch(aquariumLocalDataSourceProvider);
      final streakDs = ref.watch(streakLocalDataSourceProvider);
      final markFeedingUseCase = ref.watch(markFeedingUseCaseProvider);

      return TodayFeedingsNotifier(
        feedingDataSource: feedingDs,
        fishDataSource: fishDs,
        aquariumDataSource: aquariumDs,
        streakDataSource: streakDs,
        markFeedingUseCase: markFeedingUseCase,
        ref: ref,
      );
    });

/// Provider for grouped feedings by time period.
///
/// Returns a map with keys: 'morning', 'afternoon', 'evening'.
final groupedFeedingsProvider = Provider<Map<String, List<ScheduledFeeding>>>((
  ref,
) {
  final state = ref.watch(todayFeedingsProvider);
  final feedings = state.feedings;

  final grouped = <String, List<ScheduledFeeding>>{
    'morning': [],
    'afternoon': [],
    'evening': [],
  };

  for (final feeding in feedings) {
    grouped[feeding.timePeriod]?.add(feeding);
  }

  return grouped;
});

/// Provider for feedings filtered by aquarium ID.
///
/// Returns list of today's feedings for a specific aquarium.
///
/// Usage:
/// ```dart
/// final feedings = ref.watch(aquariumFeedingsProvider('aquarium-123'));
/// ```
final aquariumFeedingsProvider =
    Provider.family<List<ScheduledFeeding>, String>((ref, aquariumId) {
      final state = ref.watch(todayFeedingsProvider);
      return state.feedings
          .where((feeding) => feeding.aquariumId == aquariumId)
          .toList();
    });

/// Provider for grouped feedings by aquarium ID.
///
/// Returns a map with aquarium IDs as keys and list of feedings as values.
final feedingsGroupedByAquariumProvider =
    Provider<Map<String, List<ScheduledFeeding>>>((ref) {
      final state = ref.watch(todayFeedingsProvider);
      final feedings = state.feedings;

      final grouped = <String, List<ScheduledFeeding>>{};

      for (final feeding in feedings) {
        grouped.putIfAbsent(feeding.aquariumId, () => []).add(feeding);
      }

      return grouped;
    });

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
/// Reads streak from Hive and provides methods to update it.
class StreakNotifier extends StateNotifier<StreakState> {
  StreakNotifier({
    required StreakLocalDataSource streakDataSource,
    required Ref ref,
  }) : _streakDataSource = streakDataSource,
       _ref = ref,
       super(const StreakState()) {
    loadStreak();
  }

  final StreakLocalDataSource _streakDataSource;
  final Ref _ref;

  /// Loads the current streak from Hive.
  Future<void> loadStreak() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = _ref.read(currentUserProvider)?.id ?? 'default_user';
      final streakModel = _streakDataSource.getStreakByUserId(userId);

      if (streakModel != null) {
        state = state.copyWith(
          streak: streakModel.toEntity(),
          isLoading: false,
        );
      } else {
        // No streak exists yet - return default
        state = state.copyWith(
          streak: Streak(
            id: 'streak_$userId',
            userId: userId,
            currentStreak: 0,
            longestStreak: 0,
          ),
          isLoading: false,
        );
      }
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

  /// Resets the current streak to zero.
  ///
  /// Called automatically when a feeding is marked as missed.
  Future<void> resetStreak() async {
    try {
      final userId = _ref.read(currentUserProvider)?.id ?? 'default_user';
      final previousStreak = state.streak?.currentStreak ?? 0;
      final updatedModel = await _streakDataSource.resetStreak(userId);

      if (updatedModel != null) {
        state = state.copyWith(streak: updatedModel.toEntity());
      }

      // Track streak broken if there was an active streak
      if (previousStreak > 0) {
        AnalyticsService.instance.trackStreakBroken(
          previousStreak: previousStreak,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to reset streak: $e');
    }
  }
}

/// Provider for current streak state.
final currentStreakProvider =
    StateNotifierProvider<StreakNotifier, StreakState>((ref) {
      final streakDs = ref.watch(streakLocalDataSourceProvider);

      return StreakNotifier(streakDataSource: streakDs, ref: ref);
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

/// Helper class to hold completed event info for user attribution.
class _CompletedEventInfo {
  const _CompletedEventInfo({
    this.completedBy,
    this.completedByName,
    this.completedByAvatar,
  });

  final String? completedBy;
  final String? completedByName;
  final String? completedByAvatar;
}
