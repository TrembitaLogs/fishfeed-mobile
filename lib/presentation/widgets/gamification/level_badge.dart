import 'package:flutter/material.dart';

import 'package:fishfeed/core/constants/levels.dart';
import 'package:fishfeed/l10n/app_localizations.dart';

/// A badge widget displaying the user's current level.
///
/// Features:
/// - Level icon (fish-themed for each level)
/// - Level name in Ukrainian
/// - Color scheme matching the level
/// - Optional compact mode
class LevelBadge extends StatelessWidget {
  const LevelBadge({
    super.key,
    required this.level,
    this.size = LevelBadgeSize.medium,
    this.showName = true,
  });

  /// The user's current level.
  final UserLevel level;

  /// Size variant of the badge.
  final LevelBadgeSize size;

  /// Whether to show the level name.
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dimensions = _getDimensions(size);
    final color = _getLevelColor(level);
    final backgroundColor = _getLevelBackgroundColor(level);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimensions.horizontalPadding,
        vertical: dimensions.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(dimensions.borderRadius),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLevelIcon(level, dimensions.iconSize, color),
          if (showName) ...[
            SizedBox(width: dimensions.spacing),
            Text(
              _getLocalizedLevelName(level, l10n),
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: dimensions.fontSize,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getLocalizedLevelName(UserLevel level, AppLocalizations l10n) {
    return switch (level) {
      UserLevel.beginnerAquarist => l10n.levelBeginner,
      UserLevel.caretaker => l10n.levelCaretaker,
      UserLevel.fishMaster => l10n.levelMaster,
      UserLevel.aquariumPro => l10n.levelPro,
    };
  }

  Widget _buildLevelIcon(UserLevel level, double size, Color color) {
    final icon = _getLevelIcon(level);

    return Icon(
      icon,
      size: size,
      color: color,
    );
  }

  IconData _getLevelIcon(UserLevel level) {
    return switch (level) {
      UserLevel.beginnerAquarist => Icons.set_meal_outlined,
      UserLevel.caretaker => Icons.water_drop_outlined,
      UserLevel.fishMaster => Icons.waves_outlined,
      UserLevel.aquariumPro => Icons.emoji_events_outlined,
    };
  }

  Color _getLevelColor(UserLevel level) {
    return switch (level) {
      UserLevel.beginnerAquarist => Colors.blue.shade700,
      UserLevel.caretaker => Colors.green.shade700,
      UserLevel.fishMaster => Colors.purple.shade700,
      UserLevel.aquariumPro => Colors.amber.shade800,
    };
  }

  Color _getLevelBackgroundColor(UserLevel level) {
    return switch (level) {
      UserLevel.beginnerAquarist => Colors.blue.shade50,
      UserLevel.caretaker => Colors.green.shade50,
      UserLevel.fishMaster => Colors.purple.shade50,
      UserLevel.aquariumPro => Colors.amber.shade50,
    };
  }

  _BadgeDimensions _getDimensions(LevelBadgeSize size) {
    return switch (size) {
      LevelBadgeSize.small => const _BadgeDimensions(
          horizontalPadding: 8,
          verticalPadding: 4,
          iconSize: 14,
          fontSize: 11,
          spacing: 4,
          borderRadius: 12,
        ),
      LevelBadgeSize.medium => const _BadgeDimensions(
          horizontalPadding: 12,
          verticalPadding: 6,
          iconSize: 18,
          fontSize: 13,
          spacing: 6,
          borderRadius: 16,
        ),
      LevelBadgeSize.large => const _BadgeDimensions(
          horizontalPadding: 16,
          verticalPadding: 8,
          iconSize: 24,
          fontSize: 16,
          spacing: 8,
          borderRadius: 20,
        ),
    };
  }
}

/// Size variants for LevelBadge.
enum LevelBadgeSize {
  /// Small badge for compact displays.
  small,

  /// Medium badge for standard use (default).
  medium,

  /// Large badge for prominent displays.
  large,
}

/// Dimension configuration for badge sizes.
class _BadgeDimensions {
  const _BadgeDimensions({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.iconSize,
    required this.fontSize,
    required this.spacing,
    required this.borderRadius,
  });

  final double horizontalPadding;
  final double verticalPadding;
  final double iconSize;
  final double fontSize;
  final double spacing;
  final double borderRadius;
}

/// Extension to get a descriptive tooltip for each level.
extension LevelBadgeTooltip on UserLevel {
  /// Returns a localized tooltip description for this level.
  String getTooltip(AppLocalizations l10n) {
    return switch (this) {
      UserLevel.beginnerAquarist => l10n.levelBeginnerTooltip,
      UserLevel.caretaker => l10n.levelCaretakerTooltip,
      UserLevel.fishMaster => l10n.levelMasterTooltip,
      UserLevel.aquariumPro => l10n.levelProTooltip,
    };
  }
}
