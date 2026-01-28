import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

/// DTO for user data from the API.
///
/// Maps to the JSON response from auth endpoints.
/// Use [toMap] for converting back to JSON if needed.
@freezed
class UserDto with _$UserDto {
  const factory UserDto({
    required String id,
    required String email,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'subscription_status') @Default('free') String subscriptionStatus,
    @JsonKey(name: 'free_ai_scans_remaining') @Default(5) int freeAiScansRemaining,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);
}
