import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/domain/entities/streak.dart';

part 'streak_model.g.dart';

/// Hive model for [Streak] entity.
///
/// Stores user's feeding streak data locally with freeze day mechanics.
/// Use [toEntity] and [fromEntity] for domain layer conversion.
@HiveType(typeId: 5)
class StreakModel extends HiveObject {
  StreakModel({
    required this.id,
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastFeedingDate,
    this.streakStartDate,
    this.freezeAvailable = kDefaultFreezePerMonth,
    this.frozenDays = const [],
    this.lastFreezeResetDate,
    this.synced = false,
    this.updatedAt,
    this.serverUpdatedAt,
  });

  /// Creates a model from a domain entity.
  factory StreakModel.fromEntity(Streak entity) {
    return StreakModel(
      id: entity.id,
      userId: entity.userId,
      currentStreak: entity.currentStreak,
      longestStreak: entity.longestStreak,
      lastFeedingDate: entity.lastFeedingDate,
      streakStartDate: entity.streakStartDate,
      freezeAvailable: entity.freezeAvailable,
      frozenDays: entity.frozenDays,
      lastFreezeResetDate: entity.lastFreezeResetDate,
      synced: entity.synced,
      updatedAt: entity.updatedAt,
      serverUpdatedAt: entity.serverUpdatedAt,
    );
  }

  /// Unique identifier for this streak record.
  @HiveField(0)
  String id;

  /// ID of the user this streak belongs to.
  @HiveField(1)
  String userId;

  /// Current consecutive days of feeding.
  @HiveField(2)
  int currentStreak;

  /// Longest streak ever achieved.
  @HiveField(3)
  int longestStreak;

  /// Date of the last feeding event.
  @HiveField(4)
  DateTime? lastFeedingDate;

  /// When the current streak started.
  @HiveField(5)
  DateTime? streakStartDate;

  /// Number of freeze days available this month.
  @HiveField(6)
  int freezeAvailable;

  /// History of dates when freeze was used.
  @HiveField(7)
  List<DateTime> frozenDays;

  /// Date when freeze availability was last reset.
  @HiveField(8)
  DateTime? lastFreezeResetDate;

  /// Whether this streak has been synced to the server.
  @HiveField(9, defaultValue: false)
  bool synced;

  /// When this record was last updated locally.
  @HiveField(10)
  DateTime? updatedAt;

  /// Timestamp from server indicating when it was last updated there.
  @HiveField(11)
  DateTime? serverUpdatedAt;

  /// Whether this streak needs to be synced.
  bool get needsSync =>
      !synced ||
      (updatedAt != null &&
          serverUpdatedAt != null &&
          updatedAt!.isAfter(serverUpdatedAt!));

  /// Converts this model to a domain entity.
  Streak toEntity() {
    return Streak(
      id: id,
      userId: userId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastFeedingDate: lastFeedingDate,
      streakStartDate: streakStartDate,
      freezeAvailable: freezeAvailable,
      frozenDays: frozenDays,
      lastFreezeResetDate: lastFreezeResetDate,
      synced: synced,
      updatedAt: updatedAt,
      serverUpdatedAt: serverUpdatedAt,
    );
  }

  /// Converts this model to JSON for sync.
  Map<String, dynamic> toSyncJson() {
    return {
      'id': id,
      'user_id': userId,
      'current_streak': currentStreak,
      'best_streak': longestStreak,
      'freeze_available': freezeAvailable,
      'last_feed_date': lastFeedingDate?.toIso8601String(),
      'streak_start_date': streakStartDate?.toIso8601String(),
      'frozen_days': frozenDays.map((d) => d.toIso8601String()).toList(),
      'last_freeze_reset_date': lastFreezeResetDate?.toIso8601String(),
    };
  }
}
