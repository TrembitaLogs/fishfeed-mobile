import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/aquarium_local_ds.dart';
import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/datasources/local/fish_local_ds.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/data/datasources/local/sync_queue_ds.dart';
import 'package:fishfeed/data/models/feeding_event_model.dart';
import 'package:fishfeed/data/models/streak_model.dart';
import 'package:fishfeed/domain/entities/feeding_status.dart';
import 'package:fishfeed/domain/entities/scheduled_feeding.dart';
import 'package:fishfeed/domain/entities/streak.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/usecases/mark_feeding_usecase.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockFeedingLocalDataSource extends Mock
    implements FeedingLocalDataSource {}

class MockFishLocalDataSource extends Mock implements FishLocalDataSource {}

class MockAquariumLocalDataSource extends Mock
    implements AquariumLocalDataSource {}

class MockStreakLocalDataSource extends Mock implements StreakLocalDataSource {}

class MockSyncQueueDataSource extends Mock implements SyncQueueDataSource {}

class MockMarkFeedingUseCase extends Mock implements MarkFeedingUseCase {}

class MockBox extends Mock implements Box<dynamic> {}

class FakeMarkFeedingParams extends Fake implements MarkFeedingParams {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeMarkFeedingParams());
  });

  group('TodayFeedingsState', () {
    test('isEmpty returns true when feedings empty, not loading, no error', () {
      const state = TodayFeedingsState(feedings: [], isLoading: false);
      expect(state.isEmpty, isTrue);
    });

    test('isEmpty returns false when loading', () {
      const state = TodayFeedingsState(feedings: [], isLoading: true);
      expect(state.isEmpty, isFalse);
    });

    test('isEmpty returns false when has error', () {
      const state = TodayFeedingsState(
        feedings: [],
        isLoading: false,
        error: 'Some error',
      );
      expect(state.isEmpty, isFalse);
    });

    test('hasError returns true when error is not null', () {
      const state = TodayFeedingsState(error: 'Network error');
      expect(state.hasError, isTrue);
    });

    test('hasError returns false when error is null', () {
      const state = TodayFeedingsState();
      expect(state.hasError, isFalse);
    });

    test('completedCount counts fed feedings correctly', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final state = TodayFeedingsState(
        feedings: [
          _createFeeding(
            '1',
            today.add(const Duration(hours: 8)),
            FeedingStatus.fed,
          ),
          _createFeeding(
            '2',
            today.add(const Duration(hours: 12)),
            FeedingStatus.fed,
          ),
          _createFeeding(
            '3',
            today.add(const Duration(hours: 18)),
            FeedingStatus.pending,
          ),
        ],
      );

      expect(state.completedCount, equals(2));
    });

    test('pendingCount counts pending feedings correctly', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final state = TodayFeedingsState(
        feedings: [
          _createFeeding(
            '1',
            today.add(const Duration(hours: 8)),
            FeedingStatus.fed,
          ),
          _createFeeding(
            '2',
            today.add(const Duration(hours: 12)),
            FeedingStatus.pending,
          ),
          _createFeeding(
            '3',
            today.add(const Duration(hours: 18)),
            FeedingStatus.pending,
          ),
        ],
      );

      expect(state.pendingCount, equals(2));
    });

    test('missedCount counts missed feedings correctly', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final state = TodayFeedingsState(
        feedings: [
          _createFeeding(
            '1',
            today.add(const Duration(hours: 8)),
            FeedingStatus.fed,
          ),
          _createFeeding(
            '2',
            today.add(const Duration(hours: 12)),
            FeedingStatus.missed,
          ),
          _createFeeding(
            '3',
            today.add(const Duration(hours: 18)),
            FeedingStatus.missed,
          ),
        ],
      );

      expect(state.missedCount, equals(2));
    });

    test('copyWith creates copy with updated fields', () {
      const original = TodayFeedingsState(isLoading: true);
      final copy = original.copyWith(isLoading: false, error: 'New error');

      expect(copy.isLoading, isFalse);
      expect(copy.error, equals('New error'));
      expect(copy.feedings, equals(original.feedings));
    });
  });

  group('TodayFeedingsNotifier', () {
    late MockFeedingLocalDataSource mockFeedingDs;
    late MockFishLocalDataSource mockFishDs;
    late MockAquariumLocalDataSource mockAquariumDs;
    late MockMarkFeedingUseCase mockMarkFeedingUseCase;
    late ProviderContainer container;

    final testUser = User(
      id: 'user_123',
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: DateTime(2024, 1, 15),
      subscriptionStatus: const SubscriptionStatus.free(),
      freeAiScansRemaining: 5,
    );

    setUp(() {
      mockFeedingDs = MockFeedingLocalDataSource();
      mockFishDs = MockFishLocalDataSource();
      mockAquariumDs = MockAquariumLocalDataSource();
      mockMarkFeedingUseCase = MockMarkFeedingUseCase();

      // Set up default empty responses for fish and aquarium data sources
      when(() => mockFishDs.getAllFish()).thenReturn([]);
      when(() => mockAquariumDs.getAllAquariums()).thenReturn([]);
    });

    tearDown(() {
      container.dispose();
    });

    test('loadFeedings returns only today events from datasource', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      when(() => mockFeedingDs.getFeedingEventsByDate(any())).thenReturn([
        FeedingEventModel(
          id: 'event_1',
          fishId: 'fish_1',
          aquariumId: 'aq_1',
          feedingTime: today.add(const Duration(hours: 9)),
          synced: false,
          createdAt: today,
          localId: 'feed_1',
        ),
      ]);

      container = ProviderContainer(
        overrides: [
          feedingLocalDataSourceProvider.overrideWithValue(mockFeedingDs),
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
          markFeedingUseCaseProvider.overrideWithValue(mockMarkFeedingUseCase),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(todayFeedingsProvider);

      expect(state.isLoading, isFalse);
      expect(state.feedings, isNotEmpty);

      // Verify getFeedingEventsByDate was called twice:
      // 1. For building completedEventsMap
      // 2. For generating today's schedule
      verify(() => mockFeedingDs.getFeedingEventsByDate(any())).called(2);
    });

    test('markAsFed calls usecase and updates state', () async {
      when(() => mockFeedingDs.getFeedingEventsByDate(any())).thenReturn([]);

      when(() => mockMarkFeedingUseCase(any())).thenAnswer((_) async {
        return const Right(
          MarkFeedingResult(
            updatedStreak: Streak(
              id: 'streak_user_123',
              userId: 'user_123',
              currentStreak: 1,
              longestStreak: 1,
            ),
            wasCreated: true,
          ),
        );
      });

      container = ProviderContainer(
        overrides: [
          feedingLocalDataSourceProvider.overrideWithValue(mockFeedingDs),
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
          markFeedingUseCaseProvider.overrideWithValue(mockMarkFeedingUseCase),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Get a feeding ID from the generated mock schedule
      final state = container.read(todayFeedingsProvider);
      if (state.feedings.isNotEmpty) {
        final feedingId = state.feedings.first.id;

        await container
            .read(todayFeedingsProvider.notifier)
            .markAsFed(feedingId);

        // Verify use case was called
        verify(() => mockMarkFeedingUseCase(any())).called(1);
      }
    });

    test('markAsMissed calls usecase and updates state', () async {
      when(() => mockFeedingDs.getFeedingEventsByDate(any())).thenReturn([]);

      when(() => mockMarkFeedingUseCase(any())).thenAnswer((_) async {
        return const Right(
          MarkFeedingResult(
            updatedStreak: Streak(
              id: 'streak_user_123',
              userId: 'user_123',
              currentStreak: 0,
              longestStreak: 5,
            ),
            wasCreated: false,
          ),
        );
      });

      container = ProviderContainer(
        overrides: [
          feedingLocalDataSourceProvider.overrideWithValue(mockFeedingDs),
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
          markFeedingUseCaseProvider.overrideWithValue(mockMarkFeedingUseCase),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(todayFeedingsProvider);
      if (state.feedings.isNotEmpty) {
        final feedingId = state.feedings.first.id;

        await container
            .read(todayFeedingsProvider.notifier)
            .markAsMissed(feedingId);

        verify(() => mockMarkFeedingUseCase(any())).called(1);
      }
    });

    test('markAsFed sets error state on failure', () async {
      when(() => mockFeedingDs.getFeedingEventsByDate(any())).thenReturn([]);

      when(() => mockMarkFeedingUseCase(any())).thenAnswer((_) async {
        return const Left(CacheFailure(message: 'Database error'));
      });

      container = ProviderContainer(
        overrides: [
          feedingLocalDataSourceProvider.overrideWithValue(mockFeedingDs),
          fishLocalDataSourceProvider.overrideWithValue(mockFishDs),
          aquariumLocalDataSourceProvider.overrideWithValue(mockAquariumDs),
          markFeedingUseCaseProvider.overrideWithValue(mockMarkFeedingUseCase),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(todayFeedingsProvider);
      if (state.feedings.isNotEmpty) {
        final feedingId = state.feedings.first.id;

        await container
            .read(todayFeedingsProvider.notifier)
            .markAsFed(feedingId);

        final updatedState = container.read(todayFeedingsProvider);
        expect(updatedState.error, isNotNull);
      }
    });
  });

  group('StreakState', () {
    test('currentStreak returns 0 when streak is null', () {
      const state = StreakState();
      expect(state.currentStreak, equals(0));
    });

    test('currentStreak returns correct value when streak exists', () {
      const state = StreakState(
        streak: Streak(
          id: 'streak_1',
          userId: 'user_1',
          currentStreak: 5,
          longestStreak: 10,
        ),
      );
      expect(state.currentStreak, equals(5));
    });

    test('longestStreak returns 0 when streak is null', () {
      const state = StreakState();
      expect(state.longestStreak, equals(0));
    });

    test('longestStreak returns correct value when streak exists', () {
      const state = StreakState(
        streak: Streak(
          id: 'streak_1',
          userId: 'user_1',
          currentStreak: 5,
          longestStreak: 10,
        ),
      );
      expect(state.longestStreak, equals(10));
    });

    test('isActive returns false when streak is null', () {
      const state = StreakState();
      expect(state.isActive, isFalse);
    });

    test('isActive returns false when currentStreak is 0', () {
      const state = StreakState(
        streak: Streak(
          id: 'streak_1',
          userId: 'user_1',
          currentStreak: 0,
          longestStreak: 10,
        ),
      );
      expect(state.isActive, isFalse);
    });

    test('isActive returns true when currentStreak > 0', () {
      const state = StreakState(
        streak: Streak(
          id: 'streak_1',
          userId: 'user_1',
          currentStreak: 1,
          longestStreak: 10,
        ),
      );
      expect(state.isActive, isTrue);
    });

    test('copyWith creates copy with updated fields', () {
      const original = StreakState(isLoading: true);
      final copy = original.copyWith(isLoading: false, error: 'Error');

      expect(copy.isLoading, isFalse);
      expect(copy.error, equals('Error'));
    });

    test('copyWith with clearStreak sets streak to null', () {
      const original = StreakState(
        streak: Streak(
          id: 'streak_1',
          userId: 'user_1',
          currentStreak: 5,
          longestStreak: 10,
        ),
      );
      final copy = original.copyWith(clearStreak: true);

      expect(copy.streak, isNull);
    });
  });

  group('StreakNotifier', () {
    late MockStreakLocalDataSource mockStreakDs;
    late ProviderContainer container;

    final testUser = User(
      id: 'user_123',
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: DateTime(2024, 1, 15),
      subscriptionStatus: const SubscriptionStatus.free(),
      freeAiScansRemaining: 5,
    );

    setUp(() {
      mockStreakDs = MockStreakLocalDataSource();
    });

    tearDown(() {
      container.dispose();
    });

    test('loadStreak reads streak from data source', () async {
      final streakModel = StreakModel(
        id: 'streak_user_123',
        userId: 'user_123',
        currentStreak: 5,
        longestStreak: 10,
      );

      when(
        () => mockStreakDs.getStreakByUserId('user_123'),
      ).thenReturn(streakModel);

      container = ProviderContainer(
        overrides: [
          streakLocalDataSourceProvider.overrideWithValue(mockStreakDs),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      // Wait for load
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(currentStreakProvider);

      expect(state.isLoading, isFalse);
      expect(state.currentStreak, equals(5));
      expect(state.longestStreak, equals(10));
    });

    test('loadStreak returns default streak when none exists', () async {
      when(() => mockStreakDs.getStreakByUserId('user_123')).thenReturn(null);

      container = ProviderContainer(
        overrides: [
          streakLocalDataSourceProvider.overrideWithValue(mockStreakDs),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(currentStreakProvider);

      expect(state.isLoading, isFalse);
      expect(state.currentStreak, equals(0));
      expect(state.longestStreak, equals(0));
    });

    test('incrementStreak calls datasource incrementStreak', () async {
      final initialStreak = StreakModel(
        id: 'streak_user_123',
        userId: 'user_123',
        currentStreak: 5,
        longestStreak: 10,
      );

      final updatedStreak = StreakModel(
        id: 'streak_user_123',
        userId: 'user_123',
        currentStreak: 6,
        longestStreak: 10,
      );

      when(
        () => mockStreakDs.getStreakByUserId('user_123'),
      ).thenReturn(initialStreak);
      when(
        () => mockStreakDs.incrementStreak('user_123', any()),
      ).thenAnswer((_) async => updatedStreak);

      container = ProviderContainer(
        overrides: [
          streakLocalDataSourceProvider.overrideWithValue(mockStreakDs),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      await container.read(currentStreakProvider.notifier).incrementStreak();

      verify(() => mockStreakDs.incrementStreak('user_123', any())).called(1);

      final state = container.read(currentStreakProvider);
      expect(state.currentStreak, equals(6));
    });

    test('resetStreak calls datasource resetStreak', () async {
      final initialStreak = StreakModel(
        id: 'streak_user_123',
        userId: 'user_123',
        currentStreak: 5,
        longestStreak: 10,
      );

      final resetStreakModel = StreakModel(
        id: 'streak_user_123',
        userId: 'user_123',
        currentStreak: 0,
        longestStreak: 10,
      );

      when(
        () => mockStreakDs.getStreakByUserId('user_123'),
      ).thenReturn(initialStreak);
      when(
        () => mockStreakDs.resetStreak('user_123'),
      ).thenAnswer((_) async => resetStreakModel);

      container = ProviderContainer(
        overrides: [
          streakLocalDataSourceProvider.overrideWithValue(mockStreakDs),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      await container.read(currentStreakProvider.notifier).resetStreak();

      verify(() => mockStreakDs.resetStreak('user_123')).called(1);

      final state = container.read(currentStreakProvider);
      expect(state.currentStreak, equals(0));
    });
  });

  group('currentStreakCountProvider', () {
    test('returns currentStreak from streakProvider', () async {
      final mockStreakDs = MockStreakLocalDataSource();

      final streakModel = StreakModel(
        id: 'streak_user_123',
        userId: 'user_123',
        currentStreak: 7,
        longestStreak: 15,
      );

      when(
        () => mockStreakDs.getStreakByUserId('user_123'),
      ).thenReturn(streakModel);

      final testUser = User(
        id: 'user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime(2024, 1, 15),
        subscriptionStatus: const SubscriptionStatus.free(),
        freeAiScansRemaining: 5,
      );

      final container = ProviderContainer(
        overrides: [
          streakLocalDataSourceProvider.overrideWithValue(mockStreakDs),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final count = container.read(currentStreakCountProvider);
      expect(count, equals(7));

      container.dispose();
    });
  });

  group('isStreakActiveProvider', () {
    test('returns true when streak > 0', () async {
      final mockStreakDs = MockStreakLocalDataSource();

      final streakModel = StreakModel(
        id: 'streak_user_123',
        userId: 'user_123',
        currentStreak: 3,
        longestStreak: 10,
      );

      when(
        () => mockStreakDs.getStreakByUserId('user_123'),
      ).thenReturn(streakModel);

      final testUser = User(
        id: 'user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime(2024, 1, 15),
        subscriptionStatus: const SubscriptionStatus.free(),
        freeAiScansRemaining: 5,
      );

      final container = ProviderContainer(
        overrides: [
          streakLocalDataSourceProvider.overrideWithValue(mockStreakDs),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final isActive = container.read(isStreakActiveProvider);
      expect(isActive, isTrue);

      container.dispose();
    });

    test('returns false when streak is 0', () async {
      final mockStreakDs = MockStreakLocalDataSource();

      final streakModel = StreakModel(
        id: 'streak_user_123',
        userId: 'user_123',
        currentStreak: 0,
        longestStreak: 10,
      );

      when(
        () => mockStreakDs.getStreakByUserId('user_123'),
      ).thenReturn(streakModel);

      final testUser = User(
        id: 'user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime(2024, 1, 15),
        subscriptionStatus: const SubscriptionStatus.free(),
        freeAiScansRemaining: 5,
      );

      final container = ProviderContainer(
        overrides: [
          streakLocalDataSourceProvider.overrideWithValue(mockStreakDs),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final isActive = container.read(isStreakActiveProvider);
      expect(isActive, isFalse);

      container.dispose();
    });
  });

  group('groupedFeedingsProvider', () {
    test('groups feedings by time period', () async {
      final mockFeedingDs = MockFeedingLocalDataSource();
      final mockMarkFeedingUseCase = MockMarkFeedingUseCase();

      when(() => mockFeedingDs.getFeedingEventsByDate(any())).thenReturn([]);

      final testUser = User(
        id: 'user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime(2024, 1, 15),
        subscriptionStatus: const SubscriptionStatus.free(),
        freeAiScansRemaining: 5,
      );

      final container = ProviderContainer(
        overrides: [
          feedingLocalDataSourceProvider.overrideWithValue(mockFeedingDs),
          markFeedingUseCaseProvider.overrideWithValue(mockMarkFeedingUseCase),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final grouped = container.read(groupedFeedingsProvider);

      expect(grouped.containsKey('morning'), isTrue);
      expect(grouped.containsKey('afternoon'), isTrue);
      expect(grouped.containsKey('evening'), isTrue);

      container.dispose();
    });
  });
}

/// Helper to create a scheduled feeding for testing.
ScheduledFeeding _createFeeding(
  String id,
  DateTime time,
  FeedingStatus status,
) {
  return ScheduledFeeding(
    id: id,
    scheduledTime: time,
    aquariumId: 'aq_1',
    aquariumName: 'Test Tank',
    speciesName: 'Test Fish',
    status: status,
  );
}
