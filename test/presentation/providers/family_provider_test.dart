import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/entities/family_invite.dart';
import 'package:fishfeed/domain/entities/family_member.dart';
import 'package:fishfeed/domain/repositories/family_repository.dart';
import 'package:fishfeed/presentation/providers/family_provider.dart';

class MockFamilyRepository extends Mock implements FamilyRepository {}

void main() {
  late MockFamilyRepository mockRepository;
  late FamilyNotifier notifier;

  final now = DateTime.now();
  const aquariumId = 'aquarium-1';

  final testInvite = FamilyInvite(
    id: 'invite-1',
    aquariumId: aquariumId,
    inviteCode: 'ABC12345',
    createdBy: 'user-1',
    createdAt: now,
    expiresAt: now.add(const Duration(hours: 48)),
  );

  final testOwner = FamilyMember(
    id: 'member-1',
    userId: 'user-1',
    aquariumId: aquariumId,
    role: FamilyMemberRole.owner,
    joinedAt: now,
    displayName: 'Owner',
  );

  final testMember = FamilyMember(
    id: 'member-2',
    userId: 'user-2',
    aquariumId: aquariumId,
    role: FamilyMemberRole.member,
    joinedAt: now,
    displayName: 'Member',
  );

  setUp(() {
    mockRepository = MockFamilyRepository();
    notifier = FamilyNotifier(repository: mockRepository);
  });

  group('FamilyState', () {
    test('initial state has empty lists and no loading', () {
      const state = FamilyState.initial();

      expect(state.invites, isEmpty);
      expect(state.members, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.lastCreatedInvite, isNull);
    });

    test('copyWith updates fields correctly', () {
      const initial = FamilyState.initial();
      final updated = initial.copyWith(
        invites: [testInvite],
        members: [testOwner],
        isLoading: true,
      );

      expect(updated.invites, [testInvite]);
      expect(updated.members, [testOwner]);
      expect(updated.isLoading, true);
    });

    test('copyWith clearError removes error', () {
      final withError = const FamilyState.initial().copyWith(
        error: const NetworkFailure(),
      );
      final cleared = withError.copyWith(clearError: true);

      expect(cleared.error, isNull);
    });

    test('copyWith clearLastInvite removes last invite', () {
      final withInvite = const FamilyState.initial().copyWith(
        lastCreatedInvite: testInvite,
      );
      final cleared = withInvite.copyWith(clearLastInvite: true);

      expect(cleared.lastCreatedInvite, isNull);
    });
  });

  group('FamilyNotifier.loadFamilyData', () {
    test('loads invites and members successfully', () async {
      when(
        () => mockRepository.getInvites(aquariumId: aquariumId),
      ).thenAnswer((_) async => Right([testInvite]));
      when(
        () => mockRepository.getMembers(aquariumId: aquariumId),
      ).thenAnswer((_) async => Right([testOwner, testMember]));

      await notifier.loadFamilyData(aquariumId);

      expect(notifier.state.invites, [testInvite]);
      expect(notifier.state.members, [testOwner, testMember]);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    test('handles invite fetch failure', () async {
      when(
        () => mockRepository.getInvites(aquariumId: aquariumId),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      when(
        () => mockRepository.getMembers(aquariumId: aquariumId),
      ).thenAnswer((_) async => Right([testOwner]));

      await notifier.loadFamilyData(aquariumId);

      expect(notifier.state.invites, isEmpty);
      expect(notifier.state.members, [testOwner]);
      expect(notifier.state.error, isNull);
    });

    test('handles member fetch failure', () async {
      when(
        () => mockRepository.getInvites(aquariumId: aquariumId),
      ).thenAnswer((_) async => Right([testInvite]));
      when(
        () => mockRepository.getMembers(aquariumId: aquariumId),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      await notifier.loadFamilyData(aquariumId);

      expect(notifier.state.invites, [testInvite]);
      expect(notifier.state.members, isEmpty);
      expect(notifier.state.error, isA<ServerFailure>());
    });
  });

  group('FamilyNotifier.createInvite', () {
    test('creates invite successfully', () async {
      when(
        () => mockRepository.createInvite(aquariumId: aquariumId),
      ).thenAnswer((_) async => Right(testInvite));

      await notifier.createInvite(aquariumId);

      expect(notifier.state.invites, [testInvite]);
      expect(notifier.state.lastCreatedInvite, testInvite);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    test('handles create invite failure', () async {
      when(
        () => mockRepository.createInvite(aquariumId: aquariumId),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      await notifier.createInvite(aquariumId);

      expect(notifier.state.invites, isEmpty);
      expect(notifier.state.lastCreatedInvite, isNull);
      expect(notifier.state.error, isA<ServerFailure>());
    });
  });

  group('FamilyNotifier.cancelInvite', () {
    test('cancels invite successfully', () async {
      // First add an invite
      when(
        () => mockRepository.createInvite(aquariumId: aquariumId),
      ).thenAnswer((_) async => Right(testInvite));
      await notifier.createInvite(aquariumId);

      when(
        () => mockRepository.cancelInvite(
          aquariumId: aquariumId,
          inviteId: testInvite.id,
        ),
      ).thenAnswer((_) async => const Right(unit));

      await notifier.cancelInvite(aquariumId, testInvite.id);

      expect(notifier.state.invites, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('handles cancel invite failure', () async {
      when(
        () => mockRepository.cancelInvite(
          aquariumId: aquariumId,
          inviteId: 'invalid',
        ),
      ).thenAnswer((_) async => const Left(ServerFailure()));

      await notifier.cancelInvite(aquariumId, 'invalid');

      expect(notifier.state.error, isA<ServerFailure>());
    });
  });

  group('FamilyNotifier.removeMember', () {
    test('removes member successfully', () async {
      // Setup initial state with members
      when(
        () => mockRepository.getInvites(aquariumId: aquariumId),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockRepository.getMembers(aquariumId: aquariumId),
      ).thenAnswer((_) async => Right([testOwner, testMember]));
      await notifier.loadFamilyData(aquariumId);

      when(
        () => mockRepository.removeMember(
          aquariumId: aquariumId,
          userId: testMember.userId,
        ),
      ).thenAnswer((_) async => const Right(unit));

      await notifier.removeMember(aquariumId, testMember.userId);

      expect(notifier.state.members, [testOwner]);
      expect(notifier.state.isLoading, false);
    });

    test('handles remove member failure', () async {
      when(
        () => mockRepository.removeMember(
          aquariumId: aquariumId,
          userId: 'invalid',
        ),
      ).thenAnswer((_) async => const Left(ValidationFailure()));

      await notifier.removeMember(aquariumId, 'invalid');

      expect(notifier.state.error, isA<ValidationFailure>());
    });
  });

  group('FamilyNotifier.acceptInvite', () {
    test('accepts invite successfully', () async {
      when(
        () => mockRepository.acceptInvite(inviteCode: 'ABC12345'),
      ).thenAnswer((_) async => Right(testMember));

      await notifier.acceptInvite('ABC12345');

      expect(notifier.state.members, [testMember]);
      expect(notifier.state.isLoading, false);
    });

    test('handles accept invite failure', () async {
      when(
        () => mockRepository.acceptInvite(inviteCode: 'INVALID'),
      ).thenAnswer((_) async => const Left(ValidationFailure()));

      await notifier.acceptInvite('INVALID');

      expect(notifier.state.error, isA<ValidationFailure>());
    });
  });

  group('FamilyNotifier utility methods', () {
    test('clearLastInvite removes last invite', () async {
      when(
        () => mockRepository.createInvite(aquariumId: aquariumId),
      ).thenAnswer((_) async => Right(testInvite));
      await notifier.createInvite(aquariumId);

      expect(notifier.state.lastCreatedInvite, testInvite);

      notifier.clearLastInvite();

      expect(notifier.state.lastCreatedInvite, isNull);
    });

    test('clearError removes error', () async {
      when(
        () => mockRepository.createInvite(aquariumId: aquariumId),
      ).thenAnswer((_) async => const Left(ServerFailure()));
      await notifier.createInvite(aquariumId);

      expect(notifier.state.error, isA<ServerFailure>());

      notifier.clearError();

      expect(notifier.state.error, isNull);
    });
  });
}
