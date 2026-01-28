// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'species_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SpeciesDto _$SpeciesDtoFromJson(Map<String, dynamic> json) {
  return _SpeciesDto.fromJson(json);
}

/// @nodoc
mixin _$SpeciesDto {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'common_name')
  String get commonName => throw _privateConstructorUsedError;
  @JsonKey(name: 'scientific_name')
  String? get scientificName => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String? get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'food_types')
  List<String> get foodTypes => throw _privateConstructorUsedError;
  @JsonKey(name: 'feeding_frequency')
  int get feedingFrequency => throw _privateConstructorUsedError;
  @JsonKey(name: 'portion_hint')
  String? get portionHint => throw _privateConstructorUsedError;
  @JsonKey(name: 'care_level')
  String get careLevel => throw _privateConstructorUsedError;
  @JsonKey(name: 'water_type')
  String get waterType => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SpeciesDtoCopyWith<SpeciesDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpeciesDtoCopyWith<$Res> {
  factory $SpeciesDtoCopyWith(
          SpeciesDto value, $Res Function(SpeciesDto) then) =
      _$SpeciesDtoCopyWithImpl<$Res, SpeciesDto>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'common_name') String commonName,
      @JsonKey(name: 'scientific_name') String? scientificName,
      @JsonKey(name: 'image_url') String? imageUrl,
      @JsonKey(name: 'food_types') List<String> foodTypes,
      @JsonKey(name: 'feeding_frequency') int feedingFrequency,
      @JsonKey(name: 'portion_hint') String? portionHint,
      @JsonKey(name: 'care_level') String careLevel,
      @JsonKey(name: 'water_type') String waterType});
}

/// @nodoc
class _$SpeciesDtoCopyWithImpl<$Res, $Val extends SpeciesDto>
    implements $SpeciesDtoCopyWith<$Res> {
  _$SpeciesDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? commonName = null,
    Object? scientificName = freezed,
    Object? imageUrl = freezed,
    Object? foodTypes = null,
    Object? feedingFrequency = null,
    Object? portionHint = freezed,
    Object? careLevel = null,
    Object? waterType = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      commonName: null == commonName
          ? _value.commonName
          : commonName // ignore: cast_nullable_to_non_nullable
              as String,
      scientificName: freezed == scientificName
          ? _value.scientificName
          : scientificName // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      foodTypes: null == foodTypes
          ? _value.foodTypes
          : foodTypes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      feedingFrequency: null == feedingFrequency
          ? _value.feedingFrequency
          : feedingFrequency // ignore: cast_nullable_to_non_nullable
              as int,
      portionHint: freezed == portionHint
          ? _value.portionHint
          : portionHint // ignore: cast_nullable_to_non_nullable
              as String?,
      careLevel: null == careLevel
          ? _value.careLevel
          : careLevel // ignore: cast_nullable_to_non_nullable
              as String,
      waterType: null == waterType
          ? _value.waterType
          : waterType // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SpeciesDtoImplCopyWith<$Res>
    implements $SpeciesDtoCopyWith<$Res> {
  factory _$$SpeciesDtoImplCopyWith(
          _$SpeciesDtoImpl value, $Res Function(_$SpeciesDtoImpl) then) =
      __$$SpeciesDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'common_name') String commonName,
      @JsonKey(name: 'scientific_name') String? scientificName,
      @JsonKey(name: 'image_url') String? imageUrl,
      @JsonKey(name: 'food_types') List<String> foodTypes,
      @JsonKey(name: 'feeding_frequency') int feedingFrequency,
      @JsonKey(name: 'portion_hint') String? portionHint,
      @JsonKey(name: 'care_level') String careLevel,
      @JsonKey(name: 'water_type') String waterType});
}

