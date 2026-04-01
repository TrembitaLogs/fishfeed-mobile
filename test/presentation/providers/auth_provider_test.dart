import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';


import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/core/di/repository_providers.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/domain/repositories/aquarium_repository.dart';
import 'package:fishfeed/domain/repositories/auth_repository.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/services/auth/apple_auth_service.dart';
import 'package:fishfeed/services/auth/google_auth_service.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

import '../../helpers/test_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockGoogleAuthService extends Mock implements GoogleAuthService {}

class MockAppleAuthService extends Mock implements AppleAuthService {}

class MockAquariumRepository extends Mock implements AquariumRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late MockGoogleAuthService mockGoogleAuthService;
  late MockAppleAuthService mockAppleAuthService;
  late MockAquariumRepository mockAquariumRepository;
  late MockSyncService mockSyncService;
  late AuthNotifier authNotifier;
  late Directory tempDir;

  final testUser = User(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: DateTime(2024, 1, 15),
    subscriptionStatus: const SubscriptionStatus.free(),
    freeAiScansRemaining: 5,
  );

  setUpAll(() async {
    registerFallbackValue(
      User(
        id: 'fallback',
        email: 'fallback@test.com',
        createdAt: DateTime(2024),
      ),
    );
    tempDir = await Directory.systemTemp.createTemp('auth_provider_test_');
    Hive.init(tempDir.path);
    await HiveBoxes.initForTesting();
  });

  tearDownAll(() async {
    await HiveBoxes.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    mockGoogleAuthService = MockGoogleAuthService();
    mockAppleAuthService = MockAppleAuthService();
    mockAquariumRepository = MockAquariumRepository();
    mockSyncService = createMockSyncService();

    when(
      () => mockAquariumRepository.getCachedAquariums(),
    ).thenReturn(const Right([]));
    when(
      () => mockRepository.getOnboardingCompleted(),
    ).thenReturn(false);
    when(
      () => mockRepository.setOnboardingCompleted(any()),
    ).thenAnswer((_) async {});
    when(() => mockRepository.saveUserLocally(any())).thenAnswer((_) async {});
    when(() => mockRepository.getLocalUser()).thenReturn(null);

    authNotifier = AuthNotifier(
      repository: mockRepository,
      googleAuthService: mockGoogleAuthService,
      appleAuthService: mockAppleAuthService,
      aquariumRepository: mockAquariumRepository,
      syncService: mockSyncService,
    );
  });

  group('AuthenticationState', () {
    test('initial state should be unauthenticated', () {
      const state = AuthenticationState.initial();

      expect(state.isAuthenticated, false);
      expect(state.isLoading, false);
      expect(state.user, null);
      expect(state.error, null);
    });

    test('loading state should have isLoading true', () {
      const state = AuthenticationState.loading();

      expect(state.isLoading, true);
      expect(state.isAuthenticated, false);
    });

    test('authenticated state should have user and isAuthenticated', () {
      final state = AuthenticationState.authenticated(testUser);

      expect(state.isAuthenticated, true);
      expect(state.user, testUser);
      expect(state.isLoading, false);
      expect(state.error, null);
    });

    test('error state should have error', () {
      final state = AuthenticationState.error(const AuthenticationFailure());

      expect(state.error, isA<AuthenticationFailure>());
      expect(state.isAuthenticated, false);
      expect(state.isLoading, false);
    });

    test('copyWith should create new state with updated fields', () {
      const initial = AuthenticationState.initial();
      final updated = initial.copyWith(isLoading: true);

      expect(updated.isLoading, true);
      expect(initial.isLoading, false); // Original unchanged
    });

    test('copyWith with clearError should clear error', () {
      final errorState = AuthenticationState.error(const NetworkFailure());
      final clearedState = errorState.copyWith(clearError: true);

      expect(clearedState.error, null);
    });

    test('equality should work correctly', () {
      const state1 = AuthenticationState.initial();
      const state2 = AuthenticationState.initial();

      expect(state1, equals(state2));
    });
  });

  group('AuthNotifier', () {
    test('initial state should be unauthenticated', () {
      expect(authNotifier.state.isAuthenticated, false);
      expect(authNotifier.state.isLoading, false);
    });

    group('login', () {
      test('should update state to authenticated on success', () async {
        when(
          () => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        await authNotifier.login(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(authNotifier.state.isAuthenticated, true);
        expect(authNotifier.state.user?.email, 'test@example.com');
        expect(authNotifier.state.isLoading, false);
      });

      test('should update state with error on failure', () async {
        when(
          () => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Left(AuthenticationFailure()));

        await authNotifier.login(
          email: 'test@example.com',
          password: 'wrong-password',
        );

        expect(authNotifier.state.isAuthenticated, false);
        expect(authNotifier.state.error, isA<AuthenticationFailure>());
        expect(authNotifier.state.isLoading, false);
      });

      test('should set loading state during login', () async {
        when(
          () => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async {
          // Verify loading state is set during the call
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return Right(testUser);
        });

        final future = authNotifier.login(
          email: 'test@example.com',
          password: 'password123',
        );

        // Give time for state to update
        await Future<void>.delayed(const Duration(milliseconds: 5));
        expect(authNotifier.state.isLoading, true);

        await future;
        expect(authNotifier.state.isLoading, false);
      });
    });

    group('register', () {
      test('should update state to authenticated on success', () async {
        when(
          () => mockRepository.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        await authNotifier.register(
          email: 'new@example.com',
          password: 'Password1',
          confirmPassword: 'Password1',
        );

        expect(authNotifier.state.isAuthenticated, true);
      });

      test('should update state with error on failure', () async {
        when(
          () => mockRepository.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Left(ValidationFailure()));

        await authNotifier.register(
          email: 'new@example.com',
          password: 'weak',
          confirmPassword: 'weak',
        );

        expect(authNotifier.state.error, isA<ValidationFailure>());
      });
    });

    group('loginWithGoogle', () {
      test('should update state to authenticated on success', () async {
        when(() => mockGoogleAuthService.signIn()).thenAnswer(
          (_) async => const GoogleSignInResult(
            idToken: 'google-id-token',
            email: 'test@gmail.com',
          ),
        );

        when(
          () => mockRepository.oauthLogin(
            provider: any(named: 'provider'),
            idToken: any(named: 'idToken'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        await authNotifier.loginWithGoogle();

        expect(authNotifier.state.isAuthenticated, true);
        verify(() => mockGoogleAuthService.signIn()).called(1);
      });

      test('should handle cancellation', () async {
        when(
          () => mockGoogleAuthService.signIn(),
        ).thenThrow(const GoogleAuthException(GoogleAuthErrorCode.cancelled));

        await authNotifier.loginWithGoogle();

        expect(authNotifier.state.error, isA<CancellationFailure>());
        expect(authNotifier.state.isAuthenticated, false);
      });

      test('should handle network error', () async {
        when(() => mockGoogleAuthService.signIn()).thenThrow(
          const GoogleAuthException(GoogleAuthErrorCode.networkError),
        );

        await authNotifier.loginWithGoogle();

        expect(authNotifier.state.error, isA<NetworkFailure>());
      });
    });

    group('loginWithApple', () {
      test('should update state to authenticated on success', () async {
        when(() => mockAppleAuthService.signIn()).thenAnswer(
          (_) async => const AppleSignInResult(
            identityToken: 'apple-id-token',
            authorizationCode: 'auth-code',
            userIdentifier: 'user-id',
          ),
        );

        when(
          () => mockRepository.oauthLogin(
            provider: any(named: 'provider'),
            idToken: any(named: 'idToken'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        await authNotifier.loginWithApple();

        expect(authNotifier.state.isAuthenticated, true);
        verify(() => mockAppleAuthService.signIn()).called(1);
      });

      test('should handle not available', () async {
        when(
          () => mockAppleAuthService.signIn(),
        ).thenThrow(const AppleAuthException(AppleAuthErrorCode.notAvailable));

        await authNotifier.loginWithApple();

        expect(authNotifier.state.error, isA<OAuthFailure>());
      });
    });

    group('logout', () {
      test('should reset state to initial', () async {
        // First authenticate
        when(
          () => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        await authNotifier.login(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(authNotifier.state.isAuthenticated, true);

        // Then logout
        when(
          () => mockRepository.logout(),
        ).thenAnswer((_) async => const Right(unit));
        when(() => mockGoogleAuthService.signOut()).thenAnswer((_) async {});

        await authNotifier.logout();

        expect(authNotifier.state.isAuthenticated, false);
        expect(authNotifier.state.user, null);
      });

      test('should call onLogout callback', () async {
        var logoutCalled = false;
        authNotifier.onLogout = () => logoutCalled = true;

        when(
          () => mockRepository.logout(),
        ).thenAnswer((_) async => const Right(unit));
        when(() => mockGoogleAuthService.signOut()).thenAnswer((_) async {});

        await authNotifier.logout();

        expect(logoutCalled, true);
      });
    });

    group('initialize', () {
      test('should restore authenticated state from local storage', () async {
        when(
          () => mockRepository.isAuthenticated(),
        ).thenAnswer((_) async => true);
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testUser));

        await authNotifier.initialize();

        expect(authNotifier.state.isAuthenticated, true);
        expect(authNotifier.state.user, testUser);
      });

      test('should remain unauthenticated when no tokens', () async {
        when(
          () => mockRepository.isAuthenticated(),
        ).thenAnswer((_) async => false);

        await authNotifier.initialize();

        expect(authNotifier.state.isAuthenticated, false);
      });

      test('should remain unauthenticated when no cached user', () async {
        when(
          () => mockRepository.isAuthenticated(),
        ).thenAnswer((_) async => true);
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => const Left(CacheFailure()));

        await authNotifier.initialize();

        expect(authNotifier.state.isAuthenticated, false);
      });
    });

    group('completeOnboarding', () {
      test('should update hasCompletedOnboarding', () async {
        when(
          () => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        await authNotifier.login(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(authNotifier.state.hasCompletedOnboarding, false);

        await authNotifier.completeOnboarding();

        expect(authNotifier.state.hasCompletedOnboarding, true);
      });
    });

    group('clearError', () {
      test('should clear error from state', () async {
        when(
          () => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Left(AuthenticationFailure()));

        await authNotifier.login(email: 'test@example.com', password: 'wrong');

        expect(authNotifier.state.error, isNotNull);

        authNotifier.clearError();

        expect(authNotifier.state.error, null);
      });
    });
  });

  group('Riverpod providers', () {
    test('authNotifierProvider should create AuthNotifier', () {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          googleAuthServiceProvider.overrideWithValue(mockGoogleAuthService),
          appleAuthServiceProvider.overrideWithValue(mockAppleAuthService),
          aquariumRepositoryProvider.overrideWithValue(
            mockAquariumRepository,
          ),
          syncServiceProvider.overrideWithValue(createMockSyncService()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);

      expect(notifier, isA<AuthNotifier>());
    });

    test('authStateProvider should return current state', () {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          googleAuthServiceProvider.overrideWithValue(mockGoogleAuthService),
          appleAuthServiceProvider.overrideWithValue(mockAppleAuthService),
          aquariumRepositoryProvider.overrideWithValue(
            mockAquariumRepository,
          ),
          syncServiceProvider.overrideWithValue(createMockSyncService()),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(authStateProvider);

      expect(state, isA<AuthenticationState>());
      expect(state.isAuthenticated, false);
    });

    test('currentUserProvider should return null when not authenticated', () {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          googleAuthServiceProvider.overrideWithValue(mockGoogleAuthService),
          appleAuthServiceProvider.overrideWithValue(mockAppleAuthService),
          aquariumRepositoryProvider.overrideWithValue(
            mockAquariumRepository,
          ),
          syncServiceProvider.overrideWithValue(createMockSyncService()),
        ],
      );
      addTearDown(container.dispose);

      final user = container.read(currentUserProvider);

      expect(user, null);
    });

    test('isAuthenticatedProvider should return false initially', () {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          googleAuthServiceProvider.overrideWithValue(mockGoogleAuthService),
          appleAuthServiceProvider.overrideWithValue(mockAppleAuthService),
          aquariumRepositoryProvider.overrideWithValue(
            mockAquariumRepository,
          ),
          syncServiceProvider.overrideWithValue(createMockSyncService()),
        ],
      );
      addTearDown(container.dispose);

      final isAuthenticated = container.read(isAuthenticatedProvider);

      expect(isAuthenticated, false);
    });
  });

  group('sync and onboarding check', () {
    final activeAquarium = Aquarium(
      id: 'aq-1',
      userId: 'user-123',
      name: 'Test Aquarium',
      waterType: WaterType.freshwater,
      createdAt: DateTime(2024, 1, 15),
    );

    setUp(() async {
      // Reset onboarding flag before each test in this group
      await HiveBoxes.setOnboardingCompleted(false);
    });

    test(
      'login should mark onboarding complete when sync finds aquariums',
      () async {
        when(
          () => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        when(
          () => mockAquariumRepository.getCachedAquariums(),
        ).thenReturn(Right([activeAquarium]));

        await authNotifier.login(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(authNotifier.state.isAuthenticated, true);
        expect(authNotifier.state.hasCompletedOnboarding, true);
        verify(() => mockSyncService.syncAll()).called(greaterThanOrEqualTo(1));
        verify(() => mockAquariumRepository.getCachedAquariums()).called(1);
      },
    );

    test(
      'login should not mark onboarding complete when no aquariums after sync',
      () async {
        when(
          () => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        when(
          () => mockAquariumRepository.getCachedAquariums(),
        ).thenReturn(const Right([]));

        await authNotifier.login(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(authNotifier.state.isAuthenticated, true);
        expect(authNotifier.state.hasCompletedOnboarding, false);
      },
    );

    test(
      'login should return empty when no active aquariums for onboarding check',
      () async {
        when(
          () => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        when(
          () => mockAquariumRepository.getCachedAquariums(),
        ).thenReturn(const Right([]));

        await authNotifier.login(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(authNotifier.state.hasCompletedOnboarding, false);
      },
    );

    test('login should fallback to local check when sync fails', () async {
      when(
        () => mockRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(testUser));

      // Sync fails on first call, succeeds on subsequent (background sync)
      var syncCallCount = 0;
      when(() => mockSyncService.syncAll()).thenAnswer((_) async {
        syncCallCount++;
        if (syncCallCount == 1) throw Exception('Network error');
        return 0;
      });

      // But local data has aquariums
      when(
        () => mockAquariumRepository.getCachedAquariums(),
      ).thenReturn(Right([activeAquarium]));

      await authNotifier.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(authNotifier.state.isAuthenticated, true);
      expect(authNotifier.state.hasCompletedOnboarding, true);
    });

    test(
      'login should not mark onboarding when sync fails and no local aquariums',
      () async {
        when(
          () => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        // Sync fails — no background sync triggered (onboarding not completed)
        when(
          () => mockSyncService.syncAll(),
        ).thenAnswer((_) async => throw Exception('Network error'));

        when(
          () => mockAquariumRepository.getCachedAquariums(),
        ).thenReturn(const Right([]));

        await authNotifier.login(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(authNotifier.state.isAuthenticated, true);
        expect(authNotifier.state.hasCompletedOnboarding, false);
      },
    );

    test(
      'login should skip sync check when onboarding already completed',
      () async {
        when(
          () => mockRepository.getOnboardingCompleted(),
        ).thenReturn(true);

        when(
          () => mockRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        await authNotifier.login(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(authNotifier.state.hasCompletedOnboarding, true);
        // getCachedAquariums should NOT be called since we skip _syncAndCheckOnboarding
        verifyNever(() => mockAquariumRepository.getCachedAquariums());
      },
    );

    test(
      'initialize should sync and check onboarding when flag is false',
      () async {
        when(
          () => mockRepository.isAuthenticated(),
        ).thenAnswer((_) async => true);
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testUser));
        when(
          () => mockAquariumRepository.getCachedAquariums(),
        ).thenReturn(Right([activeAquarium]));

        await authNotifier.initialize();

        expect(authNotifier.state.isAuthenticated, true);
        expect(authNotifier.state.hasCompletedOnboarding, true);
        verify(() => mockSyncService.syncAll()).called(greaterThanOrEqualTo(1));
      },
    );

    test(
      'initialize should trigger background sync when onboarding complete',
      () async {
        when(
          () => mockRepository.getOnboardingCompleted(),
        ).thenReturn(true);

        when(
          () => mockRepository.isAuthenticated(),
        ).thenAnswer((_) async => true);
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => Right(testUser));

        await authNotifier.initialize();

        expect(authNotifier.state.hasCompletedOnboarding, true);
        // Background sync should be triggered
        verify(() => mockSyncService.syncAll()).called(greaterThanOrEqualTo(1));
      },
    );
  });

  group('AuthStateListenable', () {
    test('should provide isLoggedIn based on auth state', () {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          googleAuthServiceProvider.overrideWithValue(mockGoogleAuthService),
          appleAuthServiceProvider.overrideWithValue(mockAppleAuthService),
          aquariumRepositoryProvider.overrideWithValue(
            mockAquariumRepository,
          ),
          syncServiceProvider.overrideWithValue(createMockSyncService()),
        ],
      );
      addTearDown(container.dispose);

      final listenable = container.read(authListenableProvider);

      expect(listenable.isLoggedIn, false);
    });

    test('should notify listeners on state change', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
          googleAuthServiceProvider.overrideWithValue(mockGoogleAuthService),
          appleAuthServiceProvider.overrideWithValue(mockAppleAuthService),
          aquariumRepositoryProvider.overrideWithValue(
            mockAquariumRepository,
          ),
          syncServiceProvider.overrideWithValue(createMockSyncService()),
        ],
      );
      addTearDown(container.dispose);

      when(
        () => mockRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(testUser));

      final listenable = container.read(authListenableProvider);
      var notified = false;
      listenable.addListener(() => notified = true);

      await container
          .read(authNotifierProvider.notifier)
          .login(email: 'test@example.com', password: 'password');

      // Allow microtask to run
      await Future<void>.delayed(Duration.zero);

      expect(notified, true);
    });
  });
}
