import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A bouncing dots loading indicator.
///
/// Displays three dots that animate in a wave pattern.
/// More visually appealing than a standard circular progress indicator.
class BouncingDotsLoader extends StatelessWidget {
  const BouncingDotsLoader({
    super.key,
    this.color,
    this.size = 10.0,
    this.spacing = 4.0,
  });

  /// Color of the dots. Defaults to theme's primary color.
  final Color? color;

  /// Size of each dot.
  final double size;

  /// Spacing between dots.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = color ?? theme.colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(color: dotColor, size: size, delay: 0.ms),
        SizedBox(width: spacing),
        _Dot(color: dotColor, size: size, delay: 100.ms),
        SizedBox(width: spacing),
        _Dot(color: dotColor, size: size, delay: 200.ms),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.color,
    required this.size,
    required this.delay,
  });

  final Color color;
  final double size;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
          delay: delay,
        )
        .scaleXY(
          begin: 0.5,
          end: 1.0,
          duration: 400.ms,
          curve: Curves.easeInOut,
        )
        .fadeIn(
          begin: 0.3,
          duration: 400.ms,
        );
  }
}

/// An enhanced loading indicator with optional bouncing dots variant.
///
/// Can display either bouncing dots or a circular progress indicator.
class EnhancedLoadingIndicator extends StatelessWidget {
  const EnhancedLoadingIndicator({
    super.key,
    this.message,
    this.size = 36.0,
    this.useDots = false,
    this.color,
  });

  /// Optional message to display below the indicator.
  final String? message;

  /// Size of the loading indicator.
  final double size;

  /// Whether to use bouncing dots instead of circular progress.
  final bool useDots;

  /// Color of the indicator. Defaults to theme's primary color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.colorScheme.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (useDots)
            BouncingDotsLoader(
              color: indicatorColor,
              size: size / 3,
            )
          else
            SizedBox(
              height: size,
              width: size,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
              ),
            ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// A pulsing logo animation for splash screens.
class PulsingLogo extends StatelessWidget {
  const PulsingLogo({
    super.key,
    required this.child,
  });

  /// The logo widget to animate.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .scaleXY(
          begin: 0.95,
          end: 1.05,
          duration: 1200.ms,
          curve: Curves.easeInOut,
        )
        .fadeIn(
          begin: 0.7,
          duration: 1200.ms,
        );
  }
}
