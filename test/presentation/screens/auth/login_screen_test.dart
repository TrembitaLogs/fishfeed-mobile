import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/core/utils/utils.dart';
import 'package:fishfeed/data/repositories/auth_repository_impl.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/repositories/auth_repository.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/screens/auth/login_screen.dart';
import 'package:fishfeed/presentation/widgets/common/app_button.dart';
import 'package:fishfeed/services/auth/apple_auth_service.dart';
import 'package:fishfeed/services/auth/google_auth_service.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/models/user_model.dart';
import 'package:fishfeed/core/di/repository_providers.dart';
import 'package:fishfeed/domain/repositories/aquarium_repository.dart';
import 'package:fishfeed/services/sync/sync_service.dart';
import 'package:hive/hive.dart';
import 'dart:io';

import '../../../helpers/test_helpers.dart' show createMockSyncService;

class MockAuthRepository extends Mock implements AuthRepository {}

class MockGoogleAuthService extends Mock implements GoogleAuthService {}

class MockAppleAuthService extends Mock implements AppleAuthService {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockAquariumRepository extends Mock implements AquariumRepository {}

class _FakeUserModel extends Fake implements UserModel {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockGoogleAuthService mockGoogleAuthService;
  late MockAppleAuthService mockAppleAuthService;
  late MockAuthLocalDataSource mockAuthLocalDs;
  late MockAquariumRepository mockAquariumRepository;

  final testUser = User(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: DateTime(2024, 1, 15),
    subscriptionStatus: const SubscriptionStatus.free(),
    freeAiScansRemaining: 5,
  );

