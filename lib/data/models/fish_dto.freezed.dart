// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fish_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FishDto _$FishDtoFromJson(Map<String, dynamic> json) {
  return _FishDto.fromJson(json);
}

/// @nodoc
mixin _$FishDto {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'aquarium_id')
  String get aquariumId => throw _privateConstructorUsedError;
  @JsonKey(name: 'species_id')
  String get speciesId => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_name')
  String? get customName => throw _privateConstructorUsedError;
  @JsonKey(name: 'added_via')
  String? get addedVia => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FishDtoCopyWith<FishDto> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FishDtoCopyWith<$Res> {
  factory $FishDtoCopyWith(FishDto value, $Res Function(FishDto) then) =
      _$FishDtoCopyWithImpl<$Res, FishDto>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'aquarium_id') String aquariumId,
      @JsonKey(name: 'species_id') String speciesId,
      int quantity,
      @JsonKey(name: 'custom_name') String? customName,
      @JsonKey(name: 'added_via') String? addedVia,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$FishDtoCopyWithImpl<$Res, $Val extends FishDto>
    implements $FishDtoCopyWith<$Res> {
  _$FishDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? aquariumId = null,
    Object? speciesId = null,
    Object? quantity = null,
    Object? customName = freezed,
    Object? addedVia = freezed,
    Object? createdAt = null,
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
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      customName: freezed == customName
          ? _value.customName
          : customName // ignore: cast_nullable_to_non_nullable
              as String?,
      addedVia: freezed == addedVia
          ? _value.addedVia
          : addedVia // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FishDtoImplCopyWith<$Res> implements $FishDtoCopyWith<$Res> {
  factory _$$FishDtoImplCopyWith(
          _$FishDtoImpl value, $Res Function(_$FishDtoImpl) then) =
      __$$FishDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'aquarium_id') String aquariumId,
      @JsonKey(name: 'species_id') String speciesId,
      int quantity,
      @JsonKey(name: 'custom_name') String? customName,
      @JsonKey(name: 'added_via') String? addedVia,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$FishDtoImplCopyWithImpl<$Res>
    extends _$FishDtoCopyWithImpl<$Res, _$FishDtoImpl>
    implements _$$FishDtoImplCopyWith<$Res> {
  __$$FishDtoImplCopyWithImpl(
      _$FishDtoImpl _value, $Res Function(_$FishDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? aquariumId = null,
    Object? speciesId = null,
    Object? quantity = null,
    Object? customName = freezed,
    Object? addedVia = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$FishDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      aquariumId: null == aquariumId
          ? _value.aquariumId
          : aquariumId // ignore: cast_nullable_to_non_nullable
              as String,
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      customName: freezed == customName
          ? _value.customName
          : customName // ignore: cast_nullable_to_non_nullable
              as String?,
      addedVia: freezed == addedVia
          ? _value.addedVia
          : addedVia // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FishDtoImpl extends _FishDto {
  const _$FishDtoImpl(
      {required this.id,
      @JsonKey(name: 'aquarium_id') required this.aquariumId,
      @JsonKey(name: 'species_id') required this.speciesId,
      required this.quantity,
      @JsonKey(name: 'custom_name') this.customName,
      @JsonKey(name: 'added_via') this.addedVia,
      @JsonKey(name: 'created_at') required this.createdAt})
      : super._();

  factory _$FishDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$FishDtoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'aquarium_id')
  final String aquariumId;
  @override
  @JsonKey(name: 'species_id')
  final String speciesId;
  @override
  final int quantity;
  @override
  @JsonKey(name: 'custom_name')
  final String? customName;
  @override
  @JsonKey(name: 'added_via')
  final String? addedVia;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'FishDto(id: $id, aquariumId: $aquariumId, speciesId: $speciesId, quantity: $quantity, customName: $customName, addedVia: $addedVia, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FishDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.aquariumId, aquariumId) ||
                other.aquariumId == aquariumId) &&
            (identical(other.speciesId, speciesId) ||
                other.speciesId == speciesId) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.customName, customName) ||
                other.customName == customName) &&
            (identical(other.addedVia, addedVia) ||
                other.addedVia == addedVia) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, aquariumId, speciesId,
      quantity, customName, addedVia, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FishDtoImplCopyWith<_$FishDtoImpl> get copyWith =>
      __$$FishDtoImplCopyWithImpl<_$FishDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FishDtoImplToJson(
      this,
    );
  }
}

abstract class _FishDto extends FishDto {
  const factory _FishDto(
          {required final String id,
          @JsonKey(name: 'aquarium_id') required final String aquariumId,
          @JsonKey(name: 'species_id') required final String speciesId,
          required final int quantity,
          @JsonKey(name: 'custom_name') final String? customName,
          @JsonKey(name: 'added_via') final String? addedVia,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$FishDtoImpl;
  const _FishDto._() : super._();

  factory _FishDto.fromJson(Map<String, dynamic> json) = _$FishDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'aquarium_id')
  String get aquariumId;
  @override
  @JsonKey(name: 'species_id')
  String get speciesId;
  @override
  int get quantity;
  @override
  @JsonKey(name: 'custom_name')
  String? get customName;
  @override
  @JsonKey(name: 'added_via')
  String? get addedVia;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$FishDtoImplCopyWith<_$FishDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
