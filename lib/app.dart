import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/core/utils/utils.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/settings_provider.dart';
import 'package:fishfeed/presentation/router/app_router.dart';
import 'package:fishfeed/presentation/dialogs/conflict_resolution_dialog.dart';
import 'package:fishfeed/presentation/widgets/common/offline_banner.dart';
import 'package:fishfeed/services/connectivity/connectivity_service.dart';
import 'package:fishfeed/services/lifecycle/app_lifecycle_service.dart';
import 'package:fishfeed/services/push/push_token_manager.dart';
import 'package:fishfeed/services/sentry/sentry_user_sync.dart';
import 'package:fishfeed/services/sync/sync_trigger_service.dart';
import 'package:fishfeed/services/sync/sync_service.dart';
import 'package:fishfeed/presentation/providers/image_upload_provider.dart';
import 'package:fishfeed/presentation/providers/sync_refresh_provider.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/providers/calendar_data_provider.dart';
import 'package:fishfeed/presentation/providers/statistics_provider.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/services/notifications/notification_action_handler.dart';
import 'package:fishfeed/services/notifications/notification_service.dart';

/// Provider for toggling performance overlay in debug builds.
///
/// Set to true to show Flutter's performance overlay for profiling.
/// Only has effect in debug mode.
final showPerformanceOverlayProvider = StateProvider<bool>((ref) => false);

/// The main application widget.
///
/// Uses MaterialApp.router for declarative navigation with GoRouter.
/// Supports automatic light/dark theme switching based on system settings.
/// Must be wrapped in ProviderScope for Riverpod state management.
class FishFeedApp extends ConsumerStatefulWidget {
  const FishFeedApp({super.key});

  @override
  ConsumerState<FishFeedApp> createState() => _FishFeedAppState();
}

class _FishFeedAppState extends ConsumerState<FishFeedApp> {
  late final GoRouter _router;
  AuthStateListenable? _authListenable;
  StreamSubscription<Uri>? _deepLinkSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize router once we have access to ref
    if (_authListenable == null) {
      _authListenable = ref.read(authListenableProvider);
      _router = AppRouter.createRouter(_authListenable!);
      _initDeepLinks();
    }

    // Initialize auth state from local storage
    Future.microtask(() {
      ref.read(authNotifierProvider.notifier).initialize();
    });
  }

  void _initDeepLinks() {
    final appLinks = AppLinks();

    // Handle deep links while app is running (warm start / foreground)
    _deepLinkSub = appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Handle initial deep link (cold start)
    appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    final path = uri.path;
    if (path.startsWith('/join/') && path.length > 6) {
      _router.go(path);
    }
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showPerformanceOverlay = ref.watch(showPerformanceOverlayProvider);
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(languageProvider);

    return MaterialApp.router(
      title: 'FishFeed',
      debugShowCheckedModeBanner: false,

      // Performance overlay for debug builds
      showPerformanceOverlay: kDebugMode && showPerformanceOverlay,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Router configuration
      routerConfig: _router,

      // Localization configuration
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(language),

      // Global error listener wrapper with text scale clamping
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final clampedTextScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.8,
          maxScaleFactor: 1.0,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedTextScaler),
          child: _GlobalAuthErrorListener(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// Widget that listens to auth errors globally and shows snackbars.
///
/// Must be a descendant of [MaterialApp] to access [ScaffoldMessenger].
class _GlobalAuthErrorListener extends ConsumerWidget {
  const _GlobalAuthErrorListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthenticationState>(authNotifierProvider, (previous, next) {
      // Show error snackbar when an error occurs
      if (next.error != null && previous?.error != next.error) {
        context.showAuthError(next.error!);
      }
    });

    return _PushTokenSyncListener(child: child);
  }
}

/// Widget that syncs push notification token with auth state.
///
/// Automatically registers push token after login and
/// unregisters on logout.
class _PushTokenSyncListener extends ConsumerWidget {
  const _PushTokenSyncListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger the sync provider which listens to auth state changes
    ref.watch(pushTokenAuthSyncProvider);

    return _SentryUserSyncListener(child: child);
  }
}

