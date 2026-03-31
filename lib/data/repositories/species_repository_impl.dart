import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/local/species_local_ds.dart';
import 'package:fishfeed/data/datasources/remote/api_client.dart';
import 'package:fishfeed/data/datasources/remote/species_remote_ds.dart';
import 'package:fishfeed/data/models/species_model.dart';
import 'package:fishfeed/domain/entities/species.dart';
import 'package:fishfeed/domain/repositories/species_repository.dart';

/// Implementation of [SpeciesRepository] using local Hive cache and remote API.
class SpeciesRepositoryImpl implements SpeciesRepository {
  SpeciesRepositoryImpl({
    required SpeciesLocalDataSource localDataSource,
    required SpeciesRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final SpeciesLocalDataSource _localDataSource;
  final SpeciesRemoteDataSource _remoteDataSource;

  @override
  List<Species> getCachedSpecies() {
    return _localDataSource.getAllSpecies().map((m) => m.toEntity()).toList();
  }

  @override
  Species? getCachedSpeciesById(String speciesId) {
    return _localDataSource.getSpeciesById(speciesId)?.toEntity();
  }

  @override
  Future<List<Species>> fetchAllSpecies() async {
    final fetched = <Species>[];
    var page = 1;
    const perPage = 100;

    while (true) {
      final response = await _remoteDataSource.listSpecies(
        page: page,
        perPage: perPage,
      );
      fetched.addAll(response.items.map((dto) => dto.toEntity()));

      if (page >= response.pages) break;
      page++;
    }

    // Save to local cache
    for (final species in fetched) {
      await _localDataSource.saveSpecies(SpeciesModel.fromEntity(species));
    }

    return fetched;
  }

  @override
  Future<Species> fetchSpeciesById(String speciesId) async {
    final dto = await _remoteDataSource.getSpeciesById(speciesId);
    final species = dto.toEntity();

    // Save to local cache
    await _localDataSource.saveSpecies(SpeciesModel.fromEntity(species));

    return species;
  }

  @override
  Future<void> cacheSpecies(Species species) async {
    await _localDataSource.saveSpecies(SpeciesModel.fromEntity(species));
  }
}

/// Provider for [SpeciesRepository].
final speciesRepositoryProvider = Provider<SpeciesRepository>((ref) {
  final localDs = ref.watch(speciesLocalDataSourceProvider);
  final remoteDs = ref.watch(speciesRemoteDataSourceProvider);
  return SpeciesRepositoryImpl(
    localDataSource: localDs,
    remoteDataSource: remoteDs,
  );
});
