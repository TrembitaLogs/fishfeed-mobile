import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/domain/entities/achievement.dart';

part 'achievement_model.g.dart';

/// Hive model for [Achievement] entity.
///
/// Stores user achievement data locally with progress tracking.
/// Use [toEntity] and [fromEntity] for domain layer conversion.
@HiveType(typeId: 6)
class AchievementModel extends HiveObject {
  AchievementModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.description,
    this.unlockedAt,
    this.iconUrl,
    this.progress = 0.0,
    this.synced = false,
    this.updatedAt,
    this.serverUpdatedAt,
  });

  /// Creates a model from a domain entity.
  factory AchievementModel.fromEntity(Achievement entity) {
    return AchievementModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type,
      title: entity.title,
      description: entity.description,
      unlockedAt: entity.unlockedAt,
      iconUrl: entity.iconUrl,
      progress: entity.progress,
      synced: entity.synced,
      updatedAt: entity.updatedAt,
      serverUpdatedAt: entity.serverUpdatedAt,
    );
  }

  /// Unique identifier for this achievement.
  @HiveField(0)
  String id;

  /// ID of the user who earned this achievement.
  @HiveField(1)
  String userId;

  /// Type/category of achievement (e.g., 'streak', 'first_feed', 'species_master').
  @HiveField(2)
  String type;

  /// Display title of the achievement.
  @HiveField(3)
  String title;

  /// Description of how to earn this achievement.
  @HiveField(4)
  String? description;

  /// When the achievement was unlocked. Null if not yet unlocked.
  @HiveField(5)
  DateTime? unlockedAt;

  /// URL to the achievement icon.
  @HiveField(6)
  String? iconUrl;

  /// Progress towards unlocking (0.0 to 1.0). 1.0 means unlocked.
  @HiveField(7)
  double progress;

  /// Whether this achievement has been synced to the server.
  @HiveField(8, defaultValue: false)
  bool synced;

  /// When this record was last updated locally.
  @HiveField(9)
  DateTime? updatedAt;

  /// Timestamp from server indicating when it was last updated there.
  @HiveField(10)
  DateTime? serverUpdatedAt;

  /// Whether this achievement needs to be synced.
  bool get needsSync => !synced || (updatedAt != null && serverUpdatedAt != null && updatedAt!.isAfter(serverUpdatedAt!));

  /// Whether this achievement is unlocked.
  bool get isUnlocked => unlockedAt != null;

  /// Converts this model to a domain entity.
  Achievement toEntity() {
    return Achievement(
      id: id,
      userId: userId,
      type: type,
      title: title,
      description: description,
      unlockedAt: unlockedAt,
      iconUrl: iconUrl,
      progress: progress,
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
      'achievement_type': type,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }
}
