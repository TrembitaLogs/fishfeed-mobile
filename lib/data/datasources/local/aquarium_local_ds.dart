import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/domain/entities/water_type.dart';

/// Data source for managing aquarium records in local Hive storage.
///
/// Provides CRUD operations for aquariums with offline-first support.
/// Aquariums are associated with users and contain fish.
///
/// Example:
/// ```dart
/// final aquariumDs = AquariumLocalDataSource();
/// await aquariumDs.saveAquarium(aquariumModel);
/// final aquariums = aquariumDs.getAllAquariums();
/// ```
class AquariumLocalDataSource {
  AquariumLocalDataSource({Box<dynamic>? aquariumBox})
    : _aquariumBox = aquariumBox;

  final Box<dynamic>? _aquariumBox;

  /// Gets the aquarium box, using the injected box or the default HiveBoxes.
  Box<dynamic> get _aquariums => _aquariumBox ?? HiveBoxes.aquariums;

  // ============ CRUD Operations ============

  /// Retrieves all aquariums from local storage.
  ///
  /// Returns a list of all aquariums sorted by creation date (newest first).
  List<AquariumModel> getAllAquariums() {
    final aquariums = _aquariums.values.whereType<AquariumModel>().toList();
    aquariums.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return aquariums;
  }

  /// Alias for [getAllAquariums]. Preferred in use-case layer for consistency
  /// with other local data sources.
  List<AquariumModel> getAll() => getAllAquariums();

  /// Retrieves a single aquarium by its ID.
  ///
  /// [id] - The unique identifier of the aquarium.
  /// Returns `null` if no aquarium with the given ID exists.
  AquariumModel? getAquariumById(String id) {
    final aquarium = _aquariums.get(id);
    if (aquarium is AquariumModel) {
      return aquarium;
    }
    return null;
  }

  /// Retrieves all aquariums for a specific user.
  ///
  /// [userId] - The ID of the user to filter by.
  /// Returns a list of aquariums sorted by creation date (newest first).
  List<AquariumModel> getAquariumsByUserId(String userId) {
    final aquariums = _aquariums.values
        .whereType<AquariumModel>()
        .where((a) => a.userId == userId)
        .toList();

    aquariums.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return aquariums;
  }

  /// Saves a new aquarium to local storage.
  ///
  /// [aquarium] - The aquarium model to store.
  /// The aquarium is stored with its [id] as the key.
  Future<void> saveAquarium(AquariumModel aquarium) async {
    await _aquariums.put(aquarium.id, aquarium);
  }

  /// Updates an existing aquarium in local storage.
  ///
  /// [aquarium] - The updated aquarium model.
  /// Returns `true` if the aquarium was updated, `false` if it doesn't exist.
  Future<bool> updateAquarium(AquariumModel aquarium) async {
    final existing = getAquariumById(aquarium.id);
    if (existing == null) {
      return false;
    }
    await _aquariums.put(aquarium.id, aquarium);
    return true;
  }

  /// Deletes an aquarium from local storage.
  ///
  /// [id] - The unique identifier of the aquarium to delete.
  /// Returns `true` if the aquarium was deleted, `false` if it didn't exist.
  Future<bool> deleteAquarium(String id) async {
    final existing = getAquariumById(id);
    if (existing == null) {
      return false;
    }
    await _aquariums.delete(id);
    return true;
  }

  // ============ Query Methods ============

  /// Returns the total count of aquariums in local storage.
  int getAquariumCount() {
    return _aquariums.values.whereType<AquariumModel>().length;
  }

  /// Returns the count of aquariums for a specific user.
  ///
  /// [userId] - The ID of the user to count aquariums for.
  int getAquariumCountByUserId(String userId) {
    return _aquariums.values
        .whereType<AquariumModel>()
        .where((a) => a.userId == userId)
        .length;
  }

  /// Gets the first aquarium (by creation date) for a user.
  ///
  /// Useful for migration scenarios where a default aquarium is needed.
  /// [userId] - The ID of the user.
  /// Returns `null` if no aquariums exist for the user.
  AquariumModel? getFirstAquariumByUserId(String userId) {
    final aquariums = getAquariumsByUserId(userId);
    if (aquariums.isEmpty) {
      return null;
    }
    // Sort by creation date ascending to get the oldest
    aquariums.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return aquariums.first;
  }

  /// Finds aquariums with the legacy 'default' ID pattern.
  ///
  /// Used during migration from old aquarium_id='default' to real UUIDs.
  /// Returns list of aquariums that might need migration.
  List<AquariumModel> findLegacyAquariums() {
    return _aquariums.values
        .whereType<AquariumModel>()
        .where((a) => a.id == 'default' || a.id.isEmpty)
        .toList();
  }

  // ============ Utility Methods ============

  /// Clears all aquariums from local storage.
  ///
  /// Use with caution - this permanently deletes all local aquarium data.
  Future<void> clearAll() async {
    await _aquariums.clear();
  }

  /// Saves multiple aquariums at once.
  ///
  /// [aquariumList] - List of aquarium models to save.
  /// Useful for batch operations during sync.
  Future<void> saveMultipleAquariums(List<AquariumModel> aquariumList) async {
    for (final aquarium in aquariumList) {
      await _aquariums.put(aquarium.id, aquarium);
    }
  }

  /// Replaces all aquariums for a user with new data.
  ///
  /// [userId] - The ID of the user whose aquariums to replace.
  /// [aquariums] - The new list of aquariums.
  /// Useful for full sync operations.
  Future<void> replaceAllForUser(
    String userId,
    List<AquariumModel> aquariums,
  ) async {
    // Delete existing aquariums for user
    final existing = getAquariumsByUserId(userId);
    for (final aquarium in existing) {
      await _aquariums.delete(aquarium.id);
    }

    // Save new aquariums
    await saveMultipleAquariums(aquariums);
  }

