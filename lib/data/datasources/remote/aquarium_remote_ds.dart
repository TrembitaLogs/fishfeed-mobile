import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/config/api_config.dart';
import 'package:fishfeed/data/datasources/remote/api_client.dart';
import 'package:fishfeed/data/models/aquarium_dto.dart';
import 'package:fishfeed/data/models/feeding_event_dto.dart';
import 'package:fishfeed/data/models/fish_dto.dart';
import 'package:fishfeed/domain/entities/water_type.dart';

/// Remote data source for aquarium API calls.
///
/// Provides methods for CRUD operations on aquariums through the backend API.
abstract interface class AquariumRemoteDataSource {
  /// Creates a new aquarium.
  ///
  /// [name] - The name of the aquarium.
  /// [waterType] - Optional water type (defaults to freshwater on server).
  /// [capacity] - Optional capacity in liters.
  ///
  /// Returns [AquariumDto] with the created aquarium data including server-generated ID.
  /// Throws [DioException] on network or server errors.
  Future<AquariumDto> createAquarium({
    required String name,
    WaterType? waterType,
    double? capacity,
  });

  /// Gets all aquariums for the authenticated user.
  ///
  /// Returns list of [AquariumDto] sorted by creation date (newest first).
  /// Throws [DioException] on network or server errors.
  Future<List<AquariumDto>> getAquariums();

  /// Gets a specific aquarium by ID.
  ///
  /// [aquariumId] - The unique identifier of the aquarium.
  ///
  /// Returns [AquariumDto] if found.
  /// Throws [DioException] with 404 if not found.
  Future<AquariumDto> getAquariumById(String aquariumId);

  /// Updates an existing aquarium.
  ///
  /// [aquariumId] - The unique identifier of the aquarium to update.
  /// [name] - Optional new name.
  /// [waterType] - Optional new water type.
  /// [capacity] - Optional new capacity.
  /// [imageUrl] - Optional new image URL.
  ///
  /// Returns updated [AquariumDto].
  /// Throws [DioException] on network or server errors.
  Future<AquariumDto> updateAquarium({
    required String aquariumId,
    String? name,
    WaterType? waterType,
    double? capacity,
    String? imageUrl,
  });

  /// Deletes an aquarium.
  ///
  /// [aquariumId] - The unique identifier of the aquarium to delete.
  ///
  /// Throws [DioException] on network or server errors.
  Future<void> deleteAquarium(String aquariumId);

  /// Gets all feeding events for an aquarium.
  ///
  /// [aquariumId] - The unique identifier of the aquarium.
  ///
  /// Returns list of [FeedingEventDto] for the aquarium.
  /// Throws [DioException] on network or server errors.
  Future<List<FeedingEventDto>> getFeedingEvents(String aquariumId);

  /// Gets today's feeding events for an aquarium.
  ///
  /// [aquariumId] - The unique identifier of the aquarium.
  ///
  /// Returns list of [FeedingEventDto] scheduled for today.
  /// Throws [DioException] on network or server errors.
  Future<List<FeedingEventDto>> getTodayFeedingEvents(String aquariumId);

  /// Gets all fish for an aquarium.
  ///
  /// [aquariumId] - The unique identifier of the aquarium.
  ///
  /// Returns list of [FishDto] for the aquarium.
  /// Throws [DioException] on network or server errors.
  Future<List<FishDto>> getFish(String aquariumId);

  /// Creates a new fish in an aquarium.
  ///
  /// [aquariumId] - The unique identifier of the aquarium.
  /// [speciesId] - The species ID of the fish.
  /// [quantity] - Number of fish (default 1).
  /// [customName] - Optional custom name for the fish.
  /// [addedVia] - How the fish was added (default 'manual').
  ///
  /// Returns [FishDto] with the created fish data.
  /// Throws [DioException] on network or server errors.
  Future<FishDto> createFish({
    required String aquariumId,
    required String speciesId,
    int quantity = 1,
    String? customName,
    String addedVia = 'manual',
  });

  /// Updates an existing fish.
  ///
  /// [fishId] - The unique identifier of the fish to update.
  /// [quantity] - Optional new quantity.
  /// [customName] - Optional new custom name.
  ///
  /// Returns updated [FishDto].
  /// Throws [DioException] on network or server errors.
  Future<FishDto> updateFish({
    required String fishId,
    int? quantity,
    String? customName,
  });

