import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:fishfeed/domain/entities/family_invite.dart';

part 'family_invite_dto.freezed.dart';
part 'family_invite_dto.g.dart';

/// DTO for family invitation data from the API.
///
/// Maps to backend's `InviteResponse` (create) and `InviteDetailResponse` (list).
@freezed
class FamilyInviteDto with _$FamilyInviteDto {
  const FamilyInviteDto._();

  const factory FamilyInviteDto({
    String? id,
    @JsonKey(name: 'invite_code') required String inviteCode,
    @JsonKey(name: 'invite_link') required String inviteLink,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
  }) = _FamilyInviteDto;

  factory FamilyInviteDto.fromJson(Map<String, dynamic> json) =>
      _$FamilyInviteDtoFromJson(json);

  /// Converts this DTO to a domain entity.
  ///
  /// [aquariumId] and [createdBy] must be provided from context
  /// since the create-invite response doesn't include them.
  FamilyInvite toEntity({
    required String aquariumId,
    required String createdBy,
  }) {
    return FamilyInvite(
      id: id ?? inviteCode,
      aquariumId: aquariumId,
      inviteCode: inviteCode,
      createdBy: createdBy,
      createdAt: createdAt ?? DateTime.now(),
      expiresAt: expiresAt,
      status: FamilyInviteStatus.pending,
    );
  }
}
