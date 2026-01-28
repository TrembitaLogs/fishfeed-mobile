// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_member_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FamilyMemberDtoImpl _$$FamilyMemberDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$FamilyMemberDtoImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      aquariumId: json['aquarium_id'] as String,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String),
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );

Map<String, dynamic> _$$FamilyMemberDtoImplToJson(
        _$FamilyMemberDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'aquarium_id': instance.aquariumId,
      'role': instance.role,
      'joined_at': instance.joinedAt.toIso8601String(),
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
    };
