import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/core/constants/achievements.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/achievement_model.dart';
import 'package:fishfeed/domain/entities/achievement.dart';

/// Data source for managing achievements in local Hive storage.
///
/// Provides CRUD operations for user achievements with progress tracking.
///
/// Example:
/// ```dart
/// final achievementDs = AchievementLocalDataSource();
/// final achievements = achievementDs.getAchievements('user_123');
/// await achievementDs.unlockAchievement('user_123', AchievementType.streak7);
/// ```
class AchievementLocalDataSource {
  AchievementLocalDataSource({Box<dynamic>? achievementsBox})
    : _achievementsBox = achievementsBox;

  final Box<dynamic>? _achievementsBox;

  /// Gets the achievements box, using the injected box or the default HiveBoxes.
  Box<dynamic> get _achievements => _achievementsBox ?? HiveBoxes.achievements;

  // ============ CRUD Operations ============

  /// Creates or updates an achievement in local storage.
  ///
  /// [achievement] - The achievement model to store.
  Future<void> saveAchievement(AchievementModel achievement) async {
    await _achievements.put(achievement.id, achievement);
  }

  /// Retrieves an achievement by its ID.
  ///
  /// [id] - The unique identifier of the achievement.
  /// Returns `null` if no achievement with the given ID exists.
  AchievementModel? getAchievementById(String id) {
    final achievement = _achievements.get(id);
    if (achievement is AchievementModel) {
      return achievement;
    }
    return null;
  }

  /// Retrieves all achievements for a specific user.
  ///
  /// [userId] - The ID of the user whose achievements to retrieve.
  /// Returns a list of all achievements (both locked and unlocked).
  List<AchievementModel> getAchievements(String userId) {
    return _achievements.values
        .whereType<AchievementModel>()
        .where((a) => a.userId == userId)
        .toList();
  }

  /// Retrieves all unlocked achievements for a user.
  ///
  /// [userId] - The ID of the user.
  /// Returns only achievements that have been unlocked.
  List<AchievementModel> getUnlockedAchievements(String userId) {
    return getAchievements(userId).where((a) => a.unlockedAt != null).toList();
  }

  /// Gets an achievement by user ID and type.
  ///
  /// [userId] - The ID of the user.
  /// [type] - The achievement type.
  /// Returns null if not found.
  AchievementModel? getAchievementByType(String userId, AchievementType type) {
    final id = _createAchievementId(userId, type);
    return getAchievementById(id);
  }

  /// Checks if a specific achievement type is unlocked.
  ///
  /// [userId] - The ID of the user.
  /// [type] - The achievement type to check.
  bool isAchievementUnlocked(String userId, AchievementType type) {
    final achievement = getAchievementByType(userId, type);
    return achievement?.unlockedAt != null;
  }

  /// Gets the list of unlocked achievement types for a user.
  ///
  /// [userId] - The ID of the user.
  /// Returns a list of AchievementType values that have been unlocked.
  List<AchievementType> getUnlockedAchievementTypes(String userId) {
    return getUnlockedAchievements(userId)
        .map((a) => a.toEntity().achievementType)
        .whereType<AchievementType>()
        .toList();
  }

  // ============ Unlock Operations ============

  /// Unlocks an achievement for a user.
  ///
  /// [userId] - The ID of the user.
  /// [type] - The achievement type to unlock.
  ///
  /// Creates a new achievement record if it doesn't exist.
  /// Returns the unlocked achievement model.
  /// Returns null if already unlocked (no duplicate unlock).
  Future<AchievementModel?> unlockAchievement(
    String userId,
    AchievementType type,
  ) async {
    final id = _createAchievementId(userId, type);
    var achievement = getAchievementById(id);

    if (achievement != null && achievement.unlockedAt != null) {
      // Already unlocked
      return null;
    }

    final data = type.data;
    achievement = AchievementModel(
      id: id,
      userId: userId,
      type: type.name,
      title: type.name,
      description: type.name,
      unlockedAt: DateTime.now(),
      iconUrl: data.iconAsset,
      progress: 1.0,
      synced: false,
      updatedAt: DateTime.now().toUtc(),
    );

    await saveAchievement(achievement);
    return achievement;
  }

  /// Updates the progress of an achievement.
  ///
  /// [userId] - The ID of the user.
  /// [type] - The achievement type.
  /// [progress] - Progress value between 0.0 and 1.0.
  ///
  /// Returns the updated achievement model.
  Future<AchievementModel> updateProgress(
    String userId,
    AchievementType type,
    double progress,
  ) async {
    final id = _createAchievementId(userId, type);
    var achievement = getAchievementById(id);

    if (achievement == null) {
      achievement = AchievementModel(
        id: id,
        userId: userId,
        type: type.name,
        title: type.name,
        description: type.name,
        progress: progress.clamp(0.0, 1.0),
      );
    } else {
      achievement.progress = progress.clamp(0.0, 1.0);
    }

    await saveAchievement(achievement);
    return achievement;
  }

  // ============ Initialization ============

  /// Initializes all achievements for a user with default (locked) state.
  ///
  /// [userId] - The ID of the user.
  ///
  /// Creates achievement records for all achievement types if they don't exist.
  Future<void> initializeAchievements(String userId) async {
    for (final type in AchievementType.values) {
      final id = _createAchievementId(userId, type);
      if (getAchievementById(id) == null) {
        final achievement = AchievementModel(
          id: id,
          userId: userId,
          type: type.name,
          title: type.name,
          description: type.name,
          progress: 0.0,
        );
        await saveAchievement(achievement);
      }
    }
  }

