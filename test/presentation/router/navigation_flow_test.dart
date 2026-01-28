import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/data/repositories/auth_repository_impl.dart';
import 'package:fishfeed/data/repositories/user_repository_impl.dart';
import 'package:fishfeed/domain/entities/calendar_month_data.dart';
import 'package:fishfeed/domain/entities/day_feeding_status.dart';
import 'package:fishfeed/domain/entities/feeding_status.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/repositories/auth_repository.dart';
import 'package:fishfeed/domain/repositories/user_repository.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/calendar_data_provider.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/router/app_router.dart';
import 'package:fishfeed/services/auth/apple_auth_service.dart';
import 'package:fishfeed/services/auth/google_auth_service.dart';
import 'package:fishfeed/services/sync/sync_service.dart';
import 'package:fishfeed/data/datasources/remote/aquarium_remote_ds.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/water_type.dart';

import '../../helpers/test_helpers.dart'
    show createMockSyncService, createMockAquariumRemoteDataSource;

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockGoogleAuthService extends Mock implements GoogleAuthService {}

class MockAppleAuthService extends Mock implements AppleAuthService {}

/// Mock CalendarDataNotifier that doesn't make async calls.
class MockCalendarDataNotifier extends StateNotifier<CalendarDataState>
    implements CalendarDataNotifier {
  MockCalendarDataNotifier()
    : super(
        CalendarDataState(
          monthData: CalendarMonthData.empty(
            DateTime.now().year,
            DateTime.now().month,
          ),
          isLoading: false,
        ),
      );

  @override
  Future<void> loadMonth(int year, int month) async {}

  @override
  DayFeedingStatus getDayStatus(DateTime day) => DayFeedingStatus.noData;

  @override
  Future<void> refresh() async {}
}

