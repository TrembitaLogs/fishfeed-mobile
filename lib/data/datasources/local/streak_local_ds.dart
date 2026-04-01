import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/streak_model.dart';
import 'package:fishfeed/domain/entities/streak.dart';

/// Data source for managing streak data in local Hive storage.
///
/// Provides CRUD operations for user feeding streaks with offline-first support.
/// Includes freeze day mechanics to prevent streak loss.
///
/// Example:
/// ```dart
/// final streakDs = StreakLocalDataSource();
/// final streak = streakDs.getStreakByUserId('user_123');
/// await streakDs.updateStreak(updatedStreak);
/// ```
class StreakLocalDataSource {
  StreakLocalDataSource({Box<dynamic>? streaksBox}) : _streaksBox = streaksBox;

  final Box<dynamic>? _streaksBox;

  /// Gets the streaks box, using the injected box or the default HiveBoxes.
  Box<dynamic> get _streaks => _streaksBox ?? HiveBoxes.streaks;

  // ============ CRUD Operations ============

  /// Creates or updates a streak record in local storage.
  ///
  /// [streak] - The streak model to store.
  /// The streak is stored with its [id] as the key.
  Future<void> saveStreak(StreakModel streak) async {
    await _streaks.put(streak.id, streak);
  }

  /// Retrieves a streak by its ID.
  ///
  /// [id] - The unique identifier of the streak.
  /// Returns `null` if no streak with the given ID exists.
  StreakModel? getStreakById(String id) {
    final streak = _streaks.get(id);
    if (streak is StreakModel) {
      return streak;
    }
    return null;
  }

  /// Retrieves a streak by user ID.
  ///
  /// [userId] - The ID of the user whose streak to retrieve.
  /// Returns `null` if no streak exists for the given user.
  StreakModel? getStreakByUserId(String userId) {
    return _streaks.values
        .whereType<StreakModel>()
        .cast<StreakModel?>()
        .firstWhere((streak) => streak?.userId == userId, orElse: () => null);
  }

  /// Deletes a streak from local storage.
  ///
  /// [id] - The unique identifier of the streak to delete.
  /// Returns `true` if the streak was deleted, `false` if it didn't exist.
  Future<bool> deleteStreak(String id) async {
    final existing = getStreakById(id);
    if (existing == null) {
      return false;
    }
    await _streaks.delete(id);
    return true;
  }

  /// Retrieves all streaks in local storage.
  ///
  /// Returns all stored streaks sorted by current streak (highest first).
  List<StreakModel> getAllStreaks() {
    final streaks = _streaks.values.whereType<StreakModel>().toList();
    streaks.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    return streaks;
  }

  // ============ Sync Operations ============

  /// Returns streaks that haven't been synced to the server.
  List<StreakModel> getUnsyncedStreaks() {
    return _streaks.values
        .whereType<StreakModel>()
        .where((s) => !s.synced && s.userId != 'default_user')
        .toList();
  }

  /// Returns the count of unsynced streaks.
  int getUnsyncedCount() {
    return getUnsyncedStreaks().length;
  }

  /// Whether there are unsynced streaks.
  bool hasUnsyncedStreaks() {
    return _streaks.values.whereType<StreakModel>().any((s) => !s.synced);
  }

  /// Marks a streak as synced with the server.
  Future<void> markAsSynced(String id, DateTime serverTime) async {
    final streak = getStreakById(id);
    if (streak != null) {
      streak.synced = true;
      streak.serverUpdatedAt = serverTime;
      await streak.save();
    }
  }

