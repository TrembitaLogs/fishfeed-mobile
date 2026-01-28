import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/widgets/premium/premium_badge.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({
    required SubscriptionStatus status,
    PremiumBadgeSize size = PremiumBadgeSize.medium,
    bool showLabel = true,
    VoidCallback? onTap,
  }) {
    return ProviderScope(
      overrides: [
        subscriptionStatusProvider.overrideWith((ref) => status),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: PremiumBadge(
              size: size,
              showLabel: showLabel,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }

  group('PremiumBadge', () {
    group('free user', () {
      testWidgets('displays Free label', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(status: const SubscriptionStatus.free()),
        );

        expect(find.text('Free'), findsOneWidget);
      });

      testWidgets('displays person icon', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(status: const SubscriptionStatus.free()),
        );

        expect(find.byIcon(Icons.person_outline), findsOneWidget);
      });
    });

    group('premium user', () {
      testWidgets('displays Premium label', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(status: SubscriptionStatus.premium()),
        );

        expect(find.text('Premium'), findsOneWidget);
      });

      testWidgets('displays premium icon', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(status: SubscriptionStatus.premium()),
        );

        expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
      });
    });

    group('trial user', () {
      testWidgets('displays Trial label', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            status: SubscriptionStatus.premium(
              isTrialActive: true,
              expirationDate: DateTime.now().add(const Duration(days: 7)),
            ),
          ),
        );

        expect(find.text('Trial'), findsOneWidget);
      });

      testWidgets('displays hourglass icon', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            status: SubscriptionStatus.premium(
              isTrialActive: true,
              expirationDate: DateTime.now().add(const Duration(days: 7)),
            ),
          ),
        );

        expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
      });
    });

    group('size variants', () {
      testWidgets('small size renders correctly', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            status: SubscriptionStatus.premium(),
            size: PremiumBadgeSize.small,
          ),
        );

        expect(find.byType(PremiumBadge), findsOneWidget);
        expect(find.text('Premium'), findsOneWidget);
      });

      testWidgets('medium size renders correctly', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            status: SubscriptionStatus.premium(),
            size: PremiumBadgeSize.medium,
          ),
        );

        expect(find.byType(PremiumBadge), findsOneWidget);
        expect(find.text('Premium'), findsOneWidget);
      });

      testWidgets('large size renders correctly', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            status: SubscriptionStatus.premium(),
            size: PremiumBadgeSize.large,
          ),
        );

        expect(find.byType(PremiumBadge), findsOneWidget);
        expect(find.text('Premium'), findsOneWidget);
      });
    });

    group('showLabel', () {
      testWidgets('hides label when showLabel is false', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            status: SubscriptionStatus.premium(),
            showLabel: false,
          ),
        );

        expect(find.text('Premium'), findsNothing);
        expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
      });

      testWidgets('shows label when showLabel is true', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            status: SubscriptionStatus.premium(),
            showLabel: true,
          ),
        );

        expect(find.text('Premium'), findsOneWidget);
      });
    });

    group('interactions', () {
      testWidgets('calls onTap when tapped', (tester) async {
        var tapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            status: const SubscriptionStatus.free(),
            onTap: () => tapped = true,
          ),
        );

        await tester.tap(find.byType(PremiumBadge));
        expect(tapped, isTrue);
      });

      testWidgets('does not crash when onTap is null', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            status: const SubscriptionStatus.free(),
            onTap: null,
          ),
        );

        await tester.tap(find.byType(PremiumBadge));
        // Should not throw
      });
    });
  });

  group('PremiumBadgeSize enum', () {
    test('has all expected values', () {
      expect(PremiumBadgeSize.values, contains(PremiumBadgeSize.small));
      expect(PremiumBadgeSize.values, contains(PremiumBadgeSize.medium));
      expect(PremiumBadgeSize.values, contains(PremiumBadgeSize.large));
      expect(PremiumBadgeSize.values.length, equals(3));
    });
  });
}
