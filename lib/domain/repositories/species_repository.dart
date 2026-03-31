import 'package:fishfeed/domain/entities/species.dart';

/// Repository interface for species data operations.
///
/// Provides a clean API for species lookup following Clean Architecture.
/// Handles caching and remote fetching transparently.
abstract interface class SpeciesRepository {
  /// Gets all species from local cache.
  ///
  /// Returns an empty list if cache is empty.
  List<Species> getCachedSpecies();

  /// Gets a species by ID from local cache.
  ///
  /// Returns `null` if not cached.
  Species? getCachedSpeciesById(String speciesId);

  /// Fetches all species from remote API with pagination.
  ///
  /// Saves fetched species to local cache.
  /// Returns the full list of species.
  Future<List<Species>> fetchAllSpecies();

  /// Fetches a specific species by ID from remote API.
  ///
  /// Saves the result to local cache.
  Future<Species> fetchSpeciesById(String speciesId);

  /// Saves a species to local cache.
  Future<void> cacheSpecies(Species species);
}
