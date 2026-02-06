import 'package:equatable/equatable.dart';

import 'package:fishfeed/data/models/feeding_log_model.dart';

// ============================================================================
// Legacy FeedingEvent (for Family Sync API compatibility)
// ============================================================================

/// Lightweight feeding event entity for remote API responses.
///
/// Used by [FamilySyncService] to receive and process feeding events
/// from family members via polling. This is separate from [ComputedFeedingEvent]
/// which is computed locally from schedules and logs.
///
/// Example:
/// ```dart
/// final event = FeedingEvent(
///   id: 'log-123',
///   feedingTime: DateTime.now(),
///   completedBy: 'user-456',
///   completedByName: 'John',
/// );
/// ```
class FeedingEvent extends Equatable {
  const FeedingEvent({
    required this.id,
    required this.feedingTime,
    this.localId,
    this.completedBy,
    this.completedByName,
    this.completedByAvatar,
    this.scheduleId,
    this.aquariumId,
  });

  /// Server-assigned unique identifier.
  final String id;

  /// When the feeding was completed.
  final DateTime feedingTime;

  /// Optional local identifier (for offline-created events).
  final String? localId;

  /// ID of the user who completed the feeding.
  final String? completedBy;

  /// Display name of the user who completed the feeding.
  final String? completedByName;

  /// Avatar URL of the user who completed the feeding.
  final String? completedByAvatar;

  /// ID of the schedule this feeding was for.
  final String? scheduleId;

  /// ID of the aquarium.
  final String? aquariumId;

  /// Creates from a FeedingLogModel.
  factory FeedingEvent.fromLog(FeedingLogModel log) {
    return FeedingEvent(
      id: log.id,
      feedingTime: log.actedAt,
      localId: log.id,
      completedBy: log.actedByUserId,
      completedByName: log.actedByUserName,
      scheduleId: log.scheduleId,
      aquariumId: log.aquariumId,
    );
  }

