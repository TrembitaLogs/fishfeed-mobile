import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:fishfeed/domain/entities/family_invite.dart';

part 'family_invite_dto.freezed.dart';
part 'family_invite_dto.g.dart';

/// DTO for family invitation data from the API.
@freezed
class FamilyInviteDto with _$FamilyInviteDto {
  const FamilyInviteDto._();

  const factory FamilyInviteDto({
    required String id,
    @JsonKey(name: 'aquarium_id') required String aquariumId,
    @JsonKey(name: 'invite_code') required String inviteCode,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
    @Default('pending') String status,
    @JsonKey(name: 'accepted_by') String? acceptedBy,
    @JsonKey(name: 'accepted_at') DateTime? acceptedAt,
  }) = _FamilyInviteDto;

  factory FamilyInviteDto.fromJson(Map<String, dynamic> json) =>
      _$FamilyInviteDtoFromJson(json);

  /// Converts this DTO to a domain entity.
  FamilyInvite toEntity() {
    return FamilyInvite(
      id: id,
      aquariumId: aquariumId,
      inviteCode: inviteCode,
      createdBy: createdBy,
      createdAt: createdAt,
      expiresAt: expiresAt,
      status: _parseStatus(status),
      acceptedBy: acceptedBy,
      acceptedAt: acceptedAt,
    );
  }

  FamilyInviteStatus _parseStatus(String status) {
    return switch (status) {
      'pending' => FamilyInviteStatus.pending,
      'accepted' => FamilyInviteStatus.accepted,
      'expired' => FamilyInviteStatus.expired,
      'cancelled' => FamilyInviteStatus.cancelled,
      _ => FamilyInviteStatus.pending,
    };
  }
}
