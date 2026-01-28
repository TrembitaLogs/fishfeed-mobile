import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/widgets/paywall/benefit_item.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({
    IconData icon = Icons.star,
    String text = 'Test Benefit',
    Color? iconColor,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: BenefitItem(
          icon: icon,
          text: text,
          iconColor: iconColor,
        ),
      ),
    );
  }

  group('BenefitItem', () {
    testWidgets('renders icon and text', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('Test Benefit'), findsOneWidget);
    });

    testWidgets('renders check icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays different icons correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        icon: Icons.camera_enhance,
        text: 'Unlimited AI Scans',
      ));

      expect(find.byIcon(Icons.camera_enhance), findsOneWidget);
      expect(find.text('Unlimited AI Scans'), findsOneWidget);
    });

    testWidgets('applies custom icon color', (tester) async {
      const customColor = Colors.red;

      await tester.pumpWidget(buildTestWidget(
        iconColor: customColor,
      ));

      final iconFinder = find.byIcon(Icons.star);
      final iconWidget = tester.widget<Icon>(iconFinder);

      expect(iconWidget.color, equals(customColor));
    });

    testWidgets('uses primary color by default for icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final iconFinder = find.byIcon(Icons.star);
      final iconWidget = tester.widget<Icon>(iconFinder);
      final context = tester.element(iconFinder);
      final theme = Theme.of(context);

      expect(iconWidget.color, equals(theme.colorScheme.primary));
    });

    testWidgets('wraps long text correctly', (tester) async {
      const longText = 'This is a very long benefit description that should wrap correctly in the widget';

      await tester.pumpWidget(buildTestWidget(text: longText));

      expect(find.text(longText), findsOneWidget);
    });
  });
}
