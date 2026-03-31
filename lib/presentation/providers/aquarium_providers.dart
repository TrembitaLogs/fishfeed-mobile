import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/di/repository_providers.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/domain/repositories/aquarium_repository.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

// ============================================================================
// User Aquariums Provider
// ============================================================================

/// State for user's aquariums list.
class UserAquariumsState {
  const UserAquariumsState({
    this.aquariums = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
  });

  /// List of user's aquariums.
  final List<Aquarium> aquariums;

  /// Whether data is currently loading (initial load).
  final bool isLoading;

  /// Whether data is being refreshed (pull-to-refresh).
  final bool isRefreshing;

  /// Error message if loading failed.
  final String? error;

  /// Whether state has an error.
  bool get hasError => error != null;

  /// Whether aquariums list is empty.
  bool get isEmpty =>
      aquariums.isEmpty && !isLoading && !isRefreshing && !hasError;

  /// Count of aquariums.
  int get count => aquariums.length;

  /// Gets aquarium by ID.
  Aquarium? getById(String id) {
    try {
      return aquariums.firstWhere((a) => a.id == id);
    } catch (e) {
      // Aquarium not found in current state
      return null;
    }
  }

  UserAquariumsState copyWith({
    List<Aquarium>? aquariums,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
  }) {
    return UserAquariumsState(
      aquariums: aquariums ?? this.aquariums,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
    );
  }
}

/// Notifier for managing user's aquariums state.
///
/// Integrates with [AquariumRepository] for CRUD operations.
class UserAquariumsNotifier extends StateNotifier<UserAquariumsState> {
  UserAquariumsNotifier({
    required AquariumRepository aquariumRepository,
    required SyncService syncService,
  }) : _aquariumRepository = aquariumRepository,
       _syncService = syncService,
       super(const UserAquariumsState()) {
    loadAquariums();
  }

  final AquariumRepository _aquariumRepository;
  final SyncService _syncService;

  /// Loads user's aquariums.
  ///
  /// Fetches from server if online, otherwise returns cached data.
  Future<void> loadAquariums() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _aquariumRepository.getAquariums();

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (aquariums) {
        state = state.copyWith(aquariums: aquariums, isLoading: false);
      },
    );
  }

  /// Refreshes aquariums (pull-to-refresh).
  ///
  /// Triggers a full sync via [SyncService], then reloads from local storage.
  /// Uses [isRefreshing] instead of [isLoading] to avoid showing shimmer.
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, error: null);

    try {
      await _syncService.syncAll();
    } catch (e) {
      debugPrint('AquariumProviders: Sync failed during refresh: $e');
      // Non-fatal; continue with local data reload below
    }

    final result = await _aquariumRepository.getAquariums();

    result.fold(
      (failure) {
        state = state.copyWith(isRefreshing: false, error: failure.message);
      },
      (aquariums) {
        state = state.copyWith(aquariums: aquariums, isRefreshing: false);
      },
    );
  }

  /// Creates a new aquarium.
  ///
  /// [name] - The name of the aquarium.
  /// [waterType] - Optional water type (defaults to freshwater).
  /// [capacity] - Optional capacity in liters.
  ///
  /// Returns the created aquarium on success, or null on failure.
  Future<Aquarium?> createAquarium({
    required String name,
    WaterType? waterType,
    double? capacity,
  }) async {
    final result = await _aquariumRepository.createAquarium(
      name: name,
      waterType: waterType,
      capacity: capacity,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return null;
      },
      (aquarium) {
        // Add to local state, avoiding duplicates by ID
        final existingIds = state.aquariums.map((a) => a.id).toSet();
        if (existingIds.contains(aquarium.id)) {
          // Aquarium already exists - update instead of duplicate
          final updated = state.aquariums.map((a) {
            return a.id == aquarium.id ? aquarium : a;
          }).toList();
          state = state.copyWith(aquariums: updated);
        } else {
          // New aquarium - add to beginning
          final updated = [aquarium, ...state.aquariums];
          state = state.copyWith(aquariums: updated);
        }
        return aquarium;
      },
    );
  }

  /// Updates an existing aquarium.
  ///
  /// [aquariumId] - The unique identifier of the aquarium to update.
  /// [name] - Optional new name.
  /// [waterType] - Optional new water type.
  /// [capacity] - Optional new capacity.
  /// [photoKey] - Optional new S3 object key for photo.
  /// [clearPhotoKey] - When true, explicitly sets photoKey to null
  ///   (removes photo). Takes precedence over [photoKey].
  ///
  /// Returns the updated aquarium on success, or null on failure.
  Future<Aquarium?> updateAquarium({
    required String aquariumId,
    String? name,
    WaterType? waterType,
    double? capacity,
    String? photoKey,
    bool clearPhotoKey = false,
  }) async {
    final result = await _aquariumRepository.updateAquarium(
      aquariumId: aquariumId,
      name: name,
      waterType: waterType,
      capacity: capacity,
      photoKey: photoKey,
      clearPhotoKey: clearPhotoKey,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return null;
      },
      (aquarium) {
        // Update in local state
        final updated = state.aquariums.map((a) {
          if (a.id == aquariumId) {
            return aquarium;
          }
          return a;
        }).toList();
        state = state.copyWith(aquariums: updated);
        return aquarium;
      },
    );
  }

  /// Deletes an aquarium.
  ///
  /// [aquariumId] - The unique identifier of the aquarium to delete.
  ///
  /// Returns true on success, false on failure.
  Future<bool> deleteAquarium(String aquariumId) async {
    final result = await _aquariumRepository.deleteAquarium(aquariumId);

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) {
        // Remove from local state
        final updated = state.aquariums
            .where((a) => a.id != aquariumId)
            .toList();
        state = state.copyWith(aquariums: updated);
        return true;
      },
    );
  }

  /// Clears any error state.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for user's aquariums state.