  /// Creates FeedingEvent from JSON (API response).
  factory FeedingEvent.fromJson(Map<String, dynamic> json) {
    return FeedingEvent(
      id: json['id'] as String,
      feedingTime: DateTime.parse(json['acted_at'] as String),
      localId: json['local_id'] as String?,
      completedBy: json['acted_by_user_id'] as String?,
      completedByName: json['acted_by_user_name'] as String?,
      completedByAvatar: json['acted_by_user_avatar'] as String?,
      scheduleId: json['schedule_id'] as String?,
      aquariumId: json['aquarium_id'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    feedingTime,
    localId,
    completedBy,
    completedByName,
    completedByAvatar,
    scheduleId,
    aquariumId,
  ];
}

// ============================================================================
// NEW ARCHITECTURE: Computed FeedingEvent (Task 25)
// ============================================================================

/// Status of a computed feeding event.
///
/// Determined by FeedingEventGenerator based on schedule and logs.
enum EventStatus {
  /// Feeding is scheduled for the future, not yet acted upon.
  pending,

  /// Feeding was completed (marked as fed).
  fed,

  /// Feeding was intentionally skipped.
  skipped,

  /// Scheduled time has passed without any action.
  overdue,
}

/// Computed feeding event generated from Schedule + FeedingLog.
///
/// This is an in-memory computed entity, NOT stored in Hive.
/// Generated on-the-fly by [FeedingEventGenerator] for calendar/list display.
///
/// Unlike the legacy [FeedingEvent], this class:
/// - Is computed from [ScheduleModel] and [FeedingLogModel]
/// - Has a [status] determined by schedule time and existing logs
/// - Contains denormalized UI fields (fishName, aquariumName, avatarUrl)
///
/// Example:
/// ```dart
/// final event = ComputedFeedingEvent(
///   scheduleId: 'schedule-123',
///   fishId: 'fish-456',
///   aquariumId: 'aquarium-789',
///   scheduledFor: DateTime(2025, 1, 15, 9, 0),
///   time: '09:00',
///   foodType: 'flakes',
///   status: EventStatus.pending,
/// );
/// ```
class ComputedFeedingEvent extends Equatable {
  const ComputedFeedingEvent({
    required this.scheduleId,
    required this.fishId,
    required this.aquariumId,
    required this.scheduledFor,
    required this.time,
    required this.foodType,
    this.portionHint,
    required this.status,
    this.log,
    this.fishName,
    this.aquariumName,
    this.avatarUrl,
    this.fishQuantity = 1,
  });

  /// ID of the schedule this event was generated from.
  final String scheduleId;

  /// ID of the fish to be fed.
  final String fishId;

  /// ID of the aquarium (convenience for UI grouping).
  final String aquariumId;

  /// The scheduled date and time for this feeding.
  ///
  /// Combines the schedule's date (from iteration) with schedule's time.
  final DateTime scheduledFor;

  /// Time of day in "HH:mm" format (e.g., "09:00").
  ///
  /// Preserved from schedule for display purposes.
  final String time;

  /// Type of food for this feeding (e.g., 'flakes', 'pellets').
  final String foodType;

  /// Optional hint about portion size (e.g., '2 pinches').
  final String? portionHint;

  /// Current status of this feeding event.
  ///
  /// Determined by [FeedingEventGenerator] based on:
  /// - If log exists with action="fed" → [EventStatus.fed]
  /// - If log exists with action="skipped" → [EventStatus.skipped]
  /// - If scheduledFor is in the past and no log → [EventStatus.overdue]
  /// - Otherwise → [EventStatus.pending]
  final EventStatus status;

  /// The feeding log associated with this event, if any.
  ///
  /// Present when status is [EventStatus.fed] or [EventStatus.skipped].
  /// Null when status is [EventStatus.pending] or [EventStatus.overdue].
  final FeedingLogModel? log;

  /// Display name of the fish (denormalized from Fish cache).
  final String? fishName;

  /// Display name of the aquarium (denormalized from Aquarium cache).
  final String? aquariumName;

  /// Avatar URL of who completed the feeding (from Family members cache).
  ///
  /// Present only when [log] exists and has actedByUserId.
  final String? avatarUrl;

  /// Number of fish of this type (from Fish.quantity).
  ///
  /// Defaults to 1 when not resolved. Used for display in feeding cards.
  final int fishQuantity;

  /// Whether this event has been acted upon (fed or skipped).
  bool get isCompleted =>
      status == EventStatus.fed || status == EventStatus.skipped;

  /// Whether this event needs attention (pending or overdue).
  bool get needsAttention =>
      status == EventStatus.pending || status == EventStatus.overdue;

  /// Creates a copy with updated fields.
  ComputedFeedingEvent copyWith({
    String? scheduleId,
    String? fishId,
    String? aquariumId,
    DateTime? scheduledFor,
    String? time,
    String? foodType,
    String? portionHint,
    EventStatus? status,
    FeedingLogModel? log,
    String? fishName,
    String? aquariumName,
    String? avatarUrl,
    int? fishQuantity,
  }) {
    return ComputedFeedingEvent(
      scheduleId: scheduleId ?? this.scheduleId,
      fishId: fishId ?? this.fishId,
      aquariumId: aquariumId ?? this.aquariumId,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      time: time ?? this.time,
      foodType: foodType ?? this.foodType,
      portionHint: portionHint ?? this.portionHint,
      status: status ?? this.status,
      log: log ?? this.log,
      fishName: fishName ?? this.fishName,
      aquariumName: aquariumName ?? this.aquariumName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fishQuantity: fishQuantity ?? this.fishQuantity,
    );
  }

  @override
  List<Object?> get props => [
    scheduleId,
    fishId,
    aquariumId,
    scheduledFor,
    time,
    foodType,
    portionHint,
    status,
    log,
    fishName,
    aquariumName,
    avatarUrl,
    fishQuantity,
  ];
}
