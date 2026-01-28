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
import 'package:fishfeed/presentation/providers/sync_refresh_provider.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/providers/calendar_data_provider.dart';
import 'package:fishfeed/presentation/providers/statistics_provider.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize router once we have access to ref
    _authListenable ??= ref.read(authListenableProvider);
    _router = AppRouter.createRouter(_authListenable!);

    // Initialize auth state from local storage
    Future.microtask(() {
      ref.read(authNotifierProvider.notifier).initialize();
    });
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
          debugPrint(
            'Lifecycle event: ${event.event} - may need streak refresh',
          );
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

    return ConflictResolutionListener(child: widget.child);
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