/// Widget that syncs user context with Sentry.
///
/// Automatically sets user context on login and clears on logout.
class _SentryUserSyncListener extends ConsumerWidget {
  const _SentryUserSyncListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger the sync provider which listens to auth state changes
    ref.watch(sentryUserSyncProvider);

    return _ConnectivityListener(child: child);
  }
}

/// Widget that initializes connectivity monitoring.
///
/// Wraps the app with [OfflineBannerWrapper] to show offline status.
class _ConnectivityListener extends ConsumerWidget {
  const _ConnectivityListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize connectivity service by watching the provider
    ref.watch(isOnlineProvider);

    return _LifecycleListener(child: OfflineBannerWrapper(child: child));
  }
}

/// Widget that initializes app lifecycle monitoring.
///
/// Handles edge cases like midnight crossing, DST transitions,
/// and app resume after long background periods.
class _LifecycleListener extends ConsumerWidget {
  const _LifecycleListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize lifecycle service and listen for events
    ref.watch(appLifecycleServiceProvider);

    // Listen for lifecycle events to trigger streak recalculation
    ref.listen(lifecycleEventsProvider, (previous, next) {
      next.whenData((event) {
        if (event.event == AppLifecycleEvent.midnightCrossed ||
            event.event == AppLifecycleEvent.dstTransition) {
          // Trigger UI refresh for streak-related components
        }
      });
    });

    return _SyncTriggerListener(child: child);
  }
}

/// Widget that initializes sync trigger service.
///
/// Automatically triggers sync on:
/// - App resume (with 5 second debounce)
/// - Connectivity restored (offline -> online)
///
/// Includes cooldown period (30 seconds) to prevent excessive syncing.
class _SyncTriggerListener extends ConsumerWidget {
  const _SyncTriggerListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize sync trigger service by watching the provider
    // This activates automatic sync triggers based on lifecycle/connectivity
    ref.watch(syncTriggerServiceProvider);

    return _ImageUploadTriggerListener(child: child);
  }
}

/// Widget that initializes image upload queue processing.
///
/// Watches [imageUploadNotifierProvider] to activate:
/// - Queue initialization and crash recovery on startup
/// - Automatic upload processing when connectivity restores
class _ImageUploadTriggerListener extends ConsumerWidget {
  const _ImageUploadTriggerListener({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize image upload notifier by watching the provider.
    // This activates connectivity-triggered queue processing.
    ref.watch(imageUploadNotifierProvider);

    return _SyncCompletionRefreshListener(child: child);
  }
}

/// Widget that refreshes UI providers when sync completes.
///
/// Listens to sync state changes and invalidates sync-dependent providers
/// when sync transitions to idle state after being active.
class _SyncCompletionRefreshListener extends ConsumerStatefulWidget {
  const _SyncCompletionRefreshListener({required this.child});

  final Widget child;

  @override
  ConsumerState<_SyncCompletionRefreshListener> createState() =>
      _SyncCompletionRefreshListenerState();
}

class _SyncCompletionRefreshListenerState
    extends ConsumerState<_SyncCompletionRefreshListener> {
  bool _wasSyncing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<SyncState>>(syncStateProvider, (previous, next) {
      next.whenData((state) {
        final isSyncing = state == SyncState.syncing;

        // Detect transition from syncing to idle (sync completed)
        if (_wasSyncing && !isSyncing) {
          _refreshAfterSync();
        }

        _wasSyncing = isSyncing;
      });
    });

    return _NotificationActionListener(
      child: ConflictResolutionListener(child: widget.child),
    );
  }

  /// Refreshes all sync-dependent providers after sync completion.
  ///
  /// Uses refresh() instead of invalidate() to ensure data is reloaded
  /// immediately, regardless of widget rebuild timing.
  void _refreshAfterSync() {
    // Use refresh() for StateNotifierProviders to force immediate reload
    ref.read(todayFeedingsProvider.notifier).refresh();
    ref.read(currentStreakProvider.notifier).refresh();
    // Use invalidate() for regular providers (they will reload on next watch)
    ref.invalidate(calendarDataProvider);
    ref.invalidate(statisticsProvider);
    ref.read(syncRefreshProvider.notifier).state++;
  }
}

