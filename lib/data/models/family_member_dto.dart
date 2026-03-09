import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:fishfeed/domain/entities/family_member.dart';

part 'family_member_dto.freezed.dart';
part 'family_member_dto.g.dart';

/// DTO for family member data from the API.
///
/// Maps to backend's `FamilyMemberResponse`:
/// `{ user_id, nickname, avatar_url, role, joined_at }`
@freezed
class FamilyMemberDto with _$FamilyMemberDto {
  const FamilyMemberDto._();

  const factory FamilyMemberDto({
    @JsonKey(name: 'user_id') required String userId,
    String? nickname,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @Default('member') String role,
    @JsonKey(name: 'joined_at') required DateTime joinedAt,
  }) = _FamilyMemberDto;

  factory FamilyMemberDto.fromJson(Map<String, dynamic> json) =>
      _$FamilyMemberDtoFromJson(json);

  /// Converts this DTO to a domain entity.
  ///
  /// [aquariumId] must be provided from the parent response context
  /// since the backend doesn't include it per-member.
  FamilyMember toEntity({required String aquariumId}) {
    return FamilyMember(
      id: userId,
      userId: userId,
      aquariumId: aquariumId,
      role: _parseRole(role),
      joinedAt: joinedAt,
      displayName: nickname,
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
