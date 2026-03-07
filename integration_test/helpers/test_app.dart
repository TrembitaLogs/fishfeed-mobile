import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/app.dart';
import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/local/species_local_ds.dart';
import 'package:fishfeed/domain/entities/calendar_month_data.dart';
import 'package:fishfeed/domain/entities/day_feeding_status.dart';
import 'package:fishfeed/domain/entities/species.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/repositories/auth_repository.dart';
import 'package:fishfeed/presentation/providers/ad_provider.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/calendar_data_provider.dart';
import 'package:fishfeed/presentation/providers/image_upload_provider.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/providers/species_provider.dart';
import 'package:fishfeed/services/auth/apple_auth_service.dart';
import 'package:fishfeed/services/auth/google_auth_service.dart';
import 'package:fishfeed/services/connectivity/connectivity_service.dart';
import 'package:fishfeed/services/lifecycle/app_lifecycle_service.dart';
import 'package:fishfeed/services/push/push_token_manager.dart';
import 'package:fishfeed/services/sentry/sentry_user_sync.dart';
import 'package:fishfeed/services/sync/sync_service.dart';
import 'package:fishfeed/services/sync/sync_trigger_service.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockGoogleAuthService extends Mock implements GoogleAuthService {}

class _MockAppleAuthService extends Mock implements AppleAuthService {}

class _MockSyncService extends Mock implements SyncService {}

class _MockConnectivityService extends Mock implements ConnectivityService {}

class _MockAppLifecycleService extends Mock implements AppLifecycleService {}

class _MockSyncTriggerService extends Mock implements SyncTriggerService {}

class _MockPushTokenManager extends Mock implements PushTokenManager {}

class _MockImageUploadNotifier extends StateNotifier<ImageUploadQueueStatus>
    implements ImageUploadNotifier {
  _MockImageUploadNotifier() : super(ImageUploadQueueStatus.empty);

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<String> queueUpload({
    required String entityType,
    required String entityId,
    required Uint8List imageBytes,
  }) async =>
      'local://mock';

  @override
  Future<void> processQueue() async {}

  @override
  Future<int> retryFailed() async => 0;

  @override
  Future<String?> getLocalImagePath(String localKey) async => null;
}

class _MockSpeciesListNotifier extends StateNotifier<SpeciesListState>
    implements SpeciesListNotifier {
  _MockSpeciesListNotifier() : super(const SpeciesListState());

  @override
  Future<void> loadAllSpecies() async {}

  @override
  Species? findById(String id) => null;

  @override
  void searchSpecies(String query) {}
}

