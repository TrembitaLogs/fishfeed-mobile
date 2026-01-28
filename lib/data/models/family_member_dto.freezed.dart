// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'family_member_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FamilyMemberDto _$FamilyMemberDtoFromJson(Map<String, dynamic> json) {
  return _FamilyMemberDto.fromJson(json);
}

/// @nodoc
mixin _$FamilyMemberDto {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'aquarium_id')
  String get aquariumId => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  @JsonKey(name: 'joined_at')
  DateTime get joinedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String? get displayName => throw _privateConstructorUsedError;
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FamilyMemberDtoCopyWith<FamilyMemberDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FamilyMemberDtoCopyWith<$Res> {
  factory $FamilyMemberDtoCopyWith(
          FamilyMemberDto value, $Res Function(FamilyMemberDto) then) =
      _$FamilyMemberDtoCopyWithImpl<$Res, FamilyMemberDto>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'aquarium_id') String aquariumId,
      String role,
      @JsonKey(name: 'joined_at') DateTime joinedAt,
      @JsonKey(name: 'display_name') String? displayName,
      @JsonKey(name: 'avatar_url') String? avatarUrl});
}

/// @nodoc
class _$FamilyMemberDtoCopyWithImpl<$Res, $Val extends FamilyMemberDto>
    implements $FamilyMemberDtoCopyWith<$Res> {
  _$FamilyMemberDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? aquariumId = null,
    Object? role = null,
    Object? joinedAt = null,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      aquariumId: null == aquariumId
          ? _value.aquariumId
          : aquariumId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      joinedAt: null == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FamilyMemberDtoImplCopyWith<$Res>
    implements $FamilyMemberDtoCopyWith<$Res> {
  factory _$$FamilyMemberDtoImplCopyWith(_$FamilyMemberDtoImpl value,
          $Res Function(_$FamilyMemberDtoImpl) then) =
      __$$FamilyMemberDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'aquarium_id') String aquariumId,
      String role,
      @JsonKey(name: 'joined_at') DateTime joinedAt,
      @JsonKey(name: 'display_name') String? displayName,
      @JsonKey(name: 'avatar_url') String? avatarUrl});
}

/// @nodoc
class __$$FamilyMemberDtoImplCopyWithImpl<$Res>
    extends _$FamilyMemberDtoCopyWithImpl<$Res, _$FamilyMemberDtoImpl>
    implements _$$FamilyMemberDtoImplCopyWith<$Res> {
  __$$FamilyMemberDtoImplCopyWithImpl(
      _$FamilyMemberDtoImpl _value, $Res Function(_$FamilyMemberDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? aquariumId = null,
    Object? role = null,
    Object? joinedAt = null,
    Object? displayName = freezed,
    Object? avatarUrl = freezed,
  }) {
    return _then(_$FamilyMemberDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      aquariumId: null == aquariumId
          ? _value.aquariumId
          : aquariumId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      joinedAt: null == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FamilyMemberDtoImpl extends _FamilyMemberDto {
  const _$FamilyMemberDtoImpl(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'aquarium_id') required this.aquariumId,
      this.role = 'member',
      @JsonKey(name: 'joined_at') required this.joinedAt,
      @JsonKey(name: 'display_name') this.displayName,
      @JsonKey(name: 'avatar_url') this.avatarUrl})
      : super._();

  factory _$FamilyMemberDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$FamilyMemberDtoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'aquarium_id')
  final String aquariumId;
  @override
  @JsonKey()
  final String role;
  @override
  @JsonKey(name: 'joined_at')
  final DateTime joinedAt;
  @override
  @JsonKey(name: 'display_name')
  final String? displayName;
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  @override
  String toString() {
    return 'FamilyMemberDto(id: $id, userId: $userId, aquariumId: $aquariumId, role: $role, joinedAt: $joinedAt, displayName: $displayName, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FamilyMemberDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.aquariumId, aquariumId) ||
                other.aquariumId == aquariumId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, aquariumId, role,
      joinedAt, displayName, avatarUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FamilyMemberDtoImplCopyWith<_$FamilyMemberDtoImpl> get copyWith =>
      __$$FamilyMemberDtoImplCopyWithImpl<_$FamilyMemberDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FamilyMemberDtoImplToJson(
      this,
    );
  }
}

abstract class _FamilyMemberDto extends FamilyMemberDto {
  const factory _FamilyMemberDto(
          {required final String id,
          @JsonKey(name: 'user_id') required final String userId,
          @JsonKey(name: 'aquarium_id') required final String aquariumId,
          final String role,
          @JsonKey(name: 'joined_at') required final DateTime joinedAt,
          @JsonKey(name: 'display_name') final String? displayName,
          @JsonKey(name: 'avatar_url') final String? avatarUrl}) =
      _$FamilyMemberDtoImpl;
  const _FamilyMemberDto._() : super._();

  factory _FamilyMemberDto.fromJson(Map<String, dynamic> json) =
      _$FamilyMemberDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'aquarium_id')
  String get aquariumId;
  @override
  String get role;
  @override
  @JsonKey(name: 'joined_at')
  DateTime get joinedAt;
  @override
  @JsonKey(name: 'display_name')
  String? get displayName;
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;
  @override
  @JsonKey(ignore: true)
  _$$FamilyMemberDtoImplCopyWith<_$FamilyMemberDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
