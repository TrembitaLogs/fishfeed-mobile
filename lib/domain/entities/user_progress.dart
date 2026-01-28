import 'package:equatable/equatable.dart';

import 'package:fishfeed/core/constants/levels.dart';

/// Domain entity representing a user's gamification progress.
///
/// Tracks XP, level, and earned streak bonuses for the gamification system.
class UserProgress extends Equatable {
  const UserProgress({
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

  /// Unique identifier for this progress record.
  final String id;

  /// ID of the user this progress belongs to.
  final String userId;

  /// Total accumulated experience points.
  final int totalXp;

  /// List of streak milestones that have already awarded bonus XP.
  ///
  /// Each entry is a streak day count (e.g., 7, 30, 100) that has been
  /// achieved and awarded. Prevents duplicate bonus awards.
  final List<int> streakBonusesEarned;

  /// Timestamp of the last XP award.
  final DateTime? lastXpAwardedAt;

  /// Timestamp of the last level up.
  final DateTime? lastLevelUpAt;

  /// Whether this progress has been synced to the server.
  final bool synced;

  /// When this record was last updated locally.
  final DateTime? updatedAt;

  /// Timestamp from server indicating when it was last updated there.
  final DateTime? serverUpdatedAt;

  /// Calculates the user level based on total XP.
  static int calculateLevel(int xp) {
    // Simple level calculation: level up every 100 XP
    return (xp ~/ 100) + 1;
  }

  /// Current user level based on total XP.
  UserLevel get currentLevel => LevelConstants.getLevelForXp(totalXp);

  /// XP remaining until the next level.
  ///
  /// Returns 0 if already at max level.
  int get xpToNextLevel => LevelConstants.getXpToNextLevel(totalXp);

  /// Progress towards the next level (0.0 to 1.0).
  ///
  /// Returns 1.0 if already at max level.
  double get levelProgress => LevelConstants.getXpProgress(totalXp);

  /// Whether the user is at the maximum level.
  bool get isMaxLevel => currentLevel == UserLevel.aquariumPro;

  /// XP earned in the current level.
  int get xpInCurrentLevel => totalXp - currentLevel.minXp;

  /// Total XP required to complete the current level.
  ///
  /// Returns 0 if at max level.
  int get xpForCurrentLevel {
    final nextLevel = currentLevel.nextLevel;
    if (nextLevel == null) return 0;
    return nextLevel.minXp - currentLevel.minXp;
  }

  /// Creates a copy with updated fields.
  UserProgress copyWith({
    String? id,
    String? userId,
    int? totalXp,
    List<int>? streakBonusesEarned,
    DateTime? lastXpAwardedAt,
    DateTime? lastLevelUpAt,
    bool? synced,
    DateTime? updatedAt,
    DateTime? serverUpdatedAt,
  }) {
    return UserProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      totalXp: totalXp ?? this.totalXp,
      streakBonusesEarned: streakBonusesEarned ?? this.streakBonusesEarned,
      lastXpAwardedAt: lastXpAwardedAt ?? this.lastXpAwardedAt,
      lastLevelUpAt: lastLevelUpAt ?? this.lastLevelUpAt,
      synced: synced ?? this.synced,
      updatedAt: updatedAt ?? this.updatedAt,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        totalXp,
        streakBonusesEarned,
        lastXpAwardedAt,
        lastLevelUpAt,
        synced,
        updatedAt,
        serverUpdatedAt,
      ];
}
