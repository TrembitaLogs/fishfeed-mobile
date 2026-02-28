import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/image_upload_provider.dart';
import 'package:fishfeed/presentation/widgets/common/image_picker_button.dart';

// ============ Mocks ============

class MockImagePicker extends Mock implements ImagePicker {}

/// Mock [ImageUploadNotifier] that doesn't depend on real services.
///
/// Follows the project pattern of extending StateNotifier and implementing
/// the interface, avoiding complex constructor dependencies.
class MockImageUploadNotifier extends StateNotifier<ImageUploadQueueStatus>
    implements ImageUploadNotifier {
  MockImageUploadNotifier() : super(ImageUploadQueueStatus.empty);

  int queueUploadCallCount = 0;
  String? lastEntityType;
  String? lastEntityId;
  Uint8List? lastImageBytes;
  String localKeyToReturn = 'local://mock-uuid';
  Exception? errorToThrow;

  @override
  Future<String> queueUpload({
    required String entityType,
    required String entityId,
    required Uint8List imageBytes,
  }) async {
    queueUploadCallCount++;
    lastEntityType = entityType;
    lastEntityId = entityId;
    lastImageBytes = imageBytes;
    if (errorToThrow != null) throw errorToThrow!;
    return localKeyToReturn;
  }

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> processQueue() async {}

  @override
  Future<int> retryFailed() async => 0;

  @override
  Future<String?> getLocalImagePath(String localKey) async => null;
}

// ============ Helpers ============

/// Test image bytes (minimal valid WebP header).
final _testImageBytes = Uint8List.fromList([
  0x52, 0x49, 0x46, 0x46, // RIFF
  0x24, 0x00, 0x00, 0x00, // File size
  0x57, 0x45, 0x42, 0x50, // WEBP
]);

/// Fake bytes reader that returns [_testImageBytes] without real I/O.
/// Avoids FakeAsync zone issues with [File.readAsBytes].
Future<Uint8List> _fakeReadImageBytes(String path) async => _testImageBytes;

