import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/models/user_model.dart';
import 'package:fishfeed/data/models/user_settings_model.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/usecases/ai_scan_limit_usecase.dart';

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class FakeUserModel extends Fake implements UserModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUserModel());
  });

  late MockAuthLocalDataSource mockAuthLocalDs;
  late AiScanLimitUsecase usecase;

  setUp(() {
    mockAuthLocalDs = MockAuthLocalDataSource();
    usecase = AiScanLimitUsecase(authLocalDataSource: mockAuthLocalDs);
  });

  UserModel createTestUser({
    String id = 'user_1',
    String email = 'test@example.com',
    SubscriptionStatus subscriptionStatus = const SubscriptionStatus.free(),
    int freeAiScansRemaining = 5,
  }) {
    return UserModel(
      id: id,
      email: email,
      createdAt: DateTime(2024, 1, 1),
      subscriptionStatus: subscriptionStatus,
      freeAiScansRemaining: freeAiScansRemaining,
      settings: UserSettingsModel(),
    );
  }

  group('getRemainingScans', () {
    test('should return 0 when no user is logged in', () {
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(null);

      final result = usecase.getRemainingScans();

      expect(result, 0);
    });

    test('should return -1 (unlimited) for premium users', () {
      final user = createTestUser(
        subscriptionStatus: SubscriptionStatus.premium(),
        freeAiScansRemaining: 3,
      );
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);

      final result = usecase.getRemainingScans();

      expect(result, -1);
    });

    test('should return actual scan count for free users', () {
      final user = createTestUser(freeAiScansRemaining: 3);
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);

      final result = usecase.getRemainingScans();

      expect(result, 3);
    });

    test('should return 0 when free user has no scans left', () {
      final user = createTestUser(freeAiScansRemaining: 0);
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);

      final result = usecase.getRemainingScans();

      expect(result, 0);
    });
  });

  group('hasRemainingScans', () {
    test('should return false when no user is logged in', () {
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(null);

      final result = usecase.hasRemainingScans();

      expect(result, isFalse);
    });

    test('should return true for premium users', () {
      final user = createTestUser(
        subscriptionStatus: SubscriptionStatus.premium(),
        freeAiScansRemaining: 0,
      );
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);

      final result = usecase.hasRemainingScans();

      expect(result, isTrue);
    });

    test('should return true when free user has scans remaining', () {
      final user = createTestUser(freeAiScansRemaining: 3);
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);

      final result = usecase.hasRemainingScans();

      expect(result, isTrue);
    });

    test('should return true when free user has exactly 1 scan', () {
      final user = createTestUser(freeAiScansRemaining: 1);
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);

      final result = usecase.hasRemainingScans();

      expect(result, isTrue);
    });

    test('should return false when free user has 0 scans', () {
      final user = createTestUser(freeAiScansRemaining: 0);
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);

      final result = usecase.hasRemainingScans();

      expect(result, isFalse);
    });
  });

  group('isPremiumUser', () {
    test('should return false when no user is logged in', () {
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(null);

      final result = usecase.isPremiumUser();

      expect(result, isFalse);
    });

    test('should return true for premium users', () {
      final user = createTestUser(
        subscriptionStatus: SubscriptionStatus.premium(),
      );
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);

      final result = usecase.isPremiumUser();

      expect(result, isTrue);
    });

    test('should return false for free users', () {
      final user = createTestUser(
        subscriptionStatus: const SubscriptionStatus.free(),
      );
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);

      final result = usecase.isPremiumUser();

      expect(result, isFalse);
    });
  });

  group('decrementScanCount', () {
    test(
      'should return AuthenticationFailure when no user is logged in',
      () async {
        when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(null);

        final result = await usecase.decrementScanCount();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Should return failure'),
        );
      },
    );

    test('should not decrement for premium users', () async {
      final user = createTestUser(
        subscriptionStatus: SubscriptionStatus.premium(),
        freeAiScansRemaining: 5,
      );
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);

      final result = await usecase.decrementScanCount();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (updatedUser) {
        expect(updatedUser.freeAiScansRemaining, 5);
        expect(updatedUser.subscriptionStatus, SubscriptionStatus.premium());
      });
      verifyNever(() => mockAuthLocalDs.updateUserLocally(any()));
    });

    test('should decrement scan count for free user', () async {
      final user = createTestUser(freeAiScansRemaining: 5);
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);
      when(
        () => mockAuthLocalDs.updateUserLocally(any()),
      ).thenAnswer((_) async => true);

      final result = await usecase.decrementScanCount();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (updatedUser) {
        expect(updatedUser.freeAiScansRemaining, 4);
      });

      final captured =
          verify(
                () => mockAuthLocalDs.updateUserLocally(captureAny()),
              ).captured.single
              as UserModel;
      expect(captured.freeAiScansRemaining, 4);
    });

    test('should decrement from 1 to 0', () async {
      final user = createTestUser(freeAiScansRemaining: 1);
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);
      when(
        () => mockAuthLocalDs.updateUserLocally(any()),
      ).thenAnswer((_) async => true);

      final result = await usecase.decrementScanCount();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (updatedUser) {
        expect(updatedUser.freeAiScansRemaining, 0);
      });
    });

    test('should not go below 0', () async {
      final user = createTestUser(freeAiScansRemaining: 0);
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);

      final result = await usecase.decrementScanCount();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (updatedUser) {
        expect(updatedUser.freeAiScansRemaining, 0);
      });
      verifyNever(() => mockAuthLocalDs.updateUserLocally(any()));
    });

    test('should return CacheFailure when update fails', () async {
      // Note: updateUserLocally returns void, so we test failure by throwing
      // an exception. This is consistent with the implementation which catches
      // exceptions and returns CacheFailure.
      final user = createTestUser(freeAiScansRemaining: 5);
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);
      when(
        () => mockAuthLocalDs.updateUserLocally(any()),
      ).thenThrow(Exception('Storage write failed'));

      final result = await usecase.decrementScanCount();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return CacheFailure when exception thrown', () async {
      final user = createTestUser(freeAiScansRemaining: 5);
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);
      when(
        () => mockAuthLocalDs.updateUserLocally(any()),
      ).thenThrow(Exception('Storage error'));

      final result = await usecase.decrementScanCount();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('resetScansForPremium', () {
    test(
      'should return AuthenticationFailure when no user is logged in',
      () async {
        when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(null);

        final result = await usecase.resetScansForPremium();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Should return failure'),
        );
      },
    );

    test('should set user to premium status', () async {
      final user = createTestUser(
        subscriptionStatus: const SubscriptionStatus.free(),
        freeAiScansRemaining: 2,
      );
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);
      when(
        () => mockAuthLocalDs.updateUserLocally(any()),
      ).thenAnswer((_) async => true);

      final result = await usecase.resetScansForPremium();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (updatedUser) {
        expect(updatedUser.subscriptionStatus, SubscriptionStatus.premium());
        expect(updatedUser.freeAiScansRemaining, kDefaultFreeAiScans);
      });
    });
  });

  group('updateScanCount', () {
    test(
      'should return AuthenticationFailure when no user is logged in',
      () async {
        when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(null);

        final result = await usecase.updateScanCount(5);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthenticationFailure>()),
          (_) => fail('Should return failure'),
        );
      },
    );

    test('should update scan count to specific value', () async {
      final user = createTestUser(freeAiScansRemaining: 2);
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);
      when(
        () => mockAuthLocalDs.updateUserLocally(any()),
      ).thenAnswer((_) async => true);

      final result = await usecase.updateScanCount(4);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (updatedUser) {
        expect(updatedUser.freeAiScansRemaining, 4);
      });
    });

    test('should clamp value to not exceed default', () async {
      final user = createTestUser(freeAiScansRemaining: 2);
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);
      when(
        () => mockAuthLocalDs.updateUserLocally(any()),
      ).thenAnswer((_) async => true);

      final result = await usecase.updateScanCount(10);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (updatedUser) {
        expect(updatedUser.freeAiScansRemaining, kDefaultFreeAiScans);
      });
    });

    test('should clamp value to not go below 0', () async {
      final user = createTestUser(freeAiScansRemaining: 2);
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);
      when(
        () => mockAuthLocalDs.updateUserLocally(any()),
      ).thenAnswer((_) async => true);

      final result = await usecase.updateScanCount(-5);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (updatedUser) {
        expect(updatedUser.freeAiScansRemaining, 0);
      });
    });
  });

  group('boundary cases', () {
    test('should handle exactly 5 scans (default)', () {
      final user = createTestUser(freeAiScansRemaining: 5);
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);

      expect(usecase.getRemainingScans(), 5);
      expect(usecase.hasRemainingScans(), isTrue);
    });

    test('should handle decrement from 5 to 4', () async {
      final user = createTestUser(freeAiScansRemaining: 5);
      when(() => mockAuthLocalDs.getCurrentUser()).thenReturn(user);
      when(
        () => mockAuthLocalDs.updateUserLocally(any()),
      ).thenAnswer((_) async => true);

      final result = await usecase.decrementScanCount();

      result.fold(
        (_) => fail('Should return success'),
        (updatedUser) => expect(updatedUser.freeAiScansRemaining, 4),
      );
    });
  });
}
