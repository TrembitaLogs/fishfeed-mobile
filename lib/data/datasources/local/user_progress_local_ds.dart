import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/user_progress_model.dart';

/// Data source for managing user progress (XP/levels) in local Hive storage.
///
/// Provides CRUD operations for user XP and level progression.
///
/// Example:
/// ```dart
/// final progressDs = UserProgressLocalDataSource();
/// final progress = progressDs.getProgressByUserId('user_123');
/// await progressDs.addXp('user_123', 10);
/// ```
class UserProgressLocalDataSource {
  UserProgressLocalDataSource({Box<dynamic>? progressBox})
    : _progressBox = progressBox;

  final Box<dynamic>? _progressBox;

  /// Gets the progress box, using the injected box or the default HiveBoxes.
  Box<dynamic> get _progress => _progressBox ?? HiveBoxes.userProgress;

  // ============ CRUD Operations ============

  /// Creates or updates a user progress record in local storage.
  ///
  /// [progress] - The progress model to store.
  Future<void> saveProgress(UserProgressModel progress) async {
    await _progress.put(progress.id, progress);
  }

  /// Retrieves user progress by its ID.
  ///
  /// [id] - The unique identifier of the progress record.
  /// Returns `null` if no progress with the given ID exists.
  UserProgressModel? getProgressById(String id) {
    final progress = _progress.get(id);
    if (progress is UserProgressModel) {
      return progress;
    }
    return null;
  }

  /// Retrieves user progress by user ID.
  ///
  /// [userId] - The ID of the user whose progress to retrieve.
  /// Returns `null` if no progress exists for the given user.
  UserProgressModel? getProgressByUserId(String userId) {
    return _progress.values
        .whereType<UserProgressModel>()
        .cast<UserProgressModel?>()
        .firstWhere(
          (progress) => progress?.userId == userId,
          orElse: () => null,
        );
  }

  /// Gets or creates user progress for a user.
  ///
  /// [userId] - The ID of the user.
  ///
  /// Returns existing progress or creates a new one with default values.
  Future<UserProgressModel> getOrCreateProgress(String userId) async {
    var progress = getProgressByUserId(userId);

    if (progress == null) {
      progress = UserProgressModel(
        id: 'progress_$userId',
        userId: userId,
        totalXp: 0,
        streakBonusesEarned: [],
      );
      await saveProgress(progress);
    }

    return progress;
  }

  /// Deletes user progress from local storage.
  ///
  /// [id] - The unique identifier of the progress to delete.
  /// Returns `true` if the progress was deleted, `false` if it didn't exist.
  Future<bool> deleteProgress(String id) async {
    final existing = getProgressById(id);
    if (existing == null) {
      return false;
    }
    await _progress.delete(id);
    return true;
  }

  // ============ XP Operations ============

  /// Adds XP to a user's total.
  ///
  /// [userId] - The ID of the user.
  /// [amount] - The amount of XP to add.
  ///
  /// Creates a new progress record if one doesn't exist.
  /// Returns the updated progress model.
  Future<UserProgressModel> addXp(String userId, int amount) async {
    final progress = await getOrCreateProgress(userId);

    progress.totalXp += amount;
    progress.lastXpAwardedAt = DateTime.now();
    progress.synced = false;
    progress.updatedAt = DateTime.now().toUtc();

    await saveProgress(progress);
    return progress;
  }

  /// Gets the current XP for a user.
  ///
  /// [userId] - The ID of the user.
  /// Returns 0 if no progress exists.
  int getCurrentXp(String userId) {
    final progress = getProgressByUserId(userId);
    return progress?.totalXp ?? 0;
  }

  // ============ Streak Bonus Operations ============

  /// Records that a streak bonus has been earned.
  ///
  /// [userId] - The ID of the user.
  /// [milestone] - The streak milestone (e.g., 7, 30, 100).
  ///
  /// Prevents the same bonus from being awarded twice.
  /// Returns `true` if the bonus was newly recorded, `false` if already earned.
  Future<bool> recordStreakBonusEarned(String userId, int milestone) async {
    final progress = await getOrCreateProgress(userId);

    if (progress.streakBonusesEarned.contains(milestone)) {
      return false;
    }

    progress.streakBonusesEarned = [...progress.streakBonusesEarned, milestone];
    progress.synced = false;
    progress.updatedAt = DateTime.now().toUtc();
    await saveProgress(progress);
    return true;
  }

  /// Checks if a streak bonus has already been earned.
  ///
  /// [userId] - The ID of the user.
  /// [milestone] - The streak milestone to check.
  ///
  /// Returns `true` if the bonus has been earned, `false` otherwise.
  bool hasEarnedStreakBonus(String userId, int milestone) {
    final progress = getProgressByUserId(userId);
    return progress?.streakBonusesEarned.contains(milestone) ?? false;
  }

