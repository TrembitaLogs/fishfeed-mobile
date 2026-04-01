import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/domain/entities/schedule.dart';
import 'package:fishfeed/domain/repositories/schedule_repository.dart';

/// Implementation of [ScheduleRepository] using local Hive storage.
class ScheduleRepositoryImpl implements ScheduleRepository {
  ScheduleRepositoryImpl({required ScheduleLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final ScheduleLocalDataSource _localDataSource;

  @override
  List<Schedule> getSchedulesForFish(String fishId, {bool activeOnly = false}) {
    return _localDataSource
        .getByFishId(fishId, activeOnly: activeOnly)
        .map((model) => model.toEntity())
        .toList();
  }
}

/// Riverpod provider for [ScheduleRepository].
final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final scheduleDs = ref.watch(scheduleLocalDataSourceProvider);
  return ScheduleRepositoryImpl(localDataSource: scheduleDs);
});
