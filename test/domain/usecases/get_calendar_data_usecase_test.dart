import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/domain/entities/day_feeding_status.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/domain/services/feeding_event_generator.dart';
import 'package:fishfeed/domain/usecases/get_calendar_data_usecase.dart';

class MockFeedingEventGenerator extends Mock implements FeedingEventGenerator {}

class MockAquariumLocalDataSource extends Mock
    implements AquariumLocalDataSource {}

void main() {
  late MockFeedingEventGenerator mockGenerator;
  late MockAquariumLocalDataSource mockAquariumDs;
  late GetCalendarDataUseCase useCase;

  setUp(() {
    mockGenerator = MockFeedingEventGenerator();
    mockAquariumDs = MockAquariumLocalDataSource();
    useCase = GetCalendarDataUseCase(
      feedingEventGenerator: mockGenerator,
      aquariumDataSource: mockAquariumDs,
    );
  });

  /// Creates a test aquarium model.
  AquariumModel createAquariumModel({
    String id = 'aquarium_1',
    String name = 'Test Tank',
  }) {
    return AquariumModel(
      id: id,
      name: name,
      userId: 'user_1',
      createdAt: DateTime(2024, 1, 1),
      synced: true,
    );
  }

  /// Creates a test ComputedFeedingEvent.
  ComputedFeedingEvent createEvent({
    required DateTime scheduledFor,
    String scheduleId = 'schedule_1',
    String aquariumId = 'aquarium_1',
    EventStatus status = EventStatus.fed,
  }) {
    return ComputedFeedingEvent(
      scheduleId: scheduleId,
      fishId: 'fish_1',
      aquariumId: aquariumId,
      scheduledFor: scheduledFor,
      time: '${scheduledFor.hour.toString().padLeft(2, '0')}:00',
      foodType: 'flakes',
      status: status,
    );
  }

  group('GetCalendarDataUseCase', () {
    group('Empty Aquariums', () {
      test(
        'should return empty calendar data when no aquariums exist',
        () async {
          when(() => mockAquariumDs.getAllAquariums()).thenReturn([]);

          final result = await useCase(
            const GetCalendarDataParams(year: 2025, month: 1),
          );

          expect(result.isRight(), true);
          result.fold((_) => fail('Should be Right'), (data) {
            expect(data.year, 2025);
            expect(data.month, 1);
            expect(data.days, isEmpty);
            expect(data.stats.totalScheduledFeedings, 0);
          });
        },
      );
    });

    group('Day Status Calculation', () {
      test('should return allFed when all feedings are completed', () async {
        final testDay = DateTime(2025, 1, 15);

        when(
          () => mockAquariumDs.getAllAquariums(),
        ).thenReturn([createAquariumModel()]);

        // 4 completed feedings (all fed)
        when(
          () => mockGenerator.generateEvents(
            aquariumId: any(named: 'aquariumId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenReturn([
          createEvent(
            scheduledFor: testDay.add(const Duration(hours: 8)),
            scheduleId: '1',
            status: EventStatus.fed,
          ),
          createEvent(
            scheduledFor: testDay.add(const Duration(hours: 12)),
            scheduleId: '2',
            status: EventStatus.fed,
          ),
          createEvent(
            scheduledFor: testDay.add(const Duration(hours: 18)),
            scheduleId: '3',
            status: EventStatus.fed,
          ),
          createEvent(
            scheduledFor: testDay.add(const Duration(hours: 20)),
            scheduleId: '4',
            status: EventStatus.fed,
          ),
        ]);

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

        when(
          () => mockAquariumDs.getAllAquariums(),
        ).thenReturn([createAquariumModel()]);

        // All overdue (no logs)
        when(
          () => mockGenerator.generateEvents(
            aquariumId: any(named: 'aquariumId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenReturn([
          createEvent(
            scheduledFor: testDay.add(const Duration(hours: 8)),
            scheduleId: '1',
            status: EventStatus.overdue,
          ),
          createEvent(
            scheduledFor: testDay.add(const Duration(hours: 12)),
            scheduleId: '2',
            status: EventStatus.overdue,
          ),
          createEvent(
            scheduledFor: testDay.add(const Duration(hours: 18)),
            scheduleId: '3',
            status: EventStatus.overdue,
          ),
          createEvent(
            scheduledFor: testDay.add(const Duration(hours: 20)),
            scheduleId: '4',
            status: EventStatus.overdue,
          ),
        ]);

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

        when(
          () => mockAquariumDs.getAllAquariums(),
        ).thenReturn([createAquariumModel()]);

        // 2 fed, 2 overdue
        when(
          () => mockGenerator.generateEvents(
            aquariumId: any(named: 'aquariumId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenReturn([
          createEvent(
            scheduledFor: testDay.add(const Duration(hours: 8)),
            scheduleId: '1',
            status: EventStatus.fed,
          ),
          createEvent(
            scheduledFor: testDay.add(const Duration(hours: 12)),
            scheduleId: '2',
            status: EventStatus.fed,
          ),
          createEvent(
            scheduledFor: testDay.add(const Duration(hours: 18)),
            scheduleId: '3',
            status: EventStatus.overdue,
          ),
          createEvent(
            scheduledFor: testDay.add(const Duration(hours: 20)),
            scheduleId: '4',
            status: EventStatus.overdue,
          ),
        ]);

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

      test('should return noData for days without events', () async {
        when(
          () => mockAquariumDs.getAllAquariums(),
        ).thenReturn([createAquariumModel()]);

        // Return empty list - no events generated
        when(
          () => mockGenerator.generateEvents(
            aquariumId: any(named: 'aquariumId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenReturn([]);

        final result = await useCase(
          const GetCalendarDataParams(year: 2025, month: 1),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          final dayStatus = data.getDayStatus(DateTime(2025, 1, 15));
          expect(dayStatus, DayFeedingStatus.noData);
        });
      });

      test('should count skipped as missed', () async {
        final testDay = DateTime(2025, 1, 15);

        when(
          () => mockAquariumDs.getAllAquariums(),
        ).thenReturn([createAquariumModel()]);

        // 2 fed, 1 skipped, 1 overdue = 2 completed, 2 missed
        when(
          () => mockGenerator.generateEvents(
            aquariumId: any(named: 'aquariumId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenReturn([
          createEvent(
            scheduledFor: testDay.add(const Duration(hours: 8)),
            scheduleId: '1',
            status: EventStatus.fed,
          ),
          createEvent(
            scheduledFor: testDay.add(const Duration(hours: 12)),
            scheduleId: '2',
            status: EventStatus.fed,
          ),
          createEvent(
            scheduledFor: testDay.add(const Duration(hours: 18)),
            scheduleId: '3',
            status: EventStatus.skipped,
          ),
          createEvent(
            scheduledFor: testDay.add(const Duration(hours: 20)),
            scheduleId: '4',
            status: EventStatus.overdue,
          ),
        ]);

        final result = await useCase(
          const GetCalendarDataParams(year: 2025, month: 1),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          final dayData = data.getDayData(testDay);
          expect(dayData.completedFeedings, 2);
          expect(dayData.missedFeedings, 2); // skipped + overdue
        });
      });
    });

    group('Monthly Statistics', () {
      test('should calculate correct totals', () async {
        final day1 = DateTime(2025, 1, 1);
        final day2 = DateTime(2025, 1, 2);

        when(
          () => mockAquariumDs.getAllAquariums(),
        ).thenReturn([createAquariumModel()]);

        // Day 1: 2 fed, 2 overdue
        // Day 2: 3 fed, 1 overdue
        // Total: 8 scheduled, 5 completed, 3 missed
        when(
          () => mockGenerator.generateEvents(
            aquariumId: any(named: 'aquariumId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenReturn([
          // Day 1
          createEvent(
            scheduledFor: day1.add(const Duration(hours: 8)),
            scheduleId: '1',
            status: EventStatus.fed,
          ),
          createEvent(
            scheduledFor: day1.add(const Duration(hours: 12)),
            scheduleId: '2',
            status: EventStatus.fed,
          ),
          createEvent(
            scheduledFor: day1.add(const Duration(hours: 18)),
            scheduleId: '3',
            status: EventStatus.overdue,
          ),
          createEvent(
            scheduledFor: day1.add(const Duration(hours: 20)),
            scheduleId: '4',
            status: EventStatus.overdue,
          ),
          // Day 2
          createEvent(
            scheduledFor: day2.add(const Duration(hours: 8)),
            scheduleId: '5',
            status: EventStatus.fed,
          ),
          createEvent(
            scheduledFor: day2.add(const Duration(hours: 12)),
            scheduleId: '6',
            status: EventStatus.fed,
          ),
          createEvent(
            scheduledFor: day2.add(const Duration(hours: 18)),
            scheduleId: '7',
            status: EventStatus.fed,
          ),
          createEvent(
            scheduledFor: day2.add(const Duration(hours: 20)),
            scheduleId: '8',
            status: EventStatus.overdue,
          ),
        ]);

        final result = await useCase(
          const GetCalendarDataParams(year: 2025, month: 1),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          expect(data.stats.totalScheduledFeedings, 8);
          expect(data.stats.completedFeedings, 5);
          expect(data.stats.missedFeedings, 3);
        });
      });
    });

    group('Streak Calculation', () {
      test('should calculate longest streak correctly', () async {
        when(
          () => mockAquariumDs.getAllAquariums(),
        ).thenReturn([createAquariumModel()]);

        // Create events for days 1-3 (all fed = streak of 3)
        final events = <ComputedFeedingEvent>[];
        for (int day = 1; day <= 3; day++) {
          final date = DateTime(2025, 1, day);
          events.add(
            createEvent(
              scheduledFor: date.add(const Duration(hours: 8)),
              scheduleId: 'sched_${day}_1',
              status: EventStatus.fed,
            ),
          );
          events.add(
            createEvent(
              scheduledFor: date.add(const Duration(hours: 12)),
              scheduleId: 'sched_${day}_2',
              status: EventStatus.fed,
            ),
          );
        }

        when(
          () => mockGenerator.generateEvents(
            aquariumId: any(named: 'aquariumId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenReturn(events);

        final result = await useCase(
          const GetCalendarDataParams(year: 2025, month: 1),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          expect(data.stats.longestStreak, 3);
        });
      });

      test('should handle streak broken in the middle of month', () async {
        when(
          () => mockAquariumDs.getAllAquariums(),
        ).thenReturn([createAquariumModel()]);

        // Days 1-3: all fed (streak of 3)
        // Day 4: missed (break)
        // Days 5-6: all fed (streak of 2)
        final events = <ComputedFeedingEvent>[];

        // Days 1-3 all fed
        for (int day = 1; day <= 3; day++) {
          final date = DateTime(2025, 1, day);
          events.add(
            createEvent(
              scheduledFor: date.add(const Duration(hours: 8)),
              scheduleId: 'sched_${day}_1',
              status: EventStatus.fed,
            ),
          );
        }

        // Day 4 - overdue (breaks streak)
        events.add(
          createEvent(
            scheduledFor: DateTime(2025, 1, 4, 8),
            scheduleId: 'sched_4_1',
            status: EventStatus.overdue,
          ),
        );

        // Days 5-6 all fed
        for (int day = 5; day <= 6; day++) {
          final date = DateTime(2025, 1, day);
          events.add(
            createEvent(
              scheduledFor: date.add(const Duration(hours: 8)),
              scheduleId: 'sched_${day}_1',
              status: EventStatus.fed,
            ),
          );
        }

        when(
          () => mockGenerator.generateEvents(
            aquariumId: any(named: 'aquariumId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenReturn(events);

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
          when(
            () => mockAquariumDs.getAllAquariums(),
          ).thenReturn([createAquariumModel()]);

          // All days have partial completion (some fed, some overdue)
          final events = <ComputedFeedingEvent>[];
          for (int day = 1; day <= 3; day++) {
            final date = DateTime(2025, 1, day);
            events.add(
              createEvent(
                scheduledFor: date.add(const Duration(hours: 8)),
                scheduleId: 'sched_${day}_1',
                status: EventStatus.fed,
              ),
            );
            events.add(
              createEvent(
                scheduledFor: date.add(const Duration(hours: 12)),
                scheduleId: 'sched_${day}_2',
                status: EventStatus.overdue, // Partial - breaks streak
              ),
            );
          }

          when(
            () => mockGenerator.generateEvents(
              aquariumId: any(named: 'aquariumId'),
              from: any(named: 'from'),
              to: any(named: 'to'),
            ),
          ).thenReturn(events);

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
    });

    group('CalendarMonthData', () {
      test('should provide correct year and month', () async {
        when(
          () => mockAquariumDs.getAllAquariums(),
        ).thenReturn([createAquariumModel()]);
        when(
          () => mockGenerator.generateEvents(
            aquariumId: any(named: 'aquariumId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenReturn([]);

        final result = await useCase(
          const GetCalendarDataParams(year: 2025, month: 6),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          expect(data.year, 2025);
          expect(data.month, 6);
        });
      });
    });

    group('Multiple Aquariums', () {
      test('should aggregate events from multiple aquariums', () async {
        final testDay = DateTime(2025, 1, 15);

        when(() => mockAquariumDs.getAllAquariums()).thenReturn([
          createAquariumModel(id: 'aq_1', name: 'Tank 1'),
          createAquariumModel(id: 'aq_2', name: 'Tank 2'),
        ]);

        // First call for aq_1 returns 2 fed events
        // Second call for aq_2 returns 2 fed events
        var callCount = 0;
        when(
          () => mockGenerator.generateEvents(
            aquariumId: any(named: 'aquariumId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((invocation) {
          callCount++;
          final aquariumId = invocation.namedArguments[#aquariumId] as String;
          return [
            createEvent(
              scheduledFor: testDay.add(const Duration(hours: 8)),
              scheduleId: 'sched_${aquariumId}_1',
              aquariumId: aquariumId,
              status: EventStatus.fed,
            ),
            createEvent(
              scheduledFor: testDay.add(const Duration(hours: 12)),
              scheduleId: 'sched_${aquariumId}_2',
              aquariumId: aquariumId,
              status: EventStatus.fed,
            ),
          ];
        });

        final result = await useCase(
          const GetCalendarDataParams(year: 2025, month: 1),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          final dayData = data.getDayData(testDay);
          // 4 total events (2 from each aquarium)
          expect(dayData.totalFeedings, 4);
          expect(dayData.completedFeedings, 4);
          expect(dayData.status, DayFeedingStatus.allFed);
        });

        // Verify generateEvents was called for each aquarium
        expect(callCount, 2);
      });
    });

    group('Error Handling', () {
      test(
        'should return CacheFailure when generator throws exception',
        () async {
          when(
            () => mockAquariumDs.getAllAquariums(),
          ).thenReturn([createAquariumModel()]);
          when(
            () => mockGenerator.generateEvents(
              aquariumId: any(named: 'aquariumId'),
              from: any(named: 'from'),
              to: any(named: 'to'),
            ),
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
        when(
          () => mockAquariumDs.getAllAquariums(),
        ).thenReturn([createAquariumModel()]);
        when(
          () => mockGenerator.generateEvents(
            aquariumId: any(named: 'aquariumId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenReturn([]);

        final result = await useCase(
          const GetCalendarDataParams(year: 2025, month: 2),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          expect(data.month, 2);
        });
      });

      test('should handle leap year February with 29 days', () async {
        when(
          () => mockAquariumDs.getAllAquariums(),
        ).thenReturn([createAquariumModel()]);
        when(
          () => mockGenerator.generateEvents(
            aquariumId: any(named: 'aquariumId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenReturn([]);

        final result = await useCase(
          const GetCalendarDataParams(year: 2024, month: 2),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Should be Right'), (data) {
          expect(data.month, 2);
        });
      });
    });
  });
}
