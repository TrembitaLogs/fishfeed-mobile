import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/providers/camera_provider.dart';
import 'package:fishfeed/presentation/widgets/camera/camera_controls.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget(Widget child, {List<Override>? overrides}) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(backgroundColor: Colors.black, body: child),
      ),
    );
  }

  group('CameraControls', () {
    testWidgets('renders all control buttons', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(CameraControls(onCapture: () {})),
      );

      // Flash button (flash_off icon by default)
      expect(find.byIcon(Icons.flash_off), findsOneWidget);

      // Camera flip button
      expect(find.byIcon(Icons.flip_camera_ios), findsOneWidget);

      // Capture button (by semantics label)
      expect(find.bySemanticsLabel('Take photo'), findsOneWidget);
    });

    testWidgets('calls onCapture when capture button is tapped', (
      tester,
    ) async {
      var captureCount = 0;

      await tester.pumpWidget(
        buildTestWidget(
          CameraControls(onCapture: () => captureCount++),
          overrides: [
            cameraProvider.overrideWith(
              (ref) => CameraNotifier()..setInitialized(true),
            ),
          ],
        ),
      );

      // Find and tap the capture button (GestureDetector with specific semantics)
      final captureButton = find.bySemanticsLabel('Take photo');
      await tester.tap(captureButton);
      await tester.pump();

      expect(captureCount, 1);
    });

    testWidgets('does not call onCapture when disabled', (tester) async {
      var captureCount = 0;

      await tester.pumpWidget(
        buildTestWidget(
          CameraControls(onCapture: () => captureCount++, isEnabled: false),
        ),
      );

      final captureButton = find.bySemanticsLabel('Take photo');
      await tester.tap(captureButton);
      await tester.pump();

      expect(captureCount, 0);
    });

    testWidgets('toggles flash mode when flash button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(CameraControls(onCapture: () {})),
      );

      // Initially flash_off
      expect(find.byIcon(Icons.flash_off), findsOneWidget);

      // Tap flash button
      await tester.tap(find.byIcon(Icons.flash_off));
      await tester.pump();

      // Should show flash_auto
      expect(find.byIcon(Icons.flash_auto), findsOneWidget);

      // Tap again
      await tester.tap(find.byIcon(Icons.flash_auto));
      await tester.pump();

      // Should show flash_on
      expect(find.byIcon(Icons.flash_on), findsOneWidget);

      // Tap again to cycle back
      await tester.tap(find.byIcon(Icons.flash_on));
      await tester.pump();

      // Should show flash_off
      expect(find.byIcon(Icons.flash_off), findsOneWidget);
    });

    testWidgets('toggles camera when flip button is tapped', (tester) async {
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return Scaffold(
                  backgroundColor: Colors.black,
                  body: CameraControls(onCapture: () {}),
                );
              },
            ),
          ),
        ),
      );

      // Initially using back camera
      expect(capturedRef.read(cameraProvider).isUsingFrontCamera, isFalse);

      // Tap flip button
      await tester.tap(find.byIcon(Icons.flip_camera_ios));
      await tester.pump();

      // Should now use front camera
      expect(capturedRef.read(cameraProvider).isUsingFrontCamera, isTrue);

      // Tap again
      await tester.tap(find.byIcon(Icons.flip_camera_ios));
      await tester.pump();

      // Should use back camera
      expect(capturedRef.read(cameraProvider).isUsingFrontCamera, isFalse);
    });

    testWidgets('disables flash button when using front camera', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          CameraControls(onCapture: () {}),
          overrides: [
            cameraProvider.overrideWith(
              (ref) => CameraNotifier()..setUsingFrontCamera(true),
            ),
          ],
        ),
      );

      // Flash button should be visually disabled (white54 color)
      final flashButton = find.byIcon(Icons.flash_off);
      expect(flashButton, findsOneWidget);

      // Verify the IconButton is disabled by checking its onPressed
      final iconButton = tester.widget<IconButton>(
        find.ancestor(of: flashButton, matching: find.byType(IconButton)),
      );
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('shows loading indicator when capturing', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          CameraControls(onCapture: () {}),
          overrides: [
            cameraProvider.overrideWith(
              (ref) => CameraNotifier()
                ..setInitialized(true)
                ..setCapturing(true),
            ),
          ],
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('CameraTopBar', () {
    testWidgets('renders close button', (tester) async {
      await tester.pumpWidget(buildTestWidget(CameraTopBar(onClose: () {})));

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('calls onClose when close button is tapped', (tester) async {
      var closeCalled = false;

      await tester.pumpWidget(
        buildTestWidget(CameraTopBar(onClose: () => closeCalled = true)),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(closeCalled, isTrue);
    });

    testWidgets('shows scans remaining badge when provided', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(CameraTopBar(onClose: () {}, scansRemaining: 3)),
      );

      expect(find.text('3 scans left'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('hides scans badge when scansRemaining is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(CameraTopBar(onClose: () {}, scansRemaining: null)),
      );

      expect(find.text('scans left'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('shows correct scans remaining values', (tester) async {
      // Test 0 scans - shows "No scans left"
      await tester.pumpWidget(
        buildTestWidget(CameraTopBar(onClose: () {}, scansRemaining: 0)),
      );
      expect(find.text('No scans left'), findsOneWidget);

      // Test 1 scan - shows "1 scan left" (singular)
      await tester.pumpWidget(
        buildTestWidget(CameraTopBar(onClose: () {}, scansRemaining: 1)),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 scan left'), findsOneWidget);

      // Test 5 scans - shows "5 scans left"
      await tester.pumpWidget(
        buildTestWidget(CameraTopBar(onClose: () {}, scansRemaining: 5)),
      );
      await tester.pumpAndSettle();
      expect(find.text('5 scans left'), findsOneWidget);

      // Test 10 scans - shows "10 scans left"
      await tester.pumpWidget(
        buildTestWidget(CameraTopBar(onClose: () {}, scansRemaining: 10)),
      );
      await tester.pumpAndSettle();
      expect(find.text('10 scans left'), findsOneWidget);
    });
  });
}
