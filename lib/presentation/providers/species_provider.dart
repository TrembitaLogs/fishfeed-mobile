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
  SpeciesListNotifier({
    required SpeciesRemoteDataSource speciesDataSource,
    required SpeciesLocalDataSource localDataSource,
  }) : _speciesDataSource = speciesDataSource,
       _localDataSource = localDataSource,
       super(const SpeciesListState()) {
    loadAllSpecies();
  }

  final SpeciesRemoteDataSource _speciesDataSource;
  final SpeciesLocalDataSource _localDataSource;

  /// All species (used for local filtering).
  List<Species> _allSpecies = [];

  /// Loads all species: instantly from Hive cache, then refreshes from API.
  Future<void> loadAllSpecies() async {
    // 1. Show cached species immediately (no loading spinner)
    final cached = _localDataSource.getAllSpecies();
    if (cached.isNotEmpty) {
      _allSpecies = cached.map((m) => m.toEntity()).toList();
      state = state.copyWith(species: _allSpecies);
    } else {
      state = state.copyWith(isLoading: true);
    }

    // 2. Fetch all pages from API
    try {
      final fetched = <Species>[];
      var page = 1;
      const perPage = 100;

      while (true) {
        final response = await _speciesDataSource.listSpecies(
          page: page,
          perPage: perPage,
        );
        fetched.addAll(response.items.map((dto) => dto.toEntity()));

        if (page >= response.pages) break;
        page++;
      }

      _allSpecies = fetched;
      state = state.copyWith(species: fetched, isLoading: false);

      // 3. Save to Hive for next launch
      for (final species in fetched) {
        await _localDataSource.saveSpecies(SpeciesModel.fromEntity(species));
      }
    } catch (e) {
      // If cache was empty and API failed, use hardcoded fallback
      if (_allSpecies.isEmpty) {
        _allSpecies = SpeciesData.popularSpecies;
        state = state.copyWith(
          species: SpeciesData.popularSpecies,
          isLoading: false,
          error: 'Failed to load species from server. Using offline data.',
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Finds a species by ID from the full unfiltered list.
  ///
  /// Returns null if not found.
  Species? findById(String id) {
    for (final s in _allSpecies) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Searches species by name locally (instant, no API call).
  ///
  /// If query is empty, shows all species.
  void searchSpecies(String query) {
    if (query.isEmpty) {
      state = state.copyWith(species: _allSpecies);
      return;
    }

    final lowerQuery = query.toLowerCase();
    final filtered = _allSpecies
        .where((s) => s.name.toLowerCase().contains(lowerQuery))
        .toList();
    state = state.copyWith(species: filtered);
  }
}

/// Provider for species list state.
final speciesListProvider =
    StateNotifierProvider<SpeciesListNotifier, SpeciesListState>((ref) {
      final speciesDataSource = ref.watch(speciesRemoteDataSourceProvider);
      final localDataSource = ref.watch(speciesLocalDataSourceProvider);
      return SpeciesListNotifier(
        speciesDataSource: speciesDataSource,
        localDataSource: localDataSource,
      );
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
