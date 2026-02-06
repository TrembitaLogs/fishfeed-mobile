import 'package:fishfeed/data/datasources/local/feeding_log_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';

/// Maximum number of days allowed for date range queries.
///
/// Server enforces a 366-day limit on feeding-logs endpoint.
const int maxDateRangeDays = 366;

/// Generates computed [ComputedFeedingEvent]s from schedules and logs.
///
/// This service computes feeding events on-the-fly by:
/// 1. Getting active schedules for the requested aquarium
/// 2. Getting feeding logs for the date range
/// 3. For each schedule, iterating through each day in the range
/// 4. Checking if the schedule should feed on that day (shouldFeedOn)
/// 5. Determining status based on existing logs
///
/// Uses O(1) lookup map for logs to ensure efficient status determination.
///
/// Example:
/// ```dart
/// final generator = FeedingEventGenerator(
///   scheduleLocalDs: scheduleDs,
///   feedingLogLocalDs: logDs,
/// );
/// final events = generator.generateEvents(
///   aquariumId: 'aquarium-123',
///   from: DateTime(2025, 1, 1),
///   to: DateTime(2025, 1, 7),
/// );
/// ```
class FeedingEventGenerator {
  FeedingEventGenerator({
    required ScheduleLocalDataSource scheduleLocalDs,
    required FeedingLogLocalDataSource feedingLogLocalDs,
    FishLocalDataSource? fishLocalDs,
  }) : _scheduleLocalDs = scheduleLocalDs,
       _feedingLogLocalDs = feedingLogLocalDs,
       _fishLocalDs = fishLocalDs;

  final ScheduleLocalDataSource _scheduleLocalDs;
  final FeedingLogLocalDataSource _feedingLogLocalDs;
  final FishLocalDataSource? _fishLocalDs;

  /// Generates feeding events for an aquarium within a date range.
  ///
  /// [aquariumId] - The ID of the aquarium.
  /// [from] - Start date (inclusive).
  /// [to] - End date (inclusive). Will be clamped to [from] + 366 days max.
  /// [fishNameResolver] - Optional function to resolve fish names from IDs.
  /// [aquariumNameResolver] - Optional function to resolve aquarium names.
  /// [avatarResolver] - Optional function to resolve user avatar URLs.
  ///
  /// Returns list of [ComputedFeedingEvent] sorted by scheduledFor time.
  List<ComputedFeedingEvent> generateEvents({
    required String aquariumId,
    required DateTime from,
    required DateTime to,
    String? Function(String fishId)? fishNameResolver,
    int Function(String fishId)? fishQuantityResolver,
    String? Function(String aquariumId)? aquariumNameResolver,
    String? Function(String userId)? avatarResolver,
  }) {
    // Clamp date range to 366 days max (server limit)
    final clampedTo = _clampDateRange(from, to);

    // Get active schedules for this aquarium
    var schedules = _scheduleLocalDs.getActiveByAquariumId(aquariumId);
    if (schedules.isEmpty) {
      return [];
    }

    // Filter out orphan schedules (where fish no longer exists)
    // This is a defensive check in case backend didn't cascade delete
    if (_fishLocalDs != null) {
      schedules = schedules.where((schedule) {
        final fish = _fishLocalDs.getFishById(schedule.fishId);
        return fish != null && fish.deletedAt == null;
      }).toList();

      if (schedules.isEmpty) {
        return [];
      }
    }

    // Get logs for the date range
    final logs = _feedingLogLocalDs.getByAquariumIdAndDateRange(
      aquariumId,
      from,
      clampedTo,
    );

    // Build O(1) lookup map: '$scheduleId|$YYYY-MM-DD' -> FeedingLogModel
    final logLookup = _feedingLogLocalDs.buildLookupMap(logs);

    // Generate events
    final events = <ComputedFeedingEvent>[];
    final now = DateTime.now();

    for (final schedule in schedules) {
      // Iterate through each day in range
      var currentDate = DateTime(from.year, from.month, from.day);
      final endDate = DateTime(clampedTo.year, clampedTo.month, clampedTo.day);

      while (!currentDate.isAfter(endDate)) {
        // Check if this schedule should feed on this date
        if (schedule.shouldFeedOn(currentDate)) {
          final event = _createEvent(
            schedule: schedule,
            date: currentDate,
            logLookup: logLookup,
            now: now,
            fishNameResolver: fishNameResolver,
            fishQuantityResolver: fishQuantityResolver,
            aquariumNameResolver: aquariumNameResolver,
            avatarResolver: avatarResolver,
          );
          events.add(event);
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }
    }

    // Sort by scheduledFor time
    events.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));

