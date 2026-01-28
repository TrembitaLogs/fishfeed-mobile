// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'aquarium_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AquariumDto _$AquariumDtoFromJson(Map<String, dynamic> json) {
  return _AquariumDto.fromJson(json);
}

/// @nodoc
mixin _$AquariumDto {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'owner_id')
  String get userId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double? get capacity => throw _privateConstructorUsedError;
  @JsonKey(name: 'water_type')
  String get waterType => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String? get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AquariumDtoCopyWith<AquariumDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AquariumDtoCopyWith<$Res> {
  factory $AquariumDtoCopyWith(
    AquariumDto value,
    $Res Function(AquariumDto) then,
  ) = _$AquariumDtoCopyWithImpl<$Res, AquariumDto>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'owner_id') String userId,
    String name,
    double? capacity,
    @JsonKey(name: 'water_type') String waterType,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'created_at') DateTime createdAt,
  });
}

/// @nodoc
class _$AquariumDtoCopyWithImpl<$Res, $Val extends AquariumDto>
    implements $AquariumDtoCopyWith<$Res> {
  _$AquariumDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? capacity = freezed,
    Object? waterType = null,
    Object? imageUrl = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            capacity: freezed == capacity
                ? _value.capacity
                : capacity // ignore: cast_nullable_to_non_nullable
                      as double?,
            waterType: null == waterType
                ? _value.waterType
                : waterType // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AquariumDtoImplCopyWith<$Res>
    implements $AquariumDtoCopyWith<$Res> {
  factory _$$AquariumDtoImplCopyWith(
    _$AquariumDtoImpl value,
    $Res Function(_$AquariumDtoImpl) then,
  ) = __$$AquariumDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'owner_id') String userId,
    String name,
    double? capacity,
    @JsonKey(name: 'water_type') String waterType,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'created_at') DateTime createdAt,
  });
}

/// @nodoc
class __$$AquariumDtoImplCopyWithImpl<$Res>
    extends _$AquariumDtoCopyWithImpl<$Res, _$AquariumDtoImpl>
    implements _$$AquariumDtoImplCopyWith<$Res> {
  __$$AquariumDtoImplCopyWithImpl(
    _$AquariumDtoImpl _value,
    $Res Function(_$AquariumDtoImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? capacity = freezed,
    Object? waterType = null,
    Object? imageUrl = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$AquariumDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        capacity: freezed == capacity
            ? _value.capacity
            : capacity // ignore: cast_nullable_to_non_nullable
                  as double?,
        waterType: null == waterType
            ? _value.waterType
            : waterType // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AquariumDtoImpl extends _AquariumDto {
  const _$AquariumDtoImpl({
    required this.id,
    @JsonKey(name: 'owner_id') required this.userId,
    required this.name,
    this.capacity,
    @JsonKey(name: 'water_type') this.waterType = 'freshwater',
    @JsonKey(name: 'image_url') this.imageUrl,
    @JsonKey(name: 'created_at') required this.createdAt,
  }) : super._();

  factory _$AquariumDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AquariumDtoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'owner_id')
  final String userId;
  @override
  final String name;
  @override
  final double? capacity;
  @override
  @JsonKey(name: 'water_type')
  final String waterType;
  @override
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'AquariumDto(id: $id, userId: $userId, name: $name, capacity: $capacity, waterType: $waterType, imageUrl: $imageUrl, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AquariumDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.capacity, capacity) ||
                other.capacity == capacity) &&
            (identical(other.waterType, waterType) ||
                other.waterType == waterType) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    name,
    capacity,
    waterType,
    imageUrl,
    createdAt,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AquariumDtoImplCopyWith<_$AquariumDtoImpl> get copyWith =>
      __$$AquariumDtoImplCopyWithImpl<_$AquariumDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AquariumDtoImplToJson(this);
  }
}

abstract class _AquariumDto extends AquariumDto {
  const factory _AquariumDto({
    required final String id,
    @JsonKey(name: 'owner_id') required final String userId,
    required final String name,
    final double? capacity,
    @JsonKey(name: 'water_type') final String waterType,
    @JsonKey(name: 'image_url') final String? imageUrl,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
  }) = _$AquariumDtoImpl;
  const _AquariumDto._() : super._();

  factory _AquariumDto.fromJson(Map<String, dynamic> json) =
      _$AquariumDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'owner_id')
  String get userId;
  @override
  String get name;
  @override
  double? get capacity;
  @override
  @JsonKey(name: 'water_type')
  String get waterType;
  @override
  @JsonKey(name: 'image_url')
  String? get imageUrl;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$AquariumDtoImplCopyWith<_$AquariumDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CreateAquariumRequestDto _$CreateAquariumRequestDtoFromJson(
  Map<String, dynamic> json,
) {
  return _CreateAquariumRequestDto.fromJson(json);
}

