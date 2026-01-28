import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/domain/entities/calendar_month_data.dart';
import 'package:fishfeed/domain/entities/day_feeding_status.dart';
import 'package:fishfeed/domain/usecases/get_calendar_data_usecase.dart';

/// State for calendar month data.
class CalendarDataState {
  const CalendarDataState({
    this.monthData,
    this.isLoading = false,
    this.error,
  });

  /// The loaded calendar month data.
  final CalendarMonthData? monthData;

  /// Whether data is currently loading.
  final bool isLoading;

  /// Error message if loading failed.
  final String? error;

  /// Whether state has an error.
  bool get hasError => error != null;

  /// Whether data is available.
  bool get hasData => monthData != null;

  CalendarDataState copyWith({
    CalendarMonthData? monthData,
    bool? isLoading,
    String? error,
  }) {
    return CalendarDataState(
      monthData: monthData ?? this.monthData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing calendar month data.
///
/// Loads feeding data for the focused month and provides
/// day status information for calendar display.
class CalendarDataNotifier extends StateNotifier<CalendarDataState> {
  CalendarDataNotifier({
    required GetCalendarDataUseCase getCalendarDataUseCase,
  })  : _getCalendarDataUseCase = getCalendarDataUseCase,
        super(const CalendarDataState());

  final GetCalendarDataUseCase _getCalendarDataUseCase;

  /// Currently loaded month (year * 100 + month).
  int? _loadedMonth;

  /// Loads calendar data for the specified month.
  ///
  /// Will skip loading if the same month is already loaded.
  Future<void> loadMonth(int year, int month) async {
    final monthKey = year * 100 + month;

    // Skip if already loaded
    if (_loadedMonth == monthKey && state.hasData) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await _getCalendarDataUseCase(GetCalendarDataParams(
      year: year,
      month: month,
    ));

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (data) {
        _loadedMonth = monthKey;
        state = state.copyWith(
          monthData: data,
          isLoading: false,
        );
      },
    );
  }

  /// Gets the feeding status for a specific day.
  ///
  /// Returns [DayFeedingStatus.noData] if no data is loaded.
  DayFeedingStatus getDayStatus(DateTime day) {
    return state.monthData?.getDayStatus(day) ?? DayFeedingStatus.noData;
  }

  /// Refreshes data for the currently loaded month.
  Future<void> refresh() async {
    if (_loadedMonth != null) {
      final year = _loadedMonth! ~/ 100;
      final month = _loadedMonth! % 100;
      _loadedMonth = null; // Force reload
      await loadMonth(year, month);
    }
  }
}

/// Provider for the GetCalendarDataUseCase.
final getCalendarDataUseCaseProvider = Provider<GetCalendarDataUseCase>((ref) {
  final feedingDs = ref.watch(feedingLocalDataSourceProvider);
  return GetCalendarDataUseCase(feedingDataSource: feedingDs);
});

/// Provider for calendar data state and notifier.
///
/// Usage:
/// ```dart
/// final calendarData = ref.watch(calendarDataProvider);
/// final status = ref.read(calendarDataProvider.notifier).getDayStatus(day);
/// ```
final calendarDataProvider =
    StateNotifierProvider<CalendarDataNotifier, CalendarDataState>((ref) {
  final useCase = ref.watch(getCalendarDataUseCaseProvider);
  return CalendarDataNotifier(getCalendarDataUseCase: useCase);
});
