import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/constants/species_data.dart';
import 'package:fishfeed/data/datasources/local/species_local_ds.dart';
import 'package:fishfeed/data/datasources/remote/species_remote_ds.dart';
import 'package:fishfeed/data/models/species_model.dart';
import 'package:fishfeed/domain/entities/species.dart';

/// State for species list.
class SpeciesListState {
  const SpeciesListState({
    this.species = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Species> species;
  final bool isLoading;
  final String? error;

  SpeciesListState copyWith({
    List<Species>? species,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SpeciesListState(
      species: species ?? this.species,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for managing species list state.
///
/// Fetches species from the API and provides search functionality.
class SpeciesListNotifier extends StateNotifier<SpeciesListState> {
  SpeciesListNotifier({required SpeciesRemoteDataSource speciesDataSource})
    : _speciesDataSource = speciesDataSource,
      super(const SpeciesListState()) {
    loadPopularSpecies();
  }

  final SpeciesRemoteDataSource _speciesDataSource;

  /// Loads popular species from the API.
  Future<void> loadPopularSpecies() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final speciesDtos = await _speciesDataSource.getPopularSpecies();
      final speciesList = speciesDtos.map((dto) => dto.toEntity()).toList();

      state = state.copyWith(species: speciesList, isLoading: false);
    } catch (e) {
      // Fallback to hardcoded data on error
      state = state.copyWith(
        species: SpeciesData.popularSpecies,
        isLoading: false,
        error: 'Failed to load species from server. Using offline data.',
      );
    }
  }

  /// Searches species by name.
  ///
  /// If query is empty, returns popular species.
  /// Falls back to local search on API error.
  Future<void> searchSpecies(String query) async {
    if (query.isEmpty) {
      await loadPopularSpecies();
      return;
    }

    // Need at least 2 characters for API search
    if (query.length < 2) {
      // Use local filtering for short queries
      final filtered = SpeciesData.searchByName(query);
      state = state.copyWith(species: filtered);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final speciesDtos = await _speciesDataSource.searchSpecies(query);
      final speciesList = speciesDtos.map((dto) => dto.toEntity()).toList();

      state = state.copyWith(species: speciesList, isLoading: false);
    } catch (e) {
      // Fallback to local search on error
      final filtered = SpeciesData.searchByName(query);
      state = state.copyWith(
        species: filtered,
        isLoading: false,
        error: 'Search failed. Using offline results.',
      );
    }
  }
}

/// Provider for species list state.
final speciesListProvider =
    StateNotifierProvider<SpeciesListNotifier, SpeciesListState>((ref) {
      final speciesDataSource = ref.watch(speciesRemoteDataSourceProvider);
      return SpeciesListNotifier(speciesDataSource: speciesDataSource);
    });

/// Provider for current species list (convenience accessor).
final availableSpeciesProvider = Provider<List<Species>>((ref) {
  return ref.watch(speciesListProvider).species;
});

/// Provider for species loading state.
final speciesLoadingProvider = Provider<bool>((ref) {
  return ref.watch(speciesListProvider).isLoading;
});

/// Cache for species fetched by ID.
///
/// Stores species that have been fetched from the server to avoid
/// repeated network calls.
final _speciesCacheProvider = StateProvider<Map<String, Species>>((ref) => {});

/// Provider to get a species by ID.
///
/// First checks local Hive cache, then in-memory cache, then fetches from server.
/// Returns null if species cannot be found.
///
/// Usage:
/// ```dart
/// final speciesAsync = ref.watch(speciesByIdProvider('bristlenose-pleco'));
/// speciesAsync.when(
///   data: (species) => Text(species?.name ?? 'Unknown'),
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Error'),
/// );
/// ```
final speciesByIdProvider = FutureProvider.family<Species?, String>((
  ref,
  speciesId,
) async {
  if (speciesId.isEmpty) return null;

  // 1. Check in-memory cache first
  final memoryCache = ref.read(_speciesCacheProvider);
  if (memoryCache.containsKey(speciesId)) {
    return memoryCache[speciesId];
  }

  // 2. Check local Hive cache
  final localDs = ref.read(speciesLocalDataSourceProvider);
  final cachedModel = localDs.getSpeciesById(speciesId);
  if (cachedModel != null) {
    final species = cachedModel.toEntity();
    // Store in memory cache for faster future access
    ref.read(_speciesCacheProvider.notifier).state = {
      ...memoryCache,
      speciesId: species,
    };
    return species;
  }

  // 3. Check hardcoded SpeciesData as fallback
  final hardcoded = SpeciesData.findById(speciesId);
  if (hardcoded.id == speciesId) {
    ref.read(_speciesCacheProvider.notifier).state = {
      ...memoryCache,
      speciesId: hardcoded,
    };
    return hardcoded;
  }

  // 4. Fetch from server
  try {
    final remoteDs = ref.read(speciesRemoteDataSourceProvider);
    final dto = await remoteDs.getSpeciesById(speciesId);
    final species = dto.toEntity();

    // Save to local cache
    await localDs.saveSpecies(SpeciesModel.fromEntity(species));

    // Save to memory cache
    ref.read(_speciesCacheProvider.notifier).state = {
      ...ref.read(_speciesCacheProvider),
      speciesId: species,
    };

    return species;
  } catch (e) {
    // Species not found on server
    return null;
  }
});

/// Synchronous provider to get species name by ID.
///
/// Returns the species name if cached, otherwise returns a formatted version
/// of the speciesId (e.g., "bristlenose-pleco" -> "Bristlenose Pleco").
/// Use this when you need a name immediately without async handling.
final speciesNameByIdProvider = Provider.family<String, String>((
  ref,
  speciesId,
) {
  if (speciesId.isEmpty) return 'Feeding';

  // Check memory cache
  final memoryCache = ref.read(_speciesCacheProvider);
  if (memoryCache.containsKey(speciesId)) {
    return memoryCache[speciesId]!.name;
  }

  // Check local cache
  final localDs = ref.read(speciesLocalDataSourceProvider);
  final cachedModel = localDs.getSpeciesById(speciesId);
  if (cachedModel != null) {
    return cachedModel.name;
  }

  // Check hardcoded data
  final hardcoded = SpeciesData.findById(speciesId);
  if (hardcoded.id == speciesId) {
    return hardcoded.name;
  }

  // Not found - format speciesId as readable name
  // "bristlenose-pleco" -> "Bristlenose Pleco"
  return _formatSpeciesId(speciesId);
});

/// Formats a speciesId as a readable name.
///
/// Example: "bristlenose-pleco" -> "Bristlenose Pleco"
String _formatSpeciesId(String speciesId) {
  return speciesId
      .split(RegExp(r'[-_]'))
      .map(
        (word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '',
      )
      .join(' ');
}
