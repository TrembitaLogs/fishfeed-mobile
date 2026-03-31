import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/domain/entities/streak.dart';
import 'package:fishfeed/domain/repositories/streak_repository.dart';

/// Implementation of [StreakRepository] using local Hive storage.
class StreakRepositoryImpl implements StreakRepository {
  StreakRepositoryImpl({required StreakLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final StreakLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, Streak>> getStreak(String userId) async {
    try {
      final model = _localDataSource.getStreakByUserId(userId);
      if (model == null) {
        return Left(CacheFailure(message: 'Streak not found for user'));
      }
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get streak: $e'));
    }
  }

  @override
  Stream<Streak> watchStreak(String userId) {
    return _localDataSource.watchStreak(userId).map(
      (model) => model?.toEntity() ?? Streak(
        id: 'streak_$userId',
        userId: userId,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> updateStreak(Streak streak) async {
    try {
      final model = _localDataSource.getStreakByUserId(streak.userId);
      if (model == null) {
        return Left(CacheFailure(message: 'Streak not found'));
      }
      model.currentStreak = streak.currentStreak;
      model.longestStreak = streak.longestStreak;
      model.synced = false;
      model.updatedAt = DateTime.now().toUtc();
      await _localDataSource.saveStreak(model);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to update streak: $e'));
    }
  }

  @override
  Future<Either<Failure, Streak>> incrementStreak(
    String userId,
    DateTime feedingDate,
  ) async {
    try {
      final model = await _localDataSource.incrementStreak(userId, feedingDate);
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to increment streak: $e'));
    }
  }

  @override
  Future<Either<Failure, Streak>> handleMissedDay(
    String userId,
    DateTime missedDate,
  ) async {
    try {
      final model = await _localDataSource.handleMissedDay(userId, missedDate);
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to handle missed day: $e'));
    }
  }

  @override
  Future<Either<Failure, Streak>> useFreeze(
    String userId,
    DateTime freezeDate,
  ) async {
    try {
      final model = await _localDataSource.useFreeze(userId, freezeDate);
      if (model == null) {
        return Left(
          ValidationFailure(message: 'No freeze days available'),
        );
      }
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to use freeze: $e'));
    }
  }

  @override
  Future<Either<Failure, Streak>> resetMonthlyFreeze(String userId) async {
    try {
      final model = await _localDataSource.resetMonthlyFreeze(userId);
      if (model == null) {
        return Left(CacheFailure(message: 'Streak not found'));
      }
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to reset monthly freeze: $e'));
    }
  }

  @override
  Future<bool> needsMonthlyFreezeReset(String userId) async {
    return _localDataSource.needsMonthlyFreezeReset(userId);
  }
}

/// Provider for [StreakRepository].
final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  final streakDs = ref.watch(streakLocalDataSourceProvider);
  return StreakRepositoryImpl(localDataSource: streakDs);
});
