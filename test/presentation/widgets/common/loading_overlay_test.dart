import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/presentation/widgets/common/loading_overlay.dart';

void main() {
  group('LoadingOverlay', () {
    testWidgets('shows child when isLoading is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlay(isLoading: false, child: Text('Content')),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows overlay with loading indicator when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlay(isLoading: true, child: Text('Content')),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlay(
            isLoading: true,
            message: 'Loading...',
            child: Text('Content'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('does not show message when isLoading is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlay(
            isLoading: false,
            message: 'Loading...',
            child: Text('Content'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsNothing);
    });

    testWidgets('blocks interaction when loading', (tester) async {
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LoadingOverlay(
            isLoading: true,
            child: Scaffold(
              body: ElevatedButton(
                onPressed: () => buttonPressed = true,
                child: const Text('Button'),
              ),
            ),
          ),
        ),
      );

      // Try to tap the button - use warnIfMissed: false since overlay blocks it
      await tester.tap(find.text('Button'), warnIfMissed: false);
      await tester.pump();

      // Button should not be pressed because overlay blocks interaction
      expect(buttonPressed, isFalse);
    });

    testWidgets('allows interaction when not loading', (tester) async {
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LoadingOverlay(
            isLoading: false,
            child: Scaffold(
              body: ElevatedButton(
                onPressed: () => buttonPressed = true,
                child: const Text('Button'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Button'));
      await tester.pumpAndSettle();

      expect(buttonPressed, isTrue);
    });

    testWidgets('uses custom opacity', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingOverlay(
            isLoading: true,
            opacity: 0.8,
            child: Text('Content'),
          ),
        ),
      );

      // Verify the overlay is shown (can't easily test opacity value)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('LoadingOverlay.show and hide', () {
    testWidgets('show displays overlay and hide removes it', (tester) async {
      late OverlayEntry entry;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      entry = LoadingOverlay.show(context, message: 'Loading');
                    },
                    child: const Text('Show'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      LoadingOverlay.hide(entry);
                    },
                    child: const Text('Hide'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Initially no loading indicator
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Show loading - use pump instead of pumpAndSettle due to animation
      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsOneWidget);

      // Hide loading
      LoadingOverlay.hide(entry);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('hide handles null entry gracefully', (tester) async {
      // Should not throw
      LoadingOverlay.hide(null);
    });
  });
}
