import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/species_model.dart';

/// Local data source for species cache operations.
///
/// Provides caching for species data fetched from the server.
/// Species are cached indefinitely as they rarely change.
abstract interface class SpeciesLocalDataSource {
  /// Gets a species by ID from the local cache.
  ///
  /// Returns null if species is not cached.
  SpeciesModel? getSpeciesById(String speciesId);

  /// Saves a species to the local cache.
  Future<void> saveSpecies(SpeciesModel species);

  /// Gets all cached species.
  List<SpeciesModel> getAllSpecies();

  /// Clears all cached species.
  Future<void> clearAll();
}

/// Implementation of [SpeciesLocalDataSource] using Hive.
class SpeciesLocalDataSourceImpl implements SpeciesLocalDataSource {
  @override
  SpeciesModel? getSpeciesById(String speciesId) {
    return HiveBoxes.species.get(speciesId);
  }

  @override
  Future<void> saveSpecies(SpeciesModel species) async {
    await HiveBoxes.species.put(species.id, species);
  }

  @override
  List<SpeciesModel> getAllSpecies() {
    return HiveBoxes.species.values.whereType<SpeciesModel>().toList();
  }

  @override
  Future<void> clearAll() async {
    await HiveBoxes.species.clear();
  }
}

/// Provider for [SpeciesLocalDataSource].
final speciesLocalDataSourceProvider = Provider<SpeciesLocalDataSource>((ref) {
  return SpeciesLocalDataSourceImpl();
});
