import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/core/utils/premium_gate.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/widgets/premium/premium_feature_guard.dart';

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
    PremiumFeature feature = PremiumFeature.extendedStatistics,
    Widget? child,
    bool showBlur = true,
    bool showLockIcon = true,
    bool showUpgradeButton = true,
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
                body: SizedBox(
                  width: 400,
                  height: 400,
                  child: PremiumFeatureGuard(
                    feature: feature,
                    showBlur: showBlur,
                    showLockIcon: showLockIcon,
                    showUpgradeButton: showUpgradeButton,
                    child:
                        child ??
                        const SizedBox(
                          width: 400,
                          height: 400,
                          child: Center(child: Text('Premium Content')),
                        ),
                  ),
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

  group('PremiumFeatureGuard', () {
    group('when user has access', () {
      testWidgets('shows child content for premium user', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(isPremium: true, hasRemoveAds: true),
        );
        await tester.pumpAndSettle();

        expect(find.text('Premium Content'), findsOneWidget);
        expect(find.byIcon(Icons.lock_outline), findsNothing);
      });

      testWidgets('shows child for noAds feature with removeAds purchase', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            isPremium: false,
            hasRemoveAds: true,
            feature: PremiumFeature.noAds,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Premium Content'), findsOneWidget);
        expect(find.byIcon(Icons.lock_outline), findsNothing);
      });
    });

    group('when user does not have access', () {
      testWidgets('shows lock overlay for free user', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(isPremium: false, hasRemoveAds: false),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      });

      testWidgets('shows feature name in overlay', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            isPremium: false,
            hasRemoveAds: false,
            feature: PremiumFeature.extendedStatistics,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(PremiumFeature.extendedStatistics.displayName),
          findsOneWidget,
        );
      });

      testWidgets('shows Premium feature text', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(isPremium: false, hasRemoveAds: false),
        );
        await tester.pumpAndSettle();

        expect(find.text('Premium feature'), findsOneWidget);
      });

      testWidgets('shows upgrade button by default', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(isPremium: false, hasRemoveAds: false),
        );
        await tester.pumpAndSettle();

        expect(find.text('Upgrade'), findsOneWidget);
      });

      testWidgets('hides upgrade button when showUpgradeButton is false', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            isPremium: false,
            hasRemoveAds: false,
            showUpgradeButton: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Upgrade'), findsNothing);
      });

      testWidgets('hides lock icon when showLockIcon is false', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            isPremium: false,
            hasRemoveAds: false,
            showLockIcon: false,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.lock_outline), findsNothing);
      });

      testWidgets('navigates to paywall when upgrade is tapped', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(isPremium: false, hasRemoveAds: false),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Upgrade'));
        await tester.pumpAndSettle();

        expect(find.text('Paywall Screen'), findsOneWidget);
      });
    });
  });

  group('LockedFeatureOverlay', () {
    Widget buildOverlayTestWidget({
      PremiumFeature feature = PremiumFeature.extendedStatistics,
      bool compact = false,
      VoidCallback? onUpgradeTap,
    }) {
      return MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: LockedFeatureOverlay(
                    feature: feature,
                    compact: compact,
                    onUpgradeTap: onUpgradeTap,
                  ),
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
      );
    }

    testWidgets('displays feature name', (tester) async {
      await tester.pumpWidget(buildOverlayTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text(PremiumFeature.extendedStatistics.displayName),
        findsOneWidget,
      );
    });

    testWidgets('displays feature description in full mode', (tester) async {
      await tester.pumpWidget(buildOverlayTestWidget(compact: false));
      await tester.pumpAndSettle();

      expect(
        find.text(PremiumFeature.extendedStatistics.description),
        findsOneWidget,
      );
    });

    testWidgets('shows lock icon', (tester) async {
      await tester.pumpWidget(buildOverlayTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('shows upgrade button in full mode', (tester) async {
      await tester.pumpWidget(buildOverlayTestWidget(compact: false));
      await tester.pumpAndSettle();

      expect(find.text('Upgrade to Premium'), findsOneWidget);
    });

    testWidgets('shows compact message in compact mode', (tester) async {
      await tester.pumpWidget(buildOverlayTestWidget(compact: true));
      await tester.pumpAndSettle();

      expect(find.textContaining('Upgrade to unlock'), findsOneWidget);
    });

    testWidgets('navigates to paywall on tap in full mode', (tester) async {
      await tester.pumpWidget(buildOverlayTestWidget(compact: false));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Upgrade to Premium'));
      await tester.pumpAndSettle();

      expect(find.text('Paywall Screen'), findsOneWidget);
    });

    testWidgets('navigates to paywall on tap in compact mode', (tester) async {
      await tester.pumpWidget(buildOverlayTestWidget(compact: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(LockedFeatureOverlay));
      await tester.pumpAndSettle();

      expect(find.text('Paywall Screen'), findsOneWidget);
    });

    testWidgets('calls custom onUpgradeTap if provided', (tester) async {
      var customTapped = false;

      await tester.pumpWidget(
        buildOverlayTestWidget(
          compact: false,
          onUpgradeTap: () => customTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Upgrade to Premium'));
      await tester.pumpAndSettle();

      expect(customTapped, isTrue);
    });
  });
}
