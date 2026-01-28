import 'package:flutter/material.dart';

import 'package:fishfeed/presentation/widgets/common/loading_indicator.dart';

/// A modal overlay that displays a loading indicator.
///
/// Blocks user interaction while loading is in progress.
/// Use [LoadingOverlay.show] and [LoadingOverlay.hide] for easy control,
/// or wrap content with [LoadingOverlay] widget.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.opacity = 0.5,
  });

  /// Whether to show the loading overlay.
  final bool isLoading;

  /// The widget below this widget in the tree.
  final Widget child;

  /// Optional message to display with the loading indicator.
  final String? message;

  /// Opacity of the overlay background.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: _LoadingOverlayContent(
              message: message,
              opacity: opacity,
            ),
          ),
      ],
    );
  }

  /// Shows a modal loading overlay.
  ///
  /// Returns a function to dismiss the overlay.
  /// Call the returned function or [hide] to remove the overlay.
  static OverlayEntry show(
    BuildContext context, {
    String? message,
    double opacity = 0.5,
  }) {
    final overlayEntry = OverlayEntry(
      builder: (context) => _LoadingOverlayContent(
        message: message,
        opacity: opacity,
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    return overlayEntry;
  }

  /// Hides the loading overlay created by [show].
  static void hide(OverlayEntry? entry) {
    entry?.remove();
  }
}

class _LoadingOverlayContent extends StatelessWidget {
  const _LoadingOverlayContent({
    this.message,
    required this.opacity,
  });

  final String? message;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AbsorbPointer(
      absorbing: true,
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: theme.colorScheme.scrim.withValues(alpha: opacity),
          child: LoadingIndicator(message: message),
        ),
      ),
    );
  }
}
