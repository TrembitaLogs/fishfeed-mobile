import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/repositories/auth_repository_impl.dart';
import 'package:fishfeed/data/repositories/user_repository_impl.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/repositories/auth_repository.dart';
import 'package:fishfeed/domain/repositories/user_repository.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/screens/profile/profile_screen.dart';
import 'package:fishfeed/data/datasources/remote/aquarium_remote_ds.dart';
import 'package:fishfeed/services/auth/apple_auth_service.dart';
import 'package:fishfeed/services/auth/google_auth_service.dart';

import '../../../helpers/test_helpers.dart' show createMockSyncService;

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockGoogleAuthService extends Mock implements GoogleAuthService {}

class MockAppleAuthService extends Mock implements AppleAuthService {}

class MockAquariumRemoteDataSource extends Mock
    implements AquariumRemoteDataSource {}

class FakeFile extends Fake implements File {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockUserRepository mockUserRepository;
  late MockGoogleAuthService mockGoogleAuthService;
  late MockAppleAuthService mockAppleAuthService;
  late MockAquariumRemoteDataSource mockAquariumRemoteDs;

  // Use removeAdsOnly() so "View Premium" button appears in tests
  final testUser = User(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: DateTime(2024, 1, 15),
    subscriptionStatus: const SubscriptionStatus.removeAdsOnly(),
    freeAiScansRemaining: 5,
  );

  final premiumUser = User(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Premium User',
    createdAt: DateTime(2024, 1, 15),
    subscriptionStatus: SubscriptionStatus.premium(),
    freeAiScansRemaining: 0,
  );

