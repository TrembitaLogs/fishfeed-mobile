import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/config/api_config.dart';
import 'package:fishfeed/data/datasources/remote/api_client.dart';
import 'package:fishfeed/data/models/ai_scan_result.dart';

/// Remote data source for AI fish scanning API calls.
///
/// Provides methods to upload fish images for AI-powered species detection.
abstract interface class AiScanRemoteDataSource {
  /// Scans a fish image and returns the detected species.
  ///
  /// [imageBytes] - Compressed image bytes to upload.
  /// [filename] - Optional filename for the uploaded image.
  ///
  /// Returns [AiScanResult] with detected species and confidence.
  /// Throws [DioException] on network or server errors.
  Future<AiScanResult> scanFishImage({
    required Uint8List imageBytes,
    String filename = 'fish.jpg',
  });
}

/// Implementation of [AiScanRemoteDataSource] using Dio HTTP client.
class AiScanRemoteDataSourceImpl implements AiScanRemoteDataSource {
  AiScanRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<AiScanResult> scanFishImage({
    required Uint8List imageBytes,
    String filename = 'fish.jpg',
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        imageBytes,
        filename: filename,
        contentType: DioMediaType.parse('image/jpeg'),
      ),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.aiScan,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: ApiScanTimeouts.scanTimeout,
        receiveTimeout: ApiScanTimeouts.scanTimeout,
      ),
    );

    return AiScanResult.fromJson(response.data!);
  }
}

/// Provider for [AiScanRemoteDataSource].
///
/// Usage:
/// ```dart
/// final aiScanDs = ref.watch(aiScanRemoteDataSourceProvider);
/// final result = await aiScanDs.scanFishImage(imageBytes: bytes);
/// ```
final aiScanRemoteDataSourceProvider = Provider<AiScanRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AiScanRemoteDataSourceImpl(dio: apiClient.dio);
});