/// @nodoc
mixin _$CreateAquariumRequestDto {
  String get name => throw _privateConstructorUsedError;
  double? get capacity => throw _privateConstructorUsedError;
  @JsonKey(name: 'water_type')
  String? get waterType => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CreateAquariumRequestDtoCopyWith<CreateAquariumRequestDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreateAquariumRequestDtoCopyWith<$Res> {
  factory $CreateAquariumRequestDtoCopyWith(
    CreateAquariumRequestDto value,
    $Res Function(CreateAquariumRequestDto) then,
  ) = _$CreateAquariumRequestDtoCopyWithImpl<$Res, CreateAquariumRequestDto>;
  @useResult
  $Res call({
    String name,
    double? capacity,
    @JsonKey(name: 'water_type') String? waterType,
  });
}

/// @nodoc
class _$CreateAquariumRequestDtoCopyWithImpl<
  $Res,
  $Val extends CreateAquariumRequestDto
>
    implements $CreateAquariumRequestDtoCopyWith<$Res> {
  _$CreateAquariumRequestDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? capacity = freezed,
    Object? waterType = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            capacity: freezed == capacity
                ? _value.capacity
                : capacity // ignore: cast_nullable_to_non_nullable
                      as double?,
            waterType: freezed == waterType
                ? _value.waterType
                : waterType // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreateAquariumRequestDtoImplCopyWith<$Res>
    implements $CreateAquariumRequestDtoCopyWith<$Res> {
  factory _$$CreateAquariumRequestDtoImplCopyWith(
    _$CreateAquariumRequestDtoImpl value,
    $Res Function(_$CreateAquariumRequestDtoImpl) then,
  ) = __$$CreateAquariumRequestDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    double? capacity,
    @JsonKey(name: 'water_type') String? waterType,
  });
}

/// @nodoc
class __$$CreateAquariumRequestDtoImplCopyWithImpl<$Res>
    extends
        _$CreateAquariumRequestDtoCopyWithImpl<
          $Res,
          _$CreateAquariumRequestDtoImpl
        >
    implements _$$CreateAquariumRequestDtoImplCopyWith<$Res> {
  __$$CreateAquariumRequestDtoImplCopyWithImpl(
    _$CreateAquariumRequestDtoImpl _value,
    $Res Function(_$CreateAquariumRequestDtoImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? capacity = freezed,
    Object? waterType = freezed,
  }) {
    return _then(
      _$CreateAquariumRequestDtoImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        capacity: freezed == capacity
            ? _value.capacity
            : capacity // ignore: cast_nullable_to_non_nullable
                  as double?,
        waterType: freezed == waterType
            ? _value.waterType
            : waterType // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreateAquariumRequestDtoImpl implements _CreateAquariumRequestDto {
  const _$CreateAquariumRequestDtoImpl({
    required this.name,
    this.capacity,
    @JsonKey(name: 'water_type') this.waterType,
  });

  factory _$CreateAquariumRequestDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreateAquariumRequestDtoImplFromJson(json);

  @override
  final String name;
  @override
  final double? capacity;
  @override
  @JsonKey(name: 'water_type')
  final String? waterType;

  @override
  String toString() {
    return 'CreateAquariumRequestDto(name: $name, capacity: $capacity, waterType: $waterType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateAquariumRequestDtoImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.capacity, capacity) ||
                other.capacity == capacity) &&
            (identical(other.waterType, waterType) ||
                other.waterType == waterType));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, capacity, waterType);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateAquariumRequestDtoImplCopyWith<_$CreateAquariumRequestDtoImpl>
  get copyWith =>
      __$$CreateAquariumRequestDtoImplCopyWithImpl<
        _$CreateAquariumRequestDtoImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreateAquariumRequestDtoImplToJson(this);
  }
}

abstract class _CreateAquariumRequestDto implements CreateAquariumRequestDto {
  const factory _CreateAquariumRequestDto({
    required final String name,
    final double? capacity,
    @JsonKey(name: 'water_type') final String? waterType,
  }) = _$CreateAquariumRequestDtoImpl;

  factory _CreateAquariumRequestDto.fromJson(Map<String, dynamic> json) =
      _$CreateAquariumRequestDtoImpl.fromJson;

  @override
  String get name;
  @override
  double? get capacity;
  @override
  @JsonKey(name: 'water_type')
  String? get waterType;
  @override
  @JsonKey(ignore: true)
  _$$CreateAquariumRequestDtoImplCopyWith<_$CreateAquariumRequestDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}

UpdateAquariumRequestDto _$UpdateAquariumRequestDtoFromJson(
  Map<String, dynamic> json,
) {
  return _UpdateAquariumRequestDto.fromJson(json);
}

