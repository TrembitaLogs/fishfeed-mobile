import 'package:equatable/equatable.dart';

import 'package:fishfeed/core/constants/achievements.dart';

/// Domain entity representing a user achievement.
///
/// Used for gamification to reward users for consistent feeding behavior.
class Achievement extends Equatable {
  const Achievement({
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

  /// Creates an Achievement from an AchievementType.
  ///
  /// Automatically populates title, description, and icon from constants.
  factory Achievement.fromType({
    required String id,
    required String userId,
    required AchievementType achievementType,
    DateTime? unlockedAt,
    double progress = 0.0,
  }) {
    final data = achievementType.data;
    return Achievement(
      id: id,
      userId: userId,
      type: achievementType.name,
      title: achievementType.name,
      description: achievementType.name,
      unlockedAt: unlockedAt,
      iconUrl: data.iconAsset,
      progress: progress,
    );
  }

  /// Unique identifier for this achievement.
  final String id;

  /// ID of the user who earned this achievement.
  final String userId;

  /// Type/category of achievement (e.g., 'streak7', 'firstFeeding').
  final String type;

  /// Display title of the achievement.
  final String title;

  /// Description of how to earn this achievement.
  final String? description;

  /// When the achievement was unlocked. Null if not yet unlocked.
  final DateTime? unlockedAt;

  /// URL/path to the achievement icon.
  final String? iconUrl;

  /// Progress towards unlocking (0.0 to 1.0). 1.0 means unlocked.
  final double progress;

  /// Whether this achievement has been synced to the server.
  final bool synced;

  /// When this record was last updated locally.
  final DateTime? updatedAt;

  /// Timestamp from server indicating when it was last updated there.
  final DateTime? serverUpdatedAt;

  /// Whether this achievement has been unlocked.
  bool get isUnlocked => unlockedAt != null || progress >= 1.0;

  /// Gets the AchievementType enum for this achievement.
  ///
  /// Returns null if the type string doesn't match any known achievement.
  AchievementType? get achievementType {
    try {
      return AchievementType.values.firstWhere((t) => t.name == type);
    } catch (e) {
      // Unknown achievement type — may be from a newer server version
      return null;
    }
  }

  /// Gets the XP reward for this achievement type.
  int get xpReward => achievementType?.xpReward ?? 0;

  /// Creates a copy with updated fields.
  Achievement copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? description,
    DateTime? unlockedAt,
    String? iconUrl,
    double? progress,
    bool? synced,
    DateTime? updatedAt,
    DateTime? serverUpdatedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      iconUrl: iconUrl ?? this.iconUrl,
      progress: progress ?? this.progress,
      synced: synced ?? this.synced,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    title,
    description,
    unlockedAt,
    iconUrl,
    progress,
    synced,
    updatedAt,
    serverUpdatedAt,
  ];
}
