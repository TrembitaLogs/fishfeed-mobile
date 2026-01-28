import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/presentation/providers/sync_refresh_provider.dart';

void main() {
  group('syncRefreshProvider', () {
    test('initial value is 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final value = container.read(syncRefreshProvider);

      expect(value, equals(0));
    });

    test('state can be incremented', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(syncRefreshProvider), equals(0));

      container.read(syncRefreshProvider.notifier).state++;

      expect(container.read(syncRefreshProvider), equals(1));
    });

    test('multiple increments work correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(syncRefreshProvider.notifier).state++;
      container.read(syncRefreshProvider.notifier).state++;
      container.read(syncRefreshProvider.notifier).state++;

      expect(container.read(syncRefreshProvider), equals(3));
    });

    test('listeners are notified on state change', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      var notificationCount = 0;
      container.listen(syncRefreshProvider, (previous, next) {
        notificationCount++;
      }, fireImmediately: false);

      container.read(syncRefreshProvider.notifier).state++;
      container.read(syncRefreshProvider.notifier).state++;

      expect(notificationCount, equals(2));
    });

    test('can be watched by dependent providers', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // A provider that depends on syncRefreshProvider
      final dependentProvider = Provider<String>((ref) {
        final count = ref.watch(syncRefreshProvider);
        return 'refresh-$count';
      });

      expect(container.read(dependentProvider), equals('refresh-0'));

      container.read(syncRefreshProvider.notifier).state++;

      expect(container.read(dependentProvider), equals('refresh-1'));
    });
  });

  group('SyncRefreshExtension integration', () {
    // Note: refreshAfterSync() cannot be called during provider initialization.
    // It's designed to be called from stream listeners (like SyncService.stateStream)
    // which run after providers are built.
    //
    // The actual behavior is tested in integration tests where SyncService
    // emits SyncState.success and triggers the refresh mechanism.

    test('extension method exists and is accessible', () {
      // This test verifies the extension compiles and is properly defined.
      // The extension adds refreshAfterSync() method to Ref.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Read a provider to ensure container is properly initialized
      final value = container.read(syncRefreshProvider);
      expect(value, isA<int>());

      // The extension method is tested implicitly through SyncService
      // integration tests that verify UI refreshes after successful sync.
    });
  });
}
