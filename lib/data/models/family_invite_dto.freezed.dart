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
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'aquarium_id')
  String get aquariumId => throw _privateConstructorUsedError;
  @JsonKey(name: 'invite_code')
  String get inviteCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by')
  String get createdBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'expires_at')
  DateTime get expiresAt => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'accepted_by')
  String? get acceptedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'accepted_at')
  DateTime? get acceptedAt => throw _privateConstructorUsedError;

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
    String id,
    @JsonKey(name: 'aquarium_id') String aquariumId,
    @JsonKey(name: 'invite_code') String inviteCode,
    @JsonKey(name: 'created_by') String createdBy,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'expires_at') DateTime expiresAt,
    String status,
    @JsonKey(name: 'accepted_by') String? acceptedBy,
    @JsonKey(name: 'accepted_at') DateTime? acceptedAt,
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
    Object? id = null,
    Object? aquariumId = null,
    Object? inviteCode = null,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? expiresAt = null,
    Object? status = null,
    Object? acceptedBy = freezed,
    Object? acceptedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            aquariumId: null == aquariumId
                ? _value.aquariumId
                : aquariumId // ignore: cast_nullable_to_non_nullable
                      as String,
            inviteCode: null == inviteCode
                ? _value.inviteCode
                : inviteCode // ignore: cast_nullable_to_non_nullable
                      as String,
            createdBy: null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            expiresAt: null == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            acceptedBy: freezed == acceptedBy
                ? _value.acceptedBy
                : acceptedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            acceptedAt: freezed == acceptedAt
                ? _value.acceptedAt
                : acceptedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
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
    String id,
    @JsonKey(name: 'aquarium_id') String aquariumId,
    @JsonKey(name: 'invite_code') String inviteCode,
    @JsonKey(name: 'created_by') String createdBy,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'expires_at') DateTime expiresAt,
    String status,
    @JsonKey(name: 'accepted_by') String? acceptedBy,
    @JsonKey(name: 'accepted_at') DateTime? acceptedAt,
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
    Object? id = null,
    Object? aquariumId = null,
    Object? inviteCode = null,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? expiresAt = null,
    Object? status = null,
    Object? acceptedBy = freezed,
    Object? acceptedAt = freezed,
  }) {
    return _then(
      _$FamilyInviteDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        aquariumId: null == aquariumId
            ? _value.aquariumId
            : aquariumId // ignore: cast_nullable_to_non_nullable
                  as String,
        inviteCode: null == inviteCode
            ? _value.inviteCode
            : inviteCode // ignore: cast_nullable_to_non_nullable
                  as String,
        createdBy: null == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        expiresAt: null == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        acceptedBy: freezed == acceptedBy
            ? _value.acceptedBy
            : acceptedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        acceptedAt: freezed == acceptedAt
            ? _value.acceptedAt
            : acceptedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FamilyInviteDtoImpl extends _FamilyInviteDto {
  const _$FamilyInviteDtoImpl({
    required this.id,
    @JsonKey(name: 'aquarium_id') required this.aquariumId,
    @JsonKey(name: 'invite_code') required this.inviteCode,
    @JsonKey(name: 'created_by') required this.createdBy,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'expires_at') required this.expiresAt,
    this.status = 'pending',
    @JsonKey(name: 'accepted_by') this.acceptedBy,
    @JsonKey(name: 'accepted_at') this.acceptedAt,
  }) : super._();

  factory _$FamilyInviteDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$FamilyInviteDtoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'aquarium_id')
  final String aquariumId;
  @override
  @JsonKey(name: 'invite_code')
  final String inviteCode;
  @override
  @JsonKey(name: 'created_by')
  final String createdBy;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'accepted_by')
  final String? acceptedBy;
  @override
  @JsonKey(name: 'accepted_at')
  final DateTime? acceptedAt;

  @override
  String toString() {
    return 'FamilyInviteDto(id: $id, aquariumId: $aquariumId, inviteCode: $inviteCode, createdBy: $createdBy, createdAt: $createdAt, expiresAt: $expiresAt, status: $status, acceptedBy: $acceptedBy, acceptedAt: $acceptedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FamilyInviteDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.aquariumId, aquariumId) ||
                other.aquariumId == aquariumId) &&
            (identical(other.inviteCode, inviteCode) ||
                other.inviteCode == inviteCode) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.acceptedBy, acceptedBy) ||
                other.acceptedBy == acceptedBy) &&
            (identical(other.acceptedAt, acceptedAt) ||
                other.acceptedAt == acceptedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    aquariumId,
    inviteCode,
    createdBy,
    createdAt,
    expiresAt,
    status,
    acceptedBy,
    acceptedAt,
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
    required final String id,
    @JsonKey(name: 'aquarium_id') required final String aquariumId,
    @JsonKey(name: 'invite_code') required final String inviteCode,
    @JsonKey(name: 'created_by') required final String createdBy,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
    @JsonKey(name: 'expires_at') required final DateTime expiresAt,
    final String status,
    @JsonKey(name: 'accepted_by') final String? acceptedBy,
    @JsonKey(name: 'accepted_at') final DateTime? acceptedAt,
  }) = _$FamilyInviteDtoImpl;
  const _FamilyInviteDto._() : super._();

  factory _FamilyInviteDto.fromJson(Map<String, dynamic> json) =
      _$FamilyInviteDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'aquarium_id')
  String get aquariumId;
  @override
  @JsonKey(name: 'invite_code')
  String get inviteCode;
  @override
  @JsonKey(name: 'created_by')
  String get createdBy;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'expires_at')
  DateTime get expiresAt;
  @override
  String get status;
  @override
  @JsonKey(name: 'accepted_by')
  String? get acceptedBy;
  @override
  @JsonKey(name: 'accepted_at')
  DateTime? get acceptedAt;
  @override
  @JsonKey(ignore: true)
  _$$FamilyInviteDtoImplCopyWith<_$FamilyInviteDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
