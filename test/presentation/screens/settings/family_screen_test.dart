import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/domain/entities/family_invite.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/domain/entities/family_member.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/repositories/family_repository.dart';
import 'package:fishfeed/data/repositories/family_repository_impl.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/screens/settings/family_screen.dart';

class MockFamilyRepository extends Mock implements FamilyRepository {}

void main() {
  late MockFamilyRepository mockRepository;

  final now = DateTime.now();
  const aquariumId = 'aquarium-1';
  const aquariumName = 'My Aquarium';

  final freeUser = User(
    id: 'user-1',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: now,
    subscriptionStatus: const SubscriptionStatus.free(),
  );

  final premiumUser = User(
    id: 'user-1',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: now,
    subscriptionStatus: SubscriptionStatus.premium(),
  );

  final testOwner = FamilyMember(
    id: 'member-1',
    userId: 'user-1',
    aquariumId: aquariumId,
    role: FamilyMemberRole.owner,
    joinedAt: DateTime(2024, 1, 15),
    displayName: 'Owner User',
  );

  final testMember = FamilyMember(
    id: 'member-2',
    userId: 'user-2',
    aquariumId: aquariumId,
    role: FamilyMemberRole.member,
    joinedAt: DateTime(2024, 6, 20),
    displayName: 'Family Member',
  );

  final testInvite = FamilyInvite(
    id: 'invite-1',
    aquariumId: aquariumId,
    inviteCode: 'ABC12345',
    createdBy: 'user-1',
    createdAt: now,
    expiresAt: now.add(const Duration(hours: 48)),
  );

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
    await initializeDateFormatting('en', null);
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  setUp(() {
    mockRepository = MockFamilyRepository();
  });

  Widget createTestWidget({User? user}) {
    // Default to free user if not specified
    final effectiveUser = user ?? freeUser;
    return ProviderScope(
      overrides: [
        familyRepositoryProvider.overrideWithValue(mockRepository),
        currentUserProvider.overrideWithValue(effectiveUser),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FamilyScreen(
          aquariumId: aquariumId,
          aquariumName: aquariumName,
        ),
      ),
    );
  }

  group('FamilyScreen', () {

    testWidgets('displays aquarium name in app bar', (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner]));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text(aquariumName), findsOneWidget);
    });

    testWidgets('displays family mode header', (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner]));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Family Mode'), findsOneWidget);
      expect(
        find.textContaining('Invite family members'),
        findsOneWidget,
      );
    });

    testWidgets('displays invite button', (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner]));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Invite family member'), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('displays family members section', (tester) async {
      // Use larger screen to ensure all content is visible
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.reset());

      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner, testMember]));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scroll down to see members section (upgrade prompt takes space on free tier)
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Family Members'), findsOneWidget);
      expect(find.text('Owner User'), findsOneWidget);
      expect(find.text('Family Member'), findsOneWidget);
    });

    testWidgets('displays owner role label', (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner]));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Owner'), findsOneWidget);
    });

    testWidgets('displays member role label', (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testMember]));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Member'), findsOneWidget);
    });

    testWidgets('displays active invitations section when invites exist',
        (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testInvite]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner]));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Active Invitations'), findsOneWidget);
      expect(find.text('ABC12345'), findsOneWidget);
    });

    testWidgets('shows empty members message when only owner exists',
        (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('You are the only family member'),
        findsOneWidget,
      );
    });

    testWidgets('tapping invite button creates new invite', (tester) async {
      // Use a larger screen size to avoid overflow from bottom sheet
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.reset());

      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner]));
      when(() => mockRepository.createInvite(aquariumId: aquariumId))
          .thenAnswer((_) async => Right(testInvite));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the button by text
      final inviteButtonText = find.text('Invite family member');
      expect(inviteButtonText, findsOneWidget);

      await tester.tap(inviteButtonText);
      await tester.pump();

      verify(() => mockRepository.createInvite(aquariumId: aquariumId))
          .called(1);
    });

    testWidgets('shows share bottom sheet after creating invite',
        (tester) async {
      // Use a larger screen size to avoid overflow
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.reset());

      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner]));
      when(() => mockRepository.createInvite(aquariumId: aquariumId))
          .thenAnswer((_) async => Right(testInvite));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final inviteButtonText = find.text('Invite family member');
      await tester.tap(inviteButtonText);
      await tester.pumpAndSettle();

      expect(find.text('Invitation created!'), findsOneWidget);
      expect(find.text('Invitation code'), findsOneWidget);
      expect(find.text('Share'), findsAtLeastNWidgets(1));
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets(
        'shows remove confirmation dialog for non-owner member (premium)',
        (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner, testMember]));

      await tester.pumpWidget(createTestWidget(user: premiumUser));
      await tester.pumpAndSettle();

      // Find and tap the remove button for the non-owner member
      final removeButton = find.byIcon(Icons.remove_circle_outline);
      expect(removeButton, findsOneWidget);

      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      expect(find.text('Remove member?'), findsOneWidget);
    });

    testWidgets('does not show remove button for owner', (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner]));

      await tester.pumpWidget(createTestWidget(user: premiumUser));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('does not show remove button for free user', (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner, testMember]));

      await tester.pumpWidget(createTestWidget(user: freeUser));
      await tester.pumpAndSettle();

      // Free users can't remove members
      expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
    });

    testWidgets('can pull to refresh', (tester) async {
      int callCount = 0;
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async {
        callCount++;
        return const Right([]);
      });
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner]));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initial load
      expect(callCount, 1);

      // Pull to refresh
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Should have made another call
      expect(callCount, 2);
    });
  });

  group('FamilyScreen - Tier Limits', () {
    testWidgets('displays member limit indicator for free user',
        (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner]));

      await tester.pumpWidget(createTestWidget(user: freeUser));
      await tester.pumpAndSettle();

      // Should show member count indicator
      expect(find.textContaining('Members: 1 / 2'), findsOneWidget);
    });

    testWidgets('does not display member limit indicator for premium user',
        (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner]));

      await tester.pumpWidget(createTestWidget(user: premiumUser));
      await tester.pumpAndSettle();

      // Should not show member count indicator for premium
      expect(find.textContaining('Members:'), findsNothing);
    });

    testWidgets('shows upgrade prompt when free tier limit reached',
        (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner, testMember]));

      await tester.pumpWidget(createTestWidget(user: freeUser));
      await tester.pumpAndSettle();

      // Should show upgrade prompt
      expect(
        find.text('Free plan limit reached'),
        findsOneWidget,
      );
      // Button text uses l10n.goToPremium
      expect(find.text('Go to Premium'), findsOneWidget);
      // Should not show invite button
      expect(find.text('Invite family member'), findsNothing);
    });

    testWidgets('shows invite button when premium user at free tier limit',
        (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner, testMember]));

      await tester.pumpWidget(createTestWidget(user: premiumUser));
      await tester.pumpAndSettle();

      // Premium users should still see invite button
      expect(find.text('Invite family member'), findsOneWidget);
      // Should not show upgrade prompt
      expect(
        find.text('Free plan limit reached'),
        findsNothing,
      );
    });

    testWidgets('shows limit reached warning text when at max free tier',
        (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner, testMember]));

      await tester.pumpWidget(createTestWidget(user: freeUser));
      await tester.pumpAndSettle();

      expect(find.text('Limit reached'), findsOneWidget);
    });
  });

  group('FamilyScreen - Member Card Details', () {
    testWidgets('displays join date in member card', (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner]));

      await tester.pumpWidget(createTestWidget(user: freeUser));
      await tester.pumpAndSettle();

      // Should display join date (15 Jan 2024 in Ukrainian format)
      expect(find.textContaining('Joined:'), findsOneWidget);
    });

    testWidgets('displays different join dates for multiple members',
        (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner, testMember]));

      await tester.pumpWidget(createTestWidget(user: premiumUser));
      await tester.pumpAndSettle();

      // Should display join date for both members
      expect(find.textContaining('Joined:'), findsNWidgets(2));
    });

    testWidgets('shows feeding stats for premium users', (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner]));

      await tester.pumpWidget(createTestWidget(user: premiumUser));
      await tester.pumpAndSettle();

      // Should show feeding stats chips (with 0 values as placeholder)
      expect(find.textContaining('this week'), findsOneWidget);
      expect(find.textContaining('this month'), findsOneWidget);
    });

    testWidgets('does not show feeding stats for free users', (tester) async {
      when(() => mockRepository.getInvites(aquariumId: aquariumId))
          .thenAnswer((_) async => const Right([]));
      when(() => mockRepository.getMembers(aquariumId: aquariumId))
          .thenAnswer((_) async => Right([testOwner]));

      await tester.pumpWidget(createTestWidget(user: freeUser));
      await tester.pumpAndSettle();

      // Should not show feeding stats
      expect(find.textContaining('this week'), findsNothing);
      expect(find.textContaining('this month'), findsNothing);
    });
  });
}
