import 'package:flutter/material.dart';

/// A styled card widget with customizable padding and tap handling.
///
/// Uses the app's CardTheme for consistent styling.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.elevation,
  });

  /// The content to display inside the card.
  final Widget child;

  /// Padding around the card content.
  /// Defaults to EdgeInsets.all(16) if not specified.
  final EdgeInsetsGeometry? padding;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Elevation override for the card shadow.
  /// Uses theme default if not specified.
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePadding = padding ?? const EdgeInsets.all(16);

    final cardContent = Padding(padding: effectivePadding, child: child);

    if (onTap != null) {
      return Card(
        elevation: elevation,
        child: InkWell(
          onTap: onTap,
          borderRadius: _getBorderRadius(theme),
          child: cardContent,
        ),
      );
    }

    return Card(elevation: elevation, child: cardContent);
  }

  BorderRadius? _getBorderRadius(ThemeData theme) {
    final shape = theme.cardTheme.shape;
    if (shape is RoundedRectangleBorder) {
      final borderRadius = shape.borderRadius;
      if (borderRadius is BorderRadius) {
        return borderRadius;
      }
    }
    return BorderRadius.circular(12);
  }
}
