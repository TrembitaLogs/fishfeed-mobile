import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/data/repositories/auth_repository_impl.dart';
import 'package:fishfeed/data/repositories/user_repository_impl.dart';
import 'package:fishfeed/domain/entities/calendar_month_data.dart';
import 'package:fishfeed/domain/entities/day_feeding_status.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/repositories/auth_repository.dart';
import 'package:fishfeed/domain/repositories/user_repository.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/ad_provider.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/calendar_data_provider.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/services/auth/apple_auth_service.dart';
import 'package:fishfeed/services/auth/google_auth_service.dart';
import 'package:fishfeed/services/connectivity/connectivity_service.dart';
import 'package:fishfeed/services/lifecycle/app_lifecycle_service.dart';
import 'package:fishfeed/services/push/push_token_manager.dart';
import 'package:fishfeed/services/sentry/sentry_user_sync.dart';
import 'package:fishfeed/services/sync/sync_service.dart';
import 'package:fishfeed/services/sync/sync_trigger_service.dart';
import 'package:fishfeed/presentation/providers/image_upload_provider.dart';
import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
// ============ Mock Classes ============

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAquariumLocalDataSource extends Mock
    implements AquariumLocalDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockUserRepository extends Mock implements UserRepository {}

class MockGoogleAuthService extends Mock implements GoogleAuthService {}

class MockAppleAuthService extends Mock implements AppleAuthService {}

class MockPushTokenManager extends Mock implements PushTokenManager {}

class MockSyncService extends Mock implements SyncService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockAppLifecycleService extends Mock implements AppLifecycleService {}

class MockSyncTriggerService extends Mock implements SyncTriggerService {}

/// Mock ImageUploadNotifier that does nothing.
class MockImageUploadNotifier extends StateNotifier<ImageUploadQueueStatus>
    implements ImageUploadNotifier {
  MockImageUploadNotifier() : super(ImageUploadQueueStatus.empty);

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<String> queueUpload({
    required String entityType,
    required String entityId,
    required Uint8List imageBytes,
  }) async => 'local://mock';

  @override
  Future<void> processQueue() async {}

  @override
  Future<int> retryFailed() async => 0;

  @override
  Future<String?> getLocalImagePath(String localKey) async => null;
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
  void updateFeedingStatus(String scheduleId, EventStatus newStatus) {}

  @override
  void clearError() {}
}

