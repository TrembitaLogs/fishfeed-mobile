import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/models/feeding_event_model.dart';
import 'package:fishfeed/domain/entities/day_feeding_status.dart';
import 'package:fishfeed/domain/usecases/get_calendar_data_usecase.dart';

class MockFeedingLocalDataSource extends Mock
    implements FeedingLocalDataSource {}

void main() {
  late MockFeedingLocalDataSource mockFeedingDs;
  late GetCalendarDataUseCase useCase;

  setUp(() {
    mockFeedingDs = MockFeedingLocalDataSource();
    useCase = GetCalendarDataUseCase(feedingDataSource: mockFeedingDs);
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

  group('GetCalendarDataUseCase', () {
    group('Day Status Calculation', () {
      test('should return allFed when all feedings are completed', () async {
        final testDay = DateTime(2025, 1, 15);
        // 4 completed feedings (matches _feedingsPerDay)
        final completedEvents = [
          createFeedingEvent(
            id: '1',
            feedingTime: testDay.add(const Duration(hours: 8)),
          ),
          createFeedingEvent(
            id: '2',
            feedingTime: testDay.add(const Duration(hours: 12)),
          ),
          createFeedingEvent(
            id: '3',
            feedingTime: testDay.add(const Duration(hours: 18)),
          ),
          createFeedingEvent(
            id: '4',
            feedingTime: testDay.add(const Duration(hours: 20)),
          ),
        ];

        when(
          () => mockFeedingDs.getFeedingEventsByDate(any()),
        ).thenReturn(completedEvents);

        final result = await useCase(
          const GetCalendarDataParams(year: 2025, month: 1),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          final dayData = data.getDayData(testDay);
          expect(dayData.status, DayFeedingStatus.allFed);
          expect(dayData.completedFeedings, 4);
          expect(dayData.missedFeedings, 0);
        });
      });

      test('should return allMissed when no feedings are completed', () async {
        final testDay = DateTime(2025, 1, 15);
        when(() => mockFeedingDs.getFeedingEventsByDate(any())).thenReturn([]);

        final result = await useCase(
          const GetCalendarDataParams(year: 2025, month: 1),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          final dayData = data.getDayData(testDay);
          expect(dayData.status, DayFeedingStatus.allMissed);
          expect(dayData.completedFeedings, 0);
          expect(dayData.missedFeedings, 4);
        });
      });

      test('should return partial when some feedings are completed', () async {
        final testDay = DateTime(2025, 1, 15);
        // Only 2 completed feedings
        final completedEvents = [
          createFeedingEvent(
            id: '1',
            feedingTime: testDay.add(const Duration(hours: 8)),
          ),
          createFeedingEvent(
            id: '2',
            feedingTime: testDay.add(const Duration(hours: 12)),
          ),
        ];

        when(
          () => mockFeedingDs.getFeedingEventsByDate(any()),
        ).thenReturn(completedEvents);

        final result = await useCase(
          const GetCalendarDataParams(year: 2025, month: 1),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          final dayData = data.getDayData(testDay);
          expect(dayData.status, DayFeedingStatus.partial);
          expect(dayData.completedFeedings, 2);
          expect(dayData.missedFeedings, 2);
        });
      });

      test('should return noData for future days', () async {
        // Use a month far in the future
        final result = await useCase(
          const GetCalendarDataParams(year: 2030, month: 12),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          final futureDay = DateTime(2030, 12, 25);
          final dayStatus = data.getDayStatus(futureDay);
          expect(dayStatus, DayFeedingStatus.noData);
        });
      });
    });

    group('Monthly Statistics', () {
      test('should calculate correct completion percentage', () async {
        // Set up mock for January 2025 (31 days)
        // For simplicity, return 2 completed for each day query
        when(() => mockFeedingDs.getFeedingEventsByDate(any())).thenAnswer((
          invocation,
        ) {
          final date = invocation.positionalArguments[0] as DateTime;
          return [
            createFeedingEvent(
              id: '1_${date.day}',
              feedingTime: date.add(const Duration(hours: 8)),
            ),
            createFeedingEvent(
              id: '2_${date.day}',
              feedingTime: date.add(const Duration(hours: 12)),
            ),
          ];
        });

        final result = await useCase(
          const GetCalendarDataParams(year: 2025, month: 1),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          // For days up to today in Jan 2025
          // Each day has 4 scheduled, 2 completed = 50% per day
          expect(data.stats.completionPercentage, closeTo(50.0, 1.0));
        });
      });

      test('should count total scheduled and completed feedings', () async {
        // Mock a simple scenario: 5 days, all with all feedings completed
        final testDates = List.generate(5, (i) => DateTime(2025, 1, i + 1));

        when(() => mockFeedingDs.getFeedingEventsByDate(any())).thenAnswer((
          invocation,
        ) {
          final date = invocation.positionalArguments[0] as DateTime;
          // Return 4 events for the first 5 days only
          if (testDates.any(
            (d) =>
                d.year == date.year &&
                d.month == date.month &&
                d.day == date.day,
          )) {
            return [
              createFeedingEvent(
                id: '1_${date.day}',
                feedingTime: date.add(const Duration(hours: 8)),
              ),
              createFeedingEvent(
                id: '2_${date.day}',
                feedingTime: date.add(const Duration(hours: 12)),
              ),
              createFeedingEvent(
                id: '3_${date.day}',
                feedingTime: date.add(const Duration(hours: 18)),
              ),
              createFeedingEvent(
                id: '4_${date.day}',
                feedingTime: date.add(const Duration(hours: 20)),
              ),
            ];
          }
          return [];
        });

        final result = await useCase(
          const GetCalendarDataParams(year: 2025, month: 1),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          // First 5 days: 5 * 4 = 20 completed
          expect(data.stats.completedFeedings, greaterThanOrEqualTo(20));
        });
      });
    });

    group('Streak Calculation', () {
      test('should calculate longest streak correctly', () async {
        // Create a scenario with a 3-day streak (days 1-3 all fed)
        when(() => mockFeedingDs.getFeedingEventsByDate(any())).thenAnswer((
          invocation,
        ) {
          final date = invocation.positionalArguments[0] as DateTime;
          // Days 1, 2, 3 have all feedings completed
          if (date.day >= 1 && date.day <= 3) {
            return [
              createFeedingEvent(
                id: '1_${date.day}',
                feedingTime: date.add(const Duration(hours: 8)),
              ),
              createFeedingEvent(
                id: '2_${date.day}',
                feedingTime: date.add(const Duration(hours: 12)),
              ),
              createFeedingEvent(
                id: '3_${date.day}',
                feedingTime: date.add(const Duration(hours: 18)),
              ),
              createFeedingEvent(
                id: '4_${date.day}',
                feedingTime: date.add(const Duration(hours: 20)),
              ),
            ];
          }
          return []; // Other days have no feedings
        });

        final result = await useCase(
          const GetCalendarDataParams(year: 2025, month: 1),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          expect(data.stats.longestStreak, 3);
        });
      });

      test('should handle streak broken in the middle of month', () async {
        // Days 1-3: all fed (streak of 3)
        // Day 4: missed (break)
        // Days 5-6: all fed (streak of 2)
        when(() => mockFeedingDs.getFeedingEventsByDate(any())).thenAnswer((
          invocation,
        ) {
          final date = invocation.positionalArguments[0] as DateTime;
          // Skip day 4
          if ((date.day >= 1 && date.day <= 3) ||
              (date.day >= 5 && date.day <= 6)) {
            return [
              createFeedingEvent(
                id: '1_${date.day}',
                feedingTime: date.add(const Duration(hours: 8)),
              ),
              createFeedingEvent(
                id: '2_${date.day}',
                feedingTime: date.add(const Duration(hours: 12)),
              ),
              createFeedingEvent(
                id: '3_${date.day}',
                feedingTime: date.add(const Duration(hours: 18)),
              ),
              createFeedingEvent(
                id: '4_${date.day}',
                feedingTime: date.add(const Duration(hours: 20)),
              ),
            ];
          }
          return [];
        });

        final result = await useCase(
          const GetCalendarDataParams(year: 2025, month: 1),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          // Longest streak should be 3 (days 1-3)
          expect(data.stats.longestStreak, 3);
        });
      });

      test(
        'should return 0 streak when no days have all feedings completed',
        () async {
          // All days have partial completion
          when(() => mockFeedingDs.getFeedingEventsByDate(any())).thenAnswer((
            invocation,
          ) {
            final date = invocation.positionalArguments[0] as DateTime;
            return [
              createFeedingEvent(
                id: '1_${date.day}',
                feedingTime: date.add(const Duration(hours: 8)),
              ),
            ]; // Only 1 of 4 feedings
          });

          final result = await useCase(
            const GetCalendarDataParams(year: 2025, month: 1),
          );

          expect(result.isRight(), true);
          result.fold((_) => fail('Should be Right'), (data) {
            expect(data.stats.longestStreak, 0);
            expect(data.stats.currentStreak, 0);
          });
        },
      );

      test('should handle streak at month boundaries', () async {
        // Last 3 days of January all fed
        when(() => mockFeedingDs.getFeedingEventsByDate(any())).thenAnswer((
          invocation,
        ) {
          final date = invocation.positionalArguments[0] as DateTime;
          // Days 29, 30, 31 have all feedings completed
          if (date.day >= 29 && date.day <= 31) {
            return [
              createFeedingEvent(
                id: '1_${date.day}',
                feedingTime: date.add(const Duration(hours: 8)),
              ),
              createFeedingEvent(
                id: '2_${date.day}',
                feedingTime: date.add(const Duration(hours: 12)),
              ),
              createFeedingEvent(
                id: '3_${date.day}',
                feedingTime: date.add(const Duration(hours: 18)),
              ),
              createFeedingEvent(
                id: '4_${date.day}',
                feedingTime: date.add(const Duration(hours: 20)),
              ),
            ];
          }
          return [];
        });

        final result = await useCase(
          const GetCalendarDataParams(year: 2025, month: 1),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          expect(data.stats.longestStreak, 3);
        });
      });
    });

    group('CalendarMonthData', () {
      test('should provide correct year and month', () async {
        when(() => mockFeedingDs.getFeedingEventsByDate(any())).thenReturn([]);

        final result = await useCase(
          const GetCalendarDataParams(year: 2025, month: 6),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          expect(data.year, 2025);
          expect(data.month, 6);
        });
      });

      test('should count days by status correctly', () async {
        // Set up different statuses for different days
        when(() => mockFeedingDs.getFeedingEventsByDate(any())).thenAnswer((
          invocation,
        ) {
          final date = invocation.positionalArguments[0] as DateTime;
          if (date.day <= 3) {
            // Days 1-3: all fed
            return [
              createFeedingEvent(
                id: '1_${date.day}',
                feedingTime: date.add(const Duration(hours: 8)),
              ),
              createFeedingEvent(
                id: '2_${date.day}',
                feedingTime: date.add(const Duration(hours: 12)),
              ),
              createFeedingEvent(
                id: '3_${date.day}',
                feedingTime: date.add(const Duration(hours: 18)),
              ),
              createFeedingEvent(
                id: '4_${date.day}',
                feedingTime: date.add(const Duration(hours: 20)),
              ),
            ];
          } else if (date.day <= 5) {
            // Days 4-5: partial
            return [
              createFeedingEvent(
                id: '1_${date.day}',
                feedingTime: date.add(const Duration(hours: 8)),
              ),
            ];
          }
          // Other days: all missed
          return [];
        });

        final result = await useCase(
          const GetCalendarDataParams(year: 2025, month: 1),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          expect(data.daysAllFed, 3);
          expect(data.daysPartial, 2);
          // Remaining days up to today will be allMissed
          expect(data.daysAllMissed, greaterThan(0));
        });
      });
    });

    group('Error Handling', () {
      test(
        'should return CacheFailure when datasource throws exception',
        () async {
          when(
            () => mockFeedingDs.getFeedingEventsByDate(any()),
          ).thenThrow(Exception('Database error'));

          final result = await useCase(
            const GetCalendarDataParams(year: 2025, month: 1),
          );

          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure.message, contains('Failed to get calendar data'));
          }, (_) => fail('Should be Left'));
        },
      );
    });

    group('Edge Cases', () {
      test('should handle February with 28 days', () async {
        when(() => mockFeedingDs.getFeedingEventsByDate(any())).thenReturn([]);

        final result = await useCase(
          const GetCalendarDataParams(year: 2025, month: 2),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          expect(data.month, 2);
          // Should have data for days 1-28 (up to today if in past)
        });
      });

      test('should handle leap year February with 29 days', () async {
        when(() => mockFeedingDs.getFeedingEventsByDate(any())).thenReturn([]);

        final result = await useCase(
          const GetCalendarDataParams(year: 2024, month: 2),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          expect(data.month, 2);
          // Leap year 2024 has 29 days in February
        });
      });

      test('should handle empty month (all future days)', () async {
        when(() => mockFeedingDs.getFeedingEventsByDate(any())).thenReturn([]);

        // Far future month
        final result = await useCase(
          const GetCalendarDataParams(year: 2030, month: 12),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          expect(data.hasData, false);
          expect(data.stats.totalScheduledFeedings, 0);
        });
      });
    });
  });
}
