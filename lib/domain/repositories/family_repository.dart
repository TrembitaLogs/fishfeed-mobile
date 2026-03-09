import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/entities/family_invite.dart';
import 'package:fishfeed/domain/entities/family_member.dart';

/// Repository interface for family sharing operations.
///
/// Provides methods for managing family invitations and members
/// for shared aquarium access.
abstract interface class FamilyRepository {
  /// Creates a new family invitation for an aquarium.
  ///
  /// Returns [Right(FamilyInvite)] on success with the generated invite.
  /// Returns [Left(Failure)] on error:
  /// - [AuthenticationFailure] if user is not authenticated
  /// - [ForbiddenFailure] if user is not the aquarium owner
  /// - [NetworkFailure] for connectivity issues
  /// - [ServerFailure] for server errors
  Future<Either<Failure, FamilyInvite>> createInvite({
    required String aquariumId,
  });

  /// Gets all active invitations for an aquarium.
  ///
  /// Returns [Right(List<FamilyInvite>)] on success.
  /// Returns [Left(Failure)] on error.
  Future<Either<Failure, List<FamilyInvite>>> getInvites({
    required String aquariumId,
  });

  /// Cancels an active invitation.
  ///
  /// Returns [Right(unit)] on success.
  /// Returns [Left(Failure)] on error.
  Future<Either<Failure, Unit>> cancelInvite({
    required String aquariumId,
    required String inviteId,
  });

  /// Gets all family members for an aquarium.
  ///
  /// Returns [Right(List<FamilyMember>)] on success.
  /// Returns [Left(Failure)] on error.
  Future<Either<Failure, List<FamilyMember>>> getMembers({
    required String aquariumId,
  });

  /// Removes a family member from an aquarium.
  ///
  /// Returns [Right(unit)] on success.
  /// Returns [Left(Failure)] on error:
  /// - [ForbiddenFailure] if user is not the owner
  /// - [ValidationFailure] if trying to remove the owner
  Future<Either<Failure, Unit>> removeMember({
    required String aquariumId,
    required String userId,
  });

  /// Accepts a family invitation using an invite code.
  ///
  /// Returns [Right(FamilyMember)] on success with the new membership.
  /// Returns [Left(Failure)] on error:
  /// - [ValidationFailure] if invite is expired or invalid
  /// - [ForbiddenFailure] if user already has access
  Future<Either<Failure, FamilyMember>> acceptInvite({
    required String inviteCode,
  });
}
