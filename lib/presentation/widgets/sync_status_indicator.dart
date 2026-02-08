import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/services/connectivity/connectivity_service.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

/// Compact sync status indicator for displaying in app bar.
///
/// Shows current sync state with animated icons and "Last synced" time.
/// Tap to trigger manual sync.
///
/// States:
/// - Syncing: animated sync icon
/// - Synced: check icon with relative time
/// - Error: error icon with retry option
/// - Offline: cloud off icon
class SyncStatusIndicator extends ConsumerStatefulWidget {
  const SyncStatusIndicator({super.key});

  @override
  ConsumerState<SyncStatusIndicator> createState() =>
      _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends ConsumerState<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Refresh every minute to update relative time
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncStateProvider);
    final isOffline = ref.watch(isOfflineProvider);
    final syncService = ref.watch(syncServiceProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Handle animation based on sync state
    syncState.whenData((state) {
      if (state == SyncState.syncing) {
        _animationController.repeat();
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    });

    final statusLabel = _getSyncStatusLabel(
      syncState,
      isOffline,
      syncService.lastSyncTime,
      l10n,
    );

    return Semantics(
      label: statusLabel,
      button: true,
      child: InkWell(
        onTap: () => _onTap(context, syncService, isOffline),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(syncState, isOffline, theme),
              const SizedBox(width: 6),
              _buildLabel(
                syncState,
                isOffline,
                syncService.lastSyncTime,
                l10n,
                theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(
    AsyncValue<SyncState> syncState,
    bool isOffline,
    ThemeData theme,
  ) {
    if (isOffline) {
      return Icon(
        Icons.cloud_off_rounded,
        size: 18,
        color: theme.colorScheme.outline,
      );
    }

    return syncState.when(
      data: (state) {
        switch (state) {
          case SyncState.syncing:
            return RotationTransition(
              turns: _animationController,
              child: Icon(
                Icons.sync_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            );
          case SyncState.success:
          case SyncState.idle:
            return Icon(
              Icons.cloud_done_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            );
          case SyncState.error:
            return Icon(
              Icons.sync_problem_rounded,
              size: 18,
              color: theme.colorScheme.error,
            );
        }
      },
      // Show idle state while loading to avoid stuck "Syncing" indicator
      loading: () => Icon(
        Icons.cloud_done_rounded,
        size: 18,
        color: theme.colorScheme.primary,
      ),
      error: (_, __) => Icon(
        Icons.sync_problem_rounded,
        size: 18,
        color: theme.colorScheme.error,
      ),
    );
  }

  Widget _buildLabel(
    AsyncValue<SyncState> syncState,
    bool isOffline,
    DateTime? lastSyncTime,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (isOffline) {
      return Text(
        l10n.syncStatusOffline,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      );
    }

    return syncState.when(
      data: (state) {
        switch (state) {
          case SyncState.syncing:
            return Text(
              l10n.syncStatusSyncing,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            );
          case SyncState.success:
          case SyncState.idle:
            if (lastSyncTime != null) {
              return Text(
                _formatRelativeTime(lastSyncTime, l10n),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            }
            return Text(
              l10n.syncStatusSynced,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            );
          case SyncState.error:
            return Text(
              l10n.syncStatusError,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            );
        }
      },
      // Show synced state while loading to avoid stuck "Syncing" indicator
      loading: () => Text(
        l10n.syncStatusSynced,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      error: (_, __) => Text(
        l10n.syncStatusError,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }

  /// Returns a combined sync status label for screen readers.
  String _getSyncStatusLabel(
    AsyncValue<SyncState> syncState,
    bool isOffline,
    DateTime? lastSyncTime,
    AppLocalizations l10n,
  ) {
    if (isOffline) return l10n.syncStatusOffline;
    return syncState.maybeWhen(
      data: (state) => switch (state) {
        SyncState.syncing => l10n.syncStatusSyncing,
        SyncState.success || SyncState.idle =>
          lastSyncTime != null
              ? _formatRelativeTime(lastSyncTime, l10n)
              : l10n.syncStatusSynced,
        SyncState.error => l10n.syncStatusError,
      },
      orElse: () => l10n.syncStatusSynced,
    );
  }

  String _formatRelativeTime(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return l10n.syncStatusJustNow;
    } else if (difference.inMinutes < 60) {
      return l10n.syncStatusMinutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.syncStatusHoursAgo(difference.inHours);
    } else {
      return l10n.syncStatusDaysAgo(difference.inDays);
    }
  }

  Future<void> _onTap(
    BuildContext context,
    SyncService syncService,
    bool isOffline,
  ) async {
    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.syncCannotSyncOffline),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Trigger manual sync
    await syncService.syncNow();
  }
}

/// Provider that combines sync state with additional metadata.
///
/// Provides a unified view of sync status including:
/// - Current sync state
/// - Online/offline status
/// - Pending items count
/// - Last sync time
class SyncStatusState {
  const SyncStatusState({
    required this.syncState,
    required this.isOnline,
    required this.pendingCount,
    this.lastSyncTime,
  });

  final SyncState syncState;
  final bool isOnline;
  final int pendingCount;
  final DateTime? lastSyncTime;

  bool get hasPendingItems => pendingCount > 0;
}

/// Provider for combined sync status.
final syncStatusProvider = Provider<SyncStatusState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final isOnline = ref
      .watch(isOnlineProvider)
      .maybeWhen(data: (value) => value, orElse: () => true);

  final syncState = ref
      .watch(syncStateProvider)
      .maybeWhen(data: (state) => state, orElse: () => SyncState.idle);

  return SyncStatusState(
    syncState: syncState,
    isOnline: isOnline,
    pendingCount: syncService.pendingCount + syncService.unsyncedFeedingCount,
    lastSyncTime: syncService.lastSyncTime,
  );
});
