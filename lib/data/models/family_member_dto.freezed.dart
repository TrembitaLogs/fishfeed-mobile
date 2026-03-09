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
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FamilyMemberDto _$FamilyMemberDtoFromJson(Map<String, dynamic> json) {
  return _FamilyMemberDto.fromJson(json);
}

/// @nodoc
mixin _$FamilyMemberDto {
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  String? get nickname => throw _privateConstructorUsedError;
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  @JsonKey(name: 'joined_at')
  DateTime get joinedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FamilyMemberDtoCopyWith<FamilyMemberDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FamilyMemberDtoCopyWith<$Res> {
  factory $FamilyMemberDtoCopyWith(
    FamilyMemberDto value,
    $Res Function(FamilyMemberDto) then,
  ) = _$FamilyMemberDtoCopyWithImpl<$Res, FamilyMemberDto>;
  @useResult
  $Res call({
    @JsonKey(name: 'user_id') String userId,
    String? nickname,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    String role,
    @JsonKey(name: 'joined_at') DateTime joinedAt,
  });
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
    Object? userId = null,
    Object? nickname = freezed,
    Object? avatarUrl = freezed,
    Object? role = null,
    Object? joinedAt = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            nickname: freezed == nickname
                ? _value.nickname
                : nickname // ignore: cast_nullable_to_non_nullable
                      as String?,
            avatarUrl: freezed == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as String,
            joinedAt: null == joinedAt
                ? _value.joinedAt
                : joinedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FamilyMemberDtoImplCopyWith<$Res>
    implements $FamilyMemberDtoCopyWith<$Res> {
  factory _$$FamilyMemberDtoImplCopyWith(
    _$FamilyMemberDtoImpl value,
    $Res Function(_$FamilyMemberDtoImpl) then,
  ) = __$$FamilyMemberDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'user_id') String userId,
    String? nickname,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    String role,
    @JsonKey(name: 'joined_at') DateTime joinedAt,
  });
}

/// @nodoc
class __$$FamilyMemberDtoImplCopyWithImpl<$Res>
    extends _$FamilyMemberDtoCopyWithImpl<$Res, _$FamilyMemberDtoImpl>
    implements _$$FamilyMemberDtoImplCopyWith<$Res> {
  __$$FamilyMemberDtoImplCopyWithImpl(
    _$FamilyMemberDtoImpl _value,
    $Res Function(_$FamilyMemberDtoImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? nickname = freezed,
    Object? avatarUrl = freezed,
    Object? role = null,
    Object? joinedAt = null,
  }) {
    return _then(
      _$FamilyMemberDtoImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        nickname: freezed == nickname
            ? _value.nickname
            : nickname // ignore: cast_nullable_to_non_nullable
                  as String?,
        avatarUrl: freezed == avatarUrl
            ? _value.avatarUrl
            : avatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        joinedAt: null == joinedAt
            ? _value.joinedAt
            : joinedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FamilyMemberDtoImpl extends _FamilyMemberDto {
  const _$FamilyMemberDtoImpl({
    @JsonKey(name: 'user_id') required this.userId,
    this.nickname,
    @JsonKey(name: 'avatar_url') this.avatarUrl,
    this.role = 'member',
    @JsonKey(name: 'joined_at') required this.joinedAt,
  }) : super._();

  factory _$FamilyMemberDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$FamilyMemberDtoImplFromJson(json);

  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  final String? nickname;
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @override
  @JsonKey()
  final String role;
  @override
  @JsonKey(name: 'joined_at')
  final DateTime joinedAt;

  @override
  String toString() {
    return 'FamilyMemberDto(userId: $userId, nickname: $nickname, avatarUrl: $avatarUrl, role: $role, joinedAt: $joinedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FamilyMemberDtoImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, userId, nickname, avatarUrl, role, joinedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FamilyMemberDtoImplCopyWith<_$FamilyMemberDtoImpl> get copyWith =>
      __$$FamilyMemberDtoImplCopyWithImpl<_$FamilyMemberDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FamilyMemberDtoImplToJson(this);
  }
}

abstract class _FamilyMemberDto extends FamilyMemberDto {
  const factory _FamilyMemberDto({
    @JsonKey(name: 'user_id') required final String userId,
    final String? nickname,
    @JsonKey(name: 'avatar_url') final String? avatarUrl,
    final String role,
    @JsonKey(name: 'joined_at') required final DateTime joinedAt,
  }) = _$FamilyMemberDtoImpl;
  const _FamilyMemberDto._() : super._();

  factory _FamilyMemberDto.fromJson(Map<String, dynamic> json) =
      _$FamilyMemberDtoImpl.fromJson;

  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  String? get nickname;
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;
  @override
  String get role;
  @override
  @JsonKey(name: 'joined_at')
  DateTime get joinedAt;
  @override
  @JsonKey(ignore: true)
  _$$FamilyMemberDtoImplCopyWith<_$FamilyMemberDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
