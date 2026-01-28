import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/widgets/common/app_card.dart';

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
        body: Center(child: child),
      ),
    );
  }

  group('AppCard', () {
    testWidgets('renders Card widget', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppCard(
            child: Text('Card Content'),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('applies default padding', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppCard(
            child: Text('Padded Content'),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find.ancestor(
          of: find.text('Padded Content'),
          matching: find.byType(Padding),
        ).first,
      );

      expect(padding.padding, const EdgeInsets.all(16));
    });

    testWidgets('applies custom padding', (tester) async {
      const customPadding = EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 12,
      );

      await tester.pumpWidget(
        buildTestWidget(
          const AppCard(
            padding: customPadding,
            child: Text('Custom Padding'),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find.ancestor(
          of: find.text('Custom Padding'),
          matching: find.byType(Padding),
        ).first,
      );

      expect(padding.padding, customPadding);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          AppCard(
            onTap: () => tapped = true,
            child: const Text('Tappable Card'),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('renders InkWell when onTap is provided', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          AppCard(
            onTap: () {},
            child: const Text('With InkWell'),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('does not render InkWell when onTap is null', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppCard(
            child: Text('Without InkWell'),
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('applies custom elevation', (tester) async {
      const customElevation = 8.0;

      await tester.pumpWidget(
        buildTestWidget(
          const AppCard(
            elevation: customElevation,
            child: Text('Elevated Card'),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, customElevation);
    });

    testWidgets('uses theme card style', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AppCard(
            child: Text('Themed Card'),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, isNull);
    });
  });
}