  /// Applies a server streak update to local storage.
  ///
  /// Compares timestamps: if server is newer, updates local Hive.
  /// If local is newer, skips to preserve client-authoritative data.
  Future<void> applyServerUpdate(Map<String, dynamic> serverData) async {
    final userId = serverData['user_id'] as String?;
    if (userId == null) return;

    final id = 'streak_$userId';
    final existing = getStreakById(id);

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

    final currentStreak = serverData['current_streak'] as int? ?? 0;
    final bestStreak = serverData['best_streak'] as int? ?? 0;
    final freezeAvailable =
        serverData['freeze_available'] as int? ?? kDefaultFreezePerMonth;
    final lastFeedDateStr = serverData['last_feed_date'] as String?;
    final lastFeedDate = lastFeedDateStr != null
        ? DateTime.tryParse(lastFeedDateStr)
        : null;

    if (existing != null) {
      existing.currentStreak = currentStreak;
      existing.longestStreak = bestStreak;
      existing.freezeAvailable = freezeAvailable;
      existing.lastFeedingDate = lastFeedDate;
      existing.synced = true;
      existing.serverUpdatedAt = serverUpdatedAt;
      await existing.save();
    } else {
      final streak = StreakModel(
        id: id,
        userId: userId,
        currentStreak: currentStreak,
        longestStreak: bestStreak,
        freezeAvailable: freezeAvailable,
        lastFeedingDate: lastFeedDate,
        synced: true,
        serverUpdatedAt: serverUpdatedAt,
      );
      await saveStreak(streak);
    }
  }

  // ============ Streak Update Operations ============

  /// Increments the current streak for a user.
  ///
  /// [userId] - The ID of the user whose streak to increment.
  /// [feedingDate] - The date of the feeding that triggered the increment.
  /// Creates a new streak if one doesn't exist.
  /// Returns the updated streak.
  Future<StreakModel> incrementStreak(
    String userId,
    DateTime feedingDate,
  ) async {
    var streak = getStreakByUserId(userId);
    final today = DateTime(
      feedingDate.year,
      feedingDate.month,
      feedingDate.day,
    );

    if (streak == null) {
      // Create new streak
      streak = StreakModel(
        id: 'streak_$userId',
        userId: userId,
        currentStreak: 1,
        longestStreak: 1,
        lastFeedingDate: today,
        streakStartDate: today,
        synced: false,
        updatedAt: DateTime.now().toUtc(),
      );
    } else {
      final lastDate = streak.lastFeedingDate;

      if (lastDate != null) {
        final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
        final difference = today.difference(lastDay).inDays;

        if (difference == 0) {
          // Already fed today, no change
          return streak;
        } else if (difference == 1) {
          // Consecutive day - increment streak
          streak.currentStreak++;
          if (streak.currentStreak > streak.longestStreak) {
            streak.longestStreak = streak.currentStreak;
          }
        } else {
          // Gap in feeding - reset streak to 1
          streak.currentStreak = 1;
          streak.streakStartDate = today;
        }
      } else {
        // First feeding ever
        streak.currentStreak = 1;
        streak.streakStartDate = today;
      }

      streak.lastFeedingDate = today;
      streak.synced = false;
      streak.updatedAt = DateTime.now().toUtc();
    }

    await saveStreak(streak);
    return streak;
  }

  /// Resets the current streak for a user to zero.
  ///
  /// [userId] - The ID of the user whose streak to reset.
  /// Sets synced to false so the reset is uploaded during next sync.
  /// Returns the updated streak or `null` if no streak exists.
  Future<StreakModel?> resetStreak(String userId) async {
    final streak = getStreakByUserId(userId);
    if (streak == null) {
      return null;
    }

    streak.currentStreak = 0;
    streak.streakStartDate = null;
    streak.synced = false;
    streak.updatedAt = DateTime.now().toUtc();
    await saveStreak(streak);
    return streak;
  }

  /// Checks if a user has fed all scheduled feedings for a given date.
  ///
  /// This is a helper method that should be called with feeding event data
  /// to determine if streak should be incremented.
  /// Returns `true` if all feedings for the date are completed.
  bool shouldIncrementStreak(
    String userId,
    DateTime date,
    int totalScheduledFeedings,
    int completedFeedings,
  ) {
    if (totalScheduledFeedings == 0) {
      return false;
    }
    return completedFeedings >= totalScheduledFeedings;
  }

