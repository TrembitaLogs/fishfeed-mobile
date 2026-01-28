import 'package:flutter/material.dart';

/// Badge showing remaining free AI scans.
///
/// Features:
/// - Animated count changes with scale effect
/// - Warning colors when scans are low (1-2 remaining)
/// - Hidden when user has unlimited scans (-1)
///
/// Usage:
/// ```dart
/// ScansRemainingBadge(
///   scansRemaining: 3,
/// )
/// ```
class ScansRemainingBadge extends StatefulWidget {
  const ScansRemainingBadge({super.key, required this.scansRemaining});

  /// Number of scans remaining.
  /// -1 means unlimited (premium user) - badge is hidden.
  /// 0 means no scans remaining.
  final int scansRemaining;

  @override
  State<ScansRemainingBadge> createState() => _ScansRemainingBadgeState();
}

class _ScansRemainingBadgeState extends State<ScansRemainingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _previousCount = -2; // Use -2 to detect first build

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_animationController);
  }

  @override
  void didUpdateWidget(ScansRemainingBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animate when count changes (except on first build)
    if (_previousCount != -2 &&
        oldWidget.scansRemaining != widget.scansRemaining) {
      _animationController.forward(from: 0);
    }
    _previousCount = widget.scansRemaining;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide badge for unlimited scans (premium users)
    if (widget.scansRemaining < 0) {
      return const SizedBox.shrink();
    }

    final isWarning = widget.scansRemaining <= 2;
    final isCritical = widget.scansRemaining == 0;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getBackgroundColor(isWarning, isCritical),
          borderRadius: BorderRadius.circular(16),
          border: isWarning
              ? Border.all(
                  color: isCritical
                      ? Colors.red.withValues(alpha: 0.5)
                      : Colors.orange.withValues(alpha: 0.5),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcon(isWarning, isCritical),
              color: _getIconColor(isWarning, isCritical),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              _getText(),
              style: TextStyle(
                color: _getTextColor(isWarning, isCritical),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isWarning, bool isCritical) {
    if (isCritical) {
      return Colors.red.shade900.withValues(alpha: 0.8);
    }
    if (isWarning) {
      return Colors.orange.shade900.withValues(alpha: 0.7);
    }
    return Colors.black54;
  }

  IconData _getIcon(bool isWarning, bool isCritical) {
    if (isCritical) {
      return Icons.warning_amber_rounded;
    }
    if (isWarning) {
      return Icons.info_outline;
    }
    return Icons.auto_awesome;
  }

  Color _getIconColor(bool isWarning, bool isCritical) {
    if (isCritical) {
      return Colors.red.shade300;
    }
    if (isWarning) {
      return Colors.orange.shade300;
    }
    return Colors.amber;
  }

  Color _getTextColor(bool isWarning, bool isCritical) {
    if (isCritical || isWarning) {
      return Colors.white;
    }
    return Colors.white;
  }

  String _getText() {
    if (widget.scansRemaining == 0) {
      return 'No scans left';
    }
    if (widget.scansRemaining == 1) {
      return '1 scan left';
    }
    return '${widget.scansRemaining} scans left';
  }
}
