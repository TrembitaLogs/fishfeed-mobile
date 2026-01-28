// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_scan_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AiScanResult _$AiScanResultFromJson(Map<String, dynamic> json) {
  return _AiScanResult.fromJson(json);
}

/// @nodoc
mixin _$AiScanResult {
  /// Unique identifier of the detected species.
  @JsonKey(name: 'species_id')
  String get speciesId => throw _privateConstructorUsedError;

  /// Common name of the detected species.
  @JsonKey(name: 'species_name')
  String get speciesName => throw _privateConstructorUsedError;

  /// Confidence score of the detection (0.0 to 1.0).
  double get confidence => throw _privateConstructorUsedError;

  /// AI-generated care recommendations for this species.
  List<String> get recommendations => throw _privateConstructorUsedError;

  /// Optional image URL for the detected species.
  @JsonKey(name: 'image_url')
  String? get imageUrl => throw _privateConstructorUsedError;

  /// Optional feeding frequency recommendation.
  @JsonKey(name: 'feeding_frequency')
  String? get feedingFrequency => throw _privateConstructorUsedError;

  /// Optional care level (beginner, intermediate, advanced).
  @JsonKey(name: 'care_level')
  String? get careLevel => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AiScanResultCopyWith<AiScanResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AiScanResultCopyWith<$Res> {
  factory $AiScanResultCopyWith(
    AiScanResult value,
    $Res Function(AiScanResult) then,
  ) = _$AiScanResultCopyWithImpl<$Res, AiScanResult>;
  @useResult
  $Res call({
    @JsonKey(name: 'species_id') String speciesId,
    @JsonKey(name: 'species_name') String speciesName,
    double confidence,
    List<String> recommendations,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'feeding_frequency') String? feedingFrequency,
    @JsonKey(name: 'care_level') String? careLevel,
  });
}

/// @nodoc
class _$AiScanResultCopyWithImpl<$Res, $Val extends AiScanResult>
    implements $AiScanResultCopyWith<$Res> {
  _$AiScanResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? speciesId = null,
    Object? speciesName = null,
    Object? confidence = null,
    Object? recommendations = null,
    Object? imageUrl = freezed,
    Object? feedingFrequency = freezed,
    Object? careLevel = freezed,
  }) {
    return _then(
      _value.copyWith(
            speciesId: null == speciesId
                ? _value.speciesId
                : speciesId // ignore: cast_nullable_to_non_nullable
                      as String,
            speciesName: null == speciesName
                ? _value.speciesName
                : speciesName // ignore: cast_nullable_to_non_nullable
                      as String,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
            recommendations: null == recommendations
                ? _value.recommendations
                : recommendations // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            feedingFrequency: freezed == feedingFrequency
                ? _value.feedingFrequency
                : feedingFrequency // ignore: cast_nullable_to_non_nullable
                      as String?,
            careLevel: freezed == careLevel
                ? _value.careLevel
                : careLevel // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AiScanResultImplCopyWith<$Res>
    implements $AiScanResultCopyWith<$Res> {
  factory _$$AiScanResultImplCopyWith(
    _$AiScanResultImpl value,
    $Res Function(_$AiScanResultImpl) then,
  ) = __$$AiScanResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'species_id') String speciesId,
    @JsonKey(name: 'species_name') String speciesName,
    double confidence,
    List<String> recommendations,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'feeding_frequency') String? feedingFrequency,
    @JsonKey(name: 'care_level') String? careLevel,
  });
}

