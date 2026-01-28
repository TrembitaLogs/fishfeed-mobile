// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feeding_event_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FeedingEventDtoImpl _$$FeedingEventDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$FeedingEventDtoImpl(
      id: json['id'] as String,
      aquariumId: json['aquarium_id'] as String,
      scheduleId: json['schedule_id'] as String?,
      fishId: json['fish_id'] as String?,
      speciesId: json['species_id'] as String?,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      status: json['status'] as String,
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      completedBy: json['completed_by'] as String?,
      completedByName: json['completed_by_name'] as String?,
      completedByAvatar: json['completed_by_avatar'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$FeedingEventDtoImplToJson(
        _$FeedingEventDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'aquarium_id': instance.aquariumId,
      'schedule_id': instance.scheduleId,
      'fish_id': instance.fishId,
      'species_id': instance.speciesId,
      'scheduled_at': instance.scheduledAt.toIso8601String(),
      'status': instance.status,
      'completed_at': instance.completedAt?.toIso8601String(),
      'completed_by': instance.completedBy,
      'completed_by_name': instance.completedByName,
      'completed_by_avatar': instance.completedByAvatar,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
