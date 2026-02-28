import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:fishfeed/data/models/fish_model.dart';

part 'fish_dto.freezed.dart';
part 'fish_dto.g.dart';

/// DTO for fish data from the API.
///
/// Maps to the JSON response from /aquariums/{id}/fish endpoints.
@freezed
class FishDto with _$FishDto {
  const FishDto._();

  const factory FishDto({
    required String id,
    @JsonKey(name: 'aquarium_id') required String aquariumId,
    @JsonKey(name: 'species_id') required String speciesId,
    required int quantity,
    @JsonKey(name: 'custom_name') String? customName,
    @JsonKey(name: 'photo_key') String? photoKey,
    @JsonKey(name: 'added_via') String? addedVia,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _FishDto;

  factory FishDto.fromJson(Map<String, dynamic> json) =>
      _$FishDtoFromJson(json);

  /// Converts DTO to local Hive model.
  FishModel toModel() {
    return FishModel(
      id: id,
      aquariumId: aquariumId,
      speciesId: speciesId,
      name: customName,
      quantity: quantity,
      photoKey: photoKey,
      addedAt: createdAt,
    );
  }
}
