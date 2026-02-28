import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/errors/api_exceptions.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/datasources/remote/user_remote_ds.dart';
import 'package:fishfeed/data/models/user_model.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/repositories/user_repository.dart';

/// Implementation of [UserRepository].
///
/// Handles user profile operations by coordinating between remote API
/// and local storage for caching.
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({
    required UserRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final UserRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, User>> updateDisplayName({
    required String displayName,
  }) async {
    try {
      final userDto = await _remoteDataSource.updateProfile(
        displayName: displayName,
      );

      final user = User(
        id: userDto.id,
        email: userDto.email,
        displayName: userDto.displayName,
        avatarKey: userDto.avatarKey,
        createdAt: userDto.createdAt,
        subscriptionStatus: _parseSubscriptionStatus(
          userDto.subscriptionStatus,
        ),
        freeAiScansRemaining: userDto.freeAiScansRemaining,
      );

      // Update local cache
      final userModel = UserModel.fromEntity(user);
      await _localDataSource.updateUserLocally(userModel);

      return Right(user);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e, st) {
      debugPrint('UserRepository.updateDisplayName failed: $e\n$st');
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateAvatar({required File avatarFile}) async {
    try {
      final userDto = await _remoteDataSource.uploadAvatar(
        avatarFile: avatarFile,
      );

      final user = User(
        id: userDto.id,
        email: userDto.email,
        displayName: userDto.displayName,
        avatarKey: userDto.avatarKey,
        createdAt: userDto.createdAt,
        subscriptionStatus: _parseSubscriptionStatus(
          userDto.subscriptionStatus,
        ),
        freeAiScansRemaining: userDto.freeAiScansRemaining,
      );

      // Update local cache
      final userModel = UserModel.fromEntity(user);
      await _localDataSource.updateUserLocally(userModel);

      return Right(user);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e, st) {
      debugPrint('UserRepository.updateAvatar failed: $e\n$st');
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  /// Parses subscription status string to enum.
  SubscriptionStatus _parseSubscriptionStatus(String status) {
    return switch (status.toLowerCase()) {
      'premium' => SubscriptionStatus.premium(),
      _ => const SubscriptionStatus.free(),
    };
  }

  /// Maps [ApiException] to domain [Failure].
  Failure _mapApiExceptionToFailure(ApiException exception) {
    return switch (exception) {
      NetworkException() => const NetworkFailure(),
      UnauthorizedException() => const AuthenticationFailure(
        message: 'Not authenticated',
      ),
      ValidationException(:final message, :final errors) => ValidationFailure(
        message: message,
        errors: errors,
      ),
      ForbiddenException() => const AuthenticationFailure(
        message: 'Access denied',
      ),
      NotFoundException() => const ServerFailure(message: 'User not found'),
      ServerException() => const ServerFailure(),
      UnknownApiException(:final message) => UnexpectedFailure(
        message: message,
      ),
    };
  }
}

/// Provider for [UserRepository].
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final remoteDataSource = ref.watch(userRemoteDataSourceProvider);
  final localDataSource = ref.watch(authLocalDataSourceProvider);

  return UserRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});
