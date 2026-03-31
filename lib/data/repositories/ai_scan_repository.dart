import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/errors/api_exceptions.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/remote/ai_scan_remote_ds.dart';
import 'package:fishfeed/data/models/ai_scan_result.dart';
import 'package:fishfeed/domain/repositories/ai_scan_repository.dart';

/// Implementation of [AiScanRepository].
///
/// Handles AI scan operations with proper error mapping.
class AiScanRepositoryImpl implements AiScanRepository {
  AiScanRepositoryImpl({required AiScanRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final AiScanRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, AiScanResult>> scanFishImage({
    required Uint8List imageBytes,
  }) async {
    try {
      final result = await _remoteDataSource.scanFishImage(
        imageBytes: imageBytes,
      );
      return Right(result);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (e) {
      return const Left(UnexpectedFailure(message: 'Failed to analyze image'));
    }
  }

  /// Maps [ApiException] to domain [Failure].
  Failure _mapApiExceptionToFailure(ApiException exception) {
    return switch (exception) {
      NetworkException() => const NetworkFailure(
        message: 'Check your connection',
      ),
      ServerException() => const ServerFailure(
        message: 'Server error. Try again later',
      ),
      UnauthorizedException() => const AuthenticationFailure(
        message: 'Please log in to use AI scan',
      ),
      ValidationException(:final message) => ValidationFailure(
        message: message,
      ),
      ForbiddenException() => const AuthenticationFailure(
        message: 'AI scan not available for your account',
      ),
      NotFoundException() => const ServerFailure(
        message: 'AI scan service unavailable',
      ),
      UnknownApiException(:final message) => UnexpectedFailure(
        message: message ?? 'An unexpected error occurred',
      ),
    };
  }
}

/// Provider for [AiScanRepository].
///
/// Usage:
/// ```dart
/// final aiScanRepo = ref.watch(aiScanRepositoryProvider);
/// final result = await aiScanRepo.scanFishImage(imageBytes: bytes);
/// result.fold(
///   (failure) => print('Error: ${failure.message}'),
///   (scanResult) => print('Detected: ${scanResult.speciesName}'),
/// );
/// ```
final aiScanRepositoryProvider = Provider<AiScanRepository>((ref) {
  final remoteDataSource = ref.watch(aiScanRemoteDataSourceProvider);
  return AiScanRepositoryImpl(remoteDataSource: remoteDataSource);
});
