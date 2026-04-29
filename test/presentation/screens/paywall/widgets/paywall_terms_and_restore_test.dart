import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/screens/paywall/widgets/paywall_sections.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget(TargetPlatform platform) {
    // Override Theme.of(context).platform per test — PaywallTermsAndRestore
    // reads it to pick the cancellation hint copy. Safer than mutating
    // debugDefaultTargetPlatform globally.
    return MaterialApp(
      theme: AppTheme.lightTheme.copyWith(platform: platform),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PaywallTermsAndRestore(
          isRestoring: false,
          onRestore: () {},
          onOpenUrl: (_) {},
        ),
      ),
    );
  }

  group('PaywallTermsAndRestore platform-aware trial terms', () {
    testWidgets('shows Google Play wording on Android', (tester) async {
      await tester.pumpWidget(buildTestWidget(TargetPlatform.android));
      await tester.pumpAndSettle();

      expect(find.textContaining('Google Play settings'), findsOneWidget);
      expect(find.textContaining('App Store settings'), findsNothing);
    });

    testWidgets('shows App Store wording on iOS', (tester) async {
      await tester.pumpWidget(buildTestWidget(TargetPlatform.iOS));
      await tester.pumpAndSettle();

      expect(find.textContaining('App Store settings'), findsOneWidget);
      expect(find.textContaining('Google Play settings'), findsNothing);
    });

    testWidgets('falls back to App Store wording on macOS (Apple ecosystem)', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(TargetPlatform.macOS));
      await tester.pumpAndSettle();

      // Anything that is not explicitly Android falls back to the iOS
      // disclaimer — Apple stores cover macOS too.
      expect(find.textContaining('App Store settings'), findsOneWidget);
    });
  });
}
