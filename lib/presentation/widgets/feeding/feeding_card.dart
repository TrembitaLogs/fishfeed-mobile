import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/router/app_router.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';
import 'package:fishfeed/presentation/widgets/feeding/confirm_feeding_dialog.dart';
import 'package:fishfeed/presentation/widgets/feeding/fish_card_sheet.dart';
import 'package:fishfeed/presentation/widgets/feeding/status_indicator.dart';

/// Callback type for feeding status changes.
typedef FeedingStatusCallback = void Function(String scheduleId);

/// Card widget displaying a scheduled feeding with swipe and tap actions.
///
/// Features:
/// - Tap to open fish card bottom sheet (all states)
/// - Swipe right to show confirmation dialog before marking as fed (unfed only)
/// - Swipe left to navigate to Edit Fish screen (all states)
/// - When fed: only left swipe (edit) is available
/// - When unfed: both swipe directions are available
/// - Card states: pending (normal), fed (green), syncing (cloud icon)
/// - Haptic feedback on both swipe directions
class FeedingCard extends StatefulWidget {
  const FeedingCard({
    super.key,
    required this.feeding,
    required this.onMarkAsFed,
  });

  /// The computed feeding event to display.
  final ComputedFeedingEvent feeding;

  /// Callback when feeding is confirmed as fed.
  final FeedingStatusCallback onMarkAsFed;

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

  /// Gets display name for the feeding (fish name or aquarium name).
  String get _displayName =>
      widget.feeding.fishName ?? widget.feeding.aquariumName ?? 'Fish';

  void _onTap() {
    // Tap opens fish card bottom sheet for ALL states
    showFishCardSheet(context, widget.feeding);
  }

  Future<bool> _confirmDismiss(DismissDirection direction) async {
    if (direction == DismissDirection.startToEnd) {
      // Swipe right: Mark as Fed
      if (widget.feeding.status == EventStatus.fed) return false;

      unawaited(HapticFeedback.mediumImpact());

      final confirmed = await showConfirmFeedingDialog(context, widget.feeding);
      if (confirmed && mounted) {
        widget.onMarkAsFed(widget.feeding.scheduleId);
        _showSuccessSnackBar(context);
      }
    } else if (direction == DismissDirection.endToStart) {
      // Swipe left: Navigate to Edit Fish screen
      unawaited(HapticFeedback.mediumImpact());

      if (mounted) {
        unawaited(
          context.push(
            AppRouter.editFish.replaceFirst(':fishId', widget.feeding.fishId),
          ),
        );
      }
    }

    // Always return false to keep card in list
    return false;
  }

  void _showSuccessSnackBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('$_displayName - ${l10n.feedingCompleted}'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
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
    final isFed = widget.feeding.status == EventStatus.fed;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: Dismissible(
        key: Key('feeding_card_${widget.feeding.scheduleId}'),
        direction: isFed
            ? DismissDirection.endToStart
            : DismissDirection.horizontal,
        confirmDismiss: _confirmDismiss,
        background: _SwipeBackground(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          color: Colors.green,
          icon: Icons.check_circle,
          label: l10n.feedingLabel,
        ),
        secondaryBackground: _SwipeBackground(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          color: theme.colorScheme.primary,
          icon: Icons.edit,
          label: l10n.editFish,
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

/// Background shown during swipe gestures (left or right).
class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.padding,
    required this.color,
    required this.icon,
    required this.label,
  });

  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry padding;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Content of the feeding card with status-dependent styling.
class _FeedingCardContent extends StatelessWidget {
  const _FeedingCardContent({
    required this.feeding,
    required this.onTap,
    required this.theme,
  });

  final ComputedFeedingEvent feeding;
  final VoidCallback onTap;
  final ThemeData theme;

  /// Gets display name for the feeding (fish name or aquarium name).
  String get _displayName => feeding.fishName ?? feeding.aquariumName ?? 'Fish';

  bool get _isFed => feeding.status == EventStatus.fed;
  bool get _isSyncing =>
      feeding.status == EventStatus.fed && feeding.log?.synced == false;

  Color get _backgroundColor {
    if (_isFed) {
      return Colors.green.withValues(alpha: 0.08);
    }
    return theme.colorScheme.surfaceContainerLow;
  }

  BoxBorder? get _border {
    if (_isFed) {
      return const Border(left: BorderSide(color: Colors.green, width: 3));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = StatusIndicator.getEventStatusColor(feeding.status);

    final semanticLabel =
        '${_displayName}, ${feeding.time}, ${feeding.foodType}';

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        color: Colors.transparent,
        shadowColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: _border,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status indicator or sync icon
                  if (_isSyncing)
                    _SyncIcon(theme: theme)
                  else
                    StatusIndicator.fromEventStatus(status: feeding.status),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fish name + quantity
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _displayName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: _isFed
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: _isFed
                                      ? theme.colorScheme.onSurfaceVariant
                                      : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (feeding.fishQuantity > 1) ...[
                              const SizedBox(width: 6),
                              Text(
                                l10n.fishCount(feeding.fishQuantity),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          feeding.aquariumName ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        // Fed time or attribution
                        if (_isFed && feeding.log?.actedAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.fedAtTime(
                              DateFormat.Hm().format(
                                feeding.log!.actedAt.toLocal(),
                              ),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        // Fed by attribution (only for completed feedings with user info)
                        if (_isFed && feeding.log?.actedByUserName != null) ...[
                          const SizedBox(height: 4),
                          _FedByLabel(
                            name: feeding.log!.actedByUserName!,
                            avatarUrl: feeding.avatarUrl,
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
                        feeding.time,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        feeding.foodType,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  // Chevron hint for detail sheet (all states)
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sync icon displayed when feeding is fed but not yet synced.
class _SyncIcon extends StatelessWidget {
  const _SyncIcon({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.cloud_upload_outlined,
        color: Colors.blue,
        size: 22,
      ),
    );
  }
}

/// Widget displaying who completed the feeding.
class _FedByLabel extends StatelessWidget {
  const _FedByLabel({required this.name, this.avatarUrl, required this.theme});

  final String name;
  final String? avatarUrl;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppCachedAvatar(imageUrl: avatarUrl, radius: 8),
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
