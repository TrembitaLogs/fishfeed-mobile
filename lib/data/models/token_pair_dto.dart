import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_pair_dto.freezed.dart';
part 'token_pair_dto.g.dart';

/// DTO for JWT token pair from the API.
///
/// Contains access and refresh tokens returned by auth endpoints.
@freezed
class TokenPairDto with _$TokenPairDto {
  const factory TokenPairDto({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'expires_in') int? expiresIn,
  }) = _TokenPairDto;

  factory TokenPairDto.fromJson(Map<String, dynamic> json) =>
      _$TokenPairDtoFromJson(json);
}
