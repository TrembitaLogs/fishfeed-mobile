import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/repositories/auth_repository.dart';
import 'package:fishfeed/domain/usecases/oauth_login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late OAuthLoginUseCase useCase;

  final testUser = User(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: DateTime(2024, 1, 15),
    subscriptionStatus: const SubscriptionStatus.free(),
    freeAiScansRemaining: 5,
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = OAuthLoginUseCase(mockRepository);
  });

  group('OAuthLoginUseCase', () {
    test('should return User on successful Google login', () async {
      when(
        () => mockRepository.oauthLogin(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
        ),
      ).thenAnswer((_) async => Right(testUser));

      final result = await useCase(
        const OAuthLoginParams(
          provider: OAuthProvider.google,
          idToken: 'google-id-token',
        ),
      );

      expect(result.isRight(), true);
      verify(
        () => mockRepository.oauthLogin(
          provider: 'google',
          idToken: 'google-id-token',
        ),
      ).called(1);
    });

    test('should return User on successful Apple login', () async {
      when(
        () => mockRepository.oauthLogin(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
        ),
      ).thenAnswer((_) async => Right(testUser));

      final result = await useCase(
        const OAuthLoginParams(
          provider: OAuthProvider.apple,
          idToken: 'apple-id-token',
        ),
      );

      expect(result.isRight(), true);
      verify(
        () => mockRepository.oauthLogin(
          provider: 'apple',
          idToken: 'apple-id-token',
        ),
      ).called(1);
    });

    test('should return OAuthFailure when idToken is empty', () async {
      final result = await useCase(
        const OAuthLoginParams(provider: OAuthProvider.google, idToken: ''),
      );

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<OAuthFailure>());
        expect((failure as OAuthFailure).message, 'Invalid OAuth token');
      }, (_) => fail('Should be Left'));

      verifyNever(
        () => mockRepository.oauthLogin(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
        ),
      );
    });

    test('should propagate repository failures', () async {
      when(
        () => mockRepository.oauthLogin(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
        ),
      ).thenAnswer((_) async => const Left(OAuthFailure(provider: 'google')));

      final result = await useCase(
        const OAuthLoginParams(
          provider: OAuthProvider.google,
          idToken: 'invalid-token',
        ),
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<OAuthFailure>()),
        (_) => fail('Should be Left'),
      );
    });
  });

  group('OAuthProvider', () {
    test('should have correct values', () {
      expect(OAuthProvider.google.value, 'google');
      expect(OAuthProvider.apple.value, 'apple');
    });
  });
}
