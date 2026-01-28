import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/widgets/paywall/product_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({
    String title = 'Monthly',
    String price = '\$3.99/month',
    String? subtitle,
    String? badge,
    String? savings,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: ProductCard(
          title: title,
          price: price,
          subtitle: subtitle,
          badge: badge,
          savings: savings,
          isSelected: isSelected,
          onTap: onTap ?? () {},
        ),
      ),
    );
  }

  group('ProductCard', () {
    testWidgets('renders title and price', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('\$3.99/month'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(subtitle: 'Most Flexible'));

      expect(find.text('Most Flexible'), findsOneWidget);
    });

    testWidgets('does not render subtitle when not provided', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Most Flexible'), findsNothing);
    });

    testWidgets('renders badge when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(badge: 'Best Value'));

      expect(find.text('Best Value'), findsOneWidget);
    });

    testWidgets('does not render badge when not provided', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Best Value'), findsNothing);
    });

    testWidgets('renders savings when provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(savings: 'Save 37%'));

      expect(find.text('Save 37%'), findsOneWidget);
    });

    testWidgets('does not render savings when not provided', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Save 37%'), findsNothing);
    });

    testWidgets('shows selected state correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget(isSelected: true));

      // Check icon is visible when selected
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('does not show check icon when not selected', (tester) async {
      await tester.pumpWidget(buildTestWidget(isSelected: false));

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(buildTestWidget(onTap: () => tapped = true));

      await tester.tap(find.byType(ProductCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders annual product with all options', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          title: 'Annual',
          price: '\$29.99/year',
          subtitle: '\$2.50/month',
          badge: 'Best Value',
          savings: 'Save 37%',
          isSelected: true,
        ),
      );

      expect(find.text('Annual'), findsOneWidget);
      expect(find.text('\$29.99/year'), findsOneWidget);
      expect(find.text('\$2.50/month'), findsOneWidget);
      expect(find.text('Best Value'), findsOneWidget);
      expect(find.text('Save 37%'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('has different border when selected', (tester) async {
      await tester.pumpWidget(buildTestWidget(isSelected: true));

      final containerFinder = find.byType(AnimatedContainer).first;
      final container = tester.widget<AnimatedContainer>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.border, isNotNull);
      expect(decoration.border!.top.width, equals(2));
    });

    testWidgets('has thin border when not selected', (tester) async {
      await tester.pumpWidget(buildTestWidget(isSelected: false));

      final containerFinder = find.byType(AnimatedContainer).first;
      final container = tester.widget<AnimatedContainer>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.border, isNotNull);
      expect(decoration.border!.top.width, equals(1));
    });
  });
}
