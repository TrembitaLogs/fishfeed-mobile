import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// Camera Provider
// ============================================================================

/// Available flash modes for camera.
enum CameraFlashMode {
  off,
  auto,
  on,
}

/// Extension to convert between CameraFlashMode and FlashMode.
extension CameraFlashModeExtension on CameraFlashMode {
  /// Converts to camera package FlashMode.
  FlashMode toFlashMode() {
    switch (this) {
      case CameraFlashMode.off:
        return FlashMode.off;
      case CameraFlashMode.auto:
        return FlashMode.auto;
      case CameraFlashMode.on:
        return FlashMode.always;
    }
  }

  /// Gets the next flash mode in cycle (off -> auto -> on -> off).
  CameraFlashMode get next {
    switch (this) {
      case CameraFlashMode.off:
        return CameraFlashMode.auto;
      case CameraFlashMode.auto:
        return CameraFlashMode.on;
      case CameraFlashMode.on:
        return CameraFlashMode.off;
    }
  }
}

/// State for camera controls.
class CameraState {
  const CameraState({
    this.flashMode = CameraFlashMode.off,
    this.isUsingFrontCamera = false,
    this.isInitialized = false,
    this.isCapturing = false,
    this.error,
  });

  /// Current flash mode.
  final CameraFlashMode flashMode;

  /// Whether front camera is active.
  final bool isUsingFrontCamera;

  /// Whether camera is initialized and ready.
  final bool isInitialized;

  /// Whether photo capture is in progress.
  final bool isCapturing;

  /// Error message if any operation failed.
  final String? error;

  /// Whether state has an error.
  bool get hasError => error != null;

  CameraState copyWith({
    CameraFlashMode? flashMode,
    bool? isUsingFrontCamera,
    bool? isInitialized,
    bool? isCapturing,
    String? error,
    bool clearError = false,
  }) {
    return CameraState(
      flashMode: flashMode ?? this.flashMode,
      isUsingFrontCamera: isUsingFrontCamera ?? this.isUsingFrontCamera,
      isInitialized: isInitialized ?? this.isInitialized,
      isCapturing: isCapturing ?? this.isCapturing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for managing camera state.
///
/// Handles flash mode toggling and camera direction switching.
/// Does not manage CameraController directly - that's handled by the screen
/// for proper lifecycle management.
class CameraNotifier extends StateNotifier<CameraState> {
  CameraNotifier() : super(const CameraState());

  /// Toggles flash mode in cycle: off -> auto -> on -> off.
  void toggleFlashMode() {
    state = state.copyWith(flashMode: state.flashMode.next);
  }

  /// Sets specific flash mode.
  void setFlashMode(CameraFlashMode mode) {
    state = state.copyWith(flashMode: mode);
  }

  /// Toggles between front and back camera.
  void toggleCamera() {
    state = state.copyWith(isUsingFrontCamera: !state.isUsingFrontCamera);
  }

  /// Sets camera direction.
  void setUsingFrontCamera(bool useFront) {
    state = state.copyWith(isUsingFrontCamera: useFront);
  }

  /// Marks camera as initialized.
  void setInitialized(bool initialized) {
    state = state.copyWith(isInitialized: initialized, clearError: initialized);
  }

  /// Marks capture in progress.
  void setCapturing(bool capturing) {
    state = state.copyWith(isCapturing: capturing);
  }

  /// Sets error state.
  void setError(String message) {
    state = state.copyWith(error: message, isCapturing: false);
  }

  /// Clears error state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Resets state to initial values.
  void reset() {
    state = const CameraState();
  }
}

/// Provider for camera state.
final cameraProvider = StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  return CameraNotifier();
});

/// Provider for available cameras.
///
/// Fetches available cameras once and caches the result.
final availableCamerasProvider = FutureProvider<List<CameraDescription>>((ref) async {
  return await availableCameras();
});

/// Provider for current camera description based on state.
final currentCameraProvider = Provider<CameraDescription?>((ref) {
  final cameras = ref.watch(availableCamerasProvider);
  final cameraState = ref.watch(cameraProvider);

  return cameras.whenOrNull(
    data: (cameraList) {
      if (cameraList.isEmpty) return null;

      final targetDirection = cameraState.isUsingFrontCamera
          ? CameraLensDirection.front
          : CameraLensDirection.back;

      // Try to find camera with target direction
      final camera = cameraList.cast<CameraDescription?>().firstWhere(
            (c) => c?.lensDirection == targetDirection,
            orElse: () => cameraList.first,
          );

      return camera;
    },
  );
});

/// Provider for flash mode as FlashMode enum.
final currentFlashModeProvider = Provider<FlashMode>((ref) {
  final cameraState = ref.watch(cameraProvider);
  return cameraState.flashMode.toFlashMode();
});
