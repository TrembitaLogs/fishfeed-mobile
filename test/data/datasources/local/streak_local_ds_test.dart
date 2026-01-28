import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/data/models/streak_model.dart';
import 'package:fishfeed/domain/entities/streak.dart';

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  late MockBox mockStreaksBox;
  late StreakLocalDataSource streakDs;

  setUp(() {
    mockStreaksBox = MockBox();
    streakDs = StreakLocalDataSource(streaksBox: mockStreaksBox);
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

  group('CRUD Operations', () {
    group('saveStreak', () {
      test('should save streak to Hive box', () async {
        final streak = createTestStreak();
        when(() => mockStreaksBox.put(any<dynamic>(), any<dynamic>())).thenAnswer((_) async {});

        await streakDs.saveStreak(streak);

        verify(() => mockStreaksBox.put('streak_user_1', streak)).called(1);
      });
    });

    group('getStreakById', () {
      test('should return streak when exists', () {
        final streak = createTestStreak();
        when(() => mockStreaksBox.get('streak_user_1')).thenReturn(streak);

        final result = streakDs.getStreakById('streak_user_1');

        expect(result, streak);
        expect(result?.id, 'streak_user_1');
      });

      test('should return null when streak does not exist', () {
        when(() => mockStreaksBox.get('streak_user_1')).thenReturn(null);

        final result = streakDs.getStreakById('streak_user_1');

        expect(result, isNull);
      });

      test('should return null when stored value is not StreakModel', () {
        when(() => mockStreaksBox.get('streak_user_1')).thenReturn('invalid');

        final result = streakDs.getStreakById('streak_user_1');

        expect(result, isNull);
      });
    });

    group('getStreakByUserId', () {
      test('should return streak for specific user', () {
        final streak1 = createTestStreak(id: 'streak_user_1', userId: 'user_1');
        final streak2 = createTestStreak(id: 'streak_user_2', userId: 'user_2');

        when(() => mockStreaksBox.values).thenReturn([streak1, streak2]);

        final result = streakDs.getStreakByUserId('user_1');

        expect(result, streak1);
        expect(result?.userId, 'user_1');
      });

      test('should return null when no streak for user', () {
        final streak = createTestStreak(userId: 'user_2');

        when(() => mockStreaksBox.values).thenReturn([streak]);

        final result = streakDs.getStreakByUserId('user_1');

        expect(result, isNull);
      });

      test('should return null when box is empty', () {
        when(() => mockStreaksBox.values).thenReturn([]);

        final result = streakDs.getStreakByUserId('user_1');

        expect(result, isNull);
      });
    });

    group('deleteStreak', () {
      test('should delete streak when exists', () async {
        final streak = createTestStreak();
        when(() => mockStreaksBox.get('streak_user_1')).thenReturn(streak);
        when(() => mockStreaksBox.delete(any<dynamic>())).thenAnswer((_) async {});

        final result = await streakDs.deleteStreak('streak_user_1');

        expect(result, isTrue);
        verify(() => mockStreaksBox.delete('streak_user_1')).called(1);
      });

      test('should return false when streak does not exist', () async {
        when(() => mockStreaksBox.get('streak_user_1')).thenReturn(null);

        final result = await streakDs.deleteStreak('streak_user_1');

        expect(result, isFalse);
        verifyNever(() => mockStreaksBox.delete(any<dynamic>()));
      });
    });

    group('getAllStreaks', () {
      test('should return all streaks sorted by current streak', () {
        final streak1 =
            createTestStreak(id: 'streak_1', userId: 'user_1', currentStreak: 5);
        final streak2 = createTestStreak(
            id: 'streak_2', userId: 'user_2', currentStreak: 10);
        final streak3 =
            createTestStreak(id: 'streak_3', userId: 'user_3', currentStreak: 3);

        when(() => mockStreaksBox.values)
            .thenReturn([streak1, streak2, streak3]);

        final result = streakDs.getAllStreaks();

        expect(result.length, 3);
        expect(result[0].currentStreak, 10);
        expect(result[1].currentStreak, 5);
        expect(result[2].currentStreak, 3);
      });

      test('should return empty list when no streaks', () {
        when(() => mockStreaksBox.values).thenReturn([]);

        final result = streakDs.getAllStreaks();

        expect(result, isEmpty);
      });
    });
  });

  group('Streak Update Operations', () {
    group('incrementStreak', () {
      test('should create new streak when none exists', () async {
        final feedingDate = DateTime(2025, 6, 15);

        when(() => mockStreaksBox.values).thenReturn([]);
        when(() => mockStreaksBox.put(any<dynamic>(), any<dynamic>())).thenAnswer((_) async {});

        final result = await streakDs.incrementStreak('user_1', feedingDate);

        expect(result.currentStreak, 1);
        expect(result.longestStreak, 1);
        expect(result.userId, 'user_1');
        verify(() => mockStreaksBox.put(any<dynamic>(), any<dynamic>())).called(1);
      });

      test('should increment streak when feeding consecutive day', () async {
        final yesterday = DateTime(2025, 6, 14);
        final today = DateTime(2025, 6, 15);
        final streak = createTestStreak(
          currentStreak: 5,
          longestStreak: 10,
          lastFeedingDate: yesterday,
        );

        when(() => mockStreaksBox.values).thenReturn([streak]);
        when(() => mockStreaksBox.put(any<dynamic>(), any<dynamic>())).thenAnswer((_) async {});

        final result = await streakDs.incrementStreak('user_1', today);

        expect(result.currentStreak, 6);
        expect(result.longestStreak, 10);
      });

      test('should update longest streak when current exceeds it', () async {
        final yesterday = DateTime(2025, 6, 14);
        final today = DateTime(2025, 6, 15);
        final streak = createTestStreak(
          currentStreak: 10,
          longestStreak: 10,
          lastFeedingDate: yesterday,
        );

        when(() => mockStreaksBox.values).thenReturn([streak]);
        when(() => mockStreaksBox.put(any<dynamic>(), any<dynamic>())).thenAnswer((_) async {});

        final result = await streakDs.incrementStreak('user_1', today);

        expect(result.currentStreak, 11);
        expect(result.longestStreak, 11);
      });

      test('should not change streak when feeding same day', () async {
        final today = DateTime(2025, 6, 15);
        final streak = createTestStreak(
          currentStreak: 5,
          lastFeedingDate: today,
        );

        when(() => mockStreaksBox.values).thenReturn([streak]);

        final result = await streakDs.incrementStreak('user_1', today);

        expect(result.currentStreak, 5);
        verifyNever(() => mockStreaksBox.put(any<dynamic>(), any<dynamic>()));
      });

      test('should reset streak to 1 when gap in feeding', () async {
        final oldDate = DateTime(2025, 6, 10);
        final today = DateTime(2025, 6, 15);
        final streak = createTestStreak(
          currentStreak: 5,
          lastFeedingDate: oldDate,
        );

        when(() => mockStreaksBox.values).thenReturn([streak]);
        when(() => mockStreaksBox.put(any<dynamic>(), any<dynamic>())).thenAnswer((_) async {});

        final result = await streakDs.incrementStreak('user_1', today);

        expect(result.currentStreak, 1);
        expect(result.streakStartDate, DateTime(2025, 6, 15));
      });
    });

    group('resetStreak', () {
      test('should reset streak to 0', () async {
        final streak = createTestStreak(currentStreak: 5);

        when(() => mockStreaksBox.values).thenReturn([streak]);
        when(() => mockStreaksBox.put(any<dynamic>(), any<dynamic>())).thenAnswer((_) async {});

        final result = await streakDs.resetStreak('user_1');

        expect(result?.currentStreak, 0);
        expect(result?.streakStartDate, isNull);
      });

      test('should return null when no streak exists', () async {
        when(() => mockStreaksBox.values).thenReturn([]);

        final result = await streakDs.resetStreak('user_1');

        expect(result, isNull);
      });
    });
  });

  group('Query Operations', () {
    group('getCurrentStreakCount', () {
      test('should return current streak count', () {
        final streak = createTestStreak(currentStreak: 7);

        when(() => mockStreaksBox.values).thenReturn([streak]);

        final result = streakDs.getCurrentStreakCount('user_1');

        expect(result, 7);
      });

      test('should return 0 when no streak exists', () {
        when(() => mockStreaksBox.values).thenReturn([]);

        final result = streakDs.getCurrentStreakCount('user_1');

        expect(result, 0);
      });
    });

    group('getLongestStreakCount', () {
      test('should return longest streak count', () {
        final streak = createTestStreak(longestStreak: 15);

        when(() => mockStreaksBox.values).thenReturn([streak]);

        final result = streakDs.getLongestStreakCount('user_1');

        expect(result, 15);
      });

      test('should return 0 when no streak exists', () {
        when(() => mockStreaksBox.values).thenReturn([]);

        final result = streakDs.getLongestStreakCount('user_1');

        expect(result, 0);
      });
    });

    group('isStreakActive', () {
      test('should return true when fed today', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final streak = createTestStreak(lastFeedingDate: today);

        when(() => mockStreaksBox.values).thenReturn([streak]);

        final result = streakDs.isStreakActive('user_1');

        expect(result, isTrue);
      });

      test('should return true when fed yesterday', () {
        final now = DateTime.now();
        final yesterday = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 1));
        final streak = createTestStreak(lastFeedingDate: yesterday);

        when(() => mockStreaksBox.values).thenReturn([streak]);

        final result = streakDs.isStreakActive('user_1');

        expect(result, isTrue);
      });

      test('should return false when no feeding for more than 1 day', () {
        final now = DateTime.now();
        final twoDaysAgo = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 2));
        final streak = createTestStreak(lastFeedingDate: twoDaysAgo);

        when(() => mockStreaksBox.values).thenReturn([streak]);

        final result = streakDs.isStreakActive('user_1');

        expect(result, isFalse);
      });

      test('should return false when no streak exists', () {
        when(() => mockStreaksBox.values).thenReturn([]);

        final result = streakDs.isStreakActive('user_1');

        expect(result, isFalse);
      });

      test('should return false when lastFeedingDate is null', () {
        final streak = StreakModel(
          id: 'streak_user_1',
          userId: 'user_1',
          currentStreak: 0,
          longestStreak: 0,
        );

        when(() => mockStreaksBox.values).thenReturn([streak]);

        final result = streakDs.isStreakActive('user_1');

        expect(result, isFalse);
      });
    });

    group('shouldIncrementStreak', () {
      test('should return true when all feedings completed', () {
        final result = streakDs.shouldIncrementStreak(
          'user_1',
          DateTime.now(),
          3,
          3,
        );

        expect(result, isTrue);
      });

      test('should return false when not all feedings completed', () {
        final result = streakDs.shouldIncrementStreak(
          'user_1',
          DateTime.now(),
          3,
          2,
        );

        expect(result, isFalse);
      });

      test('should return false when no scheduled feedings', () {
        final result = streakDs.shouldIncrementStreak(
          'user_1',
          DateTime.now(),
          0,
          0,
        );

        expect(result, isFalse);
      });
    });
  });

  group('Utility Operations', () {
    group('clearAll', () {
      test('should clear all streaks from box', () async {
        when(() => mockStreaksBox.clear()).thenAnswer((_) async => 0);

        await streakDs.clearAll();

        verify(() => mockStreaksBox.clear()).called(1);
      });
    });
  });

  group('StreakLocalDataSource constructor', () {
    test('should create instance with injected box', () {
      final ds = StreakLocalDataSource(streaksBox: mockStreaksBox);
      expect(ds, isA<StreakLocalDataSource>());
    });
  });

  group('Freeze Day Operations', () {
    group('useFreeze', () {
      test('should use freeze day and preserve streak', () async {
        final freezeDate = DateTime(2025, 6, 16);
        final streak = createTestStreak(
          currentStreak: 5,
          freezeAvailable: 2,
          frozenDays: [],
        );

        when(() => mockStreaksBox.values).thenReturn([streak]);
        when(() => mockStreaksBox.put(any<dynamic>(), any<dynamic>())).thenAnswer((_) async {});

        final result = await streakDs.useFreeze('user_1', freezeDate);

        expect(result, isNotNull);
        expect(result!.freezeAvailable, 1);
        expect(result.frozenDays.length, 1);
        expect(result.frozenDays.first, DateTime(2025, 6, 16));
      });

      test('should return null when no freeze available', () async {
        final freezeDate = DateTime(2025, 6, 16);
        final streak = createTestStreak(
          currentStreak: 5,
          freezeAvailable: 0,
        );

        when(() => mockStreaksBox.values).thenReturn([streak]);

        final result = await streakDs.useFreeze('user_1', freezeDate);

        expect(result, isNull);
        verifyNever(() => mockStreaksBox.put(any<dynamic>(), any<dynamic>()));
      });

      test('should not duplicate freeze for same date', () async {
        final freezeDate = DateTime(2025, 6, 16);
        final streak = createTestStreak(
          currentStreak: 5,
          freezeAvailable: 2,
          frozenDays: [DateTime(2025, 6, 16)],
        );

        when(() => mockStreaksBox.values).thenReturn([streak]);

        final result = await streakDs.useFreeze('user_1', freezeDate);

        expect(result, isNotNull);
        expect(result!.freezeAvailable, 2);
        expect(result.frozenDays.length, 1);
        verifyNever(() => mockStreaksBox.put(any<dynamic>(), any<dynamic>()));
      });

      test('should return null when no streak exists', () async {
        final freezeDate = DateTime(2025, 6, 16);

        when(() => mockStreaksBox.values).thenReturn([]);

        final result = await streakDs.useFreeze('user_1', freezeDate);

        expect(result, isNull);
      });
    });

    group('handleMissedDay', () {
      test('should use freeze when available and streak active', () async {
        final missedDate = DateTime(2025, 6, 16);
        final streak = createTestStreak(
          currentStreak: 5,
          freezeAvailable: 2,
          frozenDays: [],
        );

        when(() => mockStreaksBox.values).thenReturn([streak]);
        when(() => mockStreaksBox.put(any<dynamic>(), any<dynamic>())).thenAnswer((_) async {});

        final result = await streakDs.handleMissedDay('user_1', missedDate);

        expect(result.currentStreak, 5);
        expect(result.freezeAvailable, 1);
        expect(result.frozenDays.length, 1);
      });

      test('should reset streak when no freeze available', () async {
        final missedDate = DateTime(2025, 6, 16);
        final streak = createTestStreak(
          currentStreak: 5,
          freezeAvailable: 0,
        );

        when(() => mockStreaksBox.values).thenReturn([streak]);
        when(() => mockStreaksBox.put(any<dynamic>(), any<dynamic>())).thenAnswer((_) async {});

        final result = await streakDs.handleMissedDay('user_1', missedDate);

        expect(result.currentStreak, 0);
        expect(result.streakStartDate, isNull);
      });

      test('should create new streak when none exists', () async {
        final missedDate = DateTime(2025, 6, 16);

        when(() => mockStreaksBox.values).thenReturn([]);
        when(() => mockStreaksBox.put(any<dynamic>(), any<dynamic>())).thenAnswer((_) async {});

        final result = await streakDs.handleMissedDay('user_1', missedDate);

        expect(result.currentStreak, 0);
        expect(result.freezeAvailable, kDefaultFreezePerMonth);
      });

      test('should not change streak when already at 0', () async {
        final missedDate = DateTime(2025, 6, 16);
        final streak = createTestStreak(
          currentStreak: 0,
          freezeAvailable: 2,
        );

        when(() => mockStreaksBox.values).thenReturn([streak]);

        final result = await streakDs.handleMissedDay('user_1', missedDate);

        expect(result.currentStreak, 0);
        expect(result.freezeAvailable, 2);
        verifyNever(() => mockStreaksBox.put(any<dynamic>(), any<dynamic>()));
      });
    });

    group('resetMonthlyFreeze', () {
      test('should reset freeze to default value', () async {
        final streak = createTestStreak(
          freezeAvailable: 0,
          frozenDays: [DateTime(2025, 5, 15), DateTime(2025, 5, 20)],
          lastFreezeResetDate: DateTime(2025, 5, 1),
        );

        when(() => mockStreaksBox.values).thenReturn([streak]);
        when(() => mockStreaksBox.put(any<dynamic>(), any<dynamic>())).thenAnswer((_) async {});

        final result = await streakDs.resetMonthlyFreeze('user_1');

        expect(result, isNotNull);
        expect(result!.freezeAvailable, kDefaultFreezePerMonth);
        expect(result.frozenDays, isEmpty);
        expect(result.lastFreezeResetDate, isNotNull);
      });

      test('should return null when no streak exists', () async {
        when(() => mockStreaksBox.values).thenReturn([]);

        final result = await streakDs.resetMonthlyFreeze('user_1');

        expect(result, isNull);
      });
    });

    group('needsMonthlyFreezeReset', () {
      test('should return true when lastFreezeResetDate is null', () {
        final streak = createTestStreak(
          lastFreezeResetDate: null,
        );

        when(() => mockStreaksBox.values).thenReturn([streak]);

        final result = streakDs.needsMonthlyFreezeReset('user_1');

        expect(result, isTrue);
      });

      test('should return true when last reset was in previous month', () {
        final now = DateTime.now();
        final previousMonth = DateTime(now.year, now.month - 1, 1);
        final streak = createTestStreak(
          lastFreezeResetDate: previousMonth,
        );

        when(() => mockStreaksBox.values).thenReturn([streak]);

        final result = streakDs.needsMonthlyFreezeReset('user_1');

        expect(result, isTrue);
      });

      test('should return false when last reset was in current month', () {
        final now = DateTime.now();
        final currentMonth = DateTime(now.year, now.month, 1);
        final streak = createTestStreak(
          lastFreezeResetDate: currentMonth,
        );

        when(() => mockStreaksBox.values).thenReturn([streak]);

        final result = streakDs.needsMonthlyFreezeReset('user_1');

        expect(result, isFalse);
      });

      test('should return false when no streak exists', () {
        when(() => mockStreaksBox.values).thenReturn([]);

        final result = streakDs.needsMonthlyFreezeReset('user_1');

        expect(result, isFalse);
      });
    });

    group('checkAndResetMonthlyFreeze', () {
      test('should reset freeze when needed', () async {
        final now = DateTime.now();
        final previousMonth = DateTime(now.year, now.month - 1, 1);
        final streak = createTestStreak(
          freezeAvailable: 0,
          lastFreezeResetDate: previousMonth,
        );

        when(() => mockStreaksBox.values).thenReturn([streak]);
        when(() => mockStreaksBox.put(any<dynamic>(), any<dynamic>())).thenAnswer((_) async {});

        final result = await streakDs.checkAndResetMonthlyFreeze('user_1');

        expect(result, isNotNull);
        expect(result!.freezeAvailable, kDefaultFreezePerMonth);
      });

      test('should not reset freeze when not needed', () async {
        final now = DateTime.now();
        final currentMonth = DateTime(now.year, now.month, 1);
        final streak = createTestStreak(
          freezeAvailable: 1,
          lastFreezeResetDate: currentMonth,
        );

        when(() => mockStreaksBox.values).thenReturn([streak]);

        final result = await streakDs.checkAndResetMonthlyFreeze('user_1');

        expect(result, isNotNull);
        expect(result!.freezeAvailable, 1);
        verifyNever(() => mockStreaksBox.put(any<dynamic>(), any<dynamic>()));
      });
    });
  });
}