  // ============ Query Operations ============

  /// Gets the current streak count for a user.
  ///
  /// [userId] - The ID of the user.
  /// Returns 0 if no streak exists.
  int getCurrentStreakCount(String userId) {
    final streak = getStreakByUserId(userId);
    return streak?.currentStreak ?? 0;
  }

  /// Gets the longest streak count for a user.
  ///
  /// [userId] - The ID of the user.
  /// Returns 0 if no streak exists.
  int getLongestStreakCount(String userId) {
    final streak = getStreakByUserId(userId);
    return streak?.longestStreak ?? 0;
  }

  /// Checks if the user's streak is still active (fed yesterday or today).
  ///
  /// [userId] - The ID of the user to check.
  /// Returns `true` if the streak is active, `false` otherwise.
  bool isStreakActive(String userId) {
    final streak = getStreakByUserId(userId);
    if (streak == null || streak.lastFeedingDate == null) {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = streak.lastFeedingDate!;
    final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final difference = today.difference(lastDay).inDays;

    return difference <= 1;
  }

  // ============ Utility Operations ============

  /// Clears all streaks from local storage.
  ///
  /// Use with caution - this permanently deletes all streak data.
  Future<void> clearAll() async {
    await _streaks.clear();
  }

  // ============ Freeze Day Operations ============

  /// Uses a freeze day to prevent streak loss.
  ///
  /// [userId] - The ID of the user.
  /// [freezeDate] - The date to apply the freeze.
  ///
  /// Returns the updated streak if freeze was successfully applied.
  /// Returns `null` if no freeze days are available.
  Future<StreakModel?> useFreeze(String userId, DateTime freezeDate) async {
    final streak = getStreakByUserId(userId);
    if (streak == null || streak.freezeAvailable <= 0) {
      return null;
    }

    final normalizedDate = DateTime(
      freezeDate.year,
      freezeDate.month,
      freezeDate.day,
    );

    // Check if freeze was already used for this date
    final alreadyFrozen = streak.frozenDays.any(
      (d) =>
          d.year == normalizedDate.year &&
          d.month == normalizedDate.month &&
          d.day == normalizedDate.day,
    );

    if (alreadyFrozen) {
      return streak;
    }

    // Apply freeze
    streak.freezeAvailable--;
    streak.frozenDays = [...streak.frozenDays, normalizedDate];
    streak.lastFeedingDate = normalizedDate;
    streak.synced = false;
    streak.updatedAt = DateTime.now().toUtc();

    await saveStreak(streak);
    return streak;
  }

  /// Uses multiple freeze days to cover consecutive missed days.
  ///
  /// [userId] - The ID of the user.
  /// [count] - The number of freeze days to use.
  ///
  /// Returns the updated streak. If not enough freezes are available,
  /// uses as many as possible and then resets the streak.
  Future<StreakModel> useFreezeMultiple(String userId, int count) async {
    final streak = getStreakByUserId(userId);
    if (streak == null) {
      return StreakModel(
        id: 'streak_$userId',
        userId: userId,
        currentStreak: 0,
        longestStreak: 0,
        synced: false,
        updatedAt: DateTime.now().toUtc(),
      );
    }

    final today = DateTime.now();
    for (int i = 0; i < count; i++) {
      if (streak.freezeAvailable <= 0) break;
      // Each missed day is one day before today going backwards
      final missedDate = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: count - i));
      streak.freezeAvailable--;
      streak.frozenDays = [...streak.frozenDays, missedDate];
    }

