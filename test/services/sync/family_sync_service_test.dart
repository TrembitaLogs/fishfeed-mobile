import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/services/notifications/notification_service.dart';
import 'package:fishfeed/services/sync/family_sync_service.dart';

class MockConnectivity extends Mock implements Connectivity {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockConnectivity mockConnectivity;
  late MockNotificationService mockNotificationService;
  late StreamController<List<ConnectivityResult>> connectivityController;
  late List<FeedingEvent> fetchedEvents;
  late List<FeedingEvent> receivedFeedingEvents;
  late List<String> shownToasts;

  FeedingEvent createTestEvent({
    String id = 'event_1',
    String completedBy = 'user_2',
    String? completedByName = 'John',
    String? completedByAvatar,
    DateTime? feedingTime,
    String aquariumId = 'aq1',
  }) {
    return FeedingEvent(
      id: id,
      aquariumId: aquariumId,
      feedingTime: feedingTime ?? DateTime.now(),
      completedBy: completedBy,
      completedByName: completedByName,
      completedByAvatar: completedByAvatar,
    );
  }

  setUp(() {
    mockConnectivity = MockConnectivity();
    mockNotificationService = MockNotificationService();
    connectivityController = StreamController<List<ConnectivityResult>>();
    fetchedEvents = [];
    receivedFeedingEvents = [];
    shownToasts = [];

    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => connectivityController.stream);
    when(
      () => mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(
      () => mockNotificationService.cancelScheduledNotification(any()),
    ).thenAnswer((_) async {});
  });

  tearDown(() {
    connectivityController.close();
  });

  FamilySyncService createService({
    String currentUserId = 'user_1',
    FamilySyncConfig config = const FamilySyncConfig(
      pollingInterval: Duration(milliseconds: 100),
      maxRetries: 3,
      retryDelay: Duration(milliseconds: 50),
    ),
  }) {
    return FamilySyncService(
      currentUserId: currentUserId,
      fetchRemoteFeedings: ({required aquariumId, required since}) async {
        return fetchedEvents;
      },
      onFamilyFeeding: (event) async {
        receivedFeedingEvents.add(event);
      },
      showToast: (message) {
        shownToasts.add(message);
      },
      config: config,
      connectivity: mockConnectivity,
      notificationService: mockNotificationService,
    );
  }

