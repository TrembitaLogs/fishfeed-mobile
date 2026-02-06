import 'package:uuid/uuid.dart';

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
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
/// This service handles the one-time migration of existing fish
/// that were created with the hardcoded 'default' aquariumId to use
/// a properly generated UUID-based aquarium.
///
/// Example:
/// ```dart
/// final migrationService = MigrationService(
///   aquariumLocalDs: aquariumDs,
///   fishLocalDs: fishDs,
///   authLocalDs: authDs,
/// );
///
/// if (migrationService.needsMigration()) {
///   final result = await migrationService.migrateDefaultAquarium();
/// }
/// ```
class MigrationService {
  MigrationService({
    required AquariumLocalDataSource aquariumLocalDs,
    required FishLocalDataSource fishLocalDs,
    required AuthLocalDataSource authLocalDs,
  }) : _aquariumLocalDs = aquariumLocalDs,
       _fishLocalDs = fishLocalDs,
       _authLocalDs = authLocalDs;

  final AquariumLocalDataSource _aquariumLocalDs;
  final FishLocalDataSource _fishLocalDs;
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
  ///
  /// Note: Feeding logs are not migrated as the new architecture (Task 25)
  /// uses FeedingLogModel which is created fresh after migration.
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

      return MigrationSuccess(
        migratedFishCount: migratedFishCount,
        migratedEventsCount: 0,
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

  /// Clears the legacy syncQueue Hive box.
  ///
  /// The syncQueue is no longer used - all sync now goes through
  /// ChangeTracker -> POST /sync. This cleans up leftover data.
  Future<void> clearLegacySyncQueue() async {
    final box = HiveBoxes.syncQueue;
    if (box.isNotEmpty) {
      await box.clear();
    }
  }
}
