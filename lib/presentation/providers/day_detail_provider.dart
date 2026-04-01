import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/di/datasource_providers.dart';
import 'package:fishfeed/domain/entities/day_feeding_status.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/domain/services/feeding_event_generator.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';

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

  /// List of computed feedings for the selected date.
  final List<ComputedFeedingEvent> feedings;

  /// Whether data is currently loading.
  final bool isLoading;

  /// Error message if loading failed.
  final String? error;

  /// Whether state has an error.
  bool get hasError => error != null;

  /// Whether feedings list is empty (after loading).
  bool get isEmpty => feedings.isEmpty && !isLoading && !hasError;

  /// Count of completed feedings (fed).
  int get completedCount =>
      feedings.where((f) => f.status == EventStatus.fed).length;

  /// Count of missed feedings (skipped or overdue).
  int get missedCount => feedings
      .where(
        (f) =>
            f.status == EventStatus.skipped || f.status == EventStatus.overdue,
      )
      .length;

  /// Count of pending feedings.
  int get pendingCount =>
      feedings.where((f) => f.status == EventStatus.pending).length;

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
    List<ComputedFeedingEvent>? feedings,
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
/// Loads feedings for a specific date using FeedingEventGenerator.
class DayDetailNotifier extends StateNotifier<DayDetailState> {
  DayDetailNotifier({
    required FeedingEventGenerator eventGenerator,
    required List<String> aquariumIds,
    required String? Function(String fishId) fishNameResolver,
    required String? Function(String aquariumId) aquariumNameResolver,
    required DateTime initialDate,
  }) : _eventGenerator = eventGenerator,
       _aquariumIds = aquariumIds,
       _fishNameResolver = fishNameResolver,
       _aquariumNameResolver = aquariumNameResolver,
       super(DayDetailState(selectedDate: initialDate)) {
    loadFeedings();
  }

  final FeedingEventGenerator _eventGenerator;
  final List<String> _aquariumIds;
  final String? Function(String fishId) _fishNameResolver;
  final String? Function(String aquariumId) _aquariumNameResolver;

  /// Loads feedings for the selected date.
  Future<void> loadFeedings() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final date = state.selectedDate;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Generate events for all aquariums for this date
      final allEvents = <ComputedFeedingEvent>[];

      for (final aquariumId in _aquariumIds) {
        final events = _eventGenerator.generateEvents(
          aquariumId: aquariumId,
          from: startOfDay,
          to: endOfDay,
          fishNameResolver: _fishNameResolver,
          aquariumNameResolver: _aquariumNameResolver,
        );
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

  /// Changes the selected date and reloads feedings.
  Future<void> selectDate(DateTime date) async {
    state = state.copyWith(selectedDate: date);
    await loadFeedings();
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
      final eventGenerator = ref.watch(feedingEventGeneratorProvider);
      final aquariums = ref.watch(userAquariumsProvider.select((s) => s.aquariums));
      final aquariumIds = aquariums.map((a) => a.id).toList();

      // Build fish name lookup from local data source
      final fishDs = ref.watch(fishLocalDataSourceProvider);
      final allFish = fishDs.getAllFish();
      final fishNameMap = <String, String>{};
      for (final fish in allFish) {
        fishNameMap[fish.id] = fish.name ?? 'Fish';
      }

      String? fishNameResolver(String fishId) {
        return fishNameMap[fishId];
      }

      String? aquariumNameResolver(String aquariumId) {
        final aquarium = aquariums
            .where((a) => a.id == aquariumId)
            .firstOrNull;
        return aquarium?.name;
      }

      return DayDetailNotifier(
        eventGenerator: eventGenerator,
        aquariumIds: aquariumIds,
        fishNameResolver: fishNameResolver,
        aquariumNameResolver: aquariumNameResolver,
        initialDate: date,
      );
    });
