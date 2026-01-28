import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/domain/repositories/push_repository.dart';
import 'package:fishfeed/services/notifications/fcm_service.dart';
import 'package:fishfeed/services/push/push_token_manager.dart';

class MockPushRepository extends Mock implements PushRepository {}

class MockFcmService extends Mock implements FcmService {}

void main() {
  late MockPushRepository mockPushRepository;
  late MockFcmService mockFcmService;
  late PushTokenManager manager;
  late StreamController<String> tokenStreamController;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('push_manager_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    mockPushRepository = MockPushRepository();
    mockFcmService = MockFcmService();
    tokenStreamController = StreamController<String>.broadcast();

    when(
      () => mockFcmService.tokenStream,
    ).thenAnswer((_) => tokenStreamController.stream);

    // Initialize HiveBoxes for each test
    if (!HiveBoxes.isInitialized) {
      await HiveBoxes.initForTesting();
    }

    await HiveBoxes.clearPushToken();

    manager = PushTokenManager(
      pushRepository: mockPushRepository,
      fcmService: mockFcmService,
    );
  });

  tearDown(() async {
    manager.dispose();
    await tokenStreamController.close();
    if (HiveBoxes.isInitialized) {
      await HiveBoxes.clearPushToken();
    }
  });

  group('initialization', () {
    test('should subscribe to token stream on initialize', () {
      manager.initialize();

      verify(() => mockFcmService.tokenStream).called(1);
    });
  });

  group('onAuthStateChanged - login', () {
    test('should register token when user becomes authenticated', () async {
      when(
        () => mockFcmService.getToken(),
      ).thenAnswer((_) async => 'test-fcm-token');
      when(
        () => mockPushRepository.registerTokenWithRetry(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).thenAnswer((_) async {});

      manager.initialize();
      await manager.onAuthStateChanged(isAuthenticated: true);

      verify(() => mockFcmService.getToken()).called(1);
      verify(
        () => mockPushRepository.registerTokenWithRetry(
          token: 'test-fcm-token',
          platform: any(named: 'platform'),
        ),
      ).called(1);
    });

    test('should not register token if FCM token is null', () async {
      when(() => mockFcmService.getToken()).thenAnswer((_) async => null);

      manager.initialize();
      await manager.onAuthStateChanged(isAuthenticated: true);

      verify(() => mockFcmService.getToken()).called(1);
      verifyNever(
        () => mockPushRepository.registerTokenWithRetry(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      );
    });

    test('should not register token if already authenticated', () async {
      when(
        () => mockFcmService.getToken(),
      ).thenAnswer((_) async => 'test-token');
      when(
        () => mockPushRepository.registerTokenWithRetry(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).thenAnswer((_) async {});

      manager.initialize();

      // First login
      await manager.onAuthStateChanged(isAuthenticated: true);
      // Already authenticated
      await manager.onAuthStateChanged(isAuthenticated: true);

      // Should only register once
      verify(
        () => mockPushRepository.registerTokenWithRetry(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).called(1);
    });
  });

  group('onAuthStateChanged - logout', () {
    test('should unregister token and delete FCM token on logout', () async {
      when(
        () => mockFcmService.getToken(),
      ).thenAnswer((_) async => 'test-token');
      when(
        () => mockPushRepository.registerTokenWithRetry(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockPushRepository.unregisterToken(),
      ).thenAnswer((_) async => const Right(unit));
      when(() => mockFcmService.deleteToken()).thenAnswer((_) async {});

      manager.initialize();

      // Login first
      await manager.onAuthStateChanged(isAuthenticated: true);

      // Then logout
      await manager.onAuthStateChanged(isAuthenticated: false);

      verify(() => mockPushRepository.unregisterToken()).called(1);
      verify(() => mockFcmService.deleteToken()).called(1);
    });

    test('should not unregister if not previously authenticated', () async {
      manager.initialize();

      // Logout without login
      await manager.onAuthStateChanged(isAuthenticated: false);

      verifyNever(() => mockPushRepository.unregisterToken());
      verifyNever(() => mockFcmService.deleteToken());
    });
  });

  group('token refresh handling', () {
    test('should re-register token when refreshed and authenticated', () async {
      when(
        () => mockFcmService.getToken(),
      ).thenAnswer((_) async => 'initial-token');
      when(
        () => mockPushRepository.registerTokenWithRetry(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).thenAnswer((_) async {});

      manager.initialize();

      // Login first
      await manager.onAuthStateChanged(isAuthenticated: true);

      // Clear previous invocations
      clearInteractions(mockPushRepository);

      // Simulate token refresh
      tokenStreamController.add('refreshed-token');

      // Allow async processing
      await Future<void>.delayed(const Duration(milliseconds: 10));

      verify(
        () => mockPushRepository.registerTokenWithRetry(
          token: 'refreshed-token',
          platform: any(named: 'platform'),
        ),
      ).called(1);
    });

    test(
      'should not re-register token when refreshed but not authenticated',
      () async {
        manager.initialize();

        // Simulate token refresh without login
        tokenStreamController.add('refreshed-token');

        // Allow async processing
        await Future<void>.delayed(const Duration(milliseconds: 10));

        verifyNever(
          () => mockPushRepository.registerTokenWithRetry(
            token: any(named: 'token'),
            platform: any(named: 'platform'),
          ),
        );
      },
    );
  });

  group('forceRegisterToken', () {
    test('should register token when authenticated', () async {
      when(
        () => mockFcmService.getToken(),
      ).thenAnswer((_) async => 'forced-token');
      when(
        () => mockPushRepository.registerTokenWithRetry(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).thenAnswer((_) async {});

      manager.initialize();

      // Login first
      await manager.onAuthStateChanged(isAuthenticated: true);

      // Clear previous invocations
      clearInteractions(mockPushRepository);
      clearInteractions(mockFcmService);

      // Force register
      await manager.forceRegisterToken();

      verify(() => mockFcmService.getToken()).called(1);
      verify(
        () => mockPushRepository.registerTokenWithRetry(
          token: 'forced-token',
          platform: any(named: 'platform'),
        ),
      ).called(1);
    });

    test('should not register token when not authenticated', () async {
      manager.initialize();

      await manager.forceRegisterToken();

      verifyNever(() => mockFcmService.getToken());
      verifyNever(
        () => mockPushRepository.registerTokenWithRetry(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      );
    });
  });

  group('full integration flow', () {
    test('login -> token registered -> logout -> token unregistered', () async {
      when(
        () => mockFcmService.getToken(),
      ).thenAnswer((_) async => 'integration-token');
      when(
        () => mockPushRepository.registerTokenWithRetry(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockPushRepository.unregisterToken(),
      ).thenAnswer((_) async => const Right(unit));
      when(() => mockFcmService.deleteToken()).thenAnswer((_) async {});

      manager.initialize();

      // Step 1: Login
      await manager.onAuthStateChanged(isAuthenticated: true);

      verify(
        () => mockPushRepository.registerTokenWithRetry(
          token: 'integration-token',
          platform: any(named: 'platform'),
        ),
      ).called(1);

      // Step 2: Token refresh while logged in
      tokenStreamController.add('refreshed-integration-token');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      verify(
        () => mockPushRepository.registerTokenWithRetry(
          token: 'refreshed-integration-token',
          platform: any(named: 'platform'),
        ),
      ).called(1);

      // Step 3: Logout
      await manager.onAuthStateChanged(isAuthenticated: false);

      verify(() => mockPushRepository.unregisterToken()).called(1);
      verify(() => mockFcmService.deleteToken()).called(1);

      // Step 4: Token refresh after logout should NOT trigger registration
      clearInteractions(mockPushRepository);
      tokenStreamController.add('post-logout-token');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      verifyNever(
        () => mockPushRepository.registerTokenWithRetry(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
        ),
      );
    });
  });
}
