import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/core/services/session_expired_notifier.dart';
import 'package:fishfeed/core/di/repository_providers.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/repositories/aquarium_repository.dart';
import 'package:fishfeed/domain/repositories/auth_repository.dart';
import 'package:fishfeed/domain/usecases/login_usecase.dart';
import 'package:fishfeed/domain/usecases/logout_usecase.dart';
import 'package:fishfeed/domain/usecases/oauth_login_usecase.dart';
import 'package:fishfeed/domain/usecases/register_usecase.dart';
import 'package:fishfeed/services/auth/apple_auth_service.dart';
import 'package:fishfeed/services/auth/google_auth_service.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

/// Authentication state for the application.
///
/// Represents the current authentication status including
/// user data, loading state, and any errors.
class AuthenticationState {
  const AuthenticationState({
    this.user,
    this.isLoading = false,
    this.isInitializing = false,
    this.error,
    this.isAuthenticated = false,
    this.hasCompletedOnboarding = false,
  });

  /// Creates initial unauthenticated state.
  ///
  /// [isInitializing] is true because we haven't checked local storage yet.
  const AuthenticationState.initial()
    : user = null,
      isLoading = false,
      isInitializing = true,
      error = null,
      isAuthenticated = false,
      hasCompletedOnboarding = false;

  /// Creates loading state.
  const AuthenticationState.loading()
    : user = null,
      isLoading = true,
      isInitializing = false,
      error = null,
      isAuthenticated = false,
      hasCompletedOnboarding = false;

  /// Creates authenticated state with user.
  factory AuthenticationState.authenticated(
    User user, {
    bool hasCompletedOnboarding = false,
  }) {
    return AuthenticationState(
      user: user,
      isLoading: false,
      isInitializing: false,
      error: null,
      isAuthenticated: true,
      hasCompletedOnboarding: hasCompletedOnboarding,
    );
  }

  /// Creates error state.
  factory AuthenticationState.error(Failure failure) {
    return AuthenticationState(
      user: null,
      isLoading: false,
      isInitializing: false,
      error: failure,
      isAuthenticated: false,
      hasCompletedOnboarding: false,
    );
  }

  /// Current authenticated user.
  final User? user;

  /// Whether an auth operation is in progress.
  final bool isLoading;

  /// Whether auth state is being initialized from local storage.
  ///
  /// True on app startup until [initialize] completes.
  /// Used to show splash screen instead of login flash.
  final bool isInitializing;

  /// Current auth error, if any.
  final Failure? error;

  /// Whether user is authenticated.
  final bool isAuthenticated;

  /// Whether user has completed onboarding.
  final bool hasCompletedOnboarding;

  /// Creates a copy with updated fields.
  AuthenticationState copyWith({
    User? user,
    bool? isLoading,
    bool? isInitializing,
    Failure? error,
    bool? isAuthenticated,
    bool? hasCompletedOnboarding,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthenticationState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: clearError ? null : (error ?? this.error),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthenticationState &&
        other.user == user &&
        other.isLoading == isLoading &&
        other.isInitializing == isInitializing &&
        other.error == error &&
        other.isAuthenticated == isAuthenticated &&
        other.hasCompletedOnboarding == hasCompletedOnboarding;
  }

  @override
  int get hashCode => Object.hash(
    user,
    isLoading,
    isInitializing,
    error,
    isAuthenticated,
    hasCompletedOnboarding,
  );
}

/// Notifier for managing authentication state.
///
/// Provides methods for login, registration, OAuth, and logout.
/// Updates state reactively through Riverpod.
class AuthNotifier extends StateNotifier<AuthenticationState> {
  AuthNotifier({
    required AuthRepository repository,
    required GoogleAuthService googleAuthService,
    required AppleAuthService appleAuthService,
    required AquariumRepository aquariumRepository,
    required SyncService syncService,
  }) : _repository = repository,
       _googleAuthService = googleAuthService,
       _appleAuthService = appleAuthService,
       _aquariumRepository = aquariumRepository,
       _syncService = syncService,
       _loginUseCase = LoginUseCase(repository),
       _registerUseCase = RegisterUseCase(repository),
       _oauthLoginUseCase = OAuthLoginUseCase(repository),
       _logoutUseCase = LogoutUseCase(repository),
       super(const AuthenticationState.initial()) {
    // Set up callback to update auth state when user profile is synced from server
    _syncService.onUserProfileUpdated = (user) {
      updateUser(user);
    };
  }

