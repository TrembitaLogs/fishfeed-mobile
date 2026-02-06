import 'package:hive_flutter/hive_flutter.dart';

part 'schedule_model.g.dart';

/// Hive model for feeding schedule rules.
///
/// Stores schedule data locally with offline sync support.
/// Each schedule defines when a specific fish should be fed,
/// using interval-based scheduling from an anchor date.
///
/// Use [shouldFeedOn] to check if feeding is required on a specific date.
/// The schedule is computed client-side using [anchorDate] and [intervalDays].
@HiveType(typeId: 24)
class ScheduleModel extends HiveObject {
  ScheduleModel({
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
    this.synced = false,
    this.serverUpdatedAt,
  });

  /// Creates a model from server JSON response.
  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] as String,
      fishId: json['fish_id'] as String,
      aquariumId: json['aquarium_id'] as String,
      time: json['time'] as String,
      intervalDays: json['interval_days'] as int? ?? 1,
      anchorDate: DateTime.parse(json['anchor_date'] as String),
      foodType: json['food_type'] as String,
      portionHint: json['portion_hint'] as String?,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdByUserId: json['created_by_user_id'] as String,
      synced: true,
      serverUpdatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Unique identifier for this schedule.
  @HiveField(0)
  String id;

  /// ID of the fish this schedule applies to.
  @HiveField(1)
  String fishId;

  /// ID of the aquarium where the fish lives.
  @HiveField(2)
  String aquariumId;

  /// Time of day for feeding in "HH:mm" format (e.g., "09:00").
  @HiveField(3)
  String time;

  /// Interval between feedings in days.
  ///
  /// 1 = every day, 2 = every other day, 7 = weekly, etc.
  @HiveField(4)
  int intervalDays;

  /// Reference date for calculating feeding days.
  ///
  /// Used with [intervalDays] to determine which days require feeding.
  /// For example, if anchorDate is Jan 1 and intervalDays is 2,
  /// feeding occurs on Jan 1, 3, 5, 7, etc.
  @HiveField(5)
  DateTime anchorDate;

  /// Type of food for this schedule (e.g., 'flakes', 'pellets').
  @HiveField(6)
  String foodType;

  /// Optional hint about portion size (e.g., '2 pinches', '3 pellets').
  @HiveField(7)
  String? portionHint;

  /// Whether this schedule is currently active.
  @HiveField(8)
  bool active;

  /// When this schedule was created.
  @HiveField(9)
  DateTime createdAt;

  /// When this schedule was last updated locally.
  @HiveField(10)
  DateTime updatedAt;

  /// User ID of who created this schedule.
  @HiveField(11)
  String createdByUserId;

  /// Whether this schedule has been synced to the server.
  @HiveField(12)
  bool synced;

  /// Timestamp from server indicating when it was last updated there.
  @HiveField(13)
  DateTime? serverUpdatedAt;

  /// Parses [time] string into hour and minute components.
  ///
  /// Returns a record with (hour, minute) values.
  /// Throws [FormatException] if time format is invalid.
  ({int hour, int minute}) get timeComponents {
    final parts = time.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid time format: $time');
    }
    return (hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// Checks if feeding should occur on the given [date].
  ///
  /// Uses [anchorDate] as the reference point and [intervalDays]
  /// to determine feeding days. Returns true if the date falls
  /// on a feeding day based on the interval pattern.
  ///
  /// Example:
  /// - anchorDate = Jan 1, intervalDays = 1 → feeds every day
  /// - anchorDate = Jan 1, intervalDays = 2 → feeds Jan 1, 3, 5, ...
  /// - anchorDate = Jan 1, intervalDays = 7 → feeds Jan 1, 8, 15, ...
  bool shouldFeedOn(DateTime date) {
    final daysDiff = _daysBetween(anchorDate, date);
    // Only feed on or after anchor date, and on interval days
    return daysDiff >= 0 && daysDiff % intervalDays == 0;
  }

  /// Calculates the number of days between two dates.
  ///
  /// Normalizes both dates to midnight to ensure accurate day counting.
  int _daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  /// Whether this schedule needs to be synced.
  bool get needsSync =>
      !synced ||
      (serverUpdatedAt != null && updatedAt.isAfter(serverUpdatedAt!));

  /// Converts this model to JSON for API requests.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fish_id': fishId,
      'aquarium_id': aquariumId,
      'time': time,
      'interval_days': intervalDays,
      'anchor_date': anchorDate.toIso8601String(),
      'food_type': foodType,
      'portion_hint': portionHint,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by_user_id': createdByUserId,
    };
  }

  /// Converts this model to JSON for sync API.
  ///
  /// Includes only fields needed for synchronization.
  Map<String, dynamic> toSyncJson() {
    return {
      'id': id,
      'fish_id': fishId,
      'aquarium_id': aquariumId,
      'time': time,
      'interval_days': intervalDays,
      'anchor_date': anchorDate.toIso8601String(),
      'food_type': foodType,
      'portion_hint': portionHint,
      'active': active,
      'created_by_user_id': createdByUserId,
    };
  }

  /// Marks this schedule as modified locally.
  ///
  /// Sets [synced] to false and updates [updatedAt] timestamp.
  void markAsModified() {
    updatedAt = DateTime.now();
    synced = false;
  }

  /// Marks this schedule as synced with server.
  ///
  /// Sets [synced] to true and updates [serverUpdatedAt] timestamp.
  void markAsSynced(DateTime serverTime) {
    serverUpdatedAt = serverTime;
    synced = true;
  }

  /// Creates a copy of this schedule with optional field overrides.
  ScheduleModel copyWith({
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
    bool? synced,
    DateTime? serverUpdatedAt,
  }) {
    return ScheduleModel(
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
      synced: synced ?? this.synced,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
    );
  }

  @override
  String toString() {
    return 'ScheduleModel('
        'id: $id, '
        'fishId: $fishId, '
        'time: $time, '
        'intervalDays: $intervalDays, '
        'active: $active, '
        'synced: $synced'
        ')';
  }
}
