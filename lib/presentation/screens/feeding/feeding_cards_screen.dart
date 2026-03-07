import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fishfeed/core/config/animation_config.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/router/app_router.dart';
import 'package:fishfeed/presentation/widgets/feeding/confirm_feeding_dialog.dart';
import 'package:fishfeed/presentation/widgets/feeding/feeding_card.dart';
import 'package:fishfeed/presentation/widgets/sheets/aquarium_card_sheet.dart';
import 'package:fishfeed/services/sync/conflict_resolver.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

/// Feeding cards screen for a specific aquarium.
///
/// Groups cards by exact schedule.time (e.g., "09:00", "12:00", "18:00").
/// Each Fish record = one card per spec section 3.2.
///
/// Features:
/// - Time group headers with "Now" indicator for the current time slot
/// - Pull-to-refresh triggering sync + data reload
/// - Conflict stream listener showing styled toast for family mode
/// - Staggered entrance animations for cards
/// - Tappable aquarium name in AppBar opening aquarium card sheet
class FeedingCardsScreen extends ConsumerStatefulWidget {
  const FeedingCardsScreen({
    super.key,
    required this.aquariumId,
    this.autoFedScheduleId,
  });

  /// The aquarium ID to display feedings for.
  final String aquariumId;

  /// Optional schedule ID to automatically show the feeding confirmation dialog.
  ///
  /// When set (from notification "Fed" action), the screen will find the
  /// matching feeding event and show the confirmation dialog automatically.
  final String? autoFedScheduleId;

  @override
  ConsumerState<FeedingCardsScreen> createState() => _FeedingCardsScreenState();
}

class _FeedingCardsScreenState extends ConsumerState<FeedingCardsScreen> {
  /// Key to trigger re-animation on refresh.
  Key _listKey = UniqueKey();

  /// Subscription to feeding conflict stream for async conflict notifications.
  StreamSubscription<SyncConflict<Map<String, dynamic>>>?
  _feedingConflictSubscription;

  /// Whether the auto-fed dialog has already been shown (prevents duplicates).
  bool _autoFedDialogShown = false;

