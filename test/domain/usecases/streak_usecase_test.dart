import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/data/models/feeding_event_model.dart';
import 'package:fishfeed/data/models/streak_model.dart';
import 'package:fishfeed/domain/entities/streak.dart';
import 'package:fishfeed/domain/usecases/streak_usecase.dart';

class MockStreakLocalDataSource extends Mock implements StreakLocalDataSource {}

class MockFeedingLocalDataSource extends Mock
    implements FeedingLocalDataSource {}

class MockBox extends Mock implements Box<dynamic> {}

class FakeStreakModel extends Fake implements StreakModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeStreakModel());
    registerFallbackValue(DateTime.now());
  });

  late MockStreakLocalDataSource mockStreakDs;
  late MockFeedingLocalDataSource mockFeedingDs;
  late StreakUseCase useCase;

  setUp(() {
    mockStreakDs = MockStreakLocalDataSource();
    mockFeedingDs = MockFeedingLocalDataSource();
    useCase = StreakUseCase(
      streakDataSource: mockStreakDs,
      feedingDataSource: mockFeedingDs,
    );
  });

  StreakModel createTestStreak({
    String id = 'streak_user_1',
    String userId = 'user_1',
    int currentStreak = 5,
    int longestStreak = 10,
    DateTime? lastFeedingDate,
    DateTime? streakStartDate,
    int freezeAvailable = kDefaultFreezePerMonth,
    List<DateTime> frozenDays = const [],
    DateTime? lastFreezeResetDate,
  }) {
    return StreakModel(
      id: id,
      userId: userId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastFeedingDate: lastFeedingDate ?? DateTime(2025, 6, 15),
      streakStartDate: streakStartDate ?? DateTime(2025, 6, 10),
      freezeAvailable: freezeAvailable,
      frozenDays: frozenDays,
      lastFreezeResetDate: lastFreezeResetDate,
    );
  }

  group('checkAndUpdateStreak', () {
    test('should return validation error when userId is empty', () async {
      const params = CheckAndUpdateStreakParams(
        userId: '',
        aquariumId: 'aquarium_1',
        totalScheduledFeedings: 3,
        completedFeedings: 3,
      );

      final result = await useCase.checkAndUpdateStreak(params);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) =>
            expect(failure.toString(), contains('User ID is required')),
        (_) => fail('Should return failure'),
      );
    });

    test('should increment streak when all feedings completed', () async {
      const params = CheckAndUpdateStreakParams(
        userId: 'user_1',
        aquariumId: 'aquarium_1',
        totalScheduledFeedings: 3,
        completedFeedings: 3,
      );

      final updatedStreak = createTestStreak(currentStreak: 6);

      when(
        () => mockStreakDs.checkAndResetMonthlyFreeze('user_1'),
      ).thenAnswer((_) async => createTestStreak(currentStreak: 5));
      when(
        () => mockStreakDs.incrementStreak('user_1', any()),
      ).thenAnswer((_) async => updatedStreak);

      final result = await useCase.checkAndUpdateStreak(params);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (updateResult) {
        expect(updateResult.wasIncremented, isTrue);
        expect(updateResult.wasReset, isFalse);
        expect(updateResult.freezeUsed, isFalse);
        expect(updateResult.streak.currentStreak, 6);
      });
    });

    test(
      'should not increment streak when not all feedings completed',
      () async {
        const params = CheckAndUpdateStreakParams(
          userId: 'user_1',
          aquariumId: 'aquarium_1',
          totalScheduledFeedings: 3,
          completedFeedings: 2,
        );

        final existingStreak = createTestStreak(currentStreak: 5);

        when(
          () => mockStreakDs.checkAndResetMonthlyFreeze('user_1'),
        ).thenAnswer((_) async => existingStreak);
        when(
          () => mockStreakDs.getStreakByUserId('user_1'),
        ).thenReturn(existingStreak);

        final result = await useCase.checkAndUpdateStreak(params);

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Should return success'), (updateResult) {
          expect(updateResult.wasIncremented, isFalse);
          expect(updateResult.streak.currentStreak, 5);
        });
        verifyNever(() => mockStreakDs.incrementStreak(any(), any()));
      },
    );

    test('should create new streak when none exists', () async {
      const params = CheckAndUpdateStreakParams(
        userId: 'user_1',
        aquariumId: 'aquarium_1',
        totalScheduledFeedings: 3,
        completedFeedings: 2,
      );

      when(
        () => mockStreakDs.checkAndResetMonthlyFreeze('user_1'),
      ).thenAnswer((_) async => null);
      when(() => mockStreakDs.getStreakByUserId('user_1')).thenReturn(null);
      when(() => mockStreakDs.saveStreak(any())).thenAnswer((_) async {});

      final result = await useCase.checkAndUpdateStreak(params);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (updateResult) {
        expect(updateResult.wasIncremented, isFalse);
        expect(updateResult.streak.currentStreak, 0);
      });
    });
  });

  group('handleMissedDay', () {
    test('should return validation error when userId is empty', () async {
      final result = await useCase.handleMissedDay(
        userId: '',
        missedDate: DateTime.now(),
      );

      expect(result.isLeft(), isTrue);
    });

    test('should use freeze when available', () async {
      final missedDate = DateTime(2025, 6, 16);
      final beforeStreak = createTestStreak(
        currentStreak: 5,
        freezeAvailable: 2,
      );
      final afterStreak = createTestStreak(
        currentStreak: 5,
        freezeAvailable: 1,
        frozenDays: [missedDate],
      );

      when(
        () => mockStreakDs.checkAndResetMonthlyFreeze('user_1'),
      ).thenAnswer((_) async => beforeStreak);
      when(
        () => mockStreakDs.getStreakByUserId('user_1'),
      ).thenReturn(beforeStreak);
      when(
        () => mockStreakDs.handleMissedDay('user_1', missedDate),
      ).thenAnswer((_) async => afterStreak);

      final result = await useCase.handleMissedDay(
        userId: 'user_1',
        missedDate: missedDate,
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (updateResult) {
        expect(updateResult.freezeUsed, isTrue);
        expect(updateResult.wasReset, isFalse);
        expect(updateResult.streak.currentStreak, 5);
      });
    });

    test('should reset streak when no freeze available', () async {
      final missedDate = DateTime(2025, 6, 16);
      final beforeStreak = createTestStreak(
        currentStreak: 5,
        freezeAvailable: 0,
      );
      final afterStreak = createTestStreak(
        currentStreak: 0,
        freezeAvailable: 0,
      );

      when(
        () => mockStreakDs.checkAndResetMonthlyFreeze('user_1'),
      ).thenAnswer((_) async => beforeStreak);
      when(
        () => mockStreakDs.getStreakByUserId('user_1'),
      ).thenReturn(beforeStreak);
      when(
        () => mockStreakDs.handleMissedDay('user_1', missedDate),
      ).thenAnswer((_) async => afterStreak);

      final result = await useCase.handleMissedDay(
        userId: 'user_1',
        missedDate: missedDate,
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (updateResult) {
        expect(updateResult.freezeUsed, isFalse);
        expect(updateResult.wasReset, isTrue);
        expect(updateResult.streak.currentStreak, 0);
      });
    });
  });

  group('useFreeze', () {
    test('should return validation error when userId is empty', () async {
      final result = await useCase.useFreeze(
        userId: '',
        freezeDate: DateTime.now(),
      );

      expect(result.isLeft(), isTrue);
    });

    test('should use freeze successfully', () async {
      final freezeDate = DateTime(2025, 6, 16);
      final updatedStreak = createTestStreak(
        freezeAvailable: 1,
        frozenDays: [freezeDate],
      );

      when(
        () => mockStreakDs.useFreeze('user_1', freezeDate),
      ).thenAnswer((_) async => updatedStreak);

      final result = await useCase.useFreeze(
        userId: 'user_1',
        freezeDate: freezeDate,
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (streak) {
        expect(streak.freezeAvailable, 1);
        expect(streak.frozenDays.length, 1);
      });
    });

    test('should return error when no freeze available', () async {
      final freezeDate = DateTime(2025, 6, 16);

      when(
        () => mockStreakDs.useFreeze('user_1', freezeDate),
      ).thenAnswer((_) async => null);

      final result = await useCase.useFreeze(
        userId: 'user_1',
        freezeDate: freezeDate,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) =>
            expect(failure.toString(), contains('No freeze days available')),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('isAllFedForDay', () {
    test('should return true when all feedings completed', () {
      final result = useCase.isAllFedForDay(3, 3);
      expect(result, isTrue);
    });

    test('should return true when more feedings than scheduled', () {
      final result = useCase.isAllFedForDay(3, 5);
      expect(result, isTrue);
    });

    test('should return false when not all feedings completed', () {
      final result = useCase.isAllFedForDay(3, 2);
      expect(result, isFalse);
    });

    test('should return false when no scheduled feedings', () {
      final result = useCase.isAllFedForDay(0, 0);
      expect(result, isFalse);
    });
  });

  group('isAllFedToday', () {
    test('should return true when all aquarium feedings completed', () {
      final date = DateTime(2025, 6, 15);
      final events = [
        FeedingEventModel(
          id: 'event_1',
          fishId: 'fish_1',
          aquariumId: 'aquarium_1',
          feedingTime: date,
          synced: false,
          createdAt: date,
          localId: 'local_1',
        ),
        FeedingEventModel(
          id: 'event_2',
          fishId: 'fish_2',
          aquariumId: 'aquarium_1',
          feedingTime: date,
          synced: false,
          createdAt: date,
          localId: 'local_2',
        ),
      ];

      when(() => mockFeedingDs.getFeedingEventsByDate(date)).thenReturn(events);

      final result = useCase.isAllFedToday(
        aquariumId: 'aquarium_1',
        date: date,
        scheduledCount: 2,
      );

      expect(result, isTrue);
    });

    test('should return false when not all feedings completed', () {
      final date = DateTime(2025, 6, 15);
      final events = [
        FeedingEventModel(
          id: 'event_1',
          fishId: 'fish_1',
          aquariumId: 'aquarium_1',
          feedingTime: date,
          synced: false,
          createdAt: date,
          localId: 'local_1',
        ),
      ];

      when(() => mockFeedingDs.getFeedingEventsByDate(date)).thenReturn(events);

      final result = useCase.isAllFedToday(
        aquariumId: 'aquarium_1',
        date: date,
        scheduledCount: 3,
      );

      expect(result, isFalse);
    });

    test('should only count events for specific aquarium', () {
      final date = DateTime(2025, 6, 15);
      final events = [
        FeedingEventModel(
          id: 'event_1',
          fishId: 'fish_1',
          aquariumId: 'aquarium_1',
          feedingTime: date,
          synced: false,
          createdAt: date,
          localId: 'local_1',
        ),
        FeedingEventModel(
          id: 'event_2',
          fishId: 'fish_2',
          aquariumId: 'aquarium_2',
          feedingTime: date,
          synced: false,
          createdAt: date,
          localId: 'local_2',
        ),
      ];

      when(() => mockFeedingDs.getFeedingEventsByDate(date)).thenReturn(events);

      final result = useCase.isAllFedToday(
        aquariumId: 'aquarium_1',
        date: date,
        scheduledCount: 2,
      );

      expect(result, isFalse);
    });
  });

  group('getStreak', () {
    test('should return validation error when userId is empty', () async {
      final result = await useCase.getStreak('');

      expect(result.isLeft(), isTrue);
    });

    test('should return existing streak', () async {
      final streak = createTestStreak(currentStreak: 7);

      when(
        () => mockStreakDs.checkAndResetMonthlyFreeze('user_1'),
      ).thenAnswer((_) async => streak);

      final result = await useCase.getStreak('user_1');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should return success'),
        (s) => expect(s.currentStreak, 7),
      );
    });

    test('should create new streak when none exists', () async {
      when(
        () => mockStreakDs.checkAndResetMonthlyFreeze('user_1'),
      ).thenAnswer((_) async => null);
      when(() => mockStreakDs.saveStreak(any())).thenAnswer((_) async {});

      final result = await useCase.getStreak('user_1');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (s) {
        expect(s.currentStreak, 0);
        expect(s.userId, 'user_1');
      });
    });
  });

  group('resetMonthlyFreeze', () {
    test('should return validation error when userId is empty', () async {
      final result = await useCase.resetMonthlyFreeze('');

      expect(result.isLeft(), isTrue);
    });

    test('should reset freeze successfully', () async {
      final resetStreak = createTestStreak(
        freezeAvailable: kDefaultFreezePerMonth,
        frozenDays: [],
      );

      when(
        () => mockStreakDs.resetMonthlyFreeze('user_1'),
      ).thenAnswer((_) async => resetStreak);

      final result = await useCase.resetMonthlyFreeze('user_1');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (s) {
        expect(s.freezeAvailable, kDefaultFreezePerMonth);
        expect(s.frozenDays, isEmpty);
      });
    });

    test('should return error when no streak exists', () async {
      when(
        () => mockStreakDs.resetMonthlyFreeze('user_1'),
      ).thenAnswer((_) async => null);

      final result = await useCase.resetMonthlyFreeze('user_1');

      expect(result.isLeft(), isTrue);
    });
  });

  group('isStreakAtRisk', () {
    test('should return false when all fed', () async {
      final result = await useCase.isStreakAtRisk(
        userId: 'user_1',
        currentlyAllFed: true,
      );

      expect(result, isFalse);
    });

    test(
      'should return true when streak is active with freeze available',
      () async {
        final streak = createTestStreak(currentStreak: 5, freezeAvailable: 2);

        when(
          () => mockStreakDs.checkAndResetMonthlyFreeze('user_1'),
        ).thenAnswer((_) async => streak);

        final result = await useCase.isStreakAtRisk(
          userId: 'user_1',
          currentlyAllFed: false,
        );

        expect(result, isTrue);
      },
    );

    test('should return false when streak is zero', () async {
      final streak = createTestStreak(currentStreak: 0, freezeAvailable: 2);

      when(
        () => mockStreakDs.checkAndResetMonthlyFreeze('user_1'),
      ).thenAnswer((_) async => streak);

      final result = await useCase.isStreakAtRisk(
        userId: 'user_1',
        currentlyAllFed: false,
      );

      expect(result, isFalse);
    });

    test('should return false when no freeze available', () async {
      final streak = createTestStreak(currentStreak: 5, freezeAvailable: 0);

      when(
        () => mockStreakDs.checkAndResetMonthlyFreeze('user_1'),
      ).thenAnswer((_) async => streak);

      final result = await useCase.isStreakAtRisk(
        userId: 'user_1',
        currentlyAllFed: false,
      );

      expect(result, isFalse);
    });

    test('should return false when streak fetch fails', () async {
      when(
        () => mockStreakDs.checkAndResetMonthlyFreeze('user_1'),
      ).thenThrow(Exception('Database error'));

      final result = await useCase.isStreakAtRisk(
        userId: 'user_1',
        currentlyAllFed: false,
      );

      expect(result, isFalse);
    });
  });

  group('getFreezeWarningTime', () {
    test('should return 22:00 of current day', () {
      final warningTime = useCase.getFreezeWarningTime();
      final now = DateTime.now();

      expect(warningTime.year, equals(now.year));
      expect(warningTime.month, equals(now.month));
      expect(warningTime.day, equals(now.day));
      expect(warningTime.hour, equals(22));
      expect(warningTime.minute, equals(0));
    });
  });

  group('Edge Cases', () {
    test('should handle first day of usage correctly', () async {
      const params = CheckAndUpdateStreakParams(
        userId: 'new_user',
        aquariumId: 'aquarium_1',
        totalScheduledFeedings: 2,
        completedFeedings: 2,
      );

      final newStreak = StreakModel(
        id: 'streak_new_user',
        userId: 'new_user',
        currentStreak: 1,
        longestStreak: 1,
        lastFeedingDate: DateTime.now(),
        streakStartDate: DateTime.now(),
      );

      when(
        () => mockStreakDs.checkAndResetMonthlyFreeze('new_user'),
      ).thenAnswer((_) async => null);
      when(
        () => mockStreakDs.incrementStreak('new_user', any()),
      ).thenAnswer((_) async => newStreak);

      final result = await useCase.checkAndUpdateStreak(params);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (updateResult) {
        expect(updateResult.wasIncremented, isTrue);
        expect(updateResult.streak.currentStreak, 1);
      });
    });

    test('should update best streak when current exceeds it', () async {
      const params = CheckAndUpdateStreakParams(
        userId: 'user_1',
        aquariumId: 'aquarium_1',
        totalScheduledFeedings: 2,
        completedFeedings: 2,
      );

      final updatedStreak = createTestStreak(
        currentStreak: 11,
        longestStreak: 11,
      );

      when(() => mockStreakDs.checkAndResetMonthlyFreeze('user_1')).thenAnswer(
        (_) async => createTestStreak(currentStreak: 10, longestStreak: 10),
      );
      when(
        () => mockStreakDs.incrementStreak('user_1', any()),
      ).thenAnswer((_) async => updatedStreak);

      final result = await useCase.checkAndUpdateStreak(params);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (updateResult) {
        expect(updateResult.streak.currentStreak, 11);
        expect(updateResult.streak.longestStreak, 11);
      });
    });
  });
}
