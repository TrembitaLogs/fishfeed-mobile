import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:fishfeed/services/notifications/notification_orchestrator.dart';
import 'package:fishfeed/services/notifications/planned_alarm.dart';
import 'fake_notification_service.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('NotificationOrchestrator.eventIdFor', () {
    test('produces deterministic positive 32-bit int', () {
      final id1 = NotificationOrchestrator.eventIdFor(
        'schedule-1',
        DateTime(2026, 5, 6),
        '09:00',
      );
      final id2 = NotificationOrchestrator.eventIdFor(
        'schedule-1',
        DateTime(2026, 5, 6),
        '09:00',
      );
      expect(id1, equals(id2));
      expect(id1, greaterThanOrEqualTo(0));
      expect(id1, lessThanOrEqualTo(0x7FFFFFFF));
    });

    test('different scheduleId → different id', () {
      final id1 = NotificationOrchestrator.eventIdFor(
        'schedule-1',
        DateTime(2026, 5, 6),
        '09:00',
      );
      final id2 = NotificationOrchestrator.eventIdFor(
        'schedule-2',
        DateTime(2026, 5, 6),
        '09:00',
      );
      expect(id1, isNot(equals(id2)));
    });

    test('different date → different id', () {
      final id1 = NotificationOrchestrator.eventIdFor(
        'schedule-1',
        DateTime(2026, 5, 6),
        '09:00',
      );
      final id2 = NotificationOrchestrator.eventIdFor(
        'schedule-1',
        DateTime(2026, 5, 7),
        '09:00',
      );
      expect(id1, isNot(equals(id2)));
    });

    test('different time → different id', () {
      final id1 = NotificationOrchestrator.eventIdFor(
        'schedule-1',
        DateTime(2026, 5, 6),
        '09:00',
      );
      final id2 = NotificationOrchestrator.eventIdFor(
        'schedule-1',
        DateTime(2026, 5, 6),
        '10:00',
      );
      expect(id1, isNot(equals(id2)));
    });
  });

  // ============ planForWindow helpers ============

  ScheduleModel makeSchedule({
    String id = 's1',
    String fishId = 'f1',
    String aquariumId = 'a1',
    String time = '09:00',
    int intervalDays = 1,
    DateTime? anchorDate,
    bool active = true,
  }) {
    final now = DateTime.now();
    return ScheduleModel(
      id: id,
      fishId: fishId,
      aquariumId: aquariumId,
      time: time,
      intervalDays: intervalDays,
      anchorDate: anchorDate ?? DateTime(now.year, now.month, now.day),
      foodType: 'flakes',
      active: active,
      createdAt: now,
      updatedAt: now,
      createdByUserId: 'u1',
      synced: false,
    );
  }

  FishModel makeFish({
    String id = 'f1',
    String aquariumId = 'a1',
    String? name = 'Goldie',
    DateTime? deletedAt,
  }) {
    return FishModel(
      id: id,
      aquariumId: aquariumId,
      speciesId: 'goldfish',
      name: name,
      addedAt: DateTime.now(),
      deletedAt: deletedAt,
    );
  }

  AquariumModel makeAquarium({String id = 'a1', String userId = 'u1'}) {
    return AquariumModel(
      id: id,
      userId: userId,
      name: 'Tank',
      createdAt: DateTime.now(),
    );
  }

  group('NotificationOrchestrator.planForWindow', () {
    late Directory tempDir;
    late ScheduleLocalDataSource scheduleDs;
    late FishLocalDataSource fishDs;
    late AquariumLocalDataSource aquariumDs;
    late FakeNotificationService fakeNotif;
    late NotificationOrchestrator orchestrator;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_notif_test_');
      Hive.init(tempDir.path);
      await HiveBoxes.initForTesting();
      scheduleDs = ScheduleLocalDataSource();
      fishDs = FishLocalDataSource();
      aquariumDs = AquariumLocalDataSource();
      fakeNotif = FakeNotificationService();
      orchestrator = NotificationOrchestrator(
        scheduleDs: scheduleDs,
        fishDs: fishDs,
        aquariumDs: aquariumDs,
        notificationService: fakeNotif,
      );
    });

    tearDown(() async {
      await HiveBoxes.close();
      await Hive.deleteFromDisk();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('plans 7 alarms for daily schedule (intervalDays=1)', () async {
      await aquariumDs.saveAquarium(makeAquarium());
      await fishDs.saveFish(makeFish());
      await scheduleDs.save(makeSchedule());

      final now = DateTime(2026, 5, 6, 12, 0);
      final planned = orchestrator.planForWindow(now: now);

      expect(planned, hasLength(7));
      expect(planned.first.scheduleId, 's1');
      expect(planned.first.fishId, 'f1');
      expect(planned.first.aquariumId, 'a1');
      // Verify all 7 days, time 9:00 each
      for (var i = 0; i < 7; i++) {
        expect(planned[i].scheduledAt.hour, 9);
        expect(planned[i].scheduledAt.minute, 0);
      }
      // Verify deterministic eventIds
      expect(
        planned.map((p) => p.eventId).toSet(),
        hasLength(7),
        reason: '7 distinct alarms must have 7 distinct eventIds',
      );
    });

    test('plans every-other-day for intervalDays=2 anchor today', () async {
      final today = DateTime(2026, 5, 6);
      await aquariumDs.saveAquarium(makeAquarium());
      await fishDs.saveFish(makeFish());
      await scheduleDs.save(makeSchedule(intervalDays: 2, anchorDate: today));

      final planned = orchestrator.planForWindow(now: today, windowDays: 7);

      // Expect alarms for: 2026-05-06, 05-08, 05-10, 05-12 → 4 alarms
      expect(planned, hasLength(4));
      expect(planned[0].scheduledAt.day, 6);
      expect(planned[1].scheduledAt.day, 8);
      expect(planned[2].scheduledAt.day, 10);
      expect(planned[3].scheduledAt.day, 12);
    });

    test('skips schedules whose fish has been deleted from Hive', () async {
      await aquariumDs.saveAquarium(makeAquarium());
      // intentionally NOT saving the fish — orphan from missing fish
      await scheduleDs.save(makeSchedule());

      final planned = orchestrator.planForWindow(now: DateTime(2026, 5, 6));
      expect(planned, isEmpty);
    });

    test('skips schedules whose fish is soft-deleted', () async {
      final today = DateTime(2026, 5, 6);
      await aquariumDs.saveAquarium(makeAquarium());
      await fishDs.saveFish(makeFish(deletedAt: today));
      await scheduleDs.save(makeSchedule());

      final planned = orchestrator.planForWindow(now: today);
      expect(planned, isEmpty);
    });

    test('skips schedules whose aquarium is gone', () async {
      await fishDs.saveFish(makeFish());
      // no aquarium saved
      await scheduleDs.save(makeSchedule());

      final planned = orchestrator.planForWindow(now: DateTime(2026, 5, 6));
      expect(planned, isEmpty);
    });

    test(
      'skips schedules whose fish belongs to a different aquarium',
      () async {
        await aquariumDs.saveAquarium(makeAquarium(id: 'a1'));
        await fishDs.saveFish(makeFish(aquariumId: 'a-other'));
        await scheduleDs.save(makeSchedule(aquariumId: 'a1'));

        final planned = orchestrator.planForWindow(now: DateTime(2026, 5, 6));
        expect(planned, isEmpty);
      },
    );

    test('skips inactive schedules', () async {
      await aquariumDs.saveAquarium(makeAquarium());
      await fishDs.saveFish(makeFish());
      await scheduleDs.save(makeSchedule(active: false));

      final planned = orchestrator.planForWindow(now: DateTime(2026, 5, 6));
      expect(planned, isEmpty);
    });
  });

  group('NotificationOrchestrator.planForWindow budget trim', () {
    late Directory tempDir;
    late ScheduleLocalDataSource scheduleDs;
    late FishLocalDataSource fishDs;
    late AquariumLocalDataSource aquariumDs;
    late FakeNotificationService fakeNotif;
    late NotificationOrchestrator orchestrator;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'hive_notif_budget_test_',
      );
      Hive.init(tempDir.path);
      await HiveBoxes.initForTesting();
      scheduleDs = ScheduleLocalDataSource();
      fishDs = FishLocalDataSource();
      aquariumDs = AquariumLocalDataSource();
      fakeNotif = FakeNotificationService();
      orchestrator = NotificationOrchestrator(
        scheduleDs: scheduleDs,
        fishDs: fishDs,
        aquariumDs: aquariumDs,
        notificationService: fakeNotif,
      );
    });

    tearDown(() async {
      await HiveBoxes.close();
      await Hive.deleteFromDisk();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'trims to maxAlarms when planned exceeds budget, keeping nearest dates',
      () async {
        // 3 fish × 4 schedules each × 7 days = 84 alarms — exceeds maxAlarms=60
        await aquariumDs.saveAquarium(makeAquarium());
        for (var f = 0; f < 3; f++) {
          await fishDs.saveFish(makeFish(id: 'f$f', aquariumId: 'a1'));
          for (var s = 0; s < 4; s++) {
            await scheduleDs.save(
              makeSchedule(
                id: 'f${f}_s$s',
                fishId: 'f$f',
                time: '${(7 + s).toString().padLeft(2, '0')}:00',
              ),
            );
          }
        }

        final planned = orchestrator.planForWindow(
          now: DateTime(2026, 5, 6),
          maxAlarms: 60,
        );

        expect(planned, hasLength(60));
        // Verify chronological order — nearest dates kept first.
        for (var i = 1; i < planned.length; i++) {
          final prev = planned[i - 1].scheduledAt;
          final curr = planned[i].scheduledAt;
          expect(
            curr.isAtSameMomentAs(prev) || curr.isAfter(prev),
            isTrue,
            reason: 'plan must be sorted ascending by scheduledAt',
          );
        }
      },
    );

    test('does not trim when planned fits in maxAlarms', () async {
      await aquariumDs.saveAquarium(makeAquarium());
      await fishDs.saveFish(makeFish());
      await scheduleDs.save(makeSchedule());

      final planned = orchestrator.planForWindow(
        now: DateTime(2026, 5, 6),
        maxAlarms: 200,
      );

      expect(planned, hasLength(7));
    });

    test('does not trim when maxAlarms is null (default)', () async {
      await aquariumDs.saveAquarium(makeAquarium());
      for (var f = 0; f < 5; f++) {
        await fishDs.saveFish(makeFish(id: 'f$f', aquariumId: 'a1'));
        await scheduleDs.save(makeSchedule(id: 'f${f}_s0', fishId: 'f$f'));
      }

      final planned = orchestrator.planForWindow(now: DateTime(2026, 5, 6));
      expect(planned, hasLength(35)); // 5 fish × 7 days
    });
  });

  group('NotificationOrchestrator.reconcile', () {
    late Directory tempDir;
    late ScheduleLocalDataSource scheduleDs;
    late FishLocalDataSource fishDs;
    late AquariumLocalDataSource aquariumDs;
    late FakeNotificationService fakeNotif;
    late NotificationOrchestrator orchestrator;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_notif_reconcile_');
      Hive.init(tempDir.path);
      await HiveBoxes.initForTesting();
      scheduleDs = ScheduleLocalDataSource();
      fishDs = FishLocalDataSource();
      aquariumDs = AquariumLocalDataSource();
      fakeNotif = FakeNotificationService();
      orchestrator = NotificationOrchestrator(
        scheduleDs: scheduleDs,
        fishDs: fishDs,
        aquariumDs: aquariumDs,
        notificationService: fakeNotif,
        now: () => DateTime(2026, 5, 6, 12, 0),
      );
    });

    tearDown(() async {
      await HiveBoxes.close();
      await Hive.deleteFromDisk();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'first reconcile schedules planned alarms; result reflects counts',
      () async {
        await aquariumDs.saveAquarium(makeAquarium());
        await fishDs.saveFish(makeFish());
        await scheduleDs.save(makeSchedule());

        final result = await orchestrator.reconcile(
          reason: ReconcileReason.appLaunch,
        );

        expect(result.isSuccess, isTrue);
        expect(result.added, 7);
        expect(result.cancelled, 0);
        expect(fakeNotif.scheduleCallCount, 7);
      },
    );

    test('second reconcile with unchanged state is idempotent', () async {
      await aquariumDs.saveAquarium(makeAquarium());
      await fishDs.saveFish(makeFish());
      await scheduleDs.save(makeSchedule());

      await orchestrator.reconcile(reason: ReconcileReason.appLaunch);
      final secondResult = await orchestrator.reconcile(
        reason: ReconcileReason.appResume,
      );

      expect(secondResult.added, 0);
      expect(secondResult.cancelled, 0);
      expect(secondResult.kept, 7);
    });

    test('localeChanged forces full cancel + replan', () async {
      await aquariumDs.saveAquarium(makeAquarium());
      await fishDs.saveFish(makeFish());
      await scheduleDs.save(makeSchedule());

      await orchestrator.reconcile(reason: ReconcileReason.appLaunch);
      expect(fakeNotif.cancelAllCallCount, 0);

      final result = await orchestrator.reconcile(
        reason: ReconcileReason.localeChanged,
      );

      expect(fakeNotif.cancelAllCallCount, 1);
      expect(result.added, 7);
      expect(result.cancelled, 0); // cancelAll bypasses individual diff cancels
    });
  });

  group('NotificationOrchestrator.diffAgainstSystem', () {
    PlannedAlarm makeAlarm(int eventId, {String scheduleId = 's1'}) {
      final at = tz.TZDateTime(tz.local, 2026, 5, 6, 9, 0);
      return PlannedAlarm(
        eventId: eventId,
        scheduleId: scheduleId,
        fishId: 'f1',
        aquariumId: 'a1',
        scheduledAt: at,
        title: 'T',
        body: 'B',
        channel: NotificationChannel.feedingReminders,
        payload: 'feeding|$scheduleId|2026-05-06|0900',
      );
    }

    test('toAdd is empty, toCancel has stale ids, toKeep has overlap', () {
      final planned = [makeAlarm(1)];
      final pending = <int>{1, 99};

      final diff = NotificationOrchestrator.diffAgainstSystem(
        planned: planned,
        pendingIds: pending,
      );

      expect(diff.toAdd, isEmpty);
      expect(diff.toCancel, equals({99}));
      expect(diff.toKeep, equals({1}));
    });

    test('plans entirely missing from system go to toAdd', () {
      final planned = [makeAlarm(1), makeAlarm(2)];

      final diff = NotificationOrchestrator.diffAgainstSystem(
        planned: planned,
        pendingIds: <int>{},
      );

      expect(diff.toAdd.map((p) => p.eventId).toSet(), equals({1, 2}));
      expect(diff.toCancel, isEmpty);
      expect(diff.toKeep, isEmpty);
    });

    test('empty plan with stale pending → all go to toCancel', () {
      final diff = NotificationOrchestrator.diffAgainstSystem(
        planned: <PlannedAlarm>[],
        pendingIds: <int>{1, 2, 3},
      );

      expect(diff.toAdd, isEmpty);
      expect(diff.toCancel, equals({1, 2, 3}));
      expect(diff.toKeep, isEmpty);
    });

    test('mixed scenario — some keep, some add, some cancel', () {
      final planned = [makeAlarm(1), makeAlarm(2), makeAlarm(3)];
      final pending = <int>{2, 3, 99};

      final diff = NotificationOrchestrator.diffAgainstSystem(
        planned: planned,
        pendingIds: pending,
      );

      expect(diff.toAdd.map((p) => p.eventId).toSet(), equals({1}));
      expect(diff.toCancel, equals({99}));
      expect(diff.toKeep, equals({2, 3}));
    });
  });
}
