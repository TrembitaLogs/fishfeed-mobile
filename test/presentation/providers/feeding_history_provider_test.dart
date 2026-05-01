import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/domain/entities/feeding_history.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/usecases/calculate_feeding_history_usecase.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/feeding_history_provider.dart';

class MockUseCase extends Mock implements CalculateFeedingHistoryUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const CalculateFeedingHistoryParams(
        userId: 'x',
        range: FeedingHistoryRange.sevenDays,
      ),
    );
  });

  test('feedingHistoryProvider returns FeedingHistory from use case', () async {
    final mock = MockUseCase();
    final fakeHistory = FeedingHistory(
      range: FeedingHistoryRange.sevenDays,
      rangeStart: DateTime(2026, 4, 25),
      rangeEnd: DateTime(2026, 5, 1),
      days: const [],
      totalFedCount: 0,
      currentStreak: 0,
      longestStreak: 0,
      bestDayOfWeek: null,
      aquariumBreakdown: const [],
    );
    when(() => mock.call(any())).thenAnswer((_) async => Right(fakeHistory));

    final container = ProviderContainer(
      overrides: [
        calculateFeedingHistoryUseCaseProvider.overrideWithValue(mock),
        currentUserProvider.overrideWith(
          (ref) => User(
            id: 'user_1',
            email: 'a@b.com',
            displayName: 'A',
            createdAt: DateTime(2025, 1, 1),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(
      feedingHistoryProvider(
        const FeedingHistoryQuery(range: FeedingHistoryRange.sevenDays),
      ).future,
    );

    expect(result, equals(fakeHistory));
  });
}
