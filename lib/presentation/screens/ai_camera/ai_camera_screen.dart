import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/domain/usecases/ai_scan_limit_usecase.dart';
import 'package:fishfeed/presentation/providers/ai_scan_provider.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/camera_provider.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/screens/ai_camera/photo_preview_screen.dart';
import 'package:fishfeed/presentation/screens/ai_camera/scan_result_screen.dart';
import 'package:fishfeed/presentation/widgets/camera/camera_controls.dart';
import 'package:fishfeed/presentation/widgets/paywall/ai_scan_paywall_bottom_sheet.dart';
import 'package:fishfeed/services/analytics/analytics_service.dart';

/// Result returned when user chooses to add fish manually from paywall.
///
/// This signals to the caller that the camera flow should exit and
/// navigate to manual fish selection instead.
class ManualAddRequested {
  const ManualAddRequested();
}

/// AI Camera screen for fish species recognition.
///
/// Provides full-screen camera preview with controls for:
/// - Flash toggle (off/auto/on)
/// - Camera flip (front/back)
/// - Photo capture with animation
///
/// Handles camera lifecycle automatically with [WidgetsBindingObserver].
class AICameraScreen extends ConsumerStatefulWidget {
  const AICameraScreen({super.key});

  @override
  ConsumerState<AICameraScreen> createState() => _AICameraScreenState();
}

