import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/remote/api_client.dart';
import 'package:fishfeed/data/models/user_dto.dart';

/// API endpoints for user operations.
abstract final class UserEndpoints {
  static const String me = '/users/me';
  static const String avatar = '/users/me/avatar';
}

/// Remote data source for user API operations.
///
/// Provides methods for user profile operations such as
/// updating profile information and avatar.
abstract interface class UserRemoteDataSource {
  /// Updates the current user's profile.
  ///
  /// [displayName] - Optional new display name.
  ///
  /// Returns [UserDto] with updated user data on success.
  /// Throws [DioException] on network or server errors.
  Future<UserDto> updateProfile({String? displayName});

  /// Uploads a new avatar for the current user.
  ///
  /// [avatarFile] - The image file to upload as avatar.
  ///
  /// Returns [UserDto] with updated user data including new avatar URL.
  /// Throws [DioException] on network or server errors.
  Future<UserDto> uploadAvatar({required File avatarFile});
}

/// Implementation of [UserRemoteDataSource] using Dio HTTP client.
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  UserRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<UserDto> updateProfile({String? displayName}) async {
    final data = <String, dynamic>{};

    if (displayName != null) {
      data['display_name'] = displayName;
    }

    final response = await _dio.put<Map<String, dynamic>>(
      UserEndpoints.me,
      data: data,
    );

    return UserDto.fromJson(response.data!);
  }

  @override
  Future<UserDto> uploadAvatar({required File avatarFile}) async {
    final fileName = avatarFile.path.split('/').last;
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        avatarFile.path,
        filename: fileName,
      ),
    });

    final response = await _dio.put<Map<String, dynamic>>(
      UserEndpoints.avatar,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return UserDto.fromJson(response.data!);
  }
}

/// Provider for [UserRemoteDataSource].
final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserRemoteDataSourceImpl(dio: apiClient.dio);
});
