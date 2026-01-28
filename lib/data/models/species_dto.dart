import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:fishfeed/domain/entities/species.dart';

part 'species_dto.freezed.dart';
part 'species_dto.g.dart';

/// DTO for species data from the API.
///
/// Maps to the JSON response from /species endpoints.
@freezed
class SpeciesDto with _$SpeciesDto {
  const SpeciesDto._();

  const factory SpeciesDto({
    required String id,
    @JsonKey(name: 'common_name') required String commonName,
    @JsonKey(name: 'scientific_name') String? scientificName,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'food_types') @Default([]) List<String> foodTypes,
    @JsonKey(name: 'feeding_frequency') @Default(2) int feedingFrequency,
    @JsonKey(name: 'portion_hint') String? portionHint,
    @JsonKey(name: 'care_level') @Default('beginner') String careLevel,
    @JsonKey(name: 'water_type') @Default('freshwater') String waterType,
  }) = _SpeciesDto;

  factory SpeciesDto.fromJson(Map<String, dynamic> json) =>
      _$SpeciesDtoFromJson(json);

  /// Converts DTO to domain entity.
  Species toEntity() {
    return Species(
      id: id,
      name: commonName,
      imageUrl: imageUrl,
      feedingFrequency: _mapFeedingFrequency(feedingFrequency),
      foodType: _mapFoodType(foodTypes),
      portionHint: _mapPortionHint(portionHint),
      careLevel: careLevel,
    );
  }

  /// Maps feeding frequency integer to string representation.
  String _mapFeedingFrequency(int frequency) {
    switch (frequency) {
      case 1:
        return 'daily';
      case 2:
        return 'twice_daily';
      case 3:
        return 'three_times_daily';
      default:
        return 'twice_daily';
    }
  }

  /// Maps food type strings from API to FoodType enum.
  FoodType _mapFoodType(List<String> types) {
    if (types.isEmpty) return FoodType.flakes;

    final primary = types.first.toLowerCase();
    switch (primary) {
      case 'flakes':
        return FoodType.flakes;
      case 'pellets':
        return FoodType.pellets;
      case 'live':
        return FoodType.live;
      case 'frozen':
        return FoodType.frozen;
      default:
        return types.length > 1 ? FoodType.mixed : FoodType.flakes;
    }
  }

  /// Maps portion hint string to PortionHint enum.
  PortionHint _mapPortionHint(String? hint) {
    if (hint == null) return PortionHint.small;

    final lowerHint = hint.toLowerCase();
    if (lowerHint.contains('large')) return PortionHint.large;
    if (lowerHint.contains('medium')) return PortionHint.medium;
    return PortionHint.small;
  }
}

/// Response DTO for paginated species list.
@freezed
class SpeciesListResponseDto with _$SpeciesListResponseDto {
  const factory SpeciesListResponseDto({
    required List<SpeciesDto> items,
    required int total,
    required int page,
    @JsonKey(name: 'per_page') required int perPage,
    required int pages,
  }) = _SpeciesListResponseDto;

  factory SpeciesListResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SpeciesListResponseDtoFromJson(json);
}
