// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthResponseDtoImpl _$$AuthResponseDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$AuthResponseDtoImpl(
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );

Map<String, dynamic> _$$AuthResponseDtoImplToJson(
        _$AuthResponseDtoImpl instance) =>
    <String, dynamic>{
      'user': instance.user.toJson(),
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
    };
