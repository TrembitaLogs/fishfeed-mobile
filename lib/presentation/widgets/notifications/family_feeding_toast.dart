import 'package:flutter/material.dart';

import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';

/// A toast notification for family feeding events.
///
/// Displays when another family member completes a feeding.
/// Shows the family member's name and avatar.
class FamilyFeedingToast extends StatelessWidget {
  const FamilyFeedingToast({
    required this.event,
    this.onDismiss,
    super.key,
  });

  /// The feeding event from the family member.
  final FeedingEvent event;

  /// Callback when the toast is dismissed.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final userName = event.completedByName ?? 'Family member';
    final avatarUrl = event.completedByAvatar;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar or icon
            if (avatarUrl != null)
              AppCachedAvatar(
                imageUrl: avatarUrl,
                radius: 20,
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: _buildDefaultAvatar(),
              ),
            const SizedBox(width: 12),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Feeding completed',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Check icon
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 18,
              ),
            ),

            // Dismiss button
            if (onDismiss != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return const Center(
      child: Icon(
        Icons.person,
        color: Color(0xFF4CAF50),
        size: 20,
      ),
    );
  }
}

/// Overlay for displaying family feeding toasts.
///
/// Use this to show animated toasts from the top of the screen.
class FamilyFeedingToastOverlay {
  FamilyFeedingToastOverlay._();

  static OverlayEntry? _currentEntry;
  static bool _isShowing = false;

  /// Shows a toast notification for a family feeding event.
  ///
  /// The toast automatically dismisses after 3 seconds.
  static void show(
    BuildContext context, {
    required FeedingEvent event,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (_isShowing) {
      _currentEntry?.remove();
    }

    _isShowing = true;

    final overlay = Overlay.of(context);

    _currentEntry = OverlayEntry(
      builder: (context) => _AnimatedToast(
        event: event,
        duration: duration,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
          _isShowing = false;
        },
      ),
    );

    overlay.insert(_currentEntry!);
  }

  /// Hides the current toast if showing.
  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
    _isShowing = false;
  }
}

class _AnimatedToast extends StatefulWidget {
  const _AnimatedToast({
    required this.event,
    required this.duration,
    required this.onDismiss,
  });

  final FeedingEvent event;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dy < -100) {
                _dismiss();
              }
            },
            child: FamilyFeedingToast(
              event: widget.event,
              onDismiss: _dismiss,
            ),
          ),
        ),
      ),
    );
  }
}
