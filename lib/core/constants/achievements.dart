import 'package:flutter/material.dart';

import 'package:fishfeed/l10n/app_localizations.dart';

/// Types of achievements available in the gamification system.
///
/// Each achievement has specific unlock criteria and rewards.
enum AchievementType {
  // === Feeding ===

  /// First feeding ever completed.
  firstFeeding,

  /// 7-day feeding streak milestone.
  streak7,

  /// 30-day feeding streak milestone.
  streak30,

  /// 100-day feeding streak milestone.
  streak100,

  /// 365-day feeding streak milestone.
  streak365,

  /// Complete a full week without any missed feedings.
  weekWithoutMiss,

  /// Complete a feeding before 7:00 AM.
  earlyBird,

  /// Complete a feeding after 10:00 PM.
  nightOwl,

  /// Complete 50 total feedings.
  feedings50,

  /// Complete 100 total feedings.
  feedings100,

  /// Complete 500 total feedings.
  feedings500,

  /// Complete 1000 total feedings.
  feedings1000,

  // === Fish ===

  /// Add your first fish.
  firstFish,

  /// Collect 10 fish.
  fishCollector10,

  /// Collect 50 fish.
  fishCollector50,

  /// Explore 5 different species.
  speciesExplorer5,

  /// Explore 10 different species.
  speciesExplorer10,

  /// Explore 20 different species.
  speciesExplorer20,

  // === Aquarium ===

  /// Create your first aquarium.
  firstAquarium,

  /// Own 3 aquariums.
  aquariumCollector3,

  /// Own 10 aquariums.
  aquariumCollector10,

  // === Family ===

  /// Invite your first family member.
  familyFirst,

  /// Have 3 family members.
  familyTeam3,

  // === Social ===

  /// Share an achievement for the first time.
  firstShare,
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
    // === Feeding ===
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
    AchievementType.streak365: AchievementData(
      type: AchievementType.streak365,
      iconAsset: 'assets/achievements/streak_365.png',
      xpReward: 2000,
      targetValue: 365,
    ),
    AchievementType.weekWithoutMiss: AchievementData(
      type: AchievementType.weekWithoutMiss,
      iconAsset: 'assets/achievements/perfect_week.png',
      xpReward: 50,
      targetValue: 7,
    ),
    AchievementType.earlyBird: AchievementData(
      type: AchievementType.earlyBird,
      iconAsset: 'assets/achievements/early_bird.png',
      xpReward: 15,
      targetValue: 1,
    ),
    AchievementType.nightOwl: AchievementData(
      type: AchievementType.nightOwl,
      iconAsset: 'assets/achievements/night_owl.png',
      xpReward: 15,
      targetValue: 1,
    ),
    AchievementType.feedings50: AchievementData(
      type: AchievementType.feedings50,
      iconAsset: 'assets/achievements/feedings_50.png',
      xpReward: 40,
      targetValue: 50,
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
    AchievementType.feedings1000: AchievementData(
      type: AchievementType.feedings1000,
      iconAsset: 'assets/achievements/feedings_1000.png',
      xpReward: 750,
      targetValue: 1000,
    ),
    // === Fish ===
    AchievementType.firstFish: AchievementData(
      type: AchievementType.firstFish,
      iconAsset: 'assets/achievements/first_fish.png',
      xpReward: 10,
      targetValue: 1,
    ),
    AchievementType.fishCollector10: AchievementData(
      type: AchievementType.fishCollector10,
      iconAsset: 'assets/achievements/fish_collector_10.png',
      xpReward: 50,
      targetValue: 10,
    ),
    AchievementType.fishCollector50: AchievementData(
      type: AchievementType.fishCollector50,
      iconAsset: 'assets/achievements/fish_collector_50.png',
      xpReward: 200,
      targetValue: 50,
    ),
    AchievementType.speciesExplorer5: AchievementData(
      type: AchievementType.speciesExplorer5,
      iconAsset: 'assets/achievements/species_explorer_5.png',
      xpReward: 30,
      targetValue: 5,
    ),
    AchievementType.speciesExplorer10: AchievementData(
      type: AchievementType.speciesExplorer10,
      iconAsset: 'assets/achievements/species_explorer_10.png',
      xpReward: 75,
      targetValue: 10,
    ),
    AchievementType.speciesExplorer20: AchievementData(
      type: AchievementType.speciesExplorer20,
      iconAsset: 'assets/achievements/species_explorer_20.png',
      xpReward: 200,
      targetValue: 20,
    ),
    // === Aquarium ===
    AchievementType.firstAquarium: AchievementData(
      type: AchievementType.firstAquarium,
      iconAsset: 'assets/achievements/first_aquarium.png',
      xpReward: 10,
      targetValue: 1,
    ),
    AchievementType.aquariumCollector3: AchievementData(
      type: AchievementType.aquariumCollector3,
      iconAsset: 'assets/achievements/aquarium_collector_3.png',
      xpReward: 50,
      targetValue: 3,
    ),
    AchievementType.aquariumCollector10: AchievementData(
      type: AchievementType.aquariumCollector10,
      iconAsset: 'assets/achievements/aquarium_collector_10.png',
      xpReward: 200,
      targetValue: 10,
    ),
    // === Family ===
    AchievementType.familyFirst: AchievementData(
      type: AchievementType.familyFirst,
      iconAsset: 'assets/achievements/family_first.png',
      xpReward: 20,
      targetValue: 1,
    ),
    AchievementType.familyTeam3: AchievementData(
      type: AchievementType.familyTeam3,
      iconAsset: 'assets/achievements/family_team_3.png',
      xpReward: 75,
      targetValue: 3,
    ),
    // === Social ===
    AchievementType.firstShare: AchievementData(
      type: AchievementType.firstShare,
      iconAsset: 'assets/achievements/first_share.png',
      xpReward: 10,
      targetValue: 1,
    ),
  };

