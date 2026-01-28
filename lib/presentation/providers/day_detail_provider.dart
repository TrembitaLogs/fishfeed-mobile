import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/domain/entities/day_feeding_status.dart';
import 'package:fishfeed/domain/entities/feeding_status.dart';
import 'package:fishfeed/domain/entities/scheduled_feeding.dart';

/// State for day detail bottom sheet.
class DayDetailState {
  const DayDetailState({
    required this.selectedDate,
    this.feedings = const [],
    this.isLoading = false,
    this.error,
  });

  /// The selected date to show details for.
  final DateTime selectedDate;

  /// List of feedings for the selected date.
  final List<ScheduledFeeding> feedings;

  /// Whether data is currently loading.
  final bool isLoading;

  /// Error message if loading failed.
  final String? error;

  /// Whether state has an error.
  bool get hasError => error != null;

  /// Whether feedings list is empty (after loading).
  bool get isEmpty => feedings.isEmpty && !isLoading && !hasError;

  /// Count of completed feedings.
  int get completedCount =>
      feedings.where((f) => f.status == FeedingStatus.fed).length;

  /// Count of missed feedings.
  int get missedCount =>
      feedings.where((f) => f.status == FeedingStatus.missed).length;

  /// Count of pending feedings.
  int get pendingCount =>
      feedings.where((f) => f.status == FeedingStatus.pending).length;

  /// Overall day feeding status based on feedings.
  DayFeedingStatus get dayStatus {
    if (feedings.isEmpty) {
      return DayFeedingStatus.noData;
    }

    final total = feedings.length;
    final fed = completedCount;
    final missed = missedCount;

    if (fed == total) {
      return DayFeedingStatus.allFed;
    } else if (missed == total) {
      return DayFeedingStatus.allMissed;
    } else {
      return DayFeedingStatus.partial;
    }
  }

  DayDetailState copyWith({
    DateTime? selectedDate,
    List<ScheduledFeeding>? feedings,
    bool? isLoading,
    String? error,
  }) {
    return DayDetailState(
      selectedDate: selectedDate ?? this.selectedDate,
      feedings: feedings ?? this.feedings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing day detail state.
///
/// Loads feedings for a specific date and calculates day status.
class DayDetailNotifier extends StateNotifier<DayDetailState> {
  DayDetailNotifier({
    required FeedingLocalDataSource feedingDataSource,
    required DateTime initialDate,
  })  : _feedingDataSource = feedingDataSource,
        super(DayDetailState(selectedDate: initialDate)) {
    loadFeedings();
  }

  final FeedingLocalDataSource _feedingDataSource;

  /// Loads feedings for the selected date.
  Future<void> loadFeedings() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final date = state.selectedDate;
      final today = DateTime(date.year, date.month, date.day);
      final now = DateTime.now();

      // Get completed feeding events from Hive
      final completedEvents = _feedingDataSource.getFeedingEventsByDate(today);
      final completedIds =
          completedEvents.map((e) => e.localId ?? e.id).toSet();

      // Generate schedule for the day
      final feedings = _generateDaySchedule(today, completedIds, now);

      // Sort by scheduled time
      feedings.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

      state = state.copyWith(
        feedings: feedings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load feedings: $e',
      );
    }
  }

  /// Changes the selected date and reloads feedings.
  Future<void> selectDate(DateTime date) async {
    state = state.copyWith(selectedDate: date);
    await loadFeedings();
  }

  /// Generates feeding schedule for a specific day.
  ///
  /// In production, this would be based on user's aquariums and fish.
  /// Currently uses mock data matching TodayFeedingsNotifier.
  List<ScheduledFeeding> _generateDaySchedule(
    DateTime day,
    Set<String> completedIds,
    DateTime now,
  ) {
    // Only generate schedule for today and past days
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(day.year, day.month, day.day);

    // Future days have no data
    if (selectedDay.isAfter(today)) {
      return [];
    }

    final mockSchedule = [
      _createScheduledFeeding(
        id: 'feed_${day.year}${day.month}${day.day}_1',
        time: day.add(const Duration(hours: 8)),
        aquariumId: 'aq1',
        aquariumName: 'Living Room Tank',
        speciesName: 'Guppy',
        foodType: 'Flakes',
        portionGrams: 0.5,
        completedIds: completedIds,
        now: now,
        isHistorical: selectedDay.isBefore(today),
      ),
      _createScheduledFeeding(
        id: 'feed_${day.year}${day.month}${day.day}_2',
        time: day.add(const Duration(hours: 12)),
        aquariumId: 'aq1',
        aquariumName: 'Living Room Tank',
        speciesName: 'Betta',
        foodType: 'Pellets',
        portionGrams: 0.3,
        completedIds: completedIds,
        now: now,
        isHistorical: selectedDay.isBefore(today),
      ),
      _createScheduledFeeding(
        id: 'feed_${day.year}${day.month}${day.day}_3',
        time: day.add(const Duration(hours: 18)),
        aquariumId: 'aq2',
        aquariumName: 'Bedroom Aquarium',
        speciesName: 'Goldfish',
        foodType: 'Flakes',
        portionGrams: 1.0,
        completedIds: completedIds,
        now: now,
        isHistorical: selectedDay.isBefore(today),
      ),
      _createScheduledFeeding(
        id: 'feed_${day.year}${day.month}${day.day}_4',
        time: day.add(const Duration(hours: 20)),
        aquariumId: 'aq1',
        aquariumName: 'Living Room Tank',
        speciesName: 'Guppy',
        foodType: 'Flakes',
        portionGrams: 0.5,
        completedIds: completedIds,
        now: now,
        isHistorical: selectedDay.isBefore(today),
      ),
    ];

    return mockSchedule;
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
    required Set<String> completedIds,
    required DateTime now,
    required bool isHistorical,
  }) {
    FeedingStatus status;
    DateTime? completedAt;

    if (completedIds.contains(id)) {
      status = FeedingStatus.fed;
      completedAt = time;
    } else if (isHistorical || time.isBefore(now)) {
      // Historical days or past time = missed
      status = FeedingStatus.missed;
    } else {
      status = FeedingStatus.pending;
    }

    return ScheduledFeeding(
      id: id,
      scheduledTime: time,
      aquariumId: aquariumId,
      aquariumName: aquariumName,
      speciesName: speciesName,
      status: status,
      foodType: foodType,
      portionGrams: portionGrams,
      completedAt: completedAt,
    );
  }

  /// Refreshes feedings for the current date.
  Future<void> refresh() async {
    await loadFeedings();
  }
}

/// Provider family for day detail state.
///
/// Creates a new notifier for each selected date.
///
/// Usage:
/// ```dart
/// final state = ref.watch(dayDetailProvider(selectedDate));
/// ```
final dayDetailProvider = StateNotifierProvider.autoDispose
    .family<DayDetailNotifier, DayDetailState, DateTime>((ref, date) {
  final feedingDs = ref.watch(feedingLocalDataSourceProvider);

  return DayDetailNotifier(
    feedingDataSource: feedingDs,
    initialDate: date,
  );
});
