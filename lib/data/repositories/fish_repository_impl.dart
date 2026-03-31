import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/domain/repositories/fish_repository.dart';

/// Implementation of [FishRepository] using local Hive storage.
///
/// All reads are local-only. Server communication happens
/// exclusively through [SyncService].
class FishRepositoryImpl implements FishRepository {
  FishRepositoryImpl({required FishLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final FishLocalDataSource _localDataSource;

  @override
  List<Fish> getAllFish() {
    return _localDataSource.getAllFish().map((m) => m.toEntity()).toList();
  }

  @override
  Fish? getFishById(String id) {
    return _localDataSource.getFishById(id)?.toEntity();
  }

  @override
  List<Fish> getFishByAquariumId(String aquariumId) {
    final fishModels = _localDataSource.getFishByAquariumId(aquariumId);

    // Deduplicate by ID (in case of Hive file corruption)
    final seen = <String>{};
    final uniqueFish = <Fish>[];
    for (final model in fishModels) {
      if (seen.add(model.id)) {
        uniqueFish.add(model.toEntity());
      }
    }
    return uniqueFish;
  }

  @override
  Future<void> saveFish(Fish fish) async {
    final model = FishModel.fromEntity(fish);
    await _localDataSource.saveFish(model);
  }

  @override
  Future<bool> updateFish(Fish fish) async {
    final model = FishModel.fromEntity(fish);
    return _localDataSource.updateFish(model);
  }

  @override
  Future<void> softDelete(String id) async {
    await _localDataSource.softDelete(id);
  }
}

/// Provider for [FishRepository].
final fishRepositoryProvider = Provider<FishRepository>((ref) {
  final fishDs = ref.watch(fishLocalDataSourceProvider);
  return FishRepositoryImpl(localDataSource: fishDs);
});
