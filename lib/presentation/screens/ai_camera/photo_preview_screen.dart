import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:fishfeed/services/image_processing_service.dart';

/// Result returned from PhotoPreviewScreen.
class PhotoPreviewResult {
  const PhotoPreviewResult({
    required this.compressedBytes,
    required this.originalPath,
    this.compressionInfo,
  });

  /// Compressed image bytes ready for upload.
  final List<int> compressedBytes;

  /// Path to the original captured image.
  final String originalPath;

  /// Optional compression info for debugging.
  final CompressionResult? compressionInfo;
}

/// Photo preview screen shown after capturing an image.
///
/// Displays the captured photo with options to:
/// - Retake: Go back to camera
/// - Use Photo: Compress and return the image
class PhotoPreviewScreen extends StatefulWidget {
  const PhotoPreviewScreen({
    super.key,
    required this.imagePath,
    this.imageProcessingService,
  });

  /// Path to the captured image file.
  final String imagePath;

  /// Optional custom image processing service for testing.
  final ImageProcessingService? imageProcessingService;

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  late final ImageProcessingService _imageService;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _imageService = widget.imageProcessingService ?? ImageProcessingService();
  }

  Future<void> _onUsePhoto() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final file = XFile(widget.imagePath);
      final result = await _imageService.compressImage(file);

      if (!mounted) return;

      Navigator.of(context).pop(
        PhotoPreviewResult(
          compressedBytes: result.bytes,
          originalPath: widget.imagePath,
          compressionInfo: result,
        ),
      );
    } on ImageProcessingException catch (e) {
      setState(() {
        _error = e.message;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to process image';
        _isProcessing = false;
      });
    }
  }

  void _onRetake() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Image preview
          _buildImagePreview(),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(colorScheme),
          ),

          // Processing overlay
          if (_isProcessing) _buildProcessingOverlay(),

          // Error snackbar
          if (_error != null)
            Positioned(
              bottom: 120,
              left: 16,
              right: 16,
              child: _buildErrorBanner(),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Image.file(
      File(widget.imagePath),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.broken_image,
                color: Colors.white54,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'Failed to load image',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
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
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              color: Colors.white,
              iconSize: 28,
              onPressed: _onRetake,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.preview,
                    color: Colors.white70,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Preview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Retake button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : _onRetake,
                icon: const Icon(Icons.refresh),
                label: const Text('Retake'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Use Photo button
            Expanded(
              child: FilledButton.icon(
                onPressed: _isProcessing ? null : _onUsePhoto,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_isProcessing ? 'Processing...' : 'Use Photo'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Preparing image...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error ?? 'An error occurred',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: () => setState(() => _error = null),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
