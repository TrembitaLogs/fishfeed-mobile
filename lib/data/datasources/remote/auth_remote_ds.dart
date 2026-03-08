import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/datasources/remote/api_client.dart';
import 'package:fishfeed/data/models/auth_response_dto.dart';
import 'package:fishfeed/data/models/token_pair_dto.dart';

/// API endpoints for authentication.
abstract final class AuthEndpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String oauth = '/auth/oauth';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
}

/// Remote data source for authentication API calls.
///
/// Provides methods for user registration, login, OAuth, token refresh,
/// and logout operations.
abstract interface class AuthRemoteDataSource {
  /// Registers a new user with email and password.
  ///
  /// Returns [AuthResponseDto] with user data and tokens on success.
  /// Throws [DioException] on network or server errors.
  Future<AuthResponseDto> register({
    required String email,
    required String password,
  });

  /// Authenticates a user with email and password.
  ///
  /// Returns [AuthResponseDto] with user data and tokens on success.
  /// Throws [DioException] on network or server errors.
  Future<AuthResponseDto> login({
    required String email,
    required String password,
  });

  /// Authenticates a user via OAuth provider.
  ///
  /// [provider] is the OAuth provider name (e.g., 'google', 'apple').
  /// [idToken] is the OAuth ID token from the provider.
  ///
  /// Returns [AuthResponseDto] with user data and tokens on success.
  /// Throws [DioException] on network or server errors.
  Future<AuthResponseDto> oauthLogin({
    required String provider,
    required String idToken,
  });

  /// Refreshes the access token using a refresh token.
  ///
  /// Returns [TokenPairDto] with new access and refresh tokens.
  /// Throws [DioException] on network or server errors.
  Future<TokenPairDto> refreshToken({required String refreshToken});

  /// Logs out the user by invalidating the refresh token.
  ///
  /// Throws [DioException] on network or server errors.
  Future<void> logout({required String refreshToken});
}

/// Implementation of [AuthRemoteDataSource] using Dio HTTP client.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<AuthResponseDto> register({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      AuthEndpoints.register,
      data: {'email': email, 'password': password},
    );

    return AuthResponseDto.fromJson(response.data!);
  }

  @override
  Future<AuthResponseDto> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      AuthEndpoints.login,
      data: {'email': email, 'password': password},
    );

    return AuthResponseDto.fromJson(response.data!);
  }

  @override
  Future<AuthResponseDto> oauthLogin({
    required String provider,
    required String idToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      AuthEndpoints.oauth,
      data: {'provider': provider, 'token': idToken},
    );

    return AuthResponseDto.fromJson(response.data!);
  }

  @override
  Future<TokenPairDto> refreshToken({required String refreshToken}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      AuthEndpoints.refresh,
      data: {'refresh_token': refreshToken},
      options: Options(headers: {'Authorization': null}),
    );

    return TokenPairDto.fromJson(response.data!);
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    await _dio.post<void>(
      AuthEndpoints.logout,
      data: {'refresh_token': refreshToken},
    );
  }
}

/// Provider for [AuthRemoteDataSource].
///
/// Usage:
/// ```dart
/// final authRemoteDs = ref.watch(authRemoteDataSourceProvider);
/// final response = await authRemoteDs.login(email: email, password: password);
/// ```
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(dio: apiClient.dio);
});
