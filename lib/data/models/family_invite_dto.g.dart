// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_invite_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FamilyInviteDtoImpl _$$FamilyInviteDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$FamilyInviteDtoImpl(
      id: json['id'] as String,
      aquariumId: json['aquarium_id'] as String,
      inviteCode: json['invite_code'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      status: json['status'] as String? ?? 'pending',
      acceptedBy: json['accepted_by'] as String?,
      acceptedAt: json['accepted_at'] == null
          ? null
          : DateTime.parse(json['accepted_at'] as String),
    );

Map<String, dynamic> _$$FamilyInviteDtoImplToJson(
        _$FamilyInviteDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'aquarium_id': instance.aquariumId,
      'invite_code': instance.inviteCode,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
      'expires_at': instance.expiresAt.toIso8601String(),
      'status': instance.status,
      'accepted_by': instance.acceptedBy,
      'accepted_at': instance.acceptedAt?.toIso8601String(),
    };
