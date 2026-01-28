import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/errors/api_exceptions.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/remote/push_remote_ds.dart';
import 'package:fishfeed/domain/repositories/push_repository.dart';

/// Configuration for retry behavior in push token operations.
class PushRetryConfig {
  const PushRetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
  });

  /// Maximum number of retry attempts.
  final int maxRetries;

  /// Initial delay before the first retry.
  final Duration initialDelay;

  /// Maximum delay between retries.
  final Duration maxDelay;

  /// Multiplier for exponential backoff.
  final double backoffMultiplier;
}

/// Implementation of [PushRepository].
///
/// Coordinates between the remote data source and local Hive storage
/// for push notification token management with automatic retry logic.
class PushRepositoryImpl implements PushRepository {
  PushRepositoryImpl({
    required PushRemoteDataSource remoteDataSource,
    PushRetryConfig? retryConfig,
  }) : _remoteDataSource = remoteDataSource,
       _retryConfig = retryConfig ?? const PushRetryConfig();

  final PushRemoteDataSource _remoteDataSource;
  final PushRetryConfig _retryConfig;

  @override
  Future<Either<Failure, Unit>> registerToken({
    required String token,
    required String platform,
  }) async {
    // Skip if token hasn't changed
    if (!needsRegistration(token, platform)) {
      if (kDebugMode) {
        print('Push token unchanged, skipping registration');
      }
      return const Right(unit);
    }

    try {
      await _remoteDataSource.registerToken(token: token, platform: platform);

      // Store token locally after successful registration
      await HiveBoxes.setPushToken(token, platform);

      if (kDebugMode) {
        print('Push token registered successfully');
      }

      return const Right(unit);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      if (kDebugMode) {
        print('Push token registration failed: $e');
      }
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<void> registerTokenWithRetry({
    required String token,
    required String platform,
  }) async {
    // Skip if token hasn't changed
    if (!needsRegistration(token, platform)) {
      if (kDebugMode) {
        print('Push token unchanged, skipping registration');
      }
      return;
    }

    int retryCount = 0;
    Duration delay = _retryConfig.initialDelay;

    while (retryCount <= _retryConfig.maxRetries) {
      try {
        await _remoteDataSource.registerToken(token: token, platform: platform);

        // Store token locally after successful registration
        await HiveBoxes.setPushToken(token, platform);

        if (kDebugMode) {
          print('Push token registered successfully after $retryCount retries');
        }

        return;
      } on ApiException catch (e) {
        final isRetryable = _isRetryableError(e);

        if (!isRetryable || retryCount >= _retryConfig.maxRetries) {
          if (kDebugMode) {
            print('Push token registration failed permanently: $e');
          }
          return;
        }

        if (kDebugMode) {
          print('Push token registration failed, retrying in $delay...');
        }

        await Future<void>.delayed(delay);

        retryCount++;
        delay = _calculateNextDelay(delay);
      } catch (e) {
        if (kDebugMode) {
          print('Push token registration failed with unexpected error: $e');
        }
        return;
      }
    }
  }

  @override
  Future<Either<Failure, Unit>> unregisterToken() async {
    // Always clear local token first
    final storedToken = getStoredToken();
    await HiveBoxes.clearPushToken();

    // If no token was stored, nothing to unregister on server
    if (storedToken == null) {
      return const Right(unit);
    }

    try {
      await _remoteDataSource.unregisterToken();

      if (kDebugMode) {
        print('Push token unregistered successfully');
      }

      return const Right(unit);
    } on ApiException catch (e) {
      // Token is already cleared locally, so we consider this a success
      // even if server request fails
      if (kDebugMode) {
        print('Push token unregistration server error (local cleared): $e');
      }
      return const Right(unit);
    } catch (e) {
      if (kDebugMode) {
        print('Push token unregistration failed: $e');
      }
      return const Right(unit);
    }
  }

  @override
  String? getStoredToken() {
    return HiveBoxes.getPushToken();
  }

  @override
  String? getStoredPlatform() {
    return HiveBoxes.getPushTokenPlatform();
  }

  @override
  bool needsRegistration(String currentToken, String platform) {
    final storedToken = getStoredToken();
    final storedPlatform = getStoredPlatform();

    return storedToken != currentToken || storedPlatform != platform;
  }

  /// Checks if an error is retryable.
  bool _isRetryableError(ApiException exception) {
    return switch (exception) {
      NetworkException() => true,
      ServerException() => true,
      _ => false,
    };
  }

  /// Calculates the next delay using exponential backoff.
  Duration _calculateNextDelay(Duration currentDelay) {
    final nextDelay = currentDelay * _retryConfig.backoffMultiplier.toInt();
    return nextDelay > _retryConfig.maxDelay
        ? _retryConfig.maxDelay
        : nextDelay;
  }

  /// Maps [ApiException] to domain [Failure].
  Failure _mapApiExceptionToFailure(ApiException exception) {
    return switch (exception) {
      NetworkException() => const NetworkFailure(),
      UnauthorizedException() => const AuthenticationFailure(
        message: 'Not authenticated',
      ),
      ServerException() => const ServerFailure(),
      _ => const UnexpectedFailure(),
    };
  }
}

/// Provider for [PushRepository].
///
/// Usage:
/// ```dart
/// final pushRepo = ref.watch(pushRepositoryProvider);
/// await pushRepo.registerToken(token: fcmToken, platform: 'android');
/// ```
final pushRepositoryProvider = Provider<PushRepository>((ref) {
  final remoteDataSource = ref.watch(pushRemoteDataSourceProvider);
  return PushRepositoryImpl(remoteDataSource: remoteDataSource);
});
