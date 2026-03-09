// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_member_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FamilyMemberDtoImpl _$$FamilyMemberDtoImplFromJson(
  Map<String, dynamic> json,
) => _$FamilyMemberDtoImpl(
  userId: json['user_id'] as String,
  nickname: json['nickname'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  role: json['role'] as String? ?? 'member',
  joinedAt: DateTime.parse(json['joined_at'] as String),
);

Map<String, dynamic> _$$FamilyMemberDtoImplToJson(
  _$FamilyMemberDtoImpl instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'nickname': instance.nickname,
  'avatar_url': instance.avatarUrl,
  'role': instance.role,
  'joined_at': instance.joinedAt.toIso8601String(),
};
