import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/remote/api_client.dart';

/// API endpoints for push notification token management.
abstract final class PushEndpoints {
  static const String token = '/push/token';
}

/// Remote data source for push notification token API calls.
///
/// Provides methods for registering and unregistering FCM/APNs tokens
/// on the backend server.
abstract interface class PushRemoteDataSource {
  /// Registers a push token on the backend.
  ///
  /// [token] is the FCM token (Android) or APNs token (iOS).
  /// [platform] is the device platform ('android' or 'ios').
  ///
  /// Throws [DioException] on network or server errors.
  Future<void> registerToken({required String token, required String platform});

  /// Unregisters the push token from the backend.
  ///
  /// Should be called on logout to stop receiving push notifications.
  ///
  /// Throws [DioException] on network or server errors.
  Future<void> unregisterToken();
}

/// Implementation of [PushRemoteDataSource] using Dio HTTP client.
class PushRemoteDataSourceImpl implements PushRemoteDataSource {
  PushRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<void> registerToken({
    required String token,
    required String platform,
  }) async {
    await _dio.post<void>(
      PushEndpoints.token,
      data: {'token': token, 'platform': platform},
    );
  }

  @override
  Future<void> unregisterToken() async {
    await _dio.delete<void>(PushEndpoints.token);
  }
}

/// Provider for [PushRemoteDataSource].
///
/// Usage:
/// ```dart
/// final pushRemoteDs = ref.watch(pushRemoteDataSourceProvider);
/// await pushRemoteDs.registerToken(token: fcmToken, platform: 'android');
/// ```
final pushRemoteDataSourceProvider = Provider<PushRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PushRemoteDataSourceImpl(dio: apiClient.dio);
});
