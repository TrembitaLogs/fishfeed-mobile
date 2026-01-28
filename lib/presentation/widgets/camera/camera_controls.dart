import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/presentation/providers/camera_provider.dart';
import 'package:fishfeed/presentation/widgets/camera/scans_remaining_badge.dart';

/// Camera control buttons for AI camera screen.
///
/// Includes flash toggle, capture button, and camera flip controls.
/// Uses [CameraNotifier] for state management.
class CameraControls extends ConsumerWidget {
  const CameraControls({
    super.key,
    required this.onCapture,
    this.isEnabled = true,
  });

  /// Callback when capture button is pressed.
  final VoidCallback onCapture;

  /// Whether controls are enabled.
  final bool isEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Flash toggle button
            _FlashToggleButton(
              flashMode: cameraState.flashMode,
              isEnabled: isEnabled && !cameraState.isUsingFrontCamera,
              onPressed: () {
                ref.read(cameraProvider.notifier).toggleFlashMode();
              },
            ),
            // Capture button
            _CaptureButton(
              isCapturing: cameraState.isCapturing,
              isEnabled: isEnabled && cameraState.isInitialized,
              onPressed: onCapture,
            ),
            // Camera flip button
            _CameraFlipButton(
              isEnabled: isEnabled,
              onPressed: () {
                ref.read(cameraProvider.notifier).toggleCamera();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Flash toggle button with cycling modes.
class _FlashToggleButton extends StatelessWidget {
  const _FlashToggleButton({
    required this.flashMode,
    required this.isEnabled,
    required this.onPressed,
  });

  final CameraFlashMode flashMode;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _ControlButton(
      icon: _getFlashIcon(),
      isEnabled: isEnabled,
      onPressed: onPressed,
      semanticLabel: 'Flash mode: ${flashMode.name}',
    );
  }

  IconData _getFlashIcon() {
    switch (flashMode) {
      case CameraFlashMode.off:
        return Icons.flash_off;
      case CameraFlashMode.auto:
        return Icons.flash_auto;
      case CameraFlashMode.on:
        return Icons.flash_on;
    }
  }
}

/// Main capture button with press animation.
class _CaptureButton extends StatefulWidget {
  const _CaptureButton({
    required this.isCapturing,
    required this.isEnabled,
    required this.onPressed,
  });

  final bool isCapturing;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  State<_CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<_CaptureButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isCapturing) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.isEnabled && !widget.isCapturing) {
      widget.onPressed();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = widget.isEnabled && !widget.isCapturing;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Semantics(
          label: 'Take photo',
          button: true,
          enabled: isActive,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Colors.white : Colors.white54,
                width: 4,
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isCapturing
                    ? colorScheme.primary
                    : (isActive ? Colors.white : Colors.white54),
              ),
              child: widget.isCapturing
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Camera flip button for switching front/back camera.
class _CameraFlipButton extends StatelessWidget {
  const _CameraFlipButton({
    required this.isEnabled,
    required this.onPressed,
  });

  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _ControlButton(
      icon: Icons.flip_camera_ios,
      isEnabled: isEnabled,
      onPressed: onPressed,
      semanticLabel: 'Switch camera',
    );
  }
}

/// Base control button with consistent styling.
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.isEnabled,
    required this.onPressed,
    required this.semanticLabel,
  });

  final IconData icon;
  final bool isEnabled;
  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: isEnabled,
      child: IconButton(
        icon: Icon(icon),
        iconSize: 28,
        color: isEnabled ? Colors.white : Colors.white54,
        onPressed: isEnabled ? onPressed : null,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black38,
          disabledBackgroundColor: Colors.black26,
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}

/// Top bar for camera screen with close button and scans remaining badge.
class CameraTopBar extends StatelessWidget {
  const CameraTopBar({
    super.key,
    required this.onClose,
    this.scansRemaining,
  });

  /// Callback when close button is pressed.
  final VoidCallback onClose;

  /// Number of free scans remaining (null to hide badge).
  final int? scansRemaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close button
            IconButton(
              icon: const Icon(Icons.close),
              color: Colors.white,
              iconSize: 28,
              onPressed: onClose,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
              ),
            ),
            // Scans remaining badge
            if (scansRemaining != null)
              ScansRemainingBadge(scansRemaining: scansRemaining!),
          ],
        ),
      ),
    );
  }
}
