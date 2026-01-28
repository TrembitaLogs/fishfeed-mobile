import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import 'package:fishfeed/core/constants/achievements.dart';
import 'package:fishfeed/domain/entities/achievement.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/widgets/gamification/share_card.dart';
import 'package:fishfeed/services/share_service.dart';

/// Full-screen overlay displayed when an achievement is unlocked.
///
/// Features:
/// - Confetti animation
/// - Sound effect
/// - Auto-dismiss after 3 seconds
/// - Tap to dismiss
class AchievementUnlockOverlay extends StatefulWidget {
  const AchievementUnlockOverlay({
    super.key,
    required this.achievement,
    this.onDismiss,
    this.autoDismissSeconds = 3,
  });

  /// The achievement that was unlocked.
  final Achievement achievement;

  /// Callback when the overlay is dismissed.
  final VoidCallback? onDismiss;

  /// Seconds before auto-dismiss (default: 3).
  final int autoDismissSeconds;

  /// Shows the overlay as a modal route.
  static Future<void> show(
    BuildContext context, {
    required Achievement achievement,
    VoidCallback? onDismiss,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Achievement Unlock',
      barrierColor: Colors.black54,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AchievementUnlockOverlay(
          achievement: achievement,
          onDismiss: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  @override
  State<AchievementUnlockOverlay> createState() =>
      _AchievementUnlockOverlayState();
}

class _AchievementUnlockOverlayState extends State<AchievementUnlockOverlay>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ShareService _shareService = ShareService();
  Timer? _autoDismissTimer;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();

    // Initialize confetti
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Initialize pulse animation for the icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Start confetti and play sound
    _confettiController.play();
    _playUnlockSound();

    // Auto-dismiss timer
    _autoDismissTimer = Timer(
      Duration(seconds: widget.autoDismissSeconds),
      _dismiss,
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    _audioPlayer.dispose();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  Future<void> _playUnlockSound() async {
    try {
      // Play a system sound or asset sound
      // For now, we'll use a simple beep - can be replaced with custom sound
      await _audioPlayer.setSourceAsset('sounds/achievement_unlock.mp3');
      await _audioPlayer.resume();
    } catch (e) {
      // Sound playback failed - not critical, continue without sound
      debugPrint('Failed to play achievement sound: $e');
    }
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    widget.onDismiss?.call();
  }

  Future<void> _shareAchievement() async {
    if (_isSharing) return;

    // Cancel auto-dismiss while sharing
    _autoDismissTimer?.cancel();

    setState(() {
      _isSharing = true;
    });

    try {
      final shareCard = ShareCard.localized(
        achievement: widget.achievement,
        context: context,
      );
      await _shareService.shareAchievementWithWidget(
        widget: shareCard,
        achievement: widget.achievement,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
        // Restart auto-dismiss after sharing
        _autoDismissTimer = Timer(
          Duration(seconds: widget.autoDismissSeconds),
          _dismiss,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievementType = widget.achievement.achievementType;
    final color = achievementType?.color ?? Colors.amber;
    final icon = achievementType?.icon ?? Icons.emoji_events;

    return GestureDetector(
      onTap: _dismiss,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Main content
            Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Achievement unlocked label
                    Text(
                      AppLocalizations.of(context)!.achievementUnlocked,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Animated icon
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [color.withValues(alpha: 0.8), color],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(icon, size: 50, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Achievement title
                    Text(
                      widget.achievement.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Achievement description
                    if (widget.achievement.description != null)
                      Text(
                        widget.achievement.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 16),

                    // XP reward
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: color, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '+${widget.achievement.xpReward} XP',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Share button
                    FilledButton.icon(
                      onPressed: _isSharing ? null : _shareAchievement,
                      icon: _isSharing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share, size: 18),
                      label: Text(
                        _isSharing
                            ? AppLocalizations.of(context)!.sharingButton
                            : AppLocalizations.of(context)!.shareButton,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tap to dismiss hint
                    Text(
                      AppLocalizations.of(context)!.tapToDismiss,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Confetti - top center
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: [
                  color,
                  color.withValues(alpha: 0.8),
                  Colors.amber,
                  Colors.orange,
                  Colors.yellow,
                ],
                numberOfParticles: 30,
                maxBlastForce: 20,
                minBlastForce: 5,
                emissionFrequency: 0.05,
                gravity: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to show multiple achievements in sequence.
class AchievementUnlockQueue extends StatefulWidget {
  const AchievementUnlockQueue({
    super.key,
    required this.achievements,
    this.onAllDismissed,
  });

  /// List of achievements to show.
  final List<Achievement> achievements;

  /// Callback when all achievements have been dismissed.
  final VoidCallback? onAllDismissed;

  @override
  State<AchievementUnlockQueue> createState() => _AchievementUnlockQueueState();
}

class _AchievementUnlockQueueState extends State<AchievementUnlockQueue> {
  int _currentIndex = 0;

  void _showNext() {
    if (_currentIndex < widget.achievements.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      widget.onAllDismissed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.achievements.length) {
      return const SizedBox.shrink();
    }

    return AchievementUnlockOverlay(
      achievement: widget.achievements[_currentIndex],
      onDismiss: _showNext,
    );
  }
}
