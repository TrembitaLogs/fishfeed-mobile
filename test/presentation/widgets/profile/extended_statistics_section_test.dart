import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/utils/premium_gate.dart';
import 'package:fishfeed/domain/entities/feeding_history.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/usecases/calculate_feeding_history_usecase.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/feeding_history_provider.dart';
import 'package:fishfeed/presentation/widgets/feeding_history/feeding_history_heatmap.dart';
import 'package:fishfeed/presentation/widgets/profile/extended_statistics_section.dart';

class MockUseCase extends Mock implements CalculateFeedingHistoryUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const CalculateFeedingHistoryParams(
        userId: 'x',
        range: FeedingHistoryRange.sixMonths,
      ),
    );
  });

  testWidgets('premium user sees heatmap and insights, no locked preview', (
    tester,
  ) async {
    final mock = MockUseCase();
    when(() => mock.call(any())).thenAnswer(
      (_) async => Right(
        FeedingHistory(
          range: FeedingHistoryRange.sixMonths,
          rangeStart: DateTime(2025, 11, 1),
          rangeEnd: DateTime(2026, 5, 1),
          days: List.generate(
            7,
            (i) => FeedingHistoryDay(
              date: DateTime(2026, 4, 25 + i),
              fedCount: i,
              aquariumIds: const [],
            ),
          ),
          totalFedCount: 21,
          currentStreak: 5,
          longestStreak: 12,
          bestDayOfWeek: DateTime.tuesday,
          aquariumBreakdown: const [],
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calculateFeedingHistoryUseCaseProvider.overrideWithValue(mock),
          currentUserProvider.overrideWith(
            (ref) => User(
              id: 'user_1',
              email: 'a@b',
              displayName: 'A',
              createdAt: DateTime(2025, 1, 1),
            ),
          ),
          featureAccessProvider(
            PremiumFeature.extendedStatistics,
          ).overrideWith((ref) => true),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ExtendedStatisticsSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FeedingHistoryHeatmap), findsOneWidget);
    expect(find.text('21'), findsOneWidget);
    expect(find.text('Tuesday'), findsOneWidget);
  });

  testWidgets('free user sees locked preview, not the heatmap', (tester) async {
    final mock = MockUseCase();
    when(() => mock.call(any())).thenAnswer(
      (_) async => Right(
        FeedingHistory(
          range: FeedingHistoryRange.thirtyDays,
          rangeStart: DateTime(2026, 4, 1),
          rangeEnd: DateTime(2026, 5, 1),
          days: const [],
          totalFedCount: 0,
          currentStreak: 0,
          longestStreak: 0,
          bestDayOfWeek: null,
          aquariumBreakdown: const [],
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calculateFeedingHistoryUseCaseProvider.overrideWithValue(mock),
          currentUserProvider.overrideWith(
            (ref) => User(
              id: 'user_1',
              email: 'a@b',
              displayName: 'A',
              createdAt: DateTime(2025, 1, 1),
            ),
          ),
          featureAccessProvider(
            PremiumFeature.extendedStatistics,
          ).overrideWith((ref) => false),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ExtendedStatisticsSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FeedingHistoryHeatmap), findsNothing);
    expect(find.text('View 6 Months of History'), findsOneWidget);
  });
}
