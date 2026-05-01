import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/widgets/feeding_history/feeding_history_insights_row.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('renders three labelled insight cards', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const FeedingHistoryInsightsRow(
          totalFedCount: 42,
          longestStreak: 7,
          bestDayOfWeek: DateTime.tuesday,
        ),
      ),
    );
    expect(find.text('42'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Tuesday'), findsOneWidget);
  });

  testWidgets('renders dash for null bestDayOfWeek', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const FeedingHistoryInsightsRow(
          totalFedCount: 0,
          longestStreak: 0,
          bestDayOfWeek: null,
        ),
      ),
    );
    expect(find.text('—'), findsAtLeastNWidgets(1));
  });
}
