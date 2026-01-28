import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/config/api_config.dart';
import 'package:fishfeed/data/datasources/remote/api_client.dart';
import 'package:fishfeed/data/models/species_dto.dart';

/// Remote data source for species API calls.
///
/// Provides methods to fetch fish species from the backend.
abstract interface class SpeciesRemoteDataSource {
  /// Gets a list of popular species for onboarding.
  ///
  /// Returns up to 20 popular species suitable for beginners.
  Future<List<SpeciesDto>> getPopularSpecies();

  /// Searches species by name.
  ///
  /// [query] - Search query (minimum 2 characters).
  /// Returns list of matching species.
  Future<List<SpeciesDto>> searchSpecies(String query);

  /// Gets a paginated list of all species.
  ///
  /// [page] - Page number (1-based).
  /// [perPage] - Items per page (default 20, max 100).
  /// [careLevel] - Optional filter by care level.
  /// [waterType] - Optional filter by water type.
  Future<SpeciesListResponseDto> listSpecies({
    int page = 1,
    int perPage = 20,
    String? careLevel,
    String? waterType,
  });

  /// Gets a specific species by ID.
  Future<SpeciesDto> getSpeciesById(String speciesId);
}

/// Implementation of [SpeciesRemoteDataSource] using Dio HTTP client.
class SpeciesRemoteDataSourceImpl implements SpeciesRemoteDataSource {
  SpeciesRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<SpeciesDto>> getPopularSpecies() async {
    final response = await _dio.get<List<dynamic>>(
      ApiEndpoints.speciesPopular,
    );

    return (response.data ?? [])
        .map((json) => SpeciesDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<SpeciesDto>> searchSpecies(String query) async {
    final response = await _dio.get<List<dynamic>>(
      ApiEndpoints.speciesSearch,
      queryParameters: {'q': query},
    );

    return (response.data ?? [])
        .map((json) => SpeciesDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SpeciesListResponseDto> listSpecies({
    int page = 1,
    int perPage = 20,
    String? careLevel,
    String? waterType,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };

    if (careLevel != null) queryParams['care_level'] = careLevel;
    if (waterType != null) queryParams['water_type'] = waterType;

    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.speciesList,
      queryParameters: queryParams,
    );

    return SpeciesListResponseDto.fromJson(response.data!);
  }

  @override
  Future<SpeciesDto> getSpeciesById(String speciesId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiEndpoints.speciesList}/$speciesId',
    );

    return SpeciesDto.fromJson(response.data!);
  }
}

/// Provider for [SpeciesRemoteDataSource].
///
/// Usage:
/// ```dart
/// final speciesDs = ref.watch(speciesRemoteDataSourceProvider);
/// final popular = await speciesDs.getPopularSpecies();
/// ```
final speciesRemoteDataSourceProvider = Provider<SpeciesRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SpeciesRemoteDataSourceImpl(dio: apiClient.dio);
});
