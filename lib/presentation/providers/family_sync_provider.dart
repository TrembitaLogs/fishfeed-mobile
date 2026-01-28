import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/utils/snackbar_utils.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/services/sync/family_sync_service.dart';

/// State for family sync service.
class FamilySyncState {
  const FamilySyncState({
    this.isPolling = false,
    this.isOnline = true,
    this.activeAquariumId,
    this.lastFamilyFeeding,
    this.error,
  });

  /// Whether polling is currently active.
  final bool isPolling;

  /// Whether the device is online.
  final bool isOnline;

  /// The aquarium currently being synced.
  final String? activeAquariumId;

  /// The most recent feeding from a family member.
  final FeedingEvent? lastFamilyFeeding;

  /// Error message if any.
  final String? error;

  FamilySyncState copyWith({
    bool? isPolling,
    bool? isOnline,
    String? activeAquariumId,
    FeedingEvent? lastFamilyFeeding,
    String? error,
    bool clearError = false,
    bool clearAquarium = false,
  }) {
    return FamilySyncState(
      isPolling: isPolling ?? this.isPolling,
      isOnline: isOnline ?? this.isOnline,
      activeAquariumId: clearAquarium ? null : (activeAquariumId ?? this.activeAquariumId),
      lastFamilyFeeding: lastFamilyFeeding ?? this.lastFamilyFeeding,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for managing family sync state.
class FamilySyncNotifier extends StateNotifier<FamilySyncState> {
  FamilySyncNotifier({
    required Ref ref,
  })  : _ref = ref,
        super(const FamilySyncState());

  final Ref _ref;
  FamilySyncService? _syncService;

  /// Global key for accessing scaffold messenger.
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Initializes the sync service for the current user.
  void initialize() {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    _syncService = FamilySyncService(
      currentUserId: user.id,
      fetchRemoteFeedings: _fetchRemoteFeedings,
      onFamilyFeeding: _handleFamilyFeeding,
      showToast: _showToast,
    );

    _syncService!.initialize();

    // Listen to service's event stream
    _syncService!.familyFeedingEvents.listen((event) {
      state = state.copyWith(lastFamilyFeeding: event.event);
    });
  }

  /// Starts polling for a specific aquarium.
  void startPolling({required String aquariumId}) {
    if (_syncService == null) {
      initialize();
    }

    _syncService?.startPolling(aquariumId: aquariumId);
    state = state.copyWith(
      isPolling: true,
      activeAquariumId: aquariumId,
    );
  }

  /// Stops all polling.
  void stopPolling() {
    _syncService?.stopPolling();
    state = state.copyWith(
      isPolling: false,
      clearAquarium: true,
    );
  }

  /// Triggers an immediate sync.
  Future<void> syncNow() async {
    await _syncService?.syncNow();
  }

  /// Disposes the sync service.
  @override
  void dispose() {
    _syncService?.dispose();
    super.dispose();
  }

  // ============ Callbacks ============

  Future<List<FeedingEvent>> _fetchRemoteFeedings({
    required String aquariumId,
    required DateTime since,
  }) async {
    // TODO: Implement actual API call when backend is ready
    // For now, return empty list (mock)
    //
    // In production:
    // final result = await _ref.read(feedingRepositoryProvider)
    //     .getFeedingsForAquarium(aquariumId, since: since);
    // return result.fold((f) => throw f, (events) => events);
    return [];
  }

  Future<void> _handleFamilyFeeding(FeedingEvent event) async {
    // Refresh today's feedings to reflect the new feeding
    await _ref.read(todayFeedingsProvider.notifier).refresh();
  }

  void _showToast(String message) {
    // Use scaffold messenger key if available
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// Provider for family sync notifier.
final familySyncProvider =
    StateNotifierProvider<FamilySyncNotifier, FamilySyncState>((ref) {
  return FamilySyncNotifier(ref: ref);
});

/// Provider for checking if family sync is active.
final isFamilySyncActiveProvider = Provider<bool>((ref) {
  return ref.watch(familySyncProvider).isPolling;
});

/// Provider for the last family feeding event.
final lastFamilyFeedingProvider = Provider<FeedingEvent?>((ref) {
  return ref.watch(familySyncProvider).lastFamilyFeeding;
});

/// Widget wrapper that shows family feeding toasts.
///
/// Wrap your MaterialApp with this to enable family feeding toasts.
///
/// Example:
/// ```dart
/// MaterialApp(
///   scaffoldMessengerKey: FamilySyncNotifier.scaffoldMessengerKey,
///   // ...
/// )
/// ```
class FamilySyncToastWrapper extends ConsumerStatefulWidget {
  const FamilySyncToastWrapper({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  ConsumerState<FamilySyncToastWrapper> createState() =>
      _FamilySyncToastWrapperState();
}

class _FamilySyncToastWrapperState extends ConsumerState<FamilySyncToastWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize family sync after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familySyncProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for family feedings and show toast
    ref.listen<FeedingEvent?>(lastFamilyFeedingProvider, (previous, next) {
      if (next != null && previous?.id != next.id) {
        final userName = next.completedByName ?? 'Family member';
        SnackbarUtils.showSuccess(
          context,
          'Feeding completed: $userName',
        );
      }
    });

    return widget.child;
  }
}
