import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/api_exceptions.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/core/services/secure_storage_service.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/remote/auth_remote_ds.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/auth_response_dto.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';
import 'package:fishfeed/data/models/user_dto.dart';
import 'package:fishfeed/data/models/user_model.dart';
import 'package:fishfeed/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class FakeUserModel extends Fake implements UserModel {}

void main() {
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockSecureStorageService mockSecureStorageService;
  late AuthRepositoryImpl repository;

  final testUserDto = UserDto(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    avatarKey: null,
    createdAt: DateTime(2024, 1, 15),
    subscriptionStatus: 'free',
    freeAiScansRemaining: 5,
  );

  final testAuthResponseDto = AuthResponseDto(
    user: testUserDto,
    accessToken: 'access-token-123',
    refreshToken: 'refresh-token-456',
  );

  final testUserModel = UserModel(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: DateTime(2024, 1, 15),
  );

  late Directory tempDir;

  setUpAll(() async {
    registerFallbackValue(FakeUserModel());

    // Initialize HiveBoxes for tests
    tempDir = await Directory.systemTemp.createTemp('auth_repo_test_');
    Hive.init(tempDir.path);
    await HiveBoxes.initForTesting();
  });

  tearDownAll(() async {
    await HiveBoxes.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    mockSecureStorageService = MockSecureStorageService();

    // Default: no previously cached user, so login/register/oauthLogin do not
    // trigger the ownership-change wipe in _clearPreviousUserDataIfNeeded.
    when(() => mockLocalDataSource.getCurrentUser()).thenReturn(null);

    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      secureStorageService: mockSecureStorageService,
    );
  });

  group('login', () {
    test('should return User on successful login', () async {
      when(
        () => mockRemoteDataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => testAuthResponseDto);

      when(
        () => mockSecureStorageService.setTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockLocalDataSource.saveUserLocally(any()),
      ).thenAnswer((_) async {});

      final result = await repository.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result.isRight(), true);
      result.fold((_) => fail('Should be Right'), (user) {
        expect(user.id, 'user-123');
        expect(user.email, 'test@example.com');
      });

      verify(
        () => mockSecureStorageService.setTokens(
          accessToken: 'access-token-123',
          refreshToken: 'refresh-token-456',
        ),
      ).called(1);
    });

    test('should return AuthenticationFailure on 401', () async {
      when(
        () => mockRemoteDataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const UnauthorizedException());

      final result = await repository.login(
        email: 'test@example.com',
        password: 'wrong-password',
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<AuthenticationFailure>()),
        (_) => fail('Should be Left'),
      );
    });

    test('should return NetworkFailure on network error', () async {
      when(
        () => mockRemoteDataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const NetworkException());

      final result = await repository.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should be Left'),
      );
    });

    test('should return ValidationFailure with errors on 422', () async {
      when(
        () => mockRemoteDataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const ValidationException(
          message: 'Validation failed',
          errors: {
            'email': ['Invalid email format'],
          },
        ),
      );

      final result = await repository.login(
        email: 'invalid-email',
        password: 'password123',
      );

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        final validationFailure = failure as ValidationFailure;
        expect(
          validationFailure.errors['email'],
          contains('Invalid email format'),
        );
      }, (_) => fail('Should be Left'));
    });

    test('401 maps to AuthenticationFailure with default message (so the UI '
        'localizes it instead of showing raw English)', () async {
      when(
        () => mockRemoteDataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const UnauthorizedException());

      final result = await repository.login(
        email: 'test@example.com',
        password: 'wrong',
      );

      result.fold((failure) {
        expect(failure, isA<AuthenticationFailure>());
        // Default message — auth_error_handler treats it as "no custom
        // override" and routes to the localized errorInvalidCredentials.
        expect(failure.message, 'Authentication failed');
      }, (_) => fail('Should be Left'));
    });

    test(
      '403 maps to AuthenticationFailure with default message (for l10n)',
      () async {
        when(
          () => mockRemoteDataSource.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const ForbiddenException());

        final result = await repository.login(
          email: 'test@example.com',
          password: 'password123',
        );

        result.fold((failure) {
          expect(failure, isA<AuthenticationFailure>());
          expect(failure.message, 'Authentication failed');
        }, (_) => fail('Should be Left'));
      },
    );

    test('UnknownApiException maps to UnexpectedFailure with default message '
        '(no Dio-style technical text leaks to UI)', () async {
      when(
        () => mockRemoteDataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const UnknownApiException(
          message: 'DioException [connection error]: ...',
          statusCode: 0,
        ),
      );

      final result = await repository.login(
        email: 'test@example.com',
        password: 'password123',
      );

      result.fold((failure) {
        expect(failure, isA<UnexpectedFailure>());
        expect(failure.message, 'An unexpected error occurred');
      }, (_) => fail('Should be Left'));
    });

    test('non-ApiException is swallowed into UnexpectedFailure with default '
        'message (closes the e.toString() leak)', () async {
      when(
        () => mockRemoteDataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const FormatException('Unexpected character'));

      final result = await repository.login(
        email: 'test@example.com',
        password: 'password123',
      );

      result.fold((failure) {
        expect(failure, isA<UnexpectedFailure>());
        expect(failure.message, 'An unexpected error occurred');
        expect(failure.message, isNot(contains('FormatException')));
      }, (_) => fail('Should be Left'));
    });
  });

  group('register', () {
    test('should return User on successful registration', () async {
      when(
        () => mockRemoteDataSource.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => testAuthResponseDto);

      when(
        () => mockSecureStorageService.setTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockLocalDataSource.saveUserLocally(any()),
      ).thenAnswer((_) async {});

      final result = await repository.register(
        email: 'new@example.com',
        password: 'Password123',
      );

      expect(result.isRight(), true);
    });

    test('should return ServerFailure on 500', () async {
      when(
        () => mockRemoteDataSource.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const ServerException());

      final result = await repository.register(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should be Left'),
      );
    });
  });

  group('oauthLogin', () {
    test('should return User on successful OAuth login', () async {
      when(
        () => mockRemoteDataSource.oauthLogin(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
        ),
      ).thenAnswer((_) async => testAuthResponseDto);

      when(
        () => mockSecureStorageService.setTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockLocalDataSource.saveUserLocally(any()),
      ).thenAnswer((_) async {});

      final result = await repository.oauthLogin(
        provider: 'google',
        idToken: 'google-id-token',
      );

      expect(result.isRight(), true);
      verify(
        () => mockRemoteDataSource.oauthLogin(
          provider: 'google',
          idToken: 'google-id-token',
        ),
      ).called(1);
    });
  });

  group('logout', () {
    test('clears only the session tokens, preserving the local user record, '
        'domain data and onboarding flag', () async {
      // Seed per-user domain data and onboarding so we can prove that logout
      // leaves them intact. The original bug wiped these on every logout,
      // which made the feeding status look "not fed" after the next login.
      await HiveBoxes.setOnboardingCompleted(true);
      await HiveBoxes.aquariums.put(
        'aq-1',
        AquariumModel(
          id: 'aq-1',
          userId: 'user-123',
          name: 'Living room tank',
          createdAt: DateTime(2024, 1, 1),
        ),
      );
      await HiveBoxes.feedingLogs.put(
        'log-1',
        FeedingLogModel(
          id: 'log-1',
          scheduleId: 'sch-1',
          fishId: 'fish-1',
          aquariumId: 'aq-1',
          scheduledFor: DateTime(2024, 1, 1, 9),
          action: 'fed',
          actedAt: DateTime(2024, 1, 1, 9),
          actedByUserId: 'user-123',
          deviceId: 'device-1',
          createdAt: DateTime(2024, 1, 1, 9),
        ),
      );

      when(
        () => mockSecureStorageService.getRefreshToken(),
      ).thenAnswer((_) async => 'refresh-token');
      when(
        () => mockSecureStorageService.clearTokens(),
      ).thenAnswer((_) async {});
      when(
        () => mockRemoteDataSource.logout(
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.logout();

      expect(result.isRight(), true);
      // Session tokens are cleared...
      verify(() => mockSecureStorageService.clearTokens()).called(1);
      // ...but the user's local record and domain data are NOT wiped.
      verifyNever(() => mockLocalDataSource.clearAll());
      expect(HiveBoxes.getOnboardingCompleted(), true);
      expect(HiveBoxes.aquariums.isNotEmpty, true);
      expect(HiveBoxes.feedingLogs.isNotEmpty, true);

      // Cleanup seeded data so other tests start from a clean state.
      await HiveBoxes.aquariums.clear();
      await HiveBoxes.feedingLogs.clear();
      await HiveBoxes.setOnboardingCompleted(false);
    });

    test(
      'still clears the session when the server logout call fails',
      () async {
        when(
          () => mockSecureStorageService.getRefreshToken(),
        ).thenAnswer((_) async => 'refresh-token');
        when(
          () => mockSecureStorageService.clearTokens(),
        ).thenAnswer((_) async {});
        when(
          () => mockRemoteDataSource.logout(
            refreshToken: any(named: 'refreshToken'),
          ),
        ).thenThrow(const ServerException());

        final result = await repository.logout();

        // Should still succeed because the local session is cleared regardless.
        expect(result.isRight(), true);
        verify(() => mockSecureStorageService.clearTokens()).called(1);
        verifyNever(() => mockLocalDataSource.clearAll());
      },
    );
  });

  group('account-switch data isolation', () {
    test(
      'same-user re-login preserves local data (no ownership-change wipe)',
      () async {
        // A user record already exists locally for the SAME id signing in.
        when(
          () => mockLocalDataSource.getCurrentUser(),
        ).thenReturn(testUserModel); // id == testUserDto.id == 'user-123'
        when(
          () => mockRemoteDataSource.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => testAuthResponseDto);
        when(
          () => mockSecureStorageService.setTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockLocalDataSource.saveUserLocally(any()),
        ).thenAnswer((_) async {});

        await repository.login(email: 'test@example.com', password: 'pw');

        // No wipe because the same user is signing back in.
        verifyNever(() => mockLocalDataSource.clearAll());
        verifyNever(() => mockSecureStorageService.clearTokens());
      },
    );

    test('different-user sign-in wipes the previous user data', () async {
      // A DIFFERENT user is cached locally before sign-in.
      final otherUser = UserModel(
        id: 'other-user-999',
        email: 'other@example.com',
        displayName: 'Other',
        createdAt: DateTime(2024, 1, 1),
      );
      when(() => mockLocalDataSource.getCurrentUser()).thenReturn(otherUser);
      when(() => mockLocalDataSource.clearAll()).thenAnswer((_) async {});
      when(
        () => mockSecureStorageService.clearTokens(),
      ).thenAnswer((_) async {});
      when(
        () => mockRemoteDataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => testAuthResponseDto);
      when(
        () => mockSecureStorageService.setTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockLocalDataSource.saveUserLocally(any()),
      ).thenAnswer((_) async {});

      await repository.login(email: 'test@example.com', password: 'pw');

      // Ownership changed -> the previous user's data is wiped.
      verify(() => mockLocalDataSource.clearAll()).called(1);
      verify(() => mockSecureStorageService.clearTokens()).called(1);
    });
  });

  group('deleteAccount', () {
    test('clears local data and returns unit on success', () async {
      when(() => mockRemoteDataSource.deleteAccount()).thenAnswer((_) async {});
      when(
        () => mockSecureStorageService.clearTokens(),
      ).thenAnswer((_) async {});
      when(() => mockLocalDataSource.clearAll()).thenAnswer((_) async {});

      final result = await repository.deleteAccount();

      expect(result.isRight(), true);
      verify(() => mockRemoteDataSource.deleteAccount()).called(1);
      verify(() => mockSecureStorageService.clearTokens()).called(1);
      verify(() => mockLocalDataSource.clearAll()).called(1);
    });

    test(
      'preserves local data and returns failure when the server call fails',
      () async {
        when(
          () => mockRemoteDataSource.deleteAccount(),
        ).thenThrow(const NetworkException());

        final result = await repository.deleteAccount();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (_) => fail('Expected a failure'),
        );
        // Critical invariant: local data must NOT be wiped when the account
        // was not actually deleted on the server.
        verifyNever(() => mockSecureStorageService.clearTokens());
        verifyNever(() => mockLocalDataSource.clearAll());
      },
    );
  });

  group('getCurrentUser', () {
    test('should return User when cached user exists', () async {
      when(
        () => mockLocalDataSource.getCurrentUser(),
      ).thenReturn(testUserModel);

      final result = await repository.getCurrentUser();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (user) => expect(user.email, 'test@example.com'),
      );
    });

    test('should return CacheFailure when no user cached', () async {
      when(() => mockLocalDataSource.getCurrentUser()).thenReturn(null);

      final result = await repository.getCurrentUser();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Should be Left'),
      );
    });
  });

  group('isAuthenticated', () {
    test('should return true when tokens exist', () async {
      when(
        () => mockSecureStorageService.hasTokens(),
      ).thenAnswer((_) async => true);

      final result = await repository.isAuthenticated();

      expect(result, true);
    });

    test('should return false when no tokens', () async {
      when(
        () => mockSecureStorageService.hasTokens(),
      ).thenAnswer((_) async => false);

      final result = await repository.isAuthenticated();

      expect(result, false);
    });
  });
}
