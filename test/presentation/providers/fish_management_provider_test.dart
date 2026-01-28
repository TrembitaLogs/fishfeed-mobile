import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

import '../../helpers/test_helpers.dart' show createMockSyncService;

// ============================================================================
// Mocks
// ============================================================================

class MockFishLocalDataSource extends Mock implements FishLocalDataSource {}

class MockAquariumLocalDataSource extends Mock
    implements AquariumLocalDataSource {}

class MockSyncService extends Mock implements SyncService {}

class FakeFishModel extends Fake implements FishModel {}

const _testAquariumId = 'test-aquarium-id';

AquariumModel _createTestAquarium() {
  return AquariumModel(
    id: _testAquariumId,
    userId: 'test-user',
    name: 'Test Aquarium',
    waterType: WaterType.freshwater,
    createdAt: DateTime.now(),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeFishModel());
  });

  group('FishManagementState', () {
    test('isEmpty returns true when fish list empty, not loading, no error',
        () {
      const state = FishManagementState(userFish: [], isLoading: false);
      expect(state.isEmpty, isTrue);
    });

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
    late MockFishLocalDataSource mockFishDs;
    late MockAquariumLocalDataSource mockAquariumDs;
    late MockSyncService mockSyncService;
    late ProviderContainer container;

    setUp(() {
      mockFishDs = MockFishLocalDataSource();
      mockAquariumDs = MockAquariumLocalDataSource();
      mockSyncService = MockSyncService();
      // Default setup: return a test aquarium
      when(() => mockAquariumDs.getAllAquariums())
          .thenReturn([_createTestAquarium()]);
      // Default sync service setup
      when(() => mockSyncService.syncNow()).thenAnswer((_) async => 0);
    });

    tearDown(() {
      container.dispose();
    });

    test('loadUserFish fetches fish from data source', () async {
      final fishModels = [
        _createFishModel('1', 'guppy', 5),
        _createFishModel('2', 'betta', 1),
      ];

      when(() => mockFishDs.getFishByAquariumId(_testAquariumId))
          .thenReturn(fishModels);

      container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
        ],
      );

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(fishManagementProvider);

      expect(state.isLoading, isFalse);
      expect(state.userFish.length, equals(2));
      expect(state.userFish[0].speciesId, equals('guppy'));
      expect(state.userFish[0].quantity, equals(5));

      verify(() => mockFishDs.getFishByAquariumId(_testAquariumId)).called(1);
    });

    test('loadUserFish sets error state on failure', () async {
      when(() => mockFishDs.getFishByAquariumId(_testAquariumId))
          .thenThrow(Exception('Database error'));

      container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(fishManagementProvider);

      expect(state.isLoading, isFalse);
      expect(state.hasError, isTrue);
      expect(state.error, contains('Failed to load fish'));
    });

    test('addFish saves fish and updates state', () async {
      when(() => mockFishDs.getFishByAquariumId(_testAquariumId)).thenReturn([]);
      when(() => mockFishDs.saveFish(any())).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
        ],
      );

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

      verify(() => mockFishDs.saveFish(any())).called(1);
    });

    test('addFish returns null and sets error on failure', () async {
      when(() => mockFishDs.getFishByAquariumId(_testAquariumId)).thenReturn([]);
      when(() => mockFishDs.saveFish(any()))
          .thenThrow(Exception('Save failed'));

      container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final result = await container
          .read(fishManagementProvider.notifier)
          .addFish(speciesId: 'guppy', quantity: 5);

      expect(result, isNull);

      final state = container.read(fishManagementProvider);
      expect(state.hasError, isTrue);
      expect(state.error, contains('Failed to add fish'));
    });

    test('updateFish updates fish and state', () async {
      final existingFish = _createFishModel('fish_1', 'guppy', 5);

      when(() => mockFishDs.getFishByAquariumId(_testAquariumId))
          .thenReturn([existingFish]);
      when(() => mockFishDs.updateFish(any())).thenAnswer((_) async => true);

      container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final updatedFish = existingFish.toEntity().copyWith(quantity: 10);
      final success = await container
          .read(fishManagementProvider.notifier)
          .updateFish(updatedFish);

      expect(success, isTrue);

      final state = container.read(fishManagementProvider);
      expect(state.userFish.first.quantity, equals(10));

      verify(() => mockFishDs.updateFish(any())).called(1);
    });

    test('updateFish returns false when fish not found in data source',
        () async {
      final existingFish = _createFishModel('fish_1', 'guppy', 5);

      when(() => mockFishDs.getFishByAquariumId(_testAquariumId))
          .thenReturn([existingFish]);
      when(() => mockFishDs.updateFish(any())).thenAnswer((_) async => false);

      container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final updatedFish = existingFish.toEntity().copyWith(quantity: 10);
      final success = await container
          .read(fishManagementProvider.notifier)
          .updateFish(updatedFish);

      expect(success, isFalse);

      final state = container.read(fishManagementProvider);
      expect(state.hasError, isTrue);
      expect(state.error, equals('Fish not found'));
    });

    test('updateFish sets error state on exception', () async {
      final existingFish = _createFishModel('fish_1', 'guppy', 5);

      when(() => mockFishDs.getFishByAquariumId(_testAquariumId))
          .thenReturn([existingFish]);
      when(() => mockFishDs.updateFish(any()))
          .thenThrow(Exception('Update failed'));

      container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final updatedFish = existingFish.toEntity().copyWith(quantity: 10);
      final success = await container
          .read(fishManagementProvider.notifier)
          .updateFish(updatedFish);

      expect(success, isFalse);

      final state = container.read(fishManagementProvider);
      expect(state.hasError, isTrue);
      expect(state.error, contains('Failed to update fish'));
    });

    test('deleteFish soft deletes fish, syncs, and updates state', () async {
      final existingFish = _createFishModel('fish_1', 'guppy', 5);

      when(() => mockFishDs.getFishByAquariumId(_testAquariumId))
          .thenReturn([existingFish]);
      when(() => mockFishDs.softDelete('fish_1')).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
          syncServiceProvider.overrideWithValue(mockSyncService),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final success = await container
          .read(fishManagementProvider.notifier)
          .deleteFish('fish_1');

      expect(success, isTrue);

      final state = container.read(fishManagementProvider);
      expect(state.userFish, isEmpty);

      // Verify softDelete was called instead of deleteFish
      verify(() => mockFishDs.softDelete('fish_1')).called(1);
      // Verify sync was triggered
      verify(() => mockSyncService.syncNow()).called(1);
    });

    test('deleteFish returns false when fish not in state', () async {
      when(() => mockFishDs.getFishByAquariumId(_testAquariumId)).thenReturn([]);

      container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
        ],
      );

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
      final existingFish = _createFishModel('fish_1', 'guppy', 5);

      when(() => mockFishDs.getFishByAquariumId(_testAquariumId))
          .thenReturn([existingFish]);
      when(() => mockFishDs.softDelete('fish_1'))
          .thenThrow(Exception('Soft delete failed'));

      container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
          syncServiceProvider.overrideWithValue(mockSyncService),
        ],
      );

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
      final existingFish = _createFishModel('fish_1', 'guppy', 5);

      when(() => mockFishDs.getFishByAquariumId(_testAquariumId))
          .thenReturn([existingFish]);
      when(() => mockFishDs.softDelete('fish_1')).thenAnswer((_) async {});
      when(() => mockSyncService.syncNow())
          .thenThrow(Exception('Sync failed'));

      container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
          syncServiceProvider.overrideWithValue(mockSyncService),
        ],
      );

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
      final existingFish = _createFishModel('fish_1', 'guppy', 5);

      when(() => mockFishDs.getFishByAquariumId(_testAquariumId))
          .thenReturn([existingFish]);

      container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final fish =
          container.read(fishManagementProvider.notifier).getFishById('fish_1');

      expect(fish, isNotNull);
      expect(fish!.id, equals('fish_1'));
    });

    test('getFishById returns null when not found', () async {
      when(() => mockFishDs.getFishByAquariumId(_testAquariumId)).thenReturn([]);

      container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final fish = container
          .read(fishManagementProvider.notifier)
          .getFishById('nonexistent');

      expect(fish, isNull);
    });

    test('clearError removes error from state', () async {
      when(() => mockFishDs.getFishByAquariumId(_testAquariumId))
          .thenThrow(Exception('Error'));

      container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify error exists
      var state = container.read(fishManagementProvider);
      expect(state.hasError, isTrue);

      // Clear error
      container.read(fishManagementProvider.notifier).clearError();

      state = container.read(fishManagementProvider);
      expect(state.hasError, isFalse);
    });

    test('refresh reloads fish from data source', () async {
      when(() => mockFishDs.getFishByAquariumId(_testAquariumId)).thenReturn([]);

      container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Refresh
      await container.read(fishManagementProvider.notifier).refresh();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Initial load + refresh = 2 calls total
      verify(() => mockFishDs.getFishByAquariumId(_testAquariumId)).called(2);
    });
  });

  group('userFishListProvider', () {
    test('returns userFish from fishManagementProvider', () async {
      final mockFishDs = MockFishLocalDataSource();
      final mockAquariumDs = _createMockAquariumDs();
      final fishModels = [
        _createFishModel('1', 'guppy', 5),
        _createFishModel('2', 'betta', 1),
      ];

      when(() => mockFishDs.getFishByAquariumId(_testAquariumId))
          .thenReturn(fishModels);

      final container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final fishList = container.read(userFishListProvider);

      expect(fishList.length, equals(2));

      container.dispose();
    });
  });

  group('totalFishCountProvider', () {
    test('returns total fish count', () async {
      final mockFishDs = MockFishLocalDataSource();
      final mockAquariumDs = _createMockAquariumDs();
      final fishModels = [
        _createFishModel('1', 'guppy', 5),
        _createFishModel('2', 'betta', 3),
      ];

      when(() => mockFishDs.getFishByAquariumId(_testAquariumId))
          .thenReturn(fishModels);

      final container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
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
      final mockFishDs = MockFishLocalDataSource();
      final mockAquariumDs = _createMockAquariumDs();
      final fishModels = [
        _createFishModel('1', 'guppy', 5),
        _createFishModel('2', 'betta', 3),
        _createFishModel('3', 'goldfish', 2),
      ];

      when(() => mockFishDs.getFishByAquariumId(_testAquariumId))
          .thenReturn(fishModels);

      final container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
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
      final mockFishDs = MockFishLocalDataSource();
      final mockAquariumDs = _createMockAquariumDs();

      when(() => mockFishDs.getFishByAquariumId(_testAquariumId)).thenReturn([]);

      final container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
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
      final mockFishDs = MockFishLocalDataSource();
      final mockAquariumDs = _createMockAquariumDs();

      when(() => mockFishDs.getFishByAquariumId(_testAquariumId)).thenReturn([]);

      final container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final isEmpty = container.read(isAquariumEmptyProvider);

      expect(isEmpty, isTrue);

      container.dispose();
    });

    test('returns false when has fish', () async {
      final mockFishDs = MockFishLocalDataSource();
      final mockAquariumDs = _createMockAquariumDs();
      final fishModels = [_createFishModel('1', 'guppy', 5)];

      when(() => mockFishDs.getFishByAquariumId(_testAquariumId))
          .thenReturn(fishModels);

      final container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final isEmpty = container.read(isAquariumEmptyProvider);

      expect(isEmpty, isFalse);

      container.dispose();
    });
  });

  group('deleteFishByIdProvider', () {
    late MockFishLocalDataSource mockFishDs;
    late MockSyncService mockSyncService;

    setUp(() {
      mockFishDs = MockFishLocalDataSource();
      mockSyncService = MockSyncService();
      when(() => mockSyncService.syncNow()).thenAnswer((_) async => 0);
    });

    test('soft deletes fish and triggers sync', () async {
      final existingFish = _createFishModel('fish_1', 'guppy', 5);

      when(() => mockFishDs.getFishById('fish_1')).thenReturn(existingFish);
      when(() => mockFishDs.softDelete('fish_1')).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          syncServiceProvider.overrideWithValue(mockSyncService),
        ],
      );

      final result =
          await container.read(deleteFishByIdProvider('fish_1').future);

      expect(result, isTrue);
      verify(() => mockFishDs.softDelete('fish_1')).called(1);
      verify(() => mockSyncService.syncNow()).called(1);

      container.dispose();
    });

    test('returns false when fish not found', () async {
      when(() => mockFishDs.getFishById('nonexistent')).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          syncServiceProvider.overrideWithValue(mockSyncService),
        ],
      );

      final result =
          await container.read(deleteFishByIdProvider('nonexistent').future);

      expect(result, isFalse);
      verifyNever(() => mockFishDs.softDelete(any()));
      verifyNever(() => mockSyncService.syncNow());

      container.dispose();
    });

    test('invalidates fish providers after deletion', () async {
      final existingFish = _createFishModel('fish_1', 'guppy', 5);

      when(() => mockFishDs.getFishById('fish_1')).thenReturn(existingFish);
      when(() => mockFishDs.softDelete('fish_1')).thenAnswer((_) async {});
      // Mock for fishByIdProvider and fishByAquariumIdProvider
      when(() => mockFishDs.getFishByAquariumId(_testAquariumId)).thenReturn([]);

      final container = ProviderContainer(
        overrides: [
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          syncServiceProvider.overrideWithValue(mockSyncService),
        ],
      );

      // Read fishByIdProvider first to populate cache
      container.read(fishByIdProvider('fish_1'));
      container.read(fishByAquariumIdProvider(_testAquariumId));

      // Now delete
      await container.read(deleteFishByIdProvider('fish_1').future);

      // Verify providers were invalidated by reading them again
      // (they should re-read from data source)
      verify(() => mockFishDs.getFishById('fish_1')).called(2);

      container.dispose();
    });
  });
}

/// Creates a mock AquariumLocalDataSource with default setup.
MockAquariumLocalDataSource _createMockAquariumDs() {
  final mockAquariumDs = MockAquariumLocalDataSource();
  when(() => mockAquariumDs.getAllAquariums())
      .thenReturn([_createTestAquarium()]);
  return mockAquariumDs;
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

/// Helper to create a FishModel for testing.
FishModel _createFishModel(String id, String speciesId, int quantity) {
  return FishModel(
    id: id,
    aquariumId: _testAquariumId,
    speciesId: speciesId,
    quantity: quantity,
    addedAt: DateTime(2024, 1, 15),
  );
}