  /// Deletes a fish.
  ///
  /// [fishId] - The unique identifier of the fish to delete.
  ///
  /// Throws [DioException] on network or server errors.
  Future<void> deleteFish(String fishId);
}

/// Implementation of [AquariumRemoteDataSource] using Dio HTTP client.
class AquariumRemoteDataSourceImpl implements AquariumRemoteDataSource {
  AquariumRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<AquariumDto> createAquarium({
    required String name,
    WaterType? waterType,
    double? capacity,
  }) async {
    final data = <String, dynamic>{'name': name};

    if (waterType != null) {
      data['water_type'] = waterType.name;
    }
    if (capacity != null) {
      data['capacity'] = capacity;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.aquariums,
      data: data,
    );

    return AquariumDto.fromJson(response.data!);
  }

  @override
  Future<List<AquariumDto>> getAquariums() async {
    final response = await _dio.get<List<dynamic>>(ApiEndpoints.aquariums);

    return (response.data ?? [])
        .map((json) => AquariumDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AquariumDto> getAquariumById(String aquariumId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiEndpoints.aquariums}/$aquariumId',
    );

    return AquariumDto.fromJson(response.data!);
  }

  @override
  Future<AquariumDto> updateAquarium({
    required String aquariumId,
    String? name,
    WaterType? waterType,
    double? capacity,
    String? imageUrl,
  }) async {
    final data = <String, dynamic>{};

    if (name != null) data['name'] = name;
    if (waterType != null) data['water_type'] = waterType.name;
    if (capacity != null) data['capacity'] = capacity;
    if (imageUrl != null) data['image_url'] = imageUrl;

    final response = await _dio.put<Map<String, dynamic>>(
      '${ApiEndpoints.aquariums}/$aquariumId',
      data: data,
    );

    return AquariumDto.fromJson(response.data!);
  }

  @override
  Future<void> deleteAquarium(String aquariumId) async {
    await _dio.delete<void>('${ApiEndpoints.aquariums}/$aquariumId');
  }

  @override
  Future<List<FeedingEventDto>> getFeedingEvents(String aquariumId) async {
    final response = await _dio.get<List<dynamic>>(
      '${ApiEndpoints.aquariums}/$aquariumId/events',
    );

    return (response.data ?? [])
        .map((json) => FeedingEventDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<FeedingEventDto>> getTodayFeedingEvents(String aquariumId) async {
    final response = await _dio.get<List<dynamic>>(
      '${ApiEndpoints.aquariums}/$aquariumId/events/today',
    );

    return (response.data ?? [])
        .map((json) => FeedingEventDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<FishDto>> getFish(String aquariumId) async {
    final response = await _dio.get<List<dynamic>>(
      '${ApiEndpoints.aquariums}/$aquariumId/fish',
    );

    return (response.data ?? [])
        .map((json) => FishDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FishDto> createFish({
    required String aquariumId,
    required String speciesId,
    int quantity = 1,
    String? customName,
    String addedVia = 'manual',
  }) async {
    final data = <String, dynamic>{
      'species_id': speciesId,
      'quantity': quantity,
      'added_via': addedVia,
    };

    if (customName != null) {
      data['custom_name'] = customName;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiEndpoints.aquariums}/$aquariumId/fish',
      data: data,
    );

    return FishDto.fromJson(response.data!);
  }

  @override
  Future<FishDto> updateFish({
    required String fishId,
    int? quantity,
    String? customName,
  }) async {
    final data = <String, dynamic>{};

    if (quantity != null) data['quantity'] = quantity;
    if (customName != null) data['custom_name'] = customName;

    final response = await _dio.patch<Map<String, dynamic>>(
      '/fish/$fishId',
      data: data,
    );

    return FishDto.fromJson(response.data!);
  }

  @override
  Future<void> deleteFish(String fishId) async {
    await _dio.delete<void>('/fish/$fishId');
  }
}

/// Provider for [AquariumRemoteDataSource].
///
/// Usage:
/// ```dart
/// final aquariumDs = ref.watch(aquariumRemoteDataSourceProvider);
/// final aquariums = await aquariumDs.getAquariums();
/// ```
final aquariumRemoteDataSourceProvider = Provider<AquariumRemoteDataSource>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return AquariumRemoteDataSourceImpl(dio: apiClient.dio);
});
