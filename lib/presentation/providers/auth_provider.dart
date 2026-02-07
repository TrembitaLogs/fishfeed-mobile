import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/repositories/auth_repository_impl.dart';
import 'package:fishfeed/domain/entities/user.dart';
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
    required AquariumLocalDataSource aquariumLocalDataSource,
    required SyncService syncService,
  }) : _repository = repository,
       _googleAuthService = googleAuthService,
       _appleAuthService = appleAuthService,
       _aquariumLocalDataSource = aquariumLocalDataSource,
       _syncService = syncService,
       _loginUseCase = LoginUseCase(repository),
       _registerUseCase = RegisterUseCase(repository),
       _oauthLoginUseCase = OAuthLoginUseCase(repository),
       _logoutUseCase = LogoutUseCase(repository),
       super(const AuthenticationState.initial());

  final AuthRepository _repository;
  final GoogleAuthService _googleAuthService;
  final AppleAuthService _appleAuthService;
  final AquariumLocalDataSource _aquariumLocalDataSource;
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
          var hasCompletedOnboarding = HiveBoxes.getOnboardingCompleted();
          debugPrint('[AuthNotifier] Initialize: restored user ${user.email}');
          debugPrint(
            '[AuthNotifier] Initialize: Hive flag=$hasCompletedOnboarding',
          );

          if (!hasCompletedOnboarding) {
            hasCompletedOnboarding = await _syncAndCheckOnboarding(user.id);
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
            unawaited(_syncService.syncAll());
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
        var hasCompletedOnboarding = HiveBoxes.getOnboardingCompleted();
        debugPrint('[AuthNotifier] Login success for ${user.email}');
        debugPrint(
          '[AuthNotifier] Local Hive onboarding flag: $hasCompletedOnboarding',
        );

        if (!hasCompletedOnboarding) {
          hasCompletedOnboarding = await _syncAndCheckOnboarding(user.id);
        }

        debugPrint(
          '[AuthNotifier] Setting state with hasCompletedOnboarding=$hasCompletedOnboarding',
        );
        state = AuthenticationState.authenticated(
          user,
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
          var hasCompletedOnboarding = HiveBoxes.getOnboardingCompleted();
          debugPrint('[AuthNotifier] Google login success for ${user.email}');

          if (!hasCompletedOnboarding) {
            hasCompletedOnboarding = await _syncAndCheckOnboarding(user.id);
          }

          state = AuthenticationState.authenticated(
            user,
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
          var hasCompletedOnboarding = HiveBoxes.getOnboardingCompleted();
          debugPrint('[AuthNotifier] Apple login success for ${user.email}');

          if (!hasCompletedOnboarding) {
            hasCompletedOnboarding = await _syncAndCheckOnboarding(user.id);
          }

          state = AuthenticationState.authenticated(
            user,
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

  /// Logout the current user.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);

    // Sign out from OAuth providers
    await _googleAuthService.signOut();
    _appleAuthService.signOut();

    await _logoutUseCase();

    state = const AuthenticationState.initial();

    // Notify external listeners (e.g., router)
    onLogout?.call();
  }

  /// Mark onboarding as completed.
  Future<void> completeOnboarding() async {
    await HiveBoxes.setOnboardingCompleted(true);
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

  /// Syncs with server and checks if user has aquariums for onboarding.
  ///
  /// Returns true if onboarding should be marked as completed.
  Future<bool> _syncAndCheckOnboarding(String userId) async {
    try {
      debugPrint('[AuthNotifier] Syncing to check onboarding status...');
      await _syncService.syncAll();

      final localAquariums = _aquariumLocalDataSource.getAquariumsByUserId(
        userId,
      );
      final hasAquariums = localAquariums.any((a) => !a.isDeleted);
      debugPrint(
        '[AuthNotifier] After sync: ${localAquariums.length} aquariums, '
        'active: $hasAquariums',
      );

      if (hasAquariums) {
        await HiveBoxes.setOnboardingCompleted(true);
        return true;
      }
    } catch (e) {
      debugPrint('[AuthNotifier] Sync failed during onboarding check: $e');

      // Fallback: check local data even without sync
      final localAquariums = _aquariumLocalDataSource.getAquariumsByUserId(
        userId,
      );
      final hasAquariums = localAquariums.any((a) => !a.isDeleted);
      if (hasAquariums) {
        await HiveBoxes.setOnboardingCompleted(true);
        return true;
      }
    }
    return false;
  }
}

/// Provider for [AuthNotifier].
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthenticationState>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      final googleAuthService = ref.watch(googleAuthServiceProvider);
      final appleAuthService = ref.watch(appleAuthServiceProvider);
      final aquariumLocalDataSource = ref.watch(
        aquariumLocalDataSourceProvider,
      );
      final syncService = ref.watch(syncServiceProvider);

      return AuthNotifier(
        repository: repository,
        googleAuthService: googleAuthService,
        appleAuthService: appleAuthService,
        aquariumLocalDataSource: aquariumLocalDataSource,
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
  return ref.watch(authNotifierProvider).user;
});

/// Provider for authentication status.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

/// Listenable adapter for GoRouter integration.
///
/// Bridges Riverpod state to Flutter's Listenable interface
/// required by GoRouter's refreshListenable.
class AuthStateListenable extends ChangeNotifier {
  AuthStateListenable(this._ref) {
    _subscription = _ref.listen(authNotifierProvider, (previous, next) {
      // Notify GoRouter of state changes
      notifyListeners();
    });
  }

  final Ref _ref;
  ProviderSubscription<AuthenticationState>? _subscription;

  /// Whether auth state is still being initialized.
  bool get isInitializing => _ref.read(authNotifierProvider).isInitializing;

  /// Whether user is logged in.
  bool get isLoggedIn => _ref.read(authNotifierProvider).isAuthenticated;

  /// Whether user has completed onboarding.
  bool get hasCompletedOnboarding =>
      _ref.read(authNotifierProvider).hasCompletedOnboarding;

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }
}

/// Provider for GoRouter-compatible auth listenable.
final authListenableProvider = Provider<AuthStateListenable>((ref) {
  final listenable = AuthStateListenable(ref);
  ref.onDispose(listenable.dispose);
  return listenable;
});
