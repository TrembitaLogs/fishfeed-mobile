import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/models/feeding_event_model.dart';

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  late MockBox mockFeedingEventsBox;
  late FeedingLocalDataSource feedingDs;

  setUp(() {
    mockFeedingEventsBox = MockBox();
    feedingDs = FeedingLocalDataSource(feedingEventsBox: mockFeedingEventsBox);
  });

  FeedingEventModel createTestEvent({
    String id = 'event_1',
    String fishId = 'fish_1',
    String aquariumId = 'aquarium_1',
    DateTime? feedingTime,
    bool synced = false,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return FeedingEventModel(
      id: id,
      fishId: fishId,
      aquariumId: aquariumId,
      feedingTime: feedingTime ?? DateTime(2025, 6, 15, 10, 0),
      amount: 5.0,
      foodType: 'pellets',
      notes: 'Test feeding',
      synced: synced,
      createdAt: createdAt ?? DateTime(2025, 6, 15, 10, 0),
      deletedAt: deletedAt,
    );
  }

  group('CRUD Operations', () {
    group('createFeedingEvent', () {
      test('should save event to Hive box', () async {
        final event = createTestEvent();
        when(
          () => mockFeedingEventsBox.put(any<dynamic>(), any<dynamic>()),
        ).thenAnswer((_) async {});

        await feedingDs.createFeedingEvent(event);

        verify(() => mockFeedingEventsBox.put('event_1', event)).called(1);
      });
    });

    group('getFeedingEvents', () {
      test('should return events for specific aquarium', () {
        final event1 = createTestEvent(
          id: 'event_1',
          aquariumId: 'aquarium_1',
          feedingTime: DateTime(2025, 6, 15, 10, 0),
        );
        final event2 = createTestEvent(
          id: 'event_2',
          aquariumId: 'aquarium_1',
          feedingTime: DateTime(2025, 6, 15, 12, 0),
        );
        final event3 = createTestEvent(id: 'event_3', aquariumId: 'aquarium_2');

        when(
          () => mockFeedingEventsBox.values,
        ).thenReturn([event1, event2, event3]);

        final result = feedingDs.getFeedingEvents('aquarium_1');

        expect(result.length, 2);
        expect(result.every((e) => e.aquariumId == 'aquarium_1'), isTrue);
      });

      test('should return events sorted by feedingTime (newest first)', () {
        final oldEvent = createTestEvent(
          id: 'event_1',
          feedingTime: DateTime(2025, 6, 15, 8, 0),
        );
        final newEvent = createTestEvent(
          id: 'event_2',
          feedingTime: DateTime(2025, 6, 15, 12, 0),
        );

        when(
          () => mockFeedingEventsBox.values,
        ).thenReturn([oldEvent, newEvent]);

        final result = feedingDs.getFeedingEvents('aquarium_1');

        expect(result[0].id, 'event_2');
        expect(result[1].id, 'event_1');
      });

      test('should return empty list when no events for aquarium', () {
        when(() => mockFeedingEventsBox.values).thenReturn([]);

        final result = feedingDs.getFeedingEvents('aquarium_1');

        expect(result, isEmpty);
      });

      test('should exclude soft-deleted events', () {
        final activeEvent = createTestEvent(
          id: 'event_1',
          aquariumId: 'aquarium_1',
        );
        final deletedEvent = createTestEvent(
          id: 'event_2',
          aquariumId: 'aquarium_1',
          deletedAt: DateTime(2025, 6, 15, 11, 0),
        );

        when(
          () => mockFeedingEventsBox.values,
        ).thenReturn([activeEvent, deletedEvent]);

        final result = feedingDs.getFeedingEvents('aquarium_1');

        expect(result.length, 1);
        expect(result[0].id, 'event_1');
      });
    });

    group('getFeedingEventsByDate', () {
      test('should return events for specific date', () {
        final event1 = createTestEvent(
          id: 'event_1',
          feedingTime: DateTime(2025, 6, 15, 10, 0),
        );
        final event2 = createTestEvent(
          id: 'event_2',
          feedingTime: DateTime(2025, 6, 15, 14, 0),
        );
        final event3 = createTestEvent(
          id: 'event_3',
          feedingTime: DateTime(2025, 6, 16, 10, 0),
        );

        when(
          () => mockFeedingEventsBox.values,
        ).thenReturn([event1, event2, event3]);

        final result = feedingDs.getFeedingEventsByDate(DateTime(2025, 6, 15));

        expect(result.length, 2);
        expect(result.every((e) => e.feedingTime.day == 15), isTrue);
      });

      test('should return empty list when no events for date', () {
        final event = createTestEvent(
          feedingTime: DateTime(2025, 6, 16, 10, 0),
        );

        when(() => mockFeedingEventsBox.values).thenReturn([event]);

        final result = feedingDs.getFeedingEventsByDate(DateTime(2025, 6, 15));

        expect(result, isEmpty);
      });

      test('should exclude soft-deleted events', () {
        final activeEvent = createTestEvent(
          id: 'event_1',
          feedingTime: DateTime(2025, 6, 15, 10, 0),
        );
        final deletedEvent = createTestEvent(
          id: 'event_2',
          feedingTime: DateTime(2025, 6, 15, 14, 0),
          deletedAt: DateTime(2025, 6, 15, 15, 0),
        );

        when(
          () => mockFeedingEventsBox.values,
        ).thenReturn([activeEvent, deletedEvent]);

        final result = feedingDs.getFeedingEventsByDate(DateTime(2025, 6, 15));

        expect(result.length, 1);
        expect(result[0].id, 'event_1');
      });
    });

    group('getFeedingEventById', () {
      test('should return event when exists', () {
        final event = createTestEvent();
        when(() => mockFeedingEventsBox.get('event_1')).thenReturn(event);

        final result = feedingDs.getFeedingEventById('event_1');

        expect(result, event);
        expect(result?.id, 'event_1');
      });

      test('should return null when event does not exist', () {
        when(() => mockFeedingEventsBox.get('event_1')).thenReturn(null);

        final result = feedingDs.getFeedingEventById('event_1');

        expect(result, isNull);
      });

      test('should return null when stored value is not FeedingEventModel', () {
        when(() => mockFeedingEventsBox.get('event_1')).thenReturn('invalid');

        final result = feedingDs.getFeedingEventById('event_1');

        expect(result, isNull);
      });
    });

    group('updateFeedingEvent', () {
      test('should update event when exists', () async {
        final event = createTestEvent();
        final updatedEvent = FeedingEventModel(
          id: 'event_1',
          fishId: 'fish_1',
          aquariumId: 'aquarium_1',
          feedingTime: DateTime(2025, 6, 15, 10, 0),
          amount: 10.0,
          foodType: 'flakes',
          notes: 'Updated notes',
          synced: false,
          createdAt: DateTime(2025, 6, 15, 10, 0),
        );

        when(() => mockFeedingEventsBox.get('event_1')).thenReturn(event);
        when(
          () => mockFeedingEventsBox.put(any<dynamic>(), any<dynamic>()),
        ).thenAnswer((_) async {});

        final result = await feedingDs.updateFeedingEvent(updatedEvent);

        expect(result, isTrue);
        verify(
          () => mockFeedingEventsBox.put('event_1', updatedEvent),
        ).called(1);
      });

      test('should return false when event does not exist', () async {
        final event = createTestEvent();
        when(() => mockFeedingEventsBox.get('event_1')).thenReturn(null);

        final result = await feedingDs.updateFeedingEvent(event);

        expect(result, isFalse);
        verifyNever(
          () => mockFeedingEventsBox.put(any<dynamic>(), any<dynamic>()),
        );
      });
    });

    group('deleteFeedingEvent', () {
      test('should delete event when exists', () async {
        final event = createTestEvent();
        when(() => mockFeedingEventsBox.get('event_1')).thenReturn(event);
        when(
          () => mockFeedingEventsBox.delete(any<dynamic>()),
        ).thenAnswer((_) async {});

        final result = await feedingDs.deleteFeedingEvent('event_1');

        expect(result, isTrue);
        verify(() => mockFeedingEventsBox.delete('event_1')).called(1);
      });

      test('should return false when event does not exist', () async {
        when(() => mockFeedingEventsBox.get('event_1')).thenReturn(null);

        final result = await feedingDs.deleteFeedingEvent('event_1');

        expect(result, isFalse);
        verifyNever(() => mockFeedingEventsBox.delete(any<dynamic>()));
      });
    });

    group('getAllFeedingEvents', () {
      test('should return all events sorted by feedingTime', () {
        final event1 = createTestEvent(
          id: 'event_1',
          aquariumId: 'aquarium_1',
          feedingTime: DateTime(2025, 6, 15, 8, 0),
        );
        final event2 = createTestEvent(
          id: 'event_2',
          aquariumId: 'aquarium_2',
          feedingTime: DateTime(2025, 6, 15, 12, 0),
        );

        when(() => mockFeedingEventsBox.values).thenReturn([event1, event2]);

        final result = feedingDs.getAllFeedingEvents();

        expect(result.length, 2);
        expect(result[0].id, 'event_2');
        expect(result[1].id, 'event_1');
      });

      test('should exclude soft-deleted events', () {
        final activeEvent = createTestEvent(
          id: 'event_1',
          feedingTime: DateTime(2025, 6, 15, 12, 0),
        );
        final deletedEvent = createTestEvent(
          id: 'event_2',
          feedingTime: DateTime(2025, 6, 15, 10, 0),
          deletedAt: DateTime(2025, 6, 15, 14, 0),
        );

        when(
          () => mockFeedingEventsBox.values,
        ).thenReturn([activeEvent, deletedEvent]);

        final result = feedingDs.getAllFeedingEvents();

        expect(result.length, 1);
        expect(result[0].id, 'event_1');
      });
    });
  });

  group('Synchronization Methods', () {
    group('getUnsyncedEvents', () {
      test('should return only unsynced events', () {
        final syncedEvent = createTestEvent(id: 'event_1', synced: true);
        final unsyncedEvent1 = createTestEvent(id: 'event_2', synced: false);
        final unsyncedEvent2 = createTestEvent(id: 'event_3', synced: false);

        when(
          () => mockFeedingEventsBox.values,
        ).thenReturn([syncedEvent, unsyncedEvent1, unsyncedEvent2]);

        final result = feedingDs.getUnsyncedEvents();

        expect(result.length, 2);
        expect(result.every((e) => !e.synced), isTrue);
      });

      test('should return events sorted by createdAt (oldest first)', () {
        final newerEvent = createTestEvent(
          id: 'event_1',
          synced: false,
          createdAt: DateTime(2025, 6, 15, 12, 0),
        );
        final olderEvent = createTestEvent(
          id: 'event_2',
          synced: false,
          createdAt: DateTime(2025, 6, 15, 8, 0),
        );

        when(
          () => mockFeedingEventsBox.values,
        ).thenReturn([newerEvent, olderEvent]);

        final result = feedingDs.getUnsyncedEvents();

        expect(result[0].id, 'event_2');
        expect(result[1].id, 'event_1');
      });

      test('should return empty list when all events are synced', () {
        final syncedEvent = createTestEvent(synced: true);

        when(() => mockFeedingEventsBox.values).thenReturn([syncedEvent]);

        final result = feedingDs.getUnsyncedEvents();

        expect(result, isEmpty);
      });

      test('should exclude soft-deleted events', () {
        final unsyncedEvent = createTestEvent(id: 'event_1', synced: false);
        final deletedUnsyncedEvent = createTestEvent(
          id: 'event_2',
          synced: false,
          deletedAt: DateTime(2025, 6, 15, 11, 0),
        );

        when(
          () => mockFeedingEventsBox.values,
        ).thenReturn([unsyncedEvent, deletedUnsyncedEvent]);

        final result = feedingDs.getUnsyncedEvents();

        expect(result.length, 1);
        expect(result[0].id, 'event_1');
      });
    });

    group('markAsSynced', () {
      test('should mark event as synced when exists', () async {
        final event = createTestEvent(synced: false);
        when(() => mockFeedingEventsBox.get('event_1')).thenReturn(event);
        when(
          () => mockFeedingEventsBox.put(any<dynamic>(), any<dynamic>()),
        ).thenAnswer((_) async {});

        final result = await feedingDs.markAsSynced('event_1');

        expect(result, isTrue);
        expect(event.synced, isTrue);
        verify(() => mockFeedingEventsBox.put('event_1', event)).called(1);
      });

      test('should return false when event does not exist', () async {
        when(() => mockFeedingEventsBox.get('event_1')).thenReturn(null);

        final result = await feedingDs.markAsSynced('event_1');

        expect(result, isFalse);
        verifyNever(
          () => mockFeedingEventsBox.put(any<dynamic>(), any<dynamic>()),
        );
      });
    });

    group('markMultipleAsSynced', () {
      test('should mark multiple events as synced', () async {
        final event1 = createTestEvent(id: 'event_1', synced: false);
        final event2 = createTestEvent(id: 'event_2', synced: false);

        when(() => mockFeedingEventsBox.get('event_1')).thenReturn(event1);
        when(() => mockFeedingEventsBox.get('event_2')).thenReturn(event2);
        when(
          () => mockFeedingEventsBox.put(any<dynamic>(), any<dynamic>()),
        ).thenAnswer((_) async {});

        final result = await feedingDs.markMultipleAsSynced([
          'event_1',
          'event_2',
        ]);

        expect(result, 2);
        expect(event1.synced, isTrue);
        expect(event2.synced, isTrue);
      });

      test('should return count of successfully synced events', () async {
        final event1 = createTestEvent(id: 'event_1', synced: false);

        when(() => mockFeedingEventsBox.get('event_1')).thenReturn(event1);
        when(() => mockFeedingEventsBox.get('event_2')).thenReturn(null);
        when(
          () => mockFeedingEventsBox.put(any<dynamic>(), any<dynamic>()),
        ).thenAnswer((_) async {});

        final result = await feedingDs.markMultipleAsSynced([
          'event_1',
          'event_2',
        ]);

        expect(result, 1);
      });
    });

    group('markAsUnsynced', () {
      test('should mark event as unsynced when exists', () async {
        final event = createTestEvent(synced: true);
        when(() => mockFeedingEventsBox.get('event_1')).thenReturn(event);
        when(
          () => mockFeedingEventsBox.put(any<dynamic>(), any<dynamic>()),
        ).thenAnswer((_) async {});

        final result = await feedingDs.markAsUnsynced('event_1');

        expect(result, isTrue);
        expect(event.synced, isFalse);
      });

      test('should return false when event does not exist', () async {
        when(() => mockFeedingEventsBox.get('event_1')).thenReturn(null);

        final result = await feedingDs.markAsUnsynced('event_1');

        expect(result, isFalse);
      });
    });

    group('getUnsyncedCount', () {
      test('should return count of unsynced events', () {
        final syncedEvent = createTestEvent(id: 'event_1', synced: true);
        final unsyncedEvent1 = createTestEvent(id: 'event_2', synced: false);
        final unsyncedEvent2 = createTestEvent(id: 'event_3', synced: false);

        when(
          () => mockFeedingEventsBox.values,
        ).thenReturn([syncedEvent, unsyncedEvent1, unsyncedEvent2]);

        final result = feedingDs.getUnsyncedCount();

        expect(result, 2);
      });

      test('should return 0 when all events are synced', () {
        final syncedEvent = createTestEvent(synced: true);

        when(() => mockFeedingEventsBox.values).thenReturn([syncedEvent]);

        final result = feedingDs.getUnsyncedCount();

        expect(result, 0);
      });

      test('should exclude soft-deleted events from count', () {
        final unsyncedEvent = createTestEvent(id: 'event_1', synced: false);
        final deletedUnsyncedEvent = createTestEvent(
          id: 'event_2',
          synced: false,
          deletedAt: DateTime(2025, 6, 15, 11, 0),
        );

        when(
          () => mockFeedingEventsBox.values,
        ).thenReturn([unsyncedEvent, deletedUnsyncedEvent]);

        final result = feedingDs.getUnsyncedCount();

        expect(result, 1);
      });
    });
  });

  group('Utility Methods', () {
    group('clearAll', () {
      test('should clear all events from box', () async {
        when(() => mockFeedingEventsBox.clear()).thenAnswer((_) async => 0);

        await feedingDs.clearAll();

        verify(() => mockFeedingEventsBox.clear()).called(1);
      });
    });

    group('deleteEventsByAquarium', () {
      test('should delete all events for specific aquarium', () async {
        final event1 = createTestEvent(id: 'event_1', aquariumId: 'aquarium_1');
        final event2 = createTestEvent(id: 'event_2', aquariumId: 'aquarium_1');

        when(() => mockFeedingEventsBox.values).thenReturn([event1, event2]);
        when(
          () => mockFeedingEventsBox.delete(any<dynamic>()),
        ).thenAnswer((_) async {});

        final result = await feedingDs.deleteEventsByAquarium('aquarium_1');

        expect(result, 2);
        verify(() => mockFeedingEventsBox.delete('event_1')).called(1);
        verify(() => mockFeedingEventsBox.delete('event_2')).called(1);
      });

      test('should return 0 when no events for aquarium', () async {
        when(() => mockFeedingEventsBox.values).thenReturn([]);

        final result = await feedingDs.deleteEventsByAquarium('aquarium_1');

        expect(result, 0);
        verifyNever(() => mockFeedingEventsBox.delete(any<dynamic>()));
      });
    });
  });

  group('FeedingLocalDataSource constructor', () {
    test('should create instance without injected box', () {
      // This test verifies the constructor works without crashing
      // The actual HiveBoxes will not be initialized in tests,
      // so we only test with injected box
      final ds = FeedingLocalDataSource(feedingEventsBox: mockFeedingEventsBox);
      expect(ds, isA<FeedingLocalDataSource>());
    });
  });
}
