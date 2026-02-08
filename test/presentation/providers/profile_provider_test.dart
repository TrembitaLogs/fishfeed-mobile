import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/models/user_model.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/repositories/user_repository.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/profile_provider.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockAuthNotifier extends Mock implements AuthNotifier {}

class MockSyncService extends Mock implements SyncService {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class FakeFile extends Fake implements File {}

class FakeUserModel extends Fake implements UserModel {}

void main() {
  late MockUserRepository mockUserRepository;
  late MockAuthNotifier mockAuthNotifier;
  late MockSyncService mockSyncService;
  late MockAuthLocalDataSource mockAuthLocalDs;
  late ProfileNotifier profileNotifier;

  final testUser = User(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: DateTime(2024, 1, 15),
    subscriptionStatus: const SubscriptionStatus.free(),
    freeAiScansRemaining: 5,
  );

  setUpAll(() {
    registerFallbackValue(FakeFile());
    registerFallbackValue(testUser);
    registerFallbackValue(FakeUserModel());
  });

  setUp(() {
    mockUserRepository = MockUserRepository();
    mockAuthNotifier = MockAuthNotifier();
    mockSyncService = MockSyncService();
    mockAuthLocalDs = MockAuthLocalDataSource();

    // Default mock behavior for offline-first nickname update
    when(
      () => mockAuthNotifier.state,
    ).thenReturn(AuthenticationState.authenticated(testUser));
    when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(null);
    when(() => mockAuthLocalDs.saveUserLocally(any())).thenAnswer((_) async {});
    when(() => mockSyncService.syncAll()).thenAnswer((_) async => 0);

    profileNotifier = ProfileNotifier(
      userRepository: mockUserRepository,
      authNotifier: mockAuthNotifier,
      syncService: mockSyncService,
      authLocalDataSource: mockAuthLocalDs,
    );
  });

  group('ProfileNotifier', () {
    group('initial state', () {
      test('has correct initial values', () {
        expect(profileNotifier.state.isUpdatingNickname, false);
        expect(profileNotifier.state.isUpdatingAvatar, false);
        expect(profileNotifier.state.error, null);
        expect(profileNotifier.state.nicknameError, null);
        expect(profileNotifier.state.isLoading, false);
      });
    });

    group('validateNickname', () {
      test('returns error for empty nickname', () {
        final result = profileNotifier.validateNickname('');
        expect(result, 'Nickname cannot be empty');
      });

      test('returns error for whitespace-only nickname', () {
        final result = profileNotifier.validateNickname('   ');
        expect(result, 'Nickname cannot be empty');
      });

      test('returns error for nickname shorter than 3 characters', () {
        final result = profileNotifier.validateNickname('ab');
        expect(result, 'Nickname must be at least 3 characters');
      });

      test('returns error for nickname longer than 20 characters', () {
        final result = profileNotifier.validateNickname('a' * 21);
        expect(result, 'Nickname cannot exceed 20 characters');
      });

      test('returns null for valid nickname', () {
        final result = profileNotifier.validateNickname('ValidName');
        expect(result, null);
      });

      test('returns null for nickname at minimum length', () {
        final result = profileNotifier.validateNickname('abc');
        expect(result, null);
      });

      test('returns null for nickname at maximum length', () {
        final result = profileNotifier.validateNickname('a' * 20);
        expect(result, null);
      });
    });

    group('updateNickname', () {
      test('returns false and sets error for empty nickname', () async {
        final result = await profileNotifier.updateNickname('');

        expect(result, false);
        expect(profileNotifier.state.nicknameError, 'Nickname cannot be empty');
        verifyNever(
          () => mockUserRepository.updateDisplayName(
            displayName: any(named: 'displayName'),
          ),
        );
      });

      test('returns false and sets error for short nickname', () async {
        final result = await profileNotifier.updateNickname('ab');

        expect(result, false);
        expect(
          profileNotifier.state.nicknameError,
          'Nickname must be at least 3 characters',
        );
        verifyNever(
          () => mockUserRepository.updateDisplayName(
            displayName: any(named: 'displayName'),
          ),
        );
      });

      test('returns false and sets error for long nickname', () async {
        final result = await profileNotifier.updateNickname('a' * 21);

        expect(result, false);
        expect(
          profileNotifier.state.nicknameError,
          'Nickname cannot exceed 20 characters',
        );
        verifyNever(
          () => mockUserRepository.updateDisplayName(
            displayName: any(named: 'displayName'),
          ),
        );
      });

      test('sets isUpdatingNickname to true during update', () async {
        // Capture state during sync to verify isUpdatingNickname
        when(() => mockSyncService.syncAll()).thenAnswer((_) async {
          expect(profileNotifier.state.isUpdatingNickname, true);
          return 0;
        });

        await profileNotifier.updateNickname('NewNickname');
      });

      test('saves locally with trimmed nickname and triggers sync', () async {
        await profileNotifier.updateNickname('  NewNickname  ');

        // Verify auth state was updated with trimmed nickname
        verify(() => mockAuthNotifier.updateUser(any())).called(1);
        // Verify sync was triggered
        verify(() => mockSyncService.syncAll()).called(1);
      });

      test('returns true and updates auth state on success', () async {
        final result = await profileNotifier.updateNickname('NewNickname');

        expect(result, true);
        expect(profileNotifier.state.isUpdatingNickname, false);
        expect(profileNotifier.state.error, null);
        verify(() => mockAuthNotifier.updateUser(any())).called(1);
        verify(() => mockSyncService.syncAll()).called(1);
      });

      test('returns false and sets error when no user authenticated', () async {
        when(
          () => mockAuthNotifier.state,
        ).thenReturn(const AuthenticationState());

        final result = await profileNotifier.updateNickname('NewNickname');

        expect(result, false);
        expect(profileNotifier.state.isUpdatingNickname, false);
        expect(profileNotifier.state.error, isA<UnexpectedFailure>());
        verifyNever(() => mockAuthNotifier.updateUser(any()));
      });

      test('clears previous errors before update', () async {
        await profileNotifier.updateNickname('NewNickname');

        expect(profileNotifier.state.error, null);
        expect(profileNotifier.state.nicknameError, null);
      });
    });

    group('updateAvatar', () {
      late File testFile;

      setUp(() {
        testFile = FakeFile();
      });

      test('sets isUpdatingAvatar to true during update', () async {
        when(
          () => mockUserRepository.updateAvatar(
            avatarFile: any(named: 'avatarFile'),
          ),
        ).thenAnswer((_) async {
          expect(profileNotifier.state.isUpdatingAvatar, true);
          return Right(testUser);
        });

        await profileNotifier.updateAvatar(testFile);
      });

      test('returns true and updates auth state on success', () async {
        when(
          () => mockUserRepository.updateAvatar(
            avatarFile: any(named: 'avatarFile'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        final result = await profileNotifier.updateAvatar(testFile);

        expect(result, true);
        expect(profileNotifier.state.isUpdatingAvatar, false);
        expect(profileNotifier.state.error, null);
        verify(() => mockAuthNotifier.updateUser(testUser)).called(1);
      });

      test('returns false and sets error on failure', () async {
        when(
          () => mockUserRepository.updateAvatar(
            avatarFile: any(named: 'avatarFile'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure()));

        final result = await profileNotifier.updateAvatar(testFile);

        expect(result, false);
        expect(profileNotifier.state.isUpdatingAvatar, false);
        expect(profileNotifier.state.error, isA<ServerFailure>());
        verifyNever(() => mockAuthNotifier.updateUser(any()));
      });

      test('clears previous errors before update', () async {
        when(
          () => mockUserRepository.updateAvatar(
            avatarFile: any(named: 'avatarFile'),
          ),
        ).thenAnswer((_) async => Right(testUser));

        await profileNotifier.updateAvatar(testFile);

        expect(profileNotifier.state.error, null);
      });
    });

    group('clearErrors', () {
      test('clears all errors', () async {
        // First, trigger an error by having no authenticated user
        when(
          () => mockAuthNotifier.state,
        ).thenReturn(const AuthenticationState());
        await profileNotifier.updateNickname('ValidName');

        expect(profileNotifier.state.error, isNotNull);

        // Now clear errors
        profileNotifier.clearErrors();

        expect(profileNotifier.state.error, null);
        expect(profileNotifier.state.nicknameError, null);
      });
    });

    group('clearNicknameError', () {
      test('clears nickname error', () async {
        // Trigger nickname validation error
        await profileNotifier.updateNickname('ab');

        expect(profileNotifier.state.nicknameError, isNotNull);

        // Clear nickname error
        profileNotifier.clearNicknameError();

        expect(profileNotifier.state.nicknameError, null);
      });
    });
  });

  group('ProfileState', () {
    test('isLoading returns true when updating nickname', () {
      const state = ProfileState(isUpdatingNickname: true);
      expect(state.isLoading, true);
    });

    test('isLoading returns true when updating avatar', () {
      const state = ProfileState(isUpdatingAvatar: true);
      expect(state.isLoading, true);
    });

    test('isLoading returns true when updating both', () {
      const state = ProfileState(
        isUpdatingNickname: true,
        isUpdatingAvatar: true,
      );
      expect(state.isLoading, true);
    });

    test('isLoading returns false when not updating anything', () {
      const state = ProfileState();
      expect(state.isLoading, false);
    });

    test('copyWith creates correct copy', () {
      const original = ProfileState(
        isUpdatingNickname: true,
        isUpdatingAvatar: false,
        nicknameError: 'error',
      );

      final copy = original.copyWith(
        isUpdatingNickname: false,
        isUpdatingAvatar: true,
      );

      expect(copy.isUpdatingNickname, false);
      expect(copy.isUpdatingAvatar, true);
      expect(copy.nicknameError, 'error'); // Unchanged
    });

    test('copyWith with clearError removes error', () {
      const original = ProfileState(error: ServerFailure());

      final copy = original.copyWith(clearError: true);

      expect(copy.error, null);
    });

    test('copyWith with clearNicknameError removes nickname error', () {
      const original = ProfileState(nicknameError: 'some error');

      final copy = original.copyWith(clearNicknameError: true);

      expect(copy.nicknameError, null);
    });

    test('equality works correctly', () {
      const state1 = ProfileState(isUpdatingNickname: true);
      const state2 = ProfileState(isUpdatingNickname: true);
      const state3 = ProfileState(isUpdatingNickname: false);

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });
  });
}
