import 'package:flutter/material.dart';

import 'package:fishfeed/l10n/app_localizations.dart';

/// Types of achievements available in the gamification system.
///
/// Each achievement has specific unlock criteria and rewards.
enum AchievementType {
  /// First feeding ever completed.
  firstFeeding,

  /// 7-day feeding streak milestone.
  streak7,

  /// 30-day feeding streak milestone.
  streak30,

  /// 100-day feeding streak milestone.
  streak100,

  /// Complete a full week without any missed feedings.
  weekWithoutMiss,

  /// Complete 100 total feedings.
  feedings100,

  /// Complete 500 total feedings.
  feedings500,
}

/// Data class representing achievement metadata.
class AchievementData {
  const AchievementData({
    required this.type,
    required this.iconAsset,
    required this.xpReward,
    this.targetValue,
  });

  /// The achievement type.
  final AchievementType type;

  /// Path to the icon asset for this achievement.
  final String iconAsset;

  /// XP reward for unlocking this achievement.
  final int xpReward;

  /// Target value for progress tracking (e.g., 7 for streak7).
  final int? targetValue;
}

/// Constants and helper functions for the achievements system.
abstract final class AchievementConstants {
  /// Map of achievement types to their metadata.
  static const Map<AchievementType, AchievementData> achievements = {
    AchievementType.firstFeeding: AchievementData(
      type: AchievementType.firstFeeding,
      iconAsset: 'assets/achievements/first_feeding.png',
      xpReward: 10,
      targetValue: 1,
    ),
    AchievementType.streak7: AchievementData(
      type: AchievementType.streak7,
      iconAsset: 'assets/achievements/streak_7.png',
      xpReward: 25,
      targetValue: 7,
    ),
    AchievementType.streak30: AchievementData(
      type: AchievementType.streak30,
      iconAsset: 'assets/achievements/streak_30.png',
      xpReward: 100,
      targetValue: 30,
    ),
    AchievementType.streak100: AchievementData(
      type: AchievementType.streak100,
      iconAsset: 'assets/achievements/streak_100.png',
      xpReward: 500,
      targetValue: 100,
    ),
    AchievementType.weekWithoutMiss: AchievementData(
      type: AchievementType.weekWithoutMiss,
      iconAsset: 'assets/achievements/perfect_week.png',
      xpReward: 50,
      targetValue: 7,
    ),
    AchievementType.feedings100: AchievementData(
      type: AchievementType.feedings100,
      iconAsset: 'assets/achievements/feedings_100.png',
      xpReward: 75,
      targetValue: 100,
    ),
    AchievementType.feedings500: AchievementData(
      type: AchievementType.feedings500,
      iconAsset: 'assets/achievements/feedings_500.png',
      xpReward: 250,
      targetValue: 500,
    ),
  };

  /// Ordered list of achievements for display.
  static const List<AchievementType> orderedAchievements = [
    AchievementType.firstFeeding,
    AchievementType.streak7,
    AchievementType.weekWithoutMiss,
    AchievementType.streak30,
    AchievementType.feedings100,
    AchievementType.streak100,
    AchievementType.feedings500,
  ];

  /// Gets achievement data by type.
  static AchievementData getAchievement(AchievementType type) {
    return achievements[type]!;
  }

  /// Gets the icon for an achievement.
  ///
  /// Returns a placeholder icon if asset is not available.
  static IconData getPlaceholderIcon(AchievementType type) {
    switch (type) {
      case AchievementType.firstFeeding:
        return Icons.celebration;
      case AchievementType.streak7:
        return Icons.local_fire_department;
      case AchievementType.streak30:
        return Icons.whatshot;
      case AchievementType.streak100:
        return Icons.emoji_events;
      case AchievementType.weekWithoutMiss:
        return Icons.verified;
      case AchievementType.feedings100:
        return Icons.star;
      case AchievementType.feedings500:
        return Icons.stars;
    }
  }

  /// Gets the color associated with an achievement.
  static Color getAchievementColor(AchievementType type) {
    switch (type) {
      case AchievementType.firstFeeding:
        return const Color(0xFF4CAF50); // Green
      case AchievementType.streak7:
        return const Color(0xFFFF9800); // Orange
      case AchievementType.streak30:
        return const Color(0xFFE91E63); // Pink
      case AchievementType.streak100:
        return const Color(0xFF9C27B0); // Purple
      case AchievementType.weekWithoutMiss:
        return const Color(0xFF2196F3); // Blue
      case AchievementType.feedings100:
        return const Color(0xFFFFEB3B); // Yellow
      case AchievementType.feedings500:
        return const Color(0xFFFFD700); // Gold
    }
  }
}

/// Extension methods for [AchievementType].
extension AchievementTypeExtension on AchievementType {
  /// Gets the metadata for this achievement type.
  AchievementData get data => AchievementConstants.getAchievement(this);

  /// Gets the localized title for this achievement.
  String localizedTitle(AppLocalizations l10n) {
    switch (this) {
      case AchievementType.firstFeeding:
        return l10n.achievementFirstFeeding;
      case AchievementType.streak7:
        return l10n.achievementStreak7;
      case AchievementType.streak30:
        return l10n.achievementStreak30;
      case AchievementType.streak100:
        return l10n.achievementStreak100;
      case AchievementType.weekWithoutMiss:
        return l10n.achievementPerfectWeek;
      case AchievementType.feedings100:
        return l10n.achievementFeedings100;
      case AchievementType.feedings500:
        return l10n.achievementFeedings500;
    }
  }

  /// Gets the localized description for this achievement.
  String localizedDescription(AppLocalizations l10n) {
    switch (this) {
      case AchievementType.firstFeeding:
        return l10n.achievementFirstFeedingDesc;
      case AchievementType.streak7:
        return l10n.achievementStreak7Desc;
      case AchievementType.streak30:
        return l10n.achievementStreak30Desc;
      case AchievementType.streak100:
        return l10n.achievementStreak100Desc;
      case AchievementType.weekWithoutMiss:
        return l10n.achievementPerfectWeekDesc;
      case AchievementType.feedings100:
        return l10n.achievementFeedings100Desc;
      case AchievementType.feedings500:
        return l10n.achievementFeedings500Desc;
    }
  }

  /// Gets the XP reward.
  int get xpReward => data.xpReward;

  /// Gets the placeholder icon.
  IconData get icon => AchievementConstants.getPlaceholderIcon(this);

  /// Gets the achievement color.
  Color get color => AchievementConstants.getAchievementColor(this);

  /// Gets the target value for progress tracking.
  int? get targetValue => data.targetValue;
}
