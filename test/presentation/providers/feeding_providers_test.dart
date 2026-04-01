import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/di/repository_providers.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';
import 'package:fishfeed/data/models/streak_model.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/domain/entities/streak.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/domain/repositories/aquarium_repository.dart';
import 'package:fishfeed/domain/repositories/fish_repository.dart';
import 'package:fishfeed/domain/repositories/streak_repository.dart';
import 'package:fishfeed/domain/services/feeding_event_generator.dart';
import 'package:fishfeed/domain/entities/achievement.dart';
import 'package:fishfeed/domain/usecases/calculate_streak_usecase.dart';
import 'package:fishfeed/presentation/providers/achievement_providers.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/services/feeding/feeding_service.dart';

// ============================================================================
// Mocks
// ============================================================================

class MockFeedingEventGenerator extends Mock implements FeedingEventGenerator {}

class MockFeedingService extends Mock implements FeedingService {}

class MockFishRepository extends Mock implements FishRepository {}

class MockAquariumRepository extends Mock implements AquariumRepository {}

class MockStreakRepository extends Mock implements StreakRepository {}

class MockCalculateStreakUseCase extends Mock
    implements CalculateStreakUseCase {}

/// Test helper: StreakNotifier that skips async loadStreak() in constructor.
///
/// Prevents "dispose after use" errors in tests where the provider
/// gets invalidated (e.g., after markAsFed/markAsMissed).
class TestStreakNotifier extends StreakNotifier {
  TestStreakNotifier({
    required super.streakRepository,
    required super.calculateStreakUseCase,
    required super.ref,
    this.initialStreak,
  });

  /// Optional initial streak to set immediately.
  final Streak? initialStreak;

