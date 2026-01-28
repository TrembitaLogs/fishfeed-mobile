import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/services/sync/conflict_resolver.dart';

void main() {
  group('ConflictResolver', () {
    late ConflictResolver resolver;

    setUp(() {
      resolver = ConflictResolver();
    });

    group('resolveConflict', () {
      test('returns useLocal when local timestamp is newer', () {
        final localUpdatedAt = DateTime(2024, 1, 15, 12, 0, 0);
        final serverUpdatedAt = DateTime(2024, 1, 15, 11, 0, 0);

        final result = resolver.resolveConflict(
          localUpdatedAt: localUpdatedAt,
          serverUpdatedAt: serverUpdatedAt,
          hasDataDifferences: true,
        );

        expect(result, ConflictResolution.useLocal);
      });

      test('returns useServer when server timestamp is newer', () {
        final localUpdatedAt = DateTime(2024, 1, 15, 11, 0, 0);
        final serverUpdatedAt = DateTime(2024, 1, 15, 12, 0, 0);

        final result = resolver.resolveConflict(
          localUpdatedAt: localUpdatedAt,
          serverUpdatedAt: serverUpdatedAt,
          hasDataDifferences: true,
        );

        expect(result, ConflictResolution.useServer);
      });

      test('returns requireManual when timestamps are equal and data differs', () {
        final timestamp = DateTime(2024, 1, 15, 12, 0, 0);

        final result = resolver.resolveConflict(
          localUpdatedAt: timestamp,
          serverUpdatedAt: timestamp,
          hasDataDifferences: true,
        );

        // When timestamps are equal and data differs, requires manual resolution
        expect(result, ConflictResolution.requireManual);
      });

      test('returns useLocal when timestamps are equal and data is same', () {
        final timestamp = DateTime(2024, 1, 15, 12, 0, 0);

        final result = resolver.resolveConflict(
          localUpdatedAt: timestamp,
          serverUpdatedAt: timestamp,
          hasDataDifferences: false,
        );

        // When timestamps are equal and data is same, local wins
        expect(result, ConflictResolution.useLocal);
      });

      test('returns requireManual when timestamps are within 5 seconds and data differs',
          () {
        final localUpdatedAt = DateTime(2024, 1, 15, 12, 0, 3);
        final serverUpdatedAt = DateTime(2024, 1, 15, 12, 0, 0);

        final result = resolver.resolveConflict(
          localUpdatedAt: localUpdatedAt,
          serverUpdatedAt: serverUpdatedAt,
          hasDataDifferences: true,
        );

        expect(result, ConflictResolution.requireManual);
      });

      test('returns useLocal when timestamps are within 5 seconds but data is same',
          () {
        final localUpdatedAt = DateTime(2024, 1, 15, 12, 0, 3);
        final serverUpdatedAt = DateTime(2024, 1, 15, 12, 0, 0);

        final result = resolver.resolveConflict(
          localUpdatedAt: localUpdatedAt,
          serverUpdatedAt: serverUpdatedAt,
          hasDataDifferences: false,
        );

        expect(result, ConflictResolution.useLocal);
      });

      test('returns useServer when server is slightly newer but outside threshold',
          () {
        final localUpdatedAt = DateTime(2024, 1, 15, 12, 0, 0);
        final serverUpdatedAt = DateTime(2024, 1, 15, 12, 0, 6);

        final result = resolver.resolveConflict(
          localUpdatedAt: localUpdatedAt,
          serverUpdatedAt: serverUpdatedAt,
          hasDataDifferences: true,
        );

        expect(result, ConflictResolution.useServer);
      });

      test('uses custom critical threshold', () {
        final customResolver = ConflictResolver(
          criticalThreshold: const Duration(seconds: 10),
        );

        final localUpdatedAt = DateTime(2024, 1, 15, 12, 0, 8);
        final serverUpdatedAt = DateTime(2024, 1, 15, 12, 0, 0);

        final result = customResolver.resolveConflict(
          localUpdatedAt: localUpdatedAt,
          serverUpdatedAt: serverUpdatedAt,
          hasDataDifferences: true,
        );

        expect(result, ConflictResolution.requireManual);
      });
    });

    group('detectFeedingEventConflict', () {
      test('detects local wins scenario', () {
        final localEvent = {
          'id': 'event_1',
          'fish_id': 'fish_1',
          'amount': 5.0,
          'updated_at': '2024-01-15T12:00:00Z',
        };
        final serverEvent = {
          'id': 'event_1',
          'fish_id': 'fish_1',
          'amount': 3.0,
          'updated_at': '2024-01-15T11:00:00Z',
        };

        final conflict = resolver.detectFeedingEventConflict(
          localEvent: localEvent,
          serverEvent: serverEvent,
          entityId: 'event_1',
        );

        expect(conflict.entityId, 'event_1');
        expect(conflict.entityType, 'feeding_event');
        expect(conflict.resolution, ConflictResolution.useLocal);
        expect(conflict.conflictFields, contains('amount'));
      });

      test('detects server wins scenario', () {
        final localEvent = {
          'id': 'event_1',
          'fish_id': 'fish_1',
          'amount': 5.0,
          'updated_at': '2024-01-15T11:00:00Z',
        };
        final serverEvent = {
          'id': 'event_1',
          'fish_id': 'fish_1',
          'amount': 3.0,
          'updated_at': '2024-01-15T12:00:00Z',
        };

        final conflict = resolver.detectFeedingEventConflict(
          localEvent: localEvent,
          serverEvent: serverEvent,
          entityId: 'event_1',
        );

        expect(conflict.resolution, ConflictResolution.useServer);
      });

      test('detects critical conflict when timestamps are close', () {
        final localEvent = {
          'id': 'event_1',
          'fish_id': 'fish_1',
          'amount': 5.0,
          'updated_at': '2024-01-15T12:00:03Z',
        };
        final serverEvent = {
          'id': 'event_1',
          'fish_id': 'fish_1',
          'amount': 3.0,
          'updated_at': '2024-01-15T12:00:00Z',
        };

        final conflict = resolver.detectFeedingEventConflict(
          localEvent: localEvent,
          serverEvent: serverEvent,
          entityId: 'event_1',
        );

        expect(conflict.resolution, ConflictResolution.requireManual);
        expect(conflict.requiresManualResolution, isTrue);
      });

      test('identifies differing fields correctly', () {
        final localEvent = {
          'id': 'event_1',
          'fish_id': 'fish_1',
          'amount': 5.0,
          'notes': 'Local notes',
          'food_type': 'flakes',
          'updated_at': '2024-01-15T12:00:00Z',
        };
        final serverEvent = {
          'id': 'event_1',
          'fish_id': 'fish_1',
          'amount': 3.0,
          'notes': 'Server notes',
          'food_type': 'flakes',
          'updated_at': '2024-01-15T11:00:00Z',
        };

        final conflict = resolver.detectFeedingEventConflict(
          localEvent: localEvent,
          serverEvent: serverEvent,
          entityId: 'event_1',
        );

        expect(conflict.conflictFields, contains('amount'));
        expect(conflict.conflictFields, contains('notes'));
        expect(conflict.conflictFields, isNot(contains('food_type')));
      });

      test('ignores metadata fields when comparing', () {
        final localEvent = {
          'id': 'event_1',
          'fish_id': 'fish_1',
          'amount': 5.0,
          'updated_at': '2024-01-15T12:00:00Z',
          'synced': false,
          'conflict_status': 0,
        };
        final serverEvent = {
          'id': 'event_1',
          'fish_id': 'fish_1',
          'amount': 5.0,
          'updated_at': '2024-01-15T11:00:00Z',
          'synced': true,
          'conflict_status': 1,
        };

        final conflict = resolver.detectFeedingEventConflict(
          localEvent: localEvent,
          serverEvent: serverEvent,
          entityId: 'event_1',
        );

        // Should not detect differences in metadata fields
        expect(conflict.conflictFields, isEmpty);
        expect(conflict.resolution, ConflictResolution.useLocal);
      });

      test('uses created_at as fallback when updated_at is missing', () {
        final localEvent = {
          'id': 'event_1',
          'fish_id': 'fish_1',
          'amount': 5.0,
          'created_at': '2024-01-15T12:00:00Z',
        };
        final serverEvent = {
          'id': 'event_1',
          'fish_id': 'fish_1',
          'amount': 3.0,
          'created_at': '2024-01-15T11:00:00Z',
        };

        final conflict = resolver.detectFeedingEventConflict(
          localEvent: localEvent,
          serverEvent: serverEvent,
          entityId: 'event_1',
        );

        expect(conflict.resolution, ConflictResolution.useLocal);
      });
    });

    group('SyncConflict', () {
      test('calculates time difference correctly', () {
        final conflict = SyncConflict<Map<String, dynamic>>(
          entityId: 'event_1',
          entityType: 'feeding_event',
          localVersion: {},
          serverVersion: {},
          localUpdatedAt: DateTime(2024, 1, 15, 12, 0, 30),
          serverUpdatedAt: DateTime(2024, 1, 15, 12, 0, 0),
          resolution: ConflictResolution.useLocal,
        );

        expect(conflict.timeDifference, const Duration(seconds: 30));
      });

      test('requiresManualResolution returns correct value', () {
        final manualConflict = SyncConflict<Map<String, dynamic>>(
          entityId: 'event_1',
          entityType: 'feeding_event',
          localVersion: {},
          serverVersion: {},
          localUpdatedAt: DateTime.now(),
          serverUpdatedAt: DateTime.now(),
          resolution: ConflictResolution.requireManual,
        );

        final autoConflict = SyncConflict<Map<String, dynamic>>(
          entityId: 'event_2',
          entityType: 'feeding_event',
          localVersion: {},
          serverVersion: {},
          localUpdatedAt: DateTime.now(),
          serverUpdatedAt: DateTime.now(),
          resolution: ConflictResolution.useLocal,
        );

        expect(manualConflict.requiresManualResolution, isTrue);
        expect(autoConflict.requiresManualResolution, isFalse);
      });

      test('stores conflict fields correctly', () {
        final conflict = SyncConflict<Map<String, dynamic>>(
          entityId: 'event_1',
          entityType: 'feeding_event',
          localVersion: {'amount': 5.0},
          serverVersion: {'amount': 3.0},
          localUpdatedAt: DateTime.now(),
          serverUpdatedAt: DateTime.now(),
          resolution: ConflictResolution.useLocal,
          conflictFields: ['amount', 'notes'],
        );

        expect(conflict.conflictFields, ['amount', 'notes']);
      });
    });

    group('ConflictStatus', () {
      test('has correct enum values', () {
        expect(ConflictStatus.values.length, 3);
        expect(ConflictStatus.none.index, 0);
        expect(ConflictStatus.pending.index, 1);
        expect(ConflictStatus.resolved.index, 2);
      });
    });

    group('ConflictResolution', () {
      test('has correct enum values', () {
        expect(ConflictResolution.values.length, 3);
        expect(ConflictResolution.useLocal.index, 0);
        expect(ConflictResolution.useServer.index, 1);
        expect(ConflictResolution.requireManual.index, 2);
      });
    });
  });
}
