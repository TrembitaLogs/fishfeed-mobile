// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_scan_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AiScanResultImpl _$$AiScanResultImplFromJson(Map<String, dynamic> json) =>
    _$AiScanResultImpl(
      speciesId: json['species_id'] as String,
      speciesName: json['species_name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      recommendations:
          (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      imageUrl: json['image_url'] as String?,
      feedingFrequency: json['feeding_frequency'] as String?,
      careLevel: json['care_level'] as String?,
    );

Map<String, dynamic> _$$AiScanResultImplToJson(_$AiScanResultImpl instance) =>
    <String, dynamic>{
      'species_id': instance.speciesId,
      'species_name': instance.speciesName,
      'confidence': instance.confidence,
      'recommendations': instance.recommendations,
      'image_url': instance.imageUrl,
      'feeding_frequency': instance.feedingFrequency,
      'care_level': instance.careLevel,
    };