  /// Ordered list of achievements for display.
  static const List<AchievementType> orderedAchievements = [
    // Feeding
    AchievementType.firstFeeding,
    AchievementType.earlyBird,
    AchievementType.nightOwl,
    AchievementType.streak7,
    AchievementType.weekWithoutMiss,
    AchievementType.streak30,
    AchievementType.feedings50,
    AchievementType.feedings100,
    AchievementType.streak100,
    AchievementType.feedings500,
    AchievementType.streak365,
    AchievementType.feedings1000,
    // Fish
    AchievementType.firstFish,
    AchievementType.fishCollector10,
    AchievementType.speciesExplorer5,
    AchievementType.fishCollector50,
    AchievementType.speciesExplorer10,
    AchievementType.speciesExplorer20,
    // Aquarium
    AchievementType.firstAquarium,
    AchievementType.aquariumCollector3,
    AchievementType.aquariumCollector10,
    // Family
    AchievementType.familyFirst,
    AchievementType.familyTeam3,
    // Social
    AchievementType.firstShare,
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
      // Feeding
      case AchievementType.firstFeeding:
        return Icons.celebration;
      case AchievementType.streak7:
        return Icons.local_fire_department;
      case AchievementType.streak30:
        return Icons.whatshot;
      case AchievementType.streak100:
        return Icons.emoji_events;
      case AchievementType.streak365:
        return Icons.diamond;
      case AchievementType.weekWithoutMiss:
        return Icons.verified;
      case AchievementType.earlyBird:
        return Icons.wb_sunny;
      case AchievementType.nightOwl:
        return Icons.nightlight_round;
      case AchievementType.feedings50:
        return Icons.pets;
      case AchievementType.feedings100:
        return Icons.star;
      case AchievementType.feedings500:
        return Icons.stars;
      case AchievementType.feedings1000:
        return Icons.water_drop;
      // Fish
      case AchievementType.firstFish:
        return Icons.set_meal;
      case AchievementType.fishCollector10:
        return Icons.catching_pokemon;
      case AchievementType.fishCollector50:
        return Icons.inventory_2;
      case AchievementType.speciesExplorer5:
        return Icons.explore;
      case AchievementType.speciesExplorer10:
        return Icons.travel_explore;
      case AchievementType.speciesExplorer20:
        return Icons.public;
      // Aquarium
      case AchievementType.firstAquarium:
        return Icons.water;
      case AchievementType.aquariumCollector3:
        return Icons.dashboard;
      case AchievementType.aquariumCollector10:
        return Icons.grid_view;
      // Family
      case AchievementType.familyFirst:
        return Icons.person_add;
      case AchievementType.familyTeam3:
        return Icons.groups;
      // Social
      case AchievementType.firstShare:
        return Icons.share;
    }
  }

  /// Gets the color associated with an achievement.
  static Color getAchievementColor(AchievementType type) {
    switch (type) {
      // Feeding
      case AchievementType.firstFeeding:
        return const Color(0xFF4CAF50); // Green
      case AchievementType.streak7:
        return const Color(0xFFFF9800); // Orange
      case AchievementType.streak30:
        return const Color(0xFFE91E63); // Pink
      case AchievementType.streak100:
        return const Color(0xFF9C27B0); // Purple
      case AchievementType.streak365:
        return const Color(0xFFB71C1C); // Deep Red
      case AchievementType.weekWithoutMiss:
        return const Color(0xFF2196F3); // Blue
      case AchievementType.earlyBird:
        return const Color(0xFFFFA726); // Light Orange
      case AchievementType.nightOwl:
        return const Color(0xFF5C6BC0); // Indigo Light
      case AchievementType.feedings50:
        return const Color(0xFF009688); // Teal
      case AchievementType.feedings100:
        return const Color(0xFFFFEB3B); // Yellow
      case AchievementType.feedings500:
        return const Color(0xFFFFD700); // Gold
      case AchievementType.feedings1000:
        return const Color(0xFF3F51B5); // Indigo
      // Fish
      case AchievementType.firstFish:
        return const Color(0xFF26A69A); // Teal Light
      case AchievementType.fishCollector10:
        return const Color(0xFF00897B); // Teal Dark
      case AchievementType.fishCollector50:
        return const Color(0xFF00695C); // Teal Deeper
      case AchievementType.speciesExplorer5:
        return const Color(0xFF42A5F5); // Blue Light
      case AchievementType.speciesExplorer10:
        return const Color(0xFF1E88E5); // Blue Medium
      case AchievementType.speciesExplorer20:
        return const Color(0xFF1565C0); // Blue Dark
      // Aquarium
      case AchievementType.firstAquarium:
        return const Color(0xFF29B6F6); // Light Blue
      case AchievementType.aquariumCollector3:
        return const Color(0xFF0288D1); // Light Blue Dark
      case AchievementType.aquariumCollector10:
        return const Color(0xFF01579B); // Light Blue Deeper
      // Family
      case AchievementType.familyFirst:
        return const Color(0xFFAB47BC); // Purple Light
      case AchievementType.familyTeam3:
        return const Color(0xFF7B1FA2); // Purple Dark
      // Social
      case AchievementType.firstShare:
        return const Color(0xFFEF5350); // Red Light
    }
  }
}

