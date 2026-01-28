import 'package:equatable/equatable.dart';

/// Role of a family member in a shared aquarium.
enum FamilyMemberRole {
  /// Owner of the aquarium with full permissions.
  owner,

  /// Member with permission to feed and view.
  member,
}

/// Domain entity representing a family member with access to a shared aquarium.
class FamilyMember extends Equatable {
  const FamilyMember({
    required this.id,
    required this.userId,
    required this.aquariumId,
    required this.role,
    required this.joinedAt,
    this.displayName,
    this.avatarUrl,
  });

  /// Unique identifier for this membership record.
  final String id;

  /// ID of the user.
  final String userId;

  /// ID of the aquarium.
  final String aquariumId;

  /// Role of the member in this aquarium.
  final FamilyMemberRole role;

  /// When the member joined this aquarium.
  final DateTime joinedAt;

  /// Display name of the member.
  final String? displayName;

  /// Avatar URL of the member.
  final String? avatarUrl;

  /// Returns true if this member is the owner.
  bool get isOwner => role == FamilyMemberRole.owner;

  /// Creates a copy with updated fields.
  FamilyMember copyWith({
    String? id,
    String? userId,
    String? aquariumId,
    FamilyMemberRole? role,
    DateTime? joinedAt,
    String? displayName,
    String? avatarUrl,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      aquariumId: aquariumId ?? this.aquariumId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    aquariumId,
    role,
    joinedAt,
    displayName,
    avatarUrl,
  ];
}
