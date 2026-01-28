import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/fish_model.dart';

/// Data source for managing fish records in local Hive storage.
///
/// Provides CRUD operations for fish with offline-first support.
/// Fish records are associated with aquariums and species.
///
/// Example:
/// ```dart
/// final fishDs = FishLocalDataSource();
/// await fishDs.saveFish(fishModel);
/// final fish = fishDs.getFishByAquariumId('aquarium_123');
/// ```
class FishLocalDataSource {
  FishLocalDataSource({Box<dynamic>? fishBox}) : _fishBox = fishBox;

  final Box<dynamic>? _fishBox;

  /// Gets the fish box, using the injected box or the default HiveBoxes.
  Box<dynamic> get _fish => _fishBox ?? HiveBoxes.fish;

  // ============ CRUD Operations ============

  /// Retrieves all active (non-deleted) fish from local storage.
  ///
  /// Returns a list of all fish sorted by added date (newest first).
  /// Excludes soft-deleted fish (those with deletedAt != null).
  List<FishModel> getAllFish() {
    final fish = _fish.values
        .whereType<FishModel>()
        .where((f) => f.deletedAt == null)
        .toList();
    fish.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return fish;
  }

  /// Retrieves a single fish by its ID.
  ///
  /// [id] - The unique identifier of the fish.
  /// Returns `null` if no fish with the given ID exists.
  FishModel? getFishById(String id) {
    final fish = _fish.get(id);
    if (fish is FishModel) {
      return fish;
    }
    return null;
  }

  /// Retrieves all active (non-deleted) fish for a specific aquarium.
  ///
  /// [aquariumId] - The ID of the aquarium to filter by.
  /// Returns a list of fish sorted by added date (newest first).
  /// Excludes soft-deleted fish (those with deletedAt != null).
  /// Deduplicates by ID in case of Hive file issues.
  List<FishModel> getFishByAquariumId(String aquariumId) {
    final allFish = _fish.values.whereType<FishModel>().where(
      (f) => f.aquariumId == aquariumId && f.deletedAt == null,
    );

    // Deduplicate by ID, keeping the most recent version
    final fishMap = <String, FishModel>{};
    for (final f in allFish) {
      fishMap[f.id] = f;
    }

    final fish = fishMap.values.toList();
    fish.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return fish;
  }

  /// Saves a new fish to local storage.
  ///
  /// [fish] - The fish model to store.
  /// The fish is stored with its [id] as the key.
  Future<void> saveFish(FishModel fish) async {
    await _fish.put(fish.id, fish);
  }

  /// Updates an existing fish in local storage.
  ///
  /// [fish] - The updated fish model.
  /// Returns `true` if the fish was updated, `false` if it doesn't exist.
  Future<bool> updateFish(FishModel fish) async {
    final existing = getFishById(fish.id);
    if (existing == null) {
      return false;
    }
    await _fish.put(fish.id, fish);
    return true;
  }

  /// Deletes a fish from local storage.
  ///
  /// [id] - The unique identifier of the fish to delete.
  /// Returns `true` if the fish was deleted, `false` if it didn't exist.
  Future<bool> deleteFish(String id) async {
    final existing = getFishById(id);
    if (existing == null) {
      return false;
    }
    await _fish.delete(id);
    return true;
  }

  // ============ Query Methods ============

  /// Retrieves all fish for a specific species.
  ///
  /// [speciesId] - The ID of the species to filter by.
  /// Returns a list of fish sorted by added date (newest first).
  List<FishModel> getFishBySpeciesId(String speciesId) {
    final fish = _fish.values
        .whereType<FishModel>()
        .where((f) => f.speciesId == speciesId)
        .toList();

    fish.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return fish;
  }

  /// Returns the total count of fish in local storage.
  int getFishCount() {
    return _fish.values.whereType<FishModel>().length;
  }

  /// Returns the count of fish for a specific aquarium.
  ///
  /// [aquariumId] - The ID of the aquarium to count fish for.
  int getFishCountByAquariumId(String aquariumId) {
    return _fish.values
        .whereType<FishModel>()
        .where((f) => f.aquariumId == aquariumId)
        .length;
  }

  // ============ Sync Methods ============

  /// Retrieves all fish that haven't been synced to the server.
  ///
  /// Returns fish where synced=false OR updatedAt > serverUpdatedAt.
  List<FishModel> getUnsyncedFish() {
    return _fish.values
        .whereType<FishModel>()
        .where((f) => !f.isDeleted && f.needsSync)
        .toList();
  }

  /// Retrieves all modified fish (updatedAt > serverUpdatedAt).
  ///
  /// These fish have been changed locally since last server sync.
  List<FishModel> getModifiedFish() {
    return _fish.values
        .whereType<FishModel>()
        .where(
          (f) =>
              !f.isDeleted &&
              f.updatedAt != null &&
              f.serverUpdatedAt != null &&
              f.updatedAt!.isAfter(f.serverUpdatedAt!),
        )
        .toList();
  }

