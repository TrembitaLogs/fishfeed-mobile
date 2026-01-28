import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:fishfeed/domain/entities/family_member.dart';

part 'family_member_dto.freezed.dart';
part 'family_member_dto.g.dart';

/// DTO for family member data from the API.
@freezed
class FamilyMemberDto with _$FamilyMemberDto {
  const FamilyMemberDto._();

  const factory FamilyMemberDto({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'aquarium_id') required String aquariumId,
    @Default('member') String role,
    @JsonKey(name: 'joined_at') required DateTime joinedAt,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _FamilyMemberDto;

  factory FamilyMemberDto.fromJson(Map<String, dynamic> json) =>
      _$FamilyMemberDtoFromJson(json);

  /// Converts this DTO to a domain entity.
  FamilyMember toEntity() {
    return FamilyMember(
      id: id,
      userId: userId,
      aquariumId: aquariumId,
      role: _parseRole(role),
      joinedAt: joinedAt,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }

  FamilyMemberRole _parseRole(String role) {
    return switch (role) {
      'owner' => FamilyMemberRole.owner,
      'member' => FamilyMemberRole.member,
      _ => FamilyMemberRole.member,
    };
  }
}
