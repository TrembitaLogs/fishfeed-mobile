import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:fishfeed/services/image_processing_service.dart';

// Fake path provider for testing
class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageProcessingService', () {
    late ImageProcessingService service;
    late Uint8List testImageBytes;
    late Uint8List largeTestImageBytes;

    setUpAll(() {
      PathProviderPlatform.instance = FakePathProviderPlatform();

      // Create a small test image (100x100)
      final smallImage = img.Image(width: 100, height: 100);
      img.fill(smallImage, color: img.ColorRgb8(255, 0, 0));
      testImageBytes = Uint8List.fromList(img.encodeJpg(smallImage));

      // Create a large test image (2000x1500) that needs resizing
      final largeImage = img.Image(width: 2000, height: 1500);
      img.fill(largeImage, color: img.ColorRgb8(0, 255, 0));
      largeTestImageBytes = Uint8List.fromList(img.encodeJpg(largeImage));
    });

    setUp(() {
      service = ImageProcessingService();
    });

    group('constructor', () {
      test('uses default quality 80', () {
        expect(service.defaultQuality, 80);
      });

      test('uses default maxWidth 1024', () {
        expect(service.defaultMaxWidth, 1024);
      });

      test('accepts custom quality and maxWidth', () {
        final customService = ImageProcessingService(
          defaultQuality: 90,
          defaultMaxWidth: 800,
        );
        expect(customService.defaultQuality, 90);
        expect(customService.defaultMaxWidth, 800);
      });
    });

    group('compressBytes', () {
      test('compresses image bytes successfully', () async {
        final result = await service.compressBytes(testImageBytes);

        expect(result.bytes, isNotEmpty);
        expect(result.originalSize, testImageBytes.length);
        expect(result.compressedSize, result.bytes.length);
      });

      test('resizes large image to max width', () async {
        final result = await service.compressBytes(
          largeTestImageBytes,
          maxWidth: 1024,
        );

        // Decode result to check dimensions
        final resultImage = img.decodeImage(result.bytes);
        expect(resultImage, isNotNull);
        expect(resultImage!.width, lessThanOrEqualTo(1024));
      });

      test('maintains aspect ratio when resizing', () async {
        final result = await service.compressBytes(
          largeTestImageBytes,
          maxWidth: 1000,
        );

        final resultImage = img.decodeImage(result.bytes);
        expect(resultImage, isNotNull);

        // Original aspect ratio is 2000/1500 = 1.333
        // New aspect ratio should be similar
        final aspectRatio = resultImage!.width / resultImage.height;
        expect(aspectRatio, closeTo(1.333, 0.01));
      });

      test('applies custom quality setting', () async {
        final highQuality = await service.compressBytes(
          testImageBytes,
          quality: 100,
        );

        final lowQuality = await service.compressBytes(
          testImageBytes,
          quality: 10,
        );

        // Lower quality should generally result in smaller file size
        expect(lowQuality.compressedSize, lessThan(highQuality.compressedSize));
      });

      test('throws ImageProcessingException for invalid image data', () async {
        final invalidBytes = Uint8List.fromList([0, 1, 2, 3, 4, 5]);

        expect(
          () => service.compressBytes(invalidBytes),
          throwsA(isA<ImageProcessingException>()),
        );
      });

      test('does not resize image smaller than max width', () async {
        // Test image is 100x100, max width is 1024
        final result = await service.compressBytes(
          testImageBytes,
          maxWidth: 1024,
        );

        final resultImage = img.decodeImage(result.bytes);
        expect(resultImage, isNotNull);
        expect(resultImage!.width, equals(100));
      });
    });

    group('CompressionResult', () {
      test('calculates compression ratio correctly', () {
        final result = CompressionResult(
          bytes: Uint8List(0),
          originalSize: 1000,
          compressedSize: 300,
        );

        expect(result.compressionRatio, equals(0.3));
      });

      test('calculates size reduction percent correctly', () {
        final result = CompressionResult(
          bytes: Uint8List(0),
          originalSize: 1000,
          compressedSize: 300,
        );

        expect(result.sizeReductionPercent, equals(70.0));
      });

      test('handles zero original size', () {
        final result = CompressionResult(
          bytes: Uint8List(0),
          originalSize: 0,
          compressedSize: 0,
        );

        expect(result.compressionRatio, equals(1.0));
      });
    });

    group('ImageProcessingException', () {
      test('stores message correctly', () {
        const exception = ImageProcessingException('Test error');
        expect(exception.message, 'Test error');
      });

      test('toString returns formatted message', () {
        const exception = ImageProcessingException('Test error');
        expect(exception.toString(), 'ImageProcessingException: Test error');
      });
    });

    group('compressImage', () {
      late Directory tempDir;
      late String testFilePath;

      setUp(() async {
        // Create temp file for testing
        tempDir = Directory.systemTemp.createTempSync('test_images_');
        testFilePath = '${tempDir.path}/test_image.jpg';
        File(testFilePath).writeAsBytesSync(testImageBytes);
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('compresses image file successfully', () async {
        final file = XFile(testFilePath);
        final result = await service.compressImage(file);

        expect(result.bytes, isNotEmpty);
        expect(result.originalSize, greaterThan(0));
      });

      test('uses default quality when not specified', () async {
        final file = XFile(testFilePath);
        final result = await service.compressImage(file);

        // Just verify it works with defaults
        expect(result.bytes, isNotEmpty);
      });

      test('uses custom quality when specified', () async {
        final file = XFile(testFilePath);
        final result = await service.compressImage(file, quality: 50);

        expect(result.bytes, isNotEmpty);
      });
    });

    group('compressAndSave', () {
      late Directory tempDir;
      late String testFilePath;

      setUp(() async {
        tempDir = Directory.systemTemp.createTempSync('test_images_');
        testFilePath = '${tempDir.path}/test_image.jpg';
        File(testFilePath).writeAsBytesSync(testImageBytes);
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('saves compressed image to temp directory', () async {
        final file = XFile(testFilePath);
        final outputPath = await service.compressAndSave(file);

        expect(outputPath, contains('compressed_'));
        expect(outputPath, endsWith('.jpg'));
        expect(File(outputPath).existsSync(), isTrue);

        // Cleanup
        File(outputPath).deleteSync();
      });

      test('creates valid JPEG file', () async {
        final file = XFile(testFilePath);
        final outputPath = await service.compressAndSave(file);

        final outputBytes = File(outputPath).readAsBytesSync();
        final decodedImage = img.decodeImage(outputBytes);
        expect(decodedImage, isNotNull);

        // Cleanup
        File(outputPath).deleteSync();
      });
    });
  });
}
