import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Result of the freeze day dialog.
enum FreezeDayDialogResult {
  /// User chose to use a freeze day.
  useFreeze,

  /// User chose to lose the streak.
  loseStreak,

  /// User dismissed the dialog without a choice.
  dismissed,
}

/// A dialog that appears when a user misses a feeding day with an active streak.
///
/// Offers the option to use a freeze day to preserve the streak
/// or accept losing the streak.
///
/// Features:
/// - Animated snowflake icon with rotation and pulse
/// - Clear explanation of the situation
/// - Shows remaining freeze days count
/// - Two action buttons: use freeze or lose streak
class FreezeDayDialog extends StatefulWidget {
  const FreezeDayDialog({
    super.key,
    required this.currentStreak,
    required this.freezeAvailable,
  });

  /// Current streak that would be lost.
  final int currentStreak;

  /// Number of freeze days available.
  final int freezeAvailable;

  /// Shows the freeze day dialog.
  ///
  /// Returns [FreezeDayDialogResult.useFreeze] if the user wants to use a freeze,
  /// [FreezeDayDialogResult.loseStreak] if they accept losing the streak,
  /// or [FreezeDayDialogResult.dismissed] if the dialog was dismissed.
  static Future<FreezeDayDialogResult> show(
    BuildContext context, {
    required int currentStreak,
    required int freezeAvailable,
  }) async {
    final result = await showDialog<FreezeDayDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) => FreezeDayDialog(
        currentStreak: currentStreak,
        freezeAvailable: freezeAvailable,
      ),
    );

    return result ?? FreezeDayDialogResult.dismissed;
  }

  @override
  State<FreezeDayDialog> createState() => _FreezeDayDialogState();
}

class _FreezeDayDialogState extends State<FreezeDayDialog>
    with TickerProviderStateMixin {
  late AnimationController _snowflakeController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Snowflake rotation animation
    _snowflakeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _snowflakeController, curve: Curves.linear),
    );

    // Pulse animation for emphasis
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _snowflakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canUseFreeze = widget.freezeAvailable > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated snowflake icon
            _buildAnimatedSnowflake(theme),

            const SizedBox(height: 24),

            // Title
            Text(
              'Missed Feeding',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              _getDescription(canUseFreeze),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Streak info chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.currentStreak} day streak at risk',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Use freeze button (primary action)
            if (canUseFreeze)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(FreezeDayDialogResult.useFreeze),
                  icon: const Icon(Icons.ac_unit),
                  label: Text(
                    'Use Freeze Day (${widget.freezeAvailable} left)',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.cyan.shade600,
                  ),
                ),
              ),

            if (canUseFreeze) const SizedBox(height: 8),

            // Lose streak button (secondary action)
            SizedBox(
              width: double.infinity,
              child: canUseFreeze
                  ? TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(FreezeDayDialogResult.loseStreak),
                      child: const Text('Lose Streak'),
                    )
                  : FilledButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(FreezeDayDialogResult.loseStreak),
                      child: const Text('Continue'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSnowflake(ThemeData theme) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.cyan.shade100, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(Icons.ac_unit, size: 44, color: Colors.cyan.shade700),
      ),
    );
  }

  String _getDescription(bool canUseFreeze) {
    if (canUseFreeze) {
      return 'You missed feeding your fish today. '
          'Use a freeze day to protect your streak!';
    }
    return 'You missed feeding your fish today '
        'and have no freeze days left. '
        'Your streak will be reset.';
  }
}
