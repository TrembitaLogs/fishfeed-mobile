// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aquarium_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AquariumDtoImpl _$$AquariumDtoImplFromJson(Map<String, dynamic> json) =>
    _$AquariumDtoImpl(
      id: json['id'] as String,
      userId: json['owner_id'] as String,
      name: json['name'] as String,
      capacity: (json['capacity'] as num?)?.toDouble(),
      waterType: json['water_type'] as String? ?? 'freshwater',
      photoKey: json['photo_key'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$AquariumDtoImplToJson(_$AquariumDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.userId,
      'name': instance.name,
      'capacity': instance.capacity,
      'water_type': instance.waterType,
      'photo_key': instance.photoKey,
      'created_at': instance.createdAt.toIso8601String(),
    };

_$CreateAquariumRequestDtoImpl _$$CreateAquariumRequestDtoImplFromJson(
  Map<String, dynamic> json,
) => _$CreateAquariumRequestDtoImpl(
  name: json['name'] as String,
  capacity: (json['capacity'] as num?)?.toDouble(),
  waterType: json['water_type'] as String?,
);

Map<String, dynamic> _$$CreateAquariumRequestDtoImplToJson(
  _$CreateAquariumRequestDtoImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'capacity': instance.capacity,
  'water_type': instance.waterType,
};

_$UpdateAquariumRequestDtoImpl _$$UpdateAquariumRequestDtoImplFromJson(
  Map<String, dynamic> json,
) => _$UpdateAquariumRequestDtoImpl(
  name: json['name'] as String?,
  capacity: (json['capacity'] as num?)?.toDouble(),
  waterType: json['water_type'] as String?,
  photoKey: json['photo_key'] as String?,
);

Map<String, dynamic> _$$UpdateAquariumRequestDtoImplToJson(
  _$UpdateAquariumRequestDtoImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'capacity': instance.capacity,
  'water_type': instance.waterType,
  'photo_key': instance.photoKey,
};
