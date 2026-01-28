import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/data/repositories/family_repository_impl.dart';
import 'package:fishfeed/domain/entities/family_member.dart';
import 'package:fishfeed/domain/repositories/family_repository.dart';
import 'package:fishfeed/presentation/screens/family/join_family_screen.dart';

class MockFamilyRepository extends Mock implements FamilyRepository {}

void main() {
  late MockFamilyRepository mockRepository;

  final testMember = FamilyMember(
    id: 'member-123',
    userId: 'user-456',
    aquariumId: 'aquarium-789',
    role: FamilyMemberRole.member,
    joinedAt: DateTime(2024, 1, 15),
    displayName: 'Test User',
  );

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  setUp(() {
    mockRepository = MockFamilyRepository();
  });

  Widget buildTestWidget({
    String inviteCode = 'TEST1234',
    List<Override> additionalOverrides = const [],
  }) {
    final router = GoRouter(
      initialLocation: '/join/$inviteCode',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const Scaffold(body: Text('Auth')),
        ),
        GoRoute(
          path: '/join/:inviteCode',
          builder: (context, state) {
            final code = state.pathParameters['inviteCode']!;
            return JoinFamilyScreen(inviteCode: code);
          },
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        familyRepositoryProvider.overrideWithValue(mockRepository),
        ...additionalOverrides,
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  group('JoinFamilyScreen', () {
    group('loading state', () {
      testWidgets('shows loading indicator initially', (tester) async {
        final completer = Completer<Either<Failure, FamilyMember>>();
        when(() => mockRepository.acceptInvite(inviteCode: any(named: 'inviteCode')))
            .thenAnswer((_) => completer.future);

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Joining family...'), findsOneWidget);

        // Complete the future to prevent hanging
        completer.complete(Right(testMember));
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));
      });

      testWidgets('shows loading message', (tester) async {
        final completer = Completer<Either<Failure, FamilyMember>>();
        when(() => mockRepository.acceptInvite(inviteCode: any(named: 'inviteCode')))
            .thenAnswer((_) => completer.future);

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(
          find.text('Please wait while we process your invitation'),
          findsOneWidget,
        );

        // Complete the future to prevent hanging
        completer.complete(Right(testMember));
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));
      });
    });

    group('success state', () {
      testWidgets('shows success message on valid invite', (tester) async {
        when(() => mockRepository.acceptInvite(inviteCode: 'VALID123'))
            .thenAnswer((_) async => Right(testMember));

        await tester.pumpWidget(buildTestWidget(inviteCode: 'VALID123'));
        // Pump to trigger the post-frame callback
        await tester.pump();
        // Pump again to let the repository call complete
        await tester.pump();

        expect(find.text('Congratulations!'), findsOneWidget);
        expect(
          find.text('You have successfully joined the family aquarium'),
          findsOneWidget,
        );

        // Pump through the 2-second redirect delay to clear the timer
        await tester.pump(const Duration(seconds: 3));
      });

      testWidgets('shows success check icon', (tester) async {
        when(() => mockRepository.acceptInvite(inviteCode: any(named: 'inviteCode')))
            .thenAnswer((_) async => Right(testMember));

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();
        await tester.pump();

        expect(find.byIcon(Icons.check_circle), findsOneWidget);

        // Pump through the redirect delay to clear the timer
        await tester.pump(const Duration(seconds: 3));
      });

      testWidgets('shows redirect message', (tester) async {
        when(() => mockRepository.acceptInvite(inviteCode: any(named: 'inviteCode')))
            .thenAnswer((_) async => Right(testMember));

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();
        await tester.pump();

        expect(find.text('Redirecting...'), findsOneWidget);

        // Pump through the redirect delay to clear the timer
        await tester.pump(const Duration(seconds: 3));
      });
    });

    group('error state', () {
      testWidgets('shows error message on invalid code', (tester) async {
        when(() => mockRepository.acceptInvite(inviteCode: 'INVALID1'))
            .thenAnswer((_) async => const Left(
                  ValidationFailure(message: 'Invalid or expired invite code'),
                ));

        await tester.pumpWidget(buildTestWidget(inviteCode: 'INVALID1'));
        await tester.pump();
        await tester.pump();

        expect(find.text('Invitation error'), findsOneWidget);
        expect(find.text('Invalid or expired invite code'), findsOneWidget);
      });

      testWidgets('shows error icon for validation error', (tester) async {
        when(() => mockRepository.acceptInvite(inviteCode: any(named: 'inviteCode')))
            .thenAnswer((_) async => const Left(
                  ValidationFailure(message: 'Test error'),
                ));

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();
        await tester.pump();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('shows home button on validation error', (tester) async {
        when(() => mockRepository.acceptInvite(inviteCode: any(named: 'inviteCode')))
            .thenAnswer((_) async => const Left(
                  ValidationFailure(message: 'Test error'),
                ));

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();
        await tester.pump();

        expect(find.text('To home'), findsOneWidget);
        expect(find.byIcon(Icons.home), findsOneWidget);
      });

      testWidgets('shows auth required message for auth error', (tester) async {
        when(() => mockRepository.acceptInvite(inviteCode: any(named: 'inviteCode')))
            .thenAnswer((_) async => const Left(
                  AuthenticationFailure(message: 'User not authenticated'),
                ));

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();
        await tester.pump();

        expect(find.text('Login required'), findsOneWidget);
        expect(
          find.text('Log in to accept the invitation'),
          findsOneWidget,
        );

        // Pump through the 1-second auth redirect delay to clear the timer
        await tester.pump(const Duration(seconds: 2));
      });

      testWidgets('shows lock icon for auth error', (tester) async {
        when(() => mockRepository.acceptInvite(inviteCode: any(named: 'inviteCode')))
            .thenAnswer((_) async => const Left(
                  AuthenticationFailure(),
                ));

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();
        await tester.pump();

        expect(find.byIcon(Icons.lock_outline), findsOneWidget);

        // Pump through the 1-second auth redirect delay to clear the timer
        await tester.pump(const Duration(seconds: 2));
      });

      testWidgets('shows login button for auth error', (tester) async {
        when(() => mockRepository.acceptInvite(inviteCode: any(named: 'inviteCode')))
            .thenAnswer((_) async => const Left(
                  AuthenticationFailure(),
                ));

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();
        await tester.pump();

        expect(find.text('Log in'), findsOneWidget);
        expect(find.byIcon(Icons.login), findsOneWidget);

        // Pump through the 1-second auth redirect delay to clear the timer
        await tester.pump(const Duration(seconds: 2));
      });
    });

    group('invite code handling', () {
      testWidgets('calls repository with correct invite code', (tester) async {
        when(() => mockRepository.acceptInvite(inviteCode: 'MYCODE12'))
            .thenAnswer((_) async => Right(testMember));

        await tester.pumpWidget(buildTestWidget(inviteCode: 'MYCODE12'));
        await tester.pump();
        await tester.pump();

        verify(() => mockRepository.acceptInvite(inviteCode: 'MYCODE12')).called(1);

        // Pump through the redirect delay to clear the timer
        await tester.pump(const Duration(seconds: 3));
      });

      testWidgets('only calls accept invite once', (tester) async {
        when(() => mockRepository.acceptInvite(inviteCode: any(named: 'inviteCode')))
            .thenAnswer((_) async => Right(testMember));

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();
        await tester.pump();

        // Rebuild widget multiple times
        await tester.pump();
        await tester.pump();

        verify(() => mockRepository.acceptInvite(inviteCode: any(named: 'inviteCode')))
            .called(1);

        // Pump through the redirect delay to clear the timer
        await tester.pump(const Duration(seconds: 3));
      });
    });

    group('UI elements', () {
      testWidgets('has proper styling', (tester) async {
        when(() => mockRepository.acceptInvite(inviteCode: any(named: 'inviteCode')))
            .thenAnswer((_) async => Right(testMember));

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        // Check for SafeArea
        expect(find.byType(SafeArea), findsOneWidget);

        // Check content is centered in the body (we look for Center inside Scaffold's body)
        expect(
          find.descendant(
            of: find.byType(Scaffold),
            matching: find.byType(Center),
          ),
          findsAtLeastNWidgets(1),
        );

        // Pump through the redirect delay to clear the timer
        await tester.pump(const Duration(seconds: 3));
      });
    });
  });
}
