// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserDtoImpl _$$UserDtoImplFromJson(Map<String, dynamic> json) =>
    _$UserDtoImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarKey: json['avatar_key'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      subscriptionStatus: json['subscription_status'] as String? ?? 'free',
      freeAiScansRemaining:
          (json['free_ai_scans_remaining'] as num?)?.toInt() ?? 5,
    );

Map<String, dynamic> _$$UserDtoImplToJson(_$UserDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'display_name': instance.displayName,
      'avatar_key': instance.avatarKey,
      'created_at': instance.createdAt.toIso8601String(),
      'subscription_status': instance.subscriptionStatus,
      'free_ai_scans_remaining': instance.freeAiScansRemaining,
    };
