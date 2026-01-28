import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/repositories/auth_repository.dart';
import 'package:fishfeed/domain/usecases/logout_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late LogoutUseCase useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LogoutUseCase(mockRepository);
  });

  group('LogoutUseCase', () {
    test('should return unit on successful logout', () async {
      when(() => mockRepository.logout())
          .thenAnswer((_) async => const Right(unit));

      final result = await useCase();

      expect(result.isRight(), true);
      verify(() => mockRepository.logout()).called(1);
    });

    test('should propagate repository failures', () async {
      when(() => mockRepository.logout())
          .thenAnswer((_) async => const Left(NetworkFailure()));

      final result = await useCase();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should be Left'),
      );
    });
  });
}
