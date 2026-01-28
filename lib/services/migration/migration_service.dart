import 'package:uuid/uuid.dart';

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/domain/entities/water_type.dart';

/// Result of a migration operation.
sealed class MigrationResult {
  const MigrationResult();
}

/// No migration was needed - no data with 'default' aquariumId found.
class NoMigrationNeeded extends MigrationResult {
  const NoMigrationNeeded();
}

/// Migration completed successfully.
class MigrationSuccess extends MigrationResult {
  const MigrationSuccess({
    required this.migratedFishCount,
    required this.migratedEventsCount,
    required this.newAquariumId,
    required this.newAquariumName,
  });

  final int migratedFishCount;
  final int migratedEventsCount;
  final String newAquariumId;
  final String newAquariumName;
}

/// Migration failed with an error.
class MigrationError extends MigrationResult {
  const MigrationError({required this.message, this.error});

  final String message;
  final Object? error;
}

/// Service for migrating data from legacy 'default' aquariumId to real UUIDs.
///
/// This service handles the one-time migration of existing fish and feeding
/// events that were created with the hardcoded 'default' aquariumId to use
/// a properly generated UUID-based aquarium.
///
/// Example:
/// ```dart
/// final migrationService = MigrationService(
///   aquariumLocalDs: aquariumDs,
///   fishLocalDs: fishDs,
///   feedingLocalDs: feedingDs,
///   authLocalDs: authDs,
/// );
///
/// if (await migrationService.needsMigration()) {
///   final result = await migrationService.migrateDefaultAquarium();
/// }
/// ```
class MigrationService {
  MigrationService({
    required AquariumLocalDataSource aquariumLocalDs,
    required FishLocalDataSource fishLocalDs,
    required FeedingLocalDataSource feedingLocalDs,
    required AuthLocalDataSource authLocalDs,
  })  : _aquariumLocalDs = aquariumLocalDs,
        _fishLocalDs = fishLocalDs,
        _feedingLocalDs = feedingLocalDs,
        _authLocalDs = authLocalDs;

  final AquariumLocalDataSource _aquariumLocalDs;
  final FishLocalDataSource _fishLocalDs;
  final FeedingLocalDataSource _feedingLocalDs;
  final AuthLocalDataSource _authLocalDs;

  static const String defaultAquariumId = 'default';
  static const String defaultAquariumName = 'My Aquarium';

  /// Checks if migration is needed.
  ///
  /// Returns `true` if there are fish records with aquariumId='default',
  /// indicating that data needs to be migrated to a real UUID-based aquarium.
  bool needsMigration() {
    final allFish = _fishLocalDs.getAllFish();
    return allFish.any((fish) => fish.aquariumId == defaultAquariumId);
  }

