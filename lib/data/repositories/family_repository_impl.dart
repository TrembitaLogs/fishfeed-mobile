import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/config/api_config.dart';
import 'package:fishfeed/core/errors/api_exceptions.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/remote/api_client.dart';
import 'package:fishfeed/data/models/family_invite_dto.dart';
import 'package:fishfeed/data/models/family_member_dto.dart';
import 'package:fishfeed/domain/entities/family_invite.dart';
import 'package:fishfeed/domain/entities/family_member.dart';
import 'package:fishfeed/domain/repositories/family_repository.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';

/// Implementation of [FamilyRepository].
///
/// Handles family sharing operations via direct API calls.
/// Family data is NOT part of the delta sync protocol — all operations
/// are online-only and server-authoritative.
class FamilyRepositoryImpl implements FamilyRepository {
  FamilyRepositoryImpl({
    required ApiClient apiClient,
    required String? currentUserId,
  }) : _apiClient = apiClient,
       _currentUserId = currentUserId;

  final ApiClient _apiClient;
  final String? _currentUserId;

  @override
  Future<Either<Failure, FamilyInvite>> createInvite({
    required String aquariumId,
  }) async {
    try {
      if (_currentUserId == null) {
        return const Left(
          AuthenticationFailure(message: 'User not authenticated'),
        );
      }

      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.familyCreateInvite(aquariumId),
      );

      final dto = FamilyInviteDto.fromJson(response.data!);
      return Right(
        dto.toEntity(aquariumId: aquariumId, createdBy: _currentUserId),
      );
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
      if (_currentUserId == null) {
        return const Left(
          AuthenticationFailure(message: 'User not authenticated'),
        );
      }

      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        ApiEndpoints.familyInvites(aquariumId),
      );

      final data = response.data!;
      final invitesJson = data['invites'] as List<dynamic>;
      final invites = invitesJson
          .map(
            (json) => FamilyInviteDto.fromJson(
              json as Map<String, dynamic>,
            ).toEntity(aquariumId: aquariumId, createdBy: _currentUserId),
          )
          .toList();

      return Right(invites);
    } on ApiException catch (e) {
      // If user is not owner, they can't list invites — return empty list
      if (e is ForbiddenException) {
        return const Right([]);
      }
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelInvite({
    required String aquariumId,
    required String inviteId,
  }) async {
    try {
      await _apiClient.dio.delete<void>(
        ApiEndpoints.familyCancelInvite(aquariumId, inviteId),
      );
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
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        ApiEndpoints.familyMembers(aquariumId),
      );

      final data = response.data!;
      final membersJson = data['members'] as List<dynamic>;
      final members = membersJson
          .map(
            (json) => FamilyMemberDto.fromJson(
              json as Map<String, dynamic>,
            ).toEntity(aquariumId: aquariumId),
          )
          .toList();

      return Right(members);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> removeMember({
    required String aquariumId,
    required String userId,
  }) async {
    try {
      await _apiClient.dio.delete<void>(
        ApiEndpoints.familyRemoveMember(aquariumId, userId),
      );
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
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.familyAccept,
        data: {'invite_code': inviteCode},
      );

      // Backend returns AquariumResponse, not FamilyMember.
      // Construct a FamilyMember from the aquarium data since we know
      // the current user just joined as a member.
      final aquariumData = response.data!;
      final aquariumId = aquariumData['id'] as String;
      final userId = _currentUserId ?? '';

      final member = FamilyMember(
        id: userId,
        userId: userId,
        aquariumId: aquariumId,
        role: FamilyMemberRole.member,
        joinedAt: DateTime.now(),
      );

      return Right(member);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  Failure _mapApiExceptionToFailure(ApiException exception) {
    return switch (exception) {
      NetworkException() => const NetworkFailure(),
      UnauthorizedException() => const AuthenticationFailure(
        message: 'Authentication required',
      ),
      ValidationException(:final message, :final errors) => ValidationFailure(
        message: message,
        errors: errors,
      ),
      ForbiddenException(:final message) => ValidationFailure(
        message: message ?? 'Access denied',
      ),
      NotFoundException() => const ServerFailure(message: 'Resource not found'),
      ServerException() => const ServerFailure(),
      UnknownApiException(:final message) => UnexpectedFailure(
        message: message,
      ),
    };
  }
}

/// Provider for [FamilyRepository].
final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final currentUserId = ref.watch(currentUserProvider.select((u) => u?.id));

  return FamilyRepositoryImpl(
    apiClient: apiClient,
    currentUserId: currentUserId,
  );
});
