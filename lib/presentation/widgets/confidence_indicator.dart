import 'dart:async';

import 'package:flutter/material.dart';

/// Confidence level thresholds for visual indication.
enum ConfidenceLevel {
  /// High confidence (>= 80%) - green color.
  high,

  /// Medium confidence (50-79%) - yellow/amber color.
  medium,

  /// Low confidence (< 50%) - red color.
  low,
}

/// Extension to determine confidence level from a value.
extension ConfidenceLevelExtension on double {
  /// Returns the confidence level based on the value.
  ///
  /// - >= 0.8: high
  /// - >= 0.5: medium
  /// - < 0.5: low
  ConfidenceLevel get confidenceLevel {
    if (this >= 0.8) return ConfidenceLevel.high;
    if (this >= 0.5) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }
}

/// A circular progress indicator that displays AI scan confidence.
///
/// Features:
/// - Animated circular progress indicator
/// - Color coding based on confidence level (green/yellow/red)
/// - Percentage display in the center
/// - Optional pulse animation on appearance
///
/// Usage:
/// ```dart
/// ConfidenceIndicator(
///   confidence: 0.85,
///   size: 120,
///   showPulse: true,
/// )
/// ```
class ConfidenceIndicator extends StatefulWidget {
  const ConfidenceIndicator({
    super.key,
    required this.confidence,
    this.size = 100,
    this.strokeWidth = 8,
    this.showPulse = true,
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  /// Confidence value from 0.0 to 1.0.
  final double confidence;

  /// Size of the indicator (width and height).
  final double size;

  /// Stroke width of the circular progress.
  final double strokeWidth;

  /// Whether to show pulse animation on appearance.
  final bool showPulse;

  /// Duration of the progress animation.
  final Duration animationDuration;

  @override
  State<ConfidenceIndicator> createState() => _ConfidenceIndicatorState();
}

class _ConfidenceIndicatorState extends State<ConfidenceIndicator>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  Timer? _pulseStopTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Progress animation
    _progressController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0, end: widget.confidence)
        .animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _progressController.forward();

    if (widget.showPulse) {
      _pulseController.repeat(reverse: true);
      // Stop pulse after a few cycles using Timer (can be cancelled on dispose)
      _pulseStopTimer = Timer(const Duration(milliseconds: 2400), () {
        if (mounted && _pulseController.isAnimating) {
          _pulseController.stop();
          if (mounted) {
            _pulseController.animateTo(1.0);
          }
        }
      });
    }
  }

  @override
  void didUpdateWidget(ConfidenceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.confidence != widget.confidence) {
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: widget.confidence,
          ).animate(
            CurvedAnimation(
              parent: _progressController,
              curve: Curves.easeOutCubic,
            ),
          );
      _progressController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _pulseStopTimer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _getConfidenceColor(BuildContext context) {
    final level = widget.confidence.confidenceLevel;
    final colorScheme = Theme.of(context).colorScheme;

    return switch (level) {
      ConfidenceLevel.high => Colors.green.shade600,
      ConfidenceLevel.medium => Colors.amber.shade600,
      ConfidenceLevel.low => colorScheme.error,
    };
  }

  Color _getBackgroundColor(BuildContext context) {
    final level = widget.confidence.confidenceLevel;

    return switch (level) {
      ConfidenceLevel.high => Colors.green.shade100,
      ConfidenceLevel.medium => Colors.amber.shade100,
      ConfidenceLevel.low => Colors.red.shade100,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _getConfidenceColor(context);
    final backgroundColor = _getBackgroundColor(context);
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: Listenable.merge([_progressAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.showPulse ? _pulseAnimation.value : 1.0,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: widget.strokeWidth,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(backgroundColor),
                  ),
                ),
                // Progress circle
                SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CircularProgressIndicator(
                    value: _progressAnimation.value,
                    strokeWidth: widget.strokeWidth,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Percentage text - use FittedBox to scale if needed
                Padding(
                  padding: EdgeInsets.all(widget.strokeWidth + 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(_progressAnimation.value * 100).round()}%',
                          style: textTheme.headlineMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'confidence',
                          style: textTheme.bodySmall?.copyWith(
                            color: color.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