  final AuthRepository _repository;
  final GoogleAuthService _googleAuthService;
  final AppleAuthService _appleAuthService;
  final AquariumRepository _aquariumRepository;
  final SyncService _syncService;
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final OAuthLoginUseCase _oauthLoginUseCase;
  final LogoutUseCase _logoutUseCase;

  /// Callback triggered on logout for external cleanup (e.g., router redirect).
  VoidCallback? onLogout;

  bool _isInitializing = false;

  /// Initializes auth state from local storage.
  ///
  /// Call this on app startup to restore session.
  /// Sets [isInitializing] to false when complete.
  /// Guarded against re-entrant calls and wrapped in try-catch
  /// to ensure splash screen never hangs on unexpected errors
  /// (e.g., corrupted secure storage after Android auto-backup restore).
  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final isAuthenticated = await _repository.isAuthenticated();

      if (!isAuthenticated) {
        // Not authenticated - set initial state with isInitializing = false
        state = const AuthenticationState(
          isInitializing: false,
          isAuthenticated: false,
        );
        return;
      }

      final userResult = await _repository.getCurrentUser();
      await userResult.fold(
        (failure) async {
          // Failed to get user - not authenticated, initialization complete
          state = const AuthenticationState(
            isInitializing: false,
            isAuthenticated: false,
          );
        },
        (user) async {
          var hasCompletedOnboarding = _repository.getOnboardingCompleted();
          debugPrint('[AuthNotifier] Initialize: restored user ${user.email}');
          debugPrint(
            '[AuthNotifier] Initialize: Hive flag=$hasCompletedOnboarding',
          );

          if (!hasCompletedOnboarding) {
            hasCompletedOnboarding = await _syncAndCheckOnboarding(user.id);

            // _syncAndCheckOnboarding makes API calls that may trigger a 401.
            // If token refresh failed, the interceptor cleared tokens from
            // SecureStorage. Re-check before setting authenticated state to
            // avoid a stale session (authenticated UI but no valid tokens).
            final stillAuthenticated = await _repository.isAuthenticated();
            if (!stillAuthenticated) {
              state = const AuthenticationState(
                isInitializing: false,
                isAuthenticated: false,
              );
              return;
            }
          }

          state = AuthenticationState.authenticated(
            user,
            hasCompletedOnboarding: hasCompletedOnboarding,
          );

          // If onboarding was already completed, still trigger background sync
          if (hasCompletedOnboarding) {
            debugPrint(
              '[AuthNotifier] Triggering background sync after session restore',
            );
            unawaited(
              _syncService.syncAll().then((_) {
                // Re-read user from local storage after sync to pick up server changes
                final updatedUser = _repository.getLocalUser();
                if (updatedUser != null && updatedUser != state.user) {
                  updateUser(updatedUser);
                }
              }),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('[AuthNotifier] Initialize failed with error: $e');
      state = const AuthenticationState(
        isInitializing: false,
        isAuthenticated: false,
      );
    } finally {
      _isInitializing = false;
    }
  }

  /// Login with email and password.
  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _loginUseCase(
      LoginParams(email: email, password: password),
    );

    await result.fold(
      (failure) async {
        state = state.copyWith(isLoading: false, error: failure);
      },
      (user) async {
        // Save user locally before sync so profile updates can be applied
        await _repository.saveUserLocally(user);

        var hasCompletedOnboarding = _repository.getOnboardingCompleted();
        debugPrint('[AuthNotifier] Login success for ${user.email}');
        debugPrint(
          '[AuthNotifier] Local Hive onboarding flag: $hasCompletedOnboarding',
        );

        if (!hasCompletedOnboarding) {
          hasCompletedOnboarding = await _syncAndCheckOnboarding(user.id);
        }

        // Re-read user from local storage after sync (may have nickname from server)
        final syncedUser = _repository.getLocalUser() ?? user;

        debugPrint(
          '[AuthNotifier] Setting state with hasCompletedOnboarding=$hasCompletedOnboarding',
        );
        state = AuthenticationState.authenticated(
          syncedUser,
          hasCompletedOnboarding: hasCompletedOnboarding,
        );

        // If onboarding was already completed, still trigger background sync
        if (hasCompletedOnboarding) {
          debugPrint('[AuthNotifier] Triggering background sync after login');
          unawaited(_syncService.syncAll());
        }
      },
    );
  }

  /// Register with email and password.
  Future<void> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _registerUseCase(
      RegisterParams(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      ),
    );

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure);
      },
      (user) {
        state = AuthenticationState.authenticated(user);
      },
    );
  }

  /// Login with Google OAuth.
  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final googleResult = await _googleAuthService.signIn();

      final result = await _oauthLoginUseCase(
        OAuthLoginParams(
          provider: OAuthProvider.google,
          idToken: googleResult.idToken,
        ),
      );

      await result.fold(
        (failure) async {
          state = state.copyWith(isLoading: false, error: failure);
        },
        (user) async {
          await _repository.saveUserLocally(user);

          var hasCompletedOnboarding = _repository.getOnboardingCompleted();
          debugPrint('[AuthNotifier] Google login success for ${user.email}');

          if (!hasCompletedOnboarding) {
            hasCompletedOnboarding = await _syncAndCheckOnboarding(user.id);
          }

          final syncedUser = _repository.getLocalUser() ?? user;

          state = AuthenticationState.authenticated(
            syncedUser,
            hasCompletedOnboarding: hasCompletedOnboarding,
          );

          if (hasCompletedOnboarding) {
            debugPrint(
              '[AuthNotifier] Triggering background sync after Google login',
            );
            unawaited(_syncService.syncAll());
          }
        },
      );
    } on GoogleAuthException catch (e) {
      final failure = switch (e.code) {
        GoogleAuthErrorCode.cancelled => const CancellationFailure(),
        GoogleAuthErrorCode.networkError => const NetworkFailure(),
        _ => OAuthFailure(message: e.message, provider: 'google'),
      };
      state = state.copyWith(isLoading: false, error: failure);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: const OAuthFailure(provider: 'google'),
      );
    }
  }

  /// Login with Apple OAuth.
  Future<void> loginWithApple() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final appleResult = await _appleAuthService.signIn();

      final result = await _oauthLoginUseCase(
        OAuthLoginParams(
          provider: OAuthProvider.apple,
          idToken: appleResult.identityToken,
        ),
      );

      await result.fold(
        (failure) async {
          state = state.copyWith(isLoading: false, error: failure);
        },
        (user) async {
          await _repository.saveUserLocally(user);

          var hasCompletedOnboarding = _repository.getOnboardingCompleted();
          debugPrint('[AuthNotifier] Apple login success for ${user.email}');

          if (!hasCompletedOnboarding) {
            hasCompletedOnboarding = await _syncAndCheckOnboarding(user.id);
          }

          final syncedUser = _repository.getLocalUser() ?? user;

          state = AuthenticationState.authenticated(
            syncedUser,
            hasCompletedOnboarding: hasCompletedOnboarding,
          );

          if (hasCompletedOnboarding) {
            debugPrint(
              '[AuthNotifier] Triggering background sync after Apple login',
            );
            unawaited(_syncService.syncAll());
          }
        },
      );
    } on AppleAuthException catch (e) {
      final failure = switch (e.code) {
        AppleAuthErrorCode.cancelled => const CancellationFailure(),
        AppleAuthErrorCode.notAvailable => const OAuthFailure(
          message: 'Apple Sign-In not available',
          provider: 'apple',
        ),
        _ => OAuthFailure(message: e.message, provider: 'apple'),
      };
      state = state.copyWith(isLoading: false, error: failure);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: const OAuthFailure(provider: 'apple'),
      );
    }
  }

  /// Handles forced session expiry (both tokens expired).
  ///
  /// Called by [TokenRefreshInterceptor] when refresh token is rejected.
  /// Unlike [logout], this skips OAuth sign-out and use case cleanup
  /// because tokens are already cleared by the interceptor.
  ///
  /// During initialization ([isInitializing] is true), the call is ignored
  /// to prevent a brief login screen flash on app startup. The interceptor
  /// has already cleared the tokens from SecureStorage, so [initialize]
  /// will detect the missing tokens via [_repository.isAuthenticated] and
  /// transition to unauthenticated state cleanly (splash → login, no flash).
  void handleSessionExpired() {
    if (state.isInitializing) return;
    state = const AuthenticationState(
      isInitializing: false,
      isAuthenticated: false,
    );
  }

  /// Logout the current user.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);

    // Sign out from OAuth providers
    await _googleAuthService.signOut();
    _appleAuthService.signOut();

    await _logoutUseCase();

    state = const AuthenticationState(
      isInitializing: false,
      isAuthenticated: false,
    );

    // Notify external listeners (e.g., router)
    onLogout?.call();
  }

  /// Mark onboarding as completed.
  Future<void> completeOnboarding() async {
    await _repository.setOnboardingCompleted(true);
    state = state.copyWith(hasCompletedOnboarding: true);
  }

  /// Clear any authentication errors.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Updates the current user in the authentication state.
  ///
  /// Used when user data changes (e.g., after AI scan decrement).
  /// Does nothing if no user is currently authenticated.
  void updateUser(User updatedUser) {
    if (!state.isAuthenticated || state.user == null) return;

    state = state.copyWith(user: updatedUser);
  }

  /// Updates the avatar key in the authentication state.
  ///
  /// Called by [createPhotoKeyUpdater] after a successful avatar upload
  /// to replace the `local://` key with the actual S3 key, so the UI
  /// immediately switches from showing the local file to the S3 image.
  void updateAvatarKey(String avatarKey) {
    final currentUser = state.user;
    if (currentUser == null) return;

    state = state.copyWith(user: currentUser.copyWith(avatarKey: avatarKey));
  }

  /// Syncs with server and checks if user has aquariums for onboarding.
  ///
  /// Returns true if onboarding should be marked as completed.
  Future<bool> _syncAndCheckOnboarding(String userId) async {
    try {
      debugPrint('[AuthNotifier] Syncing to check onboarding status...');
      await _syncService.syncAll();

      final hasAquariums = _checkLocalAquariums();

      if (hasAquariums) {
        await _repository.setOnboardingCompleted(true);
        return true;
      }
    } catch (e) {
      debugPrint('[AuthNotifier] Sync failed during onboarding check: $e');

      // Fallback: check local data even without sync
      final hasAquariums = _checkLocalAquariums();
      if (hasAquariums) {
        await _repository.setOnboardingCompleted(true);
        return true;
      }
    }
    return false;
  }

  /// Checks if user has any active aquariums in local cache.
  bool _checkLocalAquariums() {
    final result = _aquariumRepository.getCachedAquariums();
    return result.fold(
      (_) => false,
      (aquariums) {
        debugPrint(
          '[AuthNotifier] Local aquariums: ${aquariums.length}',
        );
        return aquariums.isNotEmpty;
      },
    );
  }
}

