import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/remote/api_client.dart';
import 'package:fishfeed/data/models/schedule_model.dart';

/// Remote data source for feeding schedule API calls.
///
/// Provides methods for CRUD operations on schedules through the backend API.
/// All endpoints are prefixed with /aquariums/{aquarium_id}/.
abstract interface class ScheduleRemoteDataSource {
  /// Fetches all schedules for an aquarium.
  ///
  /// [aquariumId] - The ID of the aquarium.
  ///
  /// Returns list of [ScheduleModel] for the aquarium.
  /// Throws [DioException] on network or server errors.
  Future<List<ScheduleModel>> getSchedules({required String aquariumId});

  /// Creates a new schedule.
  ///
  /// [aquariumId] - The ID of the aquarium.
  /// [schedule] - The schedule to create.
  ///
  /// Returns the created [ScheduleModel] with server-assigned fields.
  /// Throws [DioException] on network or server errors.
  Future<ScheduleModel> createSchedule({
    required String aquariumId,
    required ScheduleModel schedule,
  });

  /// Generates schedules for a fish based on species feeding requirements.
  ///
  /// [aquariumId] - The ID of the aquarium.
  /// [fishId] - The ID of the fish to generate schedules for.
  ///
  /// Returns a LIST of [ScheduleModel] - multiple schedules may be created
  /// if feeding_frequency >= 2 (e.g., 2x/day creates 2 schedules with different times).
  /// Throws [DioException] on network or server errors.
  Future<List<ScheduleModel>> generateSchedules({
    required String aquariumId,
    required String fishId,
  });

  /// Updates an existing schedule.
  ///
  /// [aquariumId] - The ID of the aquarium.
  /// [scheduleId] - The ID of the schedule to update.
  /// [time] - Optional new time in "HH:mm" format.
  /// [intervalDays] - Optional new interval in days.
  /// [foodType] - Optional new food type.
  /// [portionHint] - Optional new portion hint.
  /// [active] - Optional new active status.
  ///
  /// Returns the updated [ScheduleModel].
  /// Throws [DioException] on network or server errors.
  Future<ScheduleModel> updateSchedule({
    required String aquariumId,
    required String scheduleId,
    String? time,
    int? intervalDays,
    String? foodType,
    String? portionHint,
    bool? active,
  });

  /// Deletes a schedule.
  ///
  /// [aquariumId] - The ID of the aquarium.
  /// [scheduleId] - The ID of the schedule to delete.
  ///
  /// Throws [DioException] on network or server errors.
  Future<void> deleteSchedule({
    required String aquariumId,
    required String scheduleId,
  });
}

/// Implementation of [ScheduleRemoteDataSource] using Dio HTTP client.
class ScheduleRemoteDataSourceImpl implements ScheduleRemoteDataSource {
  ScheduleRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<ScheduleModel>> getSchedules({required String aquariumId}) async {
    final response = await _dio.get<List<dynamic>>(
      '/aquariums/$aquariumId/schedules',
    );

    return (response.data ?? [])
        .map((json) => ScheduleModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ScheduleModel> createSchedule({
    required String aquariumId,
    required ScheduleModel schedule,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/aquariums/$aquariumId/schedules',
      data: schedule.toSyncJson(),
    );

    return ScheduleModel.fromJson(response.data!);
  }

  @override
  Future<List<ScheduleModel>> generateSchedules({
    required String aquariumId,
    required String fishId,
  }) async {
    final response = await _dio.post<List<dynamic>>(
      '/aquariums/$aquariumId/schedules/generate',
      data: {'fish_id': fishId},
    );

    // Server returns an ARRAY of schedules (multiple schedules for feeding_frequency >= 2)
    return (response.data ?? [])
        .map((json) => ScheduleModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ScheduleModel> updateSchedule({
    required String aquariumId,
    required String scheduleId,
    String? time,
    int? intervalDays,
    String? foodType,
    String? portionHint,
    bool? active,
  }) async {
    final data = <String, dynamic>{};

    if (time != null) data['time'] = time;
    if (intervalDays != null) data['interval_days'] = intervalDays;
    if (foodType != null) data['food_type'] = foodType;
    if (portionHint != null) data['portion_hint'] = portionHint;
    if (active != null) data['active'] = active;

    final response = await _dio.patch<Map<String, dynamic>>(
      '/aquariums/$aquariumId/schedules/$scheduleId',
      data: data,
    );

    return ScheduleModel.fromJson(response.data!);
  }

  @override
  Future<void> deleteSchedule({
    required String aquariumId,
    required String scheduleId,
  }) async {
    await _dio.delete<void>('/aquariums/$aquariumId/schedules/$scheduleId');
  }
}

/// Provider for [ScheduleRemoteDataSource].
///
/// Usage:
/// ```dart
/// final scheduleDs = ref.watch(scheduleRemoteDataSourceProvider);
/// final schedules = await scheduleDs.getSchedules(aquariumId: 'aquarium-123');
/// ```
final scheduleRemoteDataSourceProvider = Provider<ScheduleRemoteDataSource>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return ScheduleRemoteDataSourceImpl(dio: apiClient.dio);
});
