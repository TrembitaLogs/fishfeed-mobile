/// Statistics used for checking achievement unlock conditions.
class UserStats {
  const UserStats({
    required this.userId,
    this.totalFeedings = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.consecutiveDaysWithoutMiss = 0,
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

  UserStats copyWith({
    String? userId,
    int? totalFeedings,
    int? currentStreak,
    int? longestStreak,
    int? consecutiveDaysWithoutMiss,
  }) {
    return UserStats(
      userId: userId ?? this.userId,
      totalFeedings: totalFeedings ?? this.totalFeedings,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      consecutiveDaysWithoutMiss:
          consecutiveDaysWithoutMiss ?? this.consecutiveDaysWithoutMiss,
    );
  }
}