    // Update lastFeedingDate to yesterday so streak remains valid
    streak.lastFeedingDate = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 1));
    streak.synced = false;
    streak.updatedAt = DateTime.now().toUtc();

    await saveStreak(streak);
    return streak;
  }

  /// Handles a missed feeding day with freeze logic.
  ///
  /// [userId] - The ID of the user.
  /// [missedDate] - The date that was missed.
  ///
  /// If freeze is available and streak is active, uses freeze to preserve streak.
  /// Otherwise, resets the current streak to 0.
  ///
  /// Returns the updated streak.
  Future<StreakModel> handleMissedDay(
    String userId,
    DateTime missedDate,
  ) async {
    var streak = getStreakByUserId(userId);

    if (streak == null) {
      // Create new streak with default freeze
      streak = StreakModel(
        id: 'streak_$userId',
        userId: userId,
        currentStreak: 0,
        longestStreak: 0,
        freezeAvailable: kDefaultFreezePerMonth,
        frozenDays: [],
      );
      await saveStreak(streak);
      return streak;
    }

    // If streak is not active (0), nothing to freeze
    if (streak.currentStreak == 0) {
      return streak;
    }

    // Check if we can use a freeze
    if (streak.freezeAvailable > 0) {
      final frozenStreak = await useFreeze(userId, missedDate);
      if (frozenStreak != null) {
        return frozenStreak;
      }
    }

    // No freeze available - reset streak
    streak.currentStreak = 0;
    streak.streakStartDate = null;
    streak.synced = false;
    streak.updatedAt = DateTime.now().toUtc();
    await saveStreak(streak);
    return streak;
  }

  /// Adds one bonus freeze day earned from a rewarded ad.
  ///
  /// [userId] - The ID of the user.
  ///
  /// Returns the updated streak, or `null` if no streak exists.
  Future<StreakModel?> addFreezeDay(String userId) async {
    final streak = getStreakByUserId(userId);
    if (streak == null) {
      return null;
    }

    streak.freezeAvailable++;
    streak.synced = false;
    streak.updatedAt = DateTime.now().toUtc();

    await saveStreak(streak);
    return streak;
  }

  /// Resets the monthly freeze availability.
  ///
  /// [userId] - The ID of the user.
  ///
  /// Restores freeze days to the default amount and clears frozen days history.
  ///
  /// Returns the updated streak or `null` if no streak exists.
  Future<StreakModel?> resetMonthlyFreeze(String userId) async {
    final streak = getStreakByUserId(userId);
    if (streak == null) {
      return null;
    }

    final now = DateTime.now();
    streak.freezeAvailable = kDefaultFreezePerMonth;
    streak.frozenDays = [];
    streak.lastFreezeResetDate = DateTime(now.year, now.month, 1);

    await saveStreak(streak);
    return streak;
  }

  /// Checks if the monthly freeze reset is needed.
  ///
  /// [userId] - The ID of the user.
  ///
  /// Returns `true` if the last reset was in a previous month.
  bool needsMonthlyFreezeReset(String userId) {
    final streak = getStreakByUserId(userId);
    if (streak == null) {
      return false;
    }

    final lastReset = streak.lastFreezeResetDate;
    if (lastReset == null) {
      return true;
    }

    final now = DateTime.now();
    return lastReset.year < now.year ||
        (lastReset.year == now.year && lastReset.month < now.month);
  }

  /// Checks and applies monthly freeze reset if needed.
  ///
  /// [userId] - The ID of the user.
  ///
  /// Automatically resets freeze days at the start of a new month.
  ///
  /// Returns the updated streak or `null` if no streak exists.
  Future<StreakModel?> checkAndResetMonthlyFreeze(String userId) async {
    if (needsMonthlyFreezeReset(userId)) {
      return resetMonthlyFreeze(userId);
    }
    return getStreakByUserId(userId);
  }

  /// Watches the streak box for changes to a specific user's streak.
  ///
  /// [userId] - The ID of the user whose streak to watch.
  ///
  /// Emits the current streak on subscription and whenever it changes.
  Stream<StreakModel?> watchStreak(String userId) {
    // First emit current value, then watch for changes
    return _streaks.watch().map((_) => getStreakByUserId(userId));
  }
}
