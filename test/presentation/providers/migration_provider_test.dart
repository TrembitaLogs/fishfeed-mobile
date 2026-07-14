import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/presentation/providers/migration_provider.dart';
import 'package:fishfeed/services/migration/migration_service.dart';

class MockMigrationService extends Mock implements MigrationService {}

void main() {
  late MockMigrationService mockService;
  late MigrationNotifier notifier;

  setUp(() {
    mockService = MockMigrationService();
    notifier = MigrationNotifier(mockService);
  });

  group('checkAndMigrate happy path', () {
    test(
      'completes with MigrationCompleted when no migration needed',
      () async {
        when(() => mockService.needsMigration()).thenReturn(false);
        when(() => mockService.clearLegacySyncQueue()).thenAnswer((_) async {});

        await notifier.checkAndMigrate();

        expect(notifier.state, isA<MigrationCompleted>());
      },
    );
  });

  group('Notifier dispose safety (mounted guards)', () {
    // Site 1: `await migrateDefaultAquarium()` -> `state = MigrationFailed`.
    // If the notifier is disposed during the migrate await, resuming and
    // assigning `state` must NOT throw "used after dispose".
    test(
      'checkAndMigrate does not touch state after dispose during migrate',
      () async {
        when(() => mockService.needsMigration()).thenReturn(true);
        when(() => mockService.migrateDefaultAquarium()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return const MigrationError(message: 'boom');
        });
        when(() => mockService.clearLegacySyncQueue()).thenAnswer((_) async {});

        final future = notifier.checkAndMigrate();
        notifier.dispose();

        await expectLater(future, completes);
      },
    );

    // Site 2: `await clearLegacySyncQueue()` -> `state = MigrationCompleted`.
    // If the notifier is disposed during the cleanup await, resuming and
    // assigning `state` must NOT throw "used after dispose".
    test(
      'checkAndMigrate does not touch state after dispose during cleanup',
      () async {
        when(() => mockService.needsMigration()).thenReturn(false);
        when(() => mockService.clearLegacySyncQueue()).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });

        final future = notifier.checkAndMigrate();
        notifier.dispose();

        await expectLater(future, completes);
      },
    );
  });
}
