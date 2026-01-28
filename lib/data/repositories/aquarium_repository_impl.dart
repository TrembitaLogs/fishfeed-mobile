import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:fishfeed/core/errors/api_exceptions.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/datasources/remote/aquarium_remote_ds.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/domain/repositories/aquarium_repository.dart';

/// Implementation of [AquariumRepository].
///
/// Handles aquarium operations by coordinating between remote API
/// and local storage with offline-first approach.
class AquariumRepositoryImpl implements AquariumRepository {
  AquariumRepositoryImpl({
    required AquariumRemoteDataSource remoteDataSource,
    required AquariumLocalDataSource localDataSource,
    required AuthLocalDataSource authLocalDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _authLocalDataSource = authLocalDataSource;

  final AquariumRemoteDataSource _remoteDataSource;
  final AquariumLocalDataSource _localDataSource;
  final AuthLocalDataSource _authLocalDataSource;

  @override
  Future<Either<Failure, Aquarium>> createAquarium({
    required String name,
    WaterType? waterType,
    double? capacity,
  }) async {
    final currentUser = _authLocalDataSource.getCurrentUser();
    if (currentUser == null) {
      return const Left(AuthenticationFailure(message: 'User not logged in'));
    }

    try {
      // Try to create on server first
      final dto = await _remoteDataSource.createAquarium(
        name: name,
        waterType: waterType,
        capacity: capacity,
      );

      final aquarium = dto.toEntity();

      // Save to local cache
      final model = AquariumModel.fromEntity(aquarium);
      await _localDataSource.saveAquarium(model);

      return Right(aquarium);
    } on ApiException catch (e) {
      // On network failure, create locally with temporary ID
      if (e is NetworkException) {
        final tempId = const Uuid().v4();
        final aquarium = Aquarium(
          id: tempId,
          userId: currentUser.id,
          name: name,
          waterType: waterType ?? WaterType.freshwater,
          capacity: capacity,
          createdAt: DateTime.now(),
        );

        final model = AquariumModel.fromEntity(aquarium);
        await _localDataSource.saveAquarium(model);

        // TODO: Queue for sync when online
        return Right(aquarium);
      }
      return Left(_mapApiExceptionToFailure(e));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<Aquarium>>> getAquariums() async {
    try {
      // Try to fetch from server and update cache
      final dtos = await _remoteDataSource.getAquariums();
      final aquariums = dtos.map((dto) => dto.toEntity()).toList();

      // Update local cache
      final currentUser = _authLocalDataSource.getCurrentUser();
      if (currentUser != null) {
        final models = aquariums.map(AquariumModel.fromEntity).toList();
        await _localDataSource.replaceAllForUser(currentUser.id, models);
      }

      return Right(aquariums);
    } on ApiException catch (e) {
      // On network failure, return cached data
      if (e is NetworkException) {
        return getCachedAquariums();
      }
      return Left(_mapApiExceptionToFailure(e));
    } catch (_) {
      // On any error, try to return cached data
      final cached = getCachedAquariums();
      if (cached.isRight()) {
        return cached;
      }
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Aquarium>> getAquariumById(String aquariumId) async {
    // First check local cache
    final cached = _localDataSource.getAquariumById(aquariumId);
    if (cached != null) {
      return Right(cached.toEntity());
    }

    // If not in cache, try to fetch from server
    try {
      final dto = await _remoteDataSource.getAquariumById(aquariumId);
      final aquarium = dto.toEntity();

      // Save to local cache
      final model = AquariumModel.fromEntity(aquarium);
      await _localDataSource.saveAquarium(model);

      return Right(aquarium);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Aquarium>> updateAquarium({
    required String aquariumId,
    String? name,
    WaterType? waterType,
    double? capacity,
    String? imageUrl,
  }) async {
    try {
      final dto = await _remoteDataSource.updateAquarium(
        aquariumId: aquariumId,
        name: name,
        waterType: waterType,
        capacity: capacity,
        imageUrl: imageUrl,
      );

      final aquarium = dto.toEntity();

      // Update local cache
      final model = AquariumModel.fromEntity(aquarium);
      await _localDataSource.updateAquarium(model);

      return Right(aquarium);
    } on ApiException catch (e) {
      // On network failure, update locally
      if (e is NetworkException) {
        final existing = _localDataSource.getAquariumById(aquariumId);
        if (existing != null) {
          final updated = Aquarium(
            id: existing.id,
            userId: existing.userId,
            name: name ?? existing.name,
            waterType: waterType ?? existing.waterType,
            capacity: capacity ?? existing.capacity,
            imageUrl: imageUrl ?? existing.imageUrl,
            createdAt: existing.createdAt,
          );
          final model = AquariumModel.fromEntity(updated);
          await _localDataSource.updateAquarium(model);

          // TODO: Queue for sync when online
          return Right(updated);
        }
        return const Left(CacheFailure(message: 'Aquarium not found locally'));
      }
      return Left(_mapApiExceptionToFailure(e));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAquarium(String aquariumId) async {
    try {
      await _remoteDataSource.deleteAquarium(aquariumId);

      // Delete from local cache
      await _localDataSource.deleteAquarium(aquariumId);

      return const Right(unit);
    } on ApiException catch (e) {
      // On network failure, delete locally and queue for sync
      if (e is NetworkException) {
        await _localDataSource.deleteAquarium(aquariumId);

        // TODO: Queue deletion for sync when online
        return const Right(unit);
      }
      return Left(_mapApiExceptionToFailure(e));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<Aquarium>>> syncAquariums() async {
    try {
      final dtos = await _remoteDataSource.getAquariums();
      final aquariums = dtos.map((dto) => dto.toEntity()).toList();

      // Replace local cache with server data
      final currentUser = _authLocalDataSource.getCurrentUser();
      if (currentUser != null) {
        final models = aquariums.map(AquariumModel.fromEntity).toList();
        await _localDataSource.replaceAllForUser(currentUser.id, models);
      }

      return Right(aquariums);
    } on ApiException catch (e) {
      return Left(_mapApiExceptionToFailure(e));
    } catch (_) {
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Either<Failure, List<Aquarium>> getCachedAquariums() {
    final currentUser = _authLocalDataSource.getCurrentUser();
    if (currentUser == null) {
      return const Left(CacheFailure(message: 'No user logged in'));
    }

    final models = _localDataSource.getAquariumsByUserId(currentUser.id);
    if (models.isEmpty) {
      return const Left(CacheFailure(message: 'No aquariums cached'));
    }

    final aquariums = models.map((m) => m.toEntity()).toList();
    return Right(aquariums);
  }

  /// Maps [ApiException] to domain [Failure].
  Failure _mapApiExceptionToFailure(ApiException exception) {
    return switch (exception) {
      NetworkException() => const NetworkFailure(),
      UnauthorizedException() =>
        const AuthenticationFailure(message: 'Session expired'),
      ValidationException(:final message, :final errors) =>
        ValidationFailure(message: message, errors: errors),
      ForbiddenException() =>
        const AuthenticationFailure(message: 'Access denied'),
      NotFoundException() =>
        const CacheFailure(message: 'Aquarium not found'),
      ServerException() => const ServerFailure(),
      UnknownApiException(:final message) =>
        UnexpectedFailure(message: message),
    };
  }
}

/// Provider for [AquariumRepository].
///
/// Usage:
/// ```dart
/// final aquariumRepo = ref.watch(aquariumRepositoryProvider);
/// final result = await aquariumRepo.createAquarium(name: 'My Tank');
/// result.fold(
///   (failure) => print('Error: ${failure.message}'),
///   (aquarium) => print('Created: ${aquarium.name}'),
/// );
/// ```
final aquariumRepositoryProvider = Provider<AquariumRepository>((ref) {
  final remoteDataSource = ref.watch(aquariumRemoteDataSourceProvider);
  final localDataSource = ref.watch(aquariumLocalDataSourceProvider);
  final authLocalDataSource = ref.watch(authLocalDataSourceProvider);

  return AquariumRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    authLocalDataSource: authLocalDataSource,
  );
});
