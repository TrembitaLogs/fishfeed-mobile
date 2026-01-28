import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/data/repositories/auth_repository_impl.dart';
import 'package:fishfeed/data/repositories/user_repository_impl.dart';
import 'package:fishfeed/domain/entities/calendar_month_data.dart';
import 'package:fishfeed/domain/entities/day_feeding_status.dart';
import 'package:fishfeed/domain/entities/feeding_status.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/repositories/auth_repository.dart';
import 'package:fishfeed/domain/repositories/user_repository.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/calendar_data_provider.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/router/app_router.dart';
import 'package:fishfeed/services/auth/apple_auth_service.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/services/auth/google_auth_service.dart';
import 'package:fishfeed/services/sync/sync_service.dart';
import 'package:fishfeed/data/datasources/remote/aquarium_remote_ds.dart';

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
      : super(CalendarDataState(
          monthData: CalendarMonthData.empty(
            DateTime.now().year,
            DateTime.now().month,
          ),
          isLoading: false,
        ));

  @override
  Future<void> loadMonth(int year, int month) async {}

  @override
  DayFeedingStatus getDayStatus(DateTime day) => DayFeedingStatus.noData;

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

/// Mock UserAquariumsNotifier that doesn't make async calls.
class MockUserAquariumsNotifier extends StateNotifier<UserAquariumsState>
    implements UserAquariumsNotifier {
  MockUserAquariumsNotifier({List<Aquarium>? aquariums})
      : super(UserAquariumsState(aquariums: aquariums ?? _defaultAquariums));

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
  }) async =>
      null;

  @override
  Future<Aquarium?> updateAquarium({
    required String aquariumId,
    String? name,
    WaterType? waterType,
    double? capacity,
    String? imageUrl,
  }) async =>
      null;

  @override
  Future<bool> deleteAquarium(String aquariumId) async => true;

  @override
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

