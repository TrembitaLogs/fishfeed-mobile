import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/widgets/common/loading_indicator.dart';

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
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('LoadingIndicator', () {
    testWidgets('renders CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const LoadingIndicator(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders without message by default', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const LoadingIndicator(),
        ),
      );

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('renders with message when provided', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const LoadingIndicator(
            message: 'Loading data...',
          ),
        ),
      );

      expect(find.text('Loading data...'), findsOneWidget);
    });

    testWidgets('uses custom size', (tester) async {
      const customSize = 50.0;

      await tester.pumpWidget(
        buildTestWidget(
          const LoadingIndicator(
            size: customSize,
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        ),
      );

      expect(sizedBox.height, customSize);
      expect(sizedBox.width, customSize);
    });

    testWidgets('is centered', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const LoadingIndicator(),
        ),
      );

      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('uses theme primary color', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const LoadingIndicator(),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );

      final animation = indicator.valueColor as AlwaysStoppedAnimation<Color>;
      expect(animation.value, AppTheme.lightTheme.colorScheme.primary);
    });
  });
}
