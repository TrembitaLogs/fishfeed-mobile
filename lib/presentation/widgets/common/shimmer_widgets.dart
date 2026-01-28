import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loading widget for feeding cards.
///
/// Displays a placeholder matching the FeedingCard layout with
/// animated shimmer effect.
class ShimmerFeedingCard extends StatelessWidget {
  const ShimmerFeedingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerLow,
      highlightColor: theme.colorScheme.surfaceContainerHigh,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Status indicator placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            // Content placeholder
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // Time placeholder
            Container(
              width: 50,
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading widget for list tiles.
///
/// A generic shimmer placeholder for list items with leading icon,
/// title, and optional subtitle.
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({
    super.key,
    this.hasLeading = true,
    this.hasSubtitle = true,
    this.hasTrailing = false,
    this.leadingSize = 40,
  });

  /// Whether to show a leading circle placeholder.
  final bool hasLeading;

  /// Whether to show a subtitle placeholder.
  final bool hasSubtitle;

  /// Whether to show a trailing placeholder.
  final bool hasTrailing;

  /// Size of the leading circle.
  final double leadingSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerLow,
      highlightColor: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (hasLeading) ...[
              Container(
                width: leadingSize,
                height: leadingSize,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  if (hasSubtitle) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: 150,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasTrailing) ...[
              const SizedBox(width: 16),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading widget for calendar day cells.
///
/// Displays a placeholder matching the CalendarDayCell layout
/// with day number and status dot.
class ShimmerCalendarDay extends StatelessWidget {
  const ShimmerCalendarDay({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerLow,
      highlightColor: theme.colorScheme.surfaceContainerHigh,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day number placeholder
            Container(
              width: 20,
              height: 14,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            // Status dot placeholder
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading widget for grid items.
///
/// A generic shimmer placeholder for grid cards like species selection.
class ShimmerGridCard extends StatelessWidget {
  const ShimmerGridCard({
    super.key,
    this.aspectRatio = 1.0,
  });

  /// Aspect ratio of the card.
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerLow,
      highlightColor: theme.colorScheme.surfaceContainerHigh,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A generic shimmer box for custom loading states.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 4,
    this.shape = BoxShape.rectangle,
  });

  /// Width of the shimmer box.
  final double width;

  /// Height of the shimmer box.
  final double height;

  /// Border radius (only for rectangle shape).
  final double borderRadius;

  /// Shape of the shimmer box.
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerLow,
      highlightColor: theme.colorScheme.surfaceContainerHigh,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          shape: shape,
          borderRadius:
              shape == BoxShape.rectangle ? BorderRadius.circular(borderRadius) : null,
        ),
      ),
    );
  }
}

/// A wrapper widget that applies shimmer effect to its child.
///
/// Useful for creating custom shimmer loading states.
class ShimmerWrapper extends StatelessWidget {
  const ShimmerWrapper({
    super.key,
    required this.child,
    this.enabled = true,
  });

  /// The child widget to apply shimmer effect to.
  final Widget child;

  /// Whether the shimmer effect is enabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerLow,
      highlightColor: theme.colorScheme.surfaceContainerHigh,
      child: child,
    );
  }
}
