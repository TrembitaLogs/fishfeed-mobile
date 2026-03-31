import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/core/di/repository_providers.dart';
import 'package:fishfeed/data/models/ai_scan_result.dart';
import 'package:fishfeed/domain/repositories/ai_scan_repository.dart';

// ============================================================================
// AI Scan State
// ============================================================================

/// Represents the current state of AI fish scanning.
sealed class AiScanState {
  const AiScanState();
}

/// Initial idle state - no scan in progress.
class AiScanIdle extends AiScanState {
  const AiScanIdle();
}

/// Scan is in progress.
class AiScanLoading extends AiScanState {
  const AiScanLoading({this.message = 'Analyzing...'});

  /// Loading message to display.
  final String message;
}

/// Scan completed successfully.
class AiScanSuccess extends AiScanState {
  const AiScanSuccess({required this.result});

  /// The scan result with detected species.
  final AiScanResult result;
}

/// Scan failed with an error.
class AiScanError extends AiScanState {
  const AiScanError({required this.message, this.canRetry = true});

  /// Error message to display.
  final String message;

  /// Whether the user can retry the scan.
  final bool canRetry;
}

// ============================================================================
// AI Scan Notifier
// ============================================================================

/// Notifier for managing AI scan state.
///
/// Handles the scan lifecycle: idle -> loading -> success/error.
/// Supports retry functionality for failed scans.
class AiScanNotifier extends StateNotifier<AiScanState> {
  AiScanNotifier({required AiScanRepository repository})
    : _repository = repository,
      super(const AiScanIdle());

  final AiScanRepository _repository;

  /// Stores the last scanned image bytes for retry.
  Uint8List? _lastImageBytes;

  /// Scans a fish image using AI.
  ///
  /// [imageBytes] - Compressed image bytes to scan.
  ///
  /// Updates state through: idle -> loading -> success/error.
  Future<void> scanImage(Uint8List imageBytes) async {
    _lastImageBytes = imageBytes;
    state = const AiScanLoading(message: 'Analyzing...');

    final result = await _repository.scanFishImage(imageBytes: imageBytes);

    result.fold(
      (failure) {
        state = AiScanError(
          message: _getErrorMessage(failure),
          canRetry: _canRetry(failure),
        );
      },
      (scanResult) {
        state = AiScanSuccess(result: scanResult);
      },
    );
  }

  /// Retries the last scan operation.
  ///
  /// Only works if there was a previous scan attempt.
  Future<void> retry() async {
    if (_lastImageBytes == null) return;
    await scanImage(_lastImageBytes!);
  }

  /// Resets state to idle.
  void reset() {
    state = const AiScanIdle();
    _lastImageBytes = null;
  }

  /// Maps failure to user-friendly error message.
  String _getErrorMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure() => 'Check your connection',
      ServerFailure() => 'Server error. Try again later',
      AuthenticationFailure(:final message) => message ?? 'Please log in',
      ValidationFailure(:final message) => message ?? 'Invalid image',
      _ => 'Failed to analyze image',
    };
  }

  /// Determines if the failure is retryable.
  bool _canRetry(Failure failure) {
    return switch (failure) {
      NetworkFailure() => true,
      ServerFailure() => true,
      AuthenticationFailure() => false,
      ValidationFailure() => false,
      _ => true,
    };
  }
}

// ============================================================================
// Providers
// ============================================================================

/// Provider for AI scan state management.
///
/// Usage:
/// ```dart
/// // Watch state
/// final scanState = ref.watch(aiScanProvider);
///
/// // Get notifier to call methods
/// final notifier = ref.read(aiScanProvider.notifier);
/// await notifier.scanImage(imageBytes);
///
/// // Handle states
/// switch (scanState) {
///   case AiScanIdle():
///     return IdleWidget();
///   case AiScanLoading(:final message):
///     return LoadingWidget(message: message);
///   case AiScanSuccess(:final result):
///     return ResultWidget(result: result);
///   case AiScanError(:final message, :final canRetry):
///     return ErrorWidget(message: message, canRetry: canRetry);
/// }
/// ```
final aiScanProvider = StateNotifierProvider<AiScanNotifier, AiScanState>((
  ref,
) {
  final repository = ref.watch(aiScanRepositoryProvider);
  return AiScanNotifier(repository: repository);
});

/// Provider to check if scan is currently loading.
final isAiScanLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(aiScanProvider);
  return state is AiScanLoading;
});

/// Provider to get the current scan result if available.
final aiScanResultProvider = Provider<AiScanResult?>((ref) {
  final state = ref.watch(aiScanProvider);
  return switch (state) {
    AiScanSuccess(:final result) => result,
    _ => null,
  };
});
