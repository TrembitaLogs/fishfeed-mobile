// End-to-end integration test that runs against a real backend.
//
// Drives the UI through: register -> onboard -> home -> verify sync.
// Requires a running backend at http://10.0.2.2:8000 (Android emulator).
//
// Run with:
//   flutter test integration_test/e2e_api_test.dart -d emulator-5554

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/app.dart';
import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/presentation/providers/ad_provider.dart';
import 'package:fishfeed/presentation/providers/image_upload_provider.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/services/auth/apple_auth_service.dart';
import 'package:fishfeed/services/auth/google_auth_service.dart';
import 'package:fishfeed/services/lifecycle/app_lifecycle_service.dart';
import 'package:fishfeed/services/push/push_token_manager.dart';
import 'package:fishfeed/services/sentry/sentry_user_sync.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

// ---------------------------------------------------------------------------
// Mocks — only external services that require Firebase / RevenueCat / etc.
// ---------------------------------------------------------------------------

class _MockGoogleAuthService extends Mock implements GoogleAuthService {}

class _MockAppleAuthService extends Mock implements AppleAuthService {}

class _MockAppLifecycleService extends Mock implements AppLifecycleService {}

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

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _apiBaseUrl = 'http://10.0.2.2:8000';
const _testPassword = 'TestPass1!';
const _aquariumName = 'E2E Test Tank';

// Generous timeouts for real API calls.
const _settleTimeout = Duration(seconds: 30);
const _pumpInterval = Duration(milliseconds: 100);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Generates a unique email for each test run.
String _uniqueEmail() =>
    'e2e_${DateTime.now().millisecondsSinceEpoch}@test.com';

/// Pumps until the widget tree settles or the timeout expires.
///
/// Wraps [WidgetTester.pumpAndSettle] with our generous timeout constants.
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle(
    _pumpInterval,
    EnginePhase.sendSemanticsUpdate,
    _settleTimeout,
  );
}

/// Pumps frames for [duration] to let async work complete without requiring
/// full settle (useful when animations loop indefinitely).
Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

// ---------------------------------------------------------------------------
// Test App Bootstrap (real auth, real sync, mock externals)
// ---------------------------------------------------------------------------

Directory? _tempDir;

Future<void> _initE2eApp(
  WidgetTester tester, {
  List<Override> extraOverrides = const [],
}) async {
  // Environment — point at real backend
  dotenv.testLoad(fileInput: 'API_BASE_URL=$_apiBaseUrl');

  // Fonts — avoid runtime Google Fonts fetch
  GoogleFonts.config.allowRuntimeFetching = false;
  AppTheme.useDefaultFonts = true;

  // Hive — use temp directory
  _tempDir = await Directory.systemTemp.createTemp('fishfeed_e2e_');
  Hive.init(_tempDir!.path);
  await HiveBoxes.initForTesting();

  // Mock external services that need Firebase / RevenueCat / etc.
  final lifecycleService = _MockAppLifecycleService();
  when(() => lifecycleService.isInitialized).thenReturn(true);
  when(() => lifecycleService.eventStream)
      .thenAnswer((_) => const Stream.empty());
  when(() => lifecycleService.initialize()).thenReturn(null);
  when(() => lifecycleService.dispose()).thenReturn(null);

  final pushTokenManager = _MockPushTokenManager();
  when(
    () => pushTokenManager.onAuthStateChanged(
      isAuthenticated: any(named: 'isAuthenticated'),
    ),
  ).thenAnswer((_) async {});

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // External services — mock (no Firebase / RevenueCat / PostHog)
        googleAuthServiceProvider.overrideWithValue(_MockGoogleAuthService()),
        appleAuthServiceProvider.overrideWithValue(_MockAppleAuthService()),
        appLifecycleServiceProvider.overrideWithValue(lifecycleService),
        pushTokenManagerProvider.overrideWithValue(pushTokenManager),

        // No-op providers that depend on Firebase / Sentry / etc.
        sentryUserSyncProvider.overrideWith((ref) {}),
        pushTokenAuthSyncProvider.overrideWith((ref) {}),
        imageUploadNotifierProvider.overrideWith(
          (ref) => _MockImageUploadNotifier(),
        ),

        // Subscription / ads — free tier
        subscriptionStatusProvider.overrideWithValue(
          const SubscriptionStatus.free(),
        ),
        isPremiumProvider.overrideWithValue(false),
        shouldShowAdsProvider.overrideWithValue(false),

        // DO NOT override auth providers — they stay real so the full
        // register/login flow goes through the actual backend API.

        ...extraOverrides,
      ],
      child: const FishFeedApp(),
    ),
  );

  // Wait for the splash screen / auth initialization to complete.
  // Use pumpFor first since animations may loop indefinitely during init.
  await _pumpFor(tester, const Duration(seconds: 3));
  try {
    await _settle(tester);
  } catch (_) {
    // If pumpAndSettle times out, that's fine — we'll pump manually.
  }
}

