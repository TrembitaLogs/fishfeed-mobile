import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/constants/levels.dart';
import 'package:fishfeed/data/datasources/local/feeding_log_local_ds.dart';
import 'package:fishfeed/data/datasources/local/user_progress_local_ds.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';
import 'package:fishfeed/data/models/user_progress_model.dart';
import 'package:fishfeed/domain/usecases/calculate_statistics_usecase.dart';

class MockFeedingLogLocalDataSource extends Mock
    implements FeedingLogLocalDataSource {}

class MockUserProgressLocalDataSource extends Mock
    implements UserProgressLocalDataSource {}

void main() {
  late MockFeedingLogLocalDataSource mockFeedingLogDs;
  late MockUserProgressLocalDataSource mockProgressDs;
  late CalculateStatisticsUseCase useCase;

  const testUserId = 'user_123';

  setUp(() {
    mockFeedingLogDs = MockFeedingLogLocalDataSource();
    mockProgressDs = MockUserProgressLocalDataSource();
    useCase = CalculateStatisticsUseCase(
      feedingLogDataSource: mockFeedingLogDs,
      userProgressDataSource: mockProgressDs,
    );
  });

  FeedingLogModel createFeedingLog({
    required String id,
    required DateTime scheduledFor,
    String scheduleId = 'schedule_1',
    String fishId = 'fish_1',
    String aquariumId = 'aquarium_1',
    String action = 'fed',
  }) {
    return FeedingLogModel(
      id: id,
      scheduleId: scheduleId,
      fishId: fishId,
      aquariumId: aquariumId,
      scheduledFor: scheduledFor,
      action: action,
      actedAt: scheduledFor,
      actedByUserId: 'user_1',
      deviceId: 'device_1',
      createdAt: scheduledFor,
    );
  }

  UserProgressModel createProgress({
    required int totalXp,
    String id = 'progress_user_123',
    String userId = testUserId,
  }) {
    return UserProgressModel(id: id, userId: userId, totalXp: totalXp);
  }

  group('CalculateStatisticsUseCase', () {
    group('Total Feedings', () {
      test('should return 0 when no feeding events exist', () async {
        when(() => mockFeedingLogDs.getAll()).thenReturn([]);
        when(
          () => mockProgressDs.getProgressByUserId(testUserId),
        ).thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (stats) {
          expect(stats.totalFeedings, 0);
        });
      });

      test('should count all feeding events', () async {
        final events = [
          createFeedingLog(id: '1', scheduledFor: DateTime(2025, 1, 1, 8)),
          createFeedingLog(id: '2', scheduledFor: DateTime(2025, 1, 1, 12)),
          createFeedingLog(id: '3', scheduledFor: DateTime(2025, 1, 2, 8)),
        ];

        when(() => mockFeedingLogDs.getAll()).thenReturn(events);
        when(
          () => mockProgressDs.getProgressByUserId(testUserId),
        ).thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (stats) {
          expect(stats.totalFeedings, 3);
        });
      });
    });

    group('Days With App', () {
      test('should return 0 when no feeding events exist', () async {
        when(() => mockFeedingLogDs.getAll()).thenReturn([]);
        when(
          () => mockProgressDs.getProgressByUserId(testUserId),
        ).thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (stats) {
          expect(stats.daysWithApp, 0);
        });
      });

      test('should calculate days from first feeding to now', () async {
        final now = DateTime.now();
        final daysAgo = now.subtract(const Duration(days: 10));
        final events = [
          createFeedingLog(id: '1', scheduledFor: daysAgo),
          createFeedingLog(
            id: '2',
            scheduledFor: now.subtract(const Duration(days: 5)),
          ),
          createFeedingLog(
            id: '3',
            scheduledFor: now.subtract(const Duration(days: 1)),
          ),
        ];

        when(() => mockFeedingLogDs.getAll()).thenReturn(events);
        when(
          () => mockProgressDs.getProgressByUserId(testUserId),
        ).thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (stats) {
          // 10 days ago + 1 (include first day) = 11 days
          expect(stats.daysWithApp, 11);
        });
      });

      test('should return 1 for first day of usage', () async {
        final now = DateTime.now();
        final events = [createFeedingLog(id: '1', scheduledFor: now)];

        when(() => mockFeedingLogDs.getAll()).thenReturn(events);
        when(
          () => mockProgressDs.getProgressByUserId(testUserId),
        ).thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (stats) {
          expect(stats.daysWithApp, 1);
        });
      });
    });

    group('On-Time Percentage', () {
      test('should return 0 when no days with app', () async {
        when(() => mockFeedingLogDs.getAll()).thenReturn([]);
        when(
          () => mockProgressDs.getProgressByUserId(testUserId),
        ).thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (stats) {
          expect(stats.onTimePercentage, 0.0);
        });
      });

      test(
        'should calculate 100% when all expected feedings are completed',
        () async {
          final now = DateTime.now();
          final yesterday = now.subtract(const Duration(days: 1));
          // 2 days * 4 feedings per day = 8 expected feedings
          final events = [
            createFeedingLog(
              id: '1',
              scheduledFor: yesterday.add(const Duration(hours: 8)),
            ),
            createFeedingLog(
              id: '2',
              scheduledFor: yesterday.add(const Duration(hours: 12)),
            ),
            createFeedingLog(
              id: '3',
              scheduledFor: yesterday.add(const Duration(hours: 18)),
            ),
            createFeedingLog(
              id: '4',
              scheduledFor: yesterday.add(const Duration(hours: 20)),
            ),
            createFeedingLog(
              id: '5',
              scheduledFor: now.subtract(const Duration(hours: 4)),
            ),
            createFeedingLog(
              id: '6',
              scheduledFor: now.subtract(const Duration(hours: 3)),
            ),
            createFeedingLog(
              id: '7',
              scheduledFor: now.subtract(const Duration(hours: 2)),
            ),
            createFeedingLog(
              id: '8',
              scheduledFor: now.subtract(const Duration(hours: 1)),
            ),
          ];

          when(() => mockFeedingLogDs.getAll()).thenReturn(events);
          when(
            () => mockProgressDs.getProgressByUserId(testUserId),
          ).thenReturn(null);

          final result = await useCase(
            const CalculateStatisticsParams(userId: testUserId),
          );

          expect(result.isRight(), true);
          result.fold((_) => fail('Should be Right'), (stats) {
            expect(stats.onTimePercentage, 100.0);
          });
        },
      );

      test(
        'should calculate 50% when half of expected feedings are completed',
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
            createFeedingLog(id: '1', scheduledFor: twoDaysAgo),
            createFeedingLog(
              id: '2',
              scheduledFor: twoDaysAgo.add(const Duration(hours: 2)),
            ),
            createFeedingLog(
              id: '3',
              scheduledFor: now.subtract(const Duration(hours: 2)),
            ),
            createFeedingLog(
              id: '4',
              scheduledFor: now.subtract(const Duration(hours: 1)),
            ),
          ];

          when(() => mockFeedingLogDs.getAll()).thenReturn(events);
          when(
            () => mockProgressDs.getProgressByUserId(testUserId),
          ).thenReturn(null);

          final result = await useCase(
            const CalculateStatisticsParams(userId: testUserId),
          );

          expect(result.isRight(), true);
          result.fold((_) => fail('Should be Right'), (stats) {
            // 4 feedings / 8 expected (2 days * 4) = 50%
            expect(stats.onTimePercentage, 50.0);
          });
        },
      );

      test('should cap at 100% when over-feeding occurs', () async {
        final now = DateTime.now();
        // 1 day but 10 feedings (more than expected 4)
        final events = List.generate(
          10,
          (i) => createFeedingLog(
            id: '$i',
            scheduledFor: now.subtract(Duration(hours: i)),
          ),
        );

        when(() => mockFeedingLogDs.getAll()).thenReturn(events);
        when(
          () => mockProgressDs.getProgressByUserId(testUserId),
        ).thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (stats) {
          expect(stats.onTimePercentage, 100.0);
        });
      });

      test('should return 0% when no feedings but days passed', () async {
        // This edge case shouldn't happen normally, but testing for robustness
        // Since we need events to calculate days, this will return 0 days and 0%
        when(() => mockFeedingLogDs.getAll()).thenReturn([]);
        when(
          () => mockProgressDs.getProgressByUserId(testUserId),
        ).thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (stats) {
          expect(stats.onTimePercentage, 0.0);
        });
      });
    });

    group('Level and XP', () {
      test(
        'should return beginner level with 0 XP when no progress exists',
        () async {
          when(() => mockFeedingLogDs.getAll()).thenReturn([]);
          when(
            () => mockProgressDs.getProgressByUserId(testUserId),
          ).thenReturn(null);

          final result = await useCase(
            const CalculateStatisticsParams(userId: testUserId),
          );

          expect(result.isRight(), true);
          result.fold((_) => fail('Should be Right'), (stats) {
            expect(stats.currentLevel, UserLevel.beginnerAquarist);
            expect(stats.totalXp, 0);
            expect(stats.xpInCurrentLevel, 0);
            expect(stats.xpForCurrentLevel, 100);
            expect(stats.levelProgress, 0.0);
            expect(stats.isMaxLevel, false);
          });
        },
      );

      test(
        'should calculate correct level for caretaker (100-499 XP)',
        () async {
          final progress = createProgress(totalXp: 250);

          when(() => mockFeedingLogDs.getAll()).thenReturn([]);
          when(
            () => mockProgressDs.getProgressByUserId(testUserId),
          ).thenReturn(progress);

          final result = await useCase(
            const CalculateStatisticsParams(userId: testUserId),
          );

          expect(result.isRight(), true);
          result.fold((_) => fail('Should be Right'), (stats) {
            expect(stats.currentLevel, UserLevel.caretaker);
            expect(stats.totalXp, 250);
            expect(stats.xpInCurrentLevel, 150); // 250 - 100
            expect(stats.xpForCurrentLevel, 400); // 500 - 100
            expect(stats.isMaxLevel, false);
          });
        },
      );

      test(
        'should calculate correct level for fishMaster (500-1999 XP)',
        () async {
          final progress = createProgress(totalXp: 1000);

          when(() => mockFeedingLogDs.getAll()).thenReturn([]);
          when(
            () => mockProgressDs.getProgressByUserId(testUserId),
          ).thenReturn(progress);

          final result = await useCase(
            const CalculateStatisticsParams(userId: testUserId),
          );

          expect(result.isRight(), true);
          result.fold((_) => fail('Should be Right'), (stats) {
            expect(stats.currentLevel, UserLevel.fishMaster);
            expect(stats.totalXp, 1000);
            expect(stats.xpInCurrentLevel, 500); // 1000 - 500
            expect(stats.xpForCurrentLevel, 1500); // 2000 - 500
            expect(stats.isMaxLevel, false);
          });
        },
      );

      test('should detect max level for aquariumPro (2000+ XP)', () async {
        final progress = createProgress(totalXp: 3000);

        when(() => mockFeedingLogDs.getAll()).thenReturn([]);
        when(
          () => mockProgressDs.getProgressByUserId(testUserId),
        ).thenReturn(progress);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (stats) {
          expect(stats.currentLevel, UserLevel.aquariumPro);
          expect(stats.totalXp, 3000);
          expect(stats.isMaxLevel, true);
          expect(stats.levelProgress, 1.0);
          expect(stats.xpForCurrentLevel, 0);
        });
      });

      test('should calculate correct level progress', () async {
        // At 50 XP: 50% of the way to level 2 (100 XP)
        final progress = createProgress(totalXp: 50);

        when(() => mockFeedingLogDs.getAll()).thenReturn([]);
        when(
          () => mockProgressDs.getProgressByUserId(testUserId),
        ).thenReturn(progress);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (stats) {
          expect(stats.levelProgress, 0.5);
        });
      });
    });

    group('Error Handling', () {
      test(
        'should return CacheFailure when feeding datasource throws',
        () async {
          when(
            () => mockFeedingLogDs.getAll(),
          ).thenThrow(Exception('Database error'));

          final result = await useCase(
            const CalculateStatisticsParams(userId: testUserId),
          );

          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure.message, contains('Failed to calculate statistics'));
          }, (_) => fail('Should be Left'));
        },
      );

      test(
        'should return CacheFailure when progress datasource throws',
        () async {
          when(() => mockFeedingLogDs.getAll()).thenReturn([]);
          when(
            () => mockProgressDs.getProgressByUserId(testUserId),
          ).thenThrow(Exception('Database error'));

          final result = await useCase(
            const CalculateStatisticsParams(userId: testUserId),
          );

          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure.message, contains('Failed to calculate statistics'));
          }, (_) => fail('Should be Left'));
        },
      );
    });

    group('Edge Cases', () {
      test('should handle very old feeding events', () async {
        final longAgo = DateTime.now().subtract(const Duration(days: 365));
        final events = [createFeedingLog(id: '1', scheduledFor: longAgo)];

        when(() => mockFeedingLogDs.getAll()).thenReturn(events);
        when(
          () => mockProgressDs.getProgressByUserId(testUserId),
        ).thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (stats) {
          expect(stats.daysWithApp, greaterThanOrEqualTo(365));
        });
      });

      test('should handle multiple events on the same day', () async {
        final now = DateTime.now();
        final events = [
          createFeedingLog(
            id: '1',
            scheduledFor: now.subtract(const Duration(hours: 8)),
          ),
          createFeedingLog(
            id: '2',
            scheduledFor: now.subtract(const Duration(hours: 6)),
          ),
          createFeedingLog(
            id: '3',
            scheduledFor: now.subtract(const Duration(hours: 4)),
          ),
          createFeedingLog(
            id: '4',
            scheduledFor: now.subtract(const Duration(hours: 2)),
          ),
        ];

        when(() => mockFeedingLogDs.getAll()).thenReturn(events);
        when(
          () => mockProgressDs.getProgressByUserId(testUserId),
        ).thenReturn(null);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (stats) {
          expect(stats.totalFeedings, 4);
          expect(stats.daysWithApp, 1);
          expect(stats.onTimePercentage, 100.0);
        });
      });
    });
  });

  group('UserStatistics Entity', () {
    test('should format on-time percentage correctly', () async {
      final now = DateTime.now();
      // 3 feedings out of 4 expected = 75%
      final events = [
        createFeedingLog(
          id: '1',
          scheduledFor: now.subtract(const Duration(hours: 8)),
        ),
        createFeedingLog(
          id: '2',
          scheduledFor: now.subtract(const Duration(hours: 6)),
        ),
        createFeedingLog(
          id: '3',
          scheduledFor: now.subtract(const Duration(hours: 4)),
        ),
      ];

      when(() => mockFeedingLogDs.getAll()).thenReturn(events);
      when(
        () => mockProgressDs.getProgressByUserId(testUserId),
      ).thenReturn(null);

      final result = await useCase(
        const CalculateStatisticsParams(userId: testUserId),
      );

      expect(result.isRight(), true);
      result.fold((_) => fail('Should be Right'), (stats) {
        expect(stats.onTimePercentageFormatted, '75%');
      });
    });

    test(
      'should format XP progress text correctly for regular level',
      () async {
        final progress = createProgress(totalXp: 150);

        when(() => mockFeedingLogDs.getAll()).thenReturn([]);
        when(
          () => mockProgressDs.getProgressByUserId(testUserId),
        ).thenReturn(progress);

        final result = await useCase(
          const CalculateStatisticsParams(userId: testUserId),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (stats) {
          // 150 XP at caretaker level: 50 / 400 XP
          expect(stats.xpProgressText, '50 / 400 XP');
        });
      },
    );

    test('should format XP progress text correctly for max level', () async {
      final progress = createProgress(totalXp: 2500);

      when(() => mockFeedingLogDs.getAll()).thenReturn([]);
      when(
        () => mockProgressDs.getProgressByUserId(testUserId),
      ).thenReturn(progress);

      final result = await useCase(
        const CalculateStatisticsParams(userId: testUserId),
      );

      expect(result.isRight(), true);
      result.fold((_) => fail('Should be Right'), (stats) {
        expect(stats.xpProgressText, '2500 XP (Max)');
      });
    });
  });
}
