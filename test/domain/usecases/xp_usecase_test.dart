import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/constants/levels.dart';
import 'package:fishfeed/core/constants/xp_constants.dart';
import 'package:fishfeed/data/datasources/local/user_progress_local_ds.dart';
import 'package:fishfeed/data/models/user_progress_model.dart';
import 'package:fishfeed/domain/usecases/xp_usecase.dart';

class MockUserProgressLocalDataSource extends Mock
    implements UserProgressLocalDataSource {}

class MockBox extends Mock implements Box<dynamic> {}

class FakeUserProgressModel extends Fake implements UserProgressModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUserProgressModel());
  });

  late MockUserProgressLocalDataSource mockProgressDs;
  late XpUseCase useCase;

  setUp(() {
    mockProgressDs = MockUserProgressLocalDataSource();
    useCase = XpUseCase(progressDataSource: mockProgressDs);
  });

  UserProgressModel createTestProgress({
    String id = 'progress_user_1',
    String userId = 'user_1',
    int totalXp = 0,
    List<int> streakBonusesEarned = const [],
    DateTime? lastXpAwardedAt,
    DateTime? lastLevelUpAt,
  }) {
    return UserProgressModel(
      id: id,
      userId: userId,
      totalXp: totalXp,
      streakBonusesEarned: streakBonusesEarned,
      lastXpAwardedAt: lastXpAwardedAt,
      lastLevelUpAt: lastLevelUpAt,
    );
  }

  group('awardFeedingXp', () {
    test('should return validation error when userId is empty', () async {
      final result = await useCase.awardFeedingXp(userId: '', isOnTime: true);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) =>
            expect(failure.toString(), contains('User ID is required')),
        (_) => fail('Should return failure'),
      );
    });

    test('should award 10 XP for on-time feeding', () async {
      final beforeProgress = createTestProgress(totalXp: 50);
      final afterProgress = createTestProgress(totalXp: 60);

      when(
        () => mockProgressDs.getOrCreateProgress('user_1'),
      ).thenAnswer((_) async => beforeProgress);
      when(
        () => mockProgressDs.addXp('user_1', XpConstants.xpOnTimeFeeding),
      ).thenAnswer((_) async => afterProgress);

      final result = await useCase.awardFeedingXp(
        userId: 'user_1',
        isOnTime: true,
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (award) {
        expect(award.xpAwarded, XpConstants.xpOnTimeFeeding);
        expect(award.progress.totalXp, 60);
        expect(award.didLevelUp, isFalse);
      });
    });

    test('should award 5 XP for late feeding', () async {
      final beforeProgress = createTestProgress(totalXp: 50);
      final afterProgress = createTestProgress(totalXp: 55);

      when(
        () => mockProgressDs.getOrCreateProgress('user_1'),
      ).thenAnswer((_) async => beforeProgress);
      when(
        () => mockProgressDs.addXp('user_1', XpConstants.xpLateFeeding),
      ).thenAnswer((_) async => afterProgress);

      final result = await useCase.awardFeedingXp(
        userId: 'user_1',
        isOnTime: false,
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (award) {
        expect(award.xpAwarded, XpConstants.xpLateFeeding);
        expect(award.progress.totalXp, 55);
      });
    });

    test('should detect level up when crossing threshold', () async {
      // Before: 95 XP (beginnerAquarist)
      // After: 105 XP (caretaker)
      final beforeProgress = createTestProgress(totalXp: 95);
      final afterProgress = createTestProgress(totalXp: 105);

      when(
        () => mockProgressDs.getOrCreateProgress('user_1'),
      ).thenAnswer((_) async => beforeProgress);
      when(
        () => mockProgressDs.addXp('user_1', XpConstants.xpOnTimeFeeding),
      ).thenAnswer((_) async => afterProgress);
      when(
        () => mockProgressDs.recordLevelUp('user_1'),
      ).thenAnswer((_) async {});

      final result = await useCase.awardFeedingXp(
        userId: 'user_1',
        isOnTime: true,
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (award) {
        expect(award.didLevelUp, isTrue);
        expect(award.previousLevel, UserLevel.beginnerAquarist);
        expect(award.newLevel, UserLevel.caretaker);
      });

      verify(() => mockProgressDs.recordLevelUp('user_1')).called(1);
    });

    test('should not detect level up when staying in same level', () async {
      final beforeProgress = createTestProgress(totalXp: 50);
      final afterProgress = createTestProgress(totalXp: 60);

      when(
        () => mockProgressDs.getOrCreateProgress('user_1'),
      ).thenAnswer((_) async => beforeProgress);
      when(
        () => mockProgressDs.addXp('user_1', XpConstants.xpOnTimeFeeding),
      ).thenAnswer((_) async => afterProgress);

      final result = await useCase.awardFeedingXp(
        userId: 'user_1',
        isOnTime: true,
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (award) {
        expect(award.didLevelUp, isFalse);
        expect(award.previousLevel, isNull);
        expect(award.newLevel, isNull);
      });

      verifyNever(() => mockProgressDs.recordLevelUp(any()));
    });
  });

  group('checkStreakBonus', () {
    test('should return validation error when userId is empty', () async {
      final result = await useCase.checkStreakBonus(
        userId: '',
        currentStreak: 7,
      );

      expect(result.isLeft(), isTrue);
    });

    test('should award 7-day streak bonus', () async {
      // Use 150 XP so adding 50 bonus doesn't trigger level up
      final beforeProgress = createTestProgress(totalXp: 150);
      final afterProgress = createTestProgress(
        totalXp: 150 + XpConstants.streakBonus7Days,
        streakBonusesEarned: [7],
      );

      when(
        () => mockProgressDs.getOrCreateProgress('user_1'),
      ).thenAnswer((_) async => beforeProgress);
      when(
        () => mockProgressDs.hasEarnedStreakBonus('user_1', 7),
      ).thenReturn(false);
      when(
        () => mockProgressDs.recordStreakBonusEarned('user_1', 7),
      ).thenAnswer((_) async => true);
      when(
        () => mockProgressDs.addXp('user_1', XpConstants.streakBonus7Days),
      ).thenAnswer((_) async => afterProgress);

      final result = await useCase.checkStreakBonus(
        userId: 'user_1',
        currentStreak: 7,
      );

      result.fold(
        (failure) {
          fail('Should return success but got: $failure');
        },
        (bonus) {
          expect(bonus.bonusAwarded, XpConstants.streakBonus7Days);
          expect(bonus.milestone, 7);
          expect(bonus.didLevelUp, isFalse);
        },
      );
    });

    test('should award 30-day streak bonus', () async {
      final beforeProgress = createTestProgress(
        totalXp: 200,
        streakBonusesEarned: [7],
      );
      final afterProgress = createTestProgress(
        totalXp: 200 + XpConstants.streakBonus30Days,
        streakBonusesEarned: [7, 30],
      );

      when(
        () => mockProgressDs.getOrCreateProgress('user_1'),
      ).thenAnswer((_) async => beforeProgress);
      when(
        () => mockProgressDs.hasEarnedStreakBonus('user_1', 7),
      ).thenReturn(true);
      when(
        () => mockProgressDs.hasEarnedStreakBonus('user_1', 30),
      ).thenReturn(false);
      when(
        () => mockProgressDs.recordStreakBonusEarned('user_1', 30),
      ).thenAnswer((_) async => true);
      when(
        () => mockProgressDs.addXp('user_1', XpConstants.streakBonus30Days),
      ).thenAnswer((_) async => afterProgress);

      final result = await useCase.checkStreakBonus(
        userId: 'user_1',
        currentStreak: 30,
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (bonus) {
        expect(bonus.bonusAwarded, XpConstants.streakBonus30Days);
        expect(bonus.milestone, 30);
      });
    });

    test('should award 100-day streak bonus', () async {
      final beforeProgress = createTestProgress(
        totalXp: 500,
        streakBonusesEarned: [7, 30],
      );
      final afterProgress = createTestProgress(
        totalXp: 500 + XpConstants.streakBonus100Days,
        streakBonusesEarned: [7, 30, 100],
      );

      when(
        () => mockProgressDs.getOrCreateProgress('user_1'),
      ).thenAnswer((_) async => beforeProgress);
      when(
        () => mockProgressDs.hasEarnedStreakBonus('user_1', 7),
      ).thenReturn(true);
      when(
        () => mockProgressDs.hasEarnedStreakBonus('user_1', 30),
      ).thenReturn(true);
      when(
        () => mockProgressDs.hasEarnedStreakBonus('user_1', 100),
      ).thenReturn(false);
      when(
        () => mockProgressDs.recordStreakBonusEarned('user_1', 100),
      ).thenAnswer((_) async => true);
      when(
        () => mockProgressDs.addXp('user_1', XpConstants.streakBonus100Days),
      ).thenAnswer((_) async => afterProgress);

      final result = await useCase.checkStreakBonus(
        userId: 'user_1',
        currentStreak: 100,
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (bonus) {
        expect(bonus.bonusAwarded, XpConstants.streakBonus100Days);
        expect(bonus.milestone, 100);
      });
    });

    test('should not award already earned bonus', () async {
      final progress = createTestProgress(
        totalXp: 200,
        streakBonusesEarned: [7],
      );

      when(
        () => mockProgressDs.getOrCreateProgress('user_1'),
      ).thenAnswer((_) async => progress);
      when(
        () => mockProgressDs.hasEarnedStreakBonus('user_1', 7),
      ).thenReturn(true);

      final result = await useCase.checkStreakBonus(
        userId: 'user_1',
        currentStreak: 7,
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (bonus) {
        expect(bonus.bonusAwarded, 0);
        expect(bonus.milestone, isNull);
      });

      verifyNever(() => mockProgressDs.recordStreakBonusEarned(any(), any()));
      verifyNever(() => mockProgressDs.addXp(any(), any()));
    });

    test('should not award bonus when streak below milestone', () async {
      final progress = createTestProgress(totalXp: 50);

      when(
        () => mockProgressDs.getOrCreateProgress('user_1'),
      ).thenAnswer((_) async => progress);
      when(
        () => mockProgressDs.hasEarnedStreakBonus('user_1', any()),
      ).thenReturn(false);

      final result = await useCase.checkStreakBonus(
        userId: 'user_1',
        currentStreak: 5,
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (bonus) {
        expect(bonus.bonusAwarded, 0);
        expect(bonus.milestone, isNull);
      });
    });

    test('should trigger level up from streak bonus', () async {
      // Before: 450 XP (caretaker), after 50 bonus = 500 (fishMaster)
      final beforeProgress = createTestProgress(totalXp: 450);
      final afterProgress = createTestProgress(
        totalXp: 500,
        streakBonusesEarned: [7],
      );

      when(
        () => mockProgressDs.getOrCreateProgress('user_1'),
      ).thenAnswer((_) async => beforeProgress);
      when(
        () => mockProgressDs.hasEarnedStreakBonus('user_1', 7),
      ).thenReturn(false);
      when(
        () => mockProgressDs.recordStreakBonusEarned('user_1', 7),
      ).thenAnswer((_) async => true);
      when(
        () => mockProgressDs.addXp('user_1', XpConstants.streakBonus7Days),
      ).thenAnswer((_) async => afterProgress);
      when(
        () => mockProgressDs.recordLevelUp('user_1'),
      ).thenAnswer((_) async {});

      final result = await useCase.checkStreakBonus(
        userId: 'user_1',
        currentStreak: 7,
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (bonus) {
        expect(bonus.didLevelUp, isTrue);
        expect(bonus.previousLevel, UserLevel.caretaker);
        expect(bonus.newLevel, UserLevel.fishMaster);
      });
    });
  });

  group('getProgress', () {
    test('should return validation error when userId is empty', () async {
      final result = await useCase.getProgress('');

      expect(result.isLeft(), isTrue);
    });

    test('should return existing progress', () async {
      final progress = createTestProgress(totalXp: 250);

      when(
        () => mockProgressDs.getOrCreateProgress('user_1'),
      ).thenAnswer((_) async => progress);

      final result = await useCase.getProgress('user_1');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return success'), (p) {
        expect(p.totalXp, 250);
        expect(p.currentLevel, UserLevel.caretaker);
      });
    });
  });

  group('getLevelUpInfo', () {
    test('should detect level up when crossing threshold', () {
      final info = useCase.getLevelUpInfo(currentXp: 95, xpToAdd: 10);

      expect(info.wouldLevelUp, isTrue);
      expect(info.newLevel, UserLevel.caretaker);
    });

    test('should not detect level up when staying in level', () {
      final info = useCase.getLevelUpInfo(currentXp: 50, xpToAdd: 10);

      expect(info.wouldLevelUp, isFalse);
      expect(info.newLevel, isNull);
    });

    test('should handle max level correctly', () {
      final info = useCase.getLevelUpInfo(currentXp: 2500, xpToAdd: 100);

      expect(info.wouldLevelUp, isFalse);
      expect(info.newLevel, isNull);
    });
  });

  group('getEarnedStreakBonuses', () {
    test('should return earned bonuses from data source', () {
      when(
        () => mockProgressDs.getEarnedStreakBonuses('user_1'),
      ).thenReturn([7, 30]);

      final bonuses = useCase.getEarnedStreakBonuses('user_1');

      expect(bonuses, [7, 30]);
    });

    test('should return empty list when no bonuses earned', () {
      when(
        () => mockProgressDs.getEarnedStreakBonuses('user_1'),
      ).thenReturn([]);

      final bonuses = useCase.getEarnedStreakBonuses('user_1');

      expect(bonuses, isEmpty);
    });
  });

  group('getPendingStreakBonuses', () {
    test('should return pending bonus for 7-day streak', () {
      when(
        () => mockProgressDs.getEarnedStreakBonuses('user_1'),
      ).thenReturn([]);

      final pending = useCase.getPendingStreakBonuses(
        userId: 'user_1',
        currentStreak: 7,
      );

      expect(pending.length, 1);
      expect(pending[0].milestone, 7);
      expect(pending[0].xpAmount, XpConstants.streakBonus7Days);
    });

    test('should return multiple pending bonuses', () {
      when(
        () => mockProgressDs.getEarnedStreakBonuses('user_1'),
      ).thenReturn([]);

      final pending = useCase.getPendingStreakBonuses(
        userId: 'user_1',
        currentStreak: 100,
      );

      expect(pending.length, 3);
      expect(pending.map((p) => p.milestone), contains(7));
      expect(pending.map((p) => p.milestone), contains(30));
      expect(pending.map((p) => p.milestone), contains(100));
    });

    test('should exclude already earned bonuses', () {
      when(
        () => mockProgressDs.getEarnedStreakBonuses('user_1'),
      ).thenReturn([7, 30]);

      final pending = useCase.getPendingStreakBonuses(
        userId: 'user_1',
        currentStreak: 100,
      );

      expect(pending.length, 1);
      expect(pending[0].milestone, 100);
    });

    test('should return empty list when all bonuses earned', () {
      when(
        () => mockProgressDs.getEarnedStreakBonuses('user_1'),
      ).thenReturn([7, 30, 100]);

      final pending = useCase.getPendingStreakBonuses(
        userId: 'user_1',
        currentStreak: 100,
      );

      expect(pending, isEmpty);
    });
  });

  group('XP Constants', () {
    test('should have correct XP values', () {
      expect(XpConstants.xpOnTimeFeeding, 10);
      expect(XpConstants.xpLateFeeding, 5);
      expect(XpConstants.streakBonus7Days, 50);
      expect(XpConstants.streakBonus30Days, 200);
      expect(XpConstants.streakBonus100Days, 1000);
    });

    test('should have matching streak bonuses map', () {
      expect(XpConstants.streakBonuses[7], XpConstants.streakBonus7Days);
      expect(XpConstants.streakBonuses[30], XpConstants.streakBonus30Days);
      expect(XpConstants.streakBonuses[100], XpConstants.streakBonus100Days);
    });

    test('should have correct streak milestones', () {
      expect(XpConstants.streakMilestones, [7, 30, 100]);
    });
  });
}
