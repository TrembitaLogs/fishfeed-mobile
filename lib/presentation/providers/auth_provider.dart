import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/remote/aquarium_remote_ds.dart';
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
    this.error,
    this.isAuthenticated = false,
    this.hasCompletedOnboarding = false,
  });

  /// Creates initial unauthenticated state.
  const AuthenticationState.initial()
      : user = null,
        isLoading = false,
        error = null,
        isAuthenticated = false,
        hasCompletedOnboarding = false;

  /// Creates loading state.
  const AuthenticationState.loading()
      : user = null,
        isLoading = true,
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
      error: failure,
      isAuthenticated: false,
      hasCompletedOnboarding: false,
    );
  }

  /// Current authenticated user.
  final User? user;

  /// Whether an auth operation is in progress.
  final bool isLoading;

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
    Failure? error,
    bool? isAuthenticated,
    bool? hasCompletedOnboarding,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthenticationState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
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
        other.error == error &&
        other.isAuthenticated == isAuthenticated &&
        other.hasCompletedOnboarding == hasCompletedOnboarding;
  }

  @override
  int get hashCode => Object.hash(
        user,
        isLoading,
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
    required AquariumRemoteDataSource aquariumRemoteDataSource,
    required SyncService syncService,
  })  : _repository = repository,
        _googleAuthService = googleAuthService,
        _appleAuthService = appleAuthService,
        _aquariumRemoteDataSource = aquariumRemoteDataSource,
        _syncService = syncService,
        _loginUseCase = LoginUseCase(repository),
        _registerUseCase = RegisterUseCase(repository),
        _oauthLoginUseCase = OAuthLoginUseCase(repository),
        _logoutUseCase = LogoutUseCase(repository),
        super(const AuthenticationState.initial());

  final AuthRepository _repository;
  final GoogleAuthService _googleAuthService;
  final AppleAuthService _appleAuthService;
  final AquariumRemoteDataSource _aquariumRemoteDataSource;
  final SyncService _syncService;
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final OAuthLoginUseCase _oauthLoginUseCase;
  final LogoutUseCase _logoutUseCase;

  /// Callback triggered on logout for external cleanup (e.g., router redirect).
  VoidCallback? onLogout;

  /// Initializes auth state from local storage.
  ///
  /// Call this on app startup to restore session.
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final isAuthenticated = await _repository.isAuthenticated();

    if (!isAuthenticated) {
      state = const AuthenticationState.initial();
      return;
    }

    final userResult = await _repository.getCurrentUser();
    await userResult.fold(
      (failure) async {
        state = const AuthenticationState.initial();
      },
      (user) async {
        var hasCompletedOnboarding = HiveBoxes.getOnboardingCompleted();
        debugPrint('[AuthNotifier] Initialize: restored user ${user.email}');
        debugPrint('[AuthNotifier] Initialize: Hive flag=$hasCompletedOnboarding');

        // Check server data BEFORE setting authenticated state
        if (!hasCompletedOnboarding) {
          try {
            final aquariums = await _aquariumRemoteDataSource.getAquariums();
            debugPrint('[AuthNotifier] Initialize: got ${aquariums.length} aquariums');
            if (aquariums.isNotEmpty) {
              await HiveBoxes.setOnboardingCompleted(true);
              hasCompletedOnboarding = true;
            }
          } catch (e) {
            debugPrint('[AuthNotifier] Initialize: failed to check server: $e');
          }
        }

        state = AuthenticationState.authenticated(
          user,
          hasCompletedOnboarding: hasCompletedOnboarding,
        );

        // Trigger full sync after session restore to ensure fresh data
        debugPrint('[AuthNotifier] Triggering full sync after session restore');
        unawaited(_syncService.syncAll());
      },
    );
  }

  /// Login with email and password.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _loginUseCase(LoginParams(
      email: email,
      password: password,
    ));

    await result.fold(
      (failure) async {
        state = state.copyWith(isLoading: false, error: failure);
      },
      (user) async {
        // Check if user has completed onboarding (stored locally)
        var hasCompletedOnboarding = HiveBoxes.getOnboardingCompleted();
        debugPrint('[AuthNotifier] Login success for ${user.email}');
        debugPrint('[AuthNotifier] Local Hive onboarding flag: $hasCompletedOnboarding');

        // Check server data BEFORE setting authenticated state to avoid
        // premature redirect to onboarding
        if (!hasCompletedOnboarding) {
          debugPrint('[AuthNotifier] Local flag false, checking server data BEFORE setting state...');
          try {
            final aquariums = await _aquariumRemoteDataSource.getAquariums();
            debugPrint('[AuthNotifier] Got ${aquariums.length} aquariums from server');
            if (aquariums.isNotEmpty) {
              debugPrint('[AuthNotifier] User has aquariums, marking onboarding completed');
              await HiveBoxes.setOnboardingCompleted(true);
              hasCompletedOnboarding = true;
            }
          } catch (e) {
            debugPrint('[AuthNotifier] Failed to check server data: $e');
          }
        } else {
          debugPrint('[AuthNotifier] Local flag true, skipping server check');
        }

        debugPrint('[AuthNotifier] Setting state with hasCompletedOnboarding=$hasCompletedOnboarding');
        state = AuthenticationState.authenticated(
          user,
          hasCompletedOnboarding: hasCompletedOnboarding,
        );

        // Trigger full sync after login to fetch fresh data from server
        debugPrint('[AuthNotifier] Triggering full sync after login');
        unawaited(_syncService.syncAll());
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

    final result = await _registerUseCase(RegisterParams(
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    ));

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

      final result = await _oauthLoginUseCase(OAuthLoginParams(
        provider: OAuthProvider.google,
        idToken: googleResult.idToken,
      ));

      await result.fold(
        (failure) async {
          state = state.copyWith(isLoading: false, error: failure);
        },
        (user) async {
          var hasCompletedOnboarding = HiveBoxes.getOnboardingCompleted();
          debugPrint('[AuthNotifier] Google login success for ${user.email}');

          // Check server data BEFORE setting authenticated state
          if (!hasCompletedOnboarding) {
            try {
              final aquariums = await _aquariumRemoteDataSource.getAquariums();
              if (aquariums.isNotEmpty) {
                await HiveBoxes.setOnboardingCompleted(true);
                hasCompletedOnboarding = true;
              }
            } catch (e) {
              debugPrint('[AuthNotifier] Failed to check server data: $e');
            }
          }

          state = AuthenticationState.authenticated(
            user,
            hasCompletedOnboarding: hasCompletedOnboarding,
          );

          // Trigger full sync after login to fetch fresh data from server
          debugPrint('[AuthNotifier] Triggering full sync after Google login');
          unawaited(_syncService.syncAll());
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

      final result = await _oauthLoginUseCase(OAuthLoginParams(
        provider: OAuthProvider.apple,
        idToken: appleResult.identityToken,
      ));

      await result.fold(
        (failure) async {
          state = state.copyWith(isLoading: false, error: failure);
        },
        (user) async {
          var hasCompletedOnboarding = HiveBoxes.getOnboardingCompleted();
          debugPrint('[AuthNotifier] Apple login success for ${user.email}');

          // Check server data BEFORE setting authenticated state
          if (!hasCompletedOnboarding) {
            try {
              final aquariums = await _aquariumRemoteDataSource.getAquariums();
              if (aquariums.isNotEmpty) {
                await HiveBoxes.setOnboardingCompleted(true);
                hasCompletedOnboarding = true;
              }
            } catch (e) {
              debugPrint('[AuthNotifier] Failed to check server data: $e');
            }
          }

          state = AuthenticationState.authenticated(
            user,
            hasCompletedOnboarding: hasCompletedOnboarding,
          );

          // Trigger full sync after login to fetch fresh data from server
          debugPrint('[AuthNotifier] Triggering full sync after Apple login');
          unawaited(_syncService.syncAll());
        },
      );
    } on AppleAuthException catch (e) {
      final failure = switch (e.code) {
        AppleAuthErrorCode.cancelled => const CancellationFailure(),
        AppleAuthErrorCode.notAvailable =>
          const OAuthFailure(message: 'Apple Sign-In not available', provider: 'apple'),
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

  /// Check if user has data on server and update onboarding status.
  ///
  /// Called after login to determine if user should skip onboarding.
  /// If user has aquariums on server, marks onboarding as completed.
  Future<void> checkServerDataAndUpdateOnboarding() async {
    debugPrint('[AuthNotifier] checkServerDataAndUpdateOnboarding called');
    debugPrint('[AuthNotifier] isAuthenticated: ${state.isAuthenticated}');

    if (!state.isAuthenticated) {
      debugPrint('[AuthNotifier] Not authenticated, skipping server check');
      return;
    }

    try {
      debugPrint('[AuthNotifier] Fetching aquariums from server...');
      final aquariums = await _aquariumRemoteDataSource.getAquariums();
      debugPrint('[AuthNotifier] Got ${aquariums.length} aquariums from server');

      if (aquariums.isNotEmpty) {
        // User has aquariums on server - mark onboarding as completed
        debugPrint('[AuthNotifier] User has aquariums, marking onboarding completed');
        await HiveBoxes.setOnboardingCompleted(true);
        state = state.copyWith(hasCompletedOnboarding: true);
        debugPrint('[AuthNotifier] State updated: hasCompletedOnboarding=${state.hasCompletedOnboarding}');
      } else {
        debugPrint('[AuthNotifier] No aquariums on server, keeping onboarding incomplete');
      }
    } catch (e, stackTrace) {
      // If server check fails, use local Hive flag (already set during login)
      debugPrint('[AuthNotifier] Failed to check server data: $e');
      debugPrint('[AuthNotifier] Stack trace: $stackTrace');
    }
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

    state = state.copyWith(
      user: updatedUser,
    );
  }
}

/// Provider for [AuthNotifier].
///
/// Usage:
/// ```dart
/// final authNotifier = ref.watch(authNotifierProvider.notifier);
/// await authNotifier.login(email: email, password: password);
/// ```
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthenticationState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final googleAuthService = ref.watch(googleAuthServiceProvider);
  final appleAuthService = ref.watch(appleAuthServiceProvider);
  final aquariumRemoteDataSource = ref.watch(aquariumRemoteDataSourceProvider);
  final syncService = ref.watch(syncServiceProvider);

  return AuthNotifier(
    repository: repository,
    googleAuthService: googleAuthService,
    appleAuthService: appleAuthService,
    aquariumRemoteDataSource: aquariumRemoteDataSource,
    syncService: syncService,
  );
});

/// Provider for current authentication state.
///
/// Convenience provider for accessing just the state.
///
/// Usage:
/// ```dart
/// final authState = ref.watch(authStateProvider);
/// if (authState.isAuthenticated) {
///   print('User: ${authState.user?.email}');
/// }
/// ```
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
///
/// Usage:
/// ```dart
/// final authListenable = AuthStateListenable(ref);
/// GoRouter(
///   refreshListenable: authListenable,
///   redirect: (context, state) => authListenable.redirect(state),
///   ...
/// );
/// ```
class AuthStateListenable extends ChangeNotifier {
  AuthStateListenable(this._ref) {
    _subscription = _ref.listen(authNotifierProvider, (previous, next) {
      // Notify GoRouter of state changes
      notifyListeners();
    });
  }

  final Ref _ref;
  ProviderSubscription<AuthenticationState>? _subscription;

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
///
/// Usage:
/// ```dart
/// final container = ProviderContainer();
/// final authListenable = container.read(authListenableProvider);
/// final router = GoRouter(refreshListenable: authListenable, ...);
/// ```
final authListenableProvider = Provider<AuthStateListenable>((ref) {
  final listenable = AuthStateListenable(ref);
  ref.onDispose(listenable.dispose);
  return listenable;
});
