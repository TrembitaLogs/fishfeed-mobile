import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/repositories/family_repository_impl.dart';
import 'package:fishfeed/domain/entities/family_member.dart';
import 'package:fishfeed/domain/repositories/family_repository.dart';
import 'package:fishfeed/presentation/providers/join_invite_provider.dart';

class MockFamilyRepository extends Mock implements FamilyRepository {}

void main() {
  late MockFamilyRepository mockRepository;
  late ProviderContainer container;

  final testMember = FamilyMember(
    id: 'member-123',
    userId: 'user-456',
    aquariumId: 'aquarium-789',
    role: FamilyMemberRole.member,
    joinedAt: DateTime(2024, 1, 15),
    displayName: 'Test User',
  );

  setUp(() {
    mockRepository = MockFamilyRepository();
    container = ProviderContainer(
      overrides: [
        familyRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('JoinInviteNotifier', () {
    group('initial state', () {
      test('starts with JoinInviteInitial state', () {
        final state = container.read(joinInviteNotifierProvider);

        expect(state, isA<JoinInviteInitial>());
      });
    });

    group('acceptInvite', () {
      test('transitions to loading state when called', () async {
        final completer = Completer<Either<Failure, FamilyMember>>();

        when(() => mockRepository.acceptInvite(inviteCode: any(named: 'inviteCode')))
            .thenAnswer((_) => completer.future);

        final notifier = container.read(joinInviteNotifierProvider.notifier);

        // Start accepting (don't await yet)
        unawaited(notifier.acceptInvite('TEST1234'));

        // Should be in loading state
        expect(
          container.read(joinInviteNotifierProvider),
          isA<JoinInviteLoading>(),
        );

        // Complete the future to prevent hanging
        completer.complete(Right(testMember));
      });

      test('transitions to success state on valid invite', () async {
        when(() => mockRepository.acceptInvite(inviteCode: 'VALID123'))
            .thenAnswer((_) async => Right(testMember));

        final notifier = container.read(joinInviteNotifierProvider.notifier);

        await notifier.acceptInvite('VALID123');

        final state = container.read(joinInviteNotifierProvider);
        expect(state, isA<JoinInviteSuccess>());
        expect((state as JoinInviteSuccess).member, equals(testMember));
      });

      test('transitions to error state on invalid invite', () async {
        when(() => mockRepository.acceptInvite(inviteCode: 'INVALID1'))
            .thenAnswer((_) async => const Left(
                  ValidationFailure(message: 'Invalid or expired invite code'),
                ));

        final notifier = container.read(joinInviteNotifierProvider.notifier);

        await notifier.acceptInvite('INVALID1');

        final state = container.read(joinInviteNotifierProvider);
        expect(state, isA<JoinInviteError>());
        expect((state as JoinInviteError).message, 'Invalid or expired invite code');
      });

      test('transitions to error state on authentication failure', () async {
        when(() => mockRepository.acceptInvite(inviteCode: 'TEST1234'))
            .thenAnswer((_) async => const Left(
                  AuthenticationFailure(message: 'User not authenticated'),
                ));

        final notifier = container.read(joinInviteNotifierProvider.notifier);

        await notifier.acceptInvite('TEST1234');

        final state = container.read(joinInviteNotifierProvider);
        expect(state, isA<JoinInviteError>());
        expect((state as JoinInviteError).requiresAuth, isTrue);
      });

      test('calls repository with correct invite code', () async {
        when(() => mockRepository.acceptInvite(inviteCode: 'MYCODE12'))
            .thenAnswer((_) async => Right(testMember));

        final notifier = container.read(joinInviteNotifierProvider.notifier);

        await notifier.acceptInvite('MYCODE12');

        verify(() => mockRepository.acceptInvite(inviteCode: 'MYCODE12')).called(1);
      });
    });

    group('reset', () {
      test('resets state to initial', () async {
        when(() => mockRepository.acceptInvite(inviteCode: any(named: 'inviteCode')))
            .thenAnswer((_) async => Right(testMember));

        final notifier = container.read(joinInviteNotifierProvider.notifier);

        await notifier.acceptInvite('TEST1234');
        expect(container.read(joinInviteNotifierProvider), isA<JoinInviteSuccess>());

        notifier.reset();
        expect(container.read(joinInviteNotifierProvider), isA<JoinInviteInitial>());
      });
    });
  });

  group('JoinInviteError', () {
    test('message returns validation failure message', () {
      const error = JoinInviteError(
        failure: ValidationFailure(message: 'Custom error message'),
      );

      expect(error.message, 'Custom error message');
    });

    test('message returns authentication failure message', () {
      const error = JoinInviteError(
        failure: AuthenticationFailure(message: 'Please log in'),
      );

      expect(error.message, 'Please log in');
    });

    test('message returns default for unknown failures', () {
      const error = JoinInviteError(failure: NetworkFailure());

      expect(error.message, 'Failed to accept invitation. Please try again.');
    });

    test('isInvalidCode returns true for invalid code message', () {
      const error = JoinInviteError(
        failure: ValidationFailure(message: 'Invalid or expired invite code'),
      );

      expect(error.isInvalidCode, isTrue);
    });

    test('isInvalidCode returns false for other validation errors', () {
      const error = JoinInviteError(
        failure: ValidationFailure(message: 'Some other error'),
      );

      expect(error.isInvalidCode, isFalse);
    });

    test('requiresAuth returns true for authentication failures', () {
      const error = JoinInviteError(
        failure: AuthenticationFailure(),
      );

      expect(error.requiresAuth, isTrue);
    });

    test('requiresAuth returns false for other failures', () {
      const error = JoinInviteError(
        failure: ValidationFailure(),
      );

      expect(error.requiresAuth, isFalse);
    });
  });
}