  final userWithoutNickname = User(
    id: 'user-123',
    email: 'test@example.com',
    displayName: null,
    createdAt: DateTime(2024, 1, 15),
    subscriptionStatus: const SubscriptionStatus.removeAdsOnly(),
    freeAiScansRemaining: 5,
  );

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
    registerFallbackValue(FakeFile());
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockUserRepository = MockUserRepository();
    mockGoogleAuthService = MockGoogleAuthService();
    mockAppleAuthService = MockAppleAuthService();
    mockAquariumRemoteDs = MockAquariumRemoteDataSource();
  });

  Widget buildTestWidget({User? user}) {
    final effectiveUser = user ?? testUser;
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/paywall',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Paywall Screen')),
          ),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        userRepositoryProvider.overrideWithValue(mockUserRepository),
        googleAuthServiceProvider.overrideWithValue(mockGoogleAuthService),
        appleAuthServiceProvider.overrideWithValue(mockAppleAuthService),
        authNotifierProvider.overrideWith((ref) {
          final notifier = AuthNotifier(
            repository: mockAuthRepository,
            googleAuthService: mockGoogleAuthService,
            appleAuthService: mockAppleAuthService,
            aquariumRemoteDataSource: mockAquariumRemoteDs,
            syncService: createMockSyncService(),
          );
          // Set authenticated state with test user
          if (user != null) {
            // We need to manually set the state since we're testing
            // This is a workaround for testing purposes
          }
          return notifier;
        }),
        currentUserProvider.overrideWithValue(effectiveUser),
        // Override subscription status for PremiumBadge widget
        subscriptionStatusProvider.overrideWithValue(effectiveUser.subscriptionStatus),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('ProfileScreen', () {
    group('UI rendering', () {
      testWidgets('renders all required widgets', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // AppBar
        expect(find.text('Profile'), findsOneWidget);

        // Avatar section
        expect(find.byType(CircleAvatar), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);

        // Nickname
        expect(find.text('Test User'), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsOneWidget);

        // Email
        expect(find.text('test@example.com'), findsOneWidget);
        expect(find.byIcon(Icons.email_outlined), findsOneWidget);

        // Subscription badge
        expect(find.text('Free'), findsOneWidget);

        // Quick actions
        expect(find.text('Share Profile'), findsOneWidget);
        expect(find.text('View Premium'), findsOneWidget);
      });

      testWidgets('shows avatar placeholder when no avatar URL', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Should show person icon as placeholder
        expect(find.byIcon(Icons.person), findsAtLeastNWidgets(1));
      });

      testWidgets('shows set nickname prompt when no display name', (tester) async {
        await tester.pumpWidget(buildTestWidget(user: userWithoutNickname));
        await tester.pumpAndSettle();

        expect(find.text('Set your nickname'), findsOneWidget);
      });

      testWidgets('shows Premium badge for premium user', (tester) async {
        await tester.pumpWidget(buildTestWidget(user: premiumUser));
        await tester.pumpAndSettle();

        expect(find.text('Premium'), findsOneWidget);
        expect(find.byIcon(Icons.workspace_premium), findsAtLeastNWidgets(1));
      });

      testWidgets('hides View Premium button for premium user', (tester) async {
        await tester.pumpWidget(buildTestWidget(user: premiumUser));
        await tester.pumpAndSettle();

        expect(find.text('View Premium'), findsNothing);
        expect(find.text('Share Profile'), findsOneWidget);
      });
    });

    group('nickname editing', () {
      testWidgets('tapping edit icon shows text field', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Tap edit button
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        // Should show text field
        expect(find.byType(TextFormField), findsOneWidget);
      });

      testWidgets('text field is pre-populated with current nickname', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter edit mode
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        // Text field should have current nickname
        final textField = find.byType(TextFormField);
        expect(textField, findsOneWidget);

        final textFieldWidget = tester.widget<TextFormField>(textField);
        expect(textFieldWidget.controller?.text, 'Test User');
      });

      testWidgets('shows checkmark button when nickname changed', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter edit mode
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        // No checkmark initially
        expect(find.byIcon(Icons.check), findsNothing);

        // Change nickname
        await tester.enterText(find.byType(TextFormField), 'NewNickname');
        await tester.pumpAndSettle();

        // Checkmark should appear
        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('shows validation error for short nickname on checkmark tap',
          (tester) async {
        when(() => mockUserRepository.updateDisplayName(
                displayName: any(named: 'displayName')))
            .thenAnswer((_) async => Right(testUser));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter edit mode
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        // Clear and enter short nickname
        await tester.enterText(find.byType(TextFormField), 'ab');
        await tester.pumpAndSettle();

        // Tap checkmark
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.text('Nickname must be at least 3 characters'), findsOneWidget);
      });

      testWidgets('calls repository on valid save via checkmark', (tester) async {
        when(() => mockUserRepository.updateDisplayName(displayName: 'NewNickname'))
            .thenAnswer(
                (_) async => Right(testUser.copyWith(displayName: 'NewNickname')));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter edit mode
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        // Enter new nickname
        await tester.enterText(find.byType(TextFormField), 'NewNickname');
        await tester.pumpAndSettle();

        // Tap checkmark
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();

        verify(() => mockUserRepository.updateDisplayName(displayName: 'NewNickname'))
            .called(1);
      });

      testWidgets('shows success snackbar on successful save', (tester) async {
        when(() => mockUserRepository.updateDisplayName(
                displayName: any(named: 'displayName')))
            .thenAnswer(
                (_) async => Right(testUser.copyWith(displayName: 'NewNickname')));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter edit mode
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        // Enter new nickname
        await tester.enterText(find.byType(TextFormField), 'NewNickname');
        await tester.pumpAndSettle();

        // Tap checkmark
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();

        // Should show success snackbar
        expect(find.text('Nickname updated successfully'), findsOneWidget);
      });

      testWidgets('shows loading indicator during save', (tester) async {
        when(() => mockUserRepository.updateDisplayName(
                displayName: any(named: 'displayName')))
            .thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return Right(testUser);
        });

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter edit mode
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        // Enter valid nickname
        await tester.enterText(find.byType(TextFormField), 'ValidName');
        await tester.pumpAndSettle();

        // Tap checkmark
        await tester.tap(find.byIcon(Icons.check));
        await tester.pump();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

        await tester.pumpAndSettle();
      });

      testWidgets('auto-saves after 2 seconds of inactivity', (tester) async {
        when(() => mockUserRepository.updateDisplayName(
                displayName: any(named: 'displayName')))
            .thenAnswer(
                (_) async => Right(testUser.copyWith(displayName: 'AutoSaved')));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter edit mode
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        // Enter new nickname
        await tester.enterText(find.byType(TextFormField), 'AutoSaved');
        await tester.pumpAndSettle();

        // Wait for auto-save timer (2 seconds)
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Should have called the repository
        verify(() => mockUserRepository.updateDisplayName(displayName: 'AutoSaved'))
            .called(1);
      });
    });

    group('avatar editing', () {
      testWidgets('tapping avatar shows bottom sheet', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Tap camera icon
        await tester.tap(find.byIcon(Icons.camera_alt));
        await tester.pumpAndSettle();

        // Should show bottom sheet
        expect(find.text('Choose Photo'), findsOneWidget);
        expect(find.text('Take Photo'), findsOneWidget);
        expect(find.text('Choose from Gallery'), findsOneWidget);
      });

      testWidgets('bottom sheet has camera option', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Tap camera icon
        await tester.tap(find.byIcon(Icons.camera_alt));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.camera_alt), findsAtLeastNWidgets(1));
        expect(find.text('Take Photo'), findsOneWidget);
      });

      testWidgets('bottom sheet has gallery option', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Tap camera icon
        await tester.tap(find.byIcon(Icons.camera_alt));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.photo_library), findsOneWidget);
        expect(find.text('Choose from Gallery'), findsOneWidget);
      });
    });

    group('subscription badge', () {
      testWidgets('shows Free badge for free user', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Free'), findsOneWidget);
        expect(find.byIcon(Icons.person_outline), findsAtLeastNWidgets(1));
      });

      testWidgets('shows Premium badge for premium user', (tester) async {
        await tester.pumpWidget(buildTestWidget(user: premiumUser));
        await tester.pumpAndSettle();

        expect(find.text('Premium'), findsOneWidget);
        expect(find.byIcon(Icons.workspace_premium), findsAtLeastNWidgets(1));
      });

      testWidgets('tapping badge is interactive', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Find the badge by text and tap it
        final badgeFinder = find.text('Free');
        expect(badgeFinder, findsOneWidget);

        // Tap should not crash (it navigates to paywall)
        await tester.tap(badgeFinder);
        await tester.pump();
      });
    });

    group('quick actions', () {
      testWidgets('Share Profile button is visible', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Share Profile'), findsOneWidget);
        expect(find.byIcon(Icons.share), findsOneWidget);
      });

      testWidgets('View Premium button is visible for free user', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('View Premium'), findsOneWidget);
      });

      testWidgets('View Premium button is hidden for premium user', (tester) async {
        await tester.pumpWidget(buildTestWidget(user: premiumUser));
        await tester.pumpAndSettle();

        expect(find.text('View Premium'), findsNothing);
      });

      testWidgets('View Premium button is tappable', (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Scroll to make View Premium button visible
        await tester.scrollUntilVisible(
          find.text('View Premium'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        // Tap should not crash (it navigates to paywall)
        await tester.tap(find.text('View Premium'));
        await tester.pump();
      });
    });

    group('error handling', () {
      testWidgets('shows error banner on update failure', (tester) async {
        when(() => mockUserRepository.updateDisplayName(
                displayName: any(named: 'displayName')))
            .thenAnswer(
                (_) async => const Left(ServerFailure(message: 'Server error')));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter edit mode
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        // Enter valid nickname
        await tester.enterText(find.byType(TextFormField), 'ValidName');
        await tester.pumpAndSettle();

        // Tap checkmark
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();

        // Should show error banner
        expect(find.text('Server error'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsAtLeastNWidgets(1));
      });

      testWidgets('error banner can be dismissed', (tester) async {
        when(() => mockUserRepository.updateDisplayName(
                displayName: any(named: 'displayName')))
            .thenAnswer(
                (_) async => const Left(ServerFailure(message: 'Server error')));

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter edit mode and trigger error
        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), 'ValidName');
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();

        expect(find.text('Server error'), findsOneWidget);

        // Scroll to make the error banner's close button visible
        await tester.scrollUntilVisible(
          find.byIcon(Icons.close),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        // Dismiss error
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.text('Server error'), findsNothing);
      });
    });
  });
}
