import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/data/repositories/user_repository_impl.dart';
import 'package:fishfeed/domain/entities/calendar_month_data.dart';
import 'package:fishfeed/domain/entities/day_feeding_status.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/repositories/auth_repository.dart';
import 'package:fishfeed/domain/repositories/user_repository.dart';
import 'package:fishfeed/data/repositories/auth_repository_impl.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/ad_provider.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/calendar_data_provider.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/screens/home/home_screen.dart';
import 'package:fishfeed/core/di/repository_providers.dart';
import 'package:fishfeed/domain/repositories/aquarium_repository.dart';
import 'package:fishfeed/services/auth/apple_auth_service.dart';
import 'package:fishfeed/services/auth/google_auth_service.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/water_type.dart';

import '../../../helpers/test_helpers.dart' show createMockSyncService;

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockGoogleAuthService extends Mock implements GoogleAuthService {}

class MockAppleAuthService extends Mock implements AppleAuthService {}

class MockAquariumRepository extends Mock implements AquariumRepository {}

/// Mock UserAquariumsNotifier that doesn't make async calls.
class MockUserAquariumsNotifier extends StateNotifier<UserAquariumsState>
    implements UserAquariumsNotifier {
  MockUserAquariumsNotifier()
    : super(UserAquariumsState(aquariums: _defaultAquariums));

  static final _defaultAquariums = [
    Aquarium(
      id: 'test-aquarium',
      userId: 'user-123',
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
    String? photoKey,
    bool clearPhotoKey = false,
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
  Future<void> loadMonth(int year, int month) async {
    // No-op for tests
  }

  @override
  DayFeedingStatus getDayStatus(DateTime day) {
    return DayFeedingStatus.noData;
  }

  @override
  Future<void> refresh() async {
    // No-op for tests
  }
}

/// Mock notifier that extends StateNotifier directly to avoid constructor deps.
class MockTodayFeedingsNotifier extends StateNotifier<TodayFeedingsState>
    implements TodayFeedingsNotifier {
  MockTodayFeedingsNotifier()
    : super(const TodayFeedingsState(feedings: [], isLoading: false));

  @override
  Future<void> loadFeedings() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> markAsFed(String scheduleId) async {
    final updatedFeedings = state.feedings.map((f) {
      if (f.scheduleId == scheduleId) {
        return f.copyWith(status: EventStatus.fed);
      }
      return f;
    }).toList();
    state = state.copyWith(feedings: updatedFeedings);
  }

  @override
  Future<void> markAsMissed(String scheduleId) async {
    final updatedFeedings = state.feedings.map((f) {
      if (f.scheduleId == scheduleId) {
        return f.copyWith(status: EventStatus.skipped);
      }
      return f;
    }).toList();
    state = state.copyWith(feedings: updatedFeedings);
  }

  @override
  void updateFeedingStatus(String scheduleId, EventStatus newStatus) {
    final updatedFeedings = state.feedings.map((f) {
      if (f.scheduleId == scheduleId) {
        return f.copyWith(status: newStatus);
      }
      return f;
    }).toList();
    state = state.copyWith(feedings: updatedFeedings);
  }

  @override
  void clearError() {
    state = state.copyWith(error: null);
  }
}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockUserRepository mockUserRepository;
  late MockGoogleAuthService mockGoogleAuthService;
  late MockAppleAuthService mockAppleAuthService;
  late MockAquariumRepository mockAquariumRepo;

  final testUser = User(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'TestUser',
    createdAt: DateTime(2024, 1, 15),
    subscriptionStatus: const SubscriptionStatus.free(),
    freeAiScansRemaining: 5,
  );

  final testUserNoDisplayName = User(
    id: 'user-456',
    email: 'john.doe@example.com',
    displayName: null,
    createdAt: DateTime(2024, 1, 15),
    subscriptionStatus: const SubscriptionStatus.free(),
    freeAiScansRemaining: 5,
  );

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUserRepository = MockUserRepository();
    mockGoogleAuthService = MockGoogleAuthService();
    mockAppleAuthService = MockAppleAuthService();
    mockAquariumRepo = MockAquariumRepository();

    // Setup mock to return empty list by default
    when(
      () => mockAquariumRepo.getCachedAquariums(),
    ).thenReturn(const Right([]));
  });

  Widget buildTestWidget({User? user, List<ComputedFeedingEvent>? feedings}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        userRepositoryProvider.overrideWithValue(mockUserRepository),
        googleAuthServiceProvider.overrideWithValue(mockGoogleAuthService),
        appleAuthServiceProvider.overrideWithValue(mockAppleAuthService),
        todayFeedingsProvider.overrideWith((ref) {
          final notifier = MockTodayFeedingsNotifier();
          if (feedings != null) {
            notifier.state = TodayFeedingsState(
              feedings: feedings,
              isLoading: false,
            );
          }
          return notifier;
        }),
        // Mock calendar data provider to prevent infinite rebuild loop
        calendarDataProvider.overrideWith((ref) => MockCalendarDataNotifier()),
        // Mock subscription status to prevent PurchaseService initialization
        subscriptionStatusProvider.overrideWithValue(
          const SubscriptionStatus.free(),
        ),
        isPremiumProvider.overrideWithValue(false),
        shouldShowAdsProvider.overrideWithValue(false),
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
        if (user != null)
          authNotifierProvider.overrideWith((ref) {
            final notifier = AuthNotifier(
              repository: mockAuthRepository,
              googleAuthService: mockGoogleAuthService,
              appleAuthService: mockAppleAuthService,
              aquariumRepository: mockAquariumRepo,
              syncService: createMockSyncService(),
            );
            // Manually set authenticated state with user
            return notifier;
          }),
        if (user != null) currentUserProvider.overrideWithValue(user),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeScreen(),
      ),
    );
  }

  group('HomeScreen', () {
    group('AppBar', () {
      testWidgets('displays greeting with user display name', (tester) async {
        await tester.pumpWidget(buildTestWidget(user: testUser));
        await tester.pumpAndSettle();

        // Should show greeting with display name
        // The exact greeting depends on time of day
        final appBar = find.byType(AppBar);
        expect(appBar, findsOneWidget);

        // Check that user name is in the title
        expect(find.textContaining('TestUser'), findsOneWidget);
      });

      testWidgets('displays greeting with email when no display name', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(user: testUserNoDisplayName));
        await tester.pumpAndSettle();

        // Should show greeting with email prefix (before @)
        expect(find.textContaining('john.doe'), findsOneWidget);
      });

      testWidgets('displays streak badge placeholder', (tester) async {
        await tester.pumpWidget(buildTestWidget(user: testUser));
        await tester.pumpAndSettle();

        // Should show fire icon (streak badge placeholder)
        expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
        // Should show streak count (0 for placeholder)
        expect(find.text('0'), findsOneWidget);
      });
    });

    group('BottomNavigationBar', () {
      testWidgets('displays 3 navigation destinations', (tester) async {
        await tester.pumpWidget(buildTestWidget(user: testUser));
        await tester.pumpAndSettle();

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationDestination), findsNWidgets(3));
      });

      testWidgets('displays correct labels for tabs', (tester) async {
        await tester.pumpWidget(buildTestWidget(user: testUser));
        await tester.pumpAndSettle();

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Calendar'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      });

      testWidgets('displays correct icons for tabs', (tester) async {
        await tester.pumpWidget(buildTestWidget(user: testUser));
        await tester.pumpAndSettle();

        // Home tab is selected by default, so it shows filled icon
        expect(find.byIcon(Icons.home), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
        expect(find.byIcon(Icons.person_outline), findsOneWidget);
      });

      testWidgets('Home tab is selected by default', (tester) async {
        await tester.pumpWidget(buildTestWidget(user: testUser));
        await tester.pumpAndSettle();

        // TodayView should be visible - shows aquarium section with mock data
        // MockUserAquariumsNotifier provides "Test Aquarium" by default
        expect(find.text('Test Aquarium'), findsOneWidget);
      });

      testWidgets('can navigate to Calendar tab', (tester) async {
        // Use a taller surface to prevent CalendarScreen overflow
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(const Size(800, 600)));

        await tester.pumpWidget(buildTestWidget(user: testUser));
        await tester.pumpAndSettle();

        // Tap Calendar tab
        await tester.tap(find.text('Calendar'));
        await tester.pumpAndSettle();

        // CalendarScreen should be visible (TableCalendar widget)
        expect(find.byType(TableCalendar<dynamic>), findsOneWidget);
      });

      testWidgets('can navigate to Profile tab', (tester) async {
        await tester.pumpWidget(buildTestWidget(user: testUser));
        await tester.pumpAndSettle();

        // Tap Profile tab
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        // ProfileScreen should be visible - check for user's display name
        expect(find.text('TestUser'), findsAtLeastNWidgets(1));
      });

      testWidgets('tab navigation preserves state with IndexedStack', (
        tester,
      ) async {
        // Use a taller surface to prevent CalendarScreen overflow
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(const Size(800, 600)));

        await tester.pumpWidget(buildTestWidget(user: testUser));
        await tester.pumpAndSettle();

        // Verify we start on Home (TodayView shows aquarium section)
        expect(find.text('Test Aquarium'), findsOneWidget);

        // Navigate to Calendar
        await tester.tap(find.text('Calendar'));
        await tester.pumpAndSettle();
        expect(find.byType(TableCalendar<dynamic>), findsOneWidget);

        // Navigate to Profile
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        // ProfileScreen should be visible - check for user's display name
        expect(find.text('TestUser'), findsAtLeastNWidgets(1));

        // Navigate back to Home
        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
        expect(find.text('Test Aquarium'), findsOneWidget);
      });
    });

    group('FloatingActionButton', () {
      testWidgets('displays FAB with add icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(user: testUser));
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
        // Icons.add appears on FAB and AddAquariumButton
        expect(find.byIcon(Icons.add), findsAtLeastNWidgets(1));
      });

      testWidgets('FAB shows coming soon dialog for AI camera', (tester) async {
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(mockAuthRepository),
              userRepositoryProvider.overrideWithValue(mockUserRepository),
              googleAuthServiceProvider.overrideWithValue(
                mockGoogleAuthService,
              ),
              appleAuthServiceProvider.overrideWithValue(mockAppleAuthService),
              todayFeedingsProvider.overrideWith((ref) {
                return MockTodayFeedingsNotifier();
              }),
              calendarDataProvider.overrideWith(
                (ref) => MockCalendarDataNotifier(),
              ),
              subscriptionStatusProvider.overrideWithValue(
                const SubscriptionStatus.free(),
              ),
              isPremiumProvider.overrideWithValue(false),
              shouldShowAdsProvider.overrideWithValue(false),
              syncServiceProvider.overrideWithValue(createMockSyncService()),
              syncStateProvider.overrideWith((ref) async* {
                yield SyncState.idle;
              }),
              userAquariumsProvider.overrideWith(
                (ref) => MockUserAquariumsNotifier(),
              ),
              authNotifierProvider.overrideWith((ref) {
                final notifier = AuthNotifier(
                  repository: mockAuthRepository,
                  googleAuthService: mockGoogleAuthService,
                  appleAuthService: mockAppleAuthService,
                  aquariumRepository: mockAquariumRepo,
                  syncService: createMockSyncService(),
                );
                return notifier;
              }),
              currentUserProvider.overrideWithValue(testUser),
            ],
            child: MaterialApp.router(
              theme: AppTheme.lightTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap FAB to show bottom sheet
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Tap "Scan with AI Camera" option in the bottom sheet
        await tester.tap(find.text('Scan with AI Camera'));
        await tester.pumpAndSettle();

        // Verify "Coming Soon" dialog is shown
        expect(find.text('Coming Soon'), findsOneWidget);
        expect(
          find.text(
            'AI fish recognition is coming soon! Stay tuned for updates.',
          ),
          findsOneWidget,
        );
      });
    });

    group('Tab placeholder content', () {
      testWidgets('TodayView shows correct empty state', (tester) async {
        await tester.pumpWidget(buildTestWidget(user: testUser));
        await tester.pumpAndSettle();

        // TodayView shows AquariumStatusCard per aquarium with "No fish" and
        // "All fed" status when there are no feedings
        expect(find.text('No fish'), findsOneWidget);
        expect(find.text('All fed'), findsOneWidget);
      });

      testWidgets('TodayView shows aquarium cards when feedings available', (
        tester,
      ) async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final testFeedings = [
          ComputedFeedingEvent(
            scheduleId: '1',
            fishId: 'fish-1',
            // Use aquariumId that matches MockUserAquariumsNotifier's default aquarium
            aquariumId: 'test-aquarium',
            scheduledFor: today.add(const Duration(hours: 8)),
            time: '08:00',
            foodType: 'Flakes',
            status: EventStatus.pending,
            fishName: 'Guppy',
            aquariumName: 'Test Aquarium',
            fishQuantity: 3,
          ),
        ];

        await tester.pumpWidget(
          buildTestWidget(user: testUser, feedings: testFeedings),
        );
        await tester.pumpAndSettle();

        // AquariumStatusCard shows aquarium name and fish count
        expect(find.text('Test Aquarium'), findsOneWidget);
        expect(find.text('3 fish'), findsOneWidget);
      });

      testWidgets('Calendar tab shows CalendarScreen', (tester) async {
        // Use a taller surface to prevent CalendarScreen overflow
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(const Size(800, 600)));

        await tester.pumpWidget(buildTestWidget(user: testUser));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Calendar'));
        await tester.pumpAndSettle();

        // CalendarScreen with TableCalendar should be visible
        expect(find.byType(TableCalendar<dynamic>), findsOneWidget);
        // Should show selected day info
        expect(find.text('Today'), findsOneWidget);
      });

      testWidgets('Profile tab shows ProfileScreen with user info', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(user: testUser));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        // ProfileScreen shows user avatar placeholder and user info
        expect(find.byIcon(Icons.person), findsAtLeastNWidgets(1));
        expect(find.text('TestUser'), findsAtLeastNWidgets(1));
        expect(find.text('test@example.com'), findsOneWidget);
      });
    });

    group('Greeting time-based logic', () {
      // Note: These tests verify the structure exists
      // Actual time-based greeting would require mocking DateTime.now()

      testWidgets('greeting contains user name', (tester) async {
        await tester.pumpWidget(buildTestWidget(user: testUser));
        await tester.pumpAndSettle();

        // Find AppBar title
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        final titleWidget = appBar.title as Text;
        expect(titleWidget.data, contains('TestUser'));
      });
    });
  });
}
