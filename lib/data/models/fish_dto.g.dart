// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fish_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FishDtoImpl _$$FishDtoImplFromJson(Map<String, dynamic> json) =>
    _$FishDtoImpl(
      id: json['id'] as String,
      aquariumId: json['aquarium_id'] as String,
      speciesId: json['species_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
      customName: json['custom_name'] as String?,
      addedVia: json['added_via'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$FishDtoImplToJson(_$FishDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'aquarium_id': instance.aquariumId,
      'species_id': instance.speciesId,
      'quantity': instance.quantity,
      'custom_name': instance.customName,
      'added_via': instance.addedVia,
      'created_at': instance.createdAt.toIso8601String(),
    };
