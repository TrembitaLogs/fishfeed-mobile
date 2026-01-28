import 'package:flutter/material.dart';

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
    required this.titleUk,
    required this.titleEn,
    required this.descriptionUk,
    required this.descriptionEn,
    required this.iconAsset,
    required this.xpReward,
    this.targetValue,
  });

  /// The achievement type.
  final AchievementType type;

  /// Ukrainian title.
  final String titleUk;

  /// English title.
  final String titleEn;

  /// Ukrainian description.
  final String descriptionUk;

  /// English description.
  final String descriptionEn;

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
      titleUk: 'Перше годування',
      titleEn: 'First Feeding',
      descriptionUk: 'Виконайте своє перше годування',
      descriptionEn: 'Complete your first feeding',
      iconAsset: 'assets/achievements/first_feeding.png',
      xpReward: 10,
      targetValue: 1,
    ),
    AchievementType.streak7: AchievementData(
      type: AchievementType.streak7,
      titleUk: 'Тижневий страйк',
      titleEn: 'Weekly Streak',
      descriptionUk: '7 днів годувань поспіль',
      descriptionEn: '7 consecutive days of feeding',
      iconAsset: 'assets/achievements/streak_7.png',
      xpReward: 25,
      targetValue: 7,
    ),
    AchievementType.streak30: AchievementData(
      type: AchievementType.streak30,
      titleUk: 'Місячний страйк',
      titleEn: 'Monthly Streak',
      descriptionUk: '30 днів годувань поспіль',
      descriptionEn: '30 consecutive days of feeding',
      iconAsset: 'assets/achievements/streak_30.png',
      xpReward: 100,
      targetValue: 30,
    ),
    AchievementType.streak100: AchievementData(
      type: AchievementType.streak100,
      titleUk: 'Легендарний страйк',
      titleEn: 'Legendary Streak',
      descriptionUk: '100 днів годувань поспіль',
      descriptionEn: '100 consecutive days of feeding',
      iconAsset: 'assets/achievements/streak_100.png',
      xpReward: 500,
      targetValue: 100,
    ),
    AchievementType.weekWithoutMiss: AchievementData(
      type: AchievementType.weekWithoutMiss,
      titleUk: 'Тиждень без пропусків',
      titleEn: 'Perfect Week',
      descriptionUk: 'Жодного пропущеного годування за тиждень',
      descriptionEn: 'No missed feedings for a whole week',
      iconAsset: 'assets/achievements/perfect_week.png',
      xpReward: 50,
      targetValue: 7,
    ),
    AchievementType.feedings100: AchievementData(
      type: AchievementType.feedings100,
      titleUk: 'Сотня годувань',
      titleEn: 'Century Feeder',
      descriptionUk: 'Виконайте 100 годувань загалом',
      descriptionEn: 'Complete 100 total feedings',
      iconAsset: 'assets/achievements/feedings_100.png',
      xpReward: 75,
      targetValue: 100,
    ),
    AchievementType.feedings500: AchievementData(
      type: AchievementType.feedings500,
      titleUk: 'Майстер годування',
      titleEn: 'Feeding Master',
      descriptionUk: 'Виконайте 500 годувань загалом',
      descriptionEn: 'Complete 500 total feedings',
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

  /// Gets the Ukrainian title.
  String get titleUk => data.titleUk;

  /// Gets the English title.
  String get titleEn => data.titleEn;

  /// Gets the Ukrainian description.
  String get descriptionUk => data.descriptionUk;

  /// Gets the English description.
  String get descriptionEn => data.descriptionEn;

  /// Gets the XP reward.
  int get xpReward => data.xpReward;

  /// Gets the placeholder icon.
  IconData get icon => AchievementConstants.getPlaceholderIcon(this);

  /// Gets the achievement color.
  Color get color => AchievementConstants.getAchievementColor(this);

  /// Gets the target value for progress tracking.
  int? get targetValue => data.targetValue;
}
