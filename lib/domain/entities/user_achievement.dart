/// Statistics used for checking achievement unlock conditions.
class UserStats {
  const UserStats({
    required this.userId,
    this.totalFeedings = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.consecutiveDaysWithoutMiss = 0,
    this.fishCount = 0,
    this.uniqueSpeciesCount = 0,
    this.aquariumCount = 0,
    this.familyMembersCount = 0,
    this.hasEarlyBirdFeeding = false,
    this.hasNightOwlFeeding = false,
    this.hasSharedAchievement = false,
  });

  /// ID of the user.
  final String userId;

  /// Total number of feedings completed.
  final int totalFeedings;

  /// Current consecutive days of feeding.
  final int currentStreak;

  /// Longest streak ever achieved.
  final int longestStreak;

  /// Current consecutive days without any missed feeding.
  final int consecutiveDaysWithoutMiss;

  /// Total number of fish owned.
  final int fishCount;

  /// Number of unique species owned.
  final int uniqueSpeciesCount;

  /// Total number of aquariums owned.
  final int aquariumCount;

  /// Number of family members (excluding the user).
  final int familyMembersCount;

  /// Whether the user has completed a feeding before 7:00 AM.
  final bool hasEarlyBirdFeeding;

  /// Whether the user has completed a feeding after 10:00 PM.
  final bool hasNightOwlFeeding;

  /// Whether the user has shared an achievement.
  final bool hasSharedAchievement;

  UserStats copyWith({
    String? userId,
    int? totalFeedings,
    int? currentStreak,
    int? longestStreak,
    int? consecutiveDaysWithoutMiss,
    int? fishCount,
    int? uniqueSpeciesCount,
    int? aquariumCount,
    int? familyMembersCount,
    bool? hasEarlyBirdFeeding,
    bool? hasNightOwlFeeding,
    bool? hasSharedAchievement,
  }) {
    return UserStats(
      userId: userId ?? this.userId,
      totalFeedings: totalFeedings ?? this.totalFeedings,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      consecutiveDaysWithoutMiss:
          consecutiveDaysWithoutMiss ?? this.consecutiveDaysWithoutMiss,
      fishCount: fishCount ?? this.fishCount,
      uniqueSpeciesCount: uniqueSpeciesCount ?? this.uniqueSpeciesCount,
      aquariumCount: aquariumCount ?? this.aquariumCount,
      familyMembersCount: familyMembersCount ?? this.familyMembersCount,
      hasEarlyBirdFeeding: hasEarlyBirdFeeding ?? this.hasEarlyBirdFeeding,
      hasNightOwlFeeding: hasNightOwlFeeding ?? this.hasNightOwlFeeding,
      hasSharedAchievement: hasSharedAchievement ?? this.hasSharedAchievement,
    );
  }
}
