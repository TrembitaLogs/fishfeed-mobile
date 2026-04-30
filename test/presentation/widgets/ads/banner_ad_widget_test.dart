import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/providers/ad_provider.dart';
import 'package:fishfeed/presentation/widgets/ads/banner_ad_widget.dart';
import 'package:fishfeed/services/ads/ad_service.dart';

class MockAdService extends Mock implements AdService {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  late MockAdService mockAdService;

  setUp(() {
    mockAdService = MockAdService();
  });

  Widget buildTestWidget({
    required bool shouldShowAds,
    Future<BannerAd?> Function(int width)? onLoad,
  }) {
    if (onLoad != null) {
      when(
        () => mockAdService.loadBannerAd(any()),
      ).thenAnswer((inv) => onLoad(inv.positionalArguments[0] as int));
    }

    return ProviderScope(
      overrides: [
        shouldShowAdsProvider.overrideWithValue(shouldShowAds),
        adServiceProvider.overrideWithValue(mockAdService),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Center(child: BannerAdWidget())),
      ),
    );
  }

  group('BannerAdWidget', () {
    testWidgets('renders SizedBox.shrink when shouldShowAds is false', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(shouldShowAds: false));
      await tester.pump();

      expect(find.byType(AdWidget), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // No load attempt happened — ads disabled.
      verifyNever(() => mockAdService.loadBannerAd(any()));
    });

    testWidgets(
      'shows loading indicator while ad is in flight when ads enabled',
      (tester) async {
        final completer = Completer<BannerAd?>();
        await tester.pumpWidget(
          buildTestWidget(
            shouldShowAds: true,
            onLoad: (_) => completer.future,
          ),
        );

        // Allow the post-frame callback to schedule the load.
        await tester.pump();
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(AdWidget), findsNothing);

        // Complete with null so the widget can finish without leaking timers.
        completer.complete(null);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'renders nothing when load returns null and is no longer loading',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(shouldShowAds: true, onLoad: (_) async => null),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AdWidget), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets('attempts to load exactly once per widget instance', (
      tester,
    ) async {
      var loadCount = 0;
      await tester.pumpWidget(
        buildTestWidget(
          shouldShowAds: true,
          onLoad: (_) async {
            loadCount++;
            return null;
          },
        ),
      );
      await tester.pumpAndSettle();
      // Force a rebuild (e.g. theme change) to make sure the load doesn't
      // re-fire on every didChangeDependencies.
      await tester.pumpWidget(
        buildTestWidget(
          shouldShowAds: true,
          onLoad: (_) async {
            loadCount++;
            return null;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(loadCount, 1);
    });

    testWidgets(
      'does not crash when widget is disposed before load completes',
      (tester) async {
        final completer = Completer<BannerAd?>();
        await tester.pumpWidget(
          buildTestWidget(
            shouldShowAds: true,
            onLoad: (_) => completer.future,
          ),
        );
        await tester.pump();

        // Replace the widget with an empty scaffold — disposes BannerAdWidget.
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              shouldShowAdsProvider.overrideWithValue(true),
              adServiceProvider.overrideWithValue(mockAdService),
            ],
            child: const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
          ),
        );
        await tester.pump();

        // Ad load completes after disposal — must not throw.
        completer.complete(null);
        await tester.pumpAndSettle();
      },
    );
  });
}