/// Mock UserAquariumsNotifier that doesn't make async calls.
class MockUserAquariumsNotifier extends StateNotifier<UserAquariumsState>
    implements UserAquariumsNotifier {
  MockUserAquariumsNotifier()
    : super(UserAquariumsState(aquariums: _defaultAquariums));

  static final _defaultAquariums = [
    Aquarium(
      id: 'test-aquarium',
      userId: 'test-user-123',
      name: 'Test Aquarium',
      waterType: WaterType.freshwater,
      createdAt: DateTime(2024, 1, 15),
    ),
  ];

  @override
  Future<void> loadAquariums() async {}

  @override
  Future<Aquarium?> createAquarium({
    required String name,
    WaterType? waterType,
    double? capacity,
  }) async => null;

  @override
  Future<Aquarium?> updateAquarium({
    required String aquariumId,
    String? name,
    WaterType? waterType,
    double? capacity,
    String? imageUrl,
  }) async => null;

  @override
  Future<bool> deleteAquarium(String aquariumId) async => true;

  Aquarium? getAquariumById(String id) {
    try {
      return state.aquariums.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void clearError() {}

  @override
  Future<void> refresh() async {}
}

/// Mock TodayFeedingsNotifier that doesn't make async calls.
class MockTodayFeedingsNotifier extends StateNotifier<TodayFeedingsState>
    implements TodayFeedingsNotifier {
  MockTodayFeedingsNotifier()
    : super(const TodayFeedingsState(feedings: [], isLoading: false));

  @override
  Future<void> loadFeedings() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> markAsFed(String feedingId) async {}

  @override
  Future<void> markAsMissed(String feedingId) async {}

  @override
  void updateFeedingStatus(String feedingId, FeedingStatus newStatus) {}

  @override
  void clearError() {}
}

/// Test implementation of AuthStateListenable for navigation flow tests.
class TestAuthStateListenable extends ChangeNotifier
    implements AuthStateListenable {
  bool _isLoggedIn = false;
  bool _hasCompletedOnboarding = false;

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  void setAuthState({
    required bool isLoggedIn,
    required bool hasCompletedOnboarding,
  }) {
    _isLoggedIn = isLoggedIn;
    _hasCompletedOnboarding = hasCompletedOnboarding;
    notifyListeners();
  }

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _hasCompletedOnboarding = false;
    notifyListeners();
  }

  void completeOnboarding() {
    _hasCompletedOnboarding = true;
    notifyListeners();
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  group('Navigation Flow Integration Tests', () {
    late TestAuthStateListenable authState;
    late GoRouter router;
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;
    late MockGoogleAuthService mockGoogleAuthService;
    late MockAppleAuthService mockAppleAuthService;

    final testUser = User(
      id: 'test-user-123',
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: DateTime(2024, 1, 15),
      subscriptionStatus: const SubscriptionStatus.free(),
      freeAiScansRemaining: 5,
    );

    setUp(() {
      authState = TestAuthStateListenable();
      router = AppRouter.createRouter(authState);
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();
      mockGoogleAuthService = MockGoogleAuthService();
      mockAppleAuthService = MockAppleAuthService();
    });

    tearDown(() {
      authState.dispose();
    });

    Widget buildTestApp() {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          userRepositoryProvider.overrideWithValue(mockUserRepository),
          googleAuthServiceProvider.overrideWithValue(mockGoogleAuthService),
          appleAuthServiceProvider.overrideWithValue(mockAppleAuthService),
          // Mock aquarium remote data source for authNotifierProvider
          aquariumRemoteDataSourceProvider.overrideWithValue(
            createMockAquariumRemoteDataSource(),
          ),
          // Mock calendar and feeding providers to prevent infinite rebuild loops
          calendarDataProvider.overrideWith(
            (ref) => MockCalendarDataNotifier(),
          ),
          todayFeedingsProvider.overrideWith(
            (ref) => MockTodayFeedingsNotifier(),
          ),
          // Provide a test user for ProfileScreen
          currentUserProvider.overrideWithValue(testUser),
          // Mock SyncService to prevent conflicts with ConflictResolutionListener
          syncServiceProvider.overrideWithValue(createMockSyncService()),
          // Mock sync state provider to prevent infinite loop in SyncStatusIndicator
          syncStateProvider.overrideWith((ref) async* {
            yield SyncState.idle;
          }),
          // Mock user aquariums provider to avoid HiveBoxes dependency
          userAquariumsProvider.overrideWith(
            (ref) => MockUserAquariumsNotifier(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
    }

    group('new user flow', () {
      testWidgets('new user is redirected to onboarding after login', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Initially on /auth (not logged in)
        expect(router.routerDelegate.currentConfiguration.uri.path, '/auth');

        // User logs in but hasn't completed onboarding
        authState.login();
        await tester.pumpAndSettle();

        // Should be on /onboarding
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          '/onboarding',
        );
        // Real OnboardingScreen shows first step content
        expect(find.text('Create Your First Aquarium'), findsOneWidget);
      });

      testWidgets(
        'new user is redirected to home after completing onboarding',
        (tester) async {
          // Start as logged in but not onboarded
          authState.login();

          await tester.pumpWidget(buildTestApp());
          await tester.pumpAndSettle();

          // Should be on /onboarding
          expect(
            router.routerDelegate.currentConfiguration.uri.path,
            '/onboarding',
          );

          // Complete onboarding
          authState.completeOnboarding();
          await tester.pumpAndSettle();

          // Should be on home
          expect(router.routerDelegate.currentConfiguration.uri.path, '/');
          expect(find.text('Home'), findsOneWidget);
        },
      );
    });

    group('existing user flow', () {
      testWidgets('existing user is redirected to home after login', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Initially on /auth
        expect(router.routerDelegate.currentConfiguration.uri.path, '/auth');

        // Existing user logs in (already onboarded)
        authState.setAuthState(isLoggedIn: true, hasCompletedOnboarding: true);
        await tester.pumpAndSettle();

        // Should be on home
        expect(router.routerDelegate.currentConfiguration.uri.path, '/');
        expect(find.text('Home'), findsOneWidget);
      });
    });

    group('unauthenticated redirect', () {
      testWidgets('unauthenticated user is redirected to login from home', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Should be on /auth (redirected from home)
        expect(router.routerDelegate.currentConfiguration.uri.path, '/auth');
        expect(find.text('Log In'), findsOneWidget);
      });

      testWidgets(
        'unauthenticated user is redirected to login from protected routes',
        (tester) async {
          await tester.pumpWidget(buildTestApp());
          await tester.pumpAndSettle();

          // Try to navigate to calendar
          router.go('/calendar');
          await tester.pumpAndSettle();

          // Should be redirected to /auth
          expect(router.routerDelegate.currentConfiguration.uri.path, '/auth');

          // Try to navigate to profile
          router.go('/profile');
          await tester.pumpAndSettle();

          // Should be redirected to /auth
          expect(router.routerDelegate.currentConfiguration.uri.path, '/auth');
        },
      );
    });

    group('authenticated redirect from auth routes', () {
      testWidgets(
        'authenticated user with onboarding is redirected from auth to home',
        (tester) async {
          authState.setAuthState(
            isLoggedIn: true,
            hasCompletedOnboarding: true,
          );

          await tester.pumpWidget(buildTestApp());
          await tester.pumpAndSettle();

          // Try to go to /auth
          router.go('/auth');
          await tester.pumpAndSettle();

          // Should be redirected to home
          expect(router.routerDelegate.currentConfiguration.uri.path, '/');
        },
      );

      testWidgets(
        'authenticated user with onboarding is redirected from register to home',
        (tester) async {
          authState.setAuthState(
            isLoggedIn: true,
            hasCompletedOnboarding: true,
          );

          await tester.pumpWidget(buildTestApp());
          await tester.pumpAndSettle();

          // Try to go to /auth/register
          router.go('/auth/register');
          await tester.pumpAndSettle();

          // Should be redirected to home
          expect(router.routerDelegate.currentConfiguration.uri.path, '/');
        },
      );

      testWidgets(
        'authenticated user without onboarding is redirected from auth to onboarding',
        (tester) async {
          authState.login();

          await tester.pumpWidget(buildTestApp());
          await tester.pumpAndSettle();

          // Try to go to /auth
          router.go('/auth');
          await tester.pumpAndSettle();

          // Should be redirected to onboarding
          expect(
            router.routerDelegate.currentConfiguration.uri.path,
            '/onboarding',
          );
        },
      );
    });

    group('logout flow', () {
      testWidgets('user is redirected to login after logout', (tester) async {
        // Start logged in with onboarding
        authState.setAuthState(isLoggedIn: true, hasCompletedOnboarding: true);

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Should be on home
        expect(router.routerDelegate.currentConfiguration.uri.path, '/');

        // Navigate to some other protected route
        router.go('/calendar');
        await tester.pumpAndSettle();

        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          '/calendar',
        );

        // Logout
        authState.logout();
        await tester.pumpAndSettle();

        // Should be redirected to /auth
        expect(router.routerDelegate.currentConfiguration.uri.path, '/auth');
      });

      testWidgets('protected routes are not accessible after logout', (
        tester,
      ) async {
        // Start logged in
        authState.setAuthState(isLoggedIn: true, hasCompletedOnboarding: true);

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Logout
        authState.logout();
        await tester.pumpAndSettle();

        // Try to access protected routes
        for (final route in ['/calendar', '/profile', '/settings', '/']) {
          router.go(route);
          await tester.pumpAndSettle();

          expect(
            router.routerDelegate.currentConfiguration.uri.path,
            '/auth',
            reason: 'Should redirect to /auth from $route after logout',
          );
        }
      });
    });

    group('navigation between auth screens', () {
      testWidgets('can navigate from login to register', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // On login screen
        expect(router.routerDelegate.currentConfiguration.uri.path, '/auth');

        // Navigate to register using go instead of push
        router.go(AppRouter.register);
        await tester.pumpAndSettle();

        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          AppRouter.register,
        );
        expect(find.text('Create Account'), findsWidgets);
      });
    });

    group('onboarding completion', () {
      testWidgets(
        'user stays on onboarding until completion then redirects to home',
        (tester) async {
          authState.login();

          await tester.pumpWidget(buildTestApp());
          await tester.pumpAndSettle();

          // Should be on onboarding
          expect(
            router.routerDelegate.currentConfiguration.uri.path,
            '/onboarding',
          );

          // Try to navigate to home
          router.go('/');
          await tester.pumpAndSettle();

          // Should still be on onboarding
          expect(
            router.routerDelegate.currentConfiguration.uri.path,
            '/onboarding',
          );

          // Complete onboarding
          authState.completeOnboarding();
          await tester.pumpAndSettle();

          // Now should be on home
          expect(router.routerDelegate.currentConfiguration.uri.path, '/');
        },
      );
    });
  });
}
