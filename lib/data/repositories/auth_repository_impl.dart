import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/errors/api_exceptions.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/core/services/secure_storage_service.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/datasources/remote/auth_remote_ds.dart';
import 'package:fishfeed/data/models/user_dto.dart';
import 'package:fishfeed/data/models/user_model.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/repositories/auth_repository.dart';

/// Implementation of [AuthRepository].
///
/// Handles authentication flows by coordinating between remote API,
/// local storage, and secure storage for tokens.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required SecureStorageService secureStorageService,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _secureStorageService = secureStorageService;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final SecureStorageService _secureStorageService;

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      await _saveAuthData(
        response.user,
        response.tokens.accessToken,
        response.tokens.refreshToken,
      );

      return Right(_mapUserDtoToEntity(response.user));
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e, st) {
      debugPrint('AuthRepository.login failed: $e\n$st');
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.register(
        email: email,
        password: password,
      );

      await _saveAuthData(
        response.user,
        response.tokens.accessToken,
        response.tokens.refreshToken,
      );

      return Right(_mapUserDtoToEntity(response.user));
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, User>> oauthLogin({
    required String provider,
    required String idToken,
  }) async {
    try {
      final response = await _remoteDataSource.oauthLogin(
        provider: provider,
        idToken: idToken,
      );

      await _saveAuthData(
        response.user,
        response.tokens.accessToken,
        response.tokens.refreshToken,
      );

      return Right(_mapUserDtoToEntity(response.user));
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      final refreshToken = await _secureStorageService.getRefreshToken();

      // Always clear local data, even if server logout fails
      await _clearAuthData();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          await _remoteDataSource.logout(refreshToken: refreshToken);
        } catch (e, st) {
          // Ignore server logout errors - local data is already cleared
          debugPrint('AuthRepository.logout server call failed: $e\n$st');
        }
      }

      return const Right(unit);
    } catch (e) {
      // Even if something fails, try to clear local data
      await _clearAuthData();
      return const Right(unit);
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final userModel = _localDataSource.getCurrentUser();

      if (userModel == null) {
        return const Left(CacheFailure(message: 'No user cached locally'));
      }

      return Right(userModel.toEntity());
    } catch (e) {
      return const Left(
        CacheFailure(message: 'Failed to read user from cache'),
      );
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _secureStorageService.hasTokens();
  }

  /// Saves authentication data to local storage.
  Future<void> _saveAuthData(
    UserDto userDto,
    String accessToken,
    String refreshToken,
  ) async {
    // Save tokens to secure storage
    await _secureStorageService.setTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    // Save user to local Hive storage
    final user = _mapUserDtoToEntity(userDto);
    final userModel = UserModel.fromEntity(user);
    await _localDataSource.saveUserLocally(userModel);
  }

  /// Clears all authentication data from local storage.
  Future<void> _clearAuthData() async {
    await Future.wait([
      _secureStorageService.clearTokens(),
      _localDataSource.clearAll(),
      HiveBoxes.clearUserData(),
    ]);
  }

  /// Maps [UserDto] to [User] domain entity.
  User _mapUserDtoToEntity(UserDto dto) {
    return User(
      id: dto.id,
      email: dto.email,
      displayName: dto.displayName,
      avatarKey: dto.avatarKey,
      createdAt: dto.createdAt,
      subscriptionStatus: _parseSubscriptionStatus(dto.subscriptionStatus),
      freeAiScansRemaining: dto.freeAiScansRemaining,
    );
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
        message: 'Invalid credentials',
      ),
      ValidationException(:final message, :final errors) => ValidationFailure(
        message: message,
        errors: errors,
      ),
      ForbiddenException() => const AuthenticationFailure(
        message: 'Access denied',
      ),
      NotFoundException() => const ServerFailure(message: 'Resource not found'),
      ServerException() => const ServerFailure(),
      UnknownApiException(:final message) => UnexpectedFailure(
        message: message,
      ),
    };
  }
}

/// Provider for [AuthRepository].
///
/// Usage:
/// ```dart
/// final authRepo = ref.watch(authRepositoryProvider);
/// final result = await authRepo.login(email: email, password: password);
/// result.fold(
///   (failure) => print('Error: ${failure.message}'),
///   (user) => print('Welcome, ${user.email}!'),
/// );
/// ```
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final localDataSource = ref.watch(authLocalDataSourceProvider);
  final secureStorageService = ref.watch(secureStorageServiceProvider);

  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    secureStorageService: secureStorageService,
  );
});
