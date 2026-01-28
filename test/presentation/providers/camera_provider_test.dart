import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/presentation/providers/camera_provider.dart';

void main() {
  group('CameraFlashMode', () {
    test('toFlashMode converts correctly', () {
      expect(CameraFlashMode.off.toFlashMode(), FlashMode.off);
      expect(CameraFlashMode.auto.toFlashMode(), FlashMode.auto);
      expect(CameraFlashMode.on.toFlashMode(), FlashMode.always);
    });

    test('next cycles through modes correctly', () {
      expect(CameraFlashMode.off.next, CameraFlashMode.auto);
      expect(CameraFlashMode.auto.next, CameraFlashMode.on);
      expect(CameraFlashMode.on.next, CameraFlashMode.off);
    });

    test('full cycle returns to original mode', () {
      var mode = CameraFlashMode.off;
      mode = mode.next; // auto
      mode = mode.next; // on
      mode = mode.next; // off
      expect(mode, CameraFlashMode.off);
    });
  });

  group('CameraState', () {
    test('initial state has correct defaults', () {
      const state = CameraState();

      expect(state.flashMode, CameraFlashMode.off);
      expect(state.isUsingFrontCamera, isFalse);
      expect(state.isInitialized, isFalse);
      expect(state.isCapturing, isFalse);
      expect(state.error, isNull);
      expect(state.hasError, isFalse);
    });

    test('copyWith preserves values when not specified', () {
      const original = CameraState(
        flashMode: CameraFlashMode.auto,
        isUsingFrontCamera: true,
        isInitialized: true,
        isCapturing: true,
        error: 'test error',
      );

      final copied = original.copyWith();

      expect(copied.flashMode, original.flashMode);
      expect(copied.isUsingFrontCamera, original.isUsingFrontCamera);
      expect(copied.isInitialized, original.isInitialized);
      expect(copied.isCapturing, original.isCapturing);
      expect(copied.error, original.error);
    });

    test('copyWith updates specified values', () {
      const original = CameraState();

      final copied = original.copyWith(
        flashMode: CameraFlashMode.on,
        isUsingFrontCamera: true,
        isInitialized: true,
        isCapturing: true,
        error: 'new error',
      );

      expect(copied.flashMode, CameraFlashMode.on);
      expect(copied.isUsingFrontCamera, isTrue);
      expect(copied.isInitialized, isTrue);
      expect(copied.isCapturing, isTrue);
      expect(copied.error, 'new error');
    });

    test('copyWith with clearError removes error', () {
      const original = CameraState(error: 'test error');

      final copied = original.copyWith(clearError: true);

      expect(copied.error, isNull);
      expect(copied.hasError, isFalse);
    });

    test('hasError returns true when error is present', () {
      const state = CameraState(error: 'test error');
      expect(state.hasError, isTrue);
    });
  });

  group('CameraNotifier', () {
    late ProviderContainer container;
    late CameraNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(cameraProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is correct', () {
      final state = container.read(cameraProvider);

      expect(state.flashMode, CameraFlashMode.off);
      expect(state.isUsingFrontCamera, isFalse);
      expect(state.isInitialized, isFalse);
      expect(state.isCapturing, isFalse);
      expect(state.error, isNull);
    });

    group('toggleFlashMode', () {
      test('cycles through all flash modes', () {
        expect(container.read(cameraProvider).flashMode, CameraFlashMode.off);

        notifier.toggleFlashMode();
        expect(container.read(cameraProvider).flashMode, CameraFlashMode.auto);

        notifier.toggleFlashMode();
        expect(container.read(cameraProvider).flashMode, CameraFlashMode.on);

        notifier.toggleFlashMode();
        expect(container.read(cameraProvider).flashMode, CameraFlashMode.off);
      });
    });

    group('setFlashMode', () {
      test('sets specific flash mode', () {
        notifier.setFlashMode(CameraFlashMode.on);
        expect(container.read(cameraProvider).flashMode, CameraFlashMode.on);

        notifier.setFlashMode(CameraFlashMode.auto);
        expect(container.read(cameraProvider).flashMode, CameraFlashMode.auto);
      });
    });

    group('toggleCamera', () {
      test('toggles between front and back camera', () {
        expect(container.read(cameraProvider).isUsingFrontCamera, isFalse);

        notifier.toggleCamera();
        expect(container.read(cameraProvider).isUsingFrontCamera, isTrue);

        notifier.toggleCamera();
        expect(container.read(cameraProvider).isUsingFrontCamera, isFalse);
      });
    });

    group('setUsingFrontCamera', () {
      test('sets camera direction', () {
        notifier.setUsingFrontCamera(true);
        expect(container.read(cameraProvider).isUsingFrontCamera, isTrue);

        notifier.setUsingFrontCamera(false);
        expect(container.read(cameraProvider).isUsingFrontCamera, isFalse);
      });
    });

    group('setInitialized', () {
      test('sets initialized state', () {
        notifier.setInitialized(true);
        expect(container.read(cameraProvider).isInitialized, isTrue);

        notifier.setInitialized(false);
        expect(container.read(cameraProvider).isInitialized, isFalse);
      });

      test('clears error when initialized becomes true', () {
        notifier.setError('test error');
        expect(container.read(cameraProvider).hasError, isTrue);

        notifier.setInitialized(true);
        expect(container.read(cameraProvider).hasError, isFalse);
      });
    });

    group('setCapturing', () {
      test('sets capturing state', () {
        notifier.setCapturing(true);
        expect(container.read(cameraProvider).isCapturing, isTrue);

        notifier.setCapturing(false);
        expect(container.read(cameraProvider).isCapturing, isFalse);
      });
    });

    group('setError', () {
      test('sets error message', () {
        notifier.setError('Camera error occurred');
        expect(container.read(cameraProvider).error, 'Camera error occurred');
        expect(container.read(cameraProvider).hasError, isTrue);
      });

      test('sets isCapturing to false when error occurs', () {
        notifier.setCapturing(true);
        notifier.setError('Error');

        expect(container.read(cameraProvider).isCapturing, isFalse);
      });
    });

    group('clearError', () {
      test('clears error state', () {
        notifier.setError('test error');
        expect(container.read(cameraProvider).hasError, isTrue);

        notifier.clearError();
        expect(container.read(cameraProvider).hasError, isFalse);
        expect(container.read(cameraProvider).error, isNull);
      });
    });

    group('reset', () {
      test('resets to initial state', () {
        notifier.setFlashMode(CameraFlashMode.on);
        notifier.setUsingFrontCamera(true);
        notifier.setInitialized(true);
        notifier.setCapturing(true);
        notifier.setError('test error');

        notifier.reset();

        final state = container.read(cameraProvider);
        expect(state.flashMode, CameraFlashMode.off);
        expect(state.isUsingFrontCamera, isFalse);
        expect(state.isInitialized, isFalse);
        expect(state.isCapturing, isFalse);
        expect(state.error, isNull);
      });
    });
  });

  group('currentFlashModeProvider', () {
    test('returns correct FlashMode based on CameraState', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cameraProvider.notifier);

      expect(container.read(currentFlashModeProvider), FlashMode.off);

      notifier.setFlashMode(CameraFlashMode.auto);
      expect(container.read(currentFlashModeProvider), FlashMode.auto);

      notifier.setFlashMode(CameraFlashMode.on);
      expect(container.read(currentFlashModeProvider), FlashMode.always);
    });
  });
}
