import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/data/models/feeding_log_model.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/widgets/feeding_history/feeding_history_timeline.dart';

void main() {
  FeedingLogModel mk({
    required String aqName,
    required String fishName,
    required DateTime t,
    String action = 'fed',
    String? actor,
  }) {
    return FeedingLogModel(
      id: '$aqName-${t.millisecondsSinceEpoch}',
      scheduleId: 's',
      fishId: 'f',
      aquariumId: 'aq',
      scheduledFor: t,
      action: action,
      actedAt: t,
      actedByUserId: 'u',
      actedByUserName: actor,
      deviceId: 'd',
      notes: null,
      createdAt: t,
    );
  }

  testWidgets('groups rows by local-day header', (tester) async {
    final today = DateTime(2026, 5, 1, 9);
    final logs = [
      FeedingHistoryTimelineRow(
        log: mk(aqName: 'O', fishName: 'F1', t: today),
        aquariumName: 'Office',
        fishName: 'F1',
      ),
      FeedingHistoryTimelineRow(
        log: mk(
          aqName: 'O',
          fishName: 'F1',
          t: today.subtract(const Duration(days: 1)),
        ),
        aquariumName: 'Office',
        fishName: 'F1',
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: FeedingHistoryTimeline(rows: logs)),
      ),
    );
    expect(find.byType(ListTile), findsNWidgets(2));
    // Two distinct date headers expected.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey &&
            (w.key as ValueKey).value.toString().startsWith(
              'feeding_history_timeline_date_header_',
            ),
      ),
      findsNWidgets(2),
    );
  });
}