/// Extension methods for [AchievementType].
extension AchievementTypeExtension on AchievementType {
  /// Gets the metadata for this achievement type.
  AchievementData get data => AchievementConstants.getAchievement(this);

  /// Returns the server-expected snake_case achievement type string.
  String get serverKey {
    return switch (this) {
      AchievementType.firstFeeding => 'first_feed',
      AchievementType.earlyBird => 'early_bird',
      AchievementType.nightOwl => 'night_owl',
      AchievementType.streak7 => 'streak_7',
      AchievementType.weekWithoutMiss => 'perfect_week',
      AchievementType.streak30 => 'streak_30',
      AchievementType.streak100 => 'streak_100',
      AchievementType.streak365 => 'streak_365',
      AchievementType.feedings50 => 'feeding_50',
      AchievementType.feedings100 => 'feeding_100',
      AchievementType.feedings500 => 'feeding_500',
      AchievementType.feedings1000 => 'feeding_1000',
      AchievementType.firstFish => 'first_fish',
      AchievementType.fishCollector10 => 'fish_collector_10',
      AchievementType.fishCollector50 => 'fish_collector_50',
      AchievementType.speciesExplorer5 => 'species_explorer_5',
      AchievementType.speciesExplorer10 => 'species_explorer_10',
      AchievementType.speciesExplorer20 => 'species_explorer_20',
      AchievementType.firstAquarium => 'first_aquarium',
      AchievementType.aquariumCollector3 => 'aquarium_collector_3',
      AchievementType.aquariumCollector10 => 'aquarium_collector_10',
      AchievementType.familyFirst => 'family_first',
      AchievementType.familyTeam3 => 'family_team_3',
      AchievementType.firstShare => 'first_share',
    };
  }

  /// Looks up an [AchievementType] from its server key string.
  ///
  /// Returns `null` if the key is not recognized.
  static AchievementType? fromServerKey(String key) {
    return _serverKeyMap[key];
  }

  static final Map<String, AchievementType> _serverKeyMap = {
    for (final type in AchievementType.values) type.serverKey: type,
  };

