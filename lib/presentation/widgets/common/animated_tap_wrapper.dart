import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fishfeed/core/config/animation_config.dart';

/// A wrapper widget that adds tap animation and optional haptic feedback.
///
/// Wraps any widget with:
/// - Scale animation on tap (press down: shrink, release: bounce back)
/// - Optional haptic feedback (light, medium, heavy, or selection)
/// - Respects disabled state
class AnimatedTapWrapper extends StatefulWidget {
  const AnimatedTapWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.hapticFeedback = HapticFeedbackType.light,
    this.isEnabled = true,
    this.scaleDown = AnimationConfig.pressedScale,
  });

  /// The child widget to wrap.
  final Widget child;

  /// Callback when tapped. If null, no interaction is applied.
  final VoidCallback? onTap;

  /// Type of haptic feedback to trigger on tap.
  final HapticFeedbackType hapticFeedback;

  /// Whether the tap interaction is enabled.
  final bool isEnabled;

  /// Scale factor when pressed (default: 0.95).
  final double scaleDown;

  @override
  State<AnimatedTapWrapper> createState() => _AnimatedTapWrapperState();
}

class _AnimatedTapWrapperState extends State<AnimatedTapWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConfig.durationXFast,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: AnimationConfig.defaultCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isEnabled || widget.onTap == null) return;
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isEnabled || widget.onTap == null) return;
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (!widget.isEnabled || widget.onTap == null) return;
    _controller.reverse();
  }

  void _handleTap() {
    if (!widget.isEnabled || widget.onTap == null) return;

    // Trigger haptic feedback
    _triggerHaptic(widget.hapticFeedback);

    widget.onTap?.call();
  }

  void _triggerHaptic(HapticFeedbackType type) {
    switch (type) {
      case HapticFeedbackType.none:
        break;
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.isEnabled && widget.onTap != null;

    return GestureDetector(
      onTapDown: isInteractive ? _handleTapDown : null,
      onTapUp: isInteractive ? _handleTapUp : null,
      onTapCancel: isInteractive ? _handleTapCancel : null,
      onTap: isInteractive ? _handleTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

/// Types of haptic feedback available.
enum HapticFeedbackType {
  /// No haptic feedback.
  none,

  /// Light impact feedback (subtle).
  light,

  /// Medium impact feedback (noticeable).
  medium,

  /// Heavy impact feedback (strong).
  heavy,

  /// Selection click feedback.
  selection,
}
