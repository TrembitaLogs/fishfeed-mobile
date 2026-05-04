import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/services/migration/schedule_id_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}

class _UnusedDs implements ScheduleLocalDataSource {
  @override
  Never noSuchMethod(Invocation invocation) =>
      throw StateError('datasource must not be touched when flag is set');
}
