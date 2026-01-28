import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/widgets/premium/premium_chip.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({
    PremiumChipSize size = PremiumChipSize.small,
    bool showIcon = true,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: PremiumChip(
            size: size,
            showIcon: showIcon,
          ),
        ),
      ),
    );
  }

  group('PremiumChip', () {
    testWidgets('displays PRO label', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('PRO'), findsOneWidget);
    });

    testWidgets('displays premium icon by default', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
    });

    testWidgets('hides icon when showIcon is false', (tester) async {
      await tester.pumpWidget(buildTestWidget(showIcon: false));

      expect(find.byIcon(Icons.workspace_premium), findsNothing);
      expect(find.text('PRO'), findsOneWidget);
    });

    group('size variants', () {
      testWidgets('tiny size renders correctly', (tester) async {
        await tester.pumpWidget(buildTestWidget(size: PremiumChipSize.tiny));

        expect(find.byType(PremiumChip), findsOneWidget);
        expect(find.text('PRO'), findsOneWidget);
      });

      testWidgets('small size renders correctly', (tester) async {
        await tester.pumpWidget(buildTestWidget(size: PremiumChipSize.small));

        expect(find.byType(PremiumChip), findsOneWidget);
        expect(find.text('PRO'), findsOneWidget);
      });

      testWidgets('medium size renders correctly', (tester) async {
        await tester.pumpWidget(buildTestWidget(size: PremiumChipSize.medium));

        expect(find.byType(PremiumChip), findsOneWidget);
        expect(find.text('PRO'), findsOneWidget);
      });
    });
  });

  group('PremiumChipSize enum', () {
    test('has all expected values', () {
      expect(PremiumChipSize.values, contains(PremiumChipSize.tiny));
      expect(PremiumChipSize.values, contains(PremiumChipSize.small));
      expect(PremiumChipSize.values, contains(PremiumChipSize.medium));
      expect(PremiumChipSize.values.length, equals(3));
    });
  });
}
