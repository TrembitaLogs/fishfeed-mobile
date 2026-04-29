import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/screens/profile/widgets/profile_widgets.dart';

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
    VoidCallback? onShare,
    VoidCallback? onViewPremium,
  }) {
    return ProviderScope(
      overrides: [
        isPremiumProvider.overrideWith((ref) => isPremium),
        hasRemoveAdsProvider.overrideWith((ref) => hasRemoveAds),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProfileQuickActionsSection(
            onShareProfile: onShare ?? () {},
            onViewPremium: onViewPremium ?? () {},
          ),
        ),
      ),
    );
  }

  group('ProfileQuickActionsSection', () {
    testWidgets('free user sees Remove Ads upgrade button', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(isPremium: false, hasRemoveAds: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Share Profile'), findsOneWidget);
      expect(find.text('Remove Ads'), findsOneWidget);
      expect(find.text('View Premium'), findsNothing);
    });

    testWidgets('remove_ads-only user sees View Premium upgrade button', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(isPremium: false, hasRemoveAds: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('Share Profile'), findsOneWidget);
      expect(find.text('View Premium'), findsOneWidget);
      expect(find.text('Remove Ads'), findsNothing);
    });

    testWidgets(
      'premium user sees no upgrade button (closes sandbox issue #12)',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(isPremium: true, hasRemoveAds: true),
        );
        await tester.pumpAndSettle();

        expect(find.text('Share Profile'), findsOneWidget);
        expect(find.text('View Premium'), findsNothing);
        expect(find.text('Remove Ads'), findsNothing);
      },
    );

    testWidgets('share button invokes onShareProfile callback', (tester) async {
      var shareCalled = 0;
      await tester.pumpWidget(
        buildTestWidget(
          isPremium: false,
          hasRemoveAds: false,
          onShare: () => shareCalled++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Share Profile'));
      await tester.pumpAndSettle();

      expect(shareCalled, 1);
    });

    testWidgets('upgrade button invokes onViewPremium callback', (
      tester,
    ) async {
      var viewPremiumCalled = 0;
      await tester.pumpWidget(
        buildTestWidget(
          isPremium: false,
          hasRemoveAds: false,
          onViewPremium: () => viewPremiumCalled++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove Ads'));
      await tester.pumpAndSettle();

      expect(viewPremiumCalled, 1);
    });
  });
}
