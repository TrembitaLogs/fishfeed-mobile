// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feeding_event_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FeedingEventDto _$FeedingEventDtoFromJson(Map<String, dynamic> json) {
  return _FeedingEventDto.fromJson(json);
}

/// @nodoc
mixin _$FeedingEventDto {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'aquarium_id')
  String get aquariumId => throw _privateConstructorUsedError;
  @JsonKey(name: 'schedule_id')
  String? get scheduleId => throw _privateConstructorUsedError;
  @JsonKey(name: 'fish_id')
  String? get fishId => throw _privateConstructorUsedError;
  @JsonKey(name: 'species_id')
  String? get speciesId => throw _privateConstructorUsedError;
  @JsonKey(name: 'scheduled_at')
  DateTime get scheduledAt => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_by')
  String? get completedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_by_name')
  String? get completedByName => throw _privateConstructorUsedError;
  @JsonKey(name: 'completed_by_avatar')
  String? get completedByAvatar => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FeedingEventDtoCopyWith<FeedingEventDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeedingEventDtoCopyWith<$Res> {
  factory $FeedingEventDtoCopyWith(
          FeedingEventDto value, $Res Function(FeedingEventDto) then) =
      _$FeedingEventDtoCopyWithImpl<$Res, FeedingEventDto>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'aquarium_id') String aquariumId,
      @JsonKey(name: 'schedule_id') String? scheduleId,
      @JsonKey(name: 'fish_id') String? fishId,
      @JsonKey(name: 'species_id') String? speciesId,
      @JsonKey(name: 'scheduled_at') DateTime scheduledAt,
      String status,
      @JsonKey(name: 'completed_at') DateTime? completedAt,
      @JsonKey(name: 'completed_by') String? completedBy,
      @JsonKey(name: 'completed_by_name') String? completedByName,
      @JsonKey(name: 'completed_by_avatar') String? completedByAvatar,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$FeedingEventDtoCopyWithImpl<$Res, $Val extends FeedingEventDto>
    implements $FeedingEventDtoCopyWith<$Res> {
  _$FeedingEventDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? aquariumId = null,
    Object? scheduleId = freezed,
    Object? fishId = freezed,
    Object? speciesId = freezed,
    Object? scheduledAt = null,
    Object? status = null,
    Object? completedAt = freezed,
    Object? completedBy = freezed,
    Object? completedByName = freezed,
    Object? completedByAvatar = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      aquariumId: null == aquariumId
          ? _value.aquariumId
          : aquariumId // ignore: cast_nullable_to_non_nullable
              as String,
      scheduleId: freezed == scheduleId
          ? _value.scheduleId
          : scheduleId // ignore: cast_nullable_to_non_nullable
              as String?,
      fishId: freezed == fishId
          ? _value.fishId
          : fishId // ignore: cast_nullable_to_non_nullable
              as String?,
      speciesId: freezed == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as String?,
      scheduledAt: null == scheduledAt
          ? _value.scheduledAt
          : scheduledAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedBy: freezed == completedBy
          ? _value.completedBy
          : completedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      completedByName: freezed == completedByName
          ? _value.completedByName
          : completedByName // ignore: cast_nullable_to_non_nullable
              as String?,
      completedByAvatar: freezed == completedByAvatar
          ? _value.completedByAvatar
          : completedByAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FeedingEventDtoImplCopyWith<$Res>
    implements $FeedingEventDtoCopyWith<$Res> {
  factory _$$FeedingEventDtoImplCopyWith(_$FeedingEventDtoImpl value,
          $Res Function(_$FeedingEventDtoImpl) then) =
      __$$FeedingEventDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'aquarium_id') String aquariumId,
      @JsonKey(name: 'schedule_id') String? scheduleId,
      @JsonKey(name: 'fish_id') String? fishId,
      @JsonKey(name: 'species_id') String? speciesId,
      @JsonKey(name: 'scheduled_at') DateTime scheduledAt,
      String status,
      @JsonKey(name: 'completed_at') DateTime? completedAt,
      @JsonKey(name: 'completed_by') String? completedBy,
      @JsonKey(name: 'completed_by_name') String? completedByName,
      @JsonKey(name: 'completed_by_avatar') String? completedByAvatar,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$$FeedingEventDtoImplCopyWithImpl<$Res>
    extends _$FeedingEventDtoCopyWithImpl<$Res, _$FeedingEventDtoImpl>
    implements _$$FeedingEventDtoImplCopyWith<$Res> {
  __$$FeedingEventDtoImplCopyWithImpl(
      _$FeedingEventDtoImpl _value, $Res Function(_$FeedingEventDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? aquariumId = null,
    Object? scheduleId = freezed,
    Object? fishId = freezed,
    Object? speciesId = freezed,
    Object? scheduledAt = null,
    Object? status = null,
    Object? completedAt = freezed,
    Object? completedBy = freezed,
    Object? completedByName = freezed,
    Object? completedByAvatar = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$FeedingEventDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      aquariumId: null == aquariumId
          ? _value.aquariumId
          : aquariumId // ignore: cast_nullable_to_non_nullable
              as String,
      scheduleId: freezed == scheduleId
          ? _value.scheduleId
          : scheduleId // ignore: cast_nullable_to_non_nullable
              as String?,
      fishId: freezed == fishId
          ? _value.fishId
          : fishId // ignore: cast_nullable_to_non_nullable
              as String?,
      speciesId: freezed == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as String?,
      scheduledAt: null == scheduledAt
          ? _value.scheduledAt
          : scheduledAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedBy: freezed == completedBy
          ? _value.completedBy
          : completedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      completedByName: freezed == completedByName
          ? _value.completedByName
          : completedByName // ignore: cast_nullable_to_non_nullable
              as String?,
      completedByAvatar: freezed == completedByAvatar
          ? _value.completedByAvatar
          : completedByAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FeedingEventDtoImpl extends _FeedingEventDto {
  const _$FeedingEventDtoImpl(
      {required this.id,
      @JsonKey(name: 'aquarium_id') required this.aquariumId,
      @JsonKey(name: 'schedule_id') this.scheduleId,
      @JsonKey(name: 'fish_id') this.fishId,
      @JsonKey(name: 'species_id') this.speciesId,
      @JsonKey(name: 'scheduled_at') required this.scheduledAt,
      required this.status,
      @JsonKey(name: 'completed_at') this.completedAt,
      @JsonKey(name: 'completed_by') this.completedBy,
      @JsonKey(name: 'completed_by_name') this.completedByName,
      @JsonKey(name: 'completed_by_avatar') this.completedByAvatar,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt})
      : super._();

  factory _$FeedingEventDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeedingEventDtoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'aquarium_id')
  final String aquariumId;
  @override
  @JsonKey(name: 'schedule_id')
  final String? scheduleId;
  @override
  @JsonKey(name: 'fish_id')
  final String? fishId;
  @override
  @JsonKey(name: 'species_id')
  final String? speciesId;
  @override
  @JsonKey(name: 'scheduled_at')
  final DateTime scheduledAt;
  @override
  final String status;
  @override
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  @override
  @JsonKey(name: 'completed_by')
  final String? completedBy;
  @override
  @JsonKey(name: 'completed_by_name')
  final String? completedByName;
  @override
  @JsonKey(name: 'completed_by_avatar')
  final String? completedByAvatar;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'FeedingEventDto(id: $id, aquariumId: $aquariumId, scheduleId: $scheduleId, fishId: $fishId, speciesId: $speciesId, scheduledAt: $scheduledAt, status: $status, completedAt: $completedAt, completedBy: $completedBy, completedByName: $completedByName, completedByAvatar: $completedByAvatar, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeedingEventDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.aquariumId, aquariumId) ||
                other.aquariumId == aquariumId) &&
            (identical(other.scheduleId, scheduleId) ||
                other.scheduleId == scheduleId) &&
            (identical(other.fishId, fishId) || other.fishId == fishId) &&
            (identical(other.speciesId, speciesId) ||
                other.speciesId == speciesId) &&
            (identical(other.scheduledAt, scheduledAt) ||
                other.scheduledAt == scheduledAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.completedBy, completedBy) ||
                other.completedBy == completedBy) &&
            (identical(other.completedByName, completedByName) ||
                other.completedByName == completedByName) &&
            (identical(other.completedByAvatar, completedByAvatar) ||
                other.completedByAvatar == completedByAvatar) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      aquariumId,
      scheduleId,
      fishId,
      speciesId,
      scheduledAt,
      status,
      completedAt,
      completedBy,
      completedByName,
      completedByAvatar,
      createdAt,
      updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FeedingEventDtoImplCopyWith<_$FeedingEventDtoImpl> get copyWith =>
      __$$FeedingEventDtoImplCopyWithImpl<_$FeedingEventDtoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FeedingEventDtoImplToJson(
      this,
    );
  }
}

