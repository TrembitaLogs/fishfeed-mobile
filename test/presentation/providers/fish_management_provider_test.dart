import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/di/repository_providers.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/domain/repositories/fish_repository.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockFishRepository extends Mock implements FishRepository {}

class MockSyncService extends Mock implements SyncService {}

const _testAquariumId = 'test-aquarium-id';

Aquarium _createTestAquarium() {
  return Aquarium(
    id: _testAquariumId,
    userId: 'test-user',
    name: 'Test Aquarium',
    waterType: WaterType.freshwater,
    createdAt: DateTime.now(),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Fish(
        id: 'fallback',
        aquariumId: 'fallback-aq',
        speciesId: 'fallback-species',
        addedAt: DateTime(2024),
      ),
    );
  });

  group('FishManagementState', () {
    test(
      'isEmpty returns true when fish list empty, not loading, no error',
      () {
        const state = FishManagementState(userFish: [], isLoading: false);
        expect(state.isEmpty, isTrue);
      },
    );

    test('isEmpty returns false when loading', () {
      const state = FishManagementState(userFish: [], isLoading: true);
      expect(state.isEmpty, isFalse);
    });

    test('isEmpty returns false when has error', () {
      const state = FishManagementState(
        userFish: [],
        isLoading: false,
        error: 'Some error',
      );
      expect(state.isEmpty, isFalse);
    });

    test('hasError returns true when error is not null', () {
      const state = FishManagementState(error: 'Network error');
      expect(state.hasError, isTrue);
    });

    test('hasError returns false when error is null', () {
      const state = FishManagementState();
      expect(state.hasError, isFalse);
    });

    test('totalFishCount sums all fish quantities', () {
      final state = FishManagementState(
        userFish: [
          _createFish('1', 'guppy', 5),
          _createFish('2', 'betta', 1),
          _createFish('3', 'goldfish', 3),
        ],
      );

      expect(state.totalFishCount, equals(9));
    });

    test('speciesCount returns number of unique fish entries', () {
      final state = FishManagementState(
        userFish: [
          _createFish('1', 'guppy', 5),
          _createFish('2', 'betta', 1),
          _createFish('3', 'goldfish', 3),
        ],
      );

      expect(state.speciesCount, equals(3));
    });

    test('copyWith creates copy with updated fields', () {
      const original = FishManagementState(isLoading: true);
      final copy = original.copyWith(isLoading: false, error: 'New error');

      expect(copy.isLoading, isFalse);
      expect(copy.error, equals('New error'));
      expect(copy.userFish, equals(original.userFish));
    });

    test('copyWith with clearError sets error to null', () {
      const original = FishManagementState(error: 'Some error');
      final copy = original.copyWith(clearError: true);

      expect(copy.error, isNull);
    });
  });

  group('FishManagementNotifier', () {
    late MockFishRepository mockFishRepo;
    late MockSyncService mockSyncService;
    late ProviderContainer container;

    setUp(() {
      mockFishRepo = MockFishRepository();
      mockSyncService = MockSyncService();
      // Default sync service setup
      when(() => mockSyncService.syncNow()).thenAnswer((_) async => 0);
    });

    tearDown(() {
      container.dispose();
    });

    ProviderContainer _createContainer({MockSyncService? syncService}) {
      return ProviderContainer(
        overrides: [
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          selectedAquariumIdProvider.overrideWith((ref) => _testAquariumId),
          if (syncService != null)
            syncServiceProvider.overrideWithValue(syncService),
        ],
      );
    }

    test('loadUserFish fetches fish from repository', () async {
      final fishList = [
        _createFish('1', 'guppy', 5),
        _createFish('2', 'betta', 1),
      ];

      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn(fishList);

      container = _createContainer();

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(fishManagementProvider);

      expect(state.isLoading, isFalse);
      expect(state.userFish.length, equals(2));
      expect(state.userFish[0].speciesId, equals('guppy'));
      expect(state.userFish[0].quantity, equals(5));

      verify(() => mockFishRepo.getFishByAquariumId(_testAquariumId)).called(1);
    });

    test('loadUserFish sets error state on failure', () async {
      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenThrow(Exception('Database error'));

      container = _createContainer();

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(fishManagementProvider);

      expect(state.isLoading, isFalse);
      expect(state.hasError, isTrue);
      expect(state.error, contains('Failed to load fish'));
    });

    test('addFish saves fish and updates state', () async {
      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn([]);
      when(() => mockFishRepo.saveFish(any())).thenAnswer((_) async {});

      container = _createContainer();

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final result = await container
          .read(fishManagementProvider.notifier)
          .addFish(speciesId: 'guppy', quantity: 5, name: 'My Guppy');

      expect(result, isNotNull);
      expect(result!.speciesId, equals('guppy'));
      expect(result.quantity, equals(5));
      expect(result.name, equals('My Guppy'));
      expect(result.aquariumId, equals(_testAquariumId));

      final state = container.read(fishManagementProvider);
      expect(state.userFish.length, equals(1));

      verify(() => mockFishRepo.saveFish(any())).called(1);
    });

    test('addFish returns null and sets error on failure', () async {
      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn([]);
      when(
        () => mockFishRepo.saveFish(any()),
      ).thenThrow(Exception('Save failed'));

      container = _createContainer();

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final result = await container
          .read(fishManagementProvider.notifier)
          .addFish(speciesId: 'guppy', quantity: 5);

      expect(result, isNull);

      final state = container.read(fishManagementProvider);
      expect(state.hasError, isTrue);
      expect(state.error, contains('Failed to add fish'));
    });

    test(
      'addFish always creates new record even if same species exists',
      () async {
        // Arrange: Create existing fish of same species
        final existingFish = _createFish('fish_1', 'guppy', 3);

        when(
          () => mockFishRepo.getFishByAquariumId(_testAquariumId),
        ).thenReturn([existingFish]);
        when(() => mockFishRepo.saveFish(any())).thenAnswer((_) async {});

        container = _createContainer();

        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Act: Add another fish of the same species
        final result = await container
            .read(fishManagementProvider.notifier)
            .addFish(speciesId: 'guppy', quantity: 5);

        // Assert: Should create NEW record, not merge with existing
        expect(result, isNotNull);
        expect(result!.id, isNot(equals('fish_1'))); // New ID, not existing
        expect(result.speciesId, equals('guppy'));
        expect(result.quantity, equals(5)); // New quantity, not merged (3+5=8)

        final state = container.read(fishManagementProvider);
        // Should have 2 fish records now
        expect(state.userFish.length, equals(2));

        // Verify saveFish was called (not updateFish)
        verify(() => mockFishRepo.saveFish(any())).called(1);
        verifyNever(() => mockFishRepo.updateFish(any()));
      },
    );

    test('updateFish updates fish and state', () async {
      final existingFish = _createFish('fish_1', 'guppy', 5);

      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn([existingFish]);
      when(() => mockFishRepo.updateFish(any())).thenAnswer((_) async => true);

      container = _createContainer();

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final updatedFish = existingFish.copyWith(quantity: 10);
      final success = await container
          .read(fishManagementProvider.notifier)
          .updateFish(updatedFish);

      expect(success, isTrue);

      final state = container.read(fishManagementProvider);
      expect(state.userFish.first.quantity, equals(10));

      verify(() => mockFishRepo.updateFish(any())).called(1);
    });

    test(
      'updateFish returns false when fish not found in repository',
      () async {
        final existingFish = _createFish('fish_1', 'guppy', 5);

        when(
          () => mockFishRepo.getFishByAquariumId(_testAquariumId),
        ).thenReturn([existingFish]);
        when(
          () => mockFishRepo.updateFish(any()),
        ).thenAnswer((_) async => false);

        container = _createContainer();

        await Future<void>.delayed(const Duration(milliseconds: 100));

        final updatedFish = existingFish.copyWith(quantity: 10);
        final success = await container
            .read(fishManagementProvider.notifier)
            .updateFish(updatedFish);

        expect(success, isFalse);

        final state = container.read(fishManagementProvider);
        expect(state.hasError, isTrue);
        expect(state.error, equals('Fish not found'));
      },
    );

    test('updateFish sets error state on exception', () async {
      final existingFish = _createFish('fish_1', 'guppy', 5);

      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn([existingFish]);
      when(
        () => mockFishRepo.updateFish(any()),
      ).thenThrow(Exception('Update failed'));

      container = _createContainer();

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final updatedFish = existingFish.copyWith(quantity: 10);
      final success = await container
          .read(fishManagementProvider.notifier)
          .updateFish(updatedFish);

      expect(success, isFalse);

      final state = container.read(fishManagementProvider);
      expect(state.hasError, isTrue);
      expect(state.error, contains('Failed to update fish'));
    });

    test('deleteFish soft deletes fish, syncs, and updates state', () async {
      final existingFish = _createFish('fish_1', 'guppy', 5);

      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn([existingFish]);
      when(
        () => mockFishRepo.softDelete('fish_1'),
      ).thenAnswer((_) async {});

      container = _createContainer(syncService: mockSyncService);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final success = await container
          .read(fishManagementProvider.notifier)
          .deleteFish('fish_1');

      expect(success, isTrue);

      final state = container.read(fishManagementProvider);
      expect(state.userFish, isEmpty);

      // Verify softDelete was called
      verify(() => mockFishRepo.softDelete('fish_1')).called(1);
      // Verify sync was triggered
      verify(() => mockSyncService.syncNow()).called(1);
    });

    test('deleteFish returns false when fish not in state', () async {
      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn([]);

      container = _createContainer();

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final success = await container
          .read(fishManagementProvider.notifier)
          .deleteFish('nonexistent_fish');

      expect(success, isFalse);

      final state = container.read(fishManagementProvider);
      expect(state.hasError, isTrue);
      expect(state.error, equals('Fish not found'));
    });

    test('deleteFish returns false when soft delete fails', () async {
      final existingFish = _createFish('fish_1', 'guppy', 5);

      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn([existingFish]);
      when(
        () => mockFishRepo.softDelete('fish_1'),
      ).thenThrow(Exception('Soft delete failed'));

      container = _createContainer(syncService: mockSyncService);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final success = await container
          .read(fishManagementProvider.notifier)
          .deleteFish('fish_1');

      expect(success, isFalse);

      final state = container.read(fishManagementProvider);
      expect(state.hasError, isTrue);
      expect(state.error, contains('Failed to delete fish'));
    });

    test('deleteFish continues even if sync fails', () async {
      final existingFish = _createFish('fish_1', 'guppy', 5);

      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn([existingFish]);
      when(
        () => mockFishRepo.softDelete('fish_1'),
      ).thenAnswer((_) async {});
      when(() => mockSyncService.syncNow()).thenThrow(Exception('Sync failed'));

      container = _createContainer(syncService: mockSyncService);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Delete should still succeed even if sync fails
      // because sync errors are caught and handled
      final success = await container
          .read(fishManagementProvider.notifier)
          .deleteFish('fish_1');

      expect(success, isTrue);

      final state = container.read(fishManagementProvider);
      // Fish should be removed from local state
      expect(state.userFish, isEmpty);
      // No error should be set because sync errors are swallowed
      expect(state.hasError, isFalse);
    });

    test('getFishById returns fish when found', () async {
      final existingFish = _createFish('fish_1', 'guppy', 5);

      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn([existingFish]);

      container = _createContainer();

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final fish = container
          .read(fishManagementProvider.notifier)
          .getFishById('fish_1');

      expect(fish, isNotNull);
      expect(fish!.id, equals('fish_1'));
    });

    test('getFishById returns null when not found', () async {
      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn([]);

      container = _createContainer();

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final fish = container
          .read(fishManagementProvider.notifier)
          .getFishById('nonexistent');

      expect(fish, isNull);
    });

    test('clearError removes error from state', () async {
      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenThrow(Exception('Error'));

      container = _createContainer();

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify error exists
      var state = container.read(fishManagementProvider);
      expect(state.hasError, isTrue);

      // Clear error
      container.read(fishManagementProvider.notifier).clearError();

      state = container.read(fishManagementProvider);
      expect(state.hasError, isFalse);
    });

    test('refresh reloads fish from repository', () async {
      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn([]);

      container = _createContainer();

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Refresh
      await container.read(fishManagementProvider.notifier).refresh();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Initial load + refresh = 2 calls total
      verify(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).called(2);
    });
  });

  group('userFishListProvider', () {
    test('returns userFish from fishManagementProvider', () async {
      final mockFishRepo = MockFishRepository();
      final fishList = [
        _createFish('1', 'guppy', 5),
        _createFish('2', 'betta', 1),
      ];

      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn(fishList);

      final container = ProviderContainer(
        overrides: [
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          selectedAquariumIdProvider.overrideWith((ref) => _testAquariumId),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final result = container.read(userFishListProvider);

      expect(result.length, equals(2));

      container.dispose();
    });
  });

  group('totalFishCountProvider', () {
    test('returns total fish count', () async {
      final mockFishRepo = MockFishRepository();
      final fishList = [
        _createFish('1', 'guppy', 5),
        _createFish('2', 'betta', 3),
      ];

      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn(fishList);

      final container = ProviderContainer(
        overrides: [
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          selectedAquariumIdProvider.overrideWith((ref) => _testAquariumId),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final count = container.read(totalFishCountProvider);

      expect(count, equals(8));

      container.dispose();
    });
  });

  group('fishSpeciesCountProvider', () {
    test('returns species count', () async {
      final mockFishRepo = MockFishRepository();
      final fishList = [
        _createFish('1', 'guppy', 5),
        _createFish('2', 'betta', 3),
        _createFish('3', 'goldfish', 2),
      ];

      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn(fishList);

      final container = ProviderContainer(
        overrides: [
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          selectedAquariumIdProvider.overrideWith((ref) => _testAquariumId),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final count = container.read(fishSpeciesCountProvider);

      expect(count, equals(3));

      container.dispose();
    });
  });

  group('isFishLoadingProvider', () {
    test('returns loading state', () async {
      final mockFishRepo = MockFishRepository();

      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn([]);

      final container = ProviderContainer(
        overrides: [
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          selectedAquariumIdProvider.overrideWith((ref) => _testAquariumId),
        ],
      );

      // After load completes
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final isLoading = container.read(isFishLoadingProvider);

      expect(isLoading, isFalse);

      container.dispose();
    });
  });

  group('isAquariumEmptyProvider', () {
    test('returns true when no fish', () async {
      final mockFishRepo = MockFishRepository();

      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn([]);

      final container = ProviderContainer(
        overrides: [
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          selectedAquariumIdProvider.overrideWith((ref) => _testAquariumId),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final isEmpty = container.read(isAquariumEmptyProvider);

      expect(isEmpty, isTrue);

      container.dispose();
    });

    test('returns false when has fish', () async {
      final mockFishRepo = MockFishRepository();
      final fishList = [_createFish('1', 'guppy', 5)];

      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn(fishList);

      final container = ProviderContainer(
        overrides: [
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          selectedAquariumIdProvider.overrideWith((ref) => _testAquariumId),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final isEmpty = container.read(isAquariumEmptyProvider);

      expect(isEmpty, isFalse);

      container.dispose();
    });
  });

  group('deleteFishByIdProvider', () {
    late MockFishRepository mockFishRepo;
    late MockSyncService mockSyncService;

    setUp(() {
      mockFishRepo = MockFishRepository();
      mockSyncService = MockSyncService();
      when(() => mockSyncService.syncNow()).thenAnswer((_) async => 0);
    });

    test('soft deletes fish and triggers sync', () async {
      final existingFish = _createFish('fish_1', 'guppy', 5);

      when(() => mockFishRepo.getFishById('fish_1')).thenReturn(existingFish);
      when(
        () => mockFishRepo.softDelete('fish_1'),
      ).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          syncServiceProvider.overrideWithValue(mockSyncService),
        ],
      );

      final result = await container.read(
        deleteFishByIdProvider('fish_1').future,
      );

      expect(result, isTrue);
      verify(() => mockFishRepo.softDelete('fish_1')).called(1);
      verify(() => mockSyncService.syncNow()).called(1);

      container.dispose();
    });

    test('returns false when fish not found', () async {
      when(() => mockFishRepo.getFishById('nonexistent')).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          syncServiceProvider.overrideWithValue(mockSyncService),
        ],
      );

      final result = await container.read(
        deleteFishByIdProvider('nonexistent').future,
      );

      expect(result, isFalse);
      verifyNever(() => mockFishRepo.softDelete(any()));
      verifyNever(() => mockSyncService.syncNow());

      container.dispose();
    });

    test('invalidates fish providers after deletion', () async {
      final existingFish = _createFish('fish_1', 'guppy', 5);

      when(() => mockFishRepo.getFishById('fish_1')).thenReturn(existingFish);
      when(
        () => mockFishRepo.softDelete('fish_1'),
      ).thenAnswer((_) async {});
      // Mock for fishByAquariumIdProvider
      when(
        () => mockFishRepo.getFishByAquariumId(_testAquariumId),
      ).thenReturn([]);

      final container = ProviderContainer(
        overrides: [
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          syncServiceProvider.overrideWithValue(mockSyncService),
        ],
      );

      // Read fishByIdProvider first to populate cache
      container.read(fishByIdProvider('fish_1'));
      container.read(fishByAquariumIdProvider(_testAquariumId));

      // Now delete
      await container.read(deleteFishByIdProvider('fish_1').future);

      // Verify providers were invalidated by reading them again
      // (they should re-read from repository)
      verify(() => mockFishRepo.getFishById('fish_1')).called(2);

      container.dispose();
    });
  });
}

/// Helper to create a Fish entity for testing.
Fish _createFish(String id, String speciesId, int quantity) {
  return Fish(
    id: id,
    aquariumId: _testAquariumId,
    speciesId: speciesId,
    quantity: quantity,
    addedAt: DateTime(2024, 1, 15),
  );
}
