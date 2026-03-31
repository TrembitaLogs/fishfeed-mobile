import 'package:equatable/equatable.dart';

/// Domain entity representing a feeding schedule rule.
///
/// Defines when a specific fish should be fed using interval-based
/// scheduling from an anchor date.
class Schedule extends Equatable {
  const Schedule({
    required this.id,
    required this.fishId,
    required this.aquariumId,
    required this.time,
    required this.intervalDays,
    required this.anchorDate,
    required this.foodType,
    this.portionHint,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByUserId,
  });

  /// Unique identifier for this schedule.
  final String id;

  /// ID of the fish this schedule applies to.
  final String fishId;

  /// ID of the aquarium where the fish lives.
  final String aquariumId;

  /// Time of day for feeding in "HH:mm" format (e.g., "09:00").
  final String time;

  /// Interval between feedings in days.
  ///
  /// 1 = every day, 2 = every other day, 7 = weekly, etc.
  final int intervalDays;

  /// Reference date for calculating feeding days.
  final DateTime anchorDate;

  /// Type of food for this schedule (e.g., 'flakes', 'pellets').
  final String foodType;

  /// Optional hint about portion size (e.g., '2 pinches', '3 pellets').
  final String? portionHint;

  /// Whether this schedule is currently active.
  final bool active;

  /// When this schedule was created.
  final DateTime createdAt;

  /// When this schedule was last updated.
  final DateTime updatedAt;

  /// User ID of who created this schedule.
  final String createdByUserId;

  /// Parses [time] string into hour and minute components.
  ({int hour, int minute}) get timeComponents {
    final parts = time.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid time format: $time');
    }
    return (hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// Checks if feeding should occur on the given [date].
  bool shouldFeedOn(DateTime date) {
    final daysDiff = _daysBetween(anchorDate, date);
    return daysDiff >= 0 && daysDiff % intervalDays == 0;
  }

  int _daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  Schedule copyWith({
    String? id,
    String? fishId,
    String? aquariumId,
    String? time,
    int? intervalDays,
    DateTime? anchorDate,
    String? foodType,
    String? portionHint,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByUserId,
  }) {
    return Schedule(
      id: id ?? this.id,
      fishId: fishId ?? this.fishId,
      aquariumId: aquariumId ?? this.aquariumId,
      time: time ?? this.time,
      intervalDays: intervalDays ?? this.intervalDays,
      anchorDate: anchorDate ?? this.anchorDate,
      foodType: foodType ?? this.foodType,
      portionHint: portionHint ?? this.portionHint,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByUserId: createdByUserId ?? this.createdByUserId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fishId,
    aquariumId,
    time,
    intervalDays,
    anchorDate,
    foodType,
    portionHint,
    active,
    createdAt,
    updatedAt,
    createdByUserId,
  ];
}
