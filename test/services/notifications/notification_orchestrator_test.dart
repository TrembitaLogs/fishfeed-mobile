import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:fishfeed/services/notifications/notification_orchestrator.dart';

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
    late NotificationOrchestrator orchestrator;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_notif_test_');
      Hive.init(tempDir.path);
      await HiveBoxes.initForTesting();
      scheduleDs = ScheduleLocalDataSource();
      fishDs = FishLocalDataSource();
      aquariumDs = AquariumLocalDataSource();
      orchestrator = NotificationOrchestrator(
        scheduleDs: scheduleDs,
        fishDs: fishDs,
        aquariumDs: aquariumDs,
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
  });
}
