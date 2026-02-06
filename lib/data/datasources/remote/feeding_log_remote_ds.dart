import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/remote/api_client.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';

/// Maximum number of days allowed for date range queries.
///
/// Server enforces a 366-day limit on feeding-logs endpoint.
const int maxFeedingLogDateRangeDays = 366;

/// Remote data source for feeding log API calls.
///
/// Provides methods for fetching and creating feeding logs through the backend API.
/// FeedingLog is immutable - once created, it cannot be edited or deleted.
///
/// All endpoints are prefixed with /aquariums/{aquarium_id}/.
abstract interface class FeedingLogRemoteDataSource {
  /// Fetches feeding logs for an aquarium within a date range.
  ///
  /// [aquariumId] - The ID of the aquarium.
  /// [from] - Start date (inclusive).
  /// [to] - End date (inclusive). Must be within 366 days of [from].
  /// [fishId] - Optional filter by fish ID.
  ///
  /// Returns list of [FeedingLogModel] for the specified range.
  /// Throws [ArgumentError] if date range exceeds 366 days.
  /// Throws [DioException] on network or server errors.
  Future<List<FeedingLogModel>> getFeedingLogs({
    required String aquariumId,
    required DateTime from,
    required DateTime to,
    String? fishId,
  });

  /// Creates a new feeding log.
  ///
  /// [aquariumId] - The ID of the aquarium.
  /// [log] - The feeding log to create.
  ///
  /// Returns the created [FeedingLogModel] with server-assigned fields.
  /// Returns `null` if a 409 Conflict occurs (log already exists).
  /// Throws [DioException] on other network or server errors.
  Future<FeedingLogModel?> createFeedingLog({
    required String aquariumId,
    required FeedingLogModel log,
  });
}

/// Exception thrown when a feeding log already exists (409 Conflict).
class FeedingLogConflictException implements Exception {
  const FeedingLogConflictException({this.message, this.existingLog});

  final String? message;
  final FeedingLogModel? existingLog;

  @override
  String toString() =>
      'FeedingLogConflictException: ${message ?? 'Log already exists'}';
}

/// Implementation of [FeedingLogRemoteDataSource] using Dio HTTP client.
class FeedingLogRemoteDataSourceImpl implements FeedingLogRemoteDataSource {
  FeedingLogRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<FeedingLogModel>> getFeedingLogs({
    required String aquariumId,
    required DateTime from,
    required DateTime to,
    String? fishId,
  }) async {
    // Validate date range (server limit: 366 days)
    final daysDiff = to.difference(from).inDays;
    if (daysDiff > maxFeedingLogDateRangeDays) {
      throw ArgumentError(
        'Date range exceeds maximum of $maxFeedingLogDateRangeDays days. '
        'Requested: $daysDiff days.',
      );
    }

    final queryParams = <String, dynamic>{
      'from': from.toIso8601String().split('T').first,
      'to': to.toIso8601String().split('T').first,
    };

    if (fishId != null) {
      queryParams['fish_id'] = fishId;
    }

    final response = await _dio.get<List<dynamic>>(
      '/aquariums/$aquariumId/feeding-logs',
      queryParameters: queryParams,
    );

    return (response.data ?? [])
        .map((json) => FeedingLogModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FeedingLogModel?> createFeedingLog({
    required String aquariumId,
    required FeedingLogModel log,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/aquariums/$aquariumId/feeding-logs',
        data: log.toSyncJson(),
      );

      return FeedingLogModel.fromJson(response.data!);
    } on DioException catch (e) {
      // Handle 409 Conflict - log already exists
      if (e.response?.statusCode == 409) {
        FeedingLogModel? existingLog;

        // Try to parse existing log from response if provided
        final responseData = e.response?.data;
        if (responseData is Map<String, dynamic>) {
          final existingData = responseData['existing'] ?? responseData['data'];
          if (existingData is Map<String, dynamic>) {
            existingLog = FeedingLogModel.fromJson(existingData);
          }
        }

        throw FeedingLogConflictException(
          message: 'Feeding log already exists for this schedule and date',
          existingLog: existingLog,
        );
      }
      rethrow;
    }
  }
}

/// Provider for [FeedingLogRemoteDataSource].
///
/// Usage:
/// ```dart
/// final logDs = ref.watch(feedingLogRemoteDataSourceProvider);
/// final logs = await logDs.getFeedingLogs(
///   aquariumId: 'aquarium-123',
///   from: DateTime(2025, 1, 1),
///   to: DateTime(2025, 1, 31),
/// );
/// ```
final feedingLogRemoteDataSourceProvider = Provider<FeedingLogRemoteDataSource>(
  (ref) {
    final apiClient = ref.watch(apiClientProvider);
    return FeedingLogRemoteDataSourceImpl(dio: apiClient.dio);
  },
);