  /// Gets the localized title for this achievement.
  String localizedTitle(AppLocalizations l10n) {
    switch (this) {
      // Feeding
      case AchievementType.firstFeeding:
        return l10n.achievementFirstFeeding;
      case AchievementType.streak7:
        return l10n.achievementStreak7;
      case AchievementType.streak30:
        return l10n.achievementStreak30;
      case AchievementType.streak100:
        return l10n.achievementStreak100;
      case AchievementType.streak365:
        return l10n.achievementStreak365;
      case AchievementType.weekWithoutMiss:
        return l10n.achievementPerfectWeek;
      case AchievementType.earlyBird:
        return l10n.achievementEarlyBird;
      case AchievementType.nightOwl:
        return l10n.achievementNightOwl;
      case AchievementType.feedings50:
        return l10n.achievementFeedings50;
      case AchievementType.feedings100:
        return l10n.achievementFeedings100;
      case AchievementType.feedings500:
        return l10n.achievementFeedings500;
      case AchievementType.feedings1000:
        return l10n.achievementFeedings1000;
      // Fish
      case AchievementType.firstFish:
        return l10n.achievementFirstFish;
      case AchievementType.fishCollector10:
        return l10n.achievementFishCollector10;
      case AchievementType.fishCollector50:
        return l10n.achievementFishCollector50;
      case AchievementType.speciesExplorer5:
        return l10n.achievementSpeciesExplorer5;
      case AchievementType.speciesExplorer10:
        return l10n.achievementSpeciesExplorer10;
      case AchievementType.speciesExplorer20:
        return l10n.achievementSpeciesExplorer20;
      // Aquarium
      case AchievementType.firstAquarium:
        return l10n.achievementFirstAquarium;
      case AchievementType.aquariumCollector3:
        return l10n.achievementAquariumCollector3;
      case AchievementType.aquariumCollector10:
        return l10n.achievementAquariumCollector10;
      // Family
      case AchievementType.familyFirst:
        return l10n.achievementFamilyFirst;
      case AchievementType.familyTeam3:
        return l10n.achievementFamilyTeam3;
      // Social
      case AchievementType.firstShare:
        return l10n.achievementFirstShare;
    }
  }

  /// Gets the localized description for this achievement.
  String localizedDescription(AppLocalizations l10n) {
    switch (this) {
      // Feeding
      case AchievementType.firstFeeding:
        return l10n.achievementFirstFeedingDesc;
      case AchievementType.streak7:
        return l10n.achievementStreak7Desc;
      case AchievementType.streak30:
        return l10n.achievementStreak30Desc;
      case AchievementType.streak100:
        return l10n.achievementStreak100Desc;
      case AchievementType.streak365:
        return l10n.achievementStreak365Desc;
      case AchievementType.weekWithoutMiss:
        return l10n.achievementPerfectWeekDesc;
      case AchievementType.earlyBird:
        return l10n.achievementEarlyBirdDesc;
      case AchievementType.nightOwl:
        return l10n.achievementNightOwlDesc;
      case AchievementType.feedings50:
        return l10n.achievementFeedings50Desc;
      case AchievementType.feedings100:
        return l10n.achievementFeedings100Desc;
      case AchievementType.feedings500:
        return l10n.achievementFeedings500Desc;
      case AchievementType.feedings1000:
        return l10n.achievementFeedings1000Desc;
      // Fish
      case AchievementType.firstFish:
        return l10n.achievementFirstFishDesc;
      case AchievementType.fishCollector10:
        return l10n.achievementFishCollector10Desc;
      case AchievementType.fishCollector50:
        return l10n.achievementFishCollector50Desc;
      case AchievementType.speciesExplorer5:
        return l10n.achievementSpeciesExplorer5Desc;
      case AchievementType.speciesExplorer10:
        return l10n.achievementSpeciesExplorer10Desc;
      case AchievementType.speciesExplorer20:
        return l10n.achievementSpeciesExplorer20Desc;
      // Aquarium
      case AchievementType.firstAquarium:
        return l10n.achievementFirstAquariumDesc;
      case AchievementType.aquariumCollector3:
        return l10n.achievementAquariumCollector3Desc;
      case AchievementType.aquariumCollector10:
        return l10n.achievementAquariumCollector10Desc;
      // Family
      case AchievementType.familyFirst:
        return l10n.achievementFamilyFirstDesc;
      case AchievementType.familyTeam3:
        return l10n.achievementFamilyTeam3Desc;
      // Social
      case AchievementType.firstShare:
        return l10n.achievementFirstShareDesc;
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