/// Test implementation of AuthStateListenable that doesn't require Riverpod.
class TestAuthStateListenable extends ChangeNotifier
    implements AuthStateListenable {
  bool _isInitializing = false;
  bool _isLoggedIn = false;
  bool _hasCompletedOnboarding = false;

  @override
  bool get isInitializing => _isInitializing;

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  void setInitializing(bool value) {
    _isInitializing = value;
    notifyListeners();
  }

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

// ============ Test User ============

final testUser = User(
  id: 'test-user-123',
  email: 'test@example.com',
  displayName: 'Test User',
  createdAt: DateTime(2024, 1, 15),
  subscriptionStatus: const SubscriptionStatus.free(),
  freeAiScansRemaining: 5,
);

// ============ Test Setup Functions ============

/// Sets up Google Fonts and AppTheme for testing.
/// Call in setUpAll().
void setupTestFonts() {
  GoogleFonts.config.allowRuntimeFetching = false;
  AppTheme.useDefaultFonts = true;
}

/// Resets font configuration after testing.
/// Call in tearDownAll().
void teardownTestFonts() {
  AppTheme.useDefaultFonts = false;
}

/// Creates a mock ConnectivityService with default behavior.
MockConnectivityService createMockConnectivityService() {
  final service = MockConnectivityService();
  when(() => service.isOnline).thenReturn(true);
  when(() => service.isInitialized).thenReturn(true);
  when(() => service.statusStream).thenAnswer((_) => const Stream.empty());
  when(() => service.initialize()).thenAnswer((_) async {});
  when(() => service.dispose()).thenReturn(null);
  return service;
}

/// Creates a mock AppLifecycleService with default behavior.
MockAppLifecycleService createMockAppLifecycleService() {
  final service = MockAppLifecycleService();
  when(() => service.isInitialized).thenReturn(true);
  when(() => service.eventStream).thenAnswer((_) => const Stream.empty());
  when(() => service.initialize()).thenReturn(null);
  when(() => service.dispose()).thenReturn(null);
  return service;
}

/// Creates a mock SyncService with default behavior.
MockSyncService createMockSyncService() {
  final service = MockSyncService();
  when(() => service.hasUnsyncedFeedings).thenReturn(false);
  when(() => service.hasPendingOperations).thenReturn(false);
  when(() => service.hasUnresolvedConflicts).thenReturn(false);
  when(() => service.pendingConflictCount).thenReturn(0);
  when(() => service.pendingConflicts).thenReturn([]);
  when(() => service.currentState).thenReturn(SyncState.idle);
  when(() => service.isProcessing).thenReturn(false);
  when(() => service.isOnline).thenReturn(true);
  when(() => service.syncAll()).thenAnswer((_) async => 0);
  when(() => service.syncNow()).thenAnswer((_) async => 0);
  when(() => service.startListening()).thenAnswer((_) async {});
  when(() => service.stopListening()).thenReturn(null);
  when(() => service.dispose()).thenReturn(null);
  when(() => service.stateStream).thenAnswer((_) => const Stream.empty());
  when(() => service.conflictStream).thenAnswer((_) => const Stream.empty());
  when(
    () => service.feedingConflictStream,
  ).thenAnswer((_) => const Stream.empty());
  return service;
}

/// Creates a mock SyncTriggerService with default behavior.
MockSyncTriggerService createMockSyncTriggerService() {
  final service = MockSyncTriggerService();
  when(() => service.isInitialized).thenReturn(true);
  when(() => service.isSyncing).thenReturn(false);
  when(() => service.isInCooldown).thenReturn(false);
  when(() => service.lastAutoSyncTime).thenReturn(null);
  when(() => service.remainingCooldown).thenReturn(Duration.zero);
  when(() => service.initialize()).thenReturn(null);
  when(() => service.dispose()).thenReturn(null);
  when(() => service.syncNow()).thenAnswer((_) async => 0);
  when(() => service.resetCooldown()).thenReturn(null);
  return service;
}

/// Creates a mock PushTokenManager with default behavior.
MockPushTokenManager createMockPushTokenManager() {
  final manager = MockPushTokenManager();
  when(
    () => manager.onAuthStateChanged(
      isAuthenticated: any(named: 'isAuthenticated'),
    ),
  ).thenAnswer((_) async {});
  return manager;
}

/// Creates a mock AquariumLocalDataSource with default behavior.
MockAquariumLocalDataSource createMockAquariumLocalDataSource() {
  final dataSource = MockAquariumLocalDataSource();
  when(() => dataSource.getAllAquariums()).thenReturn([]);
  when(() => dataSource.getAquariumsByUserId(any())).thenReturn([]);
  when(() => dataSource.getUnsyncedAquariums()).thenReturn([]);
  when(() => dataSource.getDeletedAquariums()).thenReturn([]);
  return dataSource;
}

/// Creates a mock AuthLocalDataSource with default behavior.
MockAuthLocalDataSource createMockAuthLocalDataSource() {
  final dataSource = MockAuthLocalDataSource();
  when(() => dataSource.getCurrentUser()).thenReturn(null);
  return dataSource;
}

// ============ Common Provider Overrides ============

/// Returns common provider overrides for testing apps that use FishFeedApp.
///
/// Includes mocks for all services required by FishFeedApp's listener widgets.
List<Override> getCommonAppOverrides({
  AuthRepository? authRepository,
  UserRepository? userRepository,
  GoogleAuthService? googleAuthService,
  AppleAuthService? appleAuthService,
  PushTokenManager? pushTokenManager,
  SyncService? syncService,
  ConnectivityService? connectivityService,
  AppLifecycleService? appLifecycleService,
  SyncTriggerService? syncTriggerService,
  User? currentUser,
}) {
  return [
    // Repository mocks
    if (authRepository != null)
      authRepositoryProvider.overrideWithValue(authRepository),
    if (userRepository != null)
      userRepositoryProvider.overrideWithValue(userRepository),

    // Auth service mocks
    if (googleAuthService != null)
      googleAuthServiceProvider.overrideWithValue(googleAuthService),
    if (appleAuthService != null)
      appleAuthServiceProvider.overrideWithValue(appleAuthService),

    // Push token manager mock
    if (pushTokenManager != null)
      pushTokenManagerProvider.overrideWithValue(pushTokenManager),

    // Sync and lifecycle service mocks
    if (syncService != null) syncServiceProvider.overrideWithValue(syncService),
    if (connectivityService != null)
      connectivityServiceProvider.overrideWithValue(connectivityService),
    if (appLifecycleService != null)
      appLifecycleServiceProvider.overrideWithValue(appLifecycleService),
    if (syncTriggerService != null)
      syncTriggerServiceProvider.overrideWithValue(syncTriggerService),

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

    // Calendar and feeding provider mocks
    calendarDataProvider.overrideWith((ref) => MockCalendarDataNotifier()),
    todayFeedingsProvider.overrideWith((ref) => MockTodayFeedingsNotifier()),

    // Subscription and ads mocks
    subscriptionStatusProvider.overrideWithValue(
      const SubscriptionStatus.free(),
    ),
    isPremiumProvider.overrideWithValue(false),
    shouldShowAdsProvider.overrideWithValue(false),

    // Current user
    if (currentUser != null) currentUserProvider.overrideWithValue(currentUser),
  ];
}

/// Returns common provider overrides for testing simple widgets.
///
/// Use this for widget tests that don't use FishFeedApp.
List<Override> getWidgetTestOverrides({
  AuthRepository? authRepository,
  UserRepository? userRepository,
  GoogleAuthService? googleAuthService,
  AppleAuthService? appleAuthService,
  User? currentUser,
}) {
  return [
    if (authRepository != null)
      authRepositoryProvider.overrideWithValue(authRepository),
    if (userRepository != null)
      userRepositoryProvider.overrideWithValue(userRepository),
    if (googleAuthService != null)
      googleAuthServiceProvider.overrideWithValue(googleAuthService),
    if (appleAuthService != null)
      appleAuthServiceProvider.overrideWithValue(appleAuthService),
    calendarDataProvider.overrideWith((ref) => MockCalendarDataNotifier()),
    todayFeedingsProvider.overrideWith((ref) => MockTodayFeedingsNotifier()),
    subscriptionStatusProvider.overrideWithValue(
      const SubscriptionStatus.free(),
    ),
    isPremiumProvider.overrideWithValue(false),
    shouldShowAdsProvider.overrideWithValue(false),
    if (currentUser != null) currentUserProvider.overrideWithValue(currentUser),
  ];
}

/// Creates a test MaterialApp wrapper with proper theme and localization.
Widget createTestApp({required Widget child, ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

/// Wraps a widget with ProviderScope and MaterialApp for testing.
Widget wrapForTesting({
  required Widget child,
  List<Override> overrides = const [],
  ThemeData? theme,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}
