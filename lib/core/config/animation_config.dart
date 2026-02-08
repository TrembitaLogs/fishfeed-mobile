import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Animation configuration constants for consistent animations across the app.
///
/// Uses flutter_animate package for declarative animations.
/// Respects user accessibility preferences for reduced motion.
abstract final class AnimationConfig {
  // ============================================
  // Duration Constants
  // ============================================

  /// Extra fast animations (100ms) - for micro-interactions like button taps
  static const Duration durationXFast = Duration(milliseconds: 100);

  /// Fast animations (200ms) - for quick feedback
  static const Duration durationFast = Duration(milliseconds: 200);

  /// Normal animations (300ms) - default duration for most animations
  static const Duration durationNormal = Duration(milliseconds: 300);

  /// Medium animations (400ms) - for more noticeable transitions
  static const Duration durationMedium = Duration(milliseconds: 400);

  /// Slow animations (500ms) - for emphasis and dramatic effects
  static const Duration durationSlow = Duration(milliseconds: 500);

  /// Extra slow animations (800ms) - for elaborate transitions
  static const Duration durationXSlow = Duration(milliseconds: 800);

  // ============================================
  // Curve Constants
  // ============================================

  /// Default easing curve for most animations
  static const Curve defaultCurve = Curves.easeOutCubic;

  /// Curve for entrance animations
  static const Curve entranceCurve = Curves.easeOut;

  /// Curve for exit animations
  static const Curve exitCurve = Curves.easeIn;

  /// Curve for bounce effects
  static const Curve bounceCurve = Curves.elasticOut;

  /// Curve for spring-like animations
  static const Curve springCurve = Curves.easeOutBack;

  // ============================================
  // Stagger Intervals
  // ============================================

  /// Default interval between staggered list items
  static const Duration staggerInterval = Duration(milliseconds: 50);

  /// Fast stagger interval for quick list reveals
  static const Duration staggerIntervalFast = Duration(milliseconds: 30);

  /// Slow stagger interval for dramatic reveals
  static const Duration staggerIntervalSlow = Duration(milliseconds: 100);

  // ============================================
  // Scale Values
  // ============================================

  /// Scale for pressed state (slightly smaller)
  static const double pressedScale = 0.95;

  /// Scale for hover/focus state (slightly larger)
  static const double hoverScale = 1.02;

  /// Scale for emphasis animation
  static const double emphasisScale = 1.1;

  // ============================================
  // Offset Values
  // ============================================

  /// Vertical slide offset for entrance animations
  static const double slideInOffsetY = 20.0;

  /// Horizontal slide offset for entrance animations
  static const double slideInOffsetX = 20.0;

  // ============================================
  // Page Transition Configuration
  // ============================================

  /// Duration for page transitions
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);

  /// Curve for page transitions
  static const Curve pageTransitionCurve = Curves.easeInOut;

  // ============================================
  // Accessibility Helpers
  // ============================================

  /// Returns true if the user has enabled "Reduce Motion" in system settings.
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Returns [Duration.zero] if reduce motion is on, otherwise returns [duration].
  static Duration resolveDuration(BuildContext context, Duration duration) {
    return shouldReduceMotion(context) ? Duration.zero : duration;
  }
}

/// Extension methods for applying common animations using flutter_animate.
///
/// All methods respect the user's "Reduce Motion" accessibility setting.
/// When reduce motion is enabled, the widget is returned without animations.
extension AnimateExtensions on Widget {
  /// Applies a fade-in and slide-up animation for list items.
  /// Skips animation when reduce motion is enabled.
  Widget animateListItem(
    BuildContext context, {
    Duration? delay,
    Duration duration = AnimationConfig.durationNormal,
  }) {
    if (AnimationConfig.shouldReduceMotion(context)) return this;
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: AnimationConfig.entranceCurve)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: duration,
          curve: AnimationConfig.entranceCurve,
        );
  }

  /// Applies a scale-in animation for cards and containers.
  /// Skips animation when reduce motion is enabled.
  Widget animateScaleIn(
    BuildContext context, {
    Duration? delay,
    Duration duration = AnimationConfig.durationNormal,
  }) {
    if (AnimationConfig.shouldReduceMotion(context)) return this;
    return animate(delay: delay)
        .fadeIn(duration: duration)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.0, 1.0),
          duration: duration,
          curve: AnimationConfig.springCurve,
        );
  }

  /// Applies a slide-in from left animation.
  /// Skips animation when reduce motion is enabled.
  Widget animateSlideInLeft(
    BuildContext context, {
    Duration? delay,
    Duration duration = AnimationConfig.durationNormal,
  }) {
    if (AnimationConfig.shouldReduceMotion(context)) return this;
    return animate(delay: delay)
        .fadeIn(duration: duration)
        .slideX(
          begin: -0.1,
          end: 0,
          duration: duration,
          curve: AnimationConfig.entranceCurve,
        );
  }

  /// Applies a slide-in from right animation.
  /// Skips animation when reduce motion is enabled.
  Widget animateSlideInRight(
    BuildContext context, {
    Duration? delay,
    Duration duration = AnimationConfig.durationNormal,
  }) {
    if (AnimationConfig.shouldReduceMotion(context)) return this;
    return animate(delay: delay)
        .fadeIn(duration: duration)
        .slideX(
          begin: 0.1,
          end: 0,
          duration: duration,
          curve: AnimationConfig.entranceCurve,
        );
  }

  /// Applies a bounce-in animation for emphasis.
  /// Skips animation when reduce motion is enabled.
  Widget animateBounceIn(
    BuildContext context, {
    Duration? delay,
    Duration duration = AnimationConfig.durationMedium,
  }) {
    if (AnimationConfig.shouldReduceMotion(context)) return this;
    return animate(delay: delay)
        .fadeIn(duration: duration)
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.0, 1.0),
          duration: duration,
          curve: AnimationConfig.bounceCurve,
        );
  }
}

/// Extension for staggered list animations.
extension AnimateListExtensions on List<Widget> {
  /// Applies staggered fade-in and slide animations to a list of widgets.
  List<Widget> animateStaggered({
    Duration interval = AnimationConfig.staggerInterval,
    Duration duration = AnimationConfig.durationNormal,
  }) {
    return animate(interval: interval)
        .fadeIn(duration: duration, curve: AnimationConfig.entranceCurve)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: duration,
          curve: AnimationConfig.entranceCurve,
        );
  }
}
