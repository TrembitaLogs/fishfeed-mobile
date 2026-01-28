import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/auth_local_ds.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/models/user_model.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';

/// Default number of free AI scans for new users.
const int kDefaultFreeAiScans = 5;

/// Use case for managing AI scan limits.
///
/// Handles:
/// - Checking remaining free scans
/// - Decrementing scan count after successful scan
/// - Resetting scans for premium users
class AiScanLimitUsecase {
  AiScanLimitUsecase({required AuthLocalDataSource authLocalDataSource})
    : _authLocalDataSource = authLocalDataSource;

  final AuthLocalDataSource _authLocalDataSource;

  /// Gets the number of remaining free AI scans.
  ///
  /// Returns 0 if no user is logged in.
  /// Premium users always have unlimited scans (returns -1).
  int getRemainingScans() {
    final userModel = _authLocalDataSource.getCurrentUser();
    if (userModel == null) return 0;

    // Premium users have unlimited scans
    if (userModel.subscriptionStatus == SubscriptionStatus.premium()) {
      return -1; // -1 indicates unlimited
    }

    return userModel.freeAiScansRemaining;
  }

  /// Checks if the user has remaining free scans.
  ///
  /// Returns `true` if:
  /// - User is premium (unlimited scans)
  /// - User has at least 1 free scan remaining
  ///
  /// Returns `false` if:
  /// - No user is logged in
  /// - Free user with 0 scans remaining
  bool hasRemainingScans() {
    final remaining = getRemainingScans();
    return remaining == -1 || remaining > 0;
  }

  /// Checks if the user is a premium subscriber.
  bool isPremiumUser() {
    final userModel = _authLocalDataSource.getCurrentUser();
    if (userModel == null) return false;
    return userModel.subscriptionStatus == SubscriptionStatus.premium();
  }

  /// Decrements the free scan count after a successful scan.
  ///
  /// Does nothing if:
  /// - No user is logged in
  /// - User is premium (unlimited scans)
  /// - User already has 0 scans remaining
  ///
  /// Returns [Right(User)] with updated scan count on success.
  /// Returns [Left(Failure)] on error.
  Future<Either<Failure, User>> decrementScanCount() async {
    final userModel = _authLocalDataSource.getCurrentUser();

    if (userModel == null) {
      return const Left(AuthenticationFailure(message: 'No user logged in'));
    }

    // Premium users don't consume free scans
    if (userModel.subscriptionStatus == SubscriptionStatus.premium()) {
      return Right(userModel.toEntity());
    }

    // Don't go below 0
    if (userModel.freeAiScansRemaining <= 0) {
      return Right(userModel.toEntity());
    }

    // Decrement and save
    final newCount = userModel.freeAiScansRemaining - 1;
    final updatedModel = UserModel(
      id: userModel.id,
      email: userModel.email,
      displayName: userModel.displayName,
      avatarUrl: userModel.avatarUrl,
      createdAt: userModel.createdAt,
      subscriptionStatus: userModel.subscriptionStatus,
      freeAiScansRemaining: newCount,
      settings: userModel.settings,
    );

    try {
      await _authLocalDataSource.updateUserLocally(updatedModel);
      return Right(updatedModel.toEntity());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save scan count: $e'));
    }
  }

  /// Resets scan count for premium users (sets to unlimited).
  ///
  /// This is typically called when a user upgrades to premium.
  /// For premium users, the scan count field is ignored.
  ///
  /// Returns [Right(User)] on success.
  /// Returns [Left(Failure)] on error.
  Future<Either<Failure, User>> resetScansForPremium() async {
    final userModel = _authLocalDataSource.getCurrentUser();

    if (userModel == null) {
      return const Left(AuthenticationFailure(message: 'No user logged in'));
    }

    final updatedModel = UserModel(
      id: userModel.id,
      email: userModel.email,
      displayName: userModel.displayName,
      avatarUrl: userModel.avatarUrl,
      createdAt: userModel.createdAt,
      subscriptionStatus: SubscriptionStatus.premium(),
      freeAiScansRemaining:
          kDefaultFreeAiScans, // Reset to default (not used for premium)
      settings: userModel.settings,
    );

    try {
      await _authLocalDataSource.updateUserLocally(updatedModel);
      return Right(updatedModel.toEntity());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save premium status: $e'));
    }
  }

  /// Updates the free scan count to a specific value.
  ///
  /// Used when syncing with backend or restoring scans.
  ///
  /// Returns [Right(User)] on success.
  /// Returns [Left(Failure)] on error.
  Future<Either<Failure, User>> updateScanCount(int newCount) async {
    final userModel = _authLocalDataSource.getCurrentUser();

    if (userModel == null) {
      return const Left(AuthenticationFailure(message: 'No user logged in'));
    }

    final updatedModel = UserModel(
      id: userModel.id,
      email: userModel.email,
      displayName: userModel.displayName,
      avatarUrl: userModel.avatarUrl,
      createdAt: userModel.createdAt,
      subscriptionStatus: userModel.subscriptionStatus,
      freeAiScansRemaining: newCount.clamp(0, kDefaultFreeAiScans),
      settings: userModel.settings,
    );

    try {
      await _authLocalDataSource.updateUserLocally(updatedModel);
      return Right(updatedModel.toEntity());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save scan count: $e'));
    }
  }
}

/// Provider for [AiScanLimitUsecase].
///
/// Usage:
/// ```dart
/// final usecase = ref.watch(aiScanLimitUsecaseProvider);
/// if (usecase.hasRemainingScans()) {
///   await usecase.decrementScanCount();
/// }
/// ```
final aiScanLimitUsecaseProvider = Provider<AiScanLimitUsecase>((ref) {
  final authLocalDataSource = ref.watch(authLocalDataSourceProvider);
  return AiScanLimitUsecase(authLocalDataSource: authLocalDataSource);
});