/// Mock FishManagementNotifier that doesn't make async calls.
class MockFishManagementNotifier extends StateNotifier<FishManagementState>
    implements FishManagementNotifier {
  MockFishManagementNotifier({List<Fish>? fish})
      : super(FishManagementState(userFish: fish ?? _defaultTestFish));

  static final _defaultTestFish = [
    Fish(
      id: 'test-fish-1',
      aquariumId: 'test-aquarium',
      speciesId: 'guppy',
      name: 'My Guppy',
      quantity: 3,
      addedAt: DateTime(2024, 1, 15),
    ),
  ];

  @override
  Future<void> loadUserFish() async {}

  @override
  void setSelectedAquarium(String? aquariumId) {}

  @override
  Future<Fish?> addFish({
    required String speciesId,
    int quantity = 1,
    String? name,
    String? aquariumId,
  }) async =>
      null;

  @override
  Future<bool> updateFish(Fish fish) async => true;

  @override
  Future<bool> deleteFish(String fishId) async => true;

  @override
  Fish? getFishById(String id) {
    try {
      return state.userFish.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void clearError() {}

  @override
  Future<void> refresh() async {}
}

/// Test implementation of AuthStateListenable that doesn't require Riverpod.
class TestAuthStateListenable extends ChangeNotifier
    implements AuthStateListenable {
  bool _isLoggedIn = false;
  bool _hasCompletedOnboarding = false;

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  void completeOnboarding() {
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  void resetOnboarding() {
    _hasCompletedOnboarding = false;
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

  group('AppRouter', () {
    group('route paths', () {
      test('auth path is /auth', () {
        expect(AppRouter.auth, '/auth');
      });

      test('onboarding path is /onboarding', () {
        expect(AppRouter.onboarding, '/onboarding');
      });

      test('home path is /', () {
        expect(AppRouter.home, '/');
      });

      test('calendar path is /calendar', () {
        expect(AppRouter.calendar, '/calendar');
      });

      test('profile path is /profile', () {
        expect(AppRouter.profile, '/profile');
      });

      test('settings path is /settings', () {
        expect(AppRouter.settings, '/settings');
      });

      test('aiCamera path is /ai-camera', () {
        expect(AppRouter.aiCamera, '/ai-camera');
      });

      test('myAquarium path is /aquarium', () {
        expect(AppRouter.myAquarium, '/aquarium');
      });

      test('editFish path is /aquarium/fish/:fishId/edit', () {
        expect(AppRouter.editFish, '/aquarium/fish/:fishId/edit');
      });
    });

    group('createRouter', () {
      test('returns a GoRouter instance', () {
        final authState = TestAuthStateListenable();
        final router = AppRouter.createRouter(authState);

        expect(router, isA<GoRouter>());

        authState.dispose();
      });

      testWidgets('redirects to /auth on initial load for unauthenticated user',
          (tester) async {
        final authState = TestAuthStateListenable();
        final router = AppRouter.createRouter(authState);

        await tester.pumpWidget(_buildApp(router));
        await tester.pumpAndSettle();

        expect(router.routerDelegate.currentConfiguration.uri.path, '/auth');

        authState.dispose();
      });
    });

    group('redirect logic', () {
      late TestAuthStateListenable authState;
      late GoRouter router;

      setUp(() {
        authState = TestAuthStateListenable();
        router = AppRouter.createRouter(authState);
      });

      tearDown(() {
        authState.dispose();
      });

      group('unauthenticated user', () {
        testWidgets('redirects to /auth from home', (tester) async {
          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          expect(router.routerDelegate.currentConfiguration.uri.path, '/auth');
          // LoginScreen is rendered (shows login button)
          expect(find.text('Log In'), findsOneWidget);
        });

        testWidgets('can stay on /auth', (tester) async {
          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          router.go('/auth');
          await tester.pumpAndSettle();

          expect(router.routerDelegate.currentConfiguration.uri.path, '/auth');
        });

        testWidgets('redirects to /auth from /calendar', (tester) async {
          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          router.go('/calendar');
          await tester.pumpAndSettle();

          expect(router.routerDelegate.currentConfiguration.uri.path, '/auth');
        });

        testWidgets('redirects to /auth from /profile', (tester) async {
          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          router.go('/profile');
          await tester.pumpAndSettle();

          expect(router.routerDelegate.currentConfiguration.uri.path, '/auth');
        });

        testWidgets('redirects to /auth from /settings', (tester) async {
          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          router.go('/settings');
          await tester.pumpAndSettle();

          expect(router.routerDelegate.currentConfiguration.uri.path, '/auth');
        });
      });

      group('authenticated user without onboarding', () {
        setUp(() {
          authState.login();
        });

        testWidgets('redirects to /onboarding from home', (tester) async {
          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          expect(
            router.routerDelegate.currentConfiguration.uri.path,
            '/onboarding',
          );
          // Real OnboardingScreen shows "Create Your First Aquarium" as first step
          expect(find.text('Create Your First Aquarium'), findsOneWidget);
        });

        testWidgets('redirects to /onboarding from /auth', (tester) async {
          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          router.go('/auth');
          await tester.pumpAndSettle();

          expect(
            router.routerDelegate.currentConfiguration.uri.path,
            '/onboarding',
          );
        });

        testWidgets('can stay on /onboarding', (tester) async {
          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          router.go('/onboarding');
          await tester.pumpAndSettle();

          expect(
            router.routerDelegate.currentConfiguration.uri.path,
            '/onboarding',
          );
        });

        testWidgets('redirects to /onboarding from /calendar', (tester) async {
          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          router.go('/calendar');
          await tester.pumpAndSettle();

          expect(
            router.routerDelegate.currentConfiguration.uri.path,
            '/onboarding',
          );
        });
      });

      group('authenticated user with completed onboarding', () {
        setUp(() {
          authState.login();
          authState.completeOnboarding();
        });

        testWidgets('can access home (/)', (tester) async {
          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          expect(router.routerDelegate.currentConfiguration.uri.path, '/');
          expect(find.text('Home'), findsOneWidget);
        });

        testWidgets('redirects to / from /auth', (tester) async {
          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          router.go('/auth');
          await tester.pumpAndSettle();

          expect(router.routerDelegate.currentConfiguration.uri.path, '/');
        });

        testWidgets('redirects to / from /onboarding', (tester) async {
          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          router.go('/onboarding');
          await tester.pumpAndSettle();

          expect(router.routerDelegate.currentConfiguration.uri.path, '/');
        });

        testWidgets('can access /calendar', (tester) async {
          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          router.go('/calendar');
          await tester.pumpAndSettle();

          expect(
            router.routerDelegate.currentConfiguration.uri.path,
            '/calendar',
          );
          // CalendarScreen shows TableCalendar and "Today" for selected day
          expect(find.byType(TableCalendar<dynamic>), findsOneWidget);
        });

        testWidgets('can access /profile', (tester) async {
          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          router.go('/profile');
          await tester.pumpAndSettle();

          expect(
            router.routerDelegate.currentConfiguration.uri.path,
            '/profile',
          );
          expect(find.text('Profile'), findsOneWidget);
        });

        testWidgets('can access /settings', (tester) async {
          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          router.go('/settings');
          await tester.pumpAndSettle();

          expect(
            router.routerDelegate.currentConfiguration.uri.path,
            '/settings',
          );
          expect(find.text('Settings'), findsOneWidget);
        });

        testWidgets('can access /aquarium', (tester) async {
          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          router.go('/aquarium');
          await tester.pumpAndSettle();

          expect(
            router.routerDelegate.currentConfiguration.uri.path,
            '/aquarium',
          );
          expect(find.text('My Aquarium'), findsOneWidget);
        });

        testWidgets('can access /aquarium/fish/:fishId/edit with parameter',
            (tester) async {
          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          router.go('/aquarium/fish/test-fish-1/edit');
          await tester.pumpAndSettle();

          expect(
            router.routerDelegate.currentConfiguration.uri.path,
            '/aquarium/fish/test-fish-1/edit',
          );
          expect(find.text('Edit Fish'), findsOneWidget);
        });
      });

      group('reactive updates on auth state change', () {
        testWidgets('redirects to / after login + onboarding', (tester) async {
          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          // Initially on /auth
          expect(router.routerDelegate.currentConfiguration.uri.path, '/auth');

          // Login
          authState.login();
          await tester.pumpAndSettle();

          // Should be on /onboarding now
          expect(
            router.routerDelegate.currentConfiguration.uri.path,
            '/onboarding',
          );

          // Complete onboarding
          authState.completeOnboarding();
          await tester.pumpAndSettle();

          // Should be on home now
          expect(router.routerDelegate.currentConfiguration.uri.path, '/');
        });

        testWidgets('redirects to /auth after logout', (tester) async {
          // Start logged in with onboarding complete
          authState.login();
          authState.completeOnboarding();

          await tester.pumpWidget(_buildApp(router));
          await tester.pumpAndSettle();

          // Should be on home
          expect(router.routerDelegate.currentConfiguration.uri.path, '/');

          // Logout
          authState.logout();
          await tester.pumpAndSettle();

          // Should redirect to /auth
          expect(router.routerDelegate.currentConfiguration.uri.path, '/auth');
        });
      });
    });
  });

  group('PlaceholderScreen', () {
    testWidgets('displays title in app bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PlaceholderScreen(title: 'Test'),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('displays "FishFeed - {title}" text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PlaceholderScreen(title: 'Test'),
        ),
      );

      expect(find.text('FishFeed - Test'), findsOneWidget);
    });

    testWidgets('displays correct icon for Home', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PlaceholderScreen(title: 'Home'),
        ),
      );

      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('displays correct icon for Auth', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PlaceholderScreen(title: 'Auth'),
        ),
      );

      expect(find.byIcon(Icons.login), findsOneWidget);
    });

    testWidgets('displays correct icon for Calendar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PlaceholderScreen(title: 'Calendar'),
        ),
      );

      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    });
  });
}