abstract class _FeedingEventDto extends FeedingEventDto {
  const factory _FeedingEventDto(
          {required final String id,
          @JsonKey(name: 'aquarium_id') required final String aquariumId,
          @JsonKey(name: 'schedule_id') final String? scheduleId,
          @JsonKey(name: 'fish_id') final String? fishId,
          @JsonKey(name: 'species_id') final String? speciesId,
          @JsonKey(name: 'scheduled_at') required final DateTime scheduledAt,
          required final String status,
          @JsonKey(name: 'completed_at') final DateTime? completedAt,
          @JsonKey(name: 'completed_by') final String? completedBy,
          @JsonKey(name: 'completed_by_name') final String? completedByName,
          @JsonKey(name: 'completed_by_avatar') final String? completedByAvatar,
          @JsonKey(name: 'created_at') final DateTime? createdAt,
          @JsonKey(name: 'updated_at') final DateTime? updatedAt}) =
      _$FeedingEventDtoImpl;
  const _FeedingEventDto._() : super._();

  factory _FeedingEventDto.fromJson(Map<String, dynamic> json) =
      _$FeedingEventDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'aquarium_id')
  String get aquariumId;
  @override
  @JsonKey(name: 'schedule_id')
  String? get scheduleId;
  @override
  @JsonKey(name: 'fish_id')
  String? get fishId;
  @override
  @JsonKey(name: 'species_id')
  String? get speciesId;
  @override
  @JsonKey(name: 'scheduled_at')
  DateTime get scheduledAt;
  @override
  String get status;
  @override
  @JsonKey(name: 'completed_at')
  DateTime? get completedAt;
  @override
  @JsonKey(name: 'completed_by')
  String? get completedBy;
  @override
  @JsonKey(name: 'completed_by_name')
  String? get completedByName;
  @override
  @JsonKey(name: 'completed_by_avatar')
  String? get completedByAvatar;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$FeedingEventDtoImplCopyWith<_$FeedingEventDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