  // ============ Sync Methods ============

  /// Retrieves all unsynced aquariums.
  ///
  /// Returns aquariums where synced=false OR updatedAt > serverUpdatedAt.
  List<AquariumModel> getUnsyncedAquariums() {
    return _aquariums.values
        .whereType<AquariumModel>()
        .where((a) => !a.isDeleted && a.needsSync)
        .toList();
  }

  /// Retrieves all modified aquariums (updatedAt > serverUpdatedAt).
  ///
  /// These aquariums have been changed locally since last server sync.
  List<AquariumModel> getModifiedAquariums() {
    return _aquariums.values
        .whereType<AquariumModel>()
        .where(
          (a) =>
              !a.isDeleted &&
              a.updatedAt != null &&
              a.serverUpdatedAt != null &&
              a.updatedAt!.isAfter(a.serverUpdatedAt!),
        )
        .toList();
  }

  /// Retrieves all soft-deleted aquariums.
  ///
  /// These aquariums need to be synced as deletions to the server.
  List<AquariumModel> getDeletedAquariums() {
    return _aquariums.values
        .whereType<AquariumModel>()
        .where((a) => a.isDeleted)
        .toList();
  }

  /// Soft deletes an aquarium.
  ///
  /// Sets deletedAt to current time instead of removing from storage.
  /// This allows syncing the deletion to the server.
  Future<void> softDelete(String id) async {
    final existing = getAquariumById(id);
    if (existing == null) return;

    existing.deletedAt = DateTime.now();
    existing.updatedAt = DateTime.now();
    existing.synced = false;
    await existing.save();
  }

  /// Marks an aquarium as synced with the server.
  ///
  /// [id] - The aquarium ID.
  /// [serverUpdatedAt] - The server's updated_at timestamp.
  Future<void> markAsSynced(String id, DateTime serverUpdatedAt) async {
    final existing = getAquariumById(id);
    if (existing == null) return;

    existing.synced = true;
    existing.serverUpdatedAt = serverUpdatedAt;
    await existing.save();
  }

  /// Marks multiple aquariums as synced.
  ///
  /// [ids] - List of aquarium IDs.
  /// [serverTime] - The server timestamp to use.
  Future<void> markMultipleAsSynced(
    List<String> ids,
    DateTime serverTime,
  ) async {
    for (final id in ids) {
      await markAsSynced(id, serverTime);
    }
  }

  /// Applies a server update to a local aquarium.
  ///
  /// Updates local data with server data if server version is newer.
  /// [serverData] - The data from the server.
  Future<void> applyServerUpdate(Map<String, dynamic> serverData) async {
    final id = serverData['id'] as String;
    final existing = getAquariumById(id);

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

      // Update existing aquarium
      existing.name = serverData['name'] as String? ?? existing.name;
      if (serverData['water_type'] != null) {
        existing.waterType = _parseWaterType(
          serverData['water_type'] as String?,
        );
      }
      if (serverData['capacity'] != null) {
        final rawCapacity = serverData['capacity'];
        if (rawCapacity is double) {
          existing.capacity = rawCapacity;
        } else if (rawCapacity is int) {
          existing.capacity = rawCapacity.toDouble();
        } else if (rawCapacity is String) {
          existing.capacity = double.tryParse(rawCapacity);
        }
      }
      // Use containsKey to distinguish "not sent" from "set to null"
      if (serverData.containsKey('photo_key')) {
        existing.photoKey = serverData['photo_key'] as String?;
      }
      existing.synced = true;
      existing.serverUpdatedAt = serverUpdatedAt;
      existing.updatedAt = serverUpdatedAt;
      await existing.save();
    } else {
      // Create new aquarium from server data
      final rawCapacity = serverData['capacity'];
      double? parsedCapacity;
      if (rawCapacity is double) {
        parsedCapacity = rawCapacity;
      } else if (rawCapacity is int) {
        parsedCapacity = rawCapacity.toDouble();
      } else if (rawCapacity is String) {
        parsedCapacity = double.tryParse(rawCapacity);
      }

      final aquarium = AquariumModel(
        id: id,
        userId: serverData['owner_id'] as String? ?? '',
        name: serverData['name'] as String? ?? 'Unnamed Aquarium',
        capacity: parsedCapacity,
        waterType: _parseWaterType(serverData['water_type'] as String?),
        photoKey: serverData['photo_key'] as String?,
        createdAt: serverData['created_at'] != null
            ? DateTime.tryParse(serverData['created_at'] as String) ??
                  DateTime.now()
            : DateTime.now(),
        synced: true,
        serverUpdatedAt: serverUpdatedAt,
        updatedAt: serverUpdatedAt,
      );
      await saveAquarium(aquarium);
    }
  }

  /// Permanently removes soft-deleted aquariums that have been synced.
  ///
  /// Call this after confirming deletions have been synced to the server.
  Future<void> purgeSyncedDeletions() async {
    final deleted = getDeletedAquariums().where((a) => a.synced).toList();
    for (final aquarium in deleted) {
      await _aquariums.delete(aquarium.id);
    }
  }

  /// Parses a water type string from the server into a [WaterType] enum.
  ///
  /// Falls back to [WaterType.freshwater] for null or unknown values.
  static WaterType _parseWaterType(String? value) {
    if (value == null) {
      return WaterType.freshwater;
    }
    for (final type in WaterType.values) {
      if (type.name == value) {
        return type;
      }
    }
    return WaterType.freshwater;
  }
}
