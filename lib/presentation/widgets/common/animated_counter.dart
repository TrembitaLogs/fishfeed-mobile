import 'package:flutter/material.dart';

/// An animated counter that counts up from a previous value to a new value.
///
/// Features:
/// - Smooth count up animation
/// - Customizable duration and curve
/// - Formats numbers with optional suffix
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.style,
    this.suffix = '',
    this.prefix = '',
  });

  /// The target value to display.
  final int value;

  /// Duration of the count animation.
  final Duration duration;

  /// Animation curve.
  final Curve curve;

  /// Text style for the counter.
  final TextStyle? style;

  /// Suffix to append after the number (e.g., " days").
  final String suffix;

  /// Prefix to prepend before the number (e.g., "+").
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, child) {
        return Text(
          '$prefix$animatedValue$suffix',
          style: style,
        );
      },
    );
  }
}

/// An animated counter that animates between old and new values.
///
/// Use this when you need to animate from a previous value rather than from 0.
class AnimatedCounterFromTo extends StatefulWidget {
  const AnimatedCounterFromTo({
    super.key,
    required this.value,
    this.previousValue,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
    this.style,
    this.suffix = '',
    this.prefix = '',
  });

  /// The target value to display.
  final int value;

  /// The previous value to animate from. If null, animates from 0 on first build.
  final int? previousValue;

  /// Duration of the count animation.
  final Duration duration;

  /// Animation curve.
  final Curve curve;

  /// Text style for the counter.
  final TextStyle? style;

  /// Suffix to append after the number.
  final String suffix;

  /// Prefix to prepend before the number.
  final String prefix;

  @override
  State<AnimatedCounterFromTo> createState() => _AnimatedCounterFromToState();
}

class _AnimatedCounterFromToState extends State<AnimatedCounterFromTo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  int _oldValue = 0;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.previousValue ?? 0;
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _updateAnimation();
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounterFromTo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
      _updateAnimation();
      _controller.forward(from: 0);
    }
  }

  void _updateAnimation() {
    _animation = IntTween(
      begin: _oldValue,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix}${_animation.value}${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}

/// An animated XP counter with special styling for level ups.
///
/// Shows the XP gain with a flash effect when XP increases.
class AnimatedXpCounter extends StatefulWidget {
  const AnimatedXpCounter({
    super.key,
    required this.currentXp,
    required this.maxXp,
    this.level = 1,
    this.showLevel = true,
    this.duration = const Duration(milliseconds: 800),
  });

  /// Current XP value.
  final int currentXp;

  /// Maximum XP for current level.
  final int maxXp;

  /// Current level.
  final int level;

  /// Whether to show the level indicator.
  final bool showLevel;

  /// Duration of the animation.
  final Duration duration;

  @override
  State<AnimatedXpCounter> createState() => _AnimatedXpCounterState();
}

class _AnimatedXpCounterState extends State<AnimatedXpCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _glowAnimation;
  int _oldXp = 0;

  @override
  void initState() {
    super.initState();
    _oldXp = widget.currentXp;
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _updateAnimations();
  }

  @override
  void didUpdateWidget(AnimatedXpCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentXp != widget.currentXp) {
      _oldXp = oldWidget.currentXp;
      _updateAnimations();
      _controller.forward(from: 0);
    }
  }

  void _updateAnimations() {
    final oldProgress = _oldXp / widget.maxXp;
    final newProgress = widget.currentXp / widget.maxXp;

    _progressAnimation = Tween<double>(
      begin: oldProgress.clamp(0.0, 1.0),
      end: newProgress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Glow effect when gaining XP
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 70,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showLevel)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level ${widget.level}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    '${widget.currentXp} / ${widget.maxXp} XP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Stack(
              children: [
                // Background
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Progress
                FractionallySizedBox(
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: _glowAnimation.value > 0
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: _glowAnimation.value * 0.5),
                                blurRadius: 8 * _glowAnimation.value,
                                spreadRadius: 2 * _glowAnimation.value,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
