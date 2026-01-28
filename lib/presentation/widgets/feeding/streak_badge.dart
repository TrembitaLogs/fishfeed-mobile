import 'package:flutter/material.dart';
import 'package:fishfeed/l10n/app_localizations.dart';

/// A compact badge widget displaying the user's feeding streak.
///
/// Features:
/// - Fire icon with streak count
/// - Color changes based on streak magnitude:
///   - < 7 days: amber
///   - 7-30 days: orange
///   - > 30 days: red gradient
/// - Scale bounce animation when streak increases
/// - Tooltip showing "{N} days in a row!"
class StreakBadge extends StatefulWidget {
  const StreakBadge({
    super.key,
    required this.streak,
    this.previousStreak,
    this.size = StreakBadgeSize.medium,
  });

  /// Current streak count.
  final int streak;

  /// Previous streak value for animation trigger.
  /// When provided and less than [streak], triggers bounce animation.
  final int? previousStreak;

  /// Size variant of the badge.
  final StreakBadgeSize size;

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

/// Size variants for StreakBadge.
enum StreakBadgeSize {
  /// Small badge for compact displays.
  small,

  /// Medium badge for standard use (default).
  medium,

  /// Large badge for prominent displays.
  large,
}

class _StreakBadgeState extends State<StreakBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(StreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger bounce animation when streak increases
    if (widget.streak > oldWidget.streak ||
        (widget.previousStreak != null &&
            widget.previousStreak! < widget.streak)) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final color = _getStreakColor(widget.streak);
    final dimensions = _getDimensions(widget.size);

    return Tooltip(
      message: l10n.streakDaysInRow(widget.streak),
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: dimensions.horizontalPadding,
            vertical: dimensions.verticalPadding,
          ),
          decoration: BoxDecoration(
            gradient: _getStreakGradient(widget.streak, theme),
            borderRadius: BorderRadius.circular(dimensions.borderRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department,
                size: dimensions.iconSize,
                color: color,
              ),
              SizedBox(width: dimensions.spacing),
              Text(
                widget.streak.toString(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: dimensions.fontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns the text/icon color based on streak magnitude.
  Color _getStreakColor(int streak) {
    if (streak > 30) {
      return Colors.red.shade900;
    } else if (streak >= 7) {
      return Colors.orange.shade900;
    } else {
      return Colors.amber.shade900;
    }
  }

  /// Returns the background gradient based on streak magnitude.
  LinearGradient _getStreakGradient(int streak, ThemeData theme) {
    if (streak > 30) {
      // Hot red gradient for long streaks
      return LinearGradient(
        colors: [
          Colors.red.shade100,
          Colors.orange.shade100,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (streak >= 7) {
      // Orange gradient for medium streaks
      return LinearGradient(
        colors: [
          Colors.orange.shade100,
          Colors.amber.shade100,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // Amber gradient for starting streaks
      return LinearGradient(
        colors: [
          Colors.amber.shade100,
          Colors.amber.shade50,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  _BadgeDimensions _getDimensions(StreakBadgeSize size) {
    return switch (size) {
      StreakBadgeSize.small => const _BadgeDimensions(
          horizontalPadding: 8,
          verticalPadding: 4,
          iconSize: 14,
          fontSize: 12,
          spacing: 2,
          borderRadius: 12,
        ),
      StreakBadgeSize.medium => const _BadgeDimensions(
          horizontalPadding: 12,
          verticalPadding: 6,
          iconSize: 18,
          fontSize: 14,
          spacing: 4,
          borderRadius: 16,
        ),
      StreakBadgeSize.large => const _BadgeDimensions(
          horizontalPadding: 16,
          verticalPadding: 8,
          iconSize: 24,
          fontSize: 18,
          spacing: 6,
          borderRadius: 20,
        ),
    };
  }
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