late MockAuthRepository mockAuthRepository;
late MockUserRepository mockUserRepository;
late MockGoogleAuthService mockGoogleAuthService;
late MockAppleAuthService mockAppleAuthService;

final _testUser = User(
  id: 'test-user-123',
  email: 'test@example.com',
  displayName: 'Test User',
  createdAt: DateTime(2024, 1, 15),
  subscriptionStatus: const SubscriptionStatus.free(),
  freeAiScansRemaining: 5,
);

Widget _buildApp(GoRouter router) {
  mockAuthRepository = MockAuthRepository();
  mockUserRepository = MockUserRepository();
  mockGoogleAuthService = MockGoogleAuthService();
  mockAppleAuthService = MockAppleAuthService();

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockAuthRepository),
      userRepositoryProvider.overrideWithValue(mockUserRepository),
      googleAuthServiceProvider.overrideWithValue(mockGoogleAuthService),
      appleAuthServiceProvider.overrideWithValue(mockAppleAuthService),
      // Mock aquarium remote data source for authNotifierProvider
      aquariumRemoteDataSourceProvider
          .overrideWithValue(createMockAquariumRemoteDataSource()),
      // Mock calendar and feeding providers to prevent infinite rebuild loops
      calendarDataProvider.overrideWith((ref) => MockCalendarDataNotifier()),
      todayFeedingsProvider.overrideWith((ref) => MockTodayFeedingsNotifier()),
      // Provide a test user for ProfileScreen
      currentUserProvider.overrideWithValue(_testUser),
      // Mock SyncService to prevent conflicts with ConflictResolutionListener
      syncServiceProvider.overrideWithValue(createMockSyncService()),
      // Mock sync state provider to prevent infinite loop in SyncStatusIndicator
      syncStateProvider.overrideWith((ref) async* {
        yield SyncState.idle;
      }),
      // Mock fish management provider for aquarium screens
      fishManagementProvider.overrideWith((ref) => MockFishManagementNotifier()),
      // Mock user aquariums provider to avoid HiveBoxes dependency
      userAquariumsProvider.overrideWith((ref) => MockUserAquariumsNotifier()),
      // Mock fishByIdProvider for EditFishScreen
      fishByIdProvider.overrideWith((ref, fishId) {
        if (fishId == 'test-fish-1') {
          return Fish(
            id: 'test-fish-1',
            aquariumId: 'test-aquarium',
            speciesId: 'guppy',
            name: 'My Guppy',
            quantity: 3,
            addedAt: DateTime(2024, 1, 15),
          );
        }
        return null;
      }),
    ],
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}
