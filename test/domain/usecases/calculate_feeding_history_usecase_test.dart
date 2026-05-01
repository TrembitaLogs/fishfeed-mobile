import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/feeding_log_local_ds.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';
import 'package:fishfeed/data/models/streak_model.dart';
import 'package:fishfeed/domain/entities/feeding_history.dart';
import 'package:fishfeed/domain/usecases/calculate_feeding_history_usecase.dart';

class MockFeedingLogLocalDataSource extends Mock
    implements FeedingLogLocalDataSource {}

class MockAquariumLocalDataSource extends Mock
    implements AquariumLocalDataSource {}

class MockStreakLocalDataSource extends Mock implements StreakLocalDataSource {}

void main() {
  late MockFeedingLogLocalDataSource mockLogs;
  late MockAquariumLocalDataSource mockAquariums;
  late MockStreakLocalDataSource mockStreaks;
  late CalculateFeedingHistoryUseCase useCase;

  setUp(() {
    mockLogs = MockFeedingLogLocalDataSource();
    mockAquariums = MockAquariumLocalDataSource();
    mockStreaks = MockStreakLocalDataSource();
    useCase = CalculateFeedingHistoryUseCase(
      feedingLogDataSource: mockLogs,
      aquariumDataSource: mockAquariums,
      streakDataSource: mockStreaks,
    );
  });

  AquariumModel buildAquarium(String id, {String? name}) => AquariumModel(
    id: id,
    userId: 'user_1',
    name: name ?? 'Tank $id',
    createdAt: DateTime(2025, 1, 1),
  );

  FeedingLogModel buildLog({
    required String aquariumId,
    required DateTime actedAtLocal,
    String action = 'fed',
    String actedByUserId = 'user_1',
  }) {
    return FeedingLogModel(
      id: '${aquariumId}_${actedAtLocal.millisecondsSinceEpoch}',
      scheduleId: 's_1',
      fishId: 'f_1',
      aquariumId: aquariumId,
      scheduledFor: actedAtLocal,
      action: action,
      actedAt: actedAtLocal,
      actedByUserId: actedByUserId,
      deviceId: 'dev_1',
      createdAt: actedAtLocal,
    );
  }

  group('happy path — single aquarium, all fed', () {
    test(
      'returns dense day list with correct fedCounts for 7d range',
      () async {
        final today = DateTime(2026, 5, 1, 9, 0); // 09:00 local
        final aquariums = [buildAquarium('aq_1', name: 'Office')];
        // 5 days ago: 1 feeding; 3 days ago: 2 feedings; today: 3 feedings.
        final logs = [
          buildLog(
            aquariumId: 'aq_1',
            actedAtLocal: today.subtract(const Duration(days: 5)),
          ),
          buildLog(
            aquariumId: 'aq_1',
            actedAtLocal: today.subtract(const Duration(days: 3, hours: 2)),
          ),
          buildLog(
            aquariumId: 'aq_1',
            actedAtLocal: today.subtract(const Duration(days: 3, hours: 4)),
          ),
          buildLog(
            aquariumId: 'aq_1',
            actedAtLocal: today.subtract(const Duration(hours: 1)),
          ),
          buildLog(aquariumId: 'aq_1', actedAtLocal: today),
          buildLog(
            aquariumId: 'aq_1',
            actedAtLocal: today.add(const Duration(hours: 2)),
          ),
        ];
        when(() => mockAquariums.getAllAquariums()).thenReturn(aquariums);
        when(() => mockLogs.getAll()).thenReturn(logs);
        when(() => mockStreaks.getStreakByUserId('user_1')).thenReturn(
          StreakModel(
            id: 'streak_user_1',
            userId: 'user_1',
            currentStreak: 3,
            longestStreak: 12,
          ),
        );

        final result = await useCase(
          CalculateFeedingHistoryParams(
            userId: 'user_1',
            range: FeedingHistoryRange.sevenDays,
            referenceNow: today,
          ),
        );

        expect(result.isRight(), isTrue);
        final history = result.getOrElse(() => throw 'unreachable');
        expect(history.days, hasLength(7));
        expect(
          history.days.first.date.isBefore(history.days.last.date),
          isTrue,
        );
        expect(history.totalFedCount, 6);
        expect(history.currentStreak, 3);
        expect(history.longestStreak, 12);
        expect(history.aquariumBreakdown, isEmpty); // single aquarium
      },
    );
  });

  group('skipped logs are excluded from heatmap and totals', () {
    test('a day with only skipped events shows fedCount=0', () async {
      final today = DateTime(2026, 5, 1, 12, 0);
      when(
        () => mockAquariums.getAllAquariums(),
      ).thenReturn([buildAquarium('aq_1', name: 'A')]);
      when(() => mockLogs.getAll()).thenReturn([
        buildLog(
          aquariumId: 'aq_1',
          actedAtLocal: today.subtract(const Duration(days: 2)),
          action: 'skipped',
        ),
      ]);
      when(() => mockStreaks.getStreakByUserId(any())).thenReturn(null);

      final r = await useCase(
        CalculateFeedingHistoryParams(
          userId: 'user_1',
          range: FeedingHistoryRange.sevenDays,
          referenceNow: today,
        ),
      );

      final history = r.getOrElse(() => throw 'unreachable');
      expect(history.totalFedCount, 0);
      expect(history.days.every((d) => d.fedCount == 0), isTrue);
    });
  });

  group('aquariumId filter narrows to one tank', () {
    test('logs from other accessible aquariums are excluded', () async {
      final today = DateTime(2026, 5, 1, 9, 0);
      when(() => mockAquariums.getAllAquariums()).thenReturn([
        buildAquarium('aq_1', name: 'Office'),
        buildAquarium('aq_2', name: 'Home'),
      ]);
      when(() => mockLogs.getAll()).thenReturn([
        buildLog(aquariumId: 'aq_1', actedAtLocal: today),
        buildLog(aquariumId: 'aq_2', actedAtLocal: today),
        buildLog(aquariumId: 'aq_2', actedAtLocal: today),
      ]);
      when(() => mockStreaks.getStreakByUserId(any())).thenReturn(null);

      final r = await useCase(
        CalculateFeedingHistoryParams(
          userId: 'user_1',
          range: FeedingHistoryRange.sevenDays,
          aquariumId: 'aq_2',
          referenceNow: today,
        ),
      );

      final history = r.getOrElse(() => throw 'unreachable');
      expect(history.totalFedCount, 2);
      expect(history.aquariumBreakdown, isEmpty);
    });
  });

  group('onlyMyActions filter respects acted_by_user_id', () {
    test(
      'logs by other family members are excluded when toggle is on',
      () async {
        final today = DateTime(2026, 5, 1, 9, 0);
        when(
          () => mockAquariums.getAllAquariums(),
        ).thenReturn([buildAquarium('aq_1', name: 'Family')]);
        when(() => mockLogs.getAll()).thenReturn([
          buildLog(
            aquariumId: 'aq_1',
            actedAtLocal: today,
            actedByUserId: 'user_1',
          ),
          buildLog(
            aquariumId: 'aq_1',
            actedAtLocal: today,
            actedByUserId: 'user_2',
          ),
          buildLog(
            aquariumId: 'aq_1',
            actedAtLocal: today,
            actedByUserId: 'user_3',
          ),
        ]);
        when(() => mockStreaks.getStreakByUserId(any())).thenReturn(null);

        final r = await useCase(
          CalculateFeedingHistoryParams(
            userId: 'user_1',
            range: FeedingHistoryRange.sevenDays,
            onlyMyActions: true,
            referenceNow: today,
          ),
        );

        final history = r.getOrElse(() => throw 'unreachable');
        expect(history.totalFedCount, 1);
      },
    );
  });

  group(
    'aquariumBreakdown only when 2+ accessible aquariums and no filter',
    () {
      test('breakdown is non-empty for two aquariums', () async {
        final today = DateTime(2026, 5, 1, 9, 0);
        when(() => mockAquariums.getAllAquariums()).thenReturn([
          buildAquarium('aq_1', name: 'Office'),
          buildAquarium('aq_2', name: 'Home'),
        ]);
        when(() => mockLogs.getAll()).thenReturn([
          buildLog(aquariumId: 'aq_1', actedAtLocal: today),
          buildLog(aquariumId: 'aq_2', actedAtLocal: today),
        ]);
        when(() => mockStreaks.getStreakByUserId(any())).thenReturn(null);

        final r = await useCase(
          CalculateFeedingHistoryParams(
            userId: 'user_1',
            range: FeedingHistoryRange.sevenDays,
            referenceNow: today,
          ),
        );

        final history = r.getOrElse(() => throw 'unreachable');
        expect(history.aquariumBreakdown, hasLength(2));
        expect(history.aquariumBreakdown.first.last7DaysCounts, hasLength(7));
        expect(
          history.aquariumBreakdown
              .firstWhere((b) => b.aquariumId == 'aq_1')
              .totalCountInRange,
          1,
        );
      });
    },
  );

  group('soft-deleted aquariums are excluded from accessible set', () {
    test('logs from a deleted aquarium are dropped', () async {
      final today = DateTime(2026, 5, 1, 9, 0);
      final deleted = AquariumModel(
        id: 'aq_dead',
        userId: 'user_1',
        name: 'Old',
        createdAt: DateTime(2025, 1, 1),
        deletedAt: DateTime(2026, 4, 1),
      );
      when(
        () => mockAquariums.getAllAquariums(),
      ).thenReturn([buildAquarium('aq_1', name: 'Live'), deleted]);
      when(() => mockLogs.getAll()).thenReturn([
        buildLog(aquariumId: 'aq_1', actedAtLocal: today),
        buildLog(aquariumId: 'aq_dead', actedAtLocal: today),
      ]);
      when(() => mockStreaks.getStreakByUserId(any())).thenReturn(null);

      final r = await useCase(
        CalculateFeedingHistoryParams(
          userId: 'user_1',
          range: FeedingHistoryRange.sevenDays,
          referenceNow: today,
        ),
      );

      final history = r.getOrElse(() => throw 'unreachable');
      expect(history.totalFedCount, 1);
    });
  });

  group('bestDayOfWeek', () {
    test('returns the weekday with highest sum across the range', () async {
      // Place 3 feedings on a Tuesday and 1 on a Sunday in a 30-day window.
      final reference = DateTime(2026, 5, 1, 12); // Friday
      // Pick a Tuesday two weeks back: 2026-04-21.
      final tuesday = DateTime(2026, 4, 21, 8);
      // Pick a Sunday: 2026-04-26.
      final sunday = DateTime(2026, 4, 26, 8);
      when(
        () => mockAquariums.getAllAquariums(),
      ).thenReturn([buildAquarium('aq_1', name: 'A')]);
      when(() => mockLogs.getAll()).thenReturn([
        buildLog(aquariumId: 'aq_1', actedAtLocal: tuesday),
        buildLog(
          aquariumId: 'aq_1',
          actedAtLocal: tuesday.add(const Duration(hours: 4)),
        ),
        buildLog(
          aquariumId: 'aq_1',
          actedAtLocal: tuesday.add(const Duration(hours: 6)),
        ),
        buildLog(aquariumId: 'aq_1', actedAtLocal: sunday),
      ]);
      when(() => mockStreaks.getStreakByUserId(any())).thenReturn(null);

      final r = await useCase(
        CalculateFeedingHistoryParams(
          userId: 'user_1',
          range: FeedingHistoryRange.thirtyDays,
          referenceNow: reference,
        ),
      );

      final history = r.getOrElse(() => throw 'unreachable');
      expect(history.bestDayOfWeek, DateTime.tuesday); // 2
    });

    test('returns null when range has no fed events', () async {
      final today = DateTime(2026, 5, 1, 9, 0);
      when(
        () => mockAquariums.getAllAquariums(),
      ).thenReturn([buildAquarium('aq_1', name: 'A')]);
      when(() => mockLogs.getAll()).thenReturn([]);
      when(() => mockStreaks.getStreakByUserId(any())).thenReturn(null);

      final r = await useCase(
        CalculateFeedingHistoryParams(
          userId: 'user_1',
          range: FeedingHistoryRange.sevenDays,
          referenceNow: today,
        ),
      );

      final history = r.getOrElse(() => throw 'unreachable');
      expect(history.bestDayOfWeek, isNull);
    });
  });

  group('validation', () {
    test('returns ValidationFailure when userId is empty', () async {
      final r = await useCase(
        const CalculateFeedingHistoryParams(
          userId: '',
          range: FeedingHistoryRange.sevenDays,
        ),
      );
      expect(r.isLeft(), isTrue);
    });
  });
}
