import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fishfeed/l10n/app_localizations.dart';

import 'package:fishfeed/domain/entities/feeding_status.dart';
import 'package:fishfeed/domain/entities/scheduled_feeding.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';
import 'package:fishfeed/presentation/widgets/feeding/status_indicator.dart';

/// Callback type for feeding status changes.
typedef FeedingStatusCallback = void Function(String feedingId);

/// Card widget displaying a scheduled feeding with swipe actions.
///
/// Features:
/// - Status indicator with colors (Fed/Missed/Pending)
/// - One-tap to mark pending feeding as fed
/// - Swipe right to mark as fed
/// - Swipe left to mark as missed
/// - Haptic feedback on actions
/// - Smooth animations for status changes
class FeedingCard extends StatefulWidget {
  const FeedingCard({
    super.key,
    required this.feeding,
    required this.onMarkAsFed,
    required this.onMarkAsMissed,
  });

  /// The scheduled feeding to display.
  final ScheduledFeeding feeding;

  /// Callback when feeding is marked as fed.
  final FeedingStatusCallback onMarkAsFed;

  /// Callback when feeding is marked as missed.
  final FeedingStatusCallback onMarkAsMissed;

  @override
  State<FeedingCard> createState() => _FeedingCardState();
}

class _FeedingCardState extends State<FeedingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.feeding.status == FeedingStatus.pending) {
      _animateAndMarkAsFed();
    }
  }

  Future<void> _animateAndMarkAsFed() async {
    // Fire-and-forget haptic feedback (don't await to avoid blocking in tests)
    unawaited(HapticFeedback.mediumImpact());
    await _scaleController.forward();
    await _scaleController.reverse();
    widget.onMarkAsFed(widget.feeding.id);
    if (mounted) {
      _showSuccessSnackBar(context);
    }
  }

  void _showSuccessSnackBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('${widget.feeding.displayName} - ${l10n.feedingCompleted}'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<bool> _confirmDismiss(DismissDirection direction) async {
    // Fire-and-forget haptic feedback
    unawaited(HapticFeedback.mediumImpact());

    if (direction == DismissDirection.startToEnd) {
      // Swipe right - mark as fed
      if (widget.feeding.status != FeedingStatus.fed) {
        widget.onMarkAsFed(widget.feeding.id);
        if (mounted) {
          _showSuccessSnackBar(context);
        }
      }
    } else if (direction == DismissDirection.endToStart) {
      // Swipe left - mark as missed
      if (widget.feeding.status != FeedingStatus.missed) {
        widget.onMarkAsMissed(widget.feeding.id);
        if (mounted) {
          _showMissedSnackBar(context);
        }
      }
    }

    // Return false to prevent actual dismissal (keep the card in list)
    return false;
  }

  void _showMissedSnackBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('${widget.feeding.displayName} - ${l10n.feedingMissed}'),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Dismissible(
        key: Key('feeding_card_${widget.feeding.id}'),
        direction: DismissDirection.horizontal,
        confirmDismiss: _confirmDismiss,
        background: _SwipeBackground(
          direction: DismissDirection.startToEnd,
          color: Colors.green,
          icon: Icons.check_circle,
          label: l10n.feedingLabel,
        ),
        secondaryBackground: _SwipeBackground(
          direction: DismissDirection.endToStart,
          color: Colors.red.shade400,
          icon: Icons.cancel,
          label: l10n.feedingMissed,
        ),
        child: RepaintBoundary(
          child: _FeedingCardContent(
            feeding: widget.feeding,
            onTap: _onTap,
            theme: theme,
          ),
        ),
      ),
    );
  }
}

/// Background shown during swipe gesture.
class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.direction,
    required this.color,
    required this.icon,
    required this.label,
  });

  final DismissDirection direction;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isStartToEnd = direction == DismissDirection.startToEnd;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: isStartToEnd ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.only(
        left: isStartToEnd ? 24 : 0,
        right: isStartToEnd ? 0 : 24,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isStartToEnd
            ? [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]
            : [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 24),
              ],
      ),
    );
  }
}

/// Content of the feeding card.
class _FeedingCardContent extends StatelessWidget {
  const _FeedingCardContent({
    required this.feeding,
    required this.onTap,
    required this.theme,
  });

  final ScheduledFeeding feeding;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final statusColor = StatusIndicator.getStatusColor(feeding.status);
    final canTap = feeding.status == FeedingStatus.pending;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: canTap ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status indicator
              StatusIndicator(status: feeding.status),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feeding.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: feeding.status == FeedingStatus.fed
                            ? TextDecoration.lineThrough
                            : null,
                        color: feeding.status == FeedingStatus.fed
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      feeding.aquariumName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    // Fed by attribution (only for completed feedings with user info)
                    if (feeding.status == FeedingStatus.fed &&
                        feeding.completedByName != null) ...[
                      const SizedBox(height: 4),
                      _FedByLabel(
                        name: feeding.completedByName!,
                        avatarUrl: feeding.completedByAvatar,
                        theme: theme,
                      ),
                    ],
                  ],
                ),
              ),
              // Time and food type
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(feeding.scheduledTime),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                  if (feeding.foodType != null)
                    Text(
                      feeding.foodType!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              // Chevron hint for pending items
              if (canTap) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.touch_app_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Widget displaying who completed the feeding.
class _FedByLabel extends StatelessWidget {
  const _FedByLabel({
    required this.name,
    this.avatarUrl,
    required this.theme,
  });

  final String name;
  final String? avatarUrl;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppCachedAvatar(
          imageUrl: avatarUrl,
          radius: 8,
        ),
        const SizedBox(width: 4),
        Text(
          name,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}
