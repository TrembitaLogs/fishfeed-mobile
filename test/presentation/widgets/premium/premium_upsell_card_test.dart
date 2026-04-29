import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/widgets/premium/premium_upsell_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({
    required bool isPremium,
    required bool hasRemoveAds,
    bool showDismissButton = true,
    VoidCallback? onDismiss,
  }) {
    return ProviderScope(
      overrides: [
        isPremiumProvider.overrideWith((ref) => isPremium),
        hasRemoveAdsProvider.overrideWith((ref) => hasRemoveAds),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: PremiumUpsellCard(
                  showDismissButton: showDismissButton,
                  onDismiss: onDismiss,
                ),
              ),
            ),
            GoRoute(
              path: '/paywall',
              builder: (context, state) =>
                  const Scaffold(body: Center(child: Text('Paywall Screen'))),
            ),
          ],
        ),
      ),
    );
  }

  group('PremiumUpsellCard', () {
    testWidgets('renders nothing for premium users', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(isPremium: true, hasRemoveAds: true),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNothing);
      expect(find.text('Upgrade to Premium'), findsNothing);
    });

    testWidgets('renders all benefit chips for free users', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(isPremium: false, hasRemoveAds: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upgrade to Premium'), findsOneWidget);
      expect(find.text('No Ads'), findsOneWidget);
      expect(find.text('Unlimited AI Scans'), findsOneWidget);
      expect(find.text('6 Months History'), findsOneWidget);
    });

    testWidgets(
      'hides "No Ads" chip when user already owns remove_ads entitlement',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(isPremium: false, hasRemoveAds: true),
        );
        await tester.pumpAndSettle();

        // Card itself stays visible because user is not premium yet.
        expect(find.text('Upgrade to Premium'), findsOneWidget);
        // "No Ads" chip must be hidden — it is already owned.
        expect(find.text('No Ads'), findsNothing);
        // Other benefits still pitch premium upgrade.
        expect(find.text('Unlimited AI Scans'), findsOneWidget);
        expect(find.text('6 Months History'), findsOneWidget);
      },
    );

    testWidgets('navigates to paywall on View Plans tap', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(isPremium: false, hasRemoveAds: false),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Plans'));
      await tester.pumpAndSettle();

      expect(find.text('Paywall Screen'), findsOneWidget);
    });

    testWidgets('hides dismiss button when showDismissButton is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          isPremium: false,
          hasRemoveAds: false,
          showDismissButton: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
