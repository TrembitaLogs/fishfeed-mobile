import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Configuration for retry behavior.
class RetryConfig {
  const RetryConfig({
    this.maxRetries = 3,
    this.retryableStatusCodes = const [408, 429, 500, 502, 503, 504],
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 8),
    this.backoffMultiplier = 2.0,
  });

  /// Maximum number of retry attempts.
  final int maxRetries;

  /// HTTP status codes that should trigger a retry.
  final List<int> retryableStatusCodes;

  /// Initial delay before the first retry.
  final Duration initialDelay;

  /// Maximum delay between retries.
  final Duration maxDelay;

  /// Multiplier for exponential backoff.
  final double backoffMultiplier;
}

/// Interface for checking network connectivity.
///
/// Allows for easy mocking in tests.
abstract class ConnectivityChecker {
  /// Returns true if the device has an active network connection.
  Future<bool> hasConnection();
}

/// Default implementation using connectivity_plus.
class DefaultConnectivityChecker implements ConnectivityChecker {
  DefaultConnectivityChecker({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> hasConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return !results.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('RetryInterceptor: Connectivity check failed: $e');
      // Assume connection exists and let the request fail naturally
      return true;
    }
  }
}

/// Interceptor that retries failed requests with exponential backoff.
///
/// Features:
/// - Exponential backoff with configurable delays (default: 1s, 2s, 4s)
/// - Maximum 3 retry attempts by default
/// - Checks connectivity before retrying
/// - Only retries network errors and specific status codes
/// - Does not retry POST/PUT/PATCH requests by default to avoid duplicates
///
/// Usage:
/// ```dart
/// dio.interceptors.add(RetryInterceptor(dio: dio));
/// ```
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    RetryConfig? config,
    ConnectivityChecker? connectivityChecker,
    this.retryMutatingRequests = false,
  }) : _dio = dio,
       _config = config ?? const RetryConfig(),
       _connectivityChecker =
           connectivityChecker ?? DefaultConnectivityChecker();

  final Dio _dio;
  final RetryConfig _config;
  final ConnectivityChecker _connectivityChecker;

  /// Whether to retry mutating requests (POST, PUT, PATCH, DELETE).
  ///
  /// Defaults to false to prevent accidental duplicate operations.
  final bool retryMutatingRequests;

  /// Key for storing retry count in request options.
  static const _retryCountKey = 'retry_count';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    final retryCount = _getRetryCount(err.requestOptions);

    if (retryCount >= _config.maxRetries) {
      return handler.next(err);
    }

    // Check for network connectivity before retrying
    final hasConnection = await _connectivityChecker.hasConnection();
    if (!hasConnection) {
      return handler.next(err);
    }

    // Calculate delay with exponential backoff
    final delay = _calculateDelay(retryCount);
    await Future<void>.delayed(delay);

    // Retry the request
    try {
      final options = err.requestOptions;
      options.extra[_retryCountKey] = retryCount + 1;

      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  /// Determines if the request should be retried.
  bool _shouldRetry(DioException err) {
    // Don't retry if it's a cancel
    if (err.type == DioExceptionType.cancel) {
      return false;
    }

    // Don't retry mutating requests unless explicitly enabled
    if (!retryMutatingRequests && _isMutatingRequest(err.requestOptions)) {
      return false;
    }

    // Retry network errors
    if (_isNetworkError(err)) {
      return true;
    }

    // Retry specific status codes
    final statusCode = err.response?.statusCode;
    if (statusCode != null &&
        _config.retryableStatusCodes.contains(statusCode)) {
      return true;
    }

    return false;
  }

  /// Checks if the error is a network-related error.
  bool _isNetworkError(DioException err) {
    return switch (err.type) {
      DioExceptionType.connectionTimeout => true,
      DioExceptionType.sendTimeout => true,
      DioExceptionType.receiveTimeout => true,
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }

  /// Checks if the request is a mutating request.
  bool _isMutatingRequest(RequestOptions options) {
    final method = options.method.toUpperCase();
    return method == 'POST' ||
        method == 'PUT' ||
        method == 'PATCH' ||
        method == 'DELETE';
  }

  /// Gets the current retry count from request options.
  int _getRetryCount(RequestOptions options) {
    return options.extra[_retryCountKey] as int? ?? 0;
  }

  /// Calculates the delay for the given retry attempt using exponential backoff.
  ///
  /// Delays: 1s, 2s, 4s (with default config)
  Duration _calculateDelay(int retryCount) {
    final delay =
        _config.initialDelay *
        _pow(_config.backoffMultiplier, retryCount).toInt();

    return delay > _config.maxDelay ? _config.maxDelay : delay;
  }

  /// Power function for double base and int exponent.
  double _pow(double base, int exponent) {
    if (exponent == 0) return 1;
    double result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