  /// Retrieves all soft-deleted fish.
  ///
  /// These fish need to be synced as deletions to the server.
  List<FishModel> getDeletedFish() {
    return _fish.values
        .whereType<FishModel>()
        .where((f) => f.isDeleted)
        .toList();
  }

  /// Soft deletes a fish.
  ///
  /// Sets deletedAt to current time instead of removing from storage.
  /// This allows syncing the deletion to the server.
  Future<void> softDelete(String id) async {
    final fish = getFishById(id);
    if (fish == null) return;

    fish.deletedAt = DateTime.now();
    fish.updatedAt = DateTime.now();
    fish.synced = false;
    await fish.save();
  }

  /// Marks a fish as synced with the server.
  ///
  /// [id] - The unique identifier of the fish.
  /// [serverUpdatedAt] - The server's updated_at timestamp.
  /// Returns `true` if the fish was marked, `false` if it doesn't exist.
  Future<bool> markAsSynced(String id, [DateTime? serverUpdatedAt]) async {
    final fish = getFishById(id);
    if (fish == null) {
      return false;
    }
    fish.synced = true;
    if (serverUpdatedAt != null) {
      fish.serverUpdatedAt = serverUpdatedAt;
    }
    await _fish.put(fish.id, fish);
    return true;
  }

  /// Marks multiple fish as synced.
  ///
  /// [ids] - List of fish IDs.
  /// [serverTime] - The server timestamp to use.
  Future<void> markMultipleAsSynced(
    List<String> ids,
    DateTime serverTime,
  ) async {
    for (final id in ids) {
      await markAsSynced(id, serverTime);
    }
  }

  /// Applies a server update to a local fish.
  ///
  /// Updates local data with server data if server version is newer.
  /// [serverData] - The data from the server.
  Future<void> applyServerUpdate(Map<String, dynamic> serverData) async {
    final id = serverData['id'] as String;
    final existing = getFishById(id);

    final serverUpdatedAt = serverData['updated_at'] != null
        ? DateTime.tryParse(serverData['updated_at'] as String)
        : DateTime.now();

    if (existing != null) {
      // Check if server version is newer
      if (existing.serverUpdatedAt != null &&
          serverUpdatedAt != null &&
          !serverUpdatedAt.isAfter(existing.serverUpdatedAt!)) {
        // Local version is newer or equal, skip
        return;
      }

      // Update existing fish
      if (serverData['quantity'] != null) {
        existing.quantity = serverData['quantity'] as int;
      }
      if (serverData['custom_name'] != null) {
        existing.name = serverData['custom_name'] as String?;
      }
      if (serverData['species_id'] != null) {
        existing.speciesId = serverData['species_id'] as String;
      }
      existing.synced = true;
      existing.serverUpdatedAt = serverUpdatedAt;
      existing.updatedAt = serverUpdatedAt;
      await existing.save();
    } else {
      // Create new fish from server data
      final fish = FishModel(
        id: id,
        aquariumId: serverData['aquarium_id'] as String? ?? '',
        speciesId: serverData['species_id'] as String? ?? 'unknown',
        name: serverData['custom_name'] as String?,
        quantity: serverData['quantity'] as int? ?? 1,
        addedAt: serverData['created_at'] != null
            ? DateTime.tryParse(serverData['created_at'] as String) ??
                  DateTime.now()
            : DateTime.now(),
        synced: true,
        serverUpdatedAt: serverUpdatedAt,
        updatedAt: serverUpdatedAt,
      );
      await saveFish(fish);
    }
  }

  /// Checks if there are any unsynced fish.
  bool get hasUnsyncedFish => _fish.values.whereType<FishModel>().any(
    (f) => !f.isDeleted && f.needsSync,
  );

  /// Permanently removes soft-deleted fish that have been synced.
  ///
  /// Call this after confirming deletions have been synced to the server.
  Future<void> purgeSyncedDeletions() async {
    final deleted = getDeletedFish().where((f) => f.synced).toList();
    for (final fish in deleted) {
      await _fish.delete(fish.id);
    }
  }

  // ============ Utility Methods ============

  /// Clears all fish from local storage.
  ///
  /// Use with caution - this permanently deletes all local fish data.
  Future<void> clearAll() async {
    await _fish.clear();
  }

  /// Deletes all fish for a specific aquarium.
  ///
  /// [aquariumId] - The ID of the aquarium whose fish should be deleted.
  /// Returns the number of fish deleted.
  Future<int> deleteFishByAquariumId(String aquariumId) async {
    final fish = getFishByAquariumId(aquariumId);
    for (final f in fish) {
      await _fish.delete(f.id);
    }
    return fish.length;
  }

  /// Saves multiple fish at once.
  ///
  /// [fishList] - List of fish models to save.
  /// Useful for batch operations during onboarding or sync.
  Future<void> saveMultipleFish(List<FishModel> fishList) async {
    for (final fish in fishList) {
      await _fish.put(fish.id, fish);
    }
  }
}
