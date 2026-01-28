import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/local/achievement_local_ds.dart';
import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/datasources/local/feeding_schedule_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/data/datasources/local/sync_queue_ds.dart';

/// Provider for [AuthLocalDataSource].
///
/// Provides singleton access to authentication local data source
/// for managing tokens and user data in local storage.
///
/// Example:
/// ```dart
/// final authDs = ref.watch(authLocalDataSourceProvider);
/// final user = authDs.getCurrentUser();
/// ```
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource();
});

/// Provider for [FeedingLocalDataSource].
///
/// Provides singleton access to feeding events local data source
/// for managing feeding event CRUD operations and sync status.
///
/// Example:
/// ```dart
/// final feedingDs = ref.watch(feedingLocalDataSourceProvider);
/// final events = feedingDs.getFeedingEvents(aquariumId);
/// ```
final feedingLocalDataSourceProvider = Provider<FeedingLocalDataSource>((ref) {
  return FeedingLocalDataSource();
});

/// Provider for [SyncQueueDataSource].
///
/// Provides singleton access to sync queue data source
/// for managing offline operations pending synchronization.
///
/// Example:
/// ```dart
/// final syncQueueDs = ref.watch(syncQueueDataSourceProvider);
/// final pending = syncQueueDs.getPendingOperations();
/// ```
final syncQueueDataSourceProvider = Provider<SyncQueueDataSource>((ref) {
  return SyncQueueDataSource();
});

/// Provider for [StreakLocalDataSource].
///
/// Provides singleton access to streak local data source
/// for managing user feeding streaks in local storage.
///
/// Example:
/// ```dart
/// final streakDs = ref.watch(streakLocalDataSourceProvider);
/// final streak = streakDs.getStreakByUserId(userId);
/// ```
final streakLocalDataSourceProvider = Provider<StreakLocalDataSource>((ref) {
  return StreakLocalDataSource();
});

/// Provider for [AchievementLocalDataSource].
///
/// Provides singleton access to achievement local data source
/// for managing user achievements in local storage.
///
/// Example:
/// ```dart
/// final achievementDs = ref.watch(achievementLocalDataSourceProvider);
/// final achievements = achievementDs.getAchievements(userId);
/// ```
final achievementLocalDataSourceProvider =
    Provider<AchievementLocalDataSource>((ref) {
  return AchievementLocalDataSource();
});

/// Provider for [FishLocalDataSource].
///
/// Provides singleton access to fish local data source
/// for managing fish records in local storage.
///
/// Example:
/// ```dart
/// final fishDs = ref.watch(fishLocalDataSourceProvider);
/// final fish = fishDs.getFishByAquariumId(aquariumId);
/// ```
final fishLocalDataSourceProvider = Provider<FishLocalDataSource>((ref) {
  return FishLocalDataSource();
});

/// Provider for [AquariumLocalDataSource].
///
/// Provides singleton access to aquarium local data source
/// for managing aquarium records in local storage.
///
/// Example:
/// ```dart
/// final aquariumDs = ref.watch(aquariumLocalDataSourceProvider);
/// final aquariums = aquariumDs.getAllAquariums();
/// ```
final aquariumLocalDataSourceProvider = Provider<AquariumLocalDataSource>((ref) {
  return AquariumLocalDataSource();
});

/// Provider for [FeedingScheduleLocalDataSource].
///
/// Provides singleton access to feeding schedule local data source
/// for managing feeding schedule records in local storage.
///
/// Example:
/// ```dart
/// final scheduleDs = ref.watch(feedingScheduleLocalDataSourceProvider);
/// final schedule = scheduleDs.getScheduleByAquariumId(aquariumId);
/// ```
final feedingScheduleLocalDataSourceProvider =
    Provider<FeedingScheduleLocalDataSource>((ref) {
  return FeedingScheduleLocalDataSource();
});
