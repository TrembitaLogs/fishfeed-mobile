import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/repositories/auth_repository.dart';
import 'package:fishfeed/domain/usecases/register_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late RegisterUseCase useCase;

  final testUser = User(
    id: 'user-123',
    email: 'new@example.com',
    displayName: null,
    createdAt: DateTime(2024, 1, 15),
    subscriptionStatus: const SubscriptionStatus.free(),
    freeAiScansRemaining: 5,
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RegisterUseCase(mockRepository);
  });

  group('RegisterUseCase', () {
    test('should return User on successful registration', () async {
      when(
        () => mockRepository.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Right(testUser));

      final result = await useCase(
        const RegisterParams(
          email: 'new@example.com',
          password: 'Password1',
          confirmPassword: 'Password1',
        ),
      );

      expect(result.isRight(), true);
    });

    test('should return ValidationFailure when email is empty', () async {
      final result = await useCase(
        const RegisterParams(
          email: '',
          password: 'Password1',
          confirmPassword: 'Password1',
        ),
      );

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        final validationFailure = failure as ValidationFailure;
        expect(validationFailure.errors['email'], isNotEmpty);
      }, (_) => fail('Should be Left'));
    });

    test('should return ValidationFailure when email is invalid', () async {
      final result = await useCase(
        const RegisterParams(
          email: 'not-an-email',
          password: 'Password1',
          confirmPassword: 'Password1',
        ),
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

    test(
      'should return ValidationFailure when password is too short',
      () async {
        final result = await useCase(
          const RegisterParams(
            email: 'new@example.com',
            password: 'Pass1',
            confirmPassword: 'Pass1',
          ),
        );

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          final validationFailure = failure as ValidationFailure;
          expect(
            validationFailure.errors['password'],
            contains('Password must be at least 8 characters'),
          );
        }, (_) => fail('Should be Left'));
      },
    );

    test(
      'should return ValidationFailure when password has no uppercase',
      () async {
        final result = await useCase(
          const RegisterParams(
            email: 'new@example.com',
            password: 'password1',
            confirmPassword: 'password1',
          ),
        );

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          final validationFailure = failure as ValidationFailure;
          expect(
            validationFailure.errors['password'],
            contains('Password must contain an uppercase letter'),
          );
        }, (_) => fail('Should be Left'));
      },
    );

    test(
      'should return ValidationFailure when password has no lowercase',
      () async {
        final result = await useCase(
          const RegisterParams(
            email: 'new@example.com',
            password: 'PASSWORD1',
            confirmPassword: 'PASSWORD1',
          ),
        );

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          final validationFailure = failure as ValidationFailure;
          expect(
            validationFailure.errors['password'],
            contains('Password must contain a lowercase letter'),
          );
        }, (_) => fail('Should be Left'));
      },
    );

    test(
      'should return ValidationFailure when password has no number',
      () async {
        final result = await useCase(
          const RegisterParams(
            email: 'new@example.com',
            password: 'Password',
            confirmPassword: 'Password',
          ),
        );

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          final validationFailure = failure as ValidationFailure;
          expect(
            validationFailure.errors['password'],
            contains('Password must contain a number'),
          );
        }, (_) => fail('Should be Left'));
      },
    );

    test(
      'should return ValidationFailure when passwords do not match',
      () async {
        final result = await useCase(
          const RegisterParams(
            email: 'new@example.com',
            password: 'Password1',
            confirmPassword: 'Password2',
          ),
        );

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          final validationFailure = failure as ValidationFailure;
          expect(
            validationFailure.errors['confirmPassword'],
            contains('Passwords do not match'),
          );
        }, (_) => fail('Should be Left'));
      },
    );

    test(
      'should return multiple errors for multiple validation failures',
      () async {
        final result = await useCase(
          const RegisterParams(
            email: 'invalid',
            password: 'short',
            confirmPassword: 'different',
          ),
        );

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          final validationFailure = failure as ValidationFailure;
          expect(
            validationFailure.errors.keys,
            containsAll(['email', 'password', 'confirmPassword']),
          );
        }, (_) => fail('Should be Left'));
      },
    );

    test('should propagate repository failures', () async {
      when(
        () => mockRepository.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          ValidationFailure(
            errors: {
              'email': ['Email already exists'],
            },
          ),
        ),
      );

      final result = await useCase(
        const RegisterParams(
          email: 'existing@example.com',
          password: 'Password1',
          confirmPassword: 'Password1',
        ),
      );

      expect(result.isLeft(), true);
    });
  });
}
