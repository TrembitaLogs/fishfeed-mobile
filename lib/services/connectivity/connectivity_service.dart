import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for monitoring network connectivity status.
///
/// Provides a stream of connectivity changes and methods to check
/// current connectivity state. Used for displaying offline banners
/// and managing offline-aware features.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final _statusController = StreamController<bool>.broadcast();
  bool _isOnline = true;
  bool _isInitialized = false;

  /// Stream of connectivity status changes.
  ///
  /// Emits `true` when online, `false` when offline.
  Stream<bool> get statusStream => _statusController.stream;

  /// Current connectivity status.
  ///
  /// Returns `true` if online, `false` if offline.
  bool get isOnline => _isOnline;

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes the service and starts listening for connectivity changes.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (Object error) {
        debugPrint('ConnectivityService: Error listening to changes: $error');
      },
    );

    _isInitialized = true;
    debugPrint('ConnectivityService: Initialized, online: $_isOnline');
  }

  /// Stops listening for connectivity changes and disposes resources.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _statusController.close();
    _isInitialized = false;
  }

  /// Manually checks the current connectivity status.
  ///
  /// Useful for refreshing status on demand.
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
    return _isOnline;
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _updateStatus(results);

    if (wasOnline != _isOnline) {
      debugPrint(
        'ConnectivityService: Status changed to ${_isOnline ? "online" : "offline"}',
      );
      _statusController.add(_isOnline);
    }
  }

  void _updateStatus(List<ConnectivityResult> results) {
    _isOnline =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }
}

/// Provider for the connectivity service.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for the current connectivity status.
///
/// Returns `true` when online, `false` when offline.
/// Automatically updates when connectivity changes.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);

  // Initialize the service if not already done
  await service.initialize();

  // Emit initial status
  yield service.isOnline;

  // Listen for changes
  await for (final isOnline in service.statusStream) {
    yield isOnline;
  }
});

/// Provider that returns `true` when the device is offline.
///
/// Useful for showing offline banners.
final isOfflineProvider = Provider<bool>((ref) {
  final asyncValue = ref.watch(isOnlineProvider);
  return asyncValue.maybeWhen(
    data: (isOnline) => !isOnline,
    orElse: () => false,
  );
});
