import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/repositories/push_repository_impl.dart';
import 'package:fishfeed/domain/repositories/push_repository.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/services/notifications/fcm_service.dart';

/// Manages push notification token lifecycle.
///
/// Coordinates between:
/// - [FcmService] for FCM token management
/// - [PushRepository] for backend token registration
/// - [AuthNotifier] for authentication state changes
///
/// Automatically registers token after login and unregisters on logout.
/// Listens for token refresh events and re-registers when needed.
class PushTokenManager {
  PushTokenManager({
    required PushRepository pushRepository,
    FcmService? fcmService,
  })  : _pushRepository = pushRepository,
        _fcmService = fcmService ?? FcmService.instance;

  final PushRepository _pushRepository;
  final FcmService _fcmService;

  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _isAuthenticated = false;

  /// Gets the current device platform string.
  String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Initializes the push token manager.
  ///
  /// Call this after app startup and auth initialization.
  /// Sets up listeners for token refresh events.
  void initialize() {
    // Listen for token refresh events
    _tokenRefreshSubscription = _fcmService.tokenStream.listen(
      _onTokenRefresh,
      onError: (Object error) {
        if (kDebugMode) {
          print('PushTokenManager: Token stream error: $error');
        }
      },
    );

    if (kDebugMode) {
      print('PushTokenManager: Initialized');
    }
  }

  /// Handles authentication state change.
  ///
  /// Call this when user becomes authenticated or logs out.
  /// [isAuthenticated] should be true after login, false after logout.
  Future<void> onAuthStateChanged({required bool isAuthenticated}) async {
    final wasAuthenticated = _isAuthenticated;
    _isAuthenticated = isAuthenticated;

    if (isAuthenticated && !wasAuthenticated) {
      // User just logged in
      await _registerCurrentToken();
    } else if (!isAuthenticated && wasAuthenticated) {
      // User just logged out
      await _unregisterToken();
    }
  }

  /// Registers the current FCM token on the backend.
  ///
  /// Call this after successful login to ensure the user receives
  /// push notifications.
  Future<void> _registerCurrentToken() async {
    try {
      final token = await _fcmService.getToken();

      if (token == null) {
        if (kDebugMode) {
          print('PushTokenManager: No FCM token available');
        }
        return;
      }

      await _pushRepository.registerTokenWithRetry(
        token: token,
        platform: _platform,
      );

      if (kDebugMode) {
        print('PushTokenManager: Token registered after login');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PushTokenManager: Failed to register token: $e');
      }
    }
  }

  /// Unregisters the push token from the backend and deletes FCM token.
  ///
  /// Call this on logout to stop receiving push notifications.
  Future<void> _unregisterToken() async {
    try {
      // Unregister from backend first
      await _pushRepository.unregisterToken();

      // Delete FCM token to stop receiving any notifications
      await _fcmService.deleteToken();

      if (kDebugMode) {
        print('PushTokenManager: Token unregistered after logout');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PushTokenManager: Failed to unregister token: $e');
      }
    }
  }

  /// Handles FCM token refresh.
  ///
  /// Called when Firebase Messaging generates a new token.
  /// Re-registers the token on the backend if user is authenticated.
  void _onTokenRefresh(String newToken) {
    if (!_isAuthenticated) {
      if (kDebugMode) {
        print('PushTokenManager: Token refreshed but user not authenticated');
      }
      return;
    }

    if (kDebugMode) {
      print('PushTokenManager: Token refreshed, re-registering');
    }

    // Register new token with retry
    _pushRepository.registerTokenWithRetry(
      token: newToken,
      platform: _platform,
    );
  }

  /// Manually triggers token registration.
  ///
  /// Use this if you need to force token registration
  /// (e.g., after permission granted).
  Future<void> forceRegisterToken() async {
    if (!_isAuthenticated) {
      if (kDebugMode) {
        print('PushTokenManager: Cannot register token - not authenticated');
      }
      return;
    }

    await _registerCurrentToken();
  }

  /// Disposes of resources.
  ///
  /// Call this when the manager is no longer needed.
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}

/// Provider for [PushTokenManager].
///
/// Usage:
/// ```dart
/// final pushTokenManager = ref.watch(pushTokenManagerProvider);
/// pushTokenManager.onAuthStateChanged(isAuthenticated: true);
/// ```
final pushTokenManagerProvider = Provider<PushTokenManager>((ref) {
  final pushRepository = ref.watch(pushRepositoryProvider);
  final manager = PushTokenManager(pushRepository: pushRepository);

  // Initialize the manager
  manager.initialize();

  // Clean up on dispose
  ref.onDispose(manager.dispose);

  return manager;
});

/// Provider that automatically syncs push token with auth state.
///
/// This provider listens to auth state changes and automatically
/// registers/unregisters push tokens.
///
/// Usage in app initialization:
/// ```dart
/// // In your root widget or app initialization:
/// ref.listen(pushTokenAuthSyncProvider, (_, __) {});
/// ```
final pushTokenAuthSyncProvider = Provider<void>((ref) {
  final pushTokenManager = ref.watch(pushTokenManagerProvider);
  final authState = ref.watch(authNotifierProvider);

  // Sync push token with auth state
  pushTokenManager.onAuthStateChanged(
    isAuthenticated: authState.isAuthenticated,
  );
});
