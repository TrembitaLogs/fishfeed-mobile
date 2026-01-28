/// User level in the gamification system.
///
/// Levels are earned by accumulating XP through feeding activities.
enum UserLevel {
  /// Starting level (0-99 XP).
  beginnerAquarist,

  /// Second level (100-499 XP).
  caretaker,

  /// Third level (500-1999 XP).
  fishMaster,

  /// Highest level (2000+ XP).
  aquariumPro,
}

/// Extension methods for [UserLevel].
extension UserLevelExtension on UserLevel {
  /// Returns the display name (English by default).
  String get displayName {
    switch (this) {
      case UserLevel.beginnerAquarist:
        return 'Beginner';
      case UserLevel.caretaker:
        return 'Caretaker';
      case UserLevel.fishMaster:
        return 'Master';
      case UserLevel.aquariumPro:
        return 'Pro';
    }
  }

  /// Returns the English display name.
  String get displayNameEn {
    switch (this) {
      case UserLevel.beginnerAquarist:
        return 'Beginner Aquarist';
      case UserLevel.caretaker:
        return 'Caretaker';
      case UserLevel.fishMaster:
        return 'Fish Master';
      case UserLevel.aquariumPro:
        return 'Aquarium Pro';
    }
  }

  /// Returns the minimum XP required for this level.
  int get minXp => LevelConstants.levelThresholds[this]!;

  /// Returns the maximum XP for this level (exclusive).
  ///
  /// Returns `null` for the highest level (no upper limit).
  int? get maxXp {
    switch (this) {
      case UserLevel.beginnerAquarist:
        return LevelConstants.levelThresholds[UserLevel.caretaker];
      case UserLevel.caretaker:
        return LevelConstants.levelThresholds[UserLevel.fishMaster];
      case UserLevel.fishMaster:
        return LevelConstants.levelThresholds[UserLevel.aquariumPro];
      case UserLevel.aquariumPro:
        return null;
    }
  }

  /// Returns the next level after this one.
  ///
  /// Returns `null` if already at the highest level.
  UserLevel? get nextLevel {
    switch (this) {
      case UserLevel.beginnerAquarist:
        return UserLevel.caretaker;
      case UserLevel.caretaker:
        return UserLevel.fishMaster;
      case UserLevel.fishMaster:
        return UserLevel.aquariumPro;
      case UserLevel.aquariumPro:
        return null;
    }
  }
}

/// Constants and helper functions for the level system.
abstract final class LevelConstants {
  /// XP thresholds for each level.
  ///
  /// The value represents the minimum XP required to reach that level.
  static const Map<UserLevel, int> levelThresholds = {
    UserLevel.beginnerAquarist: 0,
    UserLevel.caretaker: 100,
    UserLevel.fishMaster: 500,
    UserLevel.aquariumPro: 2000,
  };

  /// Ordered list of levels from lowest to highest.
  static const List<UserLevel> orderedLevels = [
    UserLevel.beginnerAquarist,
    UserLevel.caretaker,
    UserLevel.fishMaster,
    UserLevel.aquariumPro,
  ];

  /// Returns the level for a given XP amount.
  ///
  /// [xp] - Total XP accumulated by the user.
  ///
  /// Returns the highest level where the user meets the XP threshold.
  static UserLevel getLevelForXp(int xp) {
    if (xp >= levelThresholds[UserLevel.aquariumPro]!) {
      return UserLevel.aquariumPro;
    }
    if (xp >= levelThresholds[UserLevel.fishMaster]!) {
      return UserLevel.fishMaster;
    }
    if (xp >= levelThresholds[UserLevel.caretaker]!) {
      return UserLevel.caretaker;
    }
    return UserLevel.beginnerAquarist;
  }

  /// Returns the progress towards the next level as a value between 0.0 and 1.0.
  ///
  /// [xp] - Total XP accumulated by the user.
  ///
  /// Returns 1.0 if the user is at the maximum level.
  static double getXpProgress(int xp) {
    final currentLevel = getLevelForXp(xp);
    final currentThreshold = levelThresholds[currentLevel]!;
    final nextLevel = currentLevel.nextLevel;

    if (nextLevel == null) {
      // Already at max level
      return 1.0;
    }

    final nextThreshold = levelThresholds[nextLevel]!;
    final xpInLevel = xp - currentThreshold;
    final xpNeededForLevel = nextThreshold - currentThreshold;

    return xpInLevel / xpNeededForLevel;
  }

  /// Returns the XP needed to reach the next level.
  ///
  /// [xp] - Total XP accumulated by the user.
  ///
  /// Returns 0 if the user is at the maximum level.
  static int getXpToNextLevel(int xp) {
    final currentLevel = getLevelForXp(xp);
    final nextLevel = currentLevel.nextLevel;

    if (nextLevel == null) {
      return 0;
    }

    return levelThresholds[nextLevel]! - xp;
  }
}
