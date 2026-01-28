// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'species_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SpeciesDtoImpl _$$SpeciesDtoImplFromJson(Map<String, dynamic> json) =>
    _$SpeciesDtoImpl(
      id: json['id'] as String,
      commonName: json['common_name'] as String,
      scientificName: json['scientific_name'] as String?,
      imageUrl: json['image_url'] as String?,
      foodTypes:
          (json['food_types'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      feedingFrequency: (json['feeding_frequency'] as num?)?.toInt() ?? 2,
      portionHint: json['portion_hint'] as String?,
      careLevel: json['care_level'] as String? ?? 'beginner',
      waterType: json['water_type'] as String? ?? 'freshwater',
    );

Map<String, dynamic> _$$SpeciesDtoImplToJson(_$SpeciesDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'common_name': instance.commonName,
      'scientific_name': instance.scientificName,
      'image_url': instance.imageUrl,
      'food_types': instance.foodTypes,
      'feeding_frequency': instance.feedingFrequency,
      'portion_hint': instance.portionHint,
      'care_level': instance.careLevel,
      'water_type': instance.waterType,
    };

_$SpeciesListResponseDtoImpl _$$SpeciesListResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$SpeciesListResponseDtoImpl(
  items: (json['items'] as List<dynamic>)
      .map((e) => SpeciesDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  perPage: (json['per_page'] as num).toInt(),
  pages: (json['pages'] as num).toInt(),
);

Map<String, dynamic> _$$SpeciesListResponseDtoImplToJson(
  _$SpeciesListResponseDtoImpl instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'total': instance.total,
  'page': instance.page,
  'per_page': instance.perPage,
  'pages': instance.pages,
};
