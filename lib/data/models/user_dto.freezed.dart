// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserDto _$UserDtoFromJson(Map<String, dynamic> json) {
  return _UserDto.fromJson(json);
}

/// @nodoc
mixin _$UserDto {
  String get id => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String? get displayName => throw _privateConstructorUsedError;
  @JsonKey(name: 'avatar_key')
  String? get avatarKey => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'subscription_status')
  String get subscriptionStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'free_ai_scans_remaining')
  int get freeAiScansRemaining => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserDtoCopyWith<UserDto> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserDtoCopyWith<$Res> {
  factory $UserDtoCopyWith(UserDto value, $Res Function(UserDto) then) =
      _$UserDtoCopyWithImpl<$Res, UserDto>;
  @useResult
  $Res call({
    String id,
    String email,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'avatar_key') String? avatarKey,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'subscription_status') String subscriptionStatus,
    @JsonKey(name: 'free_ai_scans_remaining') int freeAiScansRemaining,
  });
}

/// @nodoc
class _$UserDtoCopyWithImpl<$Res, $Val extends UserDto>
    implements $UserDtoCopyWith<$Res> {
  _$UserDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? displayName = freezed,
    Object? avatarKey = freezed,
    Object? createdAt = null,
    Object? subscriptionStatus = null,
    Object? freeAiScansRemaining = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: freezed == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String?,
            avatarKey: freezed == avatarKey
                ? _value.avatarKey
                : avatarKey // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            subscriptionStatus: null == subscriptionStatus
                ? _value.subscriptionStatus
                : subscriptionStatus // ignore: cast_nullable_to_non_nullable
                      as String,
            freeAiScansRemaining: null == freeAiScansRemaining
                ? _value.freeAiScansRemaining
                : freeAiScansRemaining // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserDtoImplCopyWith<$Res> implements $UserDtoCopyWith<$Res> {
  factory _$$UserDtoImplCopyWith(
    _$UserDtoImpl value,
    $Res Function(_$UserDtoImpl) then,
  ) = __$$UserDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String email,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'avatar_key') String? avatarKey,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'subscription_status') String subscriptionStatus,
    @JsonKey(name: 'free_ai_scans_remaining') int freeAiScansRemaining,
  });
}

/// @nodoc
class __$$UserDtoImplCopyWithImpl<$Res>
    extends _$UserDtoCopyWithImpl<$Res, _$UserDtoImpl>
    implements _$$UserDtoImplCopyWith<$Res> {
  __$$UserDtoImplCopyWithImpl(
    _$UserDtoImpl _value,
    $Res Function(_$UserDtoImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? displayName = freezed,
    Object? avatarKey = freezed,
    Object? createdAt = null,
    Object? subscriptionStatus = null,
    Object? freeAiScansRemaining = null,
  }) {
    return _then(
      _$UserDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: freezed == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String?,
        avatarKey: freezed == avatarKey
            ? _value.avatarKey
            : avatarKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        subscriptionStatus: null == subscriptionStatus
            ? _value.subscriptionStatus
            : subscriptionStatus // ignore: cast_nullable_to_non_nullable
                  as String,
        freeAiScansRemaining: null == freeAiScansRemaining
            ? _value.freeAiScansRemaining
            : freeAiScansRemaining // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserDtoImpl implements _UserDto {
  const _$UserDtoImpl({
    required this.id,
    required this.email,
    @JsonKey(name: 'display_name') this.displayName,
    @JsonKey(name: 'avatar_key') this.avatarKey,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'subscription_status') this.subscriptionStatus = 'free',
    @JsonKey(name: 'free_ai_scans_remaining') this.freeAiScansRemaining = 5,
  });

  factory _$UserDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String email;
  @override
  @JsonKey(name: 'display_name')
  final String? displayName;
  @override
  @JsonKey(name: 'avatar_key')
  final String? avatarKey;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'subscription_status')
  final String subscriptionStatus;
  @override
  @JsonKey(name: 'free_ai_scans_remaining')
  final int freeAiScansRemaining;

  @override
  String toString() {
    return 'UserDto(id: $id, email: $email, displayName: $displayName, avatarKey: $avatarKey, createdAt: $createdAt, subscriptionStatus: $subscriptionStatus, freeAiScansRemaining: $freeAiScansRemaining)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.avatarKey, avatarKey) ||
                other.avatarKey == avatarKey) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.subscriptionStatus, subscriptionStatus) ||
                other.subscriptionStatus == subscriptionStatus) &&
            (identical(other.freeAiScansRemaining, freeAiScansRemaining) ||
                other.freeAiScansRemaining == freeAiScansRemaining));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    email,
    displayName,
    avatarKey,
    createdAt,
    subscriptionStatus,
    freeAiScansRemaining,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserDtoImplCopyWith<_$UserDtoImpl> get copyWith =>
      __$$UserDtoImplCopyWithImpl<_$UserDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserDtoImplToJson(this);
  }
}

abstract class _UserDto implements UserDto {
  const factory _UserDto({
    required final String id,
    required final String email,
    @JsonKey(name: 'display_name') final String? displayName,
    @JsonKey(name: 'avatar_key') final String? avatarKey,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
    @JsonKey(name: 'subscription_status') final String subscriptionStatus,
    @JsonKey(name: 'free_ai_scans_remaining') final int freeAiScansRemaining,
  }) = _$UserDtoImpl;

  factory _UserDto.fromJson(Map<String, dynamic> json) = _$UserDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get email;
  @override
  @JsonKey(name: 'display_name')
  String? get displayName;
  @override
  @JsonKey(name: 'avatar_key')
  String? get avatarKey;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'subscription_status')
  String get subscriptionStatus;
  @override
  @JsonKey(name: 'free_ai_scans_remaining')
  int get freeAiScansRemaining;
  @override
  @JsonKey(ignore: true)
  _$$UserDtoImplCopyWith<_$UserDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
