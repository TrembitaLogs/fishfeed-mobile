import 'package:hive_flutter/hive_flutter.dart';

part 'feeding_schedule_model.g.dart';

/// Hive model for feeding schedule.
///
/// Stores feeding schedule data locally with offline support.
/// Enables offline editing of feeding times and sync when online.
@HiveType(typeId: 23)
class FeedingScheduleModel extends HiveObject {
  FeedingScheduleModel({
    required this.id,
    required this.aquariumId,
    this.timesPerDay = 2,
    this.scheduledTimes = const [],
    this.foodType = 'flakes',
    this.portionHint,
    this.synced = false,
    this.updatedAt,
    this.serverUpdatedAt,
  });

  /// Creates a model from server JSON response.
  factory FeedingScheduleModel.fromJson(Map<String, dynamic> json) {
    return FeedingScheduleModel(
      id: json['id'] as String,
      aquariumId: json['aquarium_id'] as String,
      timesPerDay: json['times_per_day'] as int? ?? 2,
      scheduledTimes:
          (json['scheduled_times'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      foodType: json['food_type'] as String? ?? 'flakes',
      portionHint: json['portion_hint'] as String?,
      synced: true,
      serverUpdatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Unique identifier for this schedule.
  @HiveField(0)
  String id;

  /// ID of the aquarium this schedule belongs to.
  @HiveField(1)
  String aquariumId;

  /// Number of feedings per day.
  @HiveField(2)
  int timesPerDay;

  /// List of scheduled feeding times in "HH:mm" format.
  @HiveField(3)
  List<String> scheduledTimes;

  /// Type of food for this schedule (e.g., 'flakes', 'pellets').
  @HiveField(4)
  String foodType;

  /// Optional hint about portion size.
  @HiveField(5)
  String? portionHint;

  /// Whether this schedule has been synced to the server.
  @HiveField(6, defaultValue: false)
  bool synced;

  /// When this record was last updated locally.
  @HiveField(7)
  DateTime? updatedAt;

  /// Timestamp from server indicating when it was last updated there.
  @HiveField(8)
  DateTime? serverUpdatedAt;

  /// Whether this schedule needs to be synced.
  bool get needsSync =>
      !synced ||
      (updatedAt != null &&
          serverUpdatedAt != null &&
          updatedAt!.isAfter(serverUpdatedAt!));

  /// Converts this model to JSON for sync.
  Map<String, dynamic> toSyncJson() {
    return {
      'id': id,
      'aquarium_id': aquariumId,
      'times_per_day': timesPerDay,
      'scheduled_times': scheduledTimes,
      'food_type': foodType,
      'portion_hint': portionHint,
    };
  }

  /// Marks this schedule as modified locally.
  void markAsModified() {
    updatedAt = DateTime.now();
    synced = false;
  }

  /// Marks this schedule as synced with server.
  void markAsSynced(DateTime serverTime) {
    serverUpdatedAt = serverTime;
    synced = true;
  }
}
