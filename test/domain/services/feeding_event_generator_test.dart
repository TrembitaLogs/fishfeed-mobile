import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/feeding_log_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/domain/services/feeding_event_generator.dart';

void main() {
  late Directory tempDir;
  late ScheduleLocalDataSource scheduleDs;
  late FeedingLogLocalDataSource logDs;
  late FeedingEventGenerator generator;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_generator_test_');
    Hive.init(tempDir.path);
    await HiveBoxes.initForTesting();

    scheduleDs = ScheduleLocalDataSource();
    logDs = FeedingLogLocalDataSource();
    generator = FeedingEventGenerator(
      scheduleLocalDs: scheduleDs,
      feedingLogLocalDs: logDs,
    );
  });

  tearDown(() async {
    await HiveBoxes.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FeedingEventGenerator - generateEvents', () {
    test(
      'should generate events for 7-day range with daily schedule',
      () async {
        // Arrange: Create a schedule with intervalDays=1 (daily)
        final anchorDate = DateTime(2025, 1, 1);
        final schedule = ScheduleModel(
          id: 'schedule-daily',
          fishId: 'fish-1',
          aquariumId: 'aquarium-1',
          time: '09:00',
          intervalDays: 1,
          anchorDate: anchorDate,
          foodType: 'flakes',
          active: true,
          createdAt: anchorDate,
          updatedAt: anchorDate,
          createdByUserId: 'user-1',
        );
        await scheduleDs.save(schedule);

        // Act: Generate events for 7 days
        final from = DateTime(2025, 1, 1);
        final to = DateTime(2025, 1, 7);
        final events = generator.generateEvents(
          aquariumId: 'aquarium-1',
          from: from,
          to: to,
        );

        // Assert: Should have 7 events (one per day)
        expect(events.length, 7);
        for (var i = 0; i < 7; i++) {
          expect(events[i].scheduledFor.day, 1 + i);
          expect(events[i].scheduleId, 'schedule-daily');
          expect(events[i].time, '09:00');
          expect(events[i].foodType, 'flakes');
        }
      },
    );

    test(
      'should generate events every other day with intervalDays=2',
      () async {
        final anchorDate = DateTime(2025, 1, 1);
        final schedule = ScheduleModel(
          id: 'schedule-alternate',
          fishId: 'fish-1',
          aquariumId: 'aquarium-1',
          time: '14:00',
          intervalDays: 2,
          anchorDate: anchorDate,
          foodType: 'pellets',
          active: true,
          createdAt: anchorDate,
          updatedAt: anchorDate,
          createdByUserId: 'user-1',
        );
        await scheduleDs.save(schedule);

        final from = DateTime(2025, 1, 1);
        final to = DateTime(2025, 1, 7);
        final events = generator.generateEvents(
          aquariumId: 'aquarium-1',
          from: from,
          to: to,
        );

        // Should have events on days 1, 3, 5, 7
        expect(events.length, 4);
        expect(events[0].scheduledFor.day, 1);
        expect(events[1].scheduledFor.day, 3);
        expect(events[2].scheduledFor.day, 5);
        expect(events[3].scheduledFor.day, 7);
      },
    );

    test('should return empty list for aquarium with no schedules', () {
      final events = generator.generateEvents(
        aquariumId: 'nonexistent-aquarium',
        from: DateTime(2025, 1, 1),
        to: DateTime(2025, 1, 7),
      );

      expect(events, isEmpty);
    });

    test('should return empty list for inactive schedules', () async {
      final anchorDate = DateTime(2025, 1, 1);
      final schedule = ScheduleModel(
        id: 'schedule-inactive',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: anchorDate,
        foodType: 'flakes',
        active: false, // Inactive
        createdAt: anchorDate,
        updatedAt: anchorDate,
        createdByUserId: 'user-1',
      );
      await scheduleDs.save(schedule);

      final events = generator.generateEvents(
        aquariumId: 'aquarium-1',
        from: DateTime(2025, 1, 1),
        to: DateTime(2025, 1, 7),
      );

      expect(events, isEmpty);
    });

    test('should sort events by scheduledFor time', () async {
      final anchorDate = DateTime(2025, 1, 1);

      // Add two schedules with different times
      final morningSchedule = ScheduleModel(
        id: 'schedule-morning',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: anchorDate,
        foodType: 'flakes',
        active: true,
        createdAt: anchorDate,
        updatedAt: anchorDate,
        createdByUserId: 'user-1',
      );

      final eveningSchedule = ScheduleModel(
        id: 'schedule-evening',
        fishId: 'fish-2',
        aquariumId: 'aquarium-1',
        time: '18:00',
        intervalDays: 1,
        anchorDate: anchorDate,
        foodType: 'pellets',
        active: true,
        createdAt: anchorDate,
        updatedAt: anchorDate,
        createdByUserId: 'user-1',
      );

      await scheduleDs.save(eveningSchedule); // Save evening first
      await scheduleDs.save(morningSchedule);

      final events = generator.generateEvents(
        aquariumId: 'aquarium-1',
        from: DateTime(2025, 1, 1),
        to: DateTime(2025, 1, 1),
      );

      expect(events.length, 2);
      // Morning should come before evening
      expect(events[0].time, '09:00');
      expect(events[1].time, '18:00');
    });
  });

  group('FeedingEventGenerator - status determination', () {
    test(
      'should return EventStatus.pending for future events without logs',
      () async {
        final now = DateTime.now();
        final tomorrow = now.add(const Duration(days: 1));
        final anchorDate = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
        );

        final schedule = ScheduleModel(
          id: 'schedule-future',
          fishId: 'fish-1',
          aquariumId: 'aquarium-1',
          time: '09:00',
          intervalDays: 1,
          anchorDate: anchorDate,
          foodType: 'flakes',
          active: true,
          createdAt: now,
          updatedAt: now,
          createdByUserId: 'user-1',
        );
        await scheduleDs.save(schedule);

        final events = generator.generateEvents(
          aquariumId: 'aquarium-1',
          from: anchorDate,
          to: anchorDate,
        );

        expect(events.length, 1);
        expect(events[0].status, EventStatus.pending);
        expect(events[0].log, isNull);
      },
    );

    test(
      'should return EventStatus.overdue for past events without logs',
      () async {
        final pastDate = DateTime(2020, 1, 1);

        final schedule = ScheduleModel(
          id: 'schedule-past',
          fishId: 'fish-1',
          aquariumId: 'aquarium-1',
          time: '09:00',
          intervalDays: 1,
          anchorDate: pastDate,
          foodType: 'flakes',
          active: true,
          createdAt: pastDate,
          updatedAt: pastDate,
          createdByUserId: 'user-1',
        );
        await scheduleDs.save(schedule);

        final events = generator.generateEvents(
          aquariumId: 'aquarium-1',
          from: pastDate,
          to: pastDate,
        );

        expect(events.length, 1);
        expect(events[0].status, EventStatus.overdue);
        expect(events[0].log, isNull);
      },
    );

    test(
      'should return EventStatus.fed when log exists with action=fed',
      () async {
        final date = DateTime(2025, 1, 15);
        final scheduledFor = DateTime(2025, 1, 15, 9, 0);

        final schedule = ScheduleModel(
          id: 'schedule-fed',
          fishId: 'fish-1',
          aquariumId: 'aquarium-1',
          time: '09:00',
          intervalDays: 1,
          anchorDate: date,
          foodType: 'flakes',
          active: true,
          createdAt: date,
          updatedAt: date,
          createdByUserId: 'user-1',
        );
        await scheduleDs.save(schedule);

        final log = FeedingLogModel(
          id: 'log-fed',
          scheduleId: 'schedule-fed',
          fishId: 'fish-1',
          aquariumId: 'aquarium-1',
          scheduledFor: scheduledFor,
          action: 'fed',
          actedAt: scheduledFor.add(const Duration(minutes: 5)),
          actedByUserId: 'user-1',
          deviceId: 'device-1',
          createdAt: scheduledFor,
        );
        await logDs.save(log);

        final events = generator.generateEvents(
          aquariumId: 'aquarium-1',
          from: date,
          to: date,
        );

        expect(events.length, 1);
        expect(events[0].status, EventStatus.fed);
        expect(events[0].log, isNotNull);
        expect(events[0].log?.id, 'log-fed');
      },
    );

    test(
      'should return EventStatus.skipped when log exists with action=skipped',
      () async {
        final date = DateTime(2025, 1, 15);
        final scheduledFor = DateTime(2025, 1, 15, 9, 0);

        final schedule = ScheduleModel(
          id: 'schedule-skipped',
          fishId: 'fish-1',
          aquariumId: 'aquarium-1',
          time: '09:00',
          intervalDays: 1,
          anchorDate: date,
          foodType: 'flakes',
          active: true,
          createdAt: date,
          updatedAt: date,
          createdByUserId: 'user-1',
        );
        await scheduleDs.save(schedule);

        final log = FeedingLogModel(
          id: 'log-skipped',
          scheduleId: 'schedule-skipped',
          fishId: 'fish-1',
          aquariumId: 'aquarium-1',
          scheduledFor: scheduledFor,
          action: 'skipped',
          actedAt: scheduledFor.add(const Duration(minutes: 5)),
          actedByUserId: 'user-1',
          deviceId: 'device-1',
          createdAt: scheduledFor,
        );
        await logDs.save(log);

        final events = generator.generateEvents(
          aquariumId: 'aquarium-1',
          from: date,
          to: date,
        );

        expect(events.length, 1);
        expect(events[0].status, EventStatus.skipped);
        expect(events[0].log, isNotNull);
        expect(events[0].log?.id, 'log-skipped');
      },
    );
  });

  group('FeedingEventGenerator - O(1) lookup efficiency', () {
    test('should use O(1) lookup for logs with many events', () async {
      final anchorDate = DateTime(2025, 1, 1);

      // Create schedule
      final schedule = ScheduleModel(
        id: 'schedule-perf',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: anchorDate,
        foodType: 'flakes',
        active: true,
        createdAt: anchorDate,
        updatedAt: anchorDate,
        createdByUserId: 'user-1',
      );
      await scheduleDs.save(schedule);

      // Create logs for specific dates (days 5, 10, 15, 20, 25, 30)
      final fedDays = [5, 10, 15, 20, 25, 30];
      for (final day in fedDays) {
        final scheduledFor = DateTime(2025, 1, day, 9, 0);
        final log = FeedingLogModel(
          id: 'log-day-$day',
          scheduleId: 'schedule-perf',
          fishId: 'fish-1',
          aquariumId: 'aquarium-1',
          scheduledFor: scheduledFor,
          action: 'fed',
          actedAt: scheduledFor,
          actedByUserId: 'user-1',
          deviceId: 'device-1',
          createdAt: scheduledFor,
        );
        await logDs.save(log);
      }

      // Generate events for 30 days
      final from = DateTime(2025, 1, 1);
      final to = DateTime(2025, 1, 30);

      // Measure execution time (should be fast with O(1) lookup)
      final stopwatch = Stopwatch()..start();
      final events = generator.generateEvents(
        aquariumId: 'aquarium-1',
        from: from,
        to: to,
      );
      stopwatch.stop();

      // Verify results
      expect(events.length, 30);

      // Count statuses
      final fedCount = events.where((e) => e.status == EventStatus.fed).length;
      final overdueCount = events
          .where((e) => e.status == EventStatus.overdue)
          .length;

      expect(fedCount, 6); // 6 days with logs
      expect(overdueCount, 24); // Rest are overdue (past dates without logs)

      // Performance check: 30 events should be generated quickly
      // Using a generous threshold of 500ms for test stability
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('should correctly match logs by scheduleId and date', () async {
      final date = DateTime(2025, 1, 15);
      final scheduledFor = DateTime(2025, 1, 15, 9, 0);

      // Create two schedules
      final schedule1 = ScheduleModel(
        id: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: date,
        foodType: 'flakes',
        active: true,
        createdAt: date,
        updatedAt: date,
        createdByUserId: 'user-1',
      );

      final schedule2 = ScheduleModel(
        id: 'schedule-2',
        fishId: 'fish-2',
        aquariumId: 'aquarium-1',
        time: '14:00',
        intervalDays: 1,
        anchorDate: date,
        foodType: 'pellets',
        active: true,
        createdAt: date,
        updatedAt: date,
        createdByUserId: 'user-1',
      );

      await scheduleDs.save(schedule1);
      await scheduleDs.save(schedule2);

      // Only create log for schedule-1
      final log = FeedingLogModel(
        id: 'log-1',
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: scheduledFor,
        action: 'fed',
        actedAt: scheduledFor,
        actedByUserId: 'user-1',
        deviceId: 'device-1',
        createdAt: scheduledFor,
      );
      await logDs.save(log);

      final events = generator.generateEvents(
        aquariumId: 'aquarium-1',
        from: date,
        to: date,
      );

      expect(events.length, 2);

      final event1 = events.firstWhere((e) => e.scheduleId == 'schedule-1');
      final event2 = events.firstWhere((e) => e.scheduleId == 'schedule-2');

      expect(event1.status, EventStatus.fed);
      expect(event1.log, isNotNull);

      expect(event2.status, EventStatus.overdue); // Past date, no log
      expect(event2.log, isNull);
    });
  });

  group('FeedingEventGenerator - date range clamping', () {
    test('should clamp date range to 366 days', () async {
      final anchorDate = DateTime(2025, 1, 1);

      final schedule = ScheduleModel(
        id: 'schedule-long',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 7, // Weekly to keep event count reasonable
        anchorDate: anchorDate,
        foodType: 'flakes',
        active: true,
        createdAt: anchorDate,
        updatedAt: anchorDate,
        createdByUserId: 'user-1',
      );
      await scheduleDs.save(schedule);

      final from = DateTime(2025, 1, 1);
      final to = DateTime(2027, 1, 1); // More than 366 days

      final events = generator.generateEvents(
        aquariumId: 'aquarium-1',
        from: from,
        to: to,
      );

      // With 366 days max and weekly schedule, should have ~52 events
      // (366 / 7 ≈ 52.3)
      expect(events.length, lessThanOrEqualTo(53));
      expect(events.length, greaterThan(50));

      // Last event should be within 366 days of from date
      final lastEvent = events.last;
      final daysDiff = lastEvent.scheduledFor.difference(from).inDays;
      expect(daysDiff, lessThanOrEqualTo(366));
    });
  });

  group('FeedingEventGenerator - name resolvers', () {
    test('should resolve fish and aquarium names', () async {
      final date = DateTime(2025, 1, 15);

      final schedule = ScheduleModel(
        id: 'schedule-names',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: date,
        foodType: 'flakes',
        active: true,
        createdAt: date,
        updatedAt: date,
        createdByUserId: 'user-1',
      );
      await scheduleDs.save(schedule);

      final events = generator.generateEvents(
        aquariumId: 'aquarium-1',
        from: date,
        to: date,
        fishNameResolver: (fishId) => fishId == 'fish-1' ? 'Nemo' : null,
        aquariumNameResolver: (aquariumId) =>
            aquariumId == 'aquarium-1' ? 'Living Room Tank' : null,
      );

      expect(events.length, 1);
      expect(events[0].fishName, 'Nemo');
      expect(events[0].aquariumName, 'Living Room Tank');
    });

    test('should resolve avatar for completed events', () async {
      final date = DateTime(2025, 1, 15);
      final scheduledFor = DateTime(2025, 1, 15, 9, 0);

      final schedule = ScheduleModel(
        id: 'schedule-avatar',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: date,
        foodType: 'flakes',
        active: true,
        createdAt: date,
        updatedAt: date,
        createdByUserId: 'user-1',
      );
      await scheduleDs.save(schedule);

      final log = FeedingLogModel(
        id: 'log-avatar',
        scheduleId: 'schedule-avatar',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: scheduledFor,
        action: 'fed',
        actedAt: scheduledFor,
        actedByUserId: 'user-mom',
        deviceId: 'device-1',
        createdAt: scheduledFor,
      );
      await logDs.save(log);

      final events = generator.generateEvents(
        aquariumId: 'aquarium-1',
        from: date,
        to: date,
        avatarResolver: (userId) =>
            userId == 'user-mom' ? 'https://example.com/mom.png' : null,
      );

      expect(events.length, 1);
      expect(events[0].avatarUrl, 'https://example.com/mom.png');
    });
  });

  group('ComputedFeedingEvent - helper methods', () {
    test('isCompleted returns true for fed and skipped', () {
      final fedEvent = ComputedFeedingEvent(
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: DateTime.now(),
        time: '09:00',
        foodType: 'flakes',
        status: EventStatus.fed,
      );

      final skippedEvent = fedEvent.copyWith(status: EventStatus.skipped);
      final pendingEvent = fedEvent.copyWith(status: EventStatus.pending);
      final overdueEvent = fedEvent.copyWith(status: EventStatus.overdue);

      expect(fedEvent.isCompleted, true);
      expect(skippedEvent.isCompleted, true);
      expect(pendingEvent.isCompleted, false);
      expect(overdueEvent.isCompleted, false);
    });

    test('needsAttention returns true for pending and overdue', () {
      final event = ComputedFeedingEvent(
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: DateTime.now(),
        time: '09:00',
        foodType: 'flakes',
        status: EventStatus.pending,
      );

      expect(event.needsAttention, true);
      expect(event.copyWith(status: EventStatus.overdue).needsAttention, true);
      expect(event.copyWith(status: EventStatus.fed).needsAttention, false);
      expect(event.copyWith(status: EventStatus.skipped).needsAttention, false);
    });
  });

  group('ComputedFeedingEvent - fishQuantity', () {
    test('fishQuantity has default value of 1 when not specified', () {
      final event = ComputedFeedingEvent(
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: DateTime.now(),
        time: '09:00',
        foodType: 'flakes',
        status: EventStatus.pending,
      );

      expect(event.fishQuantity, 1);
    });

    test('fishQuantity can be set via constructor', () {
      final event = ComputedFeedingEvent(
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: DateTime.now(),
        time: '09:00',
        foodType: 'flakes',
        status: EventStatus.pending,
        fishQuantity: 5,
      );

      expect(event.fishQuantity, 5);
    });

    test('copyWith preserves fishQuantity when not overridden', () {
      final event = ComputedFeedingEvent(
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: DateTime.now(),
        time: '09:00',
        foodType: 'flakes',
        status: EventStatus.pending,
        fishQuantity: 3,
      );

      final copy = event.copyWith(status: EventStatus.fed);
      expect(copy.fishQuantity, 3);
    });

    test('copyWith updates fishQuantity when specified', () {
      final event = ComputedFeedingEvent(
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: DateTime.now(),
        time: '09:00',
        foodType: 'flakes',
        status: EventStatus.pending,
        fishQuantity: 3,
      );

      final copy = event.copyWith(fishQuantity: 10);
      expect(copy.fishQuantity, 10);
    });

    test('Equatable props includes fishQuantity', () {
      final now = DateTime.now();
      final event1 = ComputedFeedingEvent(
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: now,
        time: '09:00',
        foodType: 'flakes',
        status: EventStatus.pending,
        fishQuantity: 3,
      );

      final event2 = ComputedFeedingEvent(
        scheduleId: 'schedule-1',
        fishId: 'fish-1',
        aquariumId: 'aquarium-1',
        scheduledFor: now,
        time: '09:00',
        foodType: 'flakes',
        status: EventStatus.pending,
        fishQuantity: 5,
      );

      // Different fishQuantity = different events
      expect(event1, isNot(equals(event2)));

      // Same fishQuantity = equal events
      final event3 = event1.copyWith();
      expect(event1, equals(event3));
    });
  });

  group('FeedingEventGenerator - fishQuantityResolver', () {
    test(
      'should pass fishQuantity from resolver to ComputedFeedingEvent',
      () async {
        final date = DateTime(2025, 1, 15);

        final schedule = ScheduleModel(
          id: 'schedule-qty',
          fishId: 'fish-1',
          aquariumId: 'aquarium-1',
          time: '09:00',
          intervalDays: 1,
          anchorDate: date,
          foodType: 'flakes',
          active: true,
          createdAt: date,
          updatedAt: date,
          createdByUserId: 'user-1',
        );
        await scheduleDs.save(schedule);

        final events = generator.generateEvents(
          aquariumId: 'aquarium-1',
          from: date,
          to: date,
          fishQuantityResolver: (fishId) => fishId == 'fish-1' ? 7 : 1,
        );

        expect(events.length, 1);
        expect(events[0].fishQuantity, 7);
      },
    );

    test(
      'should default fishQuantity to 1 when resolver is not provided',
      () async {
        final date = DateTime(2025, 1, 15);

        final schedule = ScheduleModel(
          id: 'schedule-no-qty',
          fishId: 'fish-1',
          aquariumId: 'aquarium-1',
          time: '09:00',
          intervalDays: 1,
          anchorDate: date,
          foodType: 'flakes',
          active: true,
          createdAt: date,
          updatedAt: date,
          createdByUserId: 'user-1',
        );
        await scheduleDs.save(schedule);

        final events = generator.generateEvents(
          aquariumId: 'aquarium-1',
          from: date,
          to: date,
          // No fishQuantityResolver provided
        );

        expect(events.length, 1);
        expect(events[0].fishQuantity, 1);
      },
    );
  });

  group('FeedingEventGenerator - orphan schedule filtering', () {
    late FishLocalDataSource fishDs;

    setUp(() {
      fishDs = FishLocalDataSource();
    });

    test('should filter out schedules where fish does not exist', () async {
      final date = DateTime(2025, 1, 15);

      // Create schedule for non-existent fish (orphan)
      final orphanSchedule = ScheduleModel(
        id: 'schedule-orphan',
        fishId: 'fish-deleted',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: date,
        foodType: 'flakes',
        active: true,
        createdAt: date,
        updatedAt: date,
        createdByUserId: 'user-1',
      );
      await scheduleDs.save(orphanSchedule);

      // Create generator with fishLocalDs
      final generatorWithFishDs = FeedingEventGenerator(
        scheduleLocalDs: scheduleDs,
        feedingLogLocalDs: logDs,
        fishLocalDs: fishDs,
      );

      final events = generatorWithFishDs.generateEvents(
        aquariumId: 'aquarium-1',
        from: date,
        to: date,
      );

      // Should return empty - fish doesn't exist
      expect(events.length, 0);
    });

    test('should filter out schedules where fish is soft-deleted', () async {
      final date = DateTime(2025, 1, 15);

      // Create soft-deleted fish
      final deletedFish = FishModel(
        id: 'fish-soft-deleted',
        aquariumId: 'aquarium-1',
        speciesId: 'angelfish',
        name: 'Angel',
        quantity: 1,
        addedAt: date,
        deletedAt: date, // Soft deleted!
      );
      await fishDs.saveFish(deletedFish);

      // Create schedule for soft-deleted fish
      final schedule = ScheduleModel(
        id: 'schedule-deleted-fish',
        fishId: 'fish-soft-deleted',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: date,
        foodType: 'flakes',
        active: true,
        createdAt: date,
        updatedAt: date,
        createdByUserId: 'user-1',
      );
      await scheduleDs.save(schedule);

      // Create generator with fishLocalDs
      final generatorWithFishDs = FeedingEventGenerator(
        scheduleLocalDs: scheduleDs,
        feedingLogLocalDs: logDs,
        fishLocalDs: fishDs,
      );

      final events = generatorWithFishDs.generateEvents(
        aquariumId: 'aquarium-1',
        from: date,
        to: date,
      );

      // Should return empty - fish is soft-deleted
      expect(events.length, 0);
    });

    test(
      'should include schedules where fish exists and is not deleted',
      () async {
        final date = DateTime(2025, 1, 15);

        // Create active fish
        final activeFish = FishModel(
          id: 'fish-active',
          aquariumId: 'aquarium-1',
          speciesId: 'guppy',
          name: 'Guppy',
          quantity: 5,
          addedAt: date,
        );
        await fishDs.saveFish(activeFish);

        // Create schedule for active fish
        final schedule = ScheduleModel(
          id: 'schedule-active-fish',
          fishId: 'fish-active',
          aquariumId: 'aquarium-1',
          time: '09:00',
          intervalDays: 1,
          anchorDate: date,
          foodType: 'flakes',
          active: true,
          createdAt: date,
          updatedAt: date,
          createdByUserId: 'user-1',
        );
        await scheduleDs.save(schedule);

        // Create generator with fishLocalDs
        final generatorWithFishDs = FeedingEventGenerator(
          scheduleLocalDs: scheduleDs,
          feedingLogLocalDs: logDs,
          fishLocalDs: fishDs,
        );

        final events = generatorWithFishDs.generateEvents(
          aquariumId: 'aquarium-1',
          from: date,
          to: date,
        );

        // Should return 1 event - fish exists and is active
        expect(events.length, 1);
        expect(events[0].fishId, 'fish-active');
      },
    );

    test('should filter orphans and keep valid schedules mixed', () async {
      final date = DateTime(2025, 1, 15);

      // Create one active fish
      final activeFish = FishModel(
        id: 'fish-valid',
        aquariumId: 'aquarium-1',
        speciesId: 'betta',
        name: 'Betta',
        quantity: 1,
        addedAt: date,
      );
      await fishDs.saveFish(activeFish);

      // Create schedule for valid fish
      final validSchedule = ScheduleModel(
        id: 'schedule-valid',
        fishId: 'fish-valid',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: date,
        foodType: 'pellets',
        active: true,
        createdAt: date,
        updatedAt: date,
        createdByUserId: 'user-1',
      );

      // Create schedule for non-existent fish (orphan)
      final orphanSchedule = ScheduleModel(
        id: 'schedule-orphan-2',
        fishId: 'fish-does-not-exist',
        aquariumId: 'aquarium-1',
        time: '18:00',
        intervalDays: 1,
        anchorDate: date,
        foodType: 'flakes',
        active: true,
        createdAt: date,
        updatedAt: date,
        createdByUserId: 'user-1',
      );

      await scheduleDs.save(validSchedule);
      await scheduleDs.save(orphanSchedule);

      // Create generator with fishLocalDs
      final generatorWithFishDs = FeedingEventGenerator(
        scheduleLocalDs: scheduleDs,
        feedingLogLocalDs: logDs,
        fishLocalDs: fishDs,
      );

      final events = generatorWithFishDs.generateEvents(
        aquariumId: 'aquarium-1',
        from: date,
        to: date,
      );

      // Should return only 1 event (valid schedule)
      expect(events.length, 1);
      expect(events[0].scheduleId, 'schedule-valid');
      expect(events[0].fishId, 'fish-valid');
    });

    test('should work without fishLocalDs (backward compatible)', () async {
      final date = DateTime(2025, 1, 15);

      // Create schedule (no fish in DB)
      final schedule = ScheduleModel(
        id: 'schedule-no-fish-check',
        fishId: 'fish-any',
        aquariumId: 'aquarium-1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: date,
        foodType: 'flakes',
        active: true,
        createdAt: date,
        updatedAt: date,
        createdByUserId: 'user-1',
      );
      await scheduleDs.save(schedule);

      // Generator WITHOUT fishLocalDs (backward compatible)
      final generatorWithoutFishDs = FeedingEventGenerator(
        scheduleLocalDs: scheduleDs,
        feedingLogLocalDs: logDs,
        // fishLocalDs not provided
      );

      final events = generatorWithoutFishDs.generateEvents(
        aquariumId: 'aquarium-1',
        from: date,
        to: date,
      );

      // Should return event - no filtering without fishLocalDs
      expect(events.length, 1);
    });
  });
}
