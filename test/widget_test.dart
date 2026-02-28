import 'package:dartz/dartz.dart';
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
import 'package:fishfeed/presentation/providers/image_upload_provider.dart';

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

    when(
      () => mockAuthRepository.isAuthenticated(),
    ).thenAnswer((_) async => false);
    when(
      () => mockAuthRepository.getCurrentUser(),
    ).thenAnswer((_) async => const Left(CacheFailure()));
  });

  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Auth and repository mocks
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          googleAuthServiceProvider.overrideWithValue(mockGoogleAuthService),
          appleAuthServiceProvider.overrideWithValue(mockAppleAuthService),
          pushTokenManagerProvider.overrideWithValue(mockPushTokenManager),

          // Service mocks required by FishFeedApp listeners
          syncServiceProvider.overrideWithValue(mockSyncService),
          connectivityServiceProvider.overrideWithValue(
            mockConnectivityService,
          ),
          appLifecycleServiceProvider.overrideWithValue(
            mockAppLifecycleService,
          ),
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

          // Image upload notifier (no-op)
          imageUploadNotifierProvider.overrideWith(
            (ref) => MockImageUploadNotifier(),
          ),
        ],
        child: const FishFeedApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Unauthenticated users are redirected to auth screen (LoginScreen)
    expect(find.text('Welcome to FishFeed'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
