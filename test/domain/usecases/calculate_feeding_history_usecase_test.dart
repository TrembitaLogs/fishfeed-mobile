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
        when(() => mockAquariums.getAll()).thenReturn(aquariums);
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
}
