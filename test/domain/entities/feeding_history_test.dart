import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/domain/entities/feeding_history.dart';

void main() {
  group('FeedingHistoryRange', () {
    test('exposes three values: 7d / 30d / 6m', () {
      expect(FeedingHistoryRange.values, hasLength(3));
      expect(
        FeedingHistoryRange.values,
        contains(FeedingHistoryRange.sevenDays),
      );
      expect(
        FeedingHistoryRange.values,
        contains(FeedingHistoryRange.thirtyDays),
      );
      expect(
        FeedingHistoryRange.values,
        contains(FeedingHistoryRange.sixMonths),
      );
    });

    test('durationInDays returns the correct count for each value', () {
      expect(FeedingHistoryRange.sevenDays.durationInDays, 7);
      expect(FeedingHistoryRange.thirtyDays.durationInDays, 30);
      expect(FeedingHistoryRange.sixMonths.durationInDays, 180);
    });
  });

  group('FeedingHistoryDay', () {
    test('equality holds for same date and counts', () {
      final a = FeedingHistoryDay(
        date: DateTime(2026, 4, 1),
        fedCount: 3,
        aquariumIds: const ['aq_1', 'aq_2'],
      );
      final b = FeedingHistoryDay(
        date: DateTime(2026, 4, 1),
        fedCount: 3,
        aquariumIds: const ['aq_1', 'aq_2'],
      );
      expect(a, equals(b));
    });

    test('zero feedings produces fedCount=0 with empty aquariumIds', () {
      final d = FeedingHistoryDay(
        date: DateTime(2026, 4, 1),
        fedCount: 0,
        aquariumIds: const [],
      );
      expect(d.fedCount, 0);
      expect(d.aquariumIds, isEmpty);
    });
  });
}
