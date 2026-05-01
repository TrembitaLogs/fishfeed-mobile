import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/domain/entities/feeding_history.dart';
import 'package:fishfeed/presentation/widgets/feeding_history/feeding_history_heatmap.dart';

void main() {
  testWidgets('renders one Container per FeedingHistoryDay', (tester) async {
    // 2026-04-13 is a Monday, so no week-padding placeholders are added and
    // the widget renders exactly 14 FeedingHistoryDayCell widgets.
    final days = List<FeedingHistoryDay>.generate(
      14,
      (i) => FeedingHistoryDay(
        date: DateTime(2026, 4, 13 + i),
        fedCount: i % 4,
        aquariumIds: const [],
      ),
    );
    var tappedDate = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedingHistoryHeatmap(
            days: days,
            onDayTap: (day) => tappedDate = day.date.toIso8601String(),
          ),
        ),
      ),
    );
    expect(find.byType(FeedingHistoryDayCell), findsNWidgets(14));

    await tester.tap(find.byType(FeedingHistoryDayCell).first);
    await tester.pump();
    expect(tappedDate, days.first.date.toIso8601String());
  });
}
