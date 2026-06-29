import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/services/sentry/sentry_service.dart';

class MockSentryService extends Mock implements SentryService {}

void main() {
  late Directory tempDir;
  late MockSentryService mockSentry;

  setUpAll(() {
    registerFallbackValue(SentryLevel.warning);
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('deletion_safety_test_');
    Hive.init(tempDir.path);
    await HiveBoxes.initForTesting();

    mockSentry = MockSentryService();
    when(
      () => mockSentry.captureMessage(
        any(),
        level: any(named: 'level'),
        extras: any(named: 'extras'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockSentry.addBreadcrumb(
        message: any(named: 'message'),
        category: any(named: 'category'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await HiveBoxes.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AquariumLocalDataSource deletion safety', () {
    late AquariumLocalDataSource aquariumDs;

    setUp(() {
      aquariumDs = AquariumLocalDataSource(sentry: mockSentry);
    });

    AquariumModel buildAquarium({
      String id = 'aq-1',
      bool synced = true,
      DateTime? serverUpdatedAt,
    }) {
      return AquariumModel(
        id: id,
        userId: 'user-1',
        name: 'Tank',
        createdAt: DateTime(2025, 1, 1),
        synced: synced,
        serverUpdatedAt: serverUpdatedAt ?? DateTime(2025, 1, 1),
        updatedAt: serverUpdatedAt ?? DateTime(2025, 1, 1),
      );
    }

    test(
      'softDelete emits a warning Sentry message with local origin',
      () async {
        await aquariumDs.saveAquarium(buildAquarium(id: 'aq-1'));

        await aquariumDs.softDelete('aq-1');

        verify(
          () => mockSentry.captureMessage(
            'Aquarium soft-deleted locally',
            level: SentryLevel.warning,
            extras: {'aquarium_id': 'aq-1', 'origin': 'local_soft_delete'},
          ),
        ).called(1);
      },
    );

    test(
      'getDeletedAquariums excludes synced tombstones, includes unsynced',
      () async {
        // Unsynced tombstone: must be re-sent.
        await aquariumDs.saveAquarium(buildAquarium(id: 'aq-unsynced'));
        await aquariumDs.softDelete('aq-unsynced');

        // Synced tombstone: already accepted by server, must NOT be re-sent.
        await aquariumDs.saveAquarium(buildAquarium(id: 'aq-synced'));
        await aquariumDs.softDelete('aq-synced');
        await aquariumDs.markAsSynced('aq-synced', DateTime(2025, 2, 1));

        final deleted = aquariumDs.getDeletedAquariums();

        expect(deleted.map((a) => a.id), contains('aq-unsynced'));
        expect(deleted.map((a) => a.id), isNot(contains('aq-synced')));
      },
    );

    test(
      'purgeSyncedDeletions removes only isDeleted && synced records',
      () async {
        await aquariumDs.saveAquarium(buildAquarium(id: 'aq-synced'));
        await aquariumDs.softDelete('aq-synced');
        await aquariumDs.markAsSynced('aq-synced', DateTime(2025, 2, 1));

        await aquariumDs.saveAquarium(buildAquarium(id: 'aq-unsynced'));
        await aquariumDs.softDelete('aq-unsynced');

        await aquariumDs.purgeSyncedDeletions();

        // Synced tombstone is gone; unsynced tombstone is preserved.
        expect(aquariumDs.getAquariumById('aq-synced'), isNull);
        expect(aquariumDs.getAquariumById('aq-unsynced'), isNotNull);
      },
    );

    test(
      'round-trip: soft-delete -> in getDeleted -> markAsSynced -> purged',
      () async {
        await aquariumDs.saveAquarium(buildAquarium(id: 'aq-1'));

        await aquariumDs.softDelete('aq-1');
        expect(
          aquariumDs.getDeletedAquariums().map((a) => a.id),
          contains('aq-1'),
        );

        // Server confirms the deletion (id returned in synced_ids).
        await aquariumDs.markAsSynced('aq-1', DateTime(2025, 2, 1));
        expect(
          aquariumDs.getDeletedAquariums().map((a) => a.id),
          isNot(contains('aq-1')),
        );

        await aquariumDs.purgeSyncedDeletions();
        expect(aquariumDs.getAquariumById('aq-1'), isNull);
      },
    );
  });

  group('FishLocalDataSource deletion safety', () {
    late FishLocalDataSource fishDs;

    setUp(() {
      fishDs = FishLocalDataSource(sentry: mockSentry);
    });

    FishModel buildFish({
      String id = 'fish-1',
      bool synced = true,
      DateTime? serverUpdatedAt,
    }) {
      return FishModel(
        id: id,
        aquariumId: 'aq-1',
        speciesId: 'species-1',
        addedAt: DateTime(2025, 1, 1),
        synced: synced,
        serverUpdatedAt: serverUpdatedAt ?? DateTime(2025, 1, 1),
        updatedAt: serverUpdatedAt ?? DateTime(2025, 1, 1),
      );
    }

    test('softDelete records a breadcrumb with local origin', () async {
      await fishDs.saveFish(buildFish(id: 'fish-1'));

      await fishDs.softDelete('fish-1');

      verify(
        () => mockSentry.addBreadcrumb(
          message: 'Fish soft-deleted locally',
          category: 'data.delete',
          data: {'fish_id': 'fish-1', 'origin': 'local_soft_delete'},
        ),
      ).called(1);
    });

    test(
      'getDeletedFish excludes synced tombstones, includes unsynced',
      () async {
        await fishDs.saveFish(buildFish(id: 'fish-unsynced'));
        await fishDs.softDelete('fish-unsynced');

        await fishDs.saveFish(buildFish(id: 'fish-synced'));
        await fishDs.softDelete('fish-synced');
        await fishDs.markAsSynced('fish-synced', DateTime(2025, 2, 1));

        final deleted = fishDs.getDeletedFish();

        expect(deleted.map((f) => f.id), contains('fish-unsynced'));
        expect(deleted.map((f) => f.id), isNot(contains('fish-synced')));
      },
    );

    test(
      'purgeSyncedDeletions removes only isDeleted && synced records',
      () async {
        await fishDs.saveFish(buildFish(id: 'fish-synced'));
        await fishDs.softDelete('fish-synced');
        await fishDs.markAsSynced('fish-synced', DateTime(2025, 2, 1));

        await fishDs.saveFish(buildFish(id: 'fish-unsynced'));
        await fishDs.softDelete('fish-unsynced');

        await fishDs.purgeSyncedDeletions();

        expect(fishDs.getFishById('fish-synced'), isNull);
        expect(fishDs.getFishById('fish-unsynced'), isNotNull);
      },
    );

    test(
      'round-trip: soft-delete -> in getDeleted -> markAsSynced -> purged',
      () async {
        await fishDs.saveFish(buildFish(id: 'fish-1'));

        await fishDs.softDelete('fish-1');
        expect(fishDs.getDeletedFish().map((f) => f.id), contains('fish-1'));

        await fishDs.markAsSynced('fish-1', DateTime(2025, 2, 1));
        expect(
          fishDs.getDeletedFish().map((f) => f.id),
          isNot(contains('fish-1')),
        );

        await fishDs.purgeSyncedDeletions();
        expect(fishDs.getFishById('fish-1'), isNull);
      },
    );
  });
}
