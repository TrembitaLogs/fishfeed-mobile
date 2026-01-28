import 'package:equatable/equatable.dart';

/// Status of a family invitation.
enum FamilyInviteStatus {
  /// Invitation is active and can be accepted.
  pending,

  /// Invitation has been accepted.
  accepted,

  /// Invitation has expired.
  expired,

  /// Invitation was cancelled by the owner.
  cancelled,
}

/// Domain entity representing a family invitation to share an aquarium.
class FamilyInvite extends Equatable {
  const FamilyInvite({
    required this.id,
    required this.aquariumId,
    required this.inviteCode,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    this.status = FamilyInviteStatus.pending,
    this.acceptedBy,
    this.acceptedAt,
  });

  /// Unique identifier for the invitation.
  final String id;

  /// ID of the aquarium being shared.
  final String aquariumId;

  /// Unique code used in the deep link for accepting the invitation.
  final String inviteCode;

  /// ID of the user who created the invitation.
  final String createdBy;

  /// When the invitation was created.
  final DateTime createdAt;

  /// When the invitation expires.
  final DateTime expiresAt;

  /// Current status of the invitation.
  final FamilyInviteStatus status;

  /// ID of the user who accepted the invitation.
  final String? acceptedBy;

  /// When the invitation was accepted.
  final DateTime? acceptedAt;

  /// Returns the deep link URL for this invitation.
  String get deepLink => 'fishfeed://join/$inviteCode';

  /// Returns true if the invitation is still valid and can be accepted.
  bool get isValid =>
      status == FamilyInviteStatus.pending &&
      DateTime.now().isBefore(expiresAt);

  /// Returns the remaining time until expiration.
  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }

  /// Creates a copy with updated fields.
  FamilyInvite copyWith({
    String? id,
    String? aquariumId,
    String? inviteCode,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    FamilyInviteStatus? status,
    String? acceptedBy,
    DateTime? acceptedAt,
  }) {
    return FamilyInvite(
      id: id ?? this.id,
      aquariumId: aquariumId ?? this.aquariumId,
      inviteCode: inviteCode ?? this.inviteCode,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      acceptedBy: acceptedBy ?? this.acceptedBy,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        aquariumId,
        inviteCode,
        createdBy,
        createdAt,
        expiresAt,
        status,
        acceptedBy,
        acceptedAt,
      ];
}
