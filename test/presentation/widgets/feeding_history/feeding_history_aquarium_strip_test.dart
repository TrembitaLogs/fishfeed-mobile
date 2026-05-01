import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/domain/entities/feeding_history.dart';
import 'package:fishfeed/presentation/widgets/feeding_history/feeding_history_aquarium_strip.dart';

void main() {
  testWidgets('one chip per breakdown entry, taps fire callback', (
    tester,
  ) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedingHistoryAquariumStrip(
            breakdown: const [
              AquariumSparkline(
                aquariumId: 'aq_1',
                aquariumName: 'Office',
                last7DaysCounts: [0, 1, 2, 1, 0, 2, 3],
                totalCountInRange: 12,
              ),
              AquariumSparkline(
                aquariumId: 'aq_2',
                aquariumName: 'Home',
                last7DaysCounts: [3, 3, 3, 3, 3, 3, 3],
                totalCountInRange: 28,
              ),
            ],
            onChipTap: tapped.add,
          ),
        ),
      ),
    );
    expect(find.text('Office'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('28'), findsOneWidget);

    await tester.tap(find.text('Office'));
    expect(tapped, ['aq_1']);
  });

  testWidgets('renders nothing when breakdown is empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedingHistoryAquariumStrip(
            breakdown: const [],
            onChipTap: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(Chip), findsNothing);
  });
}