/// @nodoc
class __$$SpeciesDtoImplCopyWithImpl<$Res>
    extends _$SpeciesDtoCopyWithImpl<$Res, _$SpeciesDtoImpl>
    implements _$$SpeciesDtoImplCopyWith<$Res> {
  __$$SpeciesDtoImplCopyWithImpl(
      _$SpeciesDtoImpl _value, $Res Function(_$SpeciesDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? commonName = null,
    Object? scientificName = freezed,
    Object? imageUrl = freezed,
    Object? foodTypes = null,
    Object? feedingFrequency = null,
    Object? portionHint = freezed,
    Object? careLevel = null,
    Object? waterType = null,
  }) {
    return _then(_$SpeciesDtoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      commonName: null == commonName
          ? _value.commonName
          : commonName // ignore: cast_nullable_to_non_nullable
              as String,
      scientificName: freezed == scientificName
          ? _value.scientificName
          : scientificName // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      foodTypes: null == foodTypes
          ? _value._foodTypes
          : foodTypes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      feedingFrequency: null == feedingFrequency
          ? _value.feedingFrequency
          : feedingFrequency // ignore: cast_nullable_to_non_nullable
              as int,
      portionHint: freezed == portionHint
          ? _value.portionHint
          : portionHint // ignore: cast_nullable_to_non_nullable
              as String?,
      careLevel: null == careLevel
          ? _value.careLevel
          : careLevel // ignore: cast_nullable_to_non_nullable
              as String,
      waterType: null == waterType
          ? _value.waterType
          : waterType // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SpeciesDtoImpl extends _SpeciesDto {
  const _$SpeciesDtoImpl(
      {required this.id,
      @JsonKey(name: 'common_name') required this.commonName,
      @JsonKey(name: 'scientific_name') this.scientificName,
      @JsonKey(name: 'image_url') this.imageUrl,
      @JsonKey(name: 'food_types') final List<String> foodTypes = const [],
      @JsonKey(name: 'feeding_frequency') this.feedingFrequency = 2,
      @JsonKey(name: 'portion_hint') this.portionHint,
      @JsonKey(name: 'care_level') this.careLevel = 'beginner',
      @JsonKey(name: 'water_type') this.waterType = 'freshwater'})
      : _foodTypes = foodTypes,
        super._();

  factory _$SpeciesDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpeciesDtoImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'common_name')
  final String commonName;
  @override
  @JsonKey(name: 'scientific_name')
  final String? scientificName;
  @override
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final List<String> _foodTypes;
  @override
  @JsonKey(name: 'food_types')
  List<String> get foodTypes {
    if (_foodTypes is EqualUnmodifiableListView) return _foodTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_foodTypes);
  }

  @override
  @JsonKey(name: 'feeding_frequency')
  final int feedingFrequency;
  @override
  @JsonKey(name: 'portion_hint')
  final String? portionHint;
  @override
  @JsonKey(name: 'care_level')
  final String careLevel;
  @override
  @JsonKey(name: 'water_type')
  final String waterType;

  @override
  String toString() {
    return 'SpeciesDto(id: $id, commonName: $commonName, scientificName: $scientificName, imageUrl: $imageUrl, foodTypes: $foodTypes, feedingFrequency: $feedingFrequency, portionHint: $portionHint, careLevel: $careLevel, waterType: $waterType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpeciesDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.commonName, commonName) ||
                other.commonName == commonName) &&
            (identical(other.scientificName, scientificName) ||
                other.scientificName == scientificName) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            const DeepCollectionEquality()
                .equals(other._foodTypes, _foodTypes) &&
            (identical(other.feedingFrequency, feedingFrequency) ||
                other.feedingFrequency == feedingFrequency) &&
            (identical(other.portionHint, portionHint) ||
                other.portionHint == portionHint) &&
            (identical(other.careLevel, careLevel) ||
                other.careLevel == careLevel) &&
            (identical(other.waterType, waterType) ||
                other.waterType == waterType));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      commonName,
      scientificName,
      imageUrl,
      const DeepCollectionEquality().hash(_foodTypes),
      feedingFrequency,
      portionHint,
      careLevel,
      waterType);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SpeciesDtoImplCopyWith<_$SpeciesDtoImpl> get copyWith =>
      __$$SpeciesDtoImplCopyWithImpl<_$SpeciesDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SpeciesDtoImplToJson(
      this,
    );
  }
}

abstract class _SpeciesDto extends SpeciesDto {
  const factory _SpeciesDto(
      {required final String id,
      @JsonKey(name: 'common_name') required final String commonName,
      @JsonKey(name: 'scientific_name') final String? scientificName,
      @JsonKey(name: 'image_url') final String? imageUrl,
      @JsonKey(name: 'food_types') final List<String> foodTypes,
      @JsonKey(name: 'feeding_frequency') final int feedingFrequency,
      @JsonKey(name: 'portion_hint') final String? portionHint,
      @JsonKey(name: 'care_level') final String careLevel,
      @JsonKey(name: 'water_type') final String waterType}) = _$SpeciesDtoImpl;
  const _SpeciesDto._() : super._();

  factory _SpeciesDto.fromJson(Map<String, dynamic> json) =
      _$SpeciesDtoImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'common_name')
  String get commonName;
  @override
  @JsonKey(name: 'scientific_name')
  String? get scientificName;
  @override
  @JsonKey(name: 'image_url')
  String? get imageUrl;
  @override
  @JsonKey(name: 'food_types')
  List<String> get foodTypes;
  @override
  @JsonKey(name: 'feeding_frequency')
  int get feedingFrequency;
  @override
  @JsonKey(name: 'portion_hint')
  String? get portionHint;
  @override
  @JsonKey(name: 'care_level')
  String get careLevel;
  @override
  @JsonKey(name: 'water_type')
  String get waterType;
  @override
  @JsonKey(ignore: true)
  _$$SpeciesDtoImplCopyWith<_$SpeciesDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SpeciesListResponseDto _$SpeciesListResponseDtoFromJson(
    Map<String, dynamic> json) {
  return _SpeciesListResponseDto.fromJson(json);
}

