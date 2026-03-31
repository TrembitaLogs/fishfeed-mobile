import 'package:fishfeed/domain/entities/schedule.dart';

/// Repository interface for feeding schedule operations.
abstract interface class ScheduleRepository {
  /// Returns active schedules for a specific fish.
  ///
  /// If [activeOnly] is true, returns only schedules where `active == true`.
  List<Schedule> getSchedulesForFish(String fishId, {bool activeOnly = false});
}
