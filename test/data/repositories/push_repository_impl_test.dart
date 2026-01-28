import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/api_exceptions.dart';
import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/remote/push_remote_ds.dart';
import 'package:fishfeed/data/repositories/push_repository_impl.dart';

class MockPushRemoteDataSource extends Mock implements PushRemoteDataSource {}

void main() {
  late MockPushRemoteDataSource mockRemoteDataSource;
  late PushRepositoryImpl repository;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('push_repo_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    mockRemoteDataSource = MockPushRemoteDataSource();

    // Initialize HiveBoxes for each test if not already initialized
    if (!HiveBoxes.isInitialized) {
      await HiveBoxes.initForTesting();
    }

    // Clear any existing push token data
    await HiveBoxes.clearPushToken();

    repository = PushRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      retryConfig: const PushRetryConfig(
        maxRetries: 2,
        initialDelay: Duration(milliseconds: 10),
        maxDelay: Duration(milliseconds: 50),
      ),
    );
  });

  tearDown(() async {
    // Clear push token data after each test
    if (HiveBoxes.isInitialized) {
      await HiveBoxes.clearPushToken();
    }
  });

  group('registerToken', () {
    test('should register token on server and store locally on success', () async {
      when(
        () => mockRemoteDataSource.registerToken(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.registerToken(
        token: 'test-fcm-token',
        platform: 'android',
      );

      expect(result, const Right<Failure, Unit>(unit));
      expect(HiveBoxes.getPushToken(), 'test-fcm-token');
      expect(HiveBoxes.getPushTokenPlatform(), 'android');

      verify(
        () => mockRemoteDataSource.registerToken(
          token: 'test-fcm-token',
          platform: 'android',
        ),
      ).called(1);
    });

    test('should skip registration if token unchanged', () async {
      // Pre-store the token
      await HiveBoxes.setPushToken('existing-token', 'android');

      final result = await repository.registerToken(
        token: 'existing-token',
        platform: 'android',
      );

      expect(result, const Right<Failure, Unit>(unit));
      verifyNever(
        () => mockRemoteDataSource.registerToken(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      );
    });

    test('should register if token changed', () async {
      // Pre-store a different token
      await HiveBoxes.setPushToken('old-token', 'android');

      when(
        () => mockRemoteDataSource.registerToken(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.registerToken(
        token: 'new-token',
        platform: 'android',
      );

      expect(result, const Right<Failure, Unit>(unit));
      expect(HiveBoxes.getPushToken(), 'new-token');

      verify(
        () => mockRemoteDataSource.registerToken(
          token: 'new-token',
          platform: 'android',
        ),
      ).called(1);
    });

    test('should register if platform changed', () async {
      // Pre-store token with different platform
      await HiveBoxes.setPushToken('same-token', 'ios');

      when(
        () => mockRemoteDataSource.registerToken(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.registerToken(
        token: 'same-token',
        platform: 'android',
      );

      expect(result, const Right<Failure, Unit>(unit));
      expect(HiveBoxes.getPushTokenPlatform(), 'android');
    });

    test('should return NetworkFailure on network error', () async {
      when(
        () => mockRemoteDataSource.registerToken(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).thenThrow(const NetworkException());

      final result = await repository.registerToken(
        token: 'test-token',
        platform: 'android',
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should be Left'),
      );

      // Token should NOT be stored on failure
      expect(HiveBoxes.getPushToken(), isNull);
    });

    test('should return ServerFailure on server error', () async {
      when(
        () => mockRemoteDataSource.registerToken(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).thenThrow(const ServerException());

      final result = await repository.registerToken(
        token: 'test-token',
        platform: 'android',
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should be Left'),
      );
    });
  });

  group('registerTokenWithRetry', () {
    test('should succeed on first attempt', () async {
      when(
        () => mockRemoteDataSource.registerToken(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).thenAnswer((_) async {});

      await repository.registerTokenWithRetry(
        token: 'test-token',
        platform: 'android',
      );

      expect(HiveBoxes.getPushToken(), 'test-token');

      verify(
        () => mockRemoteDataSource.registerToken(
          token: 'test-token',
          platform: 'android',
        ),
      ).called(1);
    });

    test('should retry on network error and succeed', () async {
      var callCount = 0;

      when(
        () => mockRemoteDataSource.registerToken(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        if (callCount < 2) {
          throw const NetworkException();
        }
      });

      await repository.registerTokenWithRetry(
        token: 'test-token',
        platform: 'android',
      );

      expect(HiveBoxes.getPushToken(), 'test-token');

      verify(
        () => mockRemoteDataSource.registerToken(
          token: 'test-token',
          platform: 'android',
        ),
      ).called(2);
    });

    test('should stop retrying after max retries', () async {
      when(
        () => mockRemoteDataSource.registerToken(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).thenThrow(const NetworkException());

      await repository.registerTokenWithRetry(
        token: 'test-token',
        platform: 'android',
      );

      // Should be called initial + 2 retries = 3 times
      verify(
        () => mockRemoteDataSource.registerToken(
          token: 'test-token',
          platform: 'android',
        ),
      ).called(3);

      // Token should NOT be stored
      expect(HiveBoxes.getPushToken(), isNull);
    });

    test('should not retry on unauthorized error', () async {
      when(
        () => mockRemoteDataSource.registerToken(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).thenThrow(const UnauthorizedException());

      await repository.registerTokenWithRetry(
        token: 'test-token',
        platform: 'android',
      );

      // Should only be called once (no retries for auth errors)
      verify(
        () => mockRemoteDataSource.registerToken(
          token: 'test-token',
          platform: 'android',
        ),
      ).called(1);
    });

    test('should skip if token unchanged', () async {
      await HiveBoxes.setPushToken('same-token', 'android');

      await repository.registerTokenWithRetry(
        token: 'same-token',
        platform: 'android',
      );

      verifyNever(
        () => mockRemoteDataSource.registerToken(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      );
    });
  });

  group('unregisterToken', () {
    test('should unregister from server and clear local token', () async {
      // Pre-store a token
      await HiveBoxes.setPushToken('stored-token', 'android');

      when(() => mockRemoteDataSource.unregisterToken())
          .thenAnswer((_) async {});

      final result = await repository.unregisterToken();

      expect(result, const Right<Failure, Unit>(unit));
      expect(HiveBoxes.getPushToken(), isNull);
      expect(HiveBoxes.getPushTokenPlatform(), isNull);

      verify(() => mockRemoteDataSource.unregisterToken()).called(1);
    });

    test('should skip server call if no token stored', () async {
      final result = await repository.unregisterToken();

      expect(result, const Right<Failure, Unit>(unit));
      verifyNever(() => mockRemoteDataSource.unregisterToken());
    });

    test('should clear local token even if server fails', () async {
      await HiveBoxes.setPushToken('stored-token', 'android');

      when(() => mockRemoteDataSource.unregisterToken())
          .thenThrow(const ServerException());

      final result = await repository.unregisterToken();

      // Should still succeed because local token is cleared
      expect(result, const Right<Failure, Unit>(unit));
      expect(HiveBoxes.getPushToken(), isNull);
    });
  });

  group('getStoredToken', () {
    test('should return null when no token stored', () {
      expect(repository.getStoredToken(), isNull);
    });

    test('should return stored token', () async {
      await HiveBoxes.setPushToken('my-token', 'android');
      expect(repository.getStoredToken(), 'my-token');
    });
  });

  group('getStoredPlatform', () {
    test('should return null when no platform stored', () {
      expect(repository.getStoredPlatform(), isNull);
    });

    test('should return stored platform', () async {
      await HiveBoxes.setPushToken('my-token', 'ios');
      expect(repository.getStoredPlatform(), 'ios');
    });
  });

  group('needsRegistration', () {
    test('should return true when no token stored', () {
      expect(repository.needsRegistration('new-token', 'android'), isTrue);
    });

    test('should return false when token matches', () async {
      await HiveBoxes.setPushToken('same-token', 'android');
      expect(repository.needsRegistration('same-token', 'android'), isFalse);
    });

    test('should return true when token differs', () async {
      await HiveBoxes.setPushToken('old-token', 'android');
      expect(repository.needsRegistration('new-token', 'android'), isTrue);
    });

    test('should return true when platform differs', () async {
      await HiveBoxes.setPushToken('same-token', 'ios');
      expect(repository.needsRegistration('same-token', 'android'), isTrue);
    });
  });
}
