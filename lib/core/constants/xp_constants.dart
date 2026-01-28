/// XP (Experience Points) constants for the gamification system.
///
/// Defines XP values awarded for various feeding actions and streak milestones.
abstract final class XpConstants {
  /// XP awarded for completing a feeding on time (within scheduled window).
  static const int xpOnTimeFeeding = 10;

  /// XP awarded for completing a feeding late (after scheduled time).
  static const int xpLateFeeding = 5;

  /// Bonus XP awarded for reaching a 7-day streak.
  static const int streakBonus7Days = 50;

  /// Bonus XP awarded for reaching a 30-day streak.
  static const int streakBonus30Days = 200;

  /// Bonus XP awarded for reaching a 100-day streak.
  static const int streakBonus100Days = 1000;

  /// All streak milestones that award bonus XP.
  ///
  /// Maps streak day count to bonus XP amount.
  static const Map<int, int> streakBonuses = {
    7: streakBonus7Days,
    30: streakBonus30Days,
    100: streakBonus100Days,
  };

  /// Ordered list of streak milestones for iteration.
  static const List<int> streakMilestones = [7, 30, 100];
}
