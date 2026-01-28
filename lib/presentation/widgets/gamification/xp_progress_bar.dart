import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:fishfeed/core/constants/levels.dart';

/// An animated progress bar showing XP progress towards the next level.
///
/// Features:
/// - Animated progress fill with gradient
/// - Level name and XP display
/// - Sparkle animation on level up
/// - Smooth progress transitions
class XpProgressBar extends StatefulWidget {
  const XpProgressBar({
    super.key,
    required this.totalXp,
    this.previousXp,
    this.showLevelName = true,
    this.showXpText = true,
    this.height = 12.0,
    this.onLevelUp,
  });

  /// Total XP accumulated by the user.
  final int totalXp;

  /// Previous XP value for animation purposes.
  /// When provided and differs from [totalXp], triggers animation.
  final int? previousXp;

  /// Whether to show the level name above the bar.
  final bool showLevelName;

  /// Whether to show XP text below the bar.
  final bool showXpText;

  /// Height of the progress bar.
  final double height;

  /// Callback triggered when a level up is detected.
  final VoidCallback? onLevelUp;

  @override
  State<XpProgressBar> createState() => _XpProgressBarState();
}

class _XpProgressBarState extends State<XpProgressBar>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _sparkleController;
  late Animation<double> _progressAnimation;
  late Animation<double> _sparkleAnimation;

  double _previousProgress = 0.0;
  // ignore: unused_field
  UserLevel? _previousLevel;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _sparkleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeOut),
    );

    _previousProgress = LevelConstants.getXpProgress(widget.previousXp ?? widget.totalXp);
    _previousLevel = LevelConstants.getLevelForXp(widget.previousXp ?? widget.totalXp);
  }

  @override
  void didUpdateWidget(XpProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.totalXp != oldWidget.totalXp) {
      final newLevel = LevelConstants.getLevelForXp(widget.totalXp);
      final oldLevel = LevelConstants.getLevelForXp(oldWidget.totalXp);

      // Check for level up
      if (newLevel != oldLevel &&
          LevelConstants.orderedLevels.indexOf(newLevel) >
          LevelConstants.orderedLevels.indexOf(oldLevel)) {
        _sparkleController.forward(from: 0);
        widget.onLevelUp?.call();
      }

      _previousProgress = LevelConstants.getXpProgress(oldWidget.totalXp);
      _previousLevel = oldLevel;
      _progressController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLevel = LevelConstants.getLevelForXp(widget.totalXp);
    final currentProgress = LevelConstants.getXpProgress(widget.totalXp);
    final xpToNext = LevelConstants.getXpToNextLevel(widget.totalXp);
    final xpInLevel = widget.totalXp - currentLevel.minXp;
    final xpForLevel = currentLevel.maxXp != null
        ? currentLevel.maxXp! - currentLevel.minXp
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLevelName) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentLevel.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getLevelColor(currentLevel, theme),
                ),
              ),
              if (currentLevel.nextLevel != null)
                Text(
                  currentLevel.nextLevel!.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Progress bar with sparkle overlay
        Stack(
          children: [
            // Main progress bar
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                // Interpolate between previous and current progress
                final animatedProgress = _previousProgress +
                    (_progressAnimation.value * (currentProgress - _previousProgress));

                return _buildProgressBar(
                  context,
                  animatedProgress,
                  currentLevel,
                );
              },
            ),

            // Sparkle overlay for level up
            if (_sparkleController.isAnimating || _sparkleController.value > 0)
              AnimatedBuilder(
                animation: _sparkleAnimation,
                builder: (context, child) {
                  return _buildSparkleOverlay(context, _sparkleAnimation.value);
                },
              ),
          ],
        ),

        if (widget.showXpText) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.totalXp} XP',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (xpToNext > 0)
                Text(
                  '$xpInLevel / $xpForLevel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Text(
                  'Max Level',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    double progress,
    UserLevel level,
  ) {
    final theme = Theme.of(context);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(widget.height / 2),
      ),
      child: Stack(
        children: [
          // Filled portion
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: _getLevelGradient(level, theme),
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
            ),
          ),
          // Shine effect
          if (progress > 0)
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.5],
                  ),
                  borderRadius: BorderRadius.circular(widget.height / 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSparkleOverlay(BuildContext context, double animationValue) {
    return SizedBox(
      height: widget.height,
      child: CustomPaint(
        painter: _SparklePainter(
          progress: animationValue,
          color: Colors.amber,
        ),
        size: Size.infinite,
      ),
    );
  }

  Color _getLevelColor(UserLevel level, ThemeData theme) {
    return switch (level) {
      UserLevel.beginnerAquarist => Colors.blue.shade700,
      UserLevel.caretaker => Colors.green.shade700,
      UserLevel.fishMaster => Colors.purple.shade700,
      UserLevel.aquariumPro => Colors.amber.shade700,
    };
  }

  LinearGradient _getLevelGradient(UserLevel level, ThemeData theme) {
    return switch (level) {
      UserLevel.beginnerAquarist => LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      UserLevel.caretaker => LinearGradient(
          colors: [Colors.green.shade400, Colors.teal.shade600],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      UserLevel.fishMaster => LinearGradient(
          colors: [Colors.purple.shade400, Colors.deepPurple.shade600],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      UserLevel.aquariumPro => LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade600],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
    };
  }
}

/// Custom painter for sparkle effect during level up.
class _SparklePainter extends CustomPainter {
  _SparklePainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final random = math.Random(42);
    final paint = Paint()
      ..color = color.withValues(alpha: (1 - progress) * 0.8)
      ..style = PaintingStyle.fill;

    // Draw multiple sparkles
    for (var i = 0; i < 12; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;

      // Sparkles move up and outward
      final dx = (random.nextDouble() - 0.5) * 40 * progress;
      final dy = -random.nextDouble() * 30 * progress;

      final x = startX + dx;
      final y = startY + dy;

      final sparkleSize = (1 - progress) * (2 + random.nextDouble() * 3);

      if (sparkleSize > 0) {
        canvas.drawCircle(Offset(x, y), sparkleSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