  late Directory tempDir;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
    registerFallbackValue(_FakeUserModel());
    registerFallbackValue(
      User(
        id: 'fallback',
        email: 'fallback@test.com',
        createdAt: DateTime(2024),
      ),
    );
    tempDir = await Directory.systemTemp.createTemp('login_screen_test_');
    Hive.init(tempDir.path);
    await HiveBoxes.initForTesting();
  });

  tearDownAll(() async {
    AppTheme.useDefaultFonts = false;
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockGoogleAuthService = MockGoogleAuthService();
    mockAppleAuthService = MockAppleAuthService();
    mockAuthLocalDs = MockAuthLocalDataSource();
    when(() => mockAuthLocalDs.saveUserLocally(any())).thenAnswer((_) async {});
    when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(null);

    mockAquariumRepository = MockAquariumRepository();

    // Stub AuthRepository methods called during login success flow
    when(
      () => mockAuthRepository.saveUserLocally(any()),
    ).thenAnswer((_) async {});
    when(() => mockAuthRepository.getOnboardingCompleted()).thenReturn(false);
    when(
      () => mockAuthRepository.setOnboardingCompleted(any()),
    ).thenAnswer((_) async {});
    when(() => mockAuthRepository.getLocalUser()).thenReturn(null);

    // Stub AquariumRepository for onboarding check
    when(
      () => mockAquariumRepository.getCachedAquariums(),
    ).thenReturn(const Right([]));
  });

  Widget buildTestWidget({AuthenticationState? initialState}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        googleAuthServiceProvider.overrideWithValue(mockGoogleAuthService),
        appleAuthServiceProvider.overrideWithValue(mockAppleAuthService),
        syncServiceProvider.overrideWithValue(createMockSyncService()),
        authLocalDataSourceProvider.overrideWithValue(mockAuthLocalDs),
        aquariumRepositoryProvider.overrideWithValue(mockAquariumRepository),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          return _GlobalAuthErrorListenerForTest(
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen', () {
    group('UI rendering', () {
      testWidgets('renders all required widgets', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Header
        expect(find.byIcon(Icons.pets), findsOneWidget);
        expect(find.text('Welcome to FishFeed'), findsOneWidget);

        // Email field
        expect(find.text('Email'), findsOneWidget);
        expect(find.byIcon(Icons.email_outlined), findsOneWidget);

        // Password field
        expect(find.text('Password'), findsOneWidget);
        expect(find.byIcon(Icons.lock_outlined), findsOneWidget);

        // Login button
        expect(find.text('Log In'), findsOneWidget);

        // Register link
        expect(find.text("Don't have an account?"), findsOneWidget);
        expect(find.text('Register'), findsOneWidget);

        // OAuth divider
        expect(find.text('Or continue with'), findsOneWidget);

        // Google button
        expect(find.text('Continue with Google'), findsOneWidget);
      });

      testWidgets('password field has visibility toggle', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Initially password is obscured
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

        // Tap visibility toggle
        await tester.tap(find.byIcon(Icons.visibility_outlined));
        await tester.pump();

        // Now password is visible
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      });
    });

    group('form validation', () {
      testWidgets('shows error for empty email', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter password but leave email empty
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'Password1',
        );

        // Tap login
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        expect(find.text('This field is required'), findsOneWidget);
      });

      testWidgets('shows error for invalid email format', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter invalid email
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'invalid-email',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'Password1',
        );

        // Tap login
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        expect(find.text('Invalid email format'), findsOneWidget);
      });

      testWidgets('shows error for empty password', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter email but leave password empty
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );

        // Tap login
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        expect(find.text('This field is required'), findsOneWidget);
      });

      testWidgets('shows error for weak password', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter valid email and weak password
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'weak',
        );

        // Tap login
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Password must be at least 8 characters with 1 number and 1 uppercase letter',
          ),
          findsOneWidget,
        );
      });

      testWidgets('validates email with valid format', (tester) async {
        when(
          () => mockAuthRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter valid email and password
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'Password1',
        );

        // Tap login
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        // No validation errors should appear
        expect(find.text('Invalid email format'), findsNothing);
        expect(find.text('This field is required'), findsNothing);
      });
    });

    group('login functionality', () {
      testWidgets('calls login with correct credentials', (tester) async {
        when(
          () => mockAuthRepository.login(
            email: 'test@example.com',
            password: 'Password1',
          ),
        ).thenAnswer((_) async => Right(testUser));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'Password1',
        );

        // Tap login
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        verify(
          () => mockAuthRepository.login(
            email: 'test@example.com',
            password: 'Password1',
          ),
        ).called(1);
      });

      testWidgets('shows loading indicator during login', (tester) async {
        when(
          () => mockAuthRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return Right(testUser);
        });

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'Password1',
        );

        // Tap login
        await tester.tap(find.text('Log In'));
        await tester.pump();

        // Should show loading indicators (login button + OAuth button)
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

        // Verify login button specifically shows loading
        expect(
          find.descendant(
            of: find.byType(AppButton),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );

        // Wait for login to complete
        await tester.pumpAndSettle();
      });

      testWidgets('shows snackbar on login error', (tester) async {
        when(
          () => mockAuthRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async =>
              const Left(AuthenticationFailure(message: 'Invalid credentials')),
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'Password1',
        );

        // Tap login
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        // Should show snackbar with error
        expect(find.text('Invalid credentials'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('Google OAuth', () {
      testWidgets('calls Google login when button is pressed', (tester) async {
        when(() => mockGoogleAuthService.signIn()).thenAnswer(
          (_) async => const GoogleSignInResult(
            idToken: 'google-id-token',
            email: 'test@gmail.com',
          ),
        );
        when(
          () => mockAuthRepository.oauthLogin(
            provider: any(named: 'provider'),
            idToken: any(named: 'idToken'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Continue with Google'));
        await tester.pumpAndSettle();

        verify(() => mockGoogleAuthService.signIn()).called(1);
      });

      testWidgets('shows snackbar on Google login error', (tester) async {
        when(() => mockGoogleAuthService.signIn()).thenThrow(
          const GoogleAuthException(
            GoogleAuthErrorCode.unknown,
            'Google sign-in failed',
          ),
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Continue with Google'));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('password visibility toggle', () {
      testWidgets('toggles password visibility icon on tap', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Initially visibility icon shows obscured state
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

        // Tap visibility toggle
        await tester.tap(find.byIcon(Icons.visibility_outlined));
        await tester.pump();

        // Icon should change to visibility_off (password is now visible)
        expect(find.byIcon(Icons.visibility_outlined), findsNothing);
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

        // Tap again to hide password
        await tester.tap(find.byIcon(Icons.visibility_off_outlined));
        await tester.pump();

        // Icon should change back
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
      });
    });

    group('email format validation', () {
      testWidgets('accepts valid email formats', (tester) async {
        when(
          () => mockAuthRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final validEmails = [
          'test@example.com',
          'user.name@domain.org',
          'user+tag@example.co.uk',
          'test123@example.com',
        ];

        for (final email in validEmails) {
          // Clear previous input
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Email'),
            '',
          );

          await tester.enterText(
            find.widgetWithText(TextFormField, 'Email'),
            email,
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Password'),
            'Password1',
          );
          await tester.tap(find.text('Log In'));
          await tester.pumpAndSettle();

          expect(
            find.text('Invalid email format'),
            findsNothing,
            reason: 'Email "$email" should be valid',
          );
        }
      });

      testWidgets('rejects invalid email formats', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final invalidEmails = [
          'test',
          'test@',
          '@example.com',
          'test@example',
          'test @example.com',
        ];

        for (final email in invalidEmails) {
          // Clear previous input
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Email'),
            '',
          );

          await tester.enterText(
            find.widgetWithText(TextFormField, 'Email'),
            email,
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Password'),
            'Password1',
          );
          await tester.tap(find.text('Log In'));
          await tester.pumpAndSettle();

          expect(
            find.text('Invalid email format'),
            findsOneWidget,
            reason: 'Email "$email" should be invalid',
          );
        }
      });
    });

    group('password format validation', () {
      testWidgets('accepts valid password formats', (tester) async {
        when(
          () => mockAuthRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final validPasswords = [
          'Password1',
          'Abcdefgh1',
          'Str0ngP@ss',
          'MyP4ssword',
        ];

        for (final password in validPasswords) {
          // Clear previous input
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Password'),
            '',
          );

          await tester.enterText(
            find.widgetWithText(TextFormField, 'Email'),
            'test@example.com',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Password'),
            password,
          );
          await tester.tap(find.text('Log In'));
          await tester.pumpAndSettle();

          expect(
            find.text(
              'Password must be at least 8 characters with 1 number and 1 uppercase letter',
            ),
            findsNothing,
            reason: 'Password "$password" should be valid',
          );
        }
      });

      testWidgets('rejects invalid password formats', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final invalidPasswords = [
          'short', // too short
          'password', // no uppercase, no number
          'PASSWORD', // no lowercase, no number
          'Password', // no number
          '12345678', // no letter
          'pass1', // too short
        ];

        for (final password in invalidPasswords) {
          // Clear previous input
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Password'),
            '',
          );

          await tester.enterText(
            find.widgetWithText(TextFormField, 'Email'),
            'test@example.com',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Password'),
            password,
          );
          await tester.tap(find.text('Log In'));
          await tester.pumpAndSettle();

          expect(
            find.text(
              'Password must be at least 8 characters with 1 number and 1 uppercase letter',
            ),
            findsOneWidget,
            reason: 'Password "$password" should be invalid',
          );
        }
      });
    });

    group('button states', () {
      testWidgets('login button is disabled during loading', (tester) async {
        when(
          () => mockAuthRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          return Right(testUser);
        });

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'Password1',
        );

        await tester.tap(find.text('Log In'));
        await tester.pump();

        // Try to tap again during loading - should not trigger another call
        await tester.tap(find.byType(ElevatedButton).first);
        await tester.pump();

        await tester.pumpAndSettle();

        // Should only be called once
        verify(
          () => mockAuthRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).called(1);
      });
    });
  });
}

/// Test version of global auth error listener.
class _GlobalAuthErrorListenerForTest extends ConsumerWidget {
  const _GlobalAuthErrorListenerForTest({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthenticationState>(authNotifierProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        context.showAuthError(next.error!);
      }
    });

    return child;
  }
}
