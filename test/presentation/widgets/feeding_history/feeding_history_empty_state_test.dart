import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/widgets/feeding_history/feeding_history_empty_state.dart';

void main() {
  testWidgets('renders title, subtitle and CTA, fires callback on tap', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FeedingHistoryEmptyState(onCtaTap: () => pressed = true),
        ),
      ),
    );
    expect(find.text('No feedings yet'), findsOneWidget);
    expect(find.text('Log first feeding'), findsOneWidget);

    await tester.tap(find.text('Log first feeding'));
    await tester.pump();
    expect(pressed, isTrue);
  });
}