/// @nodoc
mixin _$SpeciesListResponseDto {
  List<SpeciesDto> get items => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  @JsonKey(name: 'per_page')
  int get perPage => throw _privateConstructorUsedError;
  int get pages => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SpeciesListResponseDtoCopyWith<SpeciesListResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpeciesListResponseDtoCopyWith<$Res> {
  factory $SpeciesListResponseDtoCopyWith(SpeciesListResponseDto value,
          $Res Function(SpeciesListResponseDto) then) =
      _$SpeciesListResponseDtoCopyWithImpl<$Res, SpeciesListResponseDto>;
  @useResult
  $Res call(
      {List<SpeciesDto> items,
      int total,
      int page,
      @JsonKey(name: 'per_page') int perPage,
      int pages});
}

/// @nodoc
class _$SpeciesListResponseDtoCopyWithImpl<$Res,
        $Val extends SpeciesListResponseDto>
    implements $SpeciesListResponseDtoCopyWith<$Res> {
  _$SpeciesListResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? page = null,
    Object? perPage = null,
    Object? pages = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<SpeciesDto>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      perPage: null == perPage
          ? _value.perPage
          : perPage // ignore: cast_nullable_to_non_nullable
              as int,
      pages: null == pages
          ? _value.pages
          : pages // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SpeciesListResponseDtoImplCopyWith<$Res>
    implements $SpeciesListResponseDtoCopyWith<$Res> {
  factory _$$SpeciesListResponseDtoImplCopyWith(
          _$SpeciesListResponseDtoImpl value,
          $Res Function(_$SpeciesListResponseDtoImpl) then) =
      __$$SpeciesListResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<SpeciesDto> items,
      int total,
      int page,
      @JsonKey(name: 'per_page') int perPage,
      int pages});
}

/// @nodoc
class __$$SpeciesListResponseDtoImplCopyWithImpl<$Res>
    extends _$SpeciesListResponseDtoCopyWithImpl<$Res,
        _$SpeciesListResponseDtoImpl>
    implements _$$SpeciesListResponseDtoImplCopyWith<$Res> {
  __$$SpeciesListResponseDtoImplCopyWithImpl(
      _$SpeciesListResponseDtoImpl _value,
      $Res Function(_$SpeciesListResponseDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? page = null,
    Object? perPage = null,
    Object? pages = null,
  }) {
    return _then(_$SpeciesListResponseDtoImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<SpeciesDto>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      perPage: null == perPage
          ? _value.perPage
          : perPage // ignore: cast_nullable_to_non_nullable
              as int,
      pages: null == pages
          ? _value.pages
          : pages // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SpeciesListResponseDtoImpl implements _SpeciesListResponseDto {
  const _$SpeciesListResponseDtoImpl(
      {required final List<SpeciesDto> items,
      required this.total,
      required this.page,
      @JsonKey(name: 'per_page') required this.perPage,
      required this.pages})
      : _items = items;

  factory _$SpeciesListResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$SpeciesListResponseDtoImplFromJson(json);

  final List<SpeciesDto> _items;
  @override
  List<SpeciesDto> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final int total;
  @override
  final int page;
  @override
  @JsonKey(name: 'per_page')
  final int perPage;
  @override
  final int pages;

  @override
  String toString() {
    return 'SpeciesListResponseDto(items: $items, total: $total, page: $page, perPage: $perPage, pages: $pages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SpeciesListResponseDtoImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.perPage, perPage) || other.perPage == perPage) &&
            (identical(other.pages, pages) || other.pages == pages));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), total, page, perPage, pages);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SpeciesListResponseDtoImplCopyWith<_$SpeciesListResponseDtoImpl>
      get copyWith => __$$SpeciesListResponseDtoImplCopyWithImpl<
          _$SpeciesListResponseDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SpeciesListResponseDtoImplToJson(
      this,
    );
  }
}

abstract class _SpeciesListResponseDto implements SpeciesListResponseDto {
  const factory _SpeciesListResponseDto(
      {required final List<SpeciesDto> items,
      required final int total,
      required final int page,
      @JsonKey(name: 'per_page') required final int perPage,
      required final int pages}) = _$SpeciesListResponseDtoImpl;

  factory _SpeciesListResponseDto.fromJson(Map<String, dynamic> json) =
      _$SpeciesListResponseDtoImpl.fromJson;

  @override
  List<SpeciesDto> get items;
  @override
  int get total;
  @override
  int get page;
  @override
  @JsonKey(name: 'per_page')
  int get perPage;
  @override
  int get pages;
  @override
  @JsonKey(ignore: true)
  _$$SpeciesListResponseDtoImplCopyWith<_$SpeciesListResponseDtoImpl>
      get copyWith => throw _privateConstructorUsedError;
}
