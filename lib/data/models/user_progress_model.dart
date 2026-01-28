import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/domain/entities/user_progress.dart';

part 'user_progress_model.g.dart';

/// Hive model for [UserProgress] entity.
///
/// Stores user's XP and level progress data locally.
/// Use [toEntity] and [fromEntity] for domain layer conversion.
@HiveType(typeId: 10)
class UserProgressModel extends HiveObject {
  UserProgressModel({
    required this.id,
    required this.userId,
    this.totalXp = 0,
    this.streakBonusesEarned = const [],
    this.lastXpAwardedAt,
    this.lastLevelUpAt,
    this.synced = false,
    this.updatedAt,
    this.serverUpdatedAt,
  });

  /// Creates a model from a domain entity.
  factory UserProgressModel.fromEntity(UserProgress entity) {
    return UserProgressModel(
      id: entity.id,
      userId: entity.userId,
      totalXp: entity.totalXp,
      streakBonusesEarned: entity.streakBonusesEarned,
      lastXpAwardedAt: entity.lastXpAwardedAt,
      lastLevelUpAt: entity.lastLevelUpAt,
      synced: entity.synced,
      updatedAt: entity.updatedAt,
      serverUpdatedAt: entity.serverUpdatedAt,
    );
  }

  /// Unique identifier for this progress record.
  @HiveField(0)
  String id;

  /// ID of the user this progress belongs to.
  @HiveField(1)
  String userId;

  /// Total accumulated experience points.
  @HiveField(2)
  int totalXp;

  /// List of streak milestones that have already awarded bonus XP.
  @HiveField(3)
  List<int> streakBonusesEarned;

  /// Timestamp of the last XP award.
  @HiveField(4)
  DateTime? lastXpAwardedAt;

  /// Timestamp of the last level up.
  @HiveField(5)
  DateTime? lastLevelUpAt;

  /// Whether this progress has been synced to the server.
  @HiveField(6, defaultValue: false)
  bool synced;

  /// When this record was last updated locally.
  @HiveField(7)
  DateTime? updatedAt;

  /// Timestamp from server indicating when it was last updated there.
  @HiveField(8)
  DateTime? serverUpdatedAt;

  /// Whether this progress needs to be synced.
  bool get needsSync =>
      !synced ||
      (updatedAt != null &&
          serverUpdatedAt != null &&
          updatedAt!.isAfter(serverUpdatedAt!));

  /// Converts this model to a domain entity.
  UserProgress toEntity() {
    return UserProgress(
      id: id,
      userId: userId,
      totalXp: totalXp,
      streakBonusesEarned: streakBonusesEarned,
      lastXpAwardedAt: lastXpAwardedAt,
      lastLevelUpAt: lastLevelUpAt,
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
      'total_xp': totalXp,
      'level': UserProgress.calculateLevel(totalXp),
    };
  }
}