  @override
  void initState() {
    super.initState();
    _feedingConflictSubscription = ref
        .read(syncServiceProvider)
        .feedingConflictStream
        .listen(_onFeedingConflict);

    // Schedule auto-fed dialog after first frame if needed
    if (widget.autoFedScheduleId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryShowAutoFedDialog();
      });
    }
  }

  @override
  void dispose() {
    _feedingConflictSubscription?.cancel();
    super.dispose();
  }

  void _onFeedingConflict(SyncConflict<Map<String, dynamic>> conflict) {
    // Filter conflicts for this aquarium only
    final serverVersion = conflict.serverVersion;
    final conflictAquariumId = serverVersion['aquarium_id']?.toString();
    if (conflictAquariumId != null && conflictAquariumId != widget.aquariumId) {
      return;
    }

    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final actedByName =
        serverVersion['acted_by_user_name']?.toString() ?? l10n.familyMember;
    final actedAtStr = serverVersion['acted_at']?.toString();
    final actedAt = actedAtStr != null ? DateTime.tryParse(actedAtStr) : null;
    final timeStr = actedAt != null
        ? DateFormat.Hm().format(actedAt.toLocal())
        : '?';

    final message = l10n.feedingAlreadyDoneByMember(actedByName, timeStr);

    // Styled toast for family mode conflicts
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.people_alt, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );

    // Refresh to reflect the resolved conflict
    ref.read(todayFeedingsProvider.notifier).refresh();
  }

  /// Attempts to show the auto-fed confirmation dialog.
  ///
  /// Searches for a feeding event matching [widget.autoFedScheduleId].
  /// If already fed, shows a snackbar. Otherwise, shows the confirmation
  /// dialog and marks as fed on user confirmation.
  void _tryShowAutoFedDialog() {
    if (_autoFedDialogShown || widget.autoFedScheduleId == null || !mounted) {
      return;
    }

    final groupedByTime = ref.read(
      feedingsGroupedByTimeProvider(widget.aquariumId),
    );

    // Find the matching feeding event
    ComputedFeedingEvent? targetFeeding;
    for (final feedings in groupedByTime.values) {
      for (final feeding in feedings) {
        if (feeding.scheduleId == widget.autoFedScheduleId) {
          targetFeeding = feeding;
          break;
        }
      }
      if (targetFeeding != null) break;
    }

    // Data not loaded yet — will retry when provider updates
    if (targetFeeding == null && groupedByTime.isEmpty) return;

    _autoFedDialogShown = true;

    if (targetFeeding == null) return;

    // Already completed — show snackbar
    if (targetFeeding.isCompleted) {
      final l10n = AppLocalizations.of(context);
      if (l10n != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.feedingAlreadyCompleted)));
      }
      return;
    }

    // Show confirmation dialog
    _showAutoFedConfirmation(targetFeeding);
  }

  Future<void> _showAutoFedConfirmation(ComputedFeedingEvent feeding) async {
    if (!mounted) return;

    final confirmed = await showConfirmFeedingDialog(context, feeding);
    if (confirmed && mounted) {
      await ref
          .read(todayFeedingsProvider.notifier)
          .markAsFed(feeding.scheduleId);
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(syncServiceProvider).syncNow();
    await ref.read(todayFeedingsProvider.notifier).refresh();
    setState(() {
      _listKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final aquarium = ref.watch(aquariumByIdProvider(widget.aquariumId));
    final groupedByTime = ref.watch(
      feedingsGroupedByTimeProvider(widget.aquariumId),
    );
    final notifier = ref.read(todayFeedingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    // Retry auto-fed dialog when data loads (provider rebuilds)
    if (widget.autoFedScheduleId != null && !_autoFedDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryShowAutoFedDialog();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => showAquariumCardSheet(
            context,
            widget.aquariumId,
            onDeleted: () {
              // Navigate back to Home after aquarium deletion from this screen
              context.go(AppRouter.home);
            },
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  aquarium?.name ?? l10n.feedingLabel,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(groupedByTime, notifier, l10n),
      ),
    );
  }

  Widget _buildBody(
    Map<String, List<ComputedFeedingEvent>> groupedByTime,
    TodayFeedingsNotifier notifier,
    AppLocalizations l10n,
  ) {
    if (groupedByTime.isEmpty) {
      return _EmptyState(l10n: l10n);
    }

    final items = <Widget>[];
    final now = DateTime.now();
    final currentTimeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    int animationIndex = 0;

    for (final entry in groupedByTime.entries) {
      final time = entry.key;
      final feedings = entry.value;

      // Time group header
      final isNow = _isCurrentTimeSlot(time, currentTimeStr, groupedByTime);
      items.add(_TimeGroupHeader(time: time, isNow: isNow));

      // Feeding cards for this time group
      final reduceMotion = AnimationConfig.shouldReduceMotion(context);
      for (final feeding in feedings) {
        final card = FeedingCard(
          key: Key('feeding_${feeding.scheduleId}'),
          feeding: feeding,
          onMarkAsFed: notifier.markAsFed,
        );
        if (reduceMotion) {
          items.add(card);
        } else {
          final delay = Duration(
            milliseconds:
                animationIndex * AnimationConfig.staggerInterval.inMilliseconds,
          );
          items.add(
            card
                .animate(delay: delay)
                .fadeIn(
                  duration: AnimationConfig.durationNormal,
                  curve: AnimationConfig.entranceCurve,
                )
                .slideY(
                  begin: 0.1,
                  end: 0,
                  duration: AnimationConfig.durationNormal,
                  curve: AnimationConfig.entranceCurve,
                ),
          );
        }
        animationIndex++;
      }
    }

    return ListView(
      key: _listKey,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: items,
    );
  }

  /// Determines if [slotTime] is the current active time slot.
  ///
  /// The current slot is the latest slot whose time is <= current time.
  /// If no slot is <= current time, no slot is marked as "now".
  bool _isCurrentTimeSlot(
    String slotTime,
    String currentTime,
    Map<String, List<ComputedFeedingEvent>> groupedByTime,
  ) {
    // Find the latest slot that is <= currentTime
    String? latestPastSlot;
    for (final key in groupedByTime.keys) {
      if (key.compareTo(currentTime) <= 0) {
        if (latestPastSlot == null || key.compareTo(latestPastSlot) > 0) {
          latestPastSlot = key;
        }
      }
    }
    return slotTime == latestPastSlot;
  }
}

/// Empty state widget displayed when no feedings are scheduled.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Icon(
          Icons.no_food_outlined,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.noFeedingsScheduled,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Header widget for a time group section (e.g., "09:00" or "09:00 — Now").
class _TimeGroupHeader extends StatelessWidget {
  const _TimeGroupHeader({required this.time, this.isNow = false});

  /// The time string for this group (e.g., "09:00").
  final String time;

  /// Whether this is the current active time slot.
  final bool isNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isNow
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            isNow ? '$time — Now' : time,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
