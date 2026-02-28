import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/domain/repositories/aquarium_repository.dart';

/// Implementation of [AquariumRepository].
///
/// All reads are local-only (Hive). Server communication happens
/// exclusively through [SyncService].
class AquariumRepositoryImpl implements AquariumRepository {
  AquariumRepositoryImpl({
    required AquariumLocalDataSource localDataSource,
    required AuthLocalDataSource authLocalDataSource,
  }) : _localDataSource = localDataSource,
       _authLocalDataSource = authLocalDataSource;

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
      // Create locally with UUID; sync mechanism will push to server
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

      return Right(aquarium);
    } catch (e, st) {
      debugPrint('AquariumRepository.createAquarium failed: $e\n$st');
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Aquarium>>> getAquariums() async {
    final currentUser = _authLocalDataSource.getCurrentUser();
    if (currentUser == null) {
      return const Left(AuthenticationFailure(message: 'User not logged in'));
    }

    try {
      final models = _localDataSource.getAquariumsByUserId(currentUser.id);
      final aquariums = models
          .where((m) => !m.isDeleted)
          .map((m) => m.toEntity())
          .toList();
      return Right(aquariums);
    } catch (e, st) {
      debugPrint('AquariumRepository.getAquariums failed: $e\n$st');
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Aquarium>> getAquariumById(String aquariumId) async {
    final cached = _localDataSource.getAquariumById(aquariumId);
    if (cached != null && !cached.isDeleted) {
      return Right(cached.toEntity());
    }

    return const Left(CacheFailure(message: 'Aquarium not found locally'));
  }

  @override
  Future<Either<Failure, Aquarium>> updateAquarium({
    required String aquariumId,
    String? name,
    WaterType? waterType,
    double? capacity,
    String? photoKey,
    bool clearPhotoKey = false,
  }) async {
    try {
      // Update locally; sync mechanism will push to server
      final existing = _localDataSource.getAquariumById(aquariumId);
      if (existing == null) {
        return const Left(CacheFailure(message: 'Aquarium not found locally'));
      }

      final updated = Aquarium(
        id: existing.id,
        userId: existing.userId,
        name: name ?? existing.name,
        waterType: waterType ?? existing.waterType,
        capacity: capacity ?? existing.capacity,
        photoKey: clearPhotoKey ? null : (photoKey ?? existing.photoKey),
        createdAt: existing.createdAt,
        synced: false,
        updatedAt: DateTime.now(),
        serverUpdatedAt: existing.serverUpdatedAt,
        deletedAt: existing.deletedAt,
        conflictStatus: existing.conflictStatus,
      );
      final model = AquariumModel.fromEntity(updated);
      await _localDataSource.updateAquarium(model);

      return Right(updated);
    } catch (e, st) {
      debugPrint('AquariumRepository.updateAquarium failed: $e\n$st');
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAquarium(String aquariumId) async {
    try {
      // Soft delete locally; sync mechanism will push deletion to server
      await _localDataSource.softDelete(aquariumId);
      return const Right(unit);
    } catch (e, st) {
      debugPrint('AquariumRepository.deleteAquarium failed: $e\n$st');
      return Left(UnexpectedFailure(message: e.toString()));
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
}

/// Provider for [AquariumRepository].
final aquariumRepositoryProvider = Provider<AquariumRepository>((ref) {
  final localDataSource = ref.watch(aquariumLocalDataSourceProvider);
  final authLocalDataSource = ref.watch(authLocalDataSourceProvider);

  return AquariumRepositoryImpl(
    localDataSource: localDataSource,
    authLocalDataSource: authLocalDataSource,
  );
});
