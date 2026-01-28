import 'package:equatable/equatable.dart';

import 'package:fishfeed/core/constants/levels.dart';

/// Domain entity representing aggregated user statistics for the profile.
///
/// Contains feeding statistics, app usage metrics, and level information.
class UserStatistics extends Equatable {
  const UserStatistics({
    required this.onTimePercentage,
    required this.totalFeedings,
    required this.daysWithApp,
    required this.currentLevel,
    required this.totalXp,
    required this.xpInCurrentLevel,
    required this.xpForCurrentLevel,
    required this.levelProgress,
    required this.isMaxLevel,
  });

  /// Creates an empty/default statistics instance.
  factory UserStatistics.empty() {
    return const UserStatistics(
      onTimePercentage: 0.0,
      totalFeedings: 0,
      daysWithApp: 0,
      currentLevel: UserLevel.beginnerAquarist,
      totalXp: 0,
      xpInCurrentLevel: 0,
      xpForCurrentLevel: 100,
      levelProgress: 0.0,
      isMaxLevel: false,
    );
  }

  /// Percentage of on-time feedings (0-100).
  final double onTimePercentage;

  /// Total number of completed feedings.
  final int totalFeedings;

  /// Number of days since first app usage.
  final int daysWithApp;

  /// Current user level.
  final UserLevel currentLevel;

  /// Total accumulated XP.
  final int totalXp;

  /// XP earned in the current level.
  final int xpInCurrentLevel;

  /// Total XP required to complete the current level.
  final int xpForCurrentLevel;

  /// Progress towards the next level (0.0 to 1.0).
  final double levelProgress;

  /// Whether the user is at the maximum level.
  final bool isMaxLevel;

  /// Formatted on-time percentage string.
  String get onTimePercentageFormatted => '${onTimePercentage.toStringAsFixed(0)}%';

  /// XP display string for progress bar.
  String get xpProgressText {
    if (isMaxLevel) {
      return '$totalXp XP (Max)';
    }
    return '$xpInCurrentLevel / $xpForCurrentLevel XP';
  }

  @override
  List<Object?> get props => [
        onTimePercentage,
        totalFeedings,
        daysWithApp,
        currentLevel,
        totalXp,
        xpInCurrentLevel,
        xpForCurrentLevel,
        levelProgress,
        isMaxLevel,
      ];
}
