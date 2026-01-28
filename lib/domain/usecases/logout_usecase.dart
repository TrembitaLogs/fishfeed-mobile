import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/repositories/auth_repository.dart';

/// Use case for user logout.
///
/// Clears local authentication data and invalidates the refresh token on server.
/// Returns [Right(unit)] on success (always succeeds for local data clearing).
class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  /// Executes the logout use case.
  ///
  /// Always clears local data, even if server logout fails.
  Future<Either<Failure, Unit>> call() async {
    return _repository.logout();
  }
}
