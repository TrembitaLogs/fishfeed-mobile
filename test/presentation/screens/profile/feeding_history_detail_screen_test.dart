import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/di/datasource_providers.dart';
import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/feeding_log_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/domain/entities/feeding_history.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/usecases/calculate_feeding_history_usecase.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/feeding_history_provider.dart';
import 'package:fishfeed/presentation/screens/profile/feeding_history_detail_screen.dart';

class MockUseCase extends Mock implements CalculateFeedingHistoryUseCase {}

class MockLogs extends Mock implements FeedingLogLocalDataSource {}

class MockAqs extends Mock implements AquariumLocalDataSource {}

class MockFish extends Mock implements FishLocalDataSource {}

Widget _buildSubject({
  required CalculateFeedingHistoryUseCase useCase,
  required FeedingLogLocalDataSource logs,
  required AquariumLocalDataSource aqs,
  required FishLocalDataSource fish,
}) {
  return ProviderScope(
    overrides: [
      calculateFeedingHistoryUseCaseProvider.overrideWithValue(useCase),
      feedingLogLocalDataSourceProvider.overrideWithValue(logs),
      aquariumLocalDataSourceProvider.overrideWithValue(aqs),
      fishLocalDataSourceProvider.overrideWithValue(fish),
      currentUserProvider.overrideWith(
        (ref) => User(
          id: 'user_1',
          email: 'a@b',
          displayName: 'A',
          createdAt: DateTime(2025, 1, 1),
        ),
      ),
    ],
    // ignore: prefer_const_constructors
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const FeedingHistoryDetailScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const CalculateFeedingHistoryParams(
        userId: 'x',
        range: FeedingHistoryRange.sixMonths,
      ),
    );
    registerFallbackValue(DateTime(2026));
  });

  testWidgets('tapping the 7d chip changes the range used by the use case', (
    tester,
  ) async {
    final mock = MockUseCase();
    final logs = MockLogs();
    final aqs = MockAqs();
    final fish = MockFish();

    final calls = <FeedingHistoryRange>[];
    when(() => mock.call(any())).thenAnswer((inv) async {
      final p = inv.positionalArguments.first as CalculateFeedingHistoryParams;
      calls.add(p.range);
      return Right(
        FeedingHistory(
          range: p.range,
          rangeStart: DateTime(2026, 4, 25),
          rangeEnd: DateTime(2026, 5, 1),
          days: const [],
          totalFedCount: 0,
          currentStreak: 0,
          longestStreak: 0,
          bestDayOfWeek: null,
          aquariumBreakdown: const [],
        ),
      );
    });
    when(() => logs.getByDateRange(any(), any())).thenReturn(const []);
    when(() => aqs.getAllAquariums()).thenReturn(const []);
    when(() => fish.getAllFish()).thenReturn(const []);

    await tester.pumpWidget(
      _buildSubject(useCase: mock, logs: logs, aqs: aqs, fish: fish),
    );
    await tester.pumpAndSettle();
    expect(calls.first, FeedingHistoryRange.sixMonths);

    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();
    expect(calls.last, FeedingHistoryRange.sevenDays);
  });
}
