import 'package:dartz/dartz.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/core/utils/date_time_utils.dart';
import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/feeding_log_local_ds.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';
import 'package:fishfeed/domain/entities/feeding_history.dart';

/// Parameters for [CalculateFeedingHistoryUseCase].
class CalculateFeedingHistoryParams {
  const CalculateFeedingHistoryParams({
    required this.userId,
    required this.range,
    this.aquariumId,
    this.onlyMyActions = false,
    this.referenceNow,
  });

  final String userId;
  final FeedingHistoryRange range;
  final String? aquariumId;
  final bool onlyMyActions;

  /// Injectable "now" for deterministic tests. Defaults to [DateTime.now].
  final DateTime? referenceNow;
}

/// Aggregates local feeding log data into a [FeedingHistory] summary.
///
/// Reads from Hive datasources only — no network calls. Filters logs to
/// `action == 'fed'` and accessible (non-deleted) aquariums, then groups by
/// local-time calendar day and computes totals, best-weekday, per-aquarium
/// sparkline, and streak values.
///
/// Returns [Right(FeedingHistory)] on success.
/// Returns [Left(ValidationFailure)] if [userId] is empty.
/// Returns [Left(CacheFailure)] on any unexpected local-storage error.
class CalculateFeedingHistoryUseCase {
  CalculateFeedingHistoryUseCase({
    required FeedingLogLocalDataSource feedingLogDataSource,
    required AquariumLocalDataSource aquariumDataSource,
    required StreakLocalDataSource streakDataSource,
  }) : _logs = feedingLogDataSource,
       _aquariums = aquariumDataSource,
       _streaks = streakDataSource;

  final FeedingLogLocalDataSource _logs;
  final AquariumLocalDataSource _aquariums;
  final StreakLocalDataSource _streaks;

  Future<Either<Failure, FeedingHistory>> call(
    CalculateFeedingHistoryParams params,
  ) async {
    if (params.userId.isEmpty) {
      return const Left(ValidationFailure(message: 'userId must not be empty'));
    }

    try {
      final now = params.referenceNow ?? DateTime.now();
      final endDay = DateTimeUtils.startOfDay(now);
      final startDay = endDay.subtract(
        Duration(days: params.range.durationInDays - 1),
      );

      final accessibleAquariums = _aquariums
          .getAll()
          .where((a) => !a.isDeleted)
          .toList(growable: false);
      final accessibleIds = accessibleAquariums.map((a) => a.id).toSet();

      final filtered = _logs
          .getAll()
          .where((log) => log.action == 'fed')
          .where((log) => accessibleIds.contains(log.aquariumId))
          .where((log) {
            if (params.aquariumId == null) return true;
            return log.aquariumId == params.aquariumId;
          })
          .where((log) {
            if (!params.onlyMyActions) return true;
            return log.actedByUserId == params.userId;
          })
          .toList(growable: false);

      final byDay = <DateTime, _DayBucket>{};
      for (final log in filtered) {
        final dayKey = DateTimeUtils.startOfDay(log.actedAt.toLocal());
        if (dayKey.isBefore(startDay) || dayKey.isAfter(endDay)) continue;
        final bucket = byDay.putIfAbsent(dayKey, () => _DayBucket());
        bucket.fedCount += 1;
        bucket.aquariumIds.add(log.aquariumId);
      }

      final days = <FeedingHistoryDay>[];
      var cursor = startDay;
      while (!cursor.isAfter(endDay)) {
        final bucket = byDay[cursor];
        days.add(
          FeedingHistoryDay(
            date: cursor,
            fedCount: bucket?.fedCount ?? 0,
            aquariumIds:
                bucket?.aquariumIds.toList(growable: false) ?? const [],
          ),
        );
        cursor = cursor.add(const Duration(days: 1));
      }

      final totalFedCount = days.fold<int>(0, (sum, d) => sum + d.fedCount);
      final bestDayOfWeek = _computeBestDayOfWeek(days);
      final aquariumBreakdown = _computeBreakdown(
        accessibleAquariums: accessibleAquariums,
        filteredLogs: filtered,
        endDay: endDay,
        params: params,
      );

      final streak = _streaks.getStreakByUserId(params.userId);

      return Right(
        FeedingHistory(
          range: params.range,
          rangeStart: startDay,
          rangeEnd: endDay,
          days: days,
          totalFedCount: totalFedCount,
          currentStreak: streak?.currentStreak ?? 0,
          longestStreak: streak?.longestStreak ?? 0,
          bestDayOfWeek: bestDayOfWeek,
          aquariumBreakdown: aquariumBreakdown,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(message: 'Failed to compute feeding history: $e'),
      );
    }
  }

  int? _computeBestDayOfWeek(List<FeedingHistoryDay> days) {
    final byWeekday = <int, int>{};
    for (final d in days) {
      byWeekday.update(
        d.date.weekday,
        (v) => v + d.fedCount,
        ifAbsent: () => d.fedCount,
      );
    }
    if (byWeekday.values.every((v) => v == 0)) return null;
    return byWeekday.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  List<AquariumSparkline> _computeBreakdown({
    required List<AquariumModel> accessibleAquariums,
    required List<FeedingLogModel> filteredLogs,
    required DateTime endDay,
    required CalculateFeedingHistoryParams params,
  }) {
    if (params.aquariumId != null) return const [];
    if (accessibleAquariums.length < 2) return const [];

    final last7Start = endDay.subtract(const Duration(days: 6));
    final result = <AquariumSparkline>[];
    for (final aq in accessibleAquariums) {
      final logsForAq = filteredLogs
          .where((l) => l.aquariumId == aq.id)
          .toList();
      final last7Counts = List<int>.filled(7, 0);
      for (final log in logsForAq) {
        final dayKey = DateTimeUtils.startOfDay(log.actedAt.toLocal());
        if (dayKey.isBefore(last7Start) || dayKey.isAfter(endDay)) continue;
        final index = dayKey.difference(last7Start).inDays;
        last7Counts[index] += 1;
      }
      result.add(
        AquariumSparkline(
          aquariumId: aq.id,
          aquariumName: aq.name,
          last7DaysCounts: last7Counts,
          totalCountInRange: logsForAq.length,
        ),
      );
    }
    return result;
  }
}

class _DayBucket {
  int fedCount = 0;
  final Set<String> aquariumIds = <String>{};
}
