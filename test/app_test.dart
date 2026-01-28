import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/app.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/repositories/auth_repository_impl.dart';
import 'package:fishfeed/services/auth/apple_auth_service.dart';
import 'package:fishfeed/services/auth/google_auth_service.dart';
import 'package:fishfeed/services/connectivity/connectivity_service.dart';
import 'package:fishfeed/services/lifecycle/app_lifecycle_service.dart';
import 'package:fishfeed/services/push/push_token_manager.dart';
import 'package:fishfeed/services/sentry/sentry_user_sync.dart';
import 'package:fishfeed/services/sync/sync_service.dart';
import 'package:fishfeed/services/sync/sync_trigger_service.dart';
import 'package:fishfeed/data/datasources/remote/aquarium_remote_ds.dart';

import 'helpers/test_helpers.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockGoogleAuthService mockGoogleAuthService;
  late MockAppleAuthService mockAppleAuthService;
  late MockPushTokenManager mockPushTokenManager;
  late MockSyncService mockSyncService;
  late MockConnectivityService mockConnectivityService;
  late MockAppLifecycleService mockAppLifecycleService;
  late MockSyncTriggerService mockSyncTriggerService;
  late MockAquariumRemoteDataSource mockAquariumRemoteDataSource;

  setUpAll(() {
    setupTestFonts();
  });

  tearDownAll(() {
    teardownTestFonts();
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockGoogleAuthService = MockGoogleAuthService();
    mockAppleAuthService = MockAppleAuthService();
    mockPushTokenManager = createMockPushTokenManager();
    mockSyncService = createMockSyncService();
    mockConnectivityService = createMockConnectivityService();
    mockAppLifecycleService = createMockAppLifecycleService();
    mockSyncTriggerService = createMockSyncTriggerService();
    mockAquariumRemoteDataSource = createMockAquariumRemoteDataSource();

    // Setup default mock behavior - unauthenticated user
    when(
      () => mockAuthRepository.isAuthenticated(),
    ).thenAnswer((_) async => false);
    when(
      () => mockAuthRepository.getCurrentUser(),
    ).thenAnswer((_) async => const Left(CacheFailure()));
  });

  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        // Auth and repository mocks
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        googleAuthServiceProvider.overrideWithValue(mockGoogleAuthService),
        appleAuthServiceProvider.overrideWithValue(mockAppleAuthService),
        pushTokenManagerProvider.overrideWithValue(mockPushTokenManager),
        aquariumRemoteDataSourceProvider.overrideWithValue(
          mockAquariumRemoteDataSource,
        ),

        // Service mocks required by FishFeedApp listeners
        syncServiceProvider.overrideWithValue(mockSyncService),
        connectivityServiceProvider.overrideWithValue(mockConnectivityService),
        appLifecycleServiceProvider.overrideWithValue(mockAppLifecycleService),
        syncTriggerServiceProvider.overrideWithValue(mockSyncTriggerService),

        // Connectivity providers
        isOnlineProvider.overrideWith((ref) async* {
          yield true;
        }),

        // Lifecycle events provider (empty stream)
        lifecycleEventsProvider.overrideWith((ref) async* {
          // Don't emit anything
        }),

        // Sentry user sync (no-op)
        sentryUserSyncProvider.overrideWith((ref) => null),

        // Push token auth sync (no-op)
        pushTokenAuthSyncProvider.overrideWith((ref) => null),
      ],
      child: const FishFeedApp(),
    );
  }

  group('FishFeedApp', () {
    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('uses MaterialApp.router', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.routerConfig, isNotNull);
    });

    testWidgets('has correct app title', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'FishFeed');
    });

    testWidgets('debug banner is hidden', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.debugShowCheckedModeBanner, false);
    });

    testWidgets('has light and dark themes configured', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
    });

    testWidgets('uses ThemeMode.system', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.system);
    });

    testWidgets('displays auth screen initially (user not logged in)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // The router should redirect to auth screen for unauthenticated users
      expect(find.byType(Scaffold), findsOneWidget);
      // LoginScreen shows welcome message and login button
      expect(find.text('Welcome to FishFeed'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('applies AppTheme.lightTheme correctly', (
      WidgetTester tester,
    ) async {
      // Simulate light mode
      tester.view.platformDispatcher.platformBrightnessTestValue =
          Brightness.light;

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      final theme = Theme.of(context);

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, const Color(0xFF1565C0));

      // Reset
      tester.view.platformDispatcher.clearPlatformBrightnessTestValue();
    });

    testWidgets('applies AppTheme.darkTheme correctly', (
      WidgetTester tester,
    ) async {
      // Simulate dark mode
      tester.view.platformDispatcher.platformBrightnessTestValue =
          Brightness.dark;

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      final theme = Theme.of(context);

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, const Color(0xFF64B5F6));

      // Reset
      tester.view.platformDispatcher.clearPlatformBrightnessTestValue();
    });
  });

  group('AppRouter integration', () {
    testWidgets('GoRouter is properly connected', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // GoRouter creates a Navigator internally
      expect(find.byType(Navigator), findsOneWidget);
    });

    testWidgets('initial route redirects to auth for unauthenticated user', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Unauthenticated users should be redirected to auth (LoginScreen)
      expect(find.text('Log In'), findsOneWidget);
    });
  });
}
