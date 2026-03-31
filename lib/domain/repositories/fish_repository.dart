import 'package:fishfeed/domain/entities/fish.dart';

/// Repository interface for fish CRUD operations.
///
/// Provides a clean API for fish management following Clean Architecture.
/// All methods work with domain [Fish] entities, hiding data layer details.
abstract interface class FishRepository {
  /// Gets all active (non-deleted) fish.
  List<Fish> getAllFish();

  /// Gets a single fish by its ID.
  ///
  /// Returns `null` if no fish with the given ID exists.
  Fish? getFishById(String id);

  /// Gets all active fish for a specific aquarium.
  ///
  /// Returns a deduplicated list sorted by added date (newest first).
  List<Fish> getFishByAquariumId(String aquariumId);

  /// Saves a new fish to storage.
  Future<void> saveFish(Fish fish);

  /// Updates an existing fish.
  ///
  /// Returns `true` if the fish was updated, `false` if it doesn't exist.
  Future<bool> updateFish(Fish fish);

  /// Soft deletes a fish by ID.
  ///
  /// Sets deletedAt timestamp instead of removing from storage,
  /// allowing sync to propagate the deletion to the server.
  Future<void> softDelete(String id);

  /// Updates a fish's photo key in local storage only.
  ///
  /// Sets `updatedAt` to now and marks as unsynced to prevent LWW conflicts.
  /// Used by the image upload system after a successful photo upload.
  Future<void> updatePhotoKeyLocally({
    required String fishId,
    required String photoKey,
  });
}
