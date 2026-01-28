import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/constants/levels.dart';
import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/datasources/local/user_progress_local_ds.dart';
import 'package:fishfeed/data/models/feeding_event_model.dart';
import 'package:fishfeed/data/models/user_progress_model.dart';
import 'package:fishfeed/domain/usecases/calculate_statistics_usecase.dart';

class MockFeedingLocalDataSource extends Mock
    implements FeedingLocalDataSource {}

class MockUserProgressLocalDataSource extends Mock
    implements UserProgressLocalDataSource {}

void main() {
  late MockFeedingLocalDataSource mockFeedingDs;
  late MockUserProgressLocalDataSource mockProgressDs;
  late CalculateStatisticsUseCase useCase;

  const testUserId = 'user_123';

  setUp(() {
    mockFeedingDs = MockFeedingLocalDataSource();
    mockProgressDs = MockUserProgressLocalDataSource();
    useCase = CalculateStatisticsUseCase(
      feedingDataSource: mockFeedingDs,
      userProgressDataSource: mockProgressDs,
    );
  });

  FeedingEventModel createFeedingEvent({
    required String id,
    required DateTime feedingTime,
    String fishId = 'fish_1',
    String aquariumId = 'aquarium_1',
  }) {
    return FeedingEventModel(
      id: id,
      fishId: fishId,
      aquariumId: aquariumId,
      feedingTime: feedingTime,
      synced: false,
      createdAt: feedingTime,
    );
  }

  UserProgressModel createProgress({
    required int totalXp,
    String id = 'progress_user_123',
    String userId = testUserId,
  }) {
    return UserProgressModel(
      id: id,
      userId: userId,
      totalXp: totalXp,
    );
  }

  group('CalculateStatisticsUseCase', () {
    group('Total Feedings', () {
      test('should return 0 when no feeding events exist', () async {
        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn([]);
        when(() => mockProgressDs.getProgressByUserId(testUserId))
            .thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (stats) {
            expect(stats.totalFeedings, 0);
          },
        );
      });

      test('should count all feeding events', () async {
        final events = [
          createFeedingEvent(id: '1', feedingTime: DateTime(2025, 1, 1, 8)),
          createFeedingEvent(id: '2', feedingTime: DateTime(2025, 1, 1, 12)),
          createFeedingEvent(id: '3', feedingTime: DateTime(2025, 1, 2, 8)),
        ];

        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn(events);
        when(() => mockProgressDs.getProgressByUserId(testUserId))
            .thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (stats) {
            expect(stats.totalFeedings, 3);
          },
        );
      });
    });

    group('Days With App', () {
      test('should return 0 when no feeding events exist', () async {
        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn([]);
        when(() => mockProgressDs.getProgressByUserId(testUserId))
            .thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (stats) {
            expect(stats.daysWithApp, 0);
          },
        );
      });

      test('should calculate days from first feeding to now', () async {
        final now = DateTime.now();
        final daysAgo = now.subtract(const Duration(days: 10));
        final events = [
          createFeedingEvent(id: '1', feedingTime: daysAgo),
          createFeedingEvent(
              id: '2', feedingTime: now.subtract(const Duration(days: 5))),
          createFeedingEvent(
              id: '3', feedingTime: now.subtract(const Duration(days: 1))),
        ];

        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn(events);
        when(() => mockProgressDs.getProgressByUserId(testUserId))
            .thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (stats) {
            // 10 days ago + 1 (include first day) = 11 days
            expect(stats.daysWithApp, 11);
          },
        );
      });

      test('should return 1 for first day of usage', () async {
        final now = DateTime.now();
        final events = [
          createFeedingEvent(id: '1', feedingTime: now),
        ];

        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn(events);
        when(() => mockProgressDs.getProgressByUserId(testUserId))
            .thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (stats) {
            expect(stats.daysWithApp, 1);
          },
        );
      });
    });

    group('On-Time Percentage', () {
      test('should return 0 when no days with app', () async {
        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn([]);
        when(() => mockProgressDs.getProgressByUserId(testUserId))
            .thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (stats) {
            expect(stats.onTimePercentage, 0.0);
          },
        );
      });

      test('should calculate 100% when all expected feedings are completed',
          () async {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        // 2 days * 4 feedings per day = 8 expected feedings
        final events = [
          createFeedingEvent(
              id: '1', feedingTime: yesterday.add(const Duration(hours: 8))),
          createFeedingEvent(
              id: '2', feedingTime: yesterday.add(const Duration(hours: 12))),
          createFeedingEvent(
              id: '3', feedingTime: yesterday.add(const Duration(hours: 18))),
          createFeedingEvent(
              id: '4', feedingTime: yesterday.add(const Duration(hours: 20))),
          createFeedingEvent(
              id: '5', feedingTime: now.subtract(const Duration(hours: 4))),
          createFeedingEvent(
              id: '6', feedingTime: now.subtract(const Duration(hours: 3))),
          createFeedingEvent(
              id: '7', feedingTime: now.subtract(const Duration(hours: 2))),
          createFeedingEvent(
              id: '8', feedingTime: now.subtract(const Duration(hours: 1))),
        ];

        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn(events);
        when(() => mockProgressDs.getProgressByUserId(testUserId))
            .thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (stats) {
            expect(stats.onTimePercentage, 100.0);
          },
        );
      });

      test('should calculate 50% when half of expected feedings are completed',
          () async {
        // Use dates relative to now to ensure 2 days are counted
        // Need at least 24 hours difference for inDays to return 1
        final now = DateTime.now();
        final twoDaysAgo = DateTime(
          now.year,
          now.month,
          now.day - 1, // Yesterday at midnight
          0,
          0,
        );
        // 2 days * 4 feedings per day = 8 expected, only 4 completed = 50%
        final events = [
          createFeedingEvent(id: '1', feedingTime: twoDaysAgo),
          createFeedingEvent(
              id: '2', feedingTime: twoDaysAgo.add(const Duration(hours: 2))),
          createFeedingEvent(
              id: '3', feedingTime: now.subtract(const Duration(hours: 2))),
          createFeedingEvent(
              id: '4', feedingTime: now.subtract(const Duration(hours: 1))),
        ];

        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn(events);
        when(() => mockProgressDs.getProgressByUserId(testUserId))
            .thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (stats) {
            // 4 feedings / 8 expected (2 days * 4) = 50%
            expect(stats.onTimePercentage, 50.0);
          },
        );
      });

      test('should cap at 100% when over-feeding occurs', () async {
        final now = DateTime.now();
        // 1 day but 10 feedings (more than expected 4)
        final events = List.generate(
          10,
          (i) => createFeedingEvent(
            id: '$i',
            feedingTime: now.subtract(Duration(hours: i)),
          ),
        );

        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn(events);
        when(() => mockProgressDs.getProgressByUserId(testUserId))
            .thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (stats) {
            expect(stats.onTimePercentage, 100.0);
          },
        );
      });

      test('should return 0% when no feedings but days passed', () async {
        // This edge case shouldn't happen normally, but testing for robustness
        // Since we need events to calculate days, this will return 0 days and 0%
        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn([]);
        when(() => mockProgressDs.getProgressByUserId(testUserId))
            .thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (stats) {
            expect(stats.onTimePercentage, 0.0);
          },
        );
      });
    });

    group('Level and XP', () {
      test('should return beginner level with 0 XP when no progress exists',
          () async {
        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn([]);
        when(() => mockProgressDs.getProgressByUserId(testUserId))
            .thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (stats) {
            expect(stats.currentLevel, UserLevel.beginnerAquarist);
            expect(stats.totalXp, 0);
            expect(stats.xpInCurrentLevel, 0);
            expect(stats.xpForCurrentLevel, 100);
            expect(stats.levelProgress, 0.0);
            expect(stats.isMaxLevel, false);
          },
        );
      });

      test('should calculate correct level for caretaker (100-499 XP)',
          () async {
        final progress = createProgress(totalXp: 250);

        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn([]);
        when(() => mockProgressDs.getProgressByUserId(testUserId))
            .thenReturn(progress);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (stats) {
            expect(stats.currentLevel, UserLevel.caretaker);
            expect(stats.totalXp, 250);
            expect(stats.xpInCurrentLevel, 150); // 250 - 100
            expect(stats.xpForCurrentLevel, 400); // 500 - 100
            expect(stats.isMaxLevel, false);
          },
        );
      });

      test('should calculate correct level for fishMaster (500-1999 XP)',
          () async {
        final progress = createProgress(totalXp: 1000);

        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn([]);
        when(() => mockProgressDs.getProgressByUserId(testUserId))
            .thenReturn(progress);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (stats) {
            expect(stats.currentLevel, UserLevel.fishMaster);
            expect(stats.totalXp, 1000);
            expect(stats.xpInCurrentLevel, 500); // 1000 - 500
            expect(stats.xpForCurrentLevel, 1500); // 2000 - 500
            expect(stats.isMaxLevel, false);
          },
        );
      });

      test('should detect max level for aquariumPro (2000+ XP)', () async {
        final progress = createProgress(totalXp: 3000);

        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn([]);
        when(() => mockProgressDs.getProgressByUserId(testUserId))
            .thenReturn(progress);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (stats) {
            expect(stats.currentLevel, UserLevel.aquariumPro);
            expect(stats.totalXp, 3000);
            expect(stats.isMaxLevel, true);
            expect(stats.levelProgress, 1.0);
            expect(stats.xpForCurrentLevel, 0);
          },
        );
      });

      test('should calculate correct level progress', () async {
        // At 50 XP: 50% of the way to level 2 (100 XP)
        final progress = createProgress(totalXp: 50);

        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn([]);
        when(() => mockProgressDs.getProgressByUserId(testUserId))
            .thenReturn(progress);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (stats) {
            expect(stats.levelProgress, 0.5);
          },
        );
      });
    });

    group('Error Handling', () {
      test('should return CacheFailure when feeding datasource throws',
          () async {
        when(() => mockFeedingDs.getAllFeedingEvents())
            .thenThrow(Exception('Database error'));

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure.message, contains('Failed to calculate statistics'));
          },
          (_) => fail('Should be Left'),
        );
      });

      test('should return CacheFailure when progress datasource throws',
          () async {
        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn([]);
        when(() => mockProgressDs.getProgressByUserId(testUserId))
            .thenThrow(Exception('Database error'));

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure.message, contains('Failed to calculate statistics'));
          },
          (_) => fail('Should be Left'),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle very old feeding events', () async {
        final longAgo = DateTime.now().subtract(const Duration(days: 365));
        final events = [
          createFeedingEvent(id: '1', feedingTime: longAgo),
        ];

        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn(events);
        when(() => mockProgressDs.getProgressByUserId(testUserId))
            .thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (stats) {
            expect(stats.daysWithApp, greaterThanOrEqualTo(365));
          },
        );
      });

      test('should handle multiple events on the same day', () async {
        final now = DateTime.now();
        final events = [
          createFeedingEvent(id: '1', feedingTime: now.subtract(const Duration(hours: 8))),
          createFeedingEvent(id: '2', feedingTime: now.subtract(const Duration(hours: 6))),
          createFeedingEvent(id: '3', feedingTime: now.subtract(const Duration(hours: 4))),
          createFeedingEvent(id: '4', feedingTime: now.subtract(const Duration(hours: 2))),
        ];

        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn(events);
        when(() => mockProgressDs.getProgressByUserId(testUserId))
            .thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (stats) {
            expect(stats.totalFeedings, 4);
            expect(stats.daysWithApp, 1);
            expect(stats.onTimePercentage, 100.0);
          },
        );
      });
    });
  });

  group('UserStatistics Entity', () {
    test('should format on-time percentage correctly', () async {
      final now = DateTime.now();
      // 3 feedings out of 4 expected = 75%
      final events = [
        createFeedingEvent(id: '1', feedingTime: now.subtract(const Duration(hours: 8))),
        createFeedingEvent(id: '2', feedingTime: now.subtract(const Duration(hours: 6))),
        createFeedingEvent(id: '3', feedingTime: now.subtract(const Duration(hours: 4))),
      ];

      when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn(events);
      when(() => mockProgressDs.getProgressByUserId(testUserId))
          .thenReturn(null);

      final result = await useCase(
        const CalculateStatisticsParams(userId: testUserId),
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (stats) {
          expect(stats.onTimePercentageFormatted, '75%');
        },
      );
    });

    test('should format XP progress text correctly for regular level',
        () async {
      final progress = createProgress(totalXp: 150);

      when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn([]);
      when(() => mockProgressDs.getProgressByUserId(testUserId))
          .thenReturn(progress);

      final result = await useCase(
        const CalculateStatisticsParams(userId: testUserId),
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (stats) {
          // 150 XP at caretaker level: 50 / 400 XP
          expect(stats.xpProgressText, '50 / 400 XP');
        },
      );
    });

    test('should format XP progress text correctly for max level', () async {
      final progress = createProgress(totalXp: 2500);

      when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn([]);
      when(() => mockProgressDs.getProgressByUserId(testUserId))
          .thenReturn(progress);

      final result = await useCase(
        const CalculateStatisticsParams(userId: testUserId),
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be Right'),
        (stats) {
          expect(stats.xpProgressText, '2500 XP (Max)');
        },
      );
    });
  });
}
