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
import 'package:fishfeed/presentation/screens/auth/register_screen.dart';
import 'package:fishfeed/services/auth/apple_auth_service.dart';
import 'package:fishfeed/services/auth/google_auth_service.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

import '../../../helpers/test_helpers.dart' show createMockSyncService;

class MockAuthRepository extends Mock implements AuthRepository {}

class MockGoogleAuthService extends Mock implements GoogleAuthService {}

class MockAppleAuthService extends Mock implements AppleAuthService {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockGoogleAuthService mockGoogleAuthService;
  late MockAppleAuthService mockAppleAuthService;

  final testUser = User(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
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
    mockGoogleAuthService = MockGoogleAuthService();
    mockAppleAuthService = MockAppleAuthService();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        googleAuthServiceProvider.overrideWithValue(mockGoogleAuthService),
        appleAuthServiceProvider.overrideWithValue(mockAppleAuthService),
        syncServiceProvider.overrideWithValue(createMockSyncService()),
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
        home: const RegisterScreen(),
      ),
    );
  }

  group('RegisterScreen', () {
    group('UI rendering', () {
      testWidgets('renders all required widgets', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Header
        expect(find.byIcon(Icons.person_add), findsOneWidget);
        expect(find.text('Create Account'), findsAtLeastNWidgets(1));

        // Email field
        expect(find.text('Email'), findsOneWidget);
        expect(find.byIcon(Icons.email_outlined), findsOneWidget);

        // Password field
        expect(find.text('Password'), findsOneWidget);

        // Confirm Password field
        expect(find.text('Confirm Password'), findsOneWidget);

        // Lock icons (2 for password fields)
        expect(find.byIcon(Icons.lock_outlined), findsNWidgets(2));

        // Create Account button
        expect(find.text('Create Account'), findsAtLeastNWidgets(1));

        // Login link
        expect(find.text('Already have an account?'), findsOneWidget);
        expect(find.text('Log In'), findsOneWidget);

        // Terms of Service checkbox
        expect(find.byType(Checkbox), findsOneWidget);
        // Terms of Service text is in RichText widget
        expect(find.byType(RichText), findsWidgets);
      });

      testWidgets('password fields have visibility toggles', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Both password fields should have visibility icons
        expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));

        // Tap first visibility toggle
        await tester.tap(find.byIcon(Icons.visibility_outlined).first);
        await tester.pump();

        // One should change to visibility_off
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      });
    });

    group('password strength indicator', () {
      testWidgets('shows no indicator for empty password', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // No strength indicator visible
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.text('Weak'), findsNothing);
        expect(find.text('Medium'), findsNothing);
        expect(find.text('Strong'), findsNothing);
      });

      testWidgets('shows weak indicator for short password', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter weak password
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'weak',
        );
        await tester.pump();

        // Should show weak indicator
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Weak'), findsOneWidget);
      });

      testWidgets('shows medium indicator for moderate password', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter medium strength password (8+ chars with uppercase and number)
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'Password1',
        );
        await tester.pump();

        // Should show medium indicator
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Medium'), findsOneWidget);
      });

      testWidgets('shows strong indicator for strong password', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter strong password (12+ chars, uppercase, number, special char)
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'StrongP@ssw0rd!',
        );
        await tester.pump();

        // Should show strong indicator
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Strong'), findsOneWidget);
      });
    });

    group('form validation', () {
      testWidgets('shows error for empty email', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter password fields but leave email empty
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'Password1',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'Password1',
        );

        // Check ToS checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        // Tap create account - need to scroll down first
        await tester.ensureVisible(find.text('Create Account').last);
        await tester.tap(find.text('Create Account').last);
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
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'Password1',
        );

        // Check ToS checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        // Tap create account
        await tester.ensureVisible(find.text('Create Account').last);
        await tester.tap(find.text('Create Account').last);
        await tester.pumpAndSettle();

        expect(find.text('Invalid email format'), findsOneWidget);
      });

      testWidgets('shows error for weak password', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'weak',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'weak',
        );

        // Check ToS checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        // Tap create account
        await tester.ensureVisible(find.text('Create Account').last);
        await tester.tap(find.text('Create Account').last);
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Password must be at least 8 characters with 1 number and 1 uppercase letter',
          ),
          findsOneWidget,
        );
      });

      testWidgets('shows error for mismatched passwords', (tester) async {
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
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'DifferentPassword1',
        );

        // Check ToS checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        // Tap create account
        await tester.ensureVisible(find.text('Create Account').last);
        await tester.tap(find.text('Create Account').last);
        await tester.pumpAndSettle();

        expect(find.text('Passwords do not match'), findsOneWidget);
      });

      testWidgets('shows error when ToS checkbox is not checked', (
        tester,
      ) async {
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
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'Password1',
        );

        // Do NOT check ToS checkbox

        // Tap create account
        await tester.ensureVisible(find.text('Create Account').last);
        await tester.tap(find.text('Create Account').last);
        await tester.pumpAndSettle();

        expect(
          find.text('You must agree to the Terms of Service'),
          findsOneWidget,
        );
      });
    });

    group('ToS checkbox', () {
      testWidgets('checkbox toggles on tap', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Initially unchecked
        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, isFalse);

        // Tap to check
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        // Now checked
        final checkboxAfter = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkboxAfter.value, isTrue);
      });

      testWidgets('checkbox toggles on tap again', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Initially unchecked
        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, isFalse);

        // Check
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        var checkboxAfter = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkboxAfter.value, isTrue);

        // Uncheck
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        checkboxAfter = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkboxAfter.value, isFalse);
      });

      testWidgets('ToS error clears when checkbox is checked', (tester) async {
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
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'Password1',
        );

        // Tap create account without checking ToS
        await tester.ensureVisible(find.text('Create Account').last);
        await tester.tap(find.text('Create Account').last);
        await tester.pumpAndSettle();

        // Error should be visible
        expect(
          find.text('You must agree to the Terms of Service'),
          findsOneWidget,
        );

        // Now check the ToS checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        // Error should be cleared
        expect(
          find.text('You must agree to the Terms of Service'),
          findsNothing,
        );
      });
    });

    group('registration functionality', () {
      testWidgets('calls register with correct credentials', (tester) async {
        when(
          () => mockAuthRepository.register(
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
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'Password1',
        );

        // Check ToS checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        // Tap create account
        await tester.ensureVisible(find.text('Create Account').last);
        await tester.tap(find.text('Create Account').last);
        await tester.pumpAndSettle();

        verify(
          () => mockAuthRepository.register(
            email: 'test@example.com',
            password: 'Password1',
          ),
        ).called(1);
      });

      testWidgets('shows loading indicator during registration', (
        tester,
      ) async {
        when(
          () => mockAuthRepository.register(
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
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'Password1',
        );

        // Check ToS checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        // Tap create account
        await tester.ensureVisible(find.text('Create Account').last);
        await tester.tap(find.text('Create Account').last);
        await tester.pump();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for registration to complete
        await tester.pumpAndSettle();
      });

      testWidgets('shows snackbar on registration error', (tester) async {
        when(
          () => mockAuthRepository.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => const Left(
            AuthenticationFailure(message: 'Email already in use'),
          ),
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
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'Password1',
        );

        // Check ToS checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        // Tap create account
        await tester.ensureVisible(find.text('Create Account').last);
        await tester.tap(find.text('Create Account').last);
        await tester.pumpAndSettle();

        // Should show snackbar with error
        expect(find.text('Email already in use'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('password visibility toggle', () {
      testWidgets('toggles password visibility icon on tap', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Both visibility icons shows obscured state
        expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
        expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

        // Tap first visibility toggle (password field)
        await tester.tap(find.byIcon(Icons.visibility_outlined).first);
        await tester.pump();

        // First icon should change to visibility_off
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

        // Tap again to hide password
        await tester.tap(find.byIcon(Icons.visibility_off_outlined));
        await tester.pump();

        // Icons should reset
        expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
        expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
      });

      testWidgets('confirm password visibility is independent', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Tap second visibility toggle (confirm password field)
        await tester.tap(find.byIcon(Icons.visibility_outlined).last);
        await tester.pump();

        // Second icon should change, first stays the same
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      });
    });

    group('button states', () {
      testWidgets('create account button is disabled during loading', (
        tester,
      ) async {
        when(
          () => mockAuthRepository.register(
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
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'),
          'Password1',
        );

        // Check ToS checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        // Tap create account
        await tester.ensureVisible(find.text('Create Account').last);
        await tester.tap(find.text('Create Account').last);
        await tester.pump();

        // Try to tap again during loading - should not trigger another call
        await tester.tap(find.byType(ElevatedButton).first);
        await tester.pump();

        await tester.pumpAndSettle();

        // Should only be called once
        verify(
          () => mockAuthRepository.register(
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
