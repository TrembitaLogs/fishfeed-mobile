import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/water_type.dart';

/// Repository interface for aquarium operations.
///
/// Provides a clean API for aquarium management following Clean Architecture.
/// All methods return [Either] type for explicit error handling.
/// Implements offline-first approach: saves locally first, then syncs to server.
abstract interface class AquariumRepository {
  /// Creates a new aquarium.
  ///
  /// [name] - The name of the aquarium.
  /// [waterType] - Optional water type (defaults to freshwater).
  /// [capacity] - Optional capacity in liters.
  ///
  /// Returns [Right(Aquarium)] on success with server-generated ID.
  /// Returns [Left(Failure)] on error:
  /// - [ValidationFailure] for invalid input
  /// - [NetworkFailure] for connectivity issues (aquarium saved locally)
  /// - [ServerFailure] for server errors
  Future<Either<Failure, Aquarium>> createAquarium({
    required String name,
    WaterType? waterType,
    double? capacity,
  });

  /// Gets all aquariums for the current user from local storage.
  ///
  /// Reads from Hive only. Server data is fetched via [SyncService].
  ///
  /// Returns [Right(List<Aquarium>)] on success (may be empty).
  /// Returns [Left(Failure)] on error:
  /// - [AuthenticationFailure] if no user is logged in
  Future<Either<Failure, List<Aquarium>>> getAquariums();

  /// Gets a specific aquarium by ID from local storage.
  ///
  /// Reads from Hive only. Server data is fetched via [SyncService].
  ///
  /// [aquariumId] - The unique identifier of the aquarium.
  ///
  /// Returns [Right(Aquarium)] if found locally.
  /// Returns [Left(CacheFailure)] if not found.
  Future<Either<Failure, Aquarium>> getAquariumById(String aquariumId);

  /// Updates an existing aquarium.
  ///
  /// [aquariumId] - The unique identifier of the aquarium to update.
  /// [name] - Optional new name.
  /// [waterType] - Optional new water type.
  /// [capacity] - Optional new capacity.
  /// [imageUrl] - Optional new image URL.
  ///
  /// Returns [Right(Aquarium)] with updated data on success.
  /// Returns [Left(Failure)] on error:
  /// - [ValidationFailure] for invalid input
  /// - [NetworkFailure] for connectivity issues (changes saved locally)
  /// - [ServerFailure] for server errors
  Future<Either<Failure, Aquarium>> updateAquarium({
    required String aquariumId,
    String? name,
    WaterType? waterType,
    double? capacity,
    String? imageUrl,
  });

  /// Deletes an aquarium.
  ///
  /// [aquariumId] - The unique identifier of the aquarium to delete.
  ///
  /// Returns [Right(unit)] on success.
  /// Returns [Left(Failure)] on error:
  /// - [NetworkFailure] for connectivity issues (deletion queued)
  /// - [ServerFailure] for server errors
  Future<Either<Failure, Unit>> deleteAquarium(String aquariumId);

  /// Gets aquariums from local cache only.
  ///
  /// Does not make any network requests.
  ///
  /// Returns [Right(List<Aquarium>)] with cached data.
  /// Returns [Left(CacheFailure)] if cache is empty.
  Either<Failure, List<Aquarium>> getCachedAquariums();
}