  /// Migrates all data from 'default' aquariumId to a new UUID-based aquarium.
  ///
  /// This method:
  /// 1. Creates a new aquarium named 'My Aquarium' with a proper UUID
  /// 2. Updates all fish records with aquariumId='default' to use the new UUID
  /// 3. Updates all feeding events with aquariumId='default' to use the new UUID
  ///
  /// Returns [MigrationResult] indicating the outcome:
  /// - [NoMigrationNeeded] if no data needs migration
  /// - [MigrationSuccess] if migration completed successfully
  /// - [MigrationError] if an error occurred during migration
  Future<MigrationResult> migrateDefaultAquarium() async {
    try {
      // 1. Find all fish with 'default' aquariumId
      final defaultFish = _fishLocalDs
          .getAllFish()
          .where((fish) => fish.aquariumId == defaultAquariumId)
          .toList();

      if (defaultFish.isEmpty) {
        return const NoMigrationNeeded();
      }

      // 2. Get current user ID (fallback to 'local' if no user)
      final currentUser = _authLocalDs.getCurrentUser();
      final userId = currentUser?.id ?? 'local';

      // 3. Create new aquarium with UUID
      final newAquariumId = const Uuid().v4();
      final newAquarium = AquariumModel(
        id: newAquariumId,
        userId: userId,
        name: defaultAquariumName,
        waterType: WaterType.freshwater,
        createdAt: DateTime.now(),
      );

      await _aquariumLocalDs.saveAquarium(newAquarium);

      // 4. Update all fish records with new aquariumId
      int migratedFishCount = 0;
      for (final fish in defaultFish) {
        fish.aquariumId = newAquariumId;
        await _fishLocalDs.updateFish(fish);
        migratedFishCount++;
      }

      // 5. Update all feeding events with new aquariumId
      int migratedEventsCount = 0;
      final allEvents = _feedingLocalDs.getAllFeedingEvents();
      final defaultEvents = allEvents
          .where((event) => event.aquariumId == defaultAquariumId)
          .toList();

      for (final event in defaultEvents) {
        event.aquariumId = newAquariumId;
        await _feedingLocalDs.updateFeedingEvent(event);
        migratedEventsCount++;
      }

      return MigrationSuccess(
        migratedFishCount: migratedFishCount,
        migratedEventsCount: migratedEventsCount,
        newAquariumId: newAquariumId,
        newAquariumName: defaultAquariumName,
      );
    } catch (e) {
      return MigrationError(
        message: 'Failed to migrate default aquarium data',
        error: e,
      );
    }
  }

  /// Checks if feeding events need fish ID migration.
  ///
  /// Returns `true` if there are feeding events where fishId is a species ID
  /// (not a valid UUID) instead of an actual fish UUID.
  bool needsFishIdMigration() {
    final allEvents = _feedingLocalDs.getAllFeedingEvents();
    // A species ID is NOT a valid UUID (e.g., "guppy", "angelfish")
    // An actual fish ID IS a valid UUID (36 characters with dashes)
    return allEvents.any((event) {
      // UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx (36 chars)
      return event.fishId.length != 36 || !event.fishId.contains('-');
    });
  }

  /// Migrates feeding events' fishId from speciesId to actual fish UUID.
  ///
  /// For each feeding event with a species ID as fishId:
  /// 1. Find the fish with that species in the same aquarium
  /// 2. Update the event's fishId to the fish's actual UUID
  ///
  /// Events where no matching fish is found are deleted (orphaned events).
  Future<MigrationResult> migrateFeedingEventFishIds() async {
    try {
      final allEvents = _feedingLocalDs.getAllFeedingEvents();
      final allFish = _fishLocalDs.getAllFish();

      // Build a map of (aquariumId, speciesId) -> fishId
      final fishLookup = <String, String>{};
      for (final fish in allFish) {
        final key = '${fish.aquariumId}:${fish.speciesId}';
        fishLookup[key] = fish.id;
      }

      int migratedCount = 0;
      int deletedCount = 0;

      for (final event in allEvents) {
        final fishId = event.fishId;

        // Check if fishId is already a valid UUID (36 chars with dashes)
        if (fishId.length == 36 && fishId.contains('-')) {
          continue; // Already migrated
        }

        // fishId is actually a speciesId - need to migrate
        final lookupKey = '${event.aquariumId}:$fishId';
        final actualFishId = fishLookup[lookupKey];

        if (actualFishId != null) {
          // Update event with actual fish ID
          event.fishId = actualFishId;
          event.synced = false;
          await _feedingLocalDs.updateFeedingEvent(event);
          migratedCount++;
        } else {
          // No matching fish found - delete orphaned event
          await _feedingLocalDs.deleteEvent(event.id);
          deletedCount++;
        }
      }

      if (migratedCount == 0 && deletedCount == 0) {
        return const NoMigrationNeeded();
      }

      return MigrationSuccess(
        migratedFishCount: 0,
        migratedEventsCount: migratedCount,
        newAquariumId: '',
        newAquariumName: 'Migrated $migratedCount events, deleted $deletedCount orphaned',
      );
    } catch (e) {
      return MigrationError(
        message: 'Failed to migrate feeding event fish IDs',
        error: e,
      );
    }
  }
}
