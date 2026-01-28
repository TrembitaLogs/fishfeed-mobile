import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/repositories/auth_repository.dart';

/// Parameters for [RegisterUseCase].
class RegisterParams {
  const RegisterParams({
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  final String email;
  final String password;
  final String confirmPassword;
}

/// Use case for user registration with email and password.
///
/// Returns [Right(User)] on successful registration.
/// Returns [Left(Failure)] on error.
class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  /// Minimum password length requirement.
  static const int minPasswordLength = 8;

  /// Executes the registration use case.
  ///
  /// Validates input before calling the repository.
  Future<Either<Failure, User>> call(RegisterParams params) async {
    // Basic validation
    final validationError = _validate(params);
    if (validationError != null) {
      return Left(validationError);
    }

    return _repository.register(
      email: params.email.trim(),
      password: params.password,
    );
  }

  /// Validates registration parameters.
  ValidationFailure? _validate(RegisterParams params) {
    final errors = <String, List<String>>{};

    // Email validation
    final email = params.email.trim();
    if (email.isEmpty) {
      errors['email'] = ['Email is required'];
    } else if (!_isValidEmail(email)) {
      errors['email'] = ['Invalid email format'];
    }

    // Password validation
    final passwordErrors = <String>[];
    if (params.password.isEmpty) {
      passwordErrors.add('Password is required');
    } else {
      if (params.password.length < minPasswordLength) {
        passwordErrors.add('Password must be at least $minPasswordLength characters');
      }
      if (!_hasUppercase(params.password)) {
        passwordErrors.add('Password must contain an uppercase letter');
      }
      if (!_hasLowercase(params.password)) {
        passwordErrors.add('Password must contain a lowercase letter');
      }
      if (!_hasDigit(params.password)) {
        passwordErrors.add('Password must contain a number');
      }
    }
    if (passwordErrors.isNotEmpty) {
      errors['password'] = passwordErrors;
    }

    // Confirm password validation
    if (params.confirmPassword.isEmpty) {
      errors['confirmPassword'] = ['Please confirm your password'];
    } else if (params.password != params.confirmPassword) {
      errors['confirmPassword'] = ['Passwords do not match'];
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

  /// Checks if string contains an uppercase letter.
  bool _hasUppercase(String value) {
    return RegExp(r'[A-Z]').hasMatch(value);
  }

  /// Checks if string contains a lowercase letter.
  bool _hasLowercase(String value) {
    return RegExp(r'[a-z]').hasMatch(value);
  }

  /// Checks if string contains a digit.
  bool _hasDigit(String value) {
    return RegExp(r'\d').hasMatch(value);
  }
}
