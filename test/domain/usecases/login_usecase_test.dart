import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/repositories/auth_repository.dart';
import 'package:fishfeed/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late LoginUseCase useCase;

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
    useCase = LoginUseCase(mockRepository);
  });

  group('LoginUseCase', () {
    test('should return User on successful login', () async {
      when(
        () => mockRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(testUser));

      final result = await useCase(
        const LoginParams(email: 'test@example.com', password: 'password123'),
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (user) => expect(user.email, 'test@example.com'),
      );
    });

    test('should return ValidationFailure when email is empty', () async {
      final result = await useCase(
        const LoginParams(email: '', password: 'password123'),
      );

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        final validationFailure = failure as ValidationFailure;
        expect(validationFailure.errors['email'], isNotEmpty);
      }, (_) => fail('Should be Left'));

      verifyNever(
        () => mockRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    test('should return ValidationFailure when email is invalid', () async {
      final result = await useCase(
        const LoginParams(email: 'invalid-email', password: 'password123'),
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

    test('should return ValidationFailure when password is empty', () async {
      final result = await useCase(
        const LoginParams(email: 'test@example.com', password: ''),
      );

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        final validationFailure = failure as ValidationFailure;
        expect(validationFailure.errors['password'], isNotEmpty);
      }, (_) => fail('Should be Left'));
    });

    test('should trim email before validation', () async {
      when(
        () => mockRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(testUser));

      await useCase(
        const LoginParams(
          email: '  test@example.com  ',
          password: 'password123',
        ),
      );

      verify(
        () => mockRepository.login(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    test('should propagate repository failures', () async {
      when(
        () => mockRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Left(AuthenticationFailure()));

      final result = await useCase(
        const LoginParams(
          email: 'test@example.com',
          password: 'wrong-password',
        ),
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<AuthenticationFailure>()),
        (_) => fail('Should be Left'),
      );
    });
  });
}