/// @nodoc
class __$$AiScanResultImplCopyWithImpl<$Res>
    extends _$AiScanResultCopyWithImpl<$Res, _$AiScanResultImpl>
    implements _$$AiScanResultImplCopyWith<$Res> {
  __$$AiScanResultImplCopyWithImpl(
    _$AiScanResultImpl _value,
    $Res Function(_$AiScanResultImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? speciesId = null,
    Object? speciesName = null,
    Object? confidence = null,
    Object? recommendations = null,
    Object? imageUrl = freezed,
    Object? feedingFrequency = freezed,
    Object? careLevel = freezed,
  }) {
    return _then(
      _$AiScanResultImpl(
        speciesId: null == speciesId
            ? _value.speciesId
            : speciesId // ignore: cast_nullable_to_non_nullable
                  as String,
        speciesName: null == speciesName
            ? _value.speciesName
            : speciesName // ignore: cast_nullable_to_non_nullable
                  as String,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        recommendations: null == recommendations
            ? _value._recommendations
            : recommendations // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        feedingFrequency: freezed == feedingFrequency
            ? _value.feedingFrequency
            : feedingFrequency // ignore: cast_nullable_to_non_nullable
                  as String?,
        careLevel: freezed == careLevel
            ? _value.careLevel
            : careLevel // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AiScanResultImpl extends _AiScanResult {
  const _$AiScanResultImpl({
    @JsonKey(name: 'species_id') required this.speciesId,
    @JsonKey(name: 'species_name') required this.speciesName,
    required this.confidence,
    final List<String> recommendations = const [],
    @JsonKey(name: 'image_url') this.imageUrl,
    @JsonKey(name: 'feeding_frequency') this.feedingFrequency,
    @JsonKey(name: 'care_level') this.careLevel,
  }) : _recommendations = recommendations,
       super._();

  factory _$AiScanResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$AiScanResultImplFromJson(json);

  /// Unique identifier of the detected species.
  @override
  @JsonKey(name: 'species_id')
  final String speciesId;

  /// Common name of the detected species.
  @override
  @JsonKey(name: 'species_name')
  final String speciesName;

  /// Confidence score of the detection (0.0 to 1.0).
  @override
  final double confidence;

  /// AI-generated care recommendations for this species.
  final List<String> _recommendations;

  /// AI-generated care recommendations for this species.
  @override
  @JsonKey()
  List<String> get recommendations {
    if (_recommendations is EqualUnmodifiableListView) return _recommendations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recommendations);
  }

  /// Optional image URL for the detected species.
  @override
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  /// Optional feeding frequency recommendation.
  @override
  @JsonKey(name: 'feeding_frequency')
  final String? feedingFrequency;

  /// Optional care level (beginner, intermediate, advanced).
  @override
  @JsonKey(name: 'care_level')
  final String? careLevel;

  @override
  String toString() {
    return 'AiScanResult(speciesId: $speciesId, speciesName: $speciesName, confidence: $confidence, recommendations: $recommendations, imageUrl: $imageUrl, feedingFrequency: $feedingFrequency, careLevel: $careLevel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AiScanResultImpl &&
            (identical(other.speciesId, speciesId) ||
                other.speciesId == speciesId) &&
            (identical(other.speciesName, speciesName) ||
                other.speciesName == speciesName) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            const DeepCollectionEquality().equals(
              other._recommendations,
              _recommendations,
            ) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.feedingFrequency, feedingFrequency) ||
                other.feedingFrequency == feedingFrequency) &&
            (identical(other.careLevel, careLevel) ||
                other.careLevel == careLevel));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    speciesId,
    speciesName,
    confidence,
    const DeepCollectionEquality().hash(_recommendations),
    imageUrl,
    feedingFrequency,
    careLevel,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AiScanResultImplCopyWith<_$AiScanResultImpl> get copyWith =>
      __$$AiScanResultImplCopyWithImpl<_$AiScanResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AiScanResultImplToJson(this);
  }
}

abstract class _AiScanResult extends AiScanResult {
  const factory _AiScanResult({
    @JsonKey(name: 'species_id') required final String speciesId,
    @JsonKey(name: 'species_name') required final String speciesName,
    required final double confidence,
    final List<String> recommendations,
    @JsonKey(name: 'image_url') final String? imageUrl,
    @JsonKey(name: 'feeding_frequency') final String? feedingFrequency,
    @JsonKey(name: 'care_level') final String? careLevel,
  }) = _$AiScanResultImpl;
  const _AiScanResult._() : super._();

  factory _AiScanResult.fromJson(Map<String, dynamic> json) =
      _$AiScanResultImpl.fromJson;

  @override
  /// Unique identifier of the detected species.
  @JsonKey(name: 'species_id')
  String get speciesId;
  @override
  /// Common name of the detected species.
  @JsonKey(name: 'species_name')
  String get speciesName;
  @override
  /// Confidence score of the detection (0.0 to 1.0).
  double get confidence;
  @override
  /// AI-generated care recommendations for this species.
  List<String> get recommendations;
  @override
  /// Optional image URL for the detected species.
  @JsonKey(name: 'image_url')
  String? get imageUrl;
  @override
  /// Optional feeding frequency recommendation.
  @JsonKey(name: 'feeding_frequency')
  String? get feedingFrequency;
  @override
  /// Optional care level (beginner, intermediate, advanced).
  @JsonKey(name: 'care_level')
  String? get careLevel;
  @override
  @JsonKey(ignore: true)
  _$$AiScanResultImplCopyWith<_$AiScanResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