class _AICameraScreenState extends ConsumerState<AICameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;

    // App state changed before we got the chance to initialize
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _disposeController();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      final cameras = await ref.read(availableCamerasProvider.future);

      if (cameras.isEmpty) {
        ref.read(cameraProvider.notifier).setError('No cameras available');
        _isInitializing = false;
        return;
      }

      final cameraState = ref.read(cameraProvider);
      final targetDirection = cameraState.isUsingFrontCamera
          ? CameraLensDirection.front
          : CameraLensDirection.back;

      // Find camera with target direction
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == targetDirection,
        orElse: () => cameras.first,
      );

      await _setupController(camera);
    } catch (e) {
      ref
          .read(cameraProvider.notifier)
          .setError('Failed to initialize camera: $e');
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _setupController(CameraDescription camera) async {
    // Dispose old controller if exists
    await _disposeController();

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;

    try {
      await controller.initialize();

      if (!mounted) return;

      // Apply current flash mode
      final flashMode = ref.read(currentFlashModeProvider);
      await controller.setFlashMode(flashMode);

      ref.read(cameraProvider.notifier).setInitialized(true);
      setState(() {});
    } on CameraException catch (e) {
      ref
          .read(cameraProvider.notifier)
          .setError('Camera error: ${e.description}');
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    if (controller != null) {
      ref.read(cameraProvider.notifier).setInitialized(false);
      _controller = null;
      await controller.dispose();
    }
  }

  Future<void> _onCapture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    // Check if user has remaining scans
    final scanLimitUsecase = ref.read(aiScanLimitUsecaseProvider);
    if (!scanLimitUsecase.hasRemainingScans()) {
      await _showNoScansRemainingPaywall();
      return;
    }

    final notifier = ref.read(cameraProvider.notifier);

    if (ref.read(cameraProvider).isCapturing) {
      return;
    }

    notifier.setCapturing(true);

    try {
      final image = await controller.takePicture();

      if (!mounted) return;

      // Navigate to preview screen
      final previewResult = await Navigator.of(context)
          .push<PhotoPreviewResult>(
            MaterialPageRoute(
              builder: (context) => PhotoPreviewScreen(imagePath: image.path),
            ),
          );

      if (!mounted) return;

      // If user confirmed the photo, proceed to AI scan
      if (previewResult != null) {
        await _processAiScan(Uint8List.fromList(previewResult.compressedBytes));
      }
      // If result is null, user pressed Retake - stay on camera screen
    } on PlatformException catch (e) {
      _showCaptureError('Camera error: ${e.message}');
    } on CameraException catch (e) {
      _showCaptureError('Failed to capture: ${e.description}');
    } finally {
      notifier.setCapturing(false);
    }
  }

  Future<void> _processAiScan(Uint8List imageBytes) async {
    // Show loading dialog
    if (!mounted) return;

    // Show loading dialog (not awaited - will be closed after scan completes)
    // ignore: unawaited_futures
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Start AI scan
    final scanNotifier = ref.read(aiScanProvider.notifier);
    await scanNotifier.scanImage(imageBytes);

    if (!mounted) return;

    // Close loading dialog
    Navigator.of(context).pop();

    // Check scan result
    final scanState = ref.read(aiScanProvider);

    switch (scanState) {
      case AiScanSuccess(:final result):
        // Decrement scan count after successful scan
        await _decrementScanCount();

        if (!mounted) return;

        // Navigate to result screen
        final confirmResult = await Navigator.of(context)
            .push<ScanConfirmResult>(
              MaterialPageRoute(
                builder: (context) => ScanResultScreen(
                  result: result,
                  imageBytes: imageBytes,
                  onEditRequested: () {
                    // TODO: Navigate to species selection screen (task 11.6)
                    // For now, just close and let user retry
                  },
                ),
              ),
            );

        if (!mounted) return;

        if (confirmResult != null) {
          // User confirmed the detection - return result to caller
          Navigator.of(context).pop(confirmResult);
        }
        // User pressed back or edit - stay on camera screen

        // Reset scan state for next scan
        scanNotifier.reset();

      case AiScanError(:final message, :final canRetry):
        // Show error with retry option
        _showScanError(message, canRetry, imageBytes);
        scanNotifier.reset();

      default:
        // Unexpected state, reset
        scanNotifier.reset();
    }
  }

  void _showScanError(String message, bool canRetry, Uint8List imageBytes) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: canRetry
            ? SnackBarAction(
                label: 'Retry',
                onPressed: () => _processAiScan(imageBytes),
              )
            : null,
        backgroundColor: Colors.red.shade900,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showCaptureError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'Retry', onPressed: _onCapture),
        backgroundColor: Colors.red.shade900,
      ),
    );
  }

  Future<void> _decrementScanCount() async {
    final scanLimitUsecase = ref.read(aiScanLimitUsecaseProvider);
    final result = await scanLimitUsecase.decrementScanCount();

    result.fold(
      (failure) {
        // Log error but don't interrupt the user flow
        debugPrint('Failed to decrement scan count: ${failure.message}');
      },
      (updatedUser) {
        // Update auth state with new user data
        ref.read(authNotifierProvider.notifier).updateUser(updatedUser);
      },
    );
  }

  Future<void> _showNoScansRemainingPaywall() async {
    if (!mounted) return;

    final analytics = ref.read(analyticsServiceProvider);
    final scanLimitUsecase = ref.read(aiScanLimitUsecaseProvider);

    // Track paywall shown
    analytics.trackPaywallShown(
      source: PaywallSource.aiCameraCapture,
      scansRemaining: scanLimitUsecase.getRemainingScans(),
      isPremium: scanLimitUsecase.isPremiumUser(),
    );

    // Show bottom sheet
    final action = await AiScanPaywallBottomSheet.show(context);

    if (!mounted) return;

    // Handle action
    switch (action) {
      case PaywallAction.goPremium:
        // Navigate to paywall screen (paywall screen tracks its own events)
        await context.push('/paywall');

      case PaywallAction.addManually:
        // Track paywall dismissed (chose alternative option)
        analytics.trackPaywallDismissed(source: PaywallSource.aiCameraCapture);
        // Close camera and signal manual add
        Navigator.of(context).pop(const ManualAddRequested());

      case PaywallAction.dismissed:
      case null:
        // Track paywall dismissed
        analytics.trackPaywallDismissed(source: PaywallSource.aiCameraCapture);
        // User dismissed - stay on camera screen
        break;
    }
  }

  void _onClose() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraProvider);
    final user = ref.watch(currentUserProvider);
    final isPremium = ref.watch(isPremiumProvider);

    // Get scans remaining from user state for reactivity
    // -1 means unlimited (premium user - badge hidden)
    // null user means not logged in (show 0)
    final int scansRemaining;
    if (user == null) {
      scansRemaining = 0;
    } else if (isPremium) {
      scansRemaining = -1; // Unlimited - badge will be hidden
    } else {
      scansRemaining = user.freeAiScansRemaining;
    }

    // Listen for camera toggle to reinitialize
    ref.listen<bool>(cameraProvider.select((s) => s.isUsingFrontCamera), (
      previous,
      next,
    ) {
      if (previous != null && previous != next) {
        _initializeCamera();
      }
    });

    // Listen for flash mode changes to apply to controller
    ref.listen<CameraFlashMode>(cameraProvider.select((s) => s.flashMode), (
      previous,
      next,
    ) async {
      if (previous != null && previous != next) {
        final controller = _controller;
        if (controller != null && controller.value.isInitialized) {
          await controller.setFlashMode(next.toFlashMode());
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          _buildCameraPreview(cameraState),

          // Top bar with close button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CameraTopBar(
              onClose: _onClose,
              scansRemaining: scansRemaining,
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CameraControls(
              onCapture: _onCapture,
              isEnabled: cameraState.isInitialized && !cameraState.hasError,
            ),
          ),

          // Error overlay
          if (cameraState.hasError) _buildErrorOverlay(cameraState.error!),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(CameraState cameraState) {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // Calculate preview scaling to fill screen
    final size = MediaQuery.of(context).size;
    final previewRatio = controller.value.aspectRatio;

    return ClipRect(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width,
            height: size.width * previewRatio,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(String error) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Camera Error',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(cameraProvider.notifier).clearError();
                  _initializeCamera();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