    return events;
  }

  /// Generates events for today only (convenience method).
  ///
  /// [aquariumId] - The ID of the aquarium.
  /// Returns events scheduled for today.
  List<ComputedFeedingEvent> generateTodayEvents({
    required String aquariumId,
    String? Function(String fishId)? fishNameResolver,
    int Function(String fishId)? fishQuantityResolver,
    String? Function(String aquariumId)? aquariumNameResolver,
    String? Function(String userId)? avatarResolver,
  }) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return generateEvents(
      aquariumId: aquariumId,
      from: startOfDay,
      to: endOfDay,
      fishNameResolver: fishNameResolver,
      fishQuantityResolver: fishQuantityResolver,
      aquariumNameResolver: aquariumNameResolver,
      avatarResolver: avatarResolver,
    );
  }

  /// Generates events for all aquariums for today.
  ///
  /// [aquariumIds] - List of aquarium IDs to generate events for.
  /// Returns map of aquariumId -> list of events.
  Map<String, List<ComputedFeedingEvent>> generateTodayEventsForAllAquariums({
    required List<String> aquariumIds,
    String? Function(String fishId)? fishNameResolver,
    int Function(String fishId)? fishQuantityResolver,
    String? Function(String aquariumId)? aquariumNameResolver,
    String? Function(String userId)? avatarResolver,
  }) {
    final result = <String, List<ComputedFeedingEvent>>{};

    for (final aquariumId in aquariumIds) {
      result[aquariumId] = generateTodayEvents(
        aquariumId: aquariumId,
        fishNameResolver: fishNameResolver,
        fishQuantityResolver: fishQuantityResolver,
        aquariumNameResolver: aquariumNameResolver,
        avatarResolver: avatarResolver,
      );
    }

    return result;
  }

  /// Clamps the date range to not exceed [maxDateRangeDays].
  DateTime _clampDateRange(DateTime from, DateTime to) {
    final maxTo = from.add(const Duration(days: maxDateRangeDays));
    if (to.isAfter(maxTo)) {
      return maxTo;
    }
    return to;
  }

  /// Creates a single [ComputedFeedingEvent] for a schedule and date.
  ComputedFeedingEvent _createEvent({
    required ScheduleModel schedule,
    required DateTime date,
    required Map<String, FeedingLogModel> logLookup,
    required DateTime now,
    String? Function(String fishId)? fishNameResolver,
    int Function(String fishId)? fishQuantityResolver,
    String? Function(String aquariumId)? aquariumNameResolver,
    String? Function(String userId)? avatarResolver,
  }) {
    // Parse schedule time
    final timeComponents = schedule.timeComponents;

    // Build scheduledFor datetime
    final scheduledFor = DateTime(
      date.year,
      date.month,
      date.day,
      timeComponents.hour,
      timeComponents.minute,
    );

    // Build lookup key: '$scheduleId|$YYYY-MM-DD'
    final dateKey =
        '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final lookupKey = '${schedule.id}|$dateKey';

    // Get log if exists (O(1) lookup)
    final log = logLookup[lookupKey];

    // Determine status
    final status = _determineStatus(scheduledFor, log, now);

    // Resolve display names and quantity
    final fishName = fishNameResolver?.call(schedule.fishId);
    final fishQuantity = fishQuantityResolver?.call(schedule.fishId) ?? 1;
    final aquariumName = aquariumNameResolver?.call(schedule.aquariumId);
    final avatarUrl = log?.actedByUserId != null
        ? avatarResolver?.call(log!.actedByUserId)
        : null;

    return ComputedFeedingEvent(
      scheduleId: schedule.id,
      fishId: schedule.fishId,
      aquariumId: schedule.aquariumId,
      scheduledFor: scheduledFor,
      time: schedule.time,
      foodType: schedule.foodType,
      portionHint: schedule.portionHint,
      status: status,
      log: log,
      fishName: fishName,
      aquariumName: aquariumName,
      avatarUrl: avatarUrl,
      fishQuantity: fishQuantity,
    );
  }

  /// Determines the [EventStatus] based on schedule time and log.
  EventStatus _determineStatus(
    DateTime scheduledFor,
    FeedingLogModel? log,
    DateTime now,
  ) {
    // If log exists, status is based on action
    if (log != null) {
      if (log.isFed) {
        return EventStatus.fed;
      }
      if (log.isSkipped) {
        return EventStatus.skipped;
      }
    }

    // No log - check if time has passed
    if (scheduledFor.isBefore(now)) {
      return EventStatus.overdue;
    }

    return EventStatus.pending;
  }
}
