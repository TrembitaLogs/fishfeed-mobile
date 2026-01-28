import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/widgets/paywall/ai_scan_paywall_bottom_sheet.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({Widget? child}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: const MediaQueryData(size: Size(400, 800)),
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return child ??
                  ElevatedButton(
                    onPressed: () => AiScanPaywallBottomSheet.show(context),
                    child: const Text('Show Paywall'),
                  );
            },
          ),
        ),
      ),
    );
  }

  group('AiScanPaywallBottomSheet', () {
    testWidgets('renders title and description', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Show Paywall'));
      await tester.pumpAndSettle();

      expect(find.text("You've used all free scans"), findsOneWidget);
      expect(
        find.textContaining('Upgrade to Premium for unlimited AI fish'),
        findsOneWidget,
      );
    });

    testWidgets('renders benefit list', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Show Paywall'));
      await tester.pumpAndSettle();

      expect(find.text('Unlimited AI scans'), findsOneWidget);
      expect(find.text('Priority processing'), findsOneWidget);
      expect(find.text('Higher accuracy'), findsOneWidget);
    });

    testWidgets('renders all action buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Show Paywall'));
      await tester.pumpAndSettle();

      expect(find.text('Go Premium'), findsOneWidget);
      expect(find.text('Add manually'), findsOneWidget);
      expect(find.text('Maybe later'), findsOneWidget);
    });

    testWidgets('returns goPremium when Go Premium is tapped', (tester) async {
      PaywallAction? result;

      await tester.pumpWidget(buildTestWidget(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await AiScanPaywallBottomSheet.show(context);
              },
              child: const Text('Show Paywall'),
            );
          },
        ),
      ));

      await tester.tap(find.text('Show Paywall'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go Premium'));
      await tester.pumpAndSettle();

      expect(result, equals(PaywallAction.goPremium));
    });

    testWidgets('returns addManually when Add manually is tapped', (tester) async {
      PaywallAction? result;

      await tester.pumpWidget(buildTestWidget(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await AiScanPaywallBottomSheet.show(context);
              },
              child: const Text('Show Paywall'),
            );
          },
        ),
      ));

      await tester.tap(find.text('Show Paywall'));
      await tester.pumpAndSettle();

      // Scroll to make the button visible
      await tester.ensureVisible(find.text('Add manually'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add manually'));
      await tester.pumpAndSettle();

      expect(result, equals(PaywallAction.addManually));
    });

    testWidgets('returns dismissed when Maybe later is tapped', (tester) async {
      PaywallAction? result;

      await tester.pumpWidget(buildTestWidget(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await AiScanPaywallBottomSheet.show(context);
              },
              child: const Text('Show Paywall'),
            );
          },
        ),
      ));

      await tester.tap(find.text('Show Paywall'));
      await tester.pumpAndSettle();

      // Scroll to make the button visible
      await tester.ensureVisible(find.text('Maybe later'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Maybe later'));
      await tester.pumpAndSettle();

      expect(result, equals(PaywallAction.dismissed));
    });

    testWidgets('returns null when dismissed by tapping outside', (tester) async {
      PaywallAction? result;
      var showCompleted = false;

      await tester.pumpWidget(buildTestWidget(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await AiScanPaywallBottomSheet.show(context);
                showCompleted = true;
              },
              child: const Text('Show Paywall'),
            );
          },
        ),
      ));

      await tester.tap(find.text('Show Paywall'));
      await tester.pumpAndSettle();

      // Tap outside the bottom sheet (top of screen)
      await tester.tapAt(const Offset(200, 50));
      await tester.pumpAndSettle();

      expect(showCompleted, isTrue);
      expect(result, isNull);
    });

    testWidgets('bottom sheet is present after opening', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Show Paywall'));
      await tester.pumpAndSettle();

      expect(find.byType(AiScanPaywallBottomSheet), findsOneWidget);
    });
  });

  group('PaywallAction enum', () {
    test('has all expected values', () {
      expect(PaywallAction.values, contains(PaywallAction.goPremium));
      expect(PaywallAction.values, contains(PaywallAction.addManually));
      expect(PaywallAction.values, contains(PaywallAction.dismissed));
      expect(PaywallAction.values.length, equals(3));
    });
  });
}
