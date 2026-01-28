import 'package:flutter/material.dart';

/// A widget displaying the number of available freeze days.
///
/// Shows snowflake icons to represent freeze days that can be used
/// to prevent streak loss on missed feeding days.
///
/// Features:
/// - Displays 0-N snowflake icons based on available freeze days
/// - Shows used slots as faded/outlined icons
/// - Tooltip explaining the freeze feature
/// - Scale animation when freeze count changes
class FreezeIndicator extends StatefulWidget {
  const FreezeIndicator({
    super.key,
    required this.available,
    this.total = 2,
    this.size = FreezeIndicatorSize.medium,
    this.showTooltip = true,
  });

  /// Number of freeze days currently available.
  final int available;

  /// Total freeze days per month.
  final int total;

  /// Size variant of the indicator.
  final FreezeIndicatorSize size;

  /// Whether to show tooltip on tap.
  final bool showTooltip;

  @override
  State<FreezeIndicator> createState() => _FreezeIndicatorState();
}

/// Size variants for FreezeIndicator.
enum FreezeIndicatorSize {
  /// Small indicator for compact displays.
  small,

  /// Medium indicator for standard use (default).
  medium,

  /// Large indicator for prominent displays.
  large,
}

class _FreezeIndicatorState extends State<FreezeIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_pulseController);
  }

  @override
  void didUpdateWidget(FreezeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger pulse animation when freeze count changes
    if (widget.available != oldWidget.available) {
      _pulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimensions = _getDimensions(widget.size);
    final activeColor = Colors.cyan.shade600;
    final inactiveColor = theme.colorScheme.outline.withValues(alpha: 0.4);

    final content = AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _pulseAnimation.value, child: child);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dimensions.horizontalPadding,
          vertical: dimensions.verticalPadding,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(dimensions.borderRadius),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < widget.total; i++) ...[
              if (i > 0) SizedBox(width: dimensions.spacing),
              Icon(
                i < widget.available ? Icons.ac_unit : Icons.ac_unit_outlined,
                size: dimensions.iconSize,
                color: i < widget.available ? activeColor : inactiveColor,
              ),
            ],
          ],
        ),
      ),
    );

    if (!widget.showTooltip) {
      return content;
    }

    return Tooltip(message: _getTooltipMessage(context), child: content);
  }

  String _getTooltipMessage(BuildContext context) {
    if (widget.available == 0) {
      return 'No freeze days left this month';
    }
    if (widget.available == 1) {
      return '1 freeze day available';
    }
    return '${widget.available} freeze days available';
  }

  _FreezeDimensions _getDimensions(FreezeIndicatorSize size) {
    return switch (size) {
      FreezeIndicatorSize.small => const _FreezeDimensions(
        horizontalPadding: 6,
        verticalPadding: 4,
        iconSize: 14,
        spacing: 2,
        borderRadius: 8,
      ),
      FreezeIndicatorSize.medium => const _FreezeDimensions(
        horizontalPadding: 10,
        verticalPadding: 6,
        iconSize: 18,
        spacing: 4,
        borderRadius: 12,
      ),
      FreezeIndicatorSize.large => const _FreezeDimensions(
        horizontalPadding: 14,
        verticalPadding: 8,
        iconSize: 24,
        spacing: 6,
        borderRadius: 16,
      ),
    };
  }
}

/// Dimension configuration for freeze indicator sizes.
class _FreezeDimensions {
  const _FreezeDimensions({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.iconSize,
    required this.spacing,
    required this.borderRadius,
  });

  final double horizontalPadding;
  final double verticalPadding;
  final double iconSize;
  final double spacing;
  final double borderRadius;
}
