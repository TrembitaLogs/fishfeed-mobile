import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/widgets/paywall/remove_ads_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({
    required String price,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: RemoveAdsCard(price: price, onTap: onTap, isLoading: isLoading),
      ),
    );
  }

  group('RemoveAdsCard', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(buildTestWidget(price: '\$3.99', onTap: () {}));

      expect(find.text('Remove Ads'), findsOneWidget);
      expect(find.text('One-time purchase'), findsOneWidget);
    });

    testWidgets('renders price', (tester) async {
      await tester.pumpWidget(buildTestWidget(price: '\$3.99', onTap: () {}));

      expect(find.text('\$3.99'), findsOneWidget);
    });

    testWidgets('renders block icon', (tester) async {
      await tester.pumpWidget(buildTestWidget(price: '\$3.99', onTap: () {}));

      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildTestWidget(price: '\$3.99', onTap: () => tapped = true),
      );

      await tester.tap(find.byType(RemoveAdsCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows loading indicator when isLoading is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(price: '\$3.99', onTap: () {}, isLoading: true),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Price should not be visible when loading
      expect(find.text('\$3.99'), findsNothing);
    });

    testWidgets('does not call onTap when loading', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          price: '\$3.99',
          onTap: () => tapped = true,
          isLoading: true,
        ),
      );

      await tester.tap(find.byType(RemoveAdsCard));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('does not throw when onTap is null', (tester) async {
      await tester.pumpWidget(buildTestWidget(price: '\$3.99', onTap: null));

      // Should not throw
      await tester.tap(find.byType(RemoveAdsCard));
      await tester.pump();

      expect(find.byType(RemoveAdsCard), findsOneWidget);
    });
  });
}