/// @nodoc
mixin _$UpdateAquariumRequestDto {
  String? get name => throw _privateConstructorUsedError;
  double? get capacity => throw _privateConstructorUsedError;
  @JsonKey(name: 'water_type')
  String? get waterType => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String? get imageUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UpdateAquariumRequestDtoCopyWith<UpdateAquariumRequestDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpdateAquariumRequestDtoCopyWith<$Res> {
  factory $UpdateAquariumRequestDtoCopyWith(
    UpdateAquariumRequestDto value,
    $Res Function(UpdateAquariumRequestDto) then,
  ) = _$UpdateAquariumRequestDtoCopyWithImpl<$Res, UpdateAquariumRequestDto>;
  @useResult
  $Res call({
    String? name,
    double? capacity,
    @JsonKey(name: 'water_type') String? waterType,
    @JsonKey(name: 'image_url') String? imageUrl,
  });
}

/// @nodoc
class _$UpdateAquariumRequestDtoCopyWithImpl<
  $Res,
  $Val extends UpdateAquariumRequestDto
>
    implements $UpdateAquariumRequestDtoCopyWith<$Res> {
  _$UpdateAquariumRequestDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? capacity = freezed,
    Object? waterType = freezed,
    Object? imageUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            capacity: freezed == capacity
                ? _value.capacity
                : capacity // ignore: cast_nullable_to_non_nullable
                      as double?,
            waterType: freezed == waterType
                ? _value.waterType
                : waterType // ignore: cast_nullable_to_non_nullable
                      as String?,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UpdateAquariumRequestDtoImplCopyWith<$Res>
    implements $UpdateAquariumRequestDtoCopyWith<$Res> {
  factory _$$UpdateAquariumRequestDtoImplCopyWith(
    _$UpdateAquariumRequestDtoImpl value,
    $Res Function(_$UpdateAquariumRequestDtoImpl) then,
  ) = __$$UpdateAquariumRequestDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? name,
    double? capacity,
    @JsonKey(name: 'water_type') String? waterType,
    @JsonKey(name: 'image_url') String? imageUrl,
  });
}

/// @nodoc
class __$$UpdateAquariumRequestDtoImplCopyWithImpl<$Res>
    extends
        _$UpdateAquariumRequestDtoCopyWithImpl<
          $Res,
          _$UpdateAquariumRequestDtoImpl
        >
    implements _$$UpdateAquariumRequestDtoImplCopyWith<$Res> {
  __$$UpdateAquariumRequestDtoImplCopyWithImpl(
    _$UpdateAquariumRequestDtoImpl _value,
    $Res Function(_$UpdateAquariumRequestDtoImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = freezed,
    Object? capacity = freezed,
    Object? waterType = freezed,
    Object? imageUrl = freezed,
  }) {
    return _then(
      _$UpdateAquariumRequestDtoImpl(
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        capacity: freezed == capacity
            ? _value.capacity
            : capacity // ignore: cast_nullable_to_non_nullable
                  as double?,
        waterType: freezed == waterType
            ? _value.waterType
            : waterType // ignore: cast_nullable_to_non_nullable
                  as String?,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UpdateAquariumRequestDtoImpl implements _UpdateAquariumRequestDto {
  const _$UpdateAquariumRequestDtoImpl({
    this.name,
    this.capacity,
    @JsonKey(name: 'water_type') this.waterType,
    @JsonKey(name: 'image_url') this.imageUrl,
  });

  factory _$UpdateAquariumRequestDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$UpdateAquariumRequestDtoImplFromJson(json);

  @override
  final String? name;
  @override
  final double? capacity;
  @override
  @JsonKey(name: 'water_type')
  final String? waterType;
  @override
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @override
  String toString() {
    return 'UpdateAquariumRequestDto(name: $name, capacity: $capacity, waterType: $waterType, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateAquariumRequestDtoImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.capacity, capacity) ||
                other.capacity == capacity) &&
            (identical(other.waterType, waterType) ||
                other.waterType == waterType) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, capacity, waterType, imageUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateAquariumRequestDtoImplCopyWith<_$UpdateAquariumRequestDtoImpl>
  get copyWith =>
      __$$UpdateAquariumRequestDtoImplCopyWithImpl<
        _$UpdateAquariumRequestDtoImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UpdateAquariumRequestDtoImplToJson(this);
  }
}

abstract class _UpdateAquariumRequestDto implements UpdateAquariumRequestDto {
  const factory _UpdateAquariumRequestDto({
    final String? name,
    final double? capacity,
    @JsonKey(name: 'water_type') final String? waterType,
    @JsonKey(name: 'image_url') final String? imageUrl,
  }) = _$UpdateAquariumRequestDtoImpl;

  factory _UpdateAquariumRequestDto.fromJson(Map<String, dynamic> json) =
      _$UpdateAquariumRequestDtoImpl.fromJson;

  @override
  String? get name;
  @override
  double? get capacity;
  @override
  @JsonKey(name: 'water_type')
  String? get waterType;
  @override
  @JsonKey(name: 'image_url')
  String? get imageUrl;
  @override
  @JsonKey(ignore: true)
  _$$UpdateAquariumRequestDtoImplCopyWith<_$UpdateAquariumRequestDtoImpl>
  get copyWith => throw _privateConstructorUsedError;
}
