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
          streakDays: 7,
          streakLabel: StreakLabel.longest,
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
          streakDays: 0,
          streakLabel: StreakLabel.current,
          bestDayOfWeek: null,
        ),
      ),
    );
    expect(find.text('—'), findsAtLeastNWidgets(1));
  });

  testWidgets(
    'StreakLabel.current renders "Current streak" and StreakLabel.longest renders "Longest streak"',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const FeedingHistoryInsightsRow(
            totalFedCount: 10,
            streakDays: 3,
            streakLabel: StreakLabel.current,
            bestDayOfWeek: null,
          ),
        ),
      );
      expect(find.text('Current streak'), findsOneWidget);
      expect(find.text('Longest streak'), findsNothing);

      await tester.pumpWidget(
        _wrap(
          const FeedingHistoryInsightsRow(
            totalFedCount: 10,
            streakDays: 3,
            streakLabel: StreakLabel.longest,
            bestDayOfWeek: null,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Longest streak'), findsOneWidget);
      expect(find.text('Current streak'), findsNothing);
    },
  );
}