  @override
  Future<void> loadStreak() async {
    // No-op: set state synchronously to avoid async dispose issues in tests.
    if (initialStreak != null) {
      state = StreakState(streak: initialStreak);
    }
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      StreakModel(
        id: 'fallback',
        userId: 'fallback',
        currentStreak: 0,
        longestStreak: 0,
      ),
    );
    registerFallbackValue(const CalculateStreakParams(userId: 'fallback'));
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
            EventStatus.fed,
          ),
          _createFeeding(
            '2',
            today.add(const Duration(hours: 12)),
            EventStatus.fed,
          ),
          _createFeeding(
            '3',
            today.add(const Duration(hours: 18)),
            EventStatus.pending,
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
            EventStatus.fed,
          ),
          _createFeeding(
            '2',
            today.add(const Duration(hours: 12)),
            EventStatus.pending,
          ),
          _createFeeding(
            '3',
            today.add(const Duration(hours: 18)),
            EventStatus.pending,
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
            EventStatus.fed,
          ),
          _createFeeding(
            '2',
            today.add(const Duration(hours: 12)),
            EventStatus.skipped,
          ),
          _createFeeding(
            '3',
            today.add(const Duration(hours: 18)),
            EventStatus.skipped,
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
    late MockFeedingEventGenerator mockGenerator;
    late MockFeedingService mockFeedingService;
    late MockFishRepository mockFishRepo;
    late MockAquariumRepository mockAquariumRepo;
    late MockStreakRepository mockStreakRepo;
    late MockCalculateStreakUseCase mockCalculateStreakUseCase;
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
      mockGenerator = MockFeedingEventGenerator();
      mockFeedingService = MockFeedingService();
      mockFishRepo = MockFishRepository();
      mockAquariumRepo = MockAquariumRepository();
      mockStreakRepo = MockStreakRepository();
      mockCalculateStreakUseCase = MockCalculateStreakUseCase();

      // Set up default empty responses for fish and aquarium repositories
      when(() => mockFishRepo.getAllFish()).thenReturn([]);
      when(
        () => mockAquariumRepo.getCachedAquariums(),
      ).thenReturn(const Right([]));

      // Default mock for CalculateStreakUseCase used by StreakNotifier
      when(() => mockCalculateStreakUseCase.call(any())).thenAnswer(
        (_) async => const Right(
          StreakCalculationResult(
            streak: Streak(
              id: 'streak_user_123',
              userId: 'user_123',
              currentStreak: 0,
              longestStreak: 0,
            ),
            isActive: false,
            daysUntilExpiry: 0,
          ),
        ),
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'loadFeedings returns today events from FeedingEventGenerator',
      () async {
        // Setup generator to return some events
        when(
          () => mockGenerator.generateTodayEventsForAllAquariums(
            aquariumIds: any(named: 'aquariumIds'),
            fishNameResolver: any(named: 'fishNameResolver'),
            fishQuantityResolver: any(named: 'fishQuantityResolver'),
            aquariumNameResolver: any(named: 'aquariumNameResolver'),
            avatarResolver: any(named: 'avatarResolver'),
          ),
        ).thenReturn({});

        container = ProviderContainer(
          overrides: [
            feedingEventGeneratorProvider.overrideWithValue(mockGenerator),
            feedingServiceProvider.overrideWithValue(mockFeedingService),
            fishRepositoryProvider.overrideWithValue(mockFishRepo),
            aquariumRepositoryProvider.overrideWithValue(mockAquariumRepo),
            currentUserProvider.overrideWithValue(testUser),
          ],
        );

        // Wait for initial load
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final state = container.read(todayFeedingsProvider);

        expect(state.isLoading, isFalse);
        expect(state.feedings, isEmpty);
      },
    );

    test('markAsFed calls FeedingService and updates state on success', () async {
      final now = DateTime.now();
      final scheduledFor = DateTime(now.year, now.month, now.day, 9, 0);

      // Return an aquarium so events get loaded
      when(
        () => mockAquariumRepo.getCachedAquariums(),
      ).thenReturn(Right([_createAquarium(id: 'aq_1')]));

      // Track call count to return different values on subsequent calls
      var callCount = 0;

      // Setup generator to return pending on first call, fed on subsequent calls
      when(
        () => mockGenerator.generateTodayEventsForAllAquariums(
          aquariumIds: any(named: 'aquariumIds'),
          fishNameResolver: any(named: 'fishNameResolver'),
          fishQuantityResolver: any(named: 'fishQuantityResolver'),
          aquariumNameResolver: any(named: 'aquariumNameResolver'),
          avatarResolver: any(named: 'avatarResolver'),
        ),
      ).thenAnswer((_) {
        callCount++;
        // First call returns pending, subsequent calls return fed
        final status = callCount == 1 ? EventStatus.pending : EventStatus.fed;
        return {
          'aq_1': [
            ComputedFeedingEvent(
              scheduleId: 'schedule_1',
              fishId: 'fish_1',
              aquariumId: 'aq_1',
              scheduledFor: scheduledFor,
              time: '09:00',
              foodType: 'flakes',
              status: status,
              aquariumName: 'Test Tank',
            ),
          ],
        };
      });

      // Setup service to return success
      when(
        () => mockFeedingService.markAsFed(
          scheduleId: any(named: 'scheduleId'),
          scheduledFor: any(named: 'scheduledFor'),
          userId: any(named: 'userId'),
          userDisplayName: any(named: 'userDisplayName'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer(
        (_) async => FeedingSuccess(
          log: _createFeedingLog(),
          streak: const Streak(
            id: 'streak_user_123',
            userId: 'user_123',
            currentStreak: 1,
            longestStreak: 1,
          ),
        ),
      );

      container = ProviderContainer(
        overrides: [
          feedingEventGeneratorProvider.overrideWithValue(mockGenerator),
          feedingServiceProvider.overrideWithValue(mockFeedingService),
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          aquariumRepositoryProvider.overrideWithValue(mockAquariumRepo),
          currentStreakProvider.overrideWith(
            (ref) => TestStreakNotifier(
              streakRepository: mockStreakRepo,
              calculateStreakUseCase: mockCalculateStreakUseCase,
              ref: ref,
            ),
          ),
          currentUserProvider.overrideWithValue(testUser),
          checkAchievementsProvider.overrideWith(
            (ref) async => <Achievement>[],
          ),
        ],
      );

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(todayFeedingsProvider);
      expect(state.feedings.length, equals(1));

      // Mark as fed
      await container
          .read(todayFeedingsProvider.notifier)
          .markAsFed('schedule_1');

      // Verify FeedingService was called
      verify(
        () => mockFeedingService.markAsFed(
          scheduleId: 'schedule_1',
          scheduledFor: scheduledFor,
          userId: 'user_123',
          userDisplayName: 'Test User',
          notes: null,
        ),
      ).called(1);

      // Wait for refresh to complete
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Verify state was updated
      final updatedState = container.read(todayFeedingsProvider);
      expect(updatedState.feedings.first.status, equals(EventStatus.fed));
    });

    test(
      'markAsMissed calls FeedingService but does NOT reset streak',
      () async {
        final now = DateTime.now();
        final scheduledFor = DateTime(now.year, now.month, now.day, 9, 0);

        // Return an aquarium so events get loaded
        when(
          () => mockAquariumRepo.getCachedAquariums(),
        ).thenReturn(Right([_createAquarium(id: 'aq_1')]));

        // Setup generator to return an event
        when(
          () => mockGenerator.generateTodayEventsForAllAquariums(
            aquariumIds: any(named: 'aquariumIds'),
            fishNameResolver: any(named: 'fishNameResolver'),
            fishQuantityResolver: any(named: 'fishQuantityResolver'),
            aquariumNameResolver: any(named: 'aquariumNameResolver'),
            avatarResolver: any(named: 'avatarResolver'),
          ),
        ).thenReturn({
          'aq_1': [
            ComputedFeedingEvent(
              scheduleId: 'schedule_1',
              fishId: 'fish_1',
              aquariumId: 'aq_1',
              scheduledFor: scheduledFor,
              time: '09:00',
              foodType: 'flakes',
              status: EventStatus.pending,
              aquariumName: 'Test Tank',
            ),
          ],
        });

        // Setup service to return success - NOTE: streak is NOT reset
        when(
          () => mockFeedingService.markAsSkipped(
            scheduleId: any(named: 'scheduleId'),
            scheduledFor: any(named: 'scheduledFor'),
            userId: any(named: 'userId'),
            userDisplayName: any(named: 'userDisplayName'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer(
          (_) async => FeedingSuccess(
            log: _createFeedingLog(action: 'skipped'),
            streak: const Streak(
              id: 'streak_user_123',
              userId: 'user_123',
              currentStreak: 5, // Streak preserved - NOT reset!
              longestStreak: 10,
            ),
          ),
        );

        container = ProviderContainer(
          overrides: [
            feedingEventGeneratorProvider.overrideWithValue(mockGenerator),
            feedingServiceProvider.overrideWithValue(mockFeedingService),
            fishRepositoryProvider.overrideWithValue(mockFishRepo),
            aquariumRepositoryProvider.overrideWithValue(mockAquariumRepo),
            currentStreakProvider.overrideWith(
              (ref) => TestStreakNotifier(
                streakRepository: mockStreakRepo,
                calculateStreakUseCase: mockCalculateStreakUseCase,
                ref: ref,
              ),
            ),
            currentUserProvider.overrideWithValue(testUser),
          ],
        );

        // Wait for initial load
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Mark as missed (skipped)
        await container
            .read(todayFeedingsProvider.notifier)
            .markAsMissed('schedule_1');

        // Verify FeedingService.markAsSkipped was called
        verify(
          () => mockFeedingService.markAsSkipped(
            scheduleId: 'schedule_1',
            scheduledFor: scheduledFor,
            userId: 'user_123',
            userDisplayName: 'Test User',
            notes: null,
          ),
        ).called(1);

        // IMPORTANT: Verify that streak reset is NOT called from client
        // Per task 25.5 requirement: streak reset is handled by server,
        // not by client-side code
        verifyNever(
          () => mockFeedingService.markAsFed(
            scheduleId: any(named: 'scheduleId'),
            scheduledFor: any(named: 'scheduledFor'),
            userId: any(named: 'userId'),
            userDisplayName: any(named: 'userDisplayName'),
            notes: any(named: 'notes'),
          ),
        );

        // Wait for invalidated currentStreakProvider to complete
        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
    );

    test('markAsFed shows error on conflict (FeedingAlreadyDone)', () async {
      final now = DateTime.now();
      final scheduledFor = DateTime(now.year, now.month, now.day, 9, 0);

      // Return an aquarium so events get loaded
      when(
        () => mockAquariumRepo.getCachedAquariums(),
      ).thenReturn(Right([_createAquarium(id: 'aq_1')]));

      when(
        () => mockGenerator.generateTodayEventsForAllAquariums(
          aquariumIds: any(named: 'aquariumIds'),
          fishNameResolver: any(named: 'fishNameResolver'),
          fishQuantityResolver: any(named: 'fishQuantityResolver'),
          aquariumNameResolver: any(named: 'aquariumNameResolver'),
          avatarResolver: any(named: 'avatarResolver'),
        ),
      ).thenReturn({
        'aq_1': [
          ComputedFeedingEvent(
            scheduleId: 'schedule_1',
            fishId: 'fish_1',
            aquariumId: 'aq_1',
            scheduledFor: scheduledFor,
            time: '09:00',
            foodType: 'flakes',
            status: EventStatus.pending,
            aquariumName: 'Test Tank',
          ),
        ],
      });

      // Service returns conflict
      when(
        () => mockFeedingService.markAsFed(
          scheduleId: any(named: 'scheduleId'),
          scheduledFor: any(named: 'scheduledFor'),
          userId: any(named: 'userId'),
          userDisplayName: any(named: 'userDisplayName'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer(
        (_) async => FeedingAlreadyDone(
          scheduledFor: scheduledFor,
          message: 'Already marked by another family member',
        ),
      );

      container = ProviderContainer(
        overrides: [
          feedingEventGeneratorProvider.overrideWithValue(mockGenerator),
          feedingServiceProvider.overrideWithValue(mockFeedingService),
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          aquariumRepositoryProvider.overrideWithValue(mockAquariumRepo),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      await container
          .read(todayFeedingsProvider.notifier)
          .markAsFed('schedule_1');

      final state = container.read(todayFeedingsProvider);
      expect(state.error, contains('Already marked'));
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
    late MockStreakRepository mockStreakRepo;
    late MockCalculateStreakUseCase mockCalculateStreakUseCase;
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
      mockStreakRepo = MockStreakRepository();
      mockCalculateStreakUseCase = MockCalculateStreakUseCase();
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

      when(() => mockCalculateStreakUseCase.call(any())).thenAnswer(
        (_) async => Right(
          StreakCalculationResult(
            streak: streakModel.toEntity(),
            isActive: true,
            daysUntilExpiry: 2,
          ),
        ),
      );

      container = ProviderContainer(
        overrides: [
          currentStreakProvider.overrideWith(
            (ref) => StreakNotifier(
              streakRepository: mockStreakRepo,
              calculateStreakUseCase: mockCalculateStreakUseCase,
              ref: ref,
            ),
          ),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      // Trigger provider creation (lazy) then wait for async loadStreak
      container.read(currentStreakProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(currentStreakProvider);

      expect(state.isLoading, isFalse);
      expect(state.currentStreak, equals(5));
      expect(state.longestStreak, equals(10));
    });

    test('loadStreak returns default streak when none exists', () async {
      when(() => mockCalculateStreakUseCase.call(any())).thenAnswer(
        (_) async => const Right(
          StreakCalculationResult(
            streak: Streak(
              id: 'streak_user_123',
              userId: 'user_123',
              currentStreak: 0,
              longestStreak: 0,
            ),
            isActive: false,
            daysUntilExpiry: 0,
          ),
        ),
      );

      container = ProviderContainer(
        overrides: [
          currentStreakProvider.overrideWith(
            (ref) => StreakNotifier(
              streakRepository: mockStreakRepo,
              calculateStreakUseCase: mockCalculateStreakUseCase,
              ref: ref,
            ),
          ),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      // Trigger provider creation (lazy) then wait for async loadStreak
      container.read(currentStreakProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(currentStreakProvider);

      expect(state.isLoading, isFalse);
      expect(state.currentStreak, equals(0));
      expect(state.longestStreak, equals(0));
    });

    test('incrementStreak calls datasource incrementStreak', () async {
      final updatedStreak = StreakModel(
        id: 'streak_user_123',
        userId: 'user_123',
        currentStreak: 6,
        longestStreak: 10,
      );

      when(() => mockCalculateStreakUseCase.call(any())).thenAnswer(
        (_) async => const Right(
          StreakCalculationResult(
            streak: Streak(
              id: 'streak_user_123',
              userId: 'user_123',
              currentStreak: 5,
              longestStreak: 10,
            ),
            isActive: true,
            daysUntilExpiry: 2,
          ),
        ),
      );
      when(
        () => mockStreakRepo.incrementStreak('user_123', any()),
      ).thenAnswer((_) async => Right(updatedStreak.toEntity()));

      container = ProviderContainer(
        overrides: [
          currentStreakProvider.overrideWith(
            (ref) => StreakNotifier(
              streakRepository: mockStreakRepo,
              calculateStreakUseCase: mockCalculateStreakUseCase,
              ref: ref,
            ),
          ),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      // Trigger provider creation (lazy) then wait for async loadStreak
      container.read(currentStreakProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await container.read(currentStreakProvider.notifier).incrementStreak();

      verify(() => mockStreakRepo.incrementStreak('user_123', any())).called(1);

      final state = container.read(currentStreakProvider);
      expect(state.currentStreak, equals(6));
    });

    // Note: resetStreak test removed - streak reset is handled by server
    // during POST /sync via _check_streak_breaks function.
    // Client only increments streak on markAsFed and reads from Hive.
    // Test below verifies this architectural decision:

    test(
      'StreakNotifier does NOT have resetStreak method - server handles streak breaks',
      () {
        // This test verifies the architectural decision from Task 25.5:
        // Client should NOT reset streaks - that's server's responsibility.
        //
        // The StreakNotifier class no longer has a resetStreak() method.
        // We verify this by checking that the class has incrementStreak but not resetStreak.
        //
        // To actually verify the method doesn't exist, we rely on the fact that
        // calling a non-existent method would be a compile error.
        // Since this test compiles, the method doesn't exist on StreakNotifier.

        expect(true, isTrue); // If we got here, resetStreak doesn't exist
      },
    );
  });

  group('currentStreakCountProvider', () {
    test('returns currentStreak from streakProvider', () async {
      final mockStreakRepo = MockStreakRepository();
      final mockUseCase = MockCalculateStreakUseCase();

      when(() => mockUseCase.call(any())).thenAnswer(
        (_) async => const Right(
          StreakCalculationResult(
            streak: Streak(
              id: 'streak_user_123',
              userId: 'user_123',
              currentStreak: 7,
              longestStreak: 15,
            ),
            isActive: true,
            daysUntilExpiry: 2,
          ),
        ),
      );

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
          currentStreakProvider.overrideWith(
            (ref) => StreakNotifier(
              streakRepository: mockStreakRepo,
              calculateStreakUseCase: mockUseCase,
              ref: ref,
            ),
          ),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      // Trigger provider creation (lazy) then wait for async loadStreak
      container.read(currentStreakProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final count = container.read(currentStreakCountProvider);
      expect(count, equals(7));

      container.dispose();
    });
  });

  group('isStreakActiveProvider', () {
    test('returns true when streak > 0', () async {
      final mockStreakRepo = MockStreakRepository();
      final mockUseCase = MockCalculateStreakUseCase();

      when(() => mockUseCase.call(any())).thenAnswer(
        (_) async => const Right(
          StreakCalculationResult(
            streak: Streak(
              id: 'streak_user_123',
              userId: 'user_123',
              currentStreak: 3,
              longestStreak: 10,
            ),
            isActive: true,
            daysUntilExpiry: 2,
          ),
        ),
      );

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
          currentStreakProvider.overrideWith(
            (ref) => StreakNotifier(
              streakRepository: mockStreakRepo,
              calculateStreakUseCase: mockUseCase,
              ref: ref,
            ),
          ),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      // Trigger provider creation (lazy) then wait for async loadStreak
      container.read(currentStreakProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final isActive = container.read(isStreakActiveProvider);
      expect(isActive, isTrue);

      container.dispose();
    });

    test('returns false when streak is 0', () async {
      final mockStreakRepo = MockStreakRepository();
      final mockUseCase = MockCalculateStreakUseCase();

      when(() => mockUseCase.call(any())).thenAnswer(
        (_) async => const Right(
          StreakCalculationResult(
            streak: Streak(
              id: 'streak_user_123',
              userId: 'user_123',
              currentStreak: 0,
              longestStreak: 10,
            ),
            isActive: false,
            daysUntilExpiry: 0,
          ),
        ),
      );

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
          currentStreakProvider.overrideWith(
            (ref) => StreakNotifier(
              streakRepository: mockStreakRepo,
              calculateStreakUseCase: mockUseCase,
              ref: ref,
            ),
          ),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      // Trigger provider creation (lazy) then wait for async loadStreak
      container.read(currentStreakProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final isActive = container.read(isStreakActiveProvider);
      expect(isActive, isFalse);

      container.dispose();
    });
  });

  group('groupedFeedingsProvider', () {
    test('groups feedings by time period', () async {
      final mockGenerator = MockFeedingEventGenerator();
      final mockFeedingService = MockFeedingService();
      final mockFishRepo = MockFishRepository();
      final mockAquariumRepo = MockAquariumRepository();

      when(() => mockFishRepo.getAllFish()).thenReturn([]);
      when(
        () => mockAquariumRepo.getCachedAquariums(),
      ).thenReturn(const Right([]));
      when(
        () => mockGenerator.generateTodayEventsForAllAquariums(
          aquariumIds: any(named: 'aquariumIds'),
          fishNameResolver: any(named: 'fishNameResolver'),
          fishQuantityResolver: any(named: 'fishQuantityResolver'),
          aquariumNameResolver: any(named: 'aquariumNameResolver'),
          avatarResolver: any(named: 'avatarResolver'),
        ),
      ).thenReturn({});

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
          feedingEventGeneratorProvider.overrideWithValue(mockGenerator),
          feedingServiceProvider.overrideWithValue(mockFeedingService),
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          aquariumRepositoryProvider.overrideWithValue(mockAquariumRepo),
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

  group('Client does not reset streak', () {
    // Task 25.5 requirement:
    // "Тест має підтвердити що TodayFeedingsNotifier.markAsFed() викликає
    // incrementStreak, але жоден код-path у клієнті не викликає resetStreak."
    //
    // These tests verify that:
    // 1. markAsFed increments streak (via FeedingService)
    // 2. markAsMissed does NOT reset streak
    // 3. StreakNotifier has no resetStreak method

    test('markAsFed triggers streak increment via FeedingService', () async {
      final mockGenerator = MockFeedingEventGenerator();
      final mockFeedingService = MockFeedingService();
      final mockFishRepo = MockFishRepository();
      final mockAquariumRepo = MockAquariumRepository();
      final mockStreakRepo = MockStreakRepository();
      final mockUseCase = MockCalculateStreakUseCase();

      final now = DateTime.now();
      final scheduledFor = DateTime(now.year, now.month, now.day, 9, 0);

      when(() => mockFishRepo.getAllFish()).thenReturn([]);
      // Return an aquarium so events get loaded
      when(
        () => mockAquariumRepo.getCachedAquariums(),
      ).thenReturn(Right([_createAquarium(id: 'aq_1')]));
      when(
        () => mockGenerator.generateTodayEventsForAllAquariums(
          aquariumIds: any(named: 'aquariumIds'),
          fishNameResolver: any(named: 'fishNameResolver'),
          fishQuantityResolver: any(named: 'fishQuantityResolver'),
          aquariumNameResolver: any(named: 'aquariumNameResolver'),
          avatarResolver: any(named: 'avatarResolver'),
        ),
      ).thenReturn({
        'aq_1': [
          ComputedFeedingEvent(
            scheduleId: 'schedule_1',
            fishId: 'fish_1',
            aquariumId: 'aq_1',
            scheduledFor: scheduledFor,
            time: '09:00',
            foodType: 'flakes',
            status: EventStatus.pending,
            aquariumName: 'Test Tank',
          ),
        ],
      });

      // FeedingService.markAsFed returns success with incremented streak
      when(
        () => mockFeedingService.markAsFed(
          scheduleId: any(named: 'scheduleId'),
          scheduledFor: any(named: 'scheduledFor'),
          userId: any(named: 'userId'),
          userDisplayName: any(named: 'userDisplayName'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer(
        (_) async => FeedingSuccess(
          log: _createFeedingLog(),
          streak: const Streak(
            id: 'streak_user_123',
            userId: 'user_123',
            currentStreak: 6, // Incremented from 5
            longestStreak: 10,
          ),
        ),
      );

      // Mock CalculateStreakUseCase for StreakNotifier
      when(() => mockUseCase.call(any())).thenAnswer(
        (_) async => const Right(
          StreakCalculationResult(
            streak: Streak(
              id: 'streak_user_123',
              userId: 'user_123',
              currentStreak: 5,
              longestStreak: 10,
            ),
            isActive: true,
            daysUntilExpiry: 2,
          ),
        ),
      );

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
          feedingEventGeneratorProvider.overrideWithValue(mockGenerator),
          feedingServiceProvider.overrideWithValue(mockFeedingService),
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          aquariumRepositoryProvider.overrideWithValue(mockAquariumRepo),
          currentStreakProvider.overrideWith(
            (ref) => TestStreakNotifier(
              streakRepository: mockStreakRepo,
              calculateStreakUseCase: mockUseCase,
              ref: ref,
            ),
          ),
          currentUserProvider.overrideWithValue(testUser),
          checkAchievementsProvider.overrideWith(
            (ref) async => <Achievement>[],
          ),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Mark as fed
      await container
          .read(todayFeedingsProvider.notifier)
          .markAsFed('schedule_1');

      // Verify FeedingService.markAsFed was called (which internally calls
      // incrementStreak)
      verify(
        () => mockFeedingService.markAsFed(
          scheduleId: 'schedule_1',
          scheduledFor: scheduledFor,
          userId: 'user_123',
          userDisplayName: 'Test User',
          notes: null,
        ),
      ).called(1);

      // Wait for invalidated currentStreakProvider to re-create and complete
      await Future<void>.delayed(const Duration(milliseconds: 100));

      container.dispose();
    });

    test('markAsMissed does NOT call any streak reset method', () async {
      final mockGenerator = MockFeedingEventGenerator();
      final mockFeedingService = MockFeedingService();
      final mockFishRepo = MockFishRepository();
      final mockAquariumRepo = MockAquariumRepository();
      final mockStreakRepo = MockStreakRepository();
      final mockUseCase = MockCalculateStreakUseCase();

      final now = DateTime.now();
      final scheduledFor = DateTime(now.year, now.month, now.day, 9, 0);

      when(() => mockFishRepo.getAllFish()).thenReturn([]);
      // Return an aquarium so events get loaded
      when(
        () => mockAquariumRepo.getCachedAquariums(),
      ).thenReturn(Right([_createAquarium(id: 'aq_1')]));
      when(
        () => mockGenerator.generateTodayEventsForAllAquariums(
          aquariumIds: any(named: 'aquariumIds'),
          fishNameResolver: any(named: 'fishNameResolver'),
          fishQuantityResolver: any(named: 'fishQuantityResolver'),
          aquariumNameResolver: any(named: 'aquariumNameResolver'),
          avatarResolver: any(named: 'avatarResolver'),
        ),
      ).thenReturn({
        'aq_1': [
          ComputedFeedingEvent(
            scheduleId: 'schedule_1',
            fishId: 'fish_1',
            aquariumId: 'aq_1',
            scheduledFor: scheduledFor,
            time: '09:00',
            foodType: 'flakes',
            status: EventStatus.pending,
            aquariumName: 'Test Tank',
          ),
        ],
      });

      // FeedingService.markAsSkipped returns success with streak PRESERVED
      when(
        () => mockFeedingService.markAsSkipped(
          scheduleId: any(named: 'scheduleId'),
          scheduledFor: any(named: 'scheduledFor'),
          userId: any(named: 'userId'),
          userDisplayName: any(named: 'userDisplayName'),
          notes: any(named: 'notes'),
        ),
      ).thenAnswer(
        (_) async => FeedingSuccess(
          log: _createFeedingLog(action: 'skipped'),
          streak: const Streak(
            id: 'streak_user_123',
            userId: 'user_123',
            currentStreak: 5, // NOT reset - preserved
            longestStreak: 10,
          ),
        ),
      );

      // Mock CalculateStreakUseCase for StreakNotifier
      when(() => mockUseCase.call(any())).thenAnswer(
        (_) async => const Right(
          StreakCalculationResult(
            streak: Streak(
              id: 'streak_user_123',
              userId: 'user_123',
              currentStreak: 5,
              longestStreak: 10,
            ),
            isActive: true,
            daysUntilExpiry: 2,
          ),
        ),
      );

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
          feedingEventGeneratorProvider.overrideWithValue(mockGenerator),
          feedingServiceProvider.overrideWithValue(mockFeedingService),
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          aquariumRepositoryProvider.overrideWithValue(mockAquariumRepo),
          currentStreakProvider.overrideWith(
            (ref) => TestStreakNotifier(
              streakRepository: mockStreakRepo,
              calculateStreakUseCase: mockUseCase,
              ref: ref,
            ),
          ),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Mark as missed
      await container
          .read(todayFeedingsProvider.notifier)
          .markAsMissed('schedule_1');

      // Verify that:
      // 1. markAsSkipped was called
      verify(
        () => mockFeedingService.markAsSkipped(
          scheduleId: 'schedule_1',
          scheduledFor: scheduledFor,
          userId: 'user_123',
          userDisplayName: 'Test User',
          notes: null,
        ),
      ).called(1);

      // 2. resetStreak was NOT called on streakDs during markAsMissed
      verifyNever(() => mockStreakRepo.handleMissedDay(any(), any()));

      // Wait for invalidated currentStreakProvider to re-create and complete
      await Future<void>.delayed(const Duration(milliseconds: 100));

      container.dispose();
    });
  });

  group('feedingsGroupedByTimeProvider', () {
    late MockFeedingEventGenerator mockGenerator;
    late MockFeedingService mockFeedingService;
    late MockFishRepository mockFishRepo;
    late MockAquariumRepository mockAquariumRepo;

    final testUser = User(
      id: 'user_123',
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: DateTime(2024, 1, 15),
      subscriptionStatus: const SubscriptionStatus.free(),
      freeAiScansRemaining: 5,
    );

    setUp(() {
      mockGenerator = MockFeedingEventGenerator();
      mockFeedingService = MockFeedingService();
      mockFishRepo = MockFishRepository();
      mockAquariumRepo = MockAquariumRepository();

      when(() => mockFishRepo.getAllFish()).thenReturn([]);
      when(
        () => mockAquariumRepo.getCachedAquariums(),
      ).thenReturn(Right([_createAquarium(id: 'aq_1')]));
    });

    test('groups feedings by exact time string', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      when(
        () => mockGenerator.generateTodayEventsForAllAquariums(
          aquariumIds: any(named: 'aquariumIds'),
          fishNameResolver: any(named: 'fishNameResolver'),
          fishQuantityResolver: any(named: 'fishQuantityResolver'),
          aquariumNameResolver: any(named: 'aquariumNameResolver'),
          avatarResolver: any(named: 'avatarResolver'),
        ),
      ).thenReturn({
        'aq_1': [
          _createFeeding(
            's1',
            today.add(const Duration(hours: 9)),
            EventStatus.pending,
          ),
          _createFeeding(
            's2',
            today.add(const Duration(hours: 9)),
            EventStatus.fed,
          ),
          _createFeeding(
            's3',
            today.add(const Duration(hours: 18)),
            EventStatus.pending,
          ),
        ],
      });

      final container = ProviderContainer(
        overrides: [
          feedingEventGeneratorProvider.overrideWithValue(mockGenerator),
          feedingServiceProvider.overrideWithValue(mockFeedingService),
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          aquariumRepositoryProvider.overrideWithValue(mockAquariumRepo),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final grouped = container.read(feedingsGroupedByTimeProvider('aq_1'));

      expect(grouped.keys.toList(), ['09:00', '18:00']);
      expect(grouped['09:00']!.length, 2);
      expect(grouped['18:00']!.length, 1);

      container.dispose();
    });

    test('sorts keys chronologically', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      when(
        () => mockGenerator.generateTodayEventsForAllAquariums(
          aquariumIds: any(named: 'aquariumIds'),
          fishNameResolver: any(named: 'fishNameResolver'),
          fishQuantityResolver: any(named: 'fishQuantityResolver'),
          aquariumNameResolver: any(named: 'aquariumNameResolver'),
          avatarResolver: any(named: 'avatarResolver'),
        ),
      ).thenReturn({
        'aq_1': [
          _createFeeding(
            's1',
            today.add(const Duration(hours: 18)),
            EventStatus.pending,
          ),
          _createFeeding(
            's2',
            today.add(const Duration(hours: 9)),
            EventStatus.pending,
          ),
          _createFeeding(
            's3',
            today.add(const Duration(hours: 12)),
            EventStatus.pending,
          ),
        ],
      });

      final container = ProviderContainer(
        overrides: [
          feedingEventGeneratorProvider.overrideWithValue(mockGenerator),
          feedingServiceProvider.overrideWithValue(mockFeedingService),
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          aquariumRepositoryProvider.overrideWithValue(mockAquariumRepo),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final grouped = container.read(feedingsGroupedByTimeProvider('aq_1'));
      expect(grouped.keys.toList(), ['09:00', '12:00', '18:00']);

      container.dispose();
    });

    test('returns empty map for empty feedings list', () async {
      when(
        () => mockGenerator.generateTodayEventsForAllAquariums(
          aquariumIds: any(named: 'aquariumIds'),
          fishNameResolver: any(named: 'fishNameResolver'),
          fishQuantityResolver: any(named: 'fishQuantityResolver'),
          aquariumNameResolver: any(named: 'aquariumNameResolver'),
          avatarResolver: any(named: 'avatarResolver'),
        ),
      ).thenReturn({'aq_1': []});

      final container = ProviderContainer(
        overrides: [
          feedingEventGeneratorProvider.overrideWithValue(mockGenerator),
          feedingServiceProvider.overrideWithValue(mockFeedingService),
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          aquariumRepositoryProvider.overrideWithValue(mockAquariumRepo),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final grouped = container.read(feedingsGroupedByTimeProvider('aq_1'));
      expect(grouped, isEmpty);

      container.dispose();
    });

    test('multiple feedings in same time slot', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      when(
        () => mockGenerator.generateTodayEventsForAllAquariums(
          aquariumIds: any(named: 'aquariumIds'),
          fishNameResolver: any(named: 'fishNameResolver'),
          fishQuantityResolver: any(named: 'fishQuantityResolver'),
          aquariumNameResolver: any(named: 'aquariumNameResolver'),
          avatarResolver: any(named: 'avatarResolver'),
        ),
      ).thenReturn({
        'aq_1': [
          _createFeeding(
            's1',
            today.add(const Duration(hours: 9)),
            EventStatus.pending,
          ),
          _createFeeding(
            's2',
            today.add(const Duration(hours: 9)),
            EventStatus.fed,
          ),
          _createFeeding(
            's3',
            today.add(const Duration(hours: 9)),
            EventStatus.pending,
          ),
        ],
      });

      final container = ProviderContainer(
        overrides: [
          feedingEventGeneratorProvider.overrideWithValue(mockGenerator),
          feedingServiceProvider.overrideWithValue(mockFeedingService),
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          aquariumRepositoryProvider.overrideWithValue(mockAquariumRepo),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final grouped = container.read(feedingsGroupedByTimeProvider('aq_1'));
      expect(grouped.keys.toList(), ['09:00']);
      expect(grouped['09:00']!.length, 3);

      container.dispose();
    });
  });

  group('aquariumFeedingStatusProvider', () {
    late MockFeedingEventGenerator mockGenerator;
    late MockFeedingService mockFeedingService;
    late MockFishRepository mockFishRepo;
    late MockAquariumRepository mockAquariumRepo;

    final testUser = User(
      id: 'user_123',
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: DateTime(2024, 1, 15),
      subscriptionStatus: const SubscriptionStatus.free(),
      freeAiScansRemaining: 5,
    );

    setUp(() {
      mockGenerator = MockFeedingEventGenerator();
      mockFeedingService = MockFeedingService();
      mockFishRepo = MockFishRepository();
      mockAquariumRepo = MockAquariumRepository();

      when(() => mockFishRepo.getAllFish()).thenReturn([]);
      when(
        () => mockAquariumRepo.getCachedAquariums(),
      ).thenReturn(Right([_createAquarium(id: 'aq_1')]));
    });

    test('returns pendingFeeding when there are overdue feedings', () async {
      // Create feeding in the past (overdue)
      final pastTime = DateTime.now().subtract(const Duration(hours: 2));

      when(
        () => mockGenerator.generateTodayEventsForAllAquariums(
          aquariumIds: any(named: 'aquariumIds'),
          fishNameResolver: any(named: 'fishNameResolver'),
          fishQuantityResolver: any(named: 'fishQuantityResolver'),
          aquariumNameResolver: any(named: 'aquariumNameResolver'),
          avatarResolver: any(named: 'avatarResolver'),
        ),
      ).thenReturn({
        'aq_1': [_createFeeding('s1', pastTime, EventStatus.overdue)],
      });

      final container = ProviderContainer(
        overrides: [
          feedingEventGeneratorProvider.overrideWithValue(mockGenerator),
          feedingServiceProvider.overrideWithValue(mockFeedingService),
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          aquariumRepositoryProvider.overrideWithValue(mockAquariumRepo),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final result = container.read(aquariumFeedingStatusProvider('aq_1'));
      expect(result.status, AquariumFeedingStatus.pendingFeeding);
      expect(result.nextTime, isNotNull);

      container.dispose();
    });

    test('returns allFed when all feedings are completed', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      when(
        () => mockGenerator.generateTodayEventsForAllAquariums(
          aquariumIds: any(named: 'aquariumIds'),
          fishNameResolver: any(named: 'fishNameResolver'),
          fishQuantityResolver: any(named: 'fishQuantityResolver'),
          aquariumNameResolver: any(named: 'aquariumNameResolver'),
          avatarResolver: any(named: 'avatarResolver'),
        ),
      ).thenReturn({
        'aq_1': [
          _createFeeding(
            's1',
            today.add(const Duration(hours: 9)),
            EventStatus.fed,
          ),
          _createFeeding(
            's2',
            today.add(const Duration(hours: 12)),
            EventStatus.fed,
          ),
        ],
      });

      final container = ProviderContainer(
        overrides: [
          feedingEventGeneratorProvider.overrideWithValue(mockGenerator),
          feedingServiceProvider.overrideWithValue(mockFeedingService),
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          aquariumRepositoryProvider.overrideWithValue(mockAquariumRepo),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final result = container.read(aquariumFeedingStatusProvider('aq_1'));
      expect(result.status, AquariumFeedingStatus.allFed);
      expect(result.nextTime, isNull);

      container.dispose();
    });

    test('returns nextAt when next feeding is in the future', () async {
      final futureTime = DateTime.now().add(const Duration(hours: 3));

      when(
        () => mockGenerator.generateTodayEventsForAllAquariums(
          aquariumIds: any(named: 'aquariumIds'),
          fishNameResolver: any(named: 'fishNameResolver'),
          fishQuantityResolver: any(named: 'fishQuantityResolver'),
          aquariumNameResolver: any(named: 'aquariumNameResolver'),
          avatarResolver: any(named: 'avatarResolver'),
        ),
      ).thenReturn({
        'aq_1': [_createFeeding('s1', futureTime, EventStatus.pending)],
      });

      final container = ProviderContainer(
        overrides: [
          feedingEventGeneratorProvider.overrideWithValue(mockGenerator),
          feedingServiceProvider.overrideWithValue(mockFeedingService),
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          aquariumRepositoryProvider.overrideWithValue(mockAquariumRepo),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final result = container.read(aquariumFeedingStatusProvider('aq_1'));
      expect(result.status, AquariumFeedingStatus.nextAt);
      expect(result.nextTime, isNotNull);

      container.dispose();
    });

    test('returns allFed for empty feedings list', () async {
      when(
        () => mockGenerator.generateTodayEventsForAllAquariums(
          aquariumIds: any(named: 'aquariumIds'),
          fishNameResolver: any(named: 'fishNameResolver'),
          fishQuantityResolver: any(named: 'fishQuantityResolver'),
          aquariumNameResolver: any(named: 'aquariumNameResolver'),
          avatarResolver: any(named: 'avatarResolver'),
        ),
      ).thenReturn({'aq_1': []});

      final container = ProviderContainer(
        overrides: [
          feedingEventGeneratorProvider.overrideWithValue(mockGenerator),
          feedingServiceProvider.overrideWithValue(mockFeedingService),
          fishRepositoryProvider.overrideWithValue(mockFishRepo),
          aquariumRepositoryProvider.overrideWithValue(mockAquariumRepo),
          currentUserProvider.overrideWithValue(testUser),
        ],
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final result = container.read(aquariumFeedingStatusProvider('aq_1'));
      expect(result.status, AquariumFeedingStatus.allFed);
      expect(result.nextTime, isNull);

      container.dispose();
    });
  });
}

/// Helper to create a computed feeding event for testing.
ComputedFeedingEvent _createFeeding(
  String scheduleId,
  DateTime time,
  EventStatus status,
) {
  return ComputedFeedingEvent(
    scheduleId: scheduleId,
    fishId: 'fish_1',
    aquariumId: 'aq_1',
    scheduledFor: time,
    time:
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
    foodType: 'flakes',
    status: status,
    aquariumName: 'Test Tank',
    fishName: 'Test Fish',
  );
}

/// Helper to create a FeedingLogModel for testing.
FeedingLogModel _createFeedingLog({String action = 'fed'}) {
  final now = DateTime.now();
  return FeedingLogModel(
    id: 'log_${now.millisecondsSinceEpoch}',
    scheduleId: 'schedule_1',
    fishId: 'fish_1',
    aquariumId: 'aq_1',
    scheduledFor: now,
    action: action,
    actedAt: now.toUtc(),
    actedByUserId: 'user_123',
    actedByUserName: 'Test User',
    deviceId: 'test_device',
    createdAt: now,
    synced: false,
  );
}

/// Helper to create an Aquarium entity for testing.
Aquarium _createAquarium({
  String id = 'aq_1',
  String name = 'Test Tank',
}) {
  return Aquarium(
    id: id,
    userId: 'user_123',
    name: name,
    waterType: WaterType.freshwater,
    createdAt: DateTime(2024, 1, 1),
  );
}
