import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:fishfeed/core/errors/api_exceptions.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/remote/api_client.dart';
// TODO: Uncomment when backend API is ready
// import 'package:fishfeed/data/models/family_invite_dto.dart';
// import 'package:fishfeed/data/models/family_member_dto.dart';
import 'package:fishfeed/domain/entities/family_invite.dart';
import 'package:fishfeed/domain/entities/family_member.dart';
import 'package:fishfeed/domain/repositories/family_repository.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';

/// Implementation of [FamilyRepository].
///
/// Handles family sharing operations via API calls.
/// Uses mock data when API is not available (TODO: remove mock when backend is ready).
class FamilyRepositoryImpl implements FamilyRepository {
  FamilyRepositoryImpl({
    required ApiClient apiClient,
    required String? currentUserId,
  })  : _apiClient = apiClient,
        _currentUserId = currentUserId;

  // ignore: unused_field - will be used when backend API is ready
  final ApiClient _apiClient;
  final String? _currentUserId;
  final _uuid = const Uuid();

  // TODO: Remove mock storage when backend API is ready
  static final Map<String, List<FamilyInvite>> _mockInvites = {};
  static final Map<String, List<FamilyMember>> _mockMembers = {};

  @override
  Future<Either<Failure, FamilyInvite>> createInvite({
    required String aquariumId,
  }) async {
    try {
      // TODO: Replace with actual API call when backend is ready
      // final response = await _apiClient.dio.post(
      //   '/aquariums/$aquariumId/family/invite',
      // );
      // final dto = FamilyInviteDto.fromJson(response.data);
      // return Right(dto.toEntity());

      // Mock implementation
      if (_currentUserId == null) {
        return const Left(
            AuthenticationFailure(message: 'User not authenticated'));
      }

      final now = DateTime.now();
      final invite = FamilyInvite(
        id: _uuid.v4(),
        aquariumId: aquariumId,
        inviteCode: _generateInviteCode(),
        createdBy: _currentUserId,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 48)),
        status: FamilyInviteStatus.pending,
      );

      _mockInvites.putIfAbsent(aquariumId, () => []);
      _mockInvites[aquariumId]!.add(invite);

      return Right(invite);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<FamilyInvite>>> getInvites({
    required String aquariumId,
  }) async {
    try {
      // TODO: Replace with actual API call when backend is ready
      // final response = await _apiClient.dio.get(
      //   '/aquariums/$aquariumId/family/invites',
      // );
      // final invites = (response.data as List)
      //     .map((json) => FamilyInviteDto.fromJson(json).toEntity())
      //     .toList();
      // return Right(invites);

      // Mock implementation
      final invites = _mockInvites[aquariumId] ?? [];
      // Filter out expired invites
      final activeInvites = invites.where((invite) => invite.isValid).toList();
      return Right(activeInvites);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelInvite({
    required String inviteId,
  }) async {
    try {
      // TODO: Replace with actual API call when backend is ready
      // await _apiClient.dio.delete('/family/invites/$inviteId');

      // Mock implementation
      for (final invites in _mockInvites.values) {
        invites.removeWhere((invite) => invite.id == inviteId);
      }

      return const Right(unit);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<FamilyMember>>> getMembers({
    required String aquariumId,
  }) async {
    try {
      // TODO: Replace with actual API call when backend is ready
      // final response = await _apiClient.dio.get(
      //   '/aquariums/$aquariumId/family/members',
      // );
      // final members = (response.data as List)
      //     .map((json) => FamilyMemberDto.fromJson(json).toEntity())
      //     .toList();
      // return Right(members);

      // Mock implementation - always include owner
      final members = _mockMembers[aquariumId] ?? [];
      if (members.isEmpty && _currentUserId != null) {
        // Add owner if no members exist
        final owner = FamilyMember(
          id: _uuid.v4(),
          userId: _currentUserId,
          aquariumId: aquariumId,
          role: FamilyMemberRole.owner,
          joinedAt: DateTime.now(),
          displayName: 'You',
        );
        _mockMembers[aquariumId] = [owner];
        return Right([owner]);
      }
      return Right(members);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> removeMember({
    required String memberId,
  }) async {
    try {
      // TODO: Replace with actual API call when backend is ready
      // await _apiClient.dio.delete('/family/members/$memberId');

      // Mock implementation
      for (final members in _mockMembers.values) {
        final memberIndex =
            members.indexWhere((member) => member.id == memberId);
        if (memberIndex != -1) {
          if (members[memberIndex].isOwner) {
            return const Left(
                ValidationFailure(message: 'Cannot remove the owner'));
          }
          members.removeAt(memberIndex);
        }
      }

      return const Right(unit);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, FamilyMember>> acceptInvite({
    required String inviteCode,
  }) async {
    try {
      // TODO: Replace with actual API call when backend is ready
      // final response = await _apiClient.dio.post(
      //   '/family/accept',
      //   data: {'invite_code': inviteCode},
      // );
      // final dto = FamilyMemberDto.fromJson(response.data);
      // return Right(dto.toEntity());

      // Mock implementation
      if (_currentUserId == null) {
        return const Left(
            AuthenticationFailure(message: 'User not authenticated'));
      }

      // Find the invite
      FamilyInvite? foundInvite;
      String? aquariumId;

      for (final entry in _mockInvites.entries) {
        final invite = entry.value.cast<FamilyInvite?>().firstWhere(
              (i) => i?.inviteCode == inviteCode && i!.isValid,
              orElse: () => null,
            );
        if (invite != null) {
          foundInvite = invite;
          aquariumId = entry.key;
          break;
        }
      }

      if (foundInvite == null || aquariumId == null) {
        return const Left(ValidationFailure(
            message: 'Invalid or expired invite code'));
      }

      // Create new member
      final member = FamilyMember(
        id: _uuid.v4(),
        userId: _currentUserId,
        aquariumId: aquariumId,
        role: FamilyMemberRole.member,
        joinedAt: DateTime.now(),
      );

      _mockMembers.putIfAbsent(aquariumId, () => []);
      _mockMembers[aquariumId]!.add(member);

      // Update invite status
      final inviteIndex =
          _mockInvites[aquariumId]!.indexWhere((i) => i.id == foundInvite!.id);
      if (inviteIndex != -1) {
        _mockInvites[aquariumId]![inviteIndex] = foundInvite.copyWith(
          status: FamilyInviteStatus.accepted,
          acceptedBy: _currentUserId,
          acceptedAt: DateTime.now(),
        );
      }

      return Right(member);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  String _generateInviteCode() {
    // Generate a short, readable code
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    for (var i = 0; i < 8; i++) {
      buffer.write(chars[(random + i * 7) % chars.length]);
    }
    return buffer.toString();
  }

  Failure _mapApiExceptionToFailure(ApiException exception) {
    return switch (exception) {
      NetworkException() => const NetworkFailure(),
      UnauthorizedException() =>
        const AuthenticationFailure(message: 'Authentication required'),
      ValidationException(:final message, :final errors) =>
        ValidationFailure(message: message, errors: errors),
      ForbiddenException() =>
        const AuthenticationFailure(message: 'Access denied'),
      NotFoundException() =>
        const ServerFailure(message: 'Resource not found'),
      ServerException() => const ServerFailure(),
      UnknownApiException(:final message) =>
        UnexpectedFailure(message: message),
    };
  }
}

/// Provider for [FamilyRepository].
final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final currentUser = ref.watch(currentUserProvider);

  return FamilyRepositoryImpl(
    apiClient: apiClient,
    currentUserId: currentUser?.id,
  );
});