class _MockCalendarDataNotifier extends StateNotifier<CalendarDataState>
    implements CalendarDataNotifier {
  _MockCalendarDataNotifier()
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

/// Auth state listenable that reports logged-in + onboarded.
class _TestAuthStateListenable extends ChangeNotifier
    implements AuthStateListenable {
  @override
  bool get isInitializing => false;

  @override
  bool get isLoggedIn => true;

  @override
  bool get hasCompletedOnboarding => true;
}

/// The test user for integration tests.
final integrationTestUser = User(
  id: 'test-user-123',
  email: 'test@example.com',
  displayName: 'Test User',
  createdAt: DateTime(2024, 1, 15),
  subscriptionStatus: const SubscriptionStatus.free(),
  freeAiScansRemaining: 5,
);

Directory? _tempDir;

/// Initializes and pumps the test app with seeded Hive data.
///
/// Call this in each testWidgets callback. Provider overrides mock all
/// network services; Hive-backed providers stay real.
Future<void> initTestApp(
  WidgetTester tester, {
  Future<void> Function()? seedData,
  List<Override> extraOverrides = const [],
}) async {
  // Env config — use a non-routable URL so API calls fail immediately
  // (species provider falls back to local cache / hardcoded data).
  dotenv.testLoad(fileInput: 'API_BASE_URL=http://10.0.2.2:1');

  // Font config
  GoogleFonts.config.allowRuntimeFetching = false;
  AppTheme.useDefaultFonts = true;

  // Hive in temp directory
  _tempDir = await Directory.systemTemp.createTemp('fishfeed_integration_');
  Hive.init(_tempDir!.path);
  await HiveBoxes.initForTesting();

  // Seed data
  if (seedData != null) {
    await seedData();
  }

  // Auth repository mock (bypass SecureStorage / network)
  final authRepo = _MockAuthRepository();
  when(() => authRepo.isAuthenticated()).thenAnswer((_) async => true);
  when(
    () => authRepo.getCurrentUser(),
  ).thenAnswer((_) async => Right(integrationTestUser));
  final googleAuth = _MockGoogleAuthService();
  final appleAuth = _MockAppleAuthService();

  // Mock services
  final syncService = _MockSyncService();
  when(() => syncService.hasUnsyncedFeedings).thenReturn(false);
  when(() => syncService.hasPendingOperations).thenReturn(false);
  when(() => syncService.hasUnresolvedConflicts).thenReturn(false);
  when(() => syncService.pendingConflictCount).thenReturn(0);
  when(() => syncService.pendingConflicts).thenReturn([]);
  when(() => syncService.currentState).thenReturn(SyncState.idle);
  when(() => syncService.isProcessing).thenReturn(false);
  when(() => syncService.isOnline).thenReturn(true);
  when(() => syncService.syncAll()).thenAnswer((_) async => 0);
  when(() => syncService.syncNow()).thenAnswer((_) async => 0);
  when(() => syncService.startListening()).thenAnswer((_) async {});
  when(() => syncService.stopListening()).thenReturn(null);
  when(() => syncService.dispose()).thenReturn(null);
  when(() => syncService.stateStream).thenAnswer((_) => const Stream.empty());
  when(
    () => syncService.conflictStream,
  ).thenAnswer((_) => const Stream.empty());
  when(
    () => syncService.feedingConflictStream,
  ).thenAnswer((_) => const Stream.empty());

  final connectivityService = _MockConnectivityService();
  when(() => connectivityService.isOnline).thenReturn(true);
  when(() => connectivityService.isInitialized).thenReturn(true);
  when(
    () => connectivityService.statusStream,
  ).thenAnswer((_) => const Stream.empty());
  when(() => connectivityService.initialize()).thenAnswer((_) async {});
  when(() => connectivityService.dispose()).thenReturn(null);

  final lifecycleService = _MockAppLifecycleService();
  when(() => lifecycleService.isInitialized).thenReturn(true);
  when(
    () => lifecycleService.eventStream,
  ).thenAnswer((_) => const Stream.empty());
  when(() => lifecycleService.initialize()).thenReturn(null);
  when(() => lifecycleService.dispose()).thenReturn(null);

  final syncTriggerService = _MockSyncTriggerService();
  when(() => syncTriggerService.isInitialized).thenReturn(true);
  when(() => syncTriggerService.isSyncing).thenReturn(false);
  when(() => syncTriggerService.isInCooldown).thenReturn(false);
  when(() => syncTriggerService.lastAutoSyncTime).thenReturn(null);
  when(() => syncTriggerService.remainingCooldown).thenReturn(Duration.zero);
  when(() => syncTriggerService.initialize()).thenReturn(null);
  when(() => syncTriggerService.dispose()).thenReturn(null);
  when(() => syncTriggerService.syncNow()).thenAnswer((_) async => 0);
  when(() => syncTriggerService.resetCooldown()).thenReturn(null);

  final pushTokenManager = _MockPushTokenManager();
  when(
    () => pushTokenManager.onAuthStateChanged(
      isAuthenticated: any(named: 'isAuthenticated'),
    ),
  ).thenAnswer((_) async {});

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Auth bypass — real AuthNotifier with mocked repository
        authNotifierProvider.overrideWith(
          (ref) => AuthNotifier(
            repository: authRepo,
            googleAuthService: googleAuth,
            appleAuthService: appleAuth,
            aquariumLocalDataSource: AquariumLocalDataSource(),
            authLocalDataSource: AuthLocalDataSource(),
            syncService: syncService,
          ),
        ),
        authListenableProvider.overrideWithValue(_TestAuthStateListenable()),
        currentUserProvider.overrideWithValue(integrationTestUser),

        // Network services
        syncServiceProvider.overrideWithValue(syncService),
        connectivityServiceProvider.overrideWithValue(connectivityService),
        appLifecycleServiceProvider.overrideWithValue(lifecycleService),
        syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
        pushTokenManagerProvider.overrideWithValue(pushTokenManager),

        // No-op providers
        isOnlineProvider.overrideWith((ref) async* {
          yield true;
        }),
        lifecycleEventsProvider.overrideWith((ref) async* {}),
        sentryUserSyncProvider.overrideWith((ref) {}),
        pushTokenAuthSyncProvider.overrideWith((ref) {}),
        imageUploadNotifierProvider.overrideWith(
          (ref) => _MockImageUploadNotifier(),
        ),
        syncStateProvider.overrideWith((ref) async* {
          yield SyncState.idle;
        }),

        // Calendar mock (avoid async loading)
        calendarDataProvider.overrideWith(
          (ref) => _MockCalendarDataNotifier(),
        ),

        // Species — no API calls (prevents SpeciesListNotifier from using
        // a disposed notifier after test teardown).
        speciesListProvider.overrideWith(
          (ref) => _MockSpeciesListNotifier(),
        ),
        speciesByIdProvider.overrideWith((ref, speciesId) async {
          if (speciesId.isEmpty) return null;
          final SpeciesLocalDataSource localDs =
              ref.read(speciesLocalDataSourceProvider);
          final cached = localDs.getSpeciesById(speciesId);
          return cached?.toEntity();
        }),

        // Subscription / ads
        subscriptionStatusProvider.overrideWithValue(
          const SubscriptionStatus.free(),
        ),
        isPremiumProvider.overrideWithValue(false),
        shouldShowAdsProvider.overrideWithValue(false),

        // Extra test-specific overrides
        ...extraOverrides,
      ],
      child: const FishFeedApp(),
    ),
  );

  // Wait for app to settle (auth redirect, animations).
  // Use explicit timeout; default pumpAndSettle duration (100 ms between
  // frames) is fine but we need a generous timeout for the first build.
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 15),
  );
}

/// Tears down Hive and cleans up temp directory.
///
/// Call this in tearDown() for each test.
Future<void> tearDownTestApp() async {
  AppTheme.useDefaultFonts = false;

  if (HiveBoxes.isInitialized) {
    await HiveBoxes.close();
  }

  if (_tempDir != null && _tempDir!.existsSync()) {
    _tempDir!.deleteSync(recursive: true);
    _tempDir = null;
  }
}
