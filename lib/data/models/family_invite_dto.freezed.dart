// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'family_invite_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FamilyInviteDto _$FamilyInviteDtoFromJson(Map<String, dynamic> json) {
  return _FamilyInviteDto.fromJson(json);
}

/// @nodoc
mixin _$FamilyInviteDto {
  String? get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'invite_code')
  String get inviteCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'invite_link')
  String get inviteLink => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'expires_at')
  DateTime get expiresAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FamilyInviteDtoCopyWith<FamilyInviteDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FamilyInviteDtoCopyWith<$Res> {
  factory $FamilyInviteDtoCopyWith(
    FamilyInviteDto value,
    $Res Function(FamilyInviteDto) then,
  ) = _$FamilyInviteDtoCopyWithImpl<$Res, FamilyInviteDto>;
  @useResult
  $Res call({
    String? id,
    @JsonKey(name: 'invite_code') String inviteCode,
    @JsonKey(name: 'invite_link') String inviteLink,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'expires_at') DateTime expiresAt,
  });
}

/// @nodoc
class _$FamilyInviteDtoCopyWithImpl<$Res, $Val extends FamilyInviteDto>
    implements $FamilyInviteDtoCopyWith<$Res> {
  _$FamilyInviteDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? inviteCode = null,
    Object? inviteLink = null,
    Object? createdAt = freezed,
    Object? expiresAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            inviteCode: null == inviteCode
                ? _value.inviteCode
                : inviteCode // ignore: cast_nullable_to_non_nullable
                      as String,
            inviteLink: null == inviteLink
                ? _value.inviteLink
                : inviteLink // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            expiresAt: null == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FamilyInviteDtoImplCopyWith<$Res>
    implements $FamilyInviteDtoCopyWith<$Res> {
  factory _$$FamilyInviteDtoImplCopyWith(
    _$FamilyInviteDtoImpl value,
    $Res Function(_$FamilyInviteDtoImpl) then,
  ) = __$$FamilyInviteDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? id,
    @JsonKey(name: 'invite_code') String inviteCode,
    @JsonKey(name: 'invite_link') String inviteLink,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'expires_at') DateTime expiresAt,
  });
}

/// @nodoc
class __$$FamilyInviteDtoImplCopyWithImpl<$Res>
    extends _$FamilyInviteDtoCopyWithImpl<$Res, _$FamilyInviteDtoImpl>
    implements _$$FamilyInviteDtoImplCopyWith<$Res> {
  __$$FamilyInviteDtoImplCopyWithImpl(
    _$FamilyInviteDtoImpl _value,
    $Res Function(_$FamilyInviteDtoImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? inviteCode = null,
    Object? inviteLink = null,
    Object? createdAt = freezed,
    Object? expiresAt = null,
  }) {
    return _then(
      _$FamilyInviteDtoImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        inviteCode: null == inviteCode
            ? _value.inviteCode
            : inviteCode // ignore: cast_nullable_to_non_nullable
                  as String,
        inviteLink: null == inviteLink
            ? _value.inviteLink
            : inviteLink // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        expiresAt: null == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FamilyInviteDtoImpl extends _FamilyInviteDto {
  const _$FamilyInviteDtoImpl({
    this.id,
    @JsonKey(name: 'invite_code') required this.inviteCode,
    @JsonKey(name: 'invite_link') required this.inviteLink,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'expires_at') required this.expiresAt,
  }) : super._();

  factory _$FamilyInviteDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$FamilyInviteDtoImplFromJson(json);

  @override
  final String? id;
  @override
  @JsonKey(name: 'invite_code')
  final String inviteCode;
  @override
  @JsonKey(name: 'invite_link')
  final String inviteLink;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  @override
  String toString() {
    return 'FamilyInviteDto(id: $id, inviteCode: $inviteCode, inviteLink: $inviteLink, createdAt: $createdAt, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FamilyInviteDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.inviteCode, inviteCode) ||
                other.inviteCode == inviteCode) &&
            (identical(other.inviteLink, inviteLink) ||
                other.inviteLink == inviteLink) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    inviteCode,
    inviteLink,
    createdAt,
    expiresAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FamilyInviteDtoImplCopyWith<_$FamilyInviteDtoImpl> get copyWith =>
      __$$FamilyInviteDtoImplCopyWithImpl<_$FamilyInviteDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FamilyInviteDtoImplToJson(this);
  }
}

abstract class _FamilyInviteDto extends FamilyInviteDto {
  const factory _FamilyInviteDto({
    final String? id,
    @JsonKey(name: 'invite_code') required final String inviteCode,
    @JsonKey(name: 'invite_link') required final String inviteLink,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'expires_at') required final DateTime expiresAt,
  }) = _$FamilyInviteDtoImpl;
  const _FamilyInviteDto._() : super._();

  factory _FamilyInviteDto.fromJson(Map<String, dynamic> json) =
      _$FamilyInviteDtoImpl.fromJson;

  @override
  String? get id;
  @override
  @JsonKey(name: 'invite_code')
  String get inviteCode;
  @override
  @JsonKey(name: 'invite_link')
  String get inviteLink;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'expires_at')
  DateTime get expiresAt;
  @override
  @JsonKey(ignore: true)
  _$$FamilyInviteDtoImplCopyWith<_$FamilyInviteDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