  /// Gets all earned streak bonuses for a user.
  ///
  /// [userId] - The ID of the user.
  /// Returns an empty list if no progress exists.
  List<int> getEarnedStreakBonuses(String userId) {
    final progress = getProgressByUserId(userId);
    return progress?.streakBonusesEarned ?? [];
  }

  // ============ Level Up Tracking ============

  /// Records a level up event.
  ///
  /// [userId] - The ID of the user.
  ///
  /// Updates the lastLevelUpAt timestamp.
  Future<void> recordLevelUp(String userId) async {
    final progress = await getOrCreateProgress(userId);
    progress.lastLevelUpAt = DateTime.now();
    progress.synced = false;
    progress.updatedAt = DateTime.now().toUtc();
    await saveProgress(progress);
  }

  // ============ Watch Operations ============

  /// Watches the progress box for changes to a specific user's progress.
  ///
  /// [userId] - The ID of the user whose progress to watch.
  ///
  /// Emits the current progress whenever it changes.
  Stream<UserProgressModel?> watchProgress(String userId) {
    return _progress.watch().map((_) => getProgressByUserId(userId));
  }

  // ============ Sync Operations ============

  /// Returns all unsynced progress records.
  List<UserProgressModel> getUnsyncedProgress() {
    return _progress.values
        .whereType<UserProgressModel>()
        .where((p) => !p.synced && p.userId != 'default_user')
        .toList();
  }

  /// Returns the count of unsynced progress records.
  int getUnsyncedCount() {
    return getUnsyncedProgress().length;
  }

  /// Whether there are unsynced progress records.
  bool hasUnsyncedProgress() {
    return _progress.values.whereType<UserProgressModel>().any(
      (p) => !p.synced,
    );
  }

  /// Marks a progress record as synced with the server.
  Future<void> markAsSynced(String id, DateTime serverTime) async {
    final progress = getProgressById(id) ?? getProgressByUserId(id);
    if (progress != null) {
      progress.synced = true;
      progress.serverUpdatedAt = serverTime;
      await progress.save();
    }
  }

  /// Applies a server progress update to local storage.
  ///
  /// Compares timestamps: if server is newer, updates local Hive.
  /// If local is newer, skips to preserve client-authoritative data.
  Future<void> applyServerUpdate(Map<String, dynamic> serverData) async {
    final userId = serverData['user_id'] as String?;
    if (userId == null) return;

    final id = 'progress_$userId';
    final existing = getProgressById(id);

    final serverUpdatedAtStr =
        serverData['updated_at'] as String? ??
        serverData['server_updated_at'] as String?;
    final serverUpdatedAt = serverUpdatedAtStr != null
        ? DateTime.tryParse(serverUpdatedAtStr)
        : null;

    // If local exists and has unsynced changes with a newer timestamp, skip
    if (existing != null && !existing.synced && existing.updatedAt != null) {
      if (serverUpdatedAt != null &&
          existing.updatedAt!.isAfter(serverUpdatedAt)) {
        return;
      }
    }

    final totalXp = serverData['total_xp'] as int? ?? 0;
    final lastXpAwardedAtStr = serverData['last_xp_awarded_at'] as String?;
    final lastXpAwardedAt = lastXpAwardedAtStr != null
        ? DateTime.tryParse(lastXpAwardedAtStr)
        : null;
    final lastLevelUpAtStr = serverData['last_level_up_at'] as String?;
    final lastLevelUpAt = lastLevelUpAtStr != null
        ? DateTime.tryParse(lastLevelUpAtStr)
        : null;

    if (existing != null) {
      // XP can only go up (same rule as backend)
      if (totalXp > existing.totalXp) {
        existing.totalXp = totalXp;
      }
      // Recalculate level from XP
      existing.lastXpAwardedAt = lastXpAwardedAt ?? existing.lastXpAwardedAt;
      existing.lastLevelUpAt = lastLevelUpAt ?? existing.lastLevelUpAt;
      existing.synced = true;
      existing.serverUpdatedAt = serverUpdatedAt;
      await existing.save();
    } else {
      final progress = UserProgressModel(
        id: id,
        userId: userId,
        totalXp: totalXp,
        streakBonusesEarned: [],
        lastXpAwardedAt: lastXpAwardedAt,
        lastLevelUpAt: lastLevelUpAt,
        synced: true,
        serverUpdatedAt: serverUpdatedAt,
      );
      await saveProgress(progress);
    }
  }

  // ============ Utility Operations ============

  /// Clears all user progress from local storage.
  ///
  /// Use with caution - this permanently deletes all progress data.
  Future<void> clearAll() async {
    await _progress.clear();
  }
}
