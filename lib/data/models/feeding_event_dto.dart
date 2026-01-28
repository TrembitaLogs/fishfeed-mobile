import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:fishfeed/data/models/feeding_event_model.dart';

part 'feeding_event_dto.freezed.dart';
part 'feeding_event_dto.g.dart';

/// DTO for feeding event data from the API.
///
/// Maps to the JSON response from /aquariums/{id}/events endpoints.
@freezed
class FeedingEventDto with _$FeedingEventDto {
  const FeedingEventDto._();

  const factory FeedingEventDto({
    required String id,
    @JsonKey(name: 'aquarium_id') required String aquariumId,
    @JsonKey(name: 'schedule_id') String? scheduleId,
    @JsonKey(name: 'fish_id') String? fishId,
    @JsonKey(name: 'species_id') String? speciesId,
    @JsonKey(name: 'scheduled_at') required DateTime scheduledAt,
    required String status,
    @JsonKey(name: 'completed_at') DateTime? completedAt,
    @JsonKey(name: 'completed_by') String? completedBy,
    @JsonKey(name: 'completed_by_name') String? completedByName,
    @JsonKey(name: 'completed_by_avatar') String? completedByAvatar,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _FeedingEventDto;

  factory FeedingEventDto.fromJson(Map<String, dynamic> json) =>
      _$FeedingEventDtoFromJson(json);

  /// Converts DTO to local Hive model.
  ///
  /// The event is marked as synced since it comes from the server.
  FeedingEventModel toModel() {
    return FeedingEventModel(
      id: id,
      fishId: fishId ?? '',
      aquariumId: aquariumId,
      feedingTime: scheduledAt,
      speciesId: speciesId,
      synced: true, // From server, so already synced
      createdAt: createdAt ?? scheduledAt,
      completedBy: completedBy,
      completedByName: completedByName,
      completedByAvatar: completedByAvatar,
      updatedAt: updatedAt,
      serverUpdatedAt: updatedAt,
    );
  }

  /// Whether the event is completed.
  bool get isCompleted => status == 'completed';

  /// Whether the event is missed.
  bool get isMissed => status == 'missed';

  /// Whether the event is pending.
  bool get isPending => status == 'pending';
}
