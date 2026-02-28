import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/water_type.dart';

part 'aquarium_dto.freezed.dart';
part 'aquarium_dto.g.dart';

/// DTO for aquarium data from the API.
///
/// Maps to the JSON response from /aquariums endpoints.
@freezed
class AquariumDto with _$AquariumDto {
  const AquariumDto._();

  const factory AquariumDto({
    required String id,
    @JsonKey(name: 'owner_id') required String userId,
    required String name,
    double? capacity,
    @JsonKey(name: 'water_type') @Default('freshwater') String waterType,
    @JsonKey(name: 'photo_key') String? photoKey,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _AquariumDto;

  factory AquariumDto.fromJson(Map<String, dynamic> json) =>
      _$AquariumDtoFromJson(json);

  /// Converts DTO to domain entity.
  Aquarium toEntity() {
    return Aquarium(
      id: id,
      userId: userId,
      name: name,
      capacity: capacity,
      waterType: _mapWaterType(waterType),
      photoKey: photoKey,
      createdAt: createdAt,
    );
  }

  /// Maps water type string from API to WaterType enum.
  WaterType _mapWaterType(String type) {
    return switch (type.toLowerCase()) {
      'saltwater' => WaterType.saltwater,
      'brackish' => WaterType.brackish,
      _ => WaterType.freshwater,
    };
  }
}

/// Request DTO for creating an aquarium.
@freezed
class CreateAquariumRequestDto with _$CreateAquariumRequestDto {
  const factory CreateAquariumRequestDto({
    required String name,
    double? capacity,
    @JsonKey(name: 'water_type') String? waterType,
  }) = _CreateAquariumRequestDto;

  factory CreateAquariumRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateAquariumRequestDtoFromJson(json);
}

/// Request DTO for updating an aquarium.
@freezed
class UpdateAquariumRequestDto with _$UpdateAquariumRequestDto {
  const factory UpdateAquariumRequestDto({
    String? name,
    double? capacity,
    @JsonKey(name: 'water_type') String? waterType,
    @JsonKey(name: 'photo_key') String? photoKey,
  }) = _UpdateAquariumRequestDto;

  factory UpdateAquariumRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateAquariumRequestDtoFromJson(json);
}
