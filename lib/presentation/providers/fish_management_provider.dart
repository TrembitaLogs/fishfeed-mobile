import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:fishfeed/core/di/repository_providers.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/domain/repositories/fish_repository.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/sync_refresh_provider.dart';
import 'package:fishfeed/services/analytics/analytics_service.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

// ============================================================================
// Fish Management State
// ============================================================================

/// State for fish management.
///
/// Tracks the user's fish list with loading and error states.
class FishManagementState {
  const FishManagementState({
    this.userFish = const [],
    this.isLoading = false,
    this.error,
  });

  /// List of user's fish.
  final List<Fish> userFish;

  /// Whether data is currently loading.
  final bool isLoading;

  /// Error message if operation failed.
  final String? error;

  /// Whether state has an error.
  bool get hasError => error != null;

  /// Whether fish list is empty.
  bool get isEmpty => userFish.isEmpty && !isLoading && !hasError;

  /// Total count of fish (sum of all quantities).
  int get totalFishCount =>
      userFish.fold(0, (sum, fish) => sum + fish.quantity);

  /// Number of unique fish species.
  int get speciesCount => userFish.length;

  FishManagementState copyWith({
    List<Fish>? userFish,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FishManagementState(
      userFish: userFish ?? this.userFish,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ============================================================================
// Fish Management Notifier
// ============================================================================

/// Notifier for managing fish state.
///
/// Provides CRUD operations for fish via [FishRepository].
/// Integrates with analytics and feeding schedule updates.
class FishManagementNotifier extends StateNotifier<FishManagementState> {
  FishManagementNotifier({
    required FishRepository fishRepository,
    required Ref ref,
    String? selectedAquariumId,
  }) : _fishRepository = fishRepository,
       _ref = ref,
       _selectedAquariumId = selectedAquariumId,
       super(const FishManagementState()) {
    loadUserFish();
  }

  final FishRepository _fishRepository;
  final Ref _ref;
  String? _selectedAquariumId;

  static const _uuid = Uuid();

  /// Gets the current aquarium ID.
  ///
  /// Returns the selected aquarium ID, or the first aquarium's ID as fallback.
  String? get _currentAquariumId {
    if (_selectedAquariumId != null) {
      return _selectedAquariumId;
    }
    // Fallback to first aquarium via aquarium provider
    final aquariumState = _ref.read(userAquariumsProvider);
    return aquariumState.aquariums.isNotEmpty
        ? aquariumState.aquariums.first.id
        : null;
  }

  /// Updates the selected aquarium ID and reloads fish.
  void setSelectedAquarium(String? aquariumId) {
    if (_selectedAquariumId != aquariumId) {
      _selectedAquariumId = aquariumId;
      loadUserFish();
    }
  }

  /// Loads all fish for the current aquarium.
  ///
  /// Fetches fish from local storage via repository and updates state.
  Future<void> loadUserFish() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final aquariumId = _currentAquariumId;
      if (aquariumId == null) {
        state = state.copyWith(userFish: [], isLoading: false);
        return;
      }

      final fish = _fishRepository.getFishByAquariumId(aquariumId);

      state = state.copyWith(userFish: fish, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load fish: $e',
      );
    }
  }

  /// Adds a new fish to the aquarium.
  ///
  /// [speciesId] - The species ID from species database.
  /// [quantity] - Number of fish (default: 1).
  /// [name] - Optional custom name for the fish.
  /// [aquariumId] - Optional aquarium ID (uses current aquarium if not provided).
  ///
  /// Always creates a new Fish record, even if a fish of the same species
  /// already exists. This allows users to have separate feeding schedules
  /// for different groups of the same species.
  ///
  /// To update quantity of an existing fish group, use [updateFish] instead.
  ///
  /// Returns the created [Fish] entity on success, null on failure.
  Future<Fish?> addFish({
    required String speciesId,
    int quantity = 1,
    String? name,
    String? aquariumId,
  }) async {
    try {
      final targetAquariumId = aquariumId ?? _currentAquariumId;
      if (targetAquariumId == null) {
        state = state.copyWith(error: 'No aquarium selected');
        return null;
      }

      // Always create a new Fish record (allows separate schedules per group)
      final now = DateTime.now();
      final fish = Fish(
        id: _uuid.v4(),
        aquariumId: targetAquariumId,
        speciesId: speciesId,
        name: name,
        quantity: quantity,
        addedAt: now,
      );

      await _fishRepository.saveFish(fish);

      // Update state
      state = state.copyWith(userFish: [...state.userFish, fish]);

      // Track analytics
      AnalyticsService.instance.trackFishAdded(
        speciesId: speciesId,
        speciesName: name ?? speciesId,
        fishCount: quantity,
        method: FishAddMethod.aiCamera,
      );

      // Sync with backend to create feeding events
      unawaited(_syncAndRefreshFeedings());

      return fish;
    } catch (e) {
      state = state.copyWith(error: 'Failed to add fish: $e');
      return null;
    }
  }

  /// Updates an existing fish.
  ///
  /// [fish] - The updated fish entity.
  ///
  /// Returns true on success, false on failure.
  Future<bool> updateFish(Fish fish) async {
    try {
      final success = await _fishRepository.updateFish(fish);

      if (!success) {
        state = state.copyWith(error: 'Fish not found');
        return false;
      }

      // Update state
      final updatedList = state.userFish.map((f) {
        if (f.id == fish.id) {
          return fish;
        }
        return f;
      }).toList();

      state = state.copyWith(userFish: updatedList);

      // TODO(task-20.10): Add analytics tracking for fish_edited

      // Invalidate feeding providers to refresh schedule
      unawaited(_syncAndRefreshFeedings());

      // Invalidate fish family providers for this fish and aquarium
      _ref.invalidate(fishByIdProvider(fish.id));
      _ref.invalidate(fishByAquariumIdProvider(fish.aquariumId));

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update fish: $e');
      return false;
    }
  }

  /// Deletes a fish from the aquarium.
  ///
  /// [id] - The unique identifier of the fish to delete.
  ///
  /// Uses soft delete to mark fish for deletion, then syncs with server.
  /// Server will cascade delete feeding events.
  /// Returns true on success, false on failure.
  Future<bool> deleteFish(String id) async {
    try {
      // Find fish to get aquariumId before deletion
      final fishToDelete = state.userFish.where((f) => f.id == id).firstOrNull;
      if (fishToDelete == null) {
        state = state.copyWith(error: 'Fish not found');
        return false;
      }

      // Soft delete via repository
      await _fishRepository.softDelete(id);

      // Update state immediately for responsive UI
      final updatedList = state.userFish.where((f) => f.id != id).toList();
      state = state.copyWith(userFish: updatedList);

      // Invalidate fish family providers
      _ref.invalidate(fishByIdProvider(id));
      _ref.invalidate(fishByAquariumIdProvider(fishToDelete.aquariumId));

      // TODO(task-20.10): Add analytics tracking for fish_deleted

      // Sync with server - this sends the deletion and gets updated feeding events
      // _SyncCompletionRefreshListener will refresh UI providers automatically
      await _syncAndRefreshFeedings();

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete fish: $e');
      return false;
    }
  }

  /// Gets a fish by its ID.
  ///
  /// Returns the [Fish] entity or null if not found.
  Fish? getFishById(String id) {
    try {
      return state.userFish.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Refreshes the fish list from local storage.
  Future<void> refresh() async {
    await loadUserFish();
  }

  /// Clears any error state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Triggers sync with backend.
  ///
  /// Schedules should be created locally before calling this method.
  /// This sync uploads local changes (fish, schedules) to the server.
  /// UI refresh is handled by _SyncCompletionRefreshListener in app.dart
  /// which listens to sync state changes and calls refresh() on providers.
  Future<void> _syncAndRefreshFeedings() async {
    try {
      final syncService = _ref.read(syncServiceProvider);
      // Sync with backend - this creates feeding events for new fish
      // UI refresh is handled globally by _SyncCompletionRefreshListener
      await syncService.syncNow();
    } catch (_) {
      // Sync errors are handled by SyncService
    }
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Provider for [FishManagementNotifier].
///
/// Usage:
/// ```dart
/// final fishNotifier = ref.watch(fishManagementProvider.notifier);
/// await fishNotifier.addFish(speciesId: 'guppy', quantity: 5);
/// ```
final fishManagementProvider =
    StateNotifierProvider<FishManagementNotifier, FishManagementState>((ref) {
      final fishRepository = ref.watch(fishRepositoryProvider);
      final selectedAquariumId = ref.watch(selectedAquariumIdProvider);

      return FishManagementNotifier(
        fishRepository: fishRepository,
        ref: ref,
        selectedAquariumId: selectedAquariumId,
      );
    });

/// Provider for user's fish list.
///
/// Convenience provider for accessing just the fish list.
final userFishListProvider = Provider<List<Fish>>((ref) {
  return ref.watch(fishManagementProvider).userFish;
});

/// Provider for total fish count.
///
/// Returns the sum of all fish quantities.
final totalFishCountProvider = Provider<int>((ref) {
  return ref.watch(fishManagementProvider).totalFishCount;
});

/// Provider for fish species count.
///
/// Returns the number of unique fish species.
final fishSpeciesCountProvider = Provider<int>((ref) {
  return ref.watch(fishManagementProvider).speciesCount;
});

/// Provider for fish loading state.
final isFishLoadingProvider = Provider<bool>((ref) {
  return ref.watch(fishManagementProvider).isLoading;
});

/// Provider for checking if aquarium is empty.
final isAquariumEmptyProvider = Provider<bool>((ref) {
  return ref.watch(fishManagementProvider).isEmpty;
});

/// Provider for getting fish by aquarium ID.
///
/// Loads fish directly from repository for a specific aquarium.
/// Useful for screens that need fish for a different aquarium than selected.
final fishByAquariumIdProvider = Provider.family<List<Fish>, String>((
  ref,
  aquariumId,
) {
  // Re-read when sync completes (e.g. server-side photo_key update)
  ref.watch(syncRefreshProvider);
  final fishRepository = ref.watch(fishRepositoryProvider);
  return fishRepository.getFishByAquariumId(aquariumId);
});

/// Provider for getting a single fish by ID.
///
/// Loads fish directly from repository regardless of selected aquarium.
/// Useful for edit screens that need to find a specific fish.
final fishByIdProvider = Provider.family<Fish?, String>((ref, fishId) {
  // Re-read when sync completes (e.g. server-side photo_key update)
  ref.watch(syncRefreshProvider);
  final fishRepository = ref.watch(fishRepositoryProvider);
  return fishRepository.getFishById(fishId);
});

/// Provider for deleting a fish by ID.
///
/// Uses soft delete + sync to properly delete fish and feeding events.
/// Works regardless of which aquarium is selected.
/// Returns true on success, false on failure.
final deleteFishByIdProvider = FutureProvider.family<bool, String>((
  ref,
  fishId,
) async {
  final fishRepository = ref.watch(fishRepositoryProvider);
  final syncService = ref.watch(syncServiceProvider);

  // Get fish to find aquariumId before deletion
  final fish = fishRepository.getFishById(fishId);
  if (fish == null) {
    return false;
  }

  final aquariumId = fish.aquariumId;

  // Soft delete via repository
  await fishRepository.softDelete(fishId);

  // Invalidate fish providers immediately for responsive UI
  ref.invalidate(fishByIdProvider(fishId));
  ref.invalidate(fishByAquariumIdProvider(aquariumId));

  // Sync with server - this sends deletion and gets updated feeding events
  // _SyncCompletionRefreshListener will refresh UI providers automatically
  await syncService.syncNow();

  return true;
});