Future<void> _tearDownE2eApp() async {
  AppTheme.useDefaultFonts = false;

  if (HiveBoxes.isInitialized) {
    await HiveBoxes.close();
  }

  if (_tempDir != null && _tempDir!.existsSync()) {
    _tempDir!.deleteSync(recursive: true);
    _tempDir = null;
  }
}

// ---------------------------------------------------------------------------
// Test
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(_tearDownE2eApp);

  testWidgets('E2E: register -> onboard -> home -> verify sync',
      (tester) async {
    final testEmail = _uniqueEmail();
    String? accessToken;

    // ======================================================================
    // 1. Start the app — should land on LoginScreen (not authenticated)
    // ======================================================================
    await _initE2eApp(tester);

    // The router should redirect to /auth since we are not authenticated.
    // Look for the Register text link that appears on the login screen.
    await _pumpFor(tester, const Duration(seconds: 2));
    try {
      await _settle(tester);
    } catch (_) {}

    // Verify we are on the login screen.
    expect(
      find.text('Register'),
      findsWidgets,
      reason: 'Expected to find "Register" link on login screen',
    );

    // ======================================================================
    // 2. Navigate to register screen
    // ======================================================================
    // Tap the "Register" TextButton (the registration link).
    final registerLink = find.text('Register');
    await tester.tap(registerLink.last);
    await _pumpFor(tester, const Duration(seconds: 1));
    try {
      await _settle(tester);
    } catch (_) {}

    // Verify we are on the register screen.
    expect(
      find.text('Create Account'),
      findsWidgets,
      reason: 'Expected to find "Create Account" on register screen',
    );

    // ======================================================================
    // 3. Fill in registration form
    // ======================================================================

    // Enter email
    final emailField = find.widgetWithText(TextFormField, 'Email');
    expect(emailField, findsOneWidget, reason: 'Email field not found');
    await tester.enterText(emailField, testEmail);
    await tester.pump();

    // Enter password — find by label "Password" but NOT "Confirm Password".
    // There are two password fields; we want the first one.
    final passwordFields = find.widgetWithText(TextFormField, 'Password');
    expect(
      passwordFields,
      findsWidgets,
      reason: 'Password fields not found',
    );
    await tester.enterText(passwordFields.first, _testPassword);
    await tester.pump();

    // Enter confirm password
    final confirmPasswordField =
        find.widgetWithText(TextFormField, 'Confirm Password');
    expect(
      confirmPasswordField,
      findsOneWidget,
      reason: 'Confirm Password field not found',
    );
    await tester.enterText(confirmPasswordField, _testPassword);
    await tester.pump();

    // Accept Terms of Service — tap the checkbox.
    final checkbox = find.byType(Checkbox);
    expect(checkbox, findsOneWidget, reason: 'Terms checkbox not found');
    await tester.tap(checkbox);
    await tester.pump();

    // ======================================================================
    // 4. Submit registration
    // ======================================================================
    // Scroll down if needed to make the "Create Account" button visible.
    final createAccountBtn = find.text('Create Account');
    // The header also says "Create Account", so the button may be the last.
    // Tap the one that is a FilledButton or AppButton descendant.
    // We'll use the last occurrence which is the button (not the header).
    await tester.tap(createAccountBtn.last);

    // Wait for the API call to complete and the router to redirect.
    await _pumpFor(tester, const Duration(seconds: 5));
    try {
      await _settle(tester);
    } catch (_) {}

    // ======================================================================
    // 5. Onboarding — Step 0: Aquarium Name
    // ======================================================================
    // After registration, the router should redirect to /onboarding.
    // Step 0 shows "Create Your First Aquarium" or similar, with a name
    // input and a "Next" button.

    // Wait a bit for the onboarding screen to appear.
    await _pumpFor(tester, const Duration(seconds: 2));
    try {
      await _settle(tester);
    } catch (_) {}

    // Find the aquarium name text field and enter a name.
    // The field has a hint text from l10n.aquariumNameHint and a prefix icon.
    final aquariumNameField = find.byType(TextFormField);
    expect(
      aquariumNameField,
      findsWidgets,
      reason: 'Expected TextFormField on aquarium name step',
    );
    // The first TextFormField should be the aquarium name.
    await tester.enterText(aquariumNameField.first, _aquariumName);
    await tester.pump();

    // Tap "Next" to create aquarium and proceed.
    final nextBtn = find.text('Next');
    expect(nextBtn, findsOneWidget, reason: '"Next" button not found on step 0');
    await tester.tap(nextBtn);

    // This creates the aquarium via API — wait for it.
    await _pumpFor(tester, const Duration(seconds: 5));
    try {
      await _settle(tester);
    } catch (_) {}

    // ======================================================================
    // 6. Onboarding — Step 1: Species Selection
    // ======================================================================
    // Select the "I don't know my species" option for simplicity.
    // This is a card with the text "I don't know my species".
    final unknownSpeciesOption = find.text("I don't know my species");
    // If species haven't loaded yet, pump a bit more.
    if (unknownSpeciesOption.evaluate().isEmpty) {
      await _pumpFor(tester, const Duration(seconds: 3));
      try {
        await _settle(tester);
      } catch (_) {}
    }

    expect(
      unknownSpeciesOption,
      findsOneWidget,
      reason: '"I don\'t know my species" option not found',
    );
    await tester.tap(unknownSpeciesOption);
    await tester.pump();

    // Tap "Next" to proceed to quantity step.
    final nextBtnStep1 = find.text('Next');
    expect(
      nextBtnStep1,
      findsOneWidget,
      reason: '"Next" button not found on step 1',
    );
    await tester.tap(nextBtnStep1);
    await _pumpFor(tester, const Duration(seconds: 1));
    try {
      await _settle(tester);
    } catch (_) {}

    // ======================================================================
    // 7. Onboarding — Step 2: Quantity
    // ======================================================================
    // Default quantity is 1, which is fine. Just tap "Next".
    expect(
      find.text('How many fish?'),
      findsOneWidget,
      reason: 'Expected "How many fish?" heading on quantity step',
    );

    final nextBtnStep2 = find.text('Next');
    expect(
      nextBtnStep2,
      findsOneWidget,
      reason: '"Next" button not found on step 2',
    );
    await tester.tap(nextBtnStep2);
    await _pumpFor(tester, const Duration(seconds: 1));
    try {
      await _settle(tester);
    } catch (_) {}

    // ======================================================================
    // 8. Onboarding — Step 3: Schedule Preview
    // ======================================================================
    // The schedule is auto-generated. Just tap "Next".
    final nextBtnStep3 = find.text('Next');
    expect(
      nextBtnStep3,
      findsOneWidget,
      reason: '"Next" button not found on step 3',
    );
    await tester.tap(nextBtnStep3);
    await _pumpFor(tester, const Duration(seconds: 1));
    try {
      await _settle(tester);
    } catch (_) {}

    // ======================================================================
    // 9. Onboarding — Step 4: Add More Aquarium
    // ======================================================================
    // This is the final step. Tap "Get Started" to finish onboarding.
    final getStartedBtn = find.text('Get Started');
    expect(
      getStartedBtn,
      findsOneWidget,
      reason: '"Get Started" button not found on step 4',
    );
    await tester.tap(getStartedBtn);

    // Wait for onboarding completion, notification permission dialog (may or
    // may not appear), sync, and router redirect to home.
    await _pumpFor(tester, const Duration(seconds: 8));
    try {
      await _settle(tester);
    } catch (_) {}

    // If a system permission dialog appeared, it will block the UI.
    // The NotificationService.requestPermissions() is called but may
    // not show a dialog in the test environment. Give extra pump time.
    await _pumpFor(tester, const Duration(seconds: 3));
    try {
      await _settle(tester);
    } catch (_) {}

    // ======================================================================
    // 10. Verify Home Screen
    // ======================================================================
    // The home screen should show our aquarium name somewhere.
    // The greeting in the AppBar contains the user name, and the TodayView
    // shows aquarium cards.

    // Give the home screen time to load data.
    await _pumpFor(tester, const Duration(seconds: 3));
    try {
      await _settle(tester);
    } catch (_) {}

    // Check that the aquarium name appears on screen.
    expect(
      find.textContaining(_aquariumName),
      findsWidgets,
      reason:
          'Expected aquarium name "$_aquariumName" to appear on home screen',
    );

    // ======================================================================
    // 11. Trigger sync explicitly and wait for it to complete
    // ======================================================================
    // Onboarding creates data in Hive locally. The automatic sync may not
    // trigger in the test environment (mocked AppLifecycleService), so we
    // trigger it explicitly via the SyncService provider.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp).first),
    );
    final syncService = container.read(syncServiceProvider);
    await syncService.syncNow();
    await _pumpFor(tester, const Duration(seconds: 5));

    // ======================================================================
    // 12. Backend Verification — direct HTTP check
    // ======================================================================

    final verifyDio = Dio(
      BaseOptions(
        baseUrl: _apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    try {
      // Login with the same credentials to get an access token.
      final loginResponse = await verifyDio.post<Map<String, dynamic>>(
        '/api/v1/auth/login',
        data: <String, dynamic>{
          'email': testEmail,
          'password': _testPassword,
        },
      );
      expect(loginResponse.statusCode, 200);
      accessToken = loginResponse.data!['access_token'] as String?;
      expect(accessToken, isNotNull, reason: 'Access token should be present');

      // Verify aquarium was synced to backend.
      // Retry a few times since sync is async and may still be in progress.
      verifyDio.options.headers['Authorization'] = 'Bearer $accessToken';
      List<dynamic> aquariums = [];
      for (var attempt = 0; attempt < 5; attempt++) {
        final aquariumsResponse =
            await verifyDio.get<List<dynamic>>('/api/v1/aquariums');
        expect(aquariumsResponse.statusCode, 200);
        aquariums = aquariumsResponse.data!;
        if (aquariums.isNotEmpty) break;
        // Wait and pump to give sync more time
        await _pumpFor(tester, const Duration(seconds: 3));
      }
      expect(
        aquariums,
        isNotEmpty,
        reason: 'Backend should have at least one aquarium after onboarding',
      );

      // Find our aquarium by name.
      final ourAquarium = aquariums.firstWhere(
        (a) => (a as Map<String, dynamic>)['name'] == _aquariumName,
        orElse: () => null,
      );
      expect(
        ourAquarium,
        isNotNull,
        reason:
            'Backend should have aquarium "$_aquariumName" after onboarding',
      );
    } finally {
      verifyDio.close();
    }

    // ======================================================================
    // Test passed — user registered, onboarded, and data synced to backend.
    // ======================================================================
  });
}
