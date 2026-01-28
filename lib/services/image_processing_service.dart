import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Result of image compression operation.
class CompressionResult {
  const CompressionResult({
    required this.bytes,
    required this.originalSize,
    required this.compressedSize,
  });

  /// Compressed image bytes.
  final Uint8List bytes;

  /// Original file size in bytes.
  final int originalSize;

  /// Compressed file size in bytes.
  final int compressedSize;

  /// Compression ratio (e.g., 0.3 means 70% size reduction).
  double get compressionRatio =>
      originalSize > 0 ? compressedSize / originalSize : 1.0;

  /// Size reduction percentage.
  double get sizeReductionPercent => (1 - compressionRatio) * 100;
}

/// Service for image processing operations.
///
/// Provides methods for:
/// - Capturing images from camera
/// - Compressing images for upload
/// - Saving compressed images to temp directory
class ImageProcessingService {
  ImageProcessingService({
    this.defaultQuality = 80,
    this.defaultMaxWidth = 1024,
  });

  /// Default JPEG quality for compression (0-100).
  final int defaultQuality;

  /// Default maximum width for resizing.
  final int defaultMaxWidth;

  /// Captures an image from the camera controller.
  ///
  /// Returns the captured image as [XFile].
  /// Throws [CameraException] if capture fails.
  Future<XFile> captureImage(CameraController controller) async {
    if (!controller.value.isInitialized) {
      throw CameraException('notInitialized', 'Camera is not initialized');
    }

    return controller.takePicture();
  }

  /// Compresses an image file for upload.
  ///
  /// [file] - The image file to compress.
  /// [quality] - JPEG quality (0-100). Defaults to [defaultQuality].
  /// [maxWidth] - Maximum width in pixels. Defaults to [defaultMaxWidth].
  ///
  /// Returns [CompressionResult] with compressed bytes and size info.
  /// Throws [ImageProcessingException] if compression fails.
  Future<CompressionResult> compressImage(
    XFile file, {
    int? quality,
    int? maxWidth,
  }) async {
    final effectiveQuality = quality ?? defaultQuality;
    final effectiveMaxWidth = maxWidth ?? defaultMaxWidth;

    try {
      // Read original file
      final originalBytes = await file.readAsBytes();
      final originalSize = originalBytes.length;

      // Decode image
      final image = img.decodeImage(originalBytes);
      if (image == null) {
        throw const ImageProcessingException('Failed to decode image');
      }

      // Resize if needed (maintaining aspect ratio)
      img.Image processedImage = image;
      if (image.width > effectiveMaxWidth) {
        processedImage = img.copyResize(image, width: effectiveMaxWidth);
      }

      // Encode as JPEG with quality
      final compressedBytes = img.encodeJpg(
        processedImage,
        quality: effectiveQuality,
      );

      return CompressionResult(
        bytes: Uint8List.fromList(compressedBytes),
        originalSize: originalSize,
        compressedSize: compressedBytes.length,
      );
    } catch (e) {
      if (e is ImageProcessingException) rethrow;
      throw ImageProcessingException('Failed to compress image: $e');
    }
  }

  /// Compresses an image and saves it to a temporary file.
  ///
  /// Returns the path to the compressed image file.
  Future<String> compressAndSave(
    XFile file, {
    int? quality,
    int? maxWidth,
  }) async {
    final result = await compressImage(
      file,
      quality: quality,
      maxWidth: maxWidth,
    );

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${tempDir.path}/compressed_$timestamp.jpg';

    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(result.bytes);

    return outputPath;
  }

  /// Compresses image bytes directly.
  ///
  /// Useful when you already have the image bytes in memory.
  Future<CompressionResult> compressBytes(
    Uint8List bytes, {
    int? quality,
    int? maxWidth,
  }) async {
    final effectiveQuality = quality ?? defaultQuality;
    final effectiveMaxWidth = maxWidth ?? defaultMaxWidth;

    try {
      final originalSize = bytes.length;

      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw const ImageProcessingException('Failed to decode image bytes');
      }

      // Resize if needed
      img.Image processedImage = image;
      if (image.width > effectiveMaxWidth) {
        processedImage = img.copyResize(image, width: effectiveMaxWidth);
      }

      // Encode as JPEG
      final compressedBytes = img.encodeJpg(
        processedImage,
        quality: effectiveQuality,
      );

      return CompressionResult(
        bytes: Uint8List.fromList(compressedBytes),
        originalSize: originalSize,
        compressedSize: compressedBytes.length,
      );
    } catch (e) {
      if (e is ImageProcessingException) rethrow;
      throw ImageProcessingException('Failed to compress image bytes: $e');
    }
  }
}

/// Exception thrown when image processing fails.
class ImageProcessingException implements Exception {
  const ImageProcessingException(this.message);

  final String message;

  @override
  String toString() => 'ImageProcessingException: $message';
}
