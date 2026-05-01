import 'package:equatable/equatable.dart';

/// Time window selectable in the Feeding History feature.
enum FeedingHistoryRange { sevenDays, thirtyDays, sixMonths }

extension FeedingHistoryRangeX on FeedingHistoryRange {
  /// Number of days the range spans, inclusive of today.
  int get durationInDays {
    switch (this) {
      case FeedingHistoryRange.sevenDays:
        return 7;
      case FeedingHistoryRange.thirtyDays:
        return 30;
      case FeedingHistoryRange.sixMonths:
        return 180;
    }
  }
}

/// One bucket in the feeding-history heatmap, representing a single local-time
/// calendar day across all accessible aquariums.
class FeedingHistoryDay extends Equatable {
  const FeedingHistoryDay({
    required this.date,
    required this.fedCount,
    required this.aquariumIds,
  });

  /// Local-time start of day for this bucket (no UTC).
  final DateTime date;

  /// Number of `action == 'fed'` logs that fell on [date].
  final int fedCount;

  /// Distinct aquarium IDs that had at least one fed log on [date].
  final List<String> aquariumIds;

  @override
  List<Object?> get props => [date, fedCount, aquariumIds];
}