/// Widget that handles notification "Fed" button actions.
///
/// Instead of marking feedings directly, navigates to the feeding screen
/// with the `autoFed` parameter so the standard confirmation dialog is shown.
/// Pending background actions stored in [NotificationActionStorage] are
/// processed on app resume.
class _NotificationActionListener extends ConsumerStatefulWidget {
  const _NotificationActionListener({required this.child});

  final Widget child;

  @override
  ConsumerState<_NotificationActionListener> createState() =>
      _NotificationActionListenerState();
}

class _NotificationActionListenerState
    extends ConsumerState<_NotificationActionListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set up foreground action callback
    NotificationService.instance.onActionReceived = _handleAction;

    // Process any pending background actions
    _processPendingActions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (NotificationService.instance.onActionReceived == _handleAction) {
      NotificationService.instance.onActionReceived = null;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _processPendingActions();
    }
  }

  void _handleAction(String actionId, String? payload) {
    if (actionId != NotificationActionIds.fed || payload == null) {
      return;
    }
    _navigateToFeedingScreen(payload);
  }

  /// Resolves schedule and aquarium from payload, then navigates
  /// to the feeding screen with `autoFed` query parameter.
  void _navigateToFeedingScreen(String payload) {
    String? scheduleId;

    // Try schedule-based payload: "schedule_{scheduleId}_{timestampMs}"
    final schedulePayload = parseSchedulePayload(payload);
    if (schedulePayload != null) {
      scheduleId = schedulePayload.scheduleId;
    } else {
      // Try daily payload: "feeding_daily_{HH}_{mm}"
      final dailyPayload = parseDailyPayload(payload);
      if (dailyPayload != null) {
        final now = DateTime.now();
        final timeStr =
            '${dailyPayload.hour.toString().padLeft(2, '0')}:'
            '${dailyPayload.minute.toString().padLeft(2, '0')}';

        final scheduleDs = ref.read(scheduleLocalDataSourceProvider);
        final matching = scheduleDs.getAll().where((s) {
          return s.active && s.shouldFeedOn(now) && s.time == timeStr;
        }).toList();

        if (matching.isNotEmpty) {
          scheduleId = matching.first.id;
        }
      }
    }

    if (scheduleId == null) {
      if (kDebugMode) {
        debugPrint(
          'NotificationActionListener: no schedule for payload: $payload',
        );
      }
      return;
    }

    // Look up the schedule to get aquariumId
    final scheduleDs = ref.read(scheduleLocalDataSourceProvider);
    final schedule = scheduleDs
        .getAll()
        .where((s) => s.id == scheduleId)
        .firstOrNull;

    if (schedule == null) {
      if (kDebugMode) {
        debugPrint(
          'NotificationActionListener: schedule $scheduleId not found',
        );
      }
      return;
    }

    final aquariumId = schedule.aquariumId;

    if (!mounted) return;
    AppRouter.router.push('/aquarium/$aquariumId/feedings?autoFed=$scheduleId');
  }

  Future<void> _processPendingActions() async {
    final pendingActions =
        await NotificationActionStorage.getAndClearPendingActions();

    if (pendingActions.isEmpty) return;

    // Wait for the current frame to finish so GoRouter is ready
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Only process the most recent "fed" action within 30 minutes
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(minutes: 30));

    PendingNotificationAction? latestFedAction;
    for (final action in pendingActions) {
      if (action.actionId == NotificationActionIds.fed &&
          action.timestamp.isAfter(cutoff)) {
        if (latestFedAction == null ||
            action.timestamp.isAfter(latestFedAction.timestamp)) {
          latestFedAction = action;
        }
      } else if (action.actionId != NotificationActionIds.fed) {
        // Handle snooze and other actions via NotificationService
        NotificationService.instance.handleNotificationAction(
          action.actionId,
          action.payload,
        );
      }
    }

    if (latestFedAction != null && mounted) {
      _navigateToFeedingScreen(latestFedAction.payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
