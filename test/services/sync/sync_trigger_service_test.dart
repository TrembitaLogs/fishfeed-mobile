import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/services/connectivity/connectivity_service.dart';
import 'package:fishfeed/services/lifecycle/app_lifecycle_service.dart';
import 'package:fishfeed/services/sync/sync_service.dart';
import 'package:fishfeed/services/sync/sync_trigger_service.dart';

class MockSyncService extends Mock implements SyncService {}

class MockAppLifecycleService extends Mock implements AppLifecycleService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockSyncService mockSyncService;
  late MockAppLifecycleService mockLifecycleService;
  late MockConnectivityService mockConnectivityService;
  late StreamController<LifecycleEventData> lifecycleController;
  late StreamController<bool> connectivityController;
  late SyncTriggerService triggerService;

  setUp(() {
    mockSyncService = MockSyncService();
    mockLifecycleService = MockAppLifecycleService();
    mockConnectivityService = MockConnectivityService();
    lifecycleController = StreamController<LifecycleEventData>.broadcast();
    connectivityController = StreamController<bool>.broadcast();

    when(() => mockLifecycleService.eventStream)
        .thenAnswer((_) => lifecycleController.stream);
    when(() => mockConnectivityService.statusStream)
        .thenAnswer((_) => connectivityController.stream);
    when(() => mockConnectivityService.isOnline).thenReturn(true);
    when(() => mockSyncService.hasUnsyncedFeedings).thenReturn(true);
    when(() => mockSyncService.hasPendingOperations).thenReturn(false);
    when(() => mockSyncService.syncAll()).thenAnswer((_) async => 5);
    when(() => mockSyncService.syncNow()).thenAnswer((_) async => 5);
  });

  tearDown(() {
    lifecycleController.close();
    connectivityController.close();
  });

  SyncTriggerService createTriggerService({
    SyncTriggerConfig config = const SyncTriggerConfig(),
  }) {
    return SyncTriggerService(
      syncService: mockSyncService,
      lifecycleService: mockLifecycleService,
      connectivityService: mockConnectivityService,
      config: config,
    );
  }

  LifecycleEventData createResumedEvent() {
    return LifecycleEventData(
      event: AppLifecycleEvent.resumed,
      timestamp: DateTime.now(),
    );
  }

  LifecycleEventData createPausedEvent() {
    return LifecycleEventData(
      event: AppLifecycleEvent.paused,
      timestamp: DateTime.now(),
    );
  }

  group('SyncTriggerConfig', () {
    test('should have correct default values', () {
      const config = SyncTriggerConfig();

      expect(config.resumeDebounce, const Duration(seconds: 5));
      expect(config.cooldownPeriod, const Duration(seconds: 30));
    });

    test('should accept custom values', () {
      const config = SyncTriggerConfig(
        resumeDebounce: Duration(seconds: 10),
        cooldownPeriod: Duration(seconds: 60),
      );

      expect(config.resumeDebounce, const Duration(seconds: 10));
      expect(config.cooldownPeriod, const Duration(seconds: 60));
    });
  });

  group('Initialization', () {
    test('should not be initialized before initialize() is called', () {
      triggerService = createTriggerService();

      expect(triggerService.isInitialized, isFalse);
    });

    test('should be initialized after initialize() is called', () {
      triggerService = createTriggerService();
      triggerService.initialize();

      expect(triggerService.isInitialized, isTrue);
    });

    test('should not re-initialize if already initialized', () {
      triggerService = createTriggerService();
      triggerService.initialize();
      triggerService.initialize();

      expect(triggerService.isInitialized, isTrue);
      // Stream should only be listened to once
      verify(() => mockLifecycleService.eventStream).called(1);
    });

    test('should track offline state on initialization', () {
      when(() => mockConnectivityService.isOnline).thenReturn(false);

      triggerService = createTriggerService();
      triggerService.initialize();

      // Should have recorded initial offline state
      expect(triggerService.isInitialized, isTrue);
    });
  });

  group('Dispose', () {
    test('should clean up resources on dispose', () {
      triggerService = createTriggerService();
      triggerService.initialize();

      expect(triggerService.isInitialized, isTrue);

      triggerService.dispose();

      expect(triggerService.isInitialized, isFalse);
    });
  });

  group('App Resume Sync Trigger', () {
    test('should trigger debounced sync on app resume', () async {
      triggerService = createTriggerService(
        config: const SyncTriggerConfig(
          resumeDebounce: Duration(milliseconds: 50),
          cooldownPeriod: Duration(milliseconds: 10),
        ),
      );
      triggerService.initialize();

      lifecycleController.add(createResumedEvent());

      // Sync should not be called immediately
      verifyNever(() => mockSyncService.syncAll());

      // Wait for debounce
      await Future<void>.delayed(const Duration(milliseconds: 100));

      verify(() => mockSyncService.syncAll()).called(1);
    });

    test('should debounce multiple rapid resume events', () async {
      triggerService = createTriggerService(
        config: const SyncTriggerConfig(
          resumeDebounce: Duration(milliseconds: 100),
          cooldownPeriod: Duration(milliseconds: 10),
        ),
      );
      triggerService.initialize();

      // Simulate rapid app switching
      lifecycleController.add(createResumedEvent());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      lifecycleController.add(createResumedEvent());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      lifecycleController.add(createResumedEvent());

      // Wait for debounce to complete
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Should only sync once despite multiple resume events
      verify(() => mockSyncService.syncAll()).called(1);
    });

    test('should not trigger sync on paused event', () async {
      triggerService = createTriggerService(
        config: const SyncTriggerConfig(
          resumeDebounce: Duration(milliseconds: 10),
        ),
      );
      triggerService.initialize();

      lifecycleController.add(createPausedEvent());

      await Future<void>.delayed(const Duration(milliseconds: 50));

      verifyNever(() => mockSyncService.syncAll());
    });
  });

  group('Connectivity Sync Trigger', () {
    test('should trigger sync when connectivity is restored', () async {
      when(() => mockConnectivityService.isOnline).thenReturn(false);

      triggerService = createTriggerService(
        config: const SyncTriggerConfig(
          cooldownPeriod: Duration(milliseconds: 10),
        ),
      );
      triggerService.initialize();

      // Now go online
      when(() => mockConnectivityService.isOnline).thenReturn(true);
      connectivityController.add(true);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => mockSyncService.syncAll()).called(1);
    });

    test('should not trigger sync when going offline', () async {
      triggerService = createTriggerService();
      triggerService.initialize();

      // Go offline
      when(() => mockConnectivityService.isOnline).thenReturn(false);
      connectivityController.add(false);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      verifyNever(() => mockSyncService.syncAll());
    });

    test('should not trigger sync if already online', () async {
      // Start online
      when(() => mockConnectivityService.isOnline).thenReturn(true);

      triggerService = createTriggerService();
      triggerService.initialize();

      // Emit online (but we were already online)
      connectivityController.add(true);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      verifyNever(() => mockSyncService.syncAll());
    });
  });

  group('Cooldown Period', () {
    test('should skip sync during cooldown period', () async {
      triggerService = createTriggerService(
        config: const SyncTriggerConfig(
          resumeDebounce: Duration(milliseconds: 10),
          cooldownPeriod: Duration(milliseconds: 200),
        ),
      );
      triggerService.initialize();

      // First sync
      lifecycleController.add(createResumedEvent());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => mockSyncService.syncAll()).called(1);
      expect(triggerService.isInCooldown, isTrue);

      // Second sync should be skipped due to cooldown
      lifecycleController.add(createResumedEvent());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Should still be 1 call total
      verifyNever(() => mockSyncService.syncAll());
    });

    test('should allow sync after cooldown period expires', () async {
      triggerService = createTriggerService(
        config: const SyncTriggerConfig(
          resumeDebounce: Duration(milliseconds: 10),
          cooldownPeriod: Duration(milliseconds: 50),
        ),
      );
      triggerService.initialize();

      // First sync
      lifecycleController.add(createResumedEvent());
      await Future<void>.delayed(const Duration(milliseconds: 30));

      verify(() => mockSyncService.syncAll()).called(1);

      // Wait for cooldown to expire
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(triggerService.isInCooldown, isFalse);

      // Second sync should work
      lifecycleController.add(createResumedEvent());
      await Future<void>.delayed(const Duration(milliseconds: 30));

      verify(() => mockSyncService.syncAll()).called(1);
    });

    test('isInCooldown should return false when no sync has occurred', () {
      triggerService = createTriggerService();
      triggerService.initialize();

      expect(triggerService.isInCooldown, isFalse);
      expect(triggerService.lastAutoSyncTime, isNull);
    });

    test('remainingCooldown should return Duration.zero when not in cooldown', () {
      triggerService = createTriggerService();
      triggerService.initialize();

      expect(triggerService.remainingCooldown, Duration.zero);
    });

    test('resetCooldown should clear the cooldown', () async {
      triggerService = createTriggerService(
        config: const SyncTriggerConfig(
          resumeDebounce: Duration(milliseconds: 10),
          cooldownPeriod: Duration(seconds: 60),
        ),
      );
      triggerService.initialize();

      // Trigger sync to start cooldown
      lifecycleController.add(createResumedEvent());
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(triggerService.isInCooldown, isTrue);

      triggerService.resetCooldown();

      expect(triggerService.isInCooldown, isFalse);
      expect(triggerService.lastAutoSyncTime, isNull);
    });
  });

  group('Mutex (Concurrent Sync Prevention)', () {
    test('should prevent concurrent syncs via lifecycle trigger', () async {
      final completer = Completer<int>();
      when(() => mockSyncService.syncAll()).thenAnswer((_) => completer.future);

      triggerService = createTriggerService(
        config: const SyncTriggerConfig(
          resumeDebounce: Duration(milliseconds: 10),
          cooldownPeriod: Duration.zero,
        ),
      );
      triggerService.initialize();

      // Trigger first sync
      lifecycleController.add(createResumedEvent());
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(triggerService.isSyncing, isTrue);

      // Try to trigger second sync while first is in progress
      lifecycleController.add(createResumedEvent());
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Still only one call because second was skipped
      verify(() => mockSyncService.syncAll()).called(1);

      // Complete the first sync
      completer.complete(5);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(triggerService.isSyncing, isFalse);

      triggerService.dispose();
    });

    test('should prevent concurrent syncs via connectivity trigger', () async {
      when(() => mockConnectivityService.isOnline).thenReturn(false);

      final completer = Completer<int>();
      when(() => mockSyncService.syncAll()).thenAnswer((_) => completer.future);

      triggerService = createTriggerService(
        config: const SyncTriggerConfig(
          cooldownPeriod: Duration.zero,
        ),
      );
      triggerService.initialize();

      // Go online to trigger first sync
      when(() => mockConnectivityService.isOnline).thenReturn(true);
      connectivityController.add(true);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(triggerService.isSyncing, isTrue);

      // Try to trigger another sync via lifecycle while first is running
      lifecycleController.add(createResumedEvent());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Still only one call because second was skipped
      verify(() => mockSyncService.syncAll()).called(1);

      // Complete the first sync
      completer.complete(5);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      triggerService.dispose();
    });

    test('isSyncing should be false initially', () {
      triggerService = createTriggerService();
      triggerService.initialize();

      expect(triggerService.isSyncing, isFalse);

      triggerService.dispose();
    });
  });

  group('Offline Handling', () {
    test('should not trigger sync when offline', () async {
      when(() => mockConnectivityService.isOnline).thenReturn(false);

      triggerService = createTriggerService(
        config: const SyncTriggerConfig(
          resumeDebounce: Duration(milliseconds: 10),
        ),
      );
      triggerService.initialize();

      lifecycleController.add(createResumedEvent());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verifyNever(() => mockSyncService.syncAll());

      triggerService.dispose();
    });
  });

  group('Nothing to Sync', () {
    test('should still trigger sync on resume even with nothing to sync', () async {
      // Note: SyncTriggerService always syncs on app resume to fetch server updates,
      // regardless of local pending changes.
      when(() => mockSyncService.hasUnsyncedFeedings).thenReturn(false);
      when(() => mockSyncService.hasPendingOperations).thenReturn(false);

      triggerService = createTriggerService(
        config: const SyncTriggerConfig(
          resumeDebounce: Duration(milliseconds: 10),
        ),
      );
      triggerService.initialize();

      lifecycleController.add(createResumedEvent());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Sync is still triggered to fetch potential server updates
      verify(() => mockSyncService.syncAll()).called(1);

      triggerService.dispose();
    });
  });

  group('Manual Sync (syncNow)', () {
    test('should trigger sync immediately bypassing cooldown', () async {
      triggerService = createTriggerService(
        config: const SyncTriggerConfig(
          cooldownPeriod: Duration(seconds: 60),
        ),
      );
      triggerService.initialize();

      // Set up a previous sync time to activate cooldown
      // By calling syncNow first
      final firstResult = await triggerService.syncNow();

      expect(firstResult, 5);
      expect(triggerService.isInCooldown, isTrue);

      // syncNow should work despite cooldown
      final secondResult = await triggerService.syncNow();

      expect(secondResult, 5);
      verify(() => mockSyncService.syncNow()).called(2);

      triggerService.dispose();
    });

    test('should return 0 if already syncing', () async {
      final completer = Completer<int>();
      when(() => mockSyncService.syncNow()).thenAnswer((_) => completer.future);

      triggerService = createTriggerService();
      triggerService.initialize();

      // Start first sync
      final firstFuture = triggerService.syncNow();

      // Try second sync immediately
      final secondResult = await triggerService.syncNow();

      expect(secondResult, 0);

      // Complete first sync
      completer.complete(5);
      final firstResult = await firstFuture;

      expect(firstResult, 5);

      triggerService.dispose();
    });
  });

  group('Error Handling', () {
    test('should handle sync errors gracefully', () async {
      when(() => mockSyncService.syncAll()).thenThrow(Exception('Sync failed'));

      triggerService = createTriggerService(
        config: const SyncTriggerConfig(
          resumeDebounce: Duration(milliseconds: 10),
        ),
      );
      triggerService.initialize();

      lifecycleController.add(createResumedEvent());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Should not crash
      expect(triggerService.isSyncing, isFalse);

      triggerService.dispose();
    });

    test('should handle lifecycle stream errors gracefully', () {
      triggerService = createTriggerService();
      triggerService.initialize();

      // Send error to stream
      lifecycleController.addError(Exception('Stream error'));

      // Should not crash
      expect(triggerService.isInitialized, isTrue);

      triggerService.dispose();
    });

    test('should handle connectivity stream errors gracefully', () {
      triggerService = createTriggerService();
      triggerService.initialize();

      // Send error to stream
      connectivityController.addError(Exception('Stream error'));

      // Should not crash
      expect(triggerService.isInitialized, isTrue);

      triggerService.dispose();
    });
  });
}
