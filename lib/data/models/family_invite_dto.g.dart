// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_invite_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FamilyInviteDtoImpl _$$FamilyInviteDtoImplFromJson(
  Map<String, dynamic> json,
) => _$FamilyInviteDtoImpl(
  id: json['id'] as String?,
  inviteCode: json['invite_code'] as String,
  inviteLink: json['invite_link'] as String,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  expiresAt: DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$$FamilyInviteDtoImplToJson(
  _$FamilyInviteDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'invite_code': instance.inviteCode,
  'invite_link': instance.inviteLink,
  'created_at': instance.createdAt?.toIso8601String(),
  'expires_at': instance.expiresAt.toIso8601String(),
};
