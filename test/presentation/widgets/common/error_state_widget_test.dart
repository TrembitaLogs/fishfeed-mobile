import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/widgets/common/error_state_widget.dart';

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
      home: Scaffold(body: child),
    );
  }

  group('ErrorStateWidget', () {
    testWidgets('renders title, description and retry button', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          ErrorStateWidget(
            title: 'Error occurred',
            description: 'Something went wrong',
            onRetry: () async {},
            animate: false,
          ),
        ),
      );

      expect(find.text('Error occurred'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('uses custom retry label when provided', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          ErrorStateWidget(
            title: 'Error',
            description: 'Failed to load',
            onRetry: () async {},
            retryLabel: 'Retry Now',
            animate: false,
          ),
        ),
      );

      expect(find.text('Retry Now'), findsOneWidget);
    });

    testWidgets('calls onRetry when retry button is pressed', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        buildTestWidget(
          ErrorStateWidget(
            title: 'Error',
            description: 'Failed to load',
            onRetry: () async {
              retried = true;
            },
            animate: false,
          ),
        ),
      );

      await tester.tap(find.text('Try Again'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('shows loading indicator while retrying', (tester) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        buildTestWidget(
          ErrorStateWidget(
            title: 'Error',
            description: 'Failed to load',
            onRetry: () => completer.future,
            animate: false,
          ),
        ),
      );

      await tester.tap(find.text('Try Again'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future to allow the test to finish
      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('shows secondary action when provided', (tester) async {
      var secondaryPressed = false;

      await tester.pumpWidget(
        buildTestWidget(
          ErrorStateWidget(
            title: 'Error',
            description: 'Failed to load',
            onRetry: () async {},
            secondaryActionLabel: 'Contact Support',
            onSecondaryAction: () => secondaryPressed = true,
            animate: false,
          ),
        ),
      );

      expect(find.text('Contact Support'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);

      await tester.tap(find.byType(TextButton));
      expect(secondaryPressed, isTrue);
    });

    testWidgets('does not show secondary action when label is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          ErrorStateWidget(
            title: 'Error',
            description: 'Failed to load',
            onRetry: () async {},
            onSecondaryAction: () {},
            animate: false,
          ),
        ),
      );

      expect(find.byType(TextButton), findsNothing);
    });

    group('error types', () {
      testWidgets('shows network icon for network error', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            ErrorStateWidget(
              title: 'No connection',
              description: 'Check your internet',
              onRetry: () async {},
              errorType: ErrorType.network,
              animate: false,
            ),
          ),
        );

        expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      });

      testWidgets('shows cloud icon for server error', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            ErrorStateWidget(
              title: 'Server error',
              description: 'Please try again',
              onRetry: () async {},
              errorType: ErrorType.server,
              animate: false,
            ),
          ),
        );

        expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      });

      testWidgets('shows timer icon for timeout error', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            ErrorStateWidget(
              title: 'Timeout',
              description: 'Request took too long',
              onRetry: () async {},
              errorType: ErrorType.timeout,
              animate: false,
            ),
          ),
        );

        expect(find.byIcon(Icons.timer_off_rounded), findsOneWidget);
      });

      testWidgets('shows error icon for generic error', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            ErrorStateWidget(
              title: 'Error',
              description: 'Something went wrong',
              onRetry: () async {},
              errorType: ErrorType.generic,
              animate: false,
            ),
          ),
        );

        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      });
    });

    testWidgets('uses custom illustration when provided', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          ErrorStateWidget(
            title: 'Error',
            description: 'Failed to load',
            onRetry: () async {},
            illustration: const Icon(
              Icons.star,
              key: Key('custom_illustration'),
            ),
            animate: false,
          ),
        ),
      );

      expect(find.byKey(const Key('custom_illustration')), findsOneWidget);
    });
  });

  group('ErrorStateWidget factory constructors', () {
    testWidgets('network factory sets correct error type', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          ErrorStateWidget.network(
            title: 'No connection',
            description: 'Check your internet',
            onRetry: () async {},
          ),
        ),
      );

      // Animation starts, let it settle
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('server factory sets correct error type', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          ErrorStateWidget.server(
            title: 'Server error',
            description: 'Please try again',
            onRetry: () async {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });

    testWidgets('timeout factory sets correct error type', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          ErrorStateWidget.timeout(
            title: 'Timeout',
            description: 'Request took too long',
            onRetry: () async {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.timer_off_rounded), findsOneWidget);
    });
  });

  group('ScrollableErrorState', () {
    testWidgets('renders ErrorStateWidget inside CustomScrollView', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          ScrollableErrorState(
            title: 'Error',
            description: 'Failed to load',
            onRetry: () async {},
            animate: false,
          ),
        ),
      );

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('supports pull to refresh with RefreshIndicator', (
      tester,
    ) async {
      var refreshed = false;

      await tester.pumpWidget(
        buildTestWidget(
          RefreshIndicator(
            onRefresh: () async => refreshed = true,
            child: ScrollableErrorState(
              title: 'Error',
              description: 'Failed to load',
              onRetry: () async {},
              animate: false,
            ),
          ),
        ),
      );

      // Fling down to trigger refresh
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(refreshed, isTrue);
    });
  });
}