  /// Gets all achievements for a user, initializing if needed.
  ///
  /// [userId] - The ID of the user.
  ///
  /// Returns all achievements in the order defined by AchievementConstants.
  Future<List<Achievement>> getAllAchievementsOrdered(String userId) async {
    await initializeAchievements(userId);

    final achievements = <Achievement>[];
    for (final type in AchievementConstants.orderedAchievements) {
      final model = getAchievementByType(userId, type);
      if (model != null) {
        achievements.add(model.toEntity());
      }
    }
    return achievements;
  }

  // ============ Watch Operations ============

  /// Watches for changes to achievements.
  ///
  /// [userId] - The ID of the user whose achievements to watch.
  ///
  /// Emits the list of achievements whenever any achievement changes.
  Stream<List<Achievement>> watchAchievements(String userId) {
    return _achievements.watch().map((_) {
      return getAchievements(userId).map((m) => m.toEntity()).toList();
    });
  }

  // ============ Sync Operations ============

  /// Returns achievements that haven't been synced to the server.
  List<AchievementModel> getUnsyncedAchievements() {
    return _achievements.values
        .whereType<AchievementModel>()
        .where((a) => !a.synced && a.unlockedAt != null)
        .toList();
  }

  /// Returns the count of unsynced achievements.
  int getUnsyncedCount() {
    return getUnsyncedAchievements().length;
  }

  /// Whether there are unsynced achievements.
  bool hasUnsyncedAchievements() {
    return _achievements.values.whereType<AchievementModel>().any(
      (a) => !a.synced && a.unlockedAt != null,
    );
  }

  /// Marks an achievement as synced with the server.
  Future<void> markAsSynced(String id, DateTime serverTime) async {
    final achievement = getAchievementById(id);
    if (achievement != null) {
      achievement.synced = true;
      achievement.serverUpdatedAt = serverTime;
      await achievement.save();
    }
  }

  /// Applies a server achievement update to local storage.
  ///
  /// Converts server snake_case type to mobile camelCase enum name.
  /// Compares timestamps: if server is newer, updates local Hive.
  /// If local is newer, skips to preserve client-authoritative data.
  Future<void> applyServerUpdate(Map<String, dynamic> serverData) async {
    final userId = serverData['user_id'] as String?;
    final serverType = serverData['achievement_type'] as String?;
    if (userId == null || serverType == null) return;

    // Convert server key to mobile enum name
    final mobileType = AchievementTypeExtension.fromServerKey(serverType);
    if (mobileType == null) return; // Unknown achievement type, skip

    final mobileTypeName = mobileType.name;
    final id = 'achievement_${userId}_$mobileTypeName';
    final existing = getAchievementById(id);

    final unlockedAtStr = serverData['unlocked_at'] as String?;
    final unlockedAt = unlockedAtStr != null
        ? DateTime.tryParse(unlockedAtStr)
        : null;

    // If local exists and has unsynced changes with a newer timestamp, skip
    if (existing != null && !existing.synced && existing.updatedAt != null) {
      final serverUpdatedAtStr =
          serverData['updated_at'] as String? ??
          serverData['server_updated_at'] as String?;
      final serverUpdatedAt = serverUpdatedAtStr != null
          ? DateTime.tryParse(serverUpdatedAtStr)
          : null;
      if (serverUpdatedAt != null &&
          existing.updatedAt!.isAfter(serverUpdatedAt)) {
        return;
      }
    }

    if (existing != null) {
      // Update existing: only update if server has unlock and local doesn't
      if (unlockedAt != null && existing.unlockedAt == null) {
        existing.unlockedAt = unlockedAt;
        existing.progress = 1.0;
      }
      existing.synced = true;
      existing.serverUpdatedAt = DateTime.now().toUtc();
      await existing.save();
    } else {
      // Create new achievement from server data
      final achievement = AchievementModel(
        id: id,
        userId: userId,
        type: mobileTypeName,
        title: mobileTypeName,
        description: mobileTypeName,
        unlockedAt: unlockedAt,
        progress: unlockedAt != null ? 1.0 : 0.0,
        synced: true,
        serverUpdatedAt: DateTime.now().toUtc(),
      );
      await saveAchievement(achievement);
    }
  }

  /// Reconciles local achievements with server state after a full sync.
  ///
  /// Any locally-unlocked achievement not present in [serverTypes]
  /// is marked as unsynced so it gets re-uploaded on the next sync.
  /// [serverTypes] should contain mobile enum names (not server keys).
  Future<void> reconcileWithServer(
    String userId,
    Set<String> serverTypes,
  ) async {
    final unlocked = getUnlockedAchievements(userId);
    for (final achievement in unlocked) {
      if (achievement.synced && !serverTypes.contains(achievement.type)) {
        achievement.synced = false;
        achievement.updatedAt = DateTime.now().toUtc();
        await achievement.save();
      }
    }
  }

  // ============ Utility Methods ============

  /// Creates a unique achievement ID from user ID and type.
  String _createAchievementId(String userId, AchievementType type) {
    return 'achievement_${userId}_${type.name}';
  }

  /// Deletes an achievement from local storage.
  ///
  /// [id] - The unique identifier of the achievement to delete.
  Future<bool> deleteAchievement(String id) async {
    final existing = getAchievementById(id);
    if (existing == null) {
      return false;
    }
    await _achievements.delete(id);
    return true;
  }

  /// Clears all achievements from local storage.
  ///
  /// Use with caution - this permanently deletes all achievement data.
  Future<void> clearAll() async {
    await _achievements.clear();
  }

  /// Deletes all achievements for a specific user.
  ///
  /// [userId] - The ID of the user whose achievements should be deleted.
  /// Returns the number of achievements deleted.
  Future<int> deleteAchievementsByUser(String userId) async {
    final achievements = getAchievements(userId);
    for (final achievement in achievements) {
      await _achievements.delete(achievement.id);
    }
    return achievements.length;
  }
}
