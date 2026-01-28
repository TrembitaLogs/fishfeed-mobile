import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/data/models/ai_scan_result.dart';
import 'package:fishfeed/presentation/screens/ai_camera/scan_result_screen.dart';
import 'package:fishfeed/presentation/widgets/confidence_indicator.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  late Uint8List testImageBytes;

  setUp(() {
    // Create test image
    final testImage = img.Image(width: 100, height: 100);
    img.fill(testImage, color: img.ColorRgb8(255, 0, 0));
    testImageBytes = Uint8List.fromList(img.encodeJpg(testImage));
  });

  AiScanResult createResult({
    String speciesId = 'guppy',
    String speciesName = 'Guppy',
    double confidence = 0.85,
    List<String> recommendations = const [
      'Feed twice daily',
      'Maintain water temperature',
    ],
    String? careLevel,
    String? feedingFrequency,
  }) {
    return AiScanResult(
      speciesId: speciesId,
      speciesName: speciesName,
      confidence: confidence,
      recommendations: recommendations,
      careLevel: careLevel,
      feedingFrequency: feedingFrequency,
    );
  }

  Widget buildTestWidget({
    required AiScanResult result,
    required Uint8List imageBytes,
    VoidCallback? onEditRequested,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: ScanResultScreen(
          result: result,
          imageBytes: imageBytes,
          onEditRequested: onEditRequested,
        ),
      ),
    );
  }

  // Helper to properly clean up animations in tests
  Future<void> cleanupAnimations(WidgetTester tester) async {
    await tester.pumpWidget(Container());
    await tester.pump();
  }

  group('ScanResultScreen', () {
    group('UI rendering', () {
      // Add cleanup after each test in this group
      tearDown(() async {
        // Give time for any pending animations to complete or be cancelled
      });

      testWidgets('renders species name', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            result: createResult(speciesName: 'Neon Tetra'),
            imageBytes: testImageBytes,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Neon Tetra'), findsOneWidget);

        await cleanupAnimations(tester);
      });

      testWidgets('renders species ID badge', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            result: createResult(speciesId: 'neon_tetra'),
            imageBytes: testImageBytes,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('ID: neon_tetra'), findsOneWidget);
      });

      testWidgets('renders confidence indicator', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            result: createResult(confidence: 0.75),
            imageBytes: testImageBytes,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ConfidenceIndicator), findsOneWidget);
      });

      testWidgets('renders AI Result badge in top bar', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(result: createResult(), imageBytes: testImageBytes),
        );
        await tester.pumpAndSettle();

        expect(find.text('AI Result'), findsOneWidget);
        expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      });

      testWidgets('renders back button', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(result: createResult(), imageBytes: testImageBytes),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });

      testWidgets('renders recommendations when present', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            result: createResult(
              recommendations: ['Feed twice daily', 'Clean tank weekly'],
            ),
            imageBytes: testImageBytes,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Recommendations'), findsOneWidget);
        expect(find.text('Feed twice daily'), findsOneWidget);
        expect(find.text('Clean tank weekly'), findsOneWidget);
      });

      testWidgets('does not render recommendations section when empty', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            result: createResult(recommendations: []),
            imageBytes: testImageBytes,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Recommendations'), findsNothing);
      });

      testWidgets('limits recommendations to 3 items', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            result: createResult(
              recommendations: ['Rec 1', 'Rec 2', 'Rec 3', 'Rec 4', 'Rec 5'],
            ),
            imageBytes: testImageBytes,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Rec 1'), findsOneWidget);
        expect(find.text('Rec 2'), findsOneWidget);
        expect(find.text('Rec 3'), findsOneWidget);
        expect(find.text('Rec 4'), findsNothing);
        expect(find.text('Rec 5'), findsNothing);
      });

      testWidgets('renders care level chip when provided', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            result: createResult(careLevel: 'beginner'),
            imageBytes: testImageBytes,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Beginner'), findsOneWidget);
        expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
      });

      testWidgets('renders feeding frequency chip when provided', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            result: createResult(feedingFrequency: 'twice_daily'),
            imageBytes: testImageBytes,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Twice daily'), findsOneWidget);
        expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
      });
    });

    group('High confidence (>= 80%)', () {
      testWidgets('renders Confirm and Not correct? buttons', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            result: createResult(confidence: 0.85),
            imageBytes: testImageBytes,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Confirm'), findsOneWidget);
        expect(find.text('Not correct?'), findsOneWidget);
      });

      testWidgets('does not show warning banner', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            result: createResult(confidence: 0.9),
            imageBytes: testImageBytes,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Low confidence. Please verify or select manually.'),
          findsNothing,
        );
      });
    });

    group('Medium confidence (50-79%)', () {
      testWidgets('renders Confirm and Not correct? buttons', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            result: createResult(confidence: 0.65),
            imageBytes: testImageBytes,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Confirm'), findsOneWidget);
        expect(find.text('Not correct?'), findsOneWidget);
      });

      testWidgets('does not show warning banner', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            result: createResult(confidence: 0.65),
            imageBytes: testImageBytes,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Low confidence. Please verify or select manually.'),
          findsNothing,
        );
      });
    });

    group('Low confidence (< 50%)', () {
      testWidgets('shows warning banner', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            result: createResult(confidence: 0.35),
            imageBytes: testImageBytes,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Low confidence. Please verify or select manually.'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      });

      testWidgets('renders Select Manually as primary button', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            result: createResult(confidence: 0.35),
            imageBytes: testImageBytes,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Select Manually'), findsOneWidget);
        expect(find.text('Confirm Anyway'), findsOneWidget);
      });

      testWidgets('shows edit icon on Select Manually button', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            result: createResult(confidence: 0.35),
            imageBytes: testImageBytes,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      });
    });

    group('Navigation', () {
      testWidgets('back button pops without result', (tester) async {
        ScanConfirmResult? poppedResult = const ScanConfirmResult(
          speciesId: 'placeholder',
          speciesName: 'Placeholder',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      poppedResult = await Navigator.of(context)
                          .push<ScanConfirmResult>(
                            MaterialPageRoute(
                              builder: (_) => ScanResultScreen(
                                result: createResult(),
                                imageBytes: testImageBytes,
                              ),
                            ),
                          );
                    },
                    child: const Text('Open Result'),
                  );
                },
              ),
            ),
          ),
        );

        // Open result screen
        await tester.tap(find.text('Open Result'));
        await tester.pumpAndSettle();

        // Tap back button
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        expect(poppedResult, isNull);

        // Clean up animations
        await cleanupAnimations(tester);
      });

      testWidgets('Confirm button pops with result', (tester) async {
        ScanConfirmResult? poppedResult;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      poppedResult = await Navigator.of(context)
                          .push<ScanConfirmResult>(
                            MaterialPageRoute(
                              builder: (_) => ScanResultScreen(
                                result: createResult(
                                  speciesId: 'guppy',
                                  speciesName: 'Guppy',
                                  recommendations: ['Feed daily'],
                                ),
                                imageBytes: testImageBytes,
                              ),
                            ),
                          );
                    },
                    child: const Text('Open Result'),
                  );
                },
              ),
            ),
          ),
        );

        // Open result screen
        await tester.tap(find.text('Open Result'));
        await tester.pumpAndSettle();

        // Tap Confirm button
        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();

        expect(poppedResult, isNotNull);
        expect(poppedResult!.speciesId, 'guppy');
        expect(poppedResult!.speciesName, 'Guppy');
        expect(poppedResult!.recommendations, ['Feed daily']);

        // Clean up animations
        await cleanupAnimations(tester);
      });

      testWidgets('Not correct? button calls onEditRequested and pops', (
        tester,
      ) async {
        var editRequested = false;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      await Navigator.of(context).push<ScanConfirmResult>(
                        MaterialPageRoute(
                          builder: (_) => ScanResultScreen(
                            result: createResult(confidence: 0.85),
                            imageBytes: testImageBytes,
                            onEditRequested: () => editRequested = true,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Result'),
                  );
                },
              ),
            ),
          ),
        );

        // Open result screen
        await tester.tap(find.text('Open Result'));
        await tester.pumpAndSettle();

        // Tap Not correct? button
        await tester.tap(find.text('Not correct?'));
        await tester.pumpAndSettle();

        expect(editRequested, isTrue);

        // Clean up animations
        await cleanupAnimations(tester);
      });

      testWidgets('Confirm Anyway button pops with result for low confidence', (
        tester,
      ) async {
        ScanConfirmResult? poppedResult;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      poppedResult = await Navigator.of(context)
                          .push<ScanConfirmResult>(
                            MaterialPageRoute(
                              builder: (_) => ScanResultScreen(
                                result: createResult(
                                  speciesId: 'unknown',
                                  speciesName: 'Unknown Fish',
                                  confidence: 0.35,
                                  recommendations: [],
                                ),
                                imageBytes: testImageBytes,
                              ),
                            ),
                          );
                    },
                    child: const Text('Open Result'),
                  );
                },
              ),
            ),
          ),
        );

        // Open result screen
        await tester.tap(find.text('Open Result'));
        await tester.pumpAndSettle();

        // Scroll to make button visible if needed
        await tester.ensureVisible(find.text('Confirm Anyway'));
        await tester.pumpAndSettle();

        // Tap Confirm Anyway button
        await tester.tap(find.text('Confirm Anyway'));
        await tester.pumpAndSettle();

        expect(poppedResult, isNotNull);
        expect(poppedResult!.speciesId, 'unknown');

        // Clean up animations
        await cleanupAnimations(tester);
      });

      testWidgets(
        'Select Manually button calls onEditRequested for low confidence',
        (tester) async {
          var editRequested = false;

          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () async {
                        await Navigator.of(context).push<ScanConfirmResult>(
                          MaterialPageRoute(
                            builder: (_) => ScanResultScreen(
                              result: createResult(
                                confidence: 0.35,
                                recommendations: [],
                              ),
                              imageBytes: testImageBytes,
                              onEditRequested: () => editRequested = true,
                            ),
                          ),
                        );
                      },
                      child: const Text('Open Result'),
                    );
                  },
                ),
              ),
            ),
          );

          // Open result screen
          await tester.tap(find.text('Open Result'));
          await tester.pumpAndSettle();

          // Scroll to make button visible if needed
          await tester.ensureVisible(find.text('Select Manually'));
          await tester.pumpAndSettle();

          // Tap Select Manually button
          await tester.tap(find.text('Select Manually'));
          await tester.pumpAndSettle();

          expect(editRequested, isTrue);

          // Clean up animations
          await cleanupAnimations(tester);
        },
      );
    });
  });

  group('ScanConfirmResult', () {
    test('stores all properties correctly', () {
      const result = ScanConfirmResult(
        speciesId: 'betta',
        speciesName: 'Betta',
        recommendations: ['Feed once daily', 'Keep alone'],
      );

      expect(result.speciesId, 'betta');
      expect(result.speciesName, 'Betta');
      expect(result.recommendations, ['Feed once daily', 'Keep alone']);
    });

    test('recommendations defaults to empty list', () {
      const result = ScanConfirmResult(
        speciesId: 'guppy',
        speciesName: 'Guppy',
      );

      expect(result.recommendations, isEmpty);
    });
  });
}
