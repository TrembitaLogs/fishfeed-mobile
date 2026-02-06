import 'package:hive_flutter/hive_flutter.dart';

part 'feeding_log_model.g.dart';

/// Hive model for feeding log entries.
///
/// Records the actual feeding events (facts) when a fish is fed or skipped.
/// Unlike computed FeedingEvents, these are persisted and synced with the server.
///
/// The [scheduledFor] field stores the local time when feeding was scheduled,
/// while [actedAt] stores the UTC timestamp when the action was taken.
@HiveType(typeId: 25)
class FeedingLogModel extends HiveObject {
  FeedingLogModel({
    required this.id,
    required this.scheduleId,
    required this.fishId,
    required this.aquariumId,
    required this.scheduledFor,
    required this.action,
    required this.actedAt,
    required this.actedByUserId,
    this.actedByUserName,
    required this.deviceId,
    this.notes,
    required this.createdAt,
    this.synced = false,
    this.serverUpdatedAt,
  });

  /// Creates a model from server JSON response.
  factory FeedingLogModel.fromJson(Map<String, dynamic> json) {
    return FeedingLogModel(
      id: json['id'] as String,
      scheduleId: json['schedule_id'] as String,
      fishId: json['fish_id'] as String,
      aquariumId: json['aquarium_id'] as String,
      scheduledFor: DateTime.parse(json['scheduled_for'] as String),
      action: json['action'] as String,
      actedAt: DateTime.parse(json['acted_at'] as String),
      actedByUserId: json['acted_by_user_id'] as String,
      actedByUserName: json['acted_by_user_name'] as String?,
      deviceId: json['device_id'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      synced: true,
      serverUpdatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Unique identifier for this feeding log entry.
  @HiveField(0)
  String id;

  /// ID of the schedule this log is associated with.
  @HiveField(1)
  String scheduleId;

  /// ID of the fish that was fed.
  @HiveField(2)
  String fishId;

  /// ID of the aquarium where the fish lives.
  @HiveField(3)
  String aquariumId;

  /// The scheduled time for this feeding (local time).
  ///
  /// This is the time the feeding was supposed to happen according to the schedule.
  @HiveField(4)
  DateTime scheduledFor;

  /// The action taken: "fed" or "skipped".
  @HiveField(5)
  String action;

  /// When the action was taken (UTC).
  ///
  /// This is the actual timestamp when the user marked the feeding as done/skipped.
  @HiveField(6)
  DateTime actedAt;

  /// User ID of who performed the action.
  @HiveField(7)
  String actedByUserId;

  /// Display name of who performed the action.
  ///
  /// Used for UI display in family mode (e.g., "Fed by Mom").
  @HiveField(8)
  String? actedByUserName;

  /// Device ID that created this log entry.
  ///
  /// Used for conflict detection when the same feeding is logged
  /// from multiple devices.
  @HiveField(9)
  String deviceId;

  /// Optional notes about the feeding.
  @HiveField(10)
  String? notes;

  /// When this log entry was created.
  @HiveField(11)
  DateTime createdAt;

  /// Whether this log has been synced to the server.
  @HiveField(12)
  bool synced;

  /// Timestamp from server indicating when it was last updated there.
  @HiveField(13)
  DateTime? serverUpdatedAt;

  /// Whether this feeding was marked as "fed".
  bool get isFed => action == 'fed';

  /// Whether this feeding was marked as "skipped".
  bool get isSkipped => action == 'skipped';

  /// Converts this model to JSON for API requests.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schedule_id': scheduleId,
      'fish_id': fishId,
      'aquarium_id': aquariumId,
      'scheduled_for': scheduledFor.toIso8601String(),
      'action': action,
      'acted_at': actedAt.toUtc().toIso8601String(),
      'acted_by_user_id': actedByUserId,
      'acted_by_user_name': actedByUserName,
      'device_id': deviceId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converts this model to JSON for sync API.
  ///
  /// Includes only fields needed for synchronization.
  Map<String, dynamic> toSyncJson() {
    return {
      'id': id,
      'schedule_id': scheduleId,
      'fish_id': fishId,
      'aquarium_id': aquariumId,
      'scheduled_for': scheduledFor.toIso8601String(),
      'action': action,
      'acted_at': actedAt.toUtc().toIso8601String(),
      'device_id': deviceId,
      'notes': notes,
    };
  }

  /// Creates a copy of this log with optional field overrides.
  FeedingLogModel copyWith({
    String? id,
    String? scheduleId,
    String? fishId,
    String? aquariumId,
    DateTime? scheduledFor,
    String? action,
    DateTime? actedAt,
    String? actedByUserId,
    String? actedByUserName,
    String? deviceId,
    String? notes,
    DateTime? createdAt,
    bool? synced,
    DateTime? serverUpdatedAt,
  }) {
    return FeedingLogModel(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      fishId: fishId ?? this.fishId,
      aquariumId: aquariumId ?? this.aquariumId,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      action: action ?? this.action,
      actedAt: actedAt ?? this.actedAt,
      actedByUserId: actedByUserId ?? this.actedByUserId,
      actedByUserName: actedByUserName ?? this.actedByUserName,
      deviceId: deviceId ?? this.deviceId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
    );
  }

  @override
  String toString() {
    return 'FeedingLogModel('
        'id: $id, '
        'scheduleId: $scheduleId, '
        'fishId: $fishId, '
        'action: $action, '
        'scheduledFor: $scheduledFor, '
        'synced: $synced'
        ')';
  }
}