/// Provider for [AuthNotifier].
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthenticationState>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      final googleAuthService = ref.watch(googleAuthServiceProvider);
      final appleAuthService = ref.watch(appleAuthServiceProvider);
      final aquariumRepository = ref.watch(aquariumRepositoryProvider);
      final syncService = ref.watch(syncServiceProvider);

      return AuthNotifier(
        repository: repository,
        googleAuthService: googleAuthService,
        appleAuthService: appleAuthService,
        aquariumRepository: aquariumRepository,
        syncService: syncService,
      );
    });

/// Provider for current authentication state.
///
/// Convenience provider for accessing just the state.
final authStateProvider = Provider<AuthenticationState>((ref) {
  return ref.watch(authNotifierProvider);
});

/// Provider for current user.
///
/// Returns null if not authenticated.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authNotifierProvider.select((s) => s.user));
});

/// Provider for authentication status.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider.select((s) => s.isAuthenticated));
});

/// Listenable adapter for GoRouter integration.
///
/// Bridges Riverpod state to Flutter's Listenable interface
/// required by GoRouter's refreshListenable.
class AuthStateListenable extends ChangeNotifier {
  AuthStateListenable(this._ref) {
    _authSubscription = _ref.listen(authNotifierProvider, (previous, next) {
      // Notify GoRouter of state changes
      notifyListeners();
    });

    _sessionExpiredSubscription = _ref.listen(sessionExpiredProvider, (
      previous,
      next,
    ) {
      if (next) {
        // Both tokens expired — force logout and redirect to login
        _ref.read(authNotifierProvider.notifier).handleSessionExpired();
        // Reset the signal so it can fire again in future sessions
        _ref.read(sessionExpiredProvider.notifier).state = false;
      }
    });
  }

  final Ref _ref;
  ProviderSubscription<AuthenticationState>? _authSubscription;
  ProviderSubscription<bool>? _sessionExpiredSubscription;

  /// Whether auth state is still being initialized.
  bool get isInitializing => _ref.read(authNotifierProvider).isInitializing;

  /// Whether user is logged in.
  bool get isLoggedIn => _ref.read(authNotifierProvider).isAuthenticated;

  /// Whether user has completed onboarding.
  bool get hasCompletedOnboarding =>
      _ref.read(authNotifierProvider).hasCompletedOnboarding;

  @override
  void dispose() {
    _authSubscription?.close();
    _sessionExpiredSubscription?.close();
    super.dispose();
  }
}

/// Provider for GoRouter-compatible auth listenable.
final authListenableProvider = Provider<AuthStateListenable>((ref) {
  final listenable = AuthStateListenable(ref);
  ref.onDispose(listenable.dispose);
  return listenable;
});
