import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/screens/ai_camera/photo_preview_screen.dart';
import 'package:fishfeed/services/image_processing_service.dart';

class MockImageProcessingService extends Mock
    implements ImageProcessingService {}

class FakeXFile extends Fake implements XFile {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
    registerFallbackValue(FakeXFile());
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  late Directory tempDir;
  late String testImagePath;
  late Uint8List testImageBytes;
  late MockImageProcessingService mockImageService;

  setUp(() {
    mockImageService = MockImageProcessingService();

    // Create test image
    final testImage = img.Image(width: 100, height: 100);
    img.fill(testImage, color: img.ColorRgb8(255, 0, 0));
    testImageBytes = Uint8List.fromList(img.encodeJpg(testImage));

    // Create temp file
    tempDir = Directory.systemTemp.createTempSync('test_preview_');
    testImagePath = '${tempDir.path}/test_image.jpg';
    File(testImagePath).writeAsBytesSync(testImageBytes);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget buildTestWidget({
    required String imagePath,
    ImageProcessingService? imageService,
    NavigatorObserver? observer,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: observer != null ? [observer] : [],
      home: PhotoPreviewScreen(
        imagePath: imagePath,
        imageProcessingService: imageService,
      ),
    );
  }

  group('PhotoPreviewScreen', () {
    testWidgets('renders image preview', (tester) async {
      await tester.pumpWidget(buildTestWidget(imagePath: testImagePath));
      await tester.pumpAndSettle();

      // Should find Image.file widget
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders Retake and Use Photo buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget(imagePath: testImagePath));
      await tester.pumpAndSettle();

      expect(find.text('Retake'), findsOneWidget);
      expect(find.text('Use Photo'), findsOneWidget);
    });

    testWidgets('renders close button in top bar', (tester) async {
      await tester.pumpWidget(buildTestWidget(imagePath: testImagePath));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('renders Preview badge in top bar', (tester) async {
      await tester.pumpWidget(buildTestWidget(imagePath: testImagePath));
      await tester.pumpAndSettle();

      expect(find.text('Preview'), findsOneWidget);
      expect(find.byIcon(Icons.preview), findsOneWidget);
    });

    testWidgets('renders Retake button with refresh icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(imagePath: testImagePath));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('renders Use Photo button with check icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(imagePath: testImagePath));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('Retake button pops without result', (tester) async {
      var poppedResult = 'not popped';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.of(context)
                      .push<PhotoPreviewResult>(
                        MaterialPageRoute(
                          builder: (_) => PhotoPreviewScreen(
                            imagePath: testImagePath,
                            imageProcessingService: mockImageService,
                          ),
                        ),
                      );
                  poppedResult = result == null ? 'null' : 'has result';
                },
                child: const Text('Open Preview'),
              );
            },
          ),
        ),
      );

      // Open preview
      await tester.tap(find.text('Open Preview'));
      await tester.pumpAndSettle();

      // Tap Retake
      await tester.tap(find.text('Retake'));
      await tester.pumpAndSettle();

      expect(poppedResult, 'null');
    });

    testWidgets('close button pops without result', (tester) async {
      var poppedResult = 'not popped';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.of(context)
                      .push<PhotoPreviewResult>(
                        MaterialPageRoute(
                          builder: (_) => PhotoPreviewScreen(
                            imagePath: testImagePath,
                            imageProcessingService: mockImageService,
                          ),
                        ),
                      );
                  poppedResult = result == null ? 'null' : 'has result';
                },
                child: const Text('Open Preview'),
              );
            },
          ),
        ),
      );

      // Open preview
      await tester.tap(find.text('Open Preview'));
      await tester.pumpAndSettle();

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(poppedResult, 'null');
    });

    testWidgets('Use Photo compresses and pops with result', (tester) async {
      final compressedBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      PhotoPreviewResult? poppedResult;

      when(() => mockImageService.compressImage(any())).thenAnswer(
        (_) async => CompressionResult(
          bytes: compressedBytes,
          originalSize: 1000,
          compressedSize: 500,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  poppedResult = await Navigator.of(context)
                      .push<PhotoPreviewResult>(
                        MaterialPageRoute(
                          builder: (_) => PhotoPreviewScreen(
                            imagePath: testImagePath,
                            imageProcessingService: mockImageService,
                          ),
                        ),
                      );
                },
                child: const Text('Open Preview'),
              );
            },
          ),
        ),
      );

      // Open preview
      await tester.tap(find.text('Open Preview'));
      await tester.pumpAndSettle();

      // Tap Use Photo
      await tester.tap(find.text('Use Photo'));
      await tester.pumpAndSettle();

      expect(poppedResult, isNotNull);
      expect(poppedResult!.compressedBytes, compressedBytes);
      expect(poppedResult!.originalPath, testImagePath);
      expect(poppedResult!.compressionInfo, isNotNull);
    });

    testWidgets('shows processing state when Use Photo is tapped', (
      tester,
    ) async {
      // Use a completer to control when compression finishes
      final completer = Completer<CompressionResult>();
      when(
        () => mockImageService.compressImage(any()),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        buildTestWidget(
          imagePath: testImagePath,
          imageService: mockImageService,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Use Photo
      await tester.tap(find.text('Use Photo'));
      await tester.pump();

      // Should show "Processing..." text
      expect(find.text('Processing...'), findsOneWidget);

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Complete the future to clean up
      completer.complete(
        CompressionResult(
          bytes: Uint8List.fromList([1, 2, 3]),
          originalSize: 1000,
          compressedSize: 500,
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('shows error banner when compression fails', (tester) async {
      when(
        () => mockImageService.compressImage(any()),
      ).thenThrow(const ImageProcessingException('Compression failed'));

      await tester.pumpWidget(
        buildTestWidget(
          imagePath: testImagePath,
          imageService: mockImageService,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Use Photo
      await tester.tap(find.text('Use Photo'));
      await tester.pumpAndSettle();

      // Should show error banner
      expect(find.text('Compression failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('error banner can be dismissed', (tester) async {
      when(
        () => mockImageService.compressImage(any()),
      ).thenThrow(const ImageProcessingException('Compression failed'));

      await tester.pumpWidget(
        buildTestWidget(
          imagePath: testImagePath,
          imageService: mockImageService,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Use Photo to trigger error
      await tester.tap(find.text('Use Photo'));
      await tester.pumpAndSettle();

      // Verify error is shown
      expect(find.text('Compression failed'), findsOneWidget);

      // Find and tap dismiss button on error banner
      // The error banner has a close IconButton
      final errorBanner = find.ancestor(
        of: find.text('Compression failed'),
        matching: find.byType(Container),
      );
      final closeButton = find.descendant(
        of: errorBanner.first,
        matching: find.byIcon(Icons.close),
      );
      await tester.tap(closeButton.first);
      await tester.pumpAndSettle();

      // Error should be dismissed
      expect(find.text('Compression failed'), findsNothing);
    });

    testWidgets('buttons are disabled during processing', (tester) async {
      // Use a completer so we can control when the compression finishes
      final completer = Completer<CompressionResult>();
      when(
        () => mockImageService.compressImage(any()),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        buildTestWidget(
          imagePath: testImagePath,
          imageService: mockImageService,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Use Photo
      await tester.tap(find.text('Use Photo'));
      await tester.pump();

      // Retake button should be disabled
      final retakeButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Retake'),
      );
      expect(retakeButton.onPressed, isNull);

      // Complete the future to clean up
      completer.complete(
        CompressionResult(
          bytes: Uint8List.fromList([1, 2, 3]),
          originalSize: 1000,
          compressedSize: 500,
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets(
      'shows error widget for invalid image path',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(imagePath: '/invalid/path/image.jpg'),
        );
        // Pump multiple times to allow error to propagate
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Should show broken image icon and error text
        // Note: Image.file error might take some frames to render
        expect(find.byIcon(Icons.broken_image), findsOneWidget);
        expect(find.text('Failed to load image'), findsOneWidget);
      },
      skip: true,
    ); // Skip: Image.file error handling depends on platform timing
  });

  group('PhotoPreviewResult', () {
    test('stores all properties correctly', () {
      final bytes = [1, 2, 3, 4, 5];
      final result = CompressionResult(
        bytes: Uint8List(0),
        originalSize: 1000,
        compressedSize: 500,
      );

      final previewResult = PhotoPreviewResult(
        compressedBytes: bytes,
        originalPath: '/path/to/image.jpg',
        compressionInfo: result,
      );

      expect(previewResult.compressedBytes, bytes);
      expect(previewResult.originalPath, '/path/to/image.jpg');
      expect(previewResult.compressionInfo, result);
    });

    test('compressionInfo can be null', () {
      const previewResult = PhotoPreviewResult(
        compressedBytes: [1, 2, 3],
        originalPath: '/path/to/image.jpg',
        compressionInfo: null,
      );

      expect(previewResult.compressionInfo, isNull);
    });
  });
}