  group('FamilySyncService initialization', () {
    test('should start with correct default state', () {
      final service = createService();

      expect(service.isPolling, isFalse);
      expect(service.isOnline, isTrue);
      expect(service.activeAquariumId, isNull);

      service.dispose();
    });

    test('should check connectivity on initialize', () async {
      final service = createService();
      service.initialize();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => mockConnectivity.checkConnectivity()).called(1);

      service.dispose();
    });
  });

  group('Polling control', () {
    test('startPolling should set active aquarium and start polling', () async {
      final service = createService();
      service.initialize();

      service.startPolling(aquariumId: 'aq1');

      expect(service.isPolling, isTrue);
      expect(service.activeAquariumId, 'aq1');

      service.dispose();
    });

    test('stopPolling should stop polling and clear aquarium', () async {
      final service = createService();
      service.initialize();
      service.startPolling(aquariumId: 'aq1');

      service.stopPolling();

      expect(service.isPolling, isFalse);
      expect(service.activeAquariumId, isNull);

      service.dispose();
    });

    test('should not start duplicate polling for same aquarium', () async {
      final service = createService();
      service.initialize();

      service.startPolling(aquariumId: 'aq1');
      service.startPolling(aquariumId: 'aq1');

      expect(service.isPolling, isTrue);
      expect(service.activeAquariumId, 'aq1');

      service.dispose();
    });

    test(
      'should switch aquarium when starting polling for different aquarium',
      () async {
        final service = createService();
        service.initialize();

        service.startPolling(aquariumId: 'aq1');
        expect(service.activeAquariumId, 'aq1');

        service.startPolling(aquariumId: 'aq2');
        expect(service.activeAquariumId, 'aq2');

        service.dispose();
      },
    );
  });

  group('Event processing', () {
    test('should process family member feeding events', () async {
      final event = createTestEvent(completedBy: 'user_2');
      fetchedEvents = [event];

      final service = createService(currentUserId: 'user_1');
      service.initialize();
      service.startPolling(aquariumId: 'aq1');

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(receivedFeedingEvents, contains(event));
      expect(shownToasts.length, greaterThan(0));
      expect(shownToasts.first, contains('John'));

      service.dispose();
    });

    test('should skip own feeding events', () async {
      final ownEvent = createTestEvent(completedBy: 'user_1');
      fetchedEvents = [ownEvent];

      final service = createService(currentUserId: 'user_1');
      service.initialize();
      service.startPolling(aquariumId: 'aq1');

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(receivedFeedingEvents, isEmpty);
      expect(shownToasts, isEmpty);

      service.dispose();
    });

    test('should not process same event twice', () async {
      final event = createTestEvent(id: 'event_1', completedBy: 'user_2');
      fetchedEvents = [event];

      final service = createService(currentUserId: 'user_1');
      service.initialize();
      service.startPolling(aquariumId: 'aq1');

      // Wait for two polling cycles
      await Future<void>.delayed(const Duration(milliseconds: 250));

      // Event should only be processed once
      expect(receivedFeedingEvents.length, 1);

      service.dispose();
    });

    test('should cancel notification when family member feeds', () async {
      final event = createTestEvent(
        id: 'event_1',
        completedBy: 'user_2',
        completedByName: 'John',
      );
      fetchedEvents = [event];

      final service = createService(currentUserId: 'user_1');
      service.initialize();
      service.startPolling(aquariumId: 'aq1');

      await Future<void>.delayed(const Duration(milliseconds: 150));

      verify(
        () => mockNotificationService.cancelScheduledNotification(any()),
      ).called(greaterThan(0));

      service.dispose();
    });

    test('should emit events on familyFeedingEvents stream', () async {
      final event = createTestEvent(completedBy: 'user_2');
      fetchedEvents = [event];

      final service = createService(currentUserId: 'user_1');
      service.initialize();

      final receivedStreamEvents = <FamilyFeedingEvent>[];
      service.familyFeedingEvents.listen(receivedStreamEvents.add);

      service.startPolling(aquariumId: 'aq1');

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(receivedStreamEvents.length, 1);
      expect(receivedStreamEvents.first.event, event);

      service.dispose();
    });
  });

  group('Connectivity handling', () {
    test('should pause polling when going offline', () async {
      final service = createService();
      service.initialize();
      service.startPolling(aquariumId: 'aq1');

      expect(service.isPolling, isTrue);

      // Simulate going offline
      connectivityController.add([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(service.isOnline, isFalse);
      expect(service.isPolling, isFalse);

      service.dispose();
    });

    test('should resume polling when coming back online', () async {
      // Start offline
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      final service = createService();
      service.initialize();
      service.startPolling(aquariumId: 'aq1');

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(service.isOnline, isFalse);

      // Come back online
      connectivityController.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(service.isOnline, isTrue);
      expect(service.isPolling, isTrue);

      service.dispose();
    });
  });

  group('Error handling', () {
    test('should retry on fetch failure', () async {
      var fetchCallCount = 0;

      final service = FamilySyncService(
        currentUserId: 'user_1',
        fetchRemoteFeedings: ({required aquariumId, required since}) async {
          fetchCallCount++;
          if (fetchCallCount < 3) {
            throw Exception('Network error');
          }
          return [];
        },
        onFamilyFeeding: (event) async {},
        showToast: (message) {},
        config: const FamilySyncConfig(
          pollingInterval: Duration(milliseconds: 50),
          maxRetries: 3,
          retryDelay: Duration(milliseconds: 10),
        ),
        connectivity: mockConnectivity,
        notificationService: mockNotificationService,
      );

      service.initialize();
      service.startPolling(aquariumId: 'aq1');

      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(fetchCallCount, greaterThanOrEqualTo(3));

      service.dispose();
    });

    test('should pause polling after max retries', () async {
      var failureCount = 0;

      final service = FamilySyncService(
        currentUserId: 'user_1',
        fetchRemoteFeedings: ({required aquariumId, required since}) async {
          failureCount++;
          throw Exception('Persistent error');
        },
        onFamilyFeeding: (event) async {},
        showToast: (message) {},
        config: const FamilySyncConfig(
          pollingInterval: Duration(milliseconds: 50),
          maxRetries: 2,
          retryDelay: Duration(
            seconds: 10,
          ), // Long delay so we can check paused state
        ),
        connectivity: mockConnectivity,
        notificationService: mockNotificationService,
      );

      service.initialize();
      service.startPolling(aquariumId: 'aq1');

      // Wait for failures to accumulate (2 retries = 2 failures)
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // After max retries, polling should be paused (isPolling = false)
      // but activeAquariumId is still set (will resume after retryDelay)
      expect(failureCount, greaterThanOrEqualTo(2));
      expect(service.activeAquariumId, 'aq1');

      service.dispose();
    });
  });

  group('Conflict resolution', () {
    test('resolveConflict should return earliest event', () {
      final service = createService();

      final event1 = createTestEvent(
        id: 'e1',
        feedingTime: DateTime(2025, 6, 15, 10, 0),
      );
      final event2 = createTestEvent(
        id: 'e2',
        feedingTime: DateTime(2025, 6, 15, 10, 5),
      );

      final winner = service.resolveConflict([event2, event1]);

      expect(winner?.id, 'e1');

      service.dispose();
    });

    test('resolveConflict should return null for empty list', () {
      final service = createService();

      final winner = service.resolveConflict([]);

      expect(winner, isNull);

      service.dispose();
    });

    test('resolveConflict should return single event for list of one', () {
      final service = createService();
      final event = createTestEvent();

      final winner = service.resolveConflict([event]);

      expect(winner, event);

      service.dispose();
    });

    test('hasConflict should detect overlapping feedings', () {
      final service = createService();

      final newEvent = createTestEvent(
        feedingTime: DateTime(2025, 6, 15, 10, 2),
      );
      final existingEvent = createTestEvent(
        feedingTime: DateTime(2025, 6, 15, 10, 0),
      );

      final hasConflict = service.hasConflict(newEvent, [
        existingEvent,
      ], conflictWindow: const Duration(minutes: 5));

      expect(hasConflict, isTrue);

      service.dispose();
    });

    test('hasConflict should not detect non-overlapping feedings', () {
      final service = createService();

      final newEvent = createTestEvent(
        feedingTime: DateTime(2025, 6, 15, 10, 10),
      );
      final existingEvent = createTestEvent(
        feedingTime: DateTime(2025, 6, 15, 10, 0),
      );

      final hasConflict = service.hasConflict(newEvent, [
        existingEvent,
      ], conflictWindow: const Duration(minutes: 5));

      expect(hasConflict, isFalse);

      service.dispose();
    });
  });

  group('Manual sync', () {
    test('syncNow should trigger immediate fetch', () async {
      var fetchCalled = false;

      final service = FamilySyncService(
        currentUserId: 'user_1',
        fetchRemoteFeedings: ({required aquariumId, required since}) async {
          fetchCalled = true;
          return [];
        },
        onFamilyFeeding: (event) async {},
        showToast: (message) {},
        connectivity: mockConnectivity,
        notificationService: mockNotificationService,
      );

      service.initialize();
      service.startPolling(aquariumId: 'aq1');
      fetchCalled = false; // Reset after initial fetch

      await service.syncNow();

      expect(fetchCalled, isTrue);

      service.dispose();
    });

    test('clearCache should reset processed events', () async {
      final event = createTestEvent(completedBy: 'user_2');
      fetchedEvents = [event];

      final service = createService(currentUserId: 'user_1');
      service.initialize();
      service.startPolling(aquariumId: 'aq1');

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(receivedFeedingEvents.length, 1);

      // Clear cache
      service.clearCache();
      receivedFeedingEvents.clear();

      // Same event should be processed again
      await service.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(receivedFeedingEvents.length, 1);

      service.dispose();
    });
  });

  group('Toast messages', () {
    test('should show toast with user name', () async {
      final event = createTestEvent(
        completedBy: 'user_2',
        completedByName: 'Jane',
      );
      fetchedEvents = [event];

      final service = createService(currentUserId: 'user_1');
      service.initialize();
      service.startPolling(aquariumId: 'aq1');

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(shownToasts, isNotEmpty);
      expect(shownToasts.first, contains('Jane'));

      service.dispose();
    });

    test('should show generic toast when no user name', () async {
      final event = createTestEvent(
        completedBy: 'user_2',
        completedByName: null,
      );
      fetchedEvents = [event];

      final service = createService(currentUserId: 'user_1');
      service.initialize();
      service.startPolling(aquariumId: 'aq1');

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(shownToasts, isNotEmpty);
      expect(shownToasts.first, contains('Family member'));

      service.dispose();
    });
  });

  group('Lifecycle', () {
    test('dispose should cleanup resources', () async {
      final service = createService();
      service.initialize();
      service.startPolling(aquariumId: 'aq1');

      service.dispose();

      expect(service.isPolling, isFalse);
    });
  });
}