Widget _buildTestWidget({
  required Widget child,
  required MockImageUploadNotifier mockNotifier,
}) {
  return ProviderScope(
    overrides: [imageUploadNotifierProvider.overrideWith((_) => mockNotifier)],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  late MockImagePicker mockPicker;
  late MockImageUploadNotifier mockNotifier;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  setUp(() {
    mockPicker = MockImagePicker();
    mockNotifier = MockImageUploadNotifier();
  });

  // ---------------------------------------------------------------------------
  // Default rendering
  // ---------------------------------------------------------------------------
  group('ImagePickerButton — default rendering', () {
    testWidgets('renders default camera icon button when no child provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestWidget(
          mockNotifier: mockNotifier,
          child: ImagePickerButton(
            entityType: 'aquarium',
            entityId: 'aq-1',
            onImageSelected: (_) {},
            imagePicker: mockPicker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders custom child widget when provided', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          mockNotifier: mockNotifier,
          child: ImagePickerButton(
            entityType: 'fish',
            entityId: 'fish-1',
            onImageSelected: (_) {},
            imagePicker: mockPicker,
            child: const Text('Custom Button'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom Button'), findsOneWidget);
      expect(find.byIcon(Icons.add_a_photo), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // Bottom sheet
  // ---------------------------------------------------------------------------
  group('ImagePickerButton — bottom sheet', () {
    testWidgets('shows bottom sheet with camera and gallery options on tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestWidget(
          mockNotifier: mockNotifier,
          child: ImagePickerButton(
            entityType: 'aquarium',
            entityId: 'aq-1',
            onImageSelected: (_) {},
            imagePicker: mockPicker,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_a_photo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });

    testWidgets('shows bottom sheet when tapping custom child', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          mockNotifier: mockNotifier,
          child: ImagePickerButton(
            entityType: 'aquarium',
            entityId: 'aq-1',
            onImageSelected: (_) {},
            imagePicker: mockPicker,
            child: const Text('Pick Photo'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pick Photo'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Successful pick
  // ---------------------------------------------------------------------------
  group('ImagePickerButton — successful pick', () {
    testWidgets(
      'calls queueUpload with correct params and onImageSelected with localKey',
      (tester) async {
        when(
          () => mockPicker.pickImage(source: ImageSource.gallery),
        ).thenAnswer((_) async => XFile('/fake/image.jpg'));

        String? receivedKey;

        await tester.pumpWidget(
          _buildTestWidget(
            mockNotifier: mockNotifier,
            child: ImagePickerButton(
              entityType: 'aquarium',
              entityId: 'aq-1',
              onImageSelected: (key) => receivedKey = key,
              imagePicker: mockPicker,
              readImageBytes: _fakeReadImageBytes,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open bottom sheet
        await tester.tap(find.byIcon(Icons.add_a_photo));
        await tester.pumpAndSettle();

        // Tap "Choose from Gallery"
        await tester.tap(find.byIcon(Icons.photo_library));
        await tester.pumpAndSettle();

        // Verify queueUpload was called with correct params
        expect(mockNotifier.queueUploadCallCount, 1);
        expect(mockNotifier.lastEntityType, 'aquarium');
        expect(mockNotifier.lastEntityId, 'aq-1');
        expect(mockNotifier.lastImageBytes, _testImageBytes);

        // Verify onImageSelected was called
        expect(receivedKey, 'local://mock-uuid');
      },
    );

    testWidgets('calls queueUpload via camera source', (tester) async {
      when(
        () => mockPicker.pickImage(source: ImageSource.camera),
      ).thenAnswer((_) async => XFile('/fake/image.jpg'));

      String? receivedKey;

      await tester.pumpWidget(
        _buildTestWidget(
          mockNotifier: mockNotifier,
          child: ImagePickerButton(
            entityType: 'fish',
            entityId: 'fish-42',
            onImageSelected: (key) => receivedKey = key,
            imagePicker: mockPicker,
            readImageBytes: _fakeReadImageBytes,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.byIcon(Icons.add_a_photo));
      await tester.pumpAndSettle();

      // Tap "Take Photo" (camera)
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();

      expect(mockNotifier.queueUploadCallCount, 1);
      expect(mockNotifier.lastEntityType, 'fish');
      expect(mockNotifier.lastEntityId, 'fish-42');
      expect(receivedKey, 'local://mock-uuid');
    });

    testWidgets('returns correct custom localKey from notifier', (
      tester,
    ) async {
      mockNotifier.localKeyToReturn = 'local://custom-uuid-123';

      when(
        () => mockPicker.pickImage(source: ImageSource.gallery),
      ).thenAnswer((_) async => XFile('/fake/image.jpg'));

      String? receivedKey;

      await tester.pumpWidget(
        _buildTestWidget(
          mockNotifier: mockNotifier,
          child: ImagePickerButton(
            entityType: 'avatar',
            entityId: 'user-1',
            onImageSelected: (key) => receivedKey = key,
            imagePicker: mockPicker,
            readImageBytes: _fakeReadImageBytes,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_a_photo));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pumpAndSettle();

      expect(receivedKey, 'local://custom-uuid-123');
    });
  });

  // ---------------------------------------------------------------------------
  // User cancels — null from ImagePicker
  // ---------------------------------------------------------------------------
  group('ImagePickerButton — user cancels', () {
    testWidgets('does not call queueUpload when ImagePicker returns null', (
      tester,
    ) async {
      when(
        () => mockPicker.pickImage(source: ImageSource.gallery),
      ).thenAnswer((_) async => null);

      String? receivedKey;

      await tester.pumpWidget(
        _buildTestWidget(
          mockNotifier: mockNotifier,
          child: ImagePickerButton(
            entityType: 'aquarium',
            entityId: 'aq-1',
            onImageSelected: (key) => receivedKey = key,
            imagePicker: mockPicker,
            readImageBytes: _fakeReadImageBytes,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_a_photo));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pumpAndSettle();

      expect(mockNotifier.queueUploadCallCount, 0);
      expect(receivedKey, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Loading state
  // ---------------------------------------------------------------------------
  group('ImagePickerButton — loading state', () {
    testWidgets('shows CircularProgressIndicator while processing', (
      tester,
    ) async {
      // Use a completer to control when pickImage resolves
      final pickCompleter = Completer<XFile?>();

      when(
        () => mockPicker.pickImage(source: ImageSource.gallery),
      ).thenAnswer((_) => pickCompleter.future);

      await tester.pumpWidget(
        _buildTestWidget(
          mockNotifier: mockNotifier,
          child: ImagePickerButton(
            entityType: 'aquarium',
            entityId: 'aq-1',
            onImageSelected: (_) {},
            imagePicker: mockPicker,
            readImageBytes: _fakeReadImageBytes,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Before tap — camera icon, no spinner
      expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Open bottom sheet and tap gallery
      await tester.tap(find.byIcon(Icons.add_a_photo));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pump(); // Process tap, start _pickImage

      // pickImage hasn't resolved yet → spinner should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.add_a_photo), findsNothing);

      // Now resolve the picker with null (cancel) to end the flow cleanly
      pickCompleter.complete(null);
      await tester.pumpAndSettle();

      // After cancellation — back to camera icon
      expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('restores camera icon after successful processing', (
      tester,
    ) async {
      when(
        () => mockPicker.pickImage(source: ImageSource.gallery),
      ).thenAnswer((_) async => XFile('/fake/image.jpg'));

      await tester.pumpWidget(
        _buildTestWidget(
          mockNotifier: mockNotifier,
          child: ImagePickerButton(
            entityType: 'aquarium',
            entityId: 'aq-1',
            onImageSelected: (_) {},
            imagePicker: mockPicker,
            readImageBytes: _fakeReadImageBytes,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Complete the full flow
      await tester.tap(find.byIcon(Icons.add_a_photo));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pumpAndSettle();

      // After completion — camera icon should be back
      expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // Error handling
  // ---------------------------------------------------------------------------
  group('ImagePickerButton — error handling', () {
    testWidgets('shows permission denied error snackbar', (tester) async {
      when(() => mockPicker.pickImage(source: ImageSource.gallery)).thenThrow(
        PlatformException(
          code: 'photo_access_denied',
          message: 'Permission denied',
        ),
      );

      await tester.pumpWidget(
        _buildTestWidget(
          mockNotifier: mockNotifier,
          child: ImagePickerButton(
            entityType: 'aquarium',
            entityId: 'aq-1',
            onImageSelected: (_) {},
            imagePicker: mockPicker,
            readImageBytes: _fakeReadImageBytes,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_a_photo));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('permission'), findsOneWidget);
    });

    testWidgets('shows generic error snackbar on queueUpload failure', (
      tester,
    ) async {
      when(
        () => mockPicker.pickImage(source: ImageSource.gallery),
      ).thenAnswer((_) async => XFile('/fake/image.jpg'));

      mockNotifier.errorToThrow = Exception('Compression failed');

      await tester.pumpWidget(
        _buildTestWidget(
          mockNotifier: mockNotifier,
          child: ImagePickerButton(
            entityType: 'aquarium',
            entityId: 'aq-1',
            onImageSelected: (_) {},
            imagePicker: mockPicker,
            readImageBytes: _fakeReadImageBytes,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_a_photo));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(mockNotifier.queueUploadCallCount, 1);
    });

    testWidgets('does not call onImageSelected on error', (tester) async {
      when(
        () => mockPicker.pickImage(source: ImageSource.gallery),
      ).thenAnswer((_) async => XFile('/fake/image.jpg'));

      mockNotifier.errorToThrow = Exception('Upload queue full');

      String? receivedKey;

      await tester.pumpWidget(
        _buildTestWidget(
          mockNotifier: mockNotifier,
          child: ImagePickerButton(
            entityType: 'aquarium',
            entityId: 'aq-1',
            onImageSelected: (key) => receivedKey = key,
            imagePicker: mockPicker,
            readImageBytes: _fakeReadImageBytes,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_a_photo));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pumpAndSettle();

      expect(receivedKey, isNull);
    });

    testWidgets('restores isProcessing to false after error', (tester) async {
      when(
        () => mockPicker.pickImage(source: ImageSource.gallery),
      ).thenThrow(Exception('Unexpected error'));

      await tester.pumpWidget(
        _buildTestWidget(
          mockNotifier: mockNotifier,
          child: ImagePickerButton(
            entityType: 'aquarium',
            entityId: 'aq-1',
            onImageSelected: (_) {},
            imagePicker: mockPicker,
            readImageBytes: _fakeReadImageBytes,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_a_photo));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pumpAndSettle();

      // After error — should be back to normal state
      expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
