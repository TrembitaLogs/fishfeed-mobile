import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/di/datasource_providers.dart';
import 'package:fishfeed/domain/entities/feeding_history.dart';
import 'package:fishfeed/domain/usecases/calculate_feeding_history_usecase.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';

/// Stable, hashable parameter for [feedingHistoryProvider].
class FeedingHistoryQuery extends Equatable {
  const FeedingHistoryQuery({
    required this.range,
    this.aquariumId,
    this.onlyMyActions = false,
  });

  final FeedingHistoryRange range;
  final String? aquariumId;
  final bool onlyMyActions;

  @override
  List<Object?> get props => [range, aquariumId, onlyMyActions];
}

/// Provides a singleton [CalculateFeedingHistoryUseCase] wired with local
/// data sources from the existing DI container.
final calculateFeedingHistoryUseCaseProvider =
    Provider<CalculateFeedingHistoryUseCase>((ref) {
      return CalculateFeedingHistoryUseCase(
        feedingLogDataSource: ref.watch(feedingLogLocalDataSourceProvider),
        aquariumDataSource: ref.watch(aquariumLocalDataSourceProvider),
        streakDataSource: ref.watch(streakLocalDataSourceProvider),
      );
    });

/// Provider family that returns a [FeedingHistory] for the active user and
/// query. Throws on Failure so callers see it via `AsyncValue.error`.
final feedingHistoryProvider =
    FutureProvider.family<FeedingHistory, FeedingHistoryQuery>((
      ref,
      query,
    ) async {
      final useCase = ref.watch(calculateFeedingHistoryUseCaseProvider);
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        throw StateError('feedingHistoryProvider read with no current user');
      }
      final result = await useCase(
        CalculateFeedingHistoryParams(
          userId: user.id,
          range: query.range,
          aquariumId: query.aquariumId,
          onlyMyActions: query.onlyMyActions,
        ),
      );
      return result.fold((f) => throw f, (h) => h);
    });
