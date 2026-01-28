import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/widgets/confidence_indicator.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('ConfidenceLevel extension', () {
    test('returns high for confidence >= 0.8', () {
      expect(0.8.confidenceLevel, ConfidenceLevel.high);
      expect(0.9.confidenceLevel, ConfidenceLevel.high);
      expect(1.0.confidenceLevel, ConfidenceLevel.high);
    });

    test('returns medium for confidence >= 0.5 and < 0.8', () {
      expect(0.5.confidenceLevel, ConfidenceLevel.medium);
      expect(0.6.confidenceLevel, ConfidenceLevel.medium);
      expect(0.79.confidenceLevel, ConfidenceLevel.medium);
    });

    test('returns low for confidence < 0.5', () {
      expect(0.0.confidenceLevel, ConfidenceLevel.low);
      expect(0.3.confidenceLevel, ConfidenceLevel.low);
      expect(0.49.confidenceLevel, ConfidenceLevel.low);
    });
  });

  group('ConfidenceIndicator', () {
    testWidgets('renders with given confidence value', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ConfidenceIndicator(confidence: 0.85, showPulse: false),
        ),
      );
      await tester.pumpAndSettle();

      // Should render circular progress indicators
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      // Should display "confidence" label
      expect(find.text('confidence'), findsOneWidget);
    });

    testWidgets('displays percentage correctly for high confidence', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ConfidenceIndicator(confidence: 0.85, showPulse: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('displays percentage correctly for medium confidence', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ConfidenceIndicator(confidence: 0.65, showPulse: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('65%'), findsOneWidget);
    });

    testWidgets('displays percentage correctly for low confidence', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ConfidenceIndicator(confidence: 0.35, showPulse: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('35%'), findsOneWidget);
    });

    testWidgets('respects size parameter', (tester) async {
      const testSize = 150.0;
      await tester.pumpWidget(
        buildTestWidget(
          const ConfidenceIndicator(
            confidence: 0.75,
            size: testSize,
            showPulse: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, testSize);
      expect(sizedBox.height, testSize);
    });

    testWidgets('uses green color for high confidence', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ConfidenceIndicator(confidence: 0.85, showPulse: false),
        ),
      );
      await tester.pumpAndSettle();

      // Find the progress indicator with value color
      final progressIndicators = tester.widgetList<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );

      // One of them should have green color (progress circle)
      final hasGreenIndicator = progressIndicators.any((indicator) {
        final valueColor = indicator.valueColor;
        if (valueColor is AlwaysStoppedAnimation<Color>) {
          // Check if it's greenish (green shade 600)
          return valueColor.value.g > valueColor.value.r &&
              valueColor.value.g > valueColor.value.b;
        }
        return false;
      });
      expect(hasGreenIndicator, isTrue);
    });

    testWidgets('uses amber color for medium confidence', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ConfidenceIndicator(confidence: 0.65, showPulse: false),
        ),
      );
      await tester.pumpAndSettle();

      final progressIndicators = tester.widgetList<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );

      // One of them should have amber/yellow color
      final hasAmberIndicator = progressIndicators.any((indicator) {
        final valueColor = indicator.valueColor;
        if (valueColor is AlwaysStoppedAnimation<Color>) {
          // Amber has high red and green, low blue (using 0.0-1.0 scale)
          return valueColor.value.r > 0.78 &&
              valueColor.value.g > 0.59 &&
              valueColor.value.b < 0.39;
        }
        return false;
      });
      expect(hasAmberIndicator, isTrue);
    });

    testWidgets('uses red color for low confidence', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ConfidenceIndicator(confidence: 0.35, showPulse: false),
        ),
      );
      await tester.pumpAndSettle();

      final progressIndicators = tester.widgetList<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );

      // One of them should have red color
      final hasRedIndicator = progressIndicators.any((indicator) {
        final valueColor = indicator.valueColor;
        if (valueColor is AlwaysStoppedAnimation<Color>) {
          return valueColor.value.r > valueColor.value.g &&
              valueColor.value.r > valueColor.value.b;
        }
        return false;
      });
      expect(hasRedIndicator, isTrue);
    });

    testWidgets('animates when shown', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ConfidenceIndicator(
            confidence: 0.85,
            showPulse: false,
            animationDuration: Duration(milliseconds: 500),
          ),
        ),
      );

      // Initial state - animation not complete
      await tester.pump(const Duration(milliseconds: 100));

      // After some time, animation should progress
      await tester.pump(const Duration(milliseconds: 200));

      // After animation completes
      await tester.pumpAndSettle();

      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('updates when confidence changes', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ConfidenceIndicator(confidence: 0.5, showPulse: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('50%'), findsOneWidget);

      // Rebuild with new confidence
      await tester.pumpWidget(
        buildTestWidget(
          const ConfidenceIndicator(confidence: 0.9, showPulse: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('90%'), findsOneWidget);
    });

    testWidgets('shows pulse animation when enabled', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ConfidenceIndicator(confidence: 0.85, showPulse: true),
        ),
      );

      // Pump a few frames to see animation in progress
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Widget should still be rendering (with pulse animation)
      expect(find.byType(ConfidenceIndicator), findsOneWidget);

      // Clean up by removing the widget before test ends
      await tester.pumpWidget(Container());
    });

    testWidgets('handles zero confidence', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ConfidenceIndicator(confidence: 0.0, showPulse: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('handles full confidence', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ConfidenceIndicator(confidence: 1.0, showPulse: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('respects custom stroke width', (tester) async {
      const customStrokeWidth = 12.0;
      await tester.pumpWidget(
        buildTestWidget(
          const ConfidenceIndicator(
            confidence: 0.75,
            strokeWidth: customStrokeWidth,
            showPulse: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final progressIndicators = tester.widgetList<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );

      // All indicators should have the custom stroke width
      for (final indicator in progressIndicators) {
        expect(indicator.strokeWidth, customStrokeWidth);
      }
    });
  });
}
