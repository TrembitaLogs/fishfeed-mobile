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

  testWidgets('left-pads the first column when range starts mid-week', (
    tester,
  ) async {
    // 2026-04-17 is a Friday (weekday=5), so 4 placeholder cells precede.
    final days = List<FeedingHistoryDay>.generate(
      7,
      (i) => FeedingHistoryDay(
        date: DateTime(2026, 4, 17 + i),
        fedCount: 0,
        aquariumIds: const [],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedingHistoryHeatmap(days: days, onDayTap: (_) {}),
        ),
      ),
    );
    // 7 real days + 4 placeholder days = 11 cells total.
    expect(find.byType(FeedingHistoryDayCell), findsNWidgets(11));
  });

  testWidgets('cell colour intensity scales monotonically with fedCount', (
    tester,
  ) async {
    // 7 days, ascending count.
    final days = List<FeedingHistoryDay>.generate(
      7,
      (i) => FeedingHistoryDay(
        date: DateTime(2026, 4, 13 + i), // 2026-04-13 is a Monday
        fedCount: i,
        aquariumIds: const [],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: FeedingHistoryHeatmap(days: days, onDayTap: (_) {}),
        ),
      ),
    );
    final cells = tester
        .widgetList<FeedingHistoryDayCell>(find.byType(FeedingHistoryDayCell))
        .toList();
    expect(cells, hasLength(7));
    for (var i = 1; i < cells.length; i++) {
      expect(
        cells[i].intensity,
        greaterThanOrEqualTo(cells[i - 1].intensity),
        reason:
            'cell $i (count=${days[i].fedCount}) should be at least as '
            'intense as cell ${i - 1} (count=${days[i - 1].fedCount})',
      );
    }
  });
}
