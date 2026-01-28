import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/repositories/auth_repository.dart';

/// Supported OAuth providers.
enum OAuthProvider {
  google('google'),
  apple('apple');

  const OAuthProvider(this.value);
  final String value;
}

/// Parameters for [OAuthLoginUseCase].
class OAuthLoginParams {
  const OAuthLoginParams({
    required this.provider,
    required this.idToken,
  });

  final OAuthProvider provider;
  final String idToken;
}

/// Use case for OAuth login (Google, Apple).
///
/// Returns [Right(User)] on successful authentication.
/// Returns [Left(Failure)] on error.
class OAuthLoginUseCase {
  const OAuthLoginUseCase(this._repository);

  final AuthRepository _repository;

  /// Executes the OAuth login use case.
  ///
  /// Validates the ID token before calling the repository.
  Future<Either<Failure, User>> call(OAuthLoginParams params) async {
    // Basic validation
    final validationError = _validate(params);
    if (validationError != null) {
      return Left(validationError);
    }

    return _repository.oauthLogin(
      provider: params.provider.value,
      idToken: params.idToken,
    );
  }

  /// Validates OAuth login parameters.
  Failure? _validate(OAuthLoginParams params) {
    if (params.idToken.isEmpty) {
      return const OAuthFailure(message: 'Invalid OAuth token');
    }

    return null;
  }
}
