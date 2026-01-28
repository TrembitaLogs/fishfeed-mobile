import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/repositories/auth_repository.dart';

/// Parameters for [LoginUseCase].
class LoginParams {
  const LoginParams({required this.email, required this.password});

  final String email;
  final String password;
}

/// Use case for user login with email and password.
///
/// Returns [Right(User)] on successful authentication.
/// Returns [Left(Failure)] on error.
class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  /// Executes the login use case.
  ///
  /// Validates input before calling the repository.
  Future<Either<Failure, User>> call(LoginParams params) async {
    // Basic validation
    final validationError = _validate(params);
    if (validationError != null) {
      return Left(validationError);
    }

    return _repository.login(
      email: params.email.trim(),
      password: params.password,
    );
  }

  /// Validates login parameters.
  ValidationFailure? _validate(LoginParams params) {
    final errors = <String, List<String>>{};

    final email = params.email.trim();
    if (email.isEmpty) {
      errors['email'] = ['Email is required'];
    } else if (!_isValidEmail(email)) {
      errors['email'] = ['Invalid email format'];
    }

    if (params.password.isEmpty) {
      errors['password'] = ['Password is required'];
    }

    if (errors.isNotEmpty) {
      return ValidationFailure(errors: errors);
    }

    return null;
  }

  /// Simple email format validation.
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }
}
