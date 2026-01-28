import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/data/models/feeding_event_model.dart';
import 'package:fishfeed/data/models/streak_model.dart';
import 'package:fishfeed/domain/usecases/calculate_streak_usecase.dart';

class MockStreakLocalDataSource extends Mock implements StreakLocalDataSource {}

class MockFeedingLocalDataSource extends Mock implements FeedingLocalDataSource {
}

void main() {
  late MockStreakLocalDataSource mockStreakDs;
  late MockFeedingLocalDataSource mockFeedingDs;
  late CalculateStreakUseCase useCase;

  setUpAll(() {
    registerFallbackValue(StreakModel(
      id: 'test',
      userId: 'test',
      currentStreak: 0,
      longestStreak: 0,
    ));
  });

  setUp(() {
    mockStreakDs = MockStreakLocalDataSource();
    mockFeedingDs = MockFeedingLocalDataSource();
    useCase = CalculateStreakUseCase(
      streakDataSource: mockStreakDs,
      feedingDataSource: mockFeedingDs,
    );
  });

  StreakModel createTestStreak({
    String userId = 'user_1',
    int currentStreak = 5,
    int longestStreak = 10,
    DateTime? lastFeedingDate,
    DateTime? streakStartDate,
  }) {
    return StreakModel(
      id: 'streak_$userId',
      userId: userId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastFeedingDate: lastFeedingDate,
      streakStartDate: streakStartDate,
    );
  }

  FeedingEventModel createTestFeedingEvent({
    String id = 'event_1',
    DateTime? feedingTime,
  }) {
    return FeedingEventModel(
      id: id,
      fishId: 'fish_1',
      aquariumId: 'aquarium_1',
      feedingTime: feedingTime ?? DateTime.now(),
      synced: false,
      createdAt: DateTime.now(),
    );
  }

  group('CalculateStreakUseCase', () {
    group('Validation', () {
      test('should return ValidationFailure when userId is empty', () async {
        final result = await useCase(const CalculateStreakParams(userId: ''));

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            final validationFailure = failure as ValidationFailure;
            expect(validationFailure.errors['userId'], isNotEmpty);
          },
          (_) => fail('Should be Left'),
        );
      });
    });

    group('Calculate Streak', () {
      test('should return existing streak when found', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final streak = createTestStreak(
          currentStreak: 5,
          longestStreak: 10,
          lastFeedingDate: today,
        );

        when(() => mockStreakDs.getStreakByUserId('user_1')).thenReturn(streak);
        when(() => mockStreakDs.isStreakActive('user_1')).thenReturn(true);
        when(() => mockStreakDs.saveStreak(any())).thenAnswer((_) async {});

        final result =
            await useCase(const CalculateStreakParams(userId: 'user_1'));

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (calcResult) {
            expect(calcResult.streak.currentStreak, 5);
            expect(calcResult.streak.longestStreak, 10);
            expect(calcResult.isActive, isTrue);
          },
        );
      });

      test('should create default streak when none exists', () async {
        when(() => mockStreakDs.getStreakByUserId('user_1')).thenReturn(null);
        when(() => mockStreakDs.saveStreak(any())).thenAnswer((_) async {});
        when(() => mockStreakDs.isStreakActive('user_1')).thenReturn(false);

        final result =
            await useCase(const CalculateStreakParams(userId: 'user_1'));

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (calcResult) {
            expect(calcResult.streak.currentStreak, 0);
            expect(calcResult.streak.longestStreak, 0);
            expect(calcResult.streak.userId, 'user_1');
            expect(calcResult.isActive, isFalse);
          },
        );

        verify(() => mockStreakDs.saveStreak(any())).called(1);
      });

      test('should return isActive true when fed today', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final streak = createTestStreak(lastFeedingDate: today);

        when(() => mockStreakDs.getStreakByUserId('user_1')).thenReturn(streak);
        when(() => mockStreakDs.isStreakActive('user_1')).thenReturn(true);
        when(() => mockStreakDs.saveStreak(any())).thenAnswer((_) async {});

        final result =
            await useCase(const CalculateStreakParams(userId: 'user_1'));

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (calcResult) {
            expect(calcResult.isActive, isTrue);
            expect(calcResult.daysUntilExpiry, 2);
          },
        );
      });

      test('should return isActive true when fed yesterday', () async {
        final now = DateTime.now();
        final yesterday = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 1));
        final streak = createTestStreak(lastFeedingDate: yesterday);

        when(() => mockStreakDs.getStreakByUserId('user_1')).thenReturn(streak);
        when(() => mockStreakDs.isStreakActive('user_1')).thenReturn(true);
        when(() => mockStreakDs.saveStreak(any())).thenAnswer((_) async {});

        final result =
            await useCase(const CalculateStreakParams(userId: 'user_1'));

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (calcResult) {
            expect(calcResult.isActive, isTrue);
            expect(calcResult.daysUntilExpiry, 1);
          },
        );
      });

      test('should reset streak when more than 1 day passed', () async {
        final now = DateTime.now();
        final twoDaysAgo = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 2));
        final streak = createTestStreak(
          currentStreak: 5,
          lastFeedingDate: twoDaysAgo,
        );

        when(() => mockStreakDs.getStreakByUserId('user_1')).thenReturn(streak);
        when(() => mockStreakDs.isStreakActive('user_1')).thenReturn(false);
        when(() => mockStreakDs.saveStreak(any())).thenAnswer((_) async {});

        final result =
            await useCase(const CalculateStreakParams(userId: 'user_1'));

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (calcResult) {
            expect(calcResult.streak.currentStreak, 0);
            expect(calcResult.isActive, isFalse);
            expect(calcResult.daysUntilExpiry, 0);
          },
        );

        verify(() => mockStreakDs.saveStreak(any())).called(1);
      });

      test('should return daysUntilExpiry as 0 when streak is broken', () async {
        final streak = createTestStreak(
          currentStreak: 0,
          lastFeedingDate: null,
        );

        when(() => mockStreakDs.getStreakByUserId('user_1')).thenReturn(streak);
        when(() => mockStreakDs.isStreakActive('user_1')).thenReturn(false);
        when(() => mockStreakDs.saveStreak(any())).thenAnswer((_) async {});

        final result =
            await useCase(const CalculateStreakParams(userId: 'user_1'));

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (calcResult) {
            expect(calcResult.daysUntilExpiry, 0);
          },
        );
      });
    });

    group('Recalculate from History', () {
      test('should return empty streak when no feeding events', () async {
        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn([]);
        when(() => mockStreakDs.saveStreak(any())).thenAnswer((_) async {});

        final result = await useCase.recalculateFromHistory('user_1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (streak) {
            expect(streak.currentStreak, 0);
            expect(streak.longestStreak, 0);
          },
        );
      });

      test('should calculate streak from consecutive feeding days', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final twoDaysAgo = today.subtract(const Duration(days: 2));

        final events = [
          createTestFeedingEvent(id: 'event_1', feedingTime: today),
          createTestFeedingEvent(id: 'event_2', feedingTime: yesterday),
          createTestFeedingEvent(id: 'event_3', feedingTime: twoDaysAgo),
        ];

        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn(events);
        when(() => mockStreakDs.getStreakByUserId('user_1')).thenReturn(null);
        when(() => mockStreakDs.saveStreak(any())).thenAnswer((_) async {});

        final result = await useCase.recalculateFromHistory('user_1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (streak) {
            expect(streak.currentStreak, 3);
          },
        );
      });

      test('should set streak to 0 when feeding is too old', () async {
        final now = DateTime.now();
        final fiveDaysAgo = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 5));

        final events = [
          createTestFeedingEvent(id: 'event_1', feedingTime: fiveDaysAgo),
        ];

        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn(events);
        when(() => mockStreakDs.getStreakByUserId('user_1')).thenReturn(null);
        when(() => mockStreakDs.saveStreak(any())).thenAnswer((_) async {});

        final result = await useCase.recalculateFromHistory('user_1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (streak) {
            expect(streak.currentStreak, 0);
          },
        );
      });

      test('should preserve longest streak when recalculating', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final events = [
          createTestFeedingEvent(id: 'event_1', feedingTime: today),
        ];

        final existingStreak = createTestStreak(
          currentStreak: 1,
          longestStreak: 15,
        );

        when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn(events);
        when(() => mockStreakDs.getStreakByUserId('user_1'))
            .thenReturn(existingStreak);
        when(() => mockStreakDs.saveStreak(any())).thenAnswer((_) async {});

        final result = await useCase.recalculateFromHistory('user_1');

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (streak) {
            expect(streak.longestStreak, 15);
          },
        );
      });
    });

    group('Error Handling', () {
      test('should return CacheFailure when datasource throws exception',
          () async {
        when(() => mockStreakDs.getStreakByUserId(any()))
            .thenThrow(Exception('Hive error'));

        final result =
            await useCase(const CalculateStreakParams(userId: 'user_1'));

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<CacheFailure>());
            expect(failure.message, contains('Failed to calculate streak'));
          },
          (_) => fail('Should be Left'),
        );
      });

      test('should return CacheFailure on recalculate error', () async {
        when(() => mockFeedingDs.getAllFeedingEvents())
            .thenThrow(Exception('Hive error'));

        final result = await useCase.recalculateFromHistory('user_1');

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<CacheFailure>());
            expect(failure.message, contains('Failed to recalculate streak'));
          },
          (_) => fail('Should be Left'),
        );
      });
    });
  });
}
