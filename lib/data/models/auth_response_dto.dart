import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:fishfeed/data/models/token_pair_dto.dart';
import 'package:fishfeed/data/models/user_dto.dart';

part 'auth_response_dto.freezed.dart';
part 'auth_response_dto.g.dart';

/// DTO for authentication response from the API.
///
/// Contains user data and JWT tokens returned by login/register endpoints.
@freezed
class AuthResponseDto with _$AuthResponseDto {
  const AuthResponseDto._();

  const factory AuthResponseDto({
    required UserDto user,
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
  }) = _AuthResponseDto;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);

  /// Returns tokens as TokenPairDto for compatibility.
  TokenPairDto get tokens => TokenPairDto(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
}
