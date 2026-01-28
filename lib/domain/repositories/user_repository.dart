import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/entities/user.dart';

/// Repository interface for user operations.
///
/// Provides a clean API for user profile management following Clean Architecture.
/// All methods return [Either] type for explicit error handling.
abstract interface class UserRepository {
  /// Updates the current user's display name.
  ///
  /// Returns [Right(User)] with updated user data on success.
  /// Returns [Left(Failure)] on error:
  /// - [ValidationFailure] for invalid display name
  /// - [AuthenticationFailure] if not authenticated
  /// - [NetworkFailure] for connectivity issues
  /// - [ServerFailure] for server errors
  Future<Either<Failure, User>> updateDisplayName({
    required String displayName,
  });

  /// Updates the current user's avatar.
  ///
  /// [avatarFile] - The image file to upload as avatar.
  ///
  /// Returns [Right(User)] with updated user data including new avatar URL.
  /// Returns [Left(Failure)] on error:
  /// - [ValidationFailure] for invalid file format/size
  /// - [AuthenticationFailure] if not authenticated
  /// - [NetworkFailure] for connectivity issues
  /// - [ServerFailure] for server errors
  Future<Either<Failure, User>> updateAvatar({
    required File avatarFile,
  });
}
