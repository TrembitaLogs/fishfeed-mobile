import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:fishfeed/services/migration/schedule_id_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  setUpAll(() {
    Hive.init('./.hive_test_tmp');
  });

  test('returns NoMigrationNeeded when flag is already set', () async {
    SharedPreferences.setMockInitialValues(const {
      'schedule_id_migration_v1_done': true,
    });
    final prefs = await SharedPreferences.getInstance();

    final migration = ScheduleIdMigration(
      scheduleDs: _UnusedDs(),
      prefs: prefs,
    );

    final result = await migration.run();

    expect(result, isA<NoMigrationNeeded>());
  });

  group('isValidUuidV4', () {
    test('accepts canonical lowercase UUID v4', () {
      expect(isValidUuidV4('a74663b3-e1c1-4cb7-ad05-8e6a92af4f82'), isTrue);
    });

    test('rejects fishId_HHmm composite', () {
      expect(
        isValidUuidV4('a74663b3-e1c1-4cb7-ad05-8e6a92af4f82_1530'),
        isFalse,
      );
    });

    test('rejects empty and garbage strings', () {
      expect(isValidUuidV4(''), isFalse);
      expect(isValidUuidV4('not-a-uuid'), isFalse);
    });
  });

  group('ScheduleIdMigration.run — mutation', () {
    late Box<dynamic> box;
    late ScheduleLocalDataSource ds;
    late SharedPreferences prefs;

    setUp(() async {
      if (!Hive.isAdapterRegistered(24)) {
        Hive.registerAdapter(ScheduleModelAdapter());
      }
      box = await Hive.openBox<dynamic>('schedules_test_${const Uuid().v4()}');
      ds = ScheduleLocalDataSource(schedulesBox: box);

      SharedPreferences.setMockInitialValues(const {});
      prefs = await SharedPreferences.getInstance();
    });

    tearDown(() async {
      await box.close();
    });

    test('regenerates id for contaminated unsynced schedule', () async {
      final fishId = const Uuid().v4();
      final bad = _makeSchedule(id: '${fishId}_1530', fishId: fishId);
      await ds.save(bad);

      final result = await ScheduleIdMigration(
        scheduleDs: ds,
        prefs: prefs,
      ).run();

      expect(result, isA<MigrationSuccess>());
      expect((result as MigrationSuccess).repairedCount, 1);
      expect(result.skippedAlreadySyncedCount, 0);

      final all = ds.getAll();
      expect(all, hasLength(1));
      expect(isValidUuidV4(all.single.id), isTrue);
      expect(all.single.fishId, fishId);
      expect(all.single.time, '15:30');
      expect(
        all.single.synced,
        isFalse,
        reason: 'repaired record must re-sync as create',
      );
    });

    test('leaves valid UUID schedules untouched', () async {
      final good = _makeSchedule(
        id: const Uuid().v4(),
        fishId: const Uuid().v4(),
      );
      await ds.save(good);

      final result = await ScheduleIdMigration(
        scheduleDs: ds,
        prefs: prefs,
      ).run();

      expect(result, isA<MigrationSuccess>());
      expect((result as MigrationSuccess).repairedCount, 0);

      final all = ds.getAll();
      expect(all.single.id, good.id);
    });

    test(
      'skips contaminated record that already has serverUpdatedAt',
      () async {
        // Defensive: this state is impossible (server rejects 422), but if Hive
        // somehow ended up with one, do not double-create on the server.
        final fishId = const Uuid().v4();
        final weird = _makeSchedule(
          id: '${fishId}_0900',
          fishId: fishId,
          serverUpdatedAt: DateTime.utc(2026, 5, 1),
          synced: true,
        );
        await ds.save(weird);

        final result = await ScheduleIdMigration(
          scheduleDs: ds,
          prefs: prefs,
        ).run();

        expect((result as MigrationSuccess).repairedCount, 0);
        expect(result.skippedAlreadySyncedCount, 1);
        expect(ds.getById('${fishId}_0900'), isNotNull);
      },
    );

    test('sets idempotency flag so a second run is a no-op', () async {
      final fishId = const Uuid().v4();
      await ds.save(_makeSchedule(id: '${fishId}_1530', fishId: fishId));

      final m = ScheduleIdMigration(scheduleDs: ds, prefs: prefs);
      await m.run();
      final second = await m.run();

      expect(second, isA<NoMigrationNeeded>());
    });
  });
}

ScheduleModel _makeSchedule({
  required String id,
  required String fishId,
  DateTime? serverUpdatedAt,
  bool synced = false,
}) {
  final now = DateTime.utc(2026, 5, 4);
  return ScheduleModel(
    id: id,
    fishId: fishId,
    aquariumId: 'aq-1',
    time: '15:30',
    intervalDays: 1,
    anchorDate: now,
    foodType: 'flakes',
    portionHint: null,
    active: true,
    createdAt: now,
    updatedAt: now,
    createdByUserId: 'user-1',
    synced: synced,
    serverUpdatedAt: serverUpdatedAt,
  );
}

class _UnusedDs implements ScheduleLocalDataSource {
  @override
  Never noSuchMethod(Invocation invocation) =>
      throw StateError('datasource must not be touched when flag is set');
}