///
/// Usage:
/// ```dart
/// final aquariumsState = ref.watch(userAquariumsProvider);
/// final aquariums = aquariumsState.aquariums;
/// ```
final userAquariumsProvider =
    StateNotifierProvider<UserAquariumsNotifier, UserAquariumsState>((ref) {
      final aquariumRepository = ref.watch(aquariumRepositoryProvider);
      final syncService = ref.watch(syncServiceProvider);

      return UserAquariumsNotifier(
        aquariumRepository: aquariumRepository,
        syncService: syncService,
      );
    });

// ============================================================================
// Selected Aquarium Provider
// ============================================================================

/// Provider for currently selected aquarium ID.
///
/// Used for filtering fish and feedings by aquarium.
final selectedAquariumIdProvider = StateProvider<String?>((ref) {
  return null;
});

/// Provider for currently selected aquarium.
///
/// Returns null if no aquarium is selected or selected aquarium not found.
final selectedAquariumProvider = Provider<Aquarium?>((ref) {
  final selectedId = ref.watch(selectedAquariumIdProvider);
  if (selectedId == null) return null;

  final state = ref.watch(userAquariumsProvider);
  return state.getById(selectedId);
});

// ============================================================================
// Convenience Providers
// ============================================================================

/// Provider for just the aquariums list.
///
/// Convenience provider for widgets that only need the list.
final aquariumsListProvider = Provider<List<Aquarium>>((ref) {
  return ref.watch(userAquariumsProvider.select((s) => s.aquariums));
});

/// Provider for aquariums count.
final aquariumsCountProvider = Provider<int>((ref) {
  return ref.watch(userAquariumsProvider.select((s) => s.count));
});

/// Provider for checking if user has any aquariums.
final hasAquariumsProvider = Provider<bool>((ref) {
  return ref.watch(userAquariumsProvider.select((s) => s.aquariums.isNotEmpty));
});

/// Provider for aquariums loading state.
final aquariumsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(userAquariumsProvider.select((s) => s.isLoading));
});

/// Provider for aquariums error state.
final aquariumsErrorProvider = Provider<String?>((ref) {
  return ref.watch(userAquariumsProvider.select((s) => s.error));
});

/// Provider for getting a specific aquarium by ID.
///
/// Usage:
/// ```dart
/// final aquarium = ref.watch(aquariumByIdProvider('aquarium-123'));
/// ```
final aquariumByIdProvider = Provider.family<Aquarium?, String>((ref, id) {
  final state = ref.watch(userAquariumsProvider);
  return state.getById(id);
});
