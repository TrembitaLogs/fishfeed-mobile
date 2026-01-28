import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/constants/achievements.dart';
import 'package:fishfeed/data/datasources/local/achievement_local_ds.dart';
import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/data/datasources/local/user_progress_local_ds.dart';
import 'package:fishfeed/data/models/achievement_model.dart';
import 'package:fishfeed/data/models/feeding_event_model.dart';
import 'package:fishfeed/data/models/streak_model.dart';
import 'package:fishfeed/data/models/user_progress_model.dart';
import 'package:fishfeed/domain/usecases/achievement_usecase.dart';

class MockAchievementLocalDataSource extends Mock
    implements AchievementLocalDataSource {}

class MockFeedingLocalDataSource extends Mock
    implements FeedingLocalDataSource {}

class MockStreakLocalDataSource extends Mock implements StreakLocalDataSource {}

class MockUserProgressLocalDataSource extends Mock
    implements UserProgressLocalDataSource {}

class MockBox extends Mock implements Box<dynamic> {}

class FakeAchievementModel extends Fake implements AchievementModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAchievementModel());
    registerFallbackValue(AchievementType.firstFeeding);
  });

  late MockAchievementLocalDataSource mockAchievementDs;
  late MockFeedingLocalDataSource mockFeedingDs;
  late MockStreakLocalDataSource mockStreakDs;
  late MockUserProgressLocalDataSource mockProgressDs;
  late AchievementUseCase useCase;

  setUp(() {
    mockAchievementDs = MockAchievementLocalDataSource();
    mockFeedingDs = MockFeedingLocalDataSource();
    mockStreakDs = MockStreakLocalDataSource();
    mockProgressDs = MockUserProgressLocalDataSource();

    useCase = AchievementUseCase(
      achievementDataSource: mockAchievementDs,
      feedingDataSource: mockFeedingDs,
      streakDataSource: mockStreakDs,
      progressDataSource: mockProgressDs,
    );
  });

  AchievementModel createTestAchievement({
    required AchievementType type,
    String userId = 'user_1',
    DateTime? unlockedAt,
    double progress = 0.0,
  }) {
    final data = type.data;
    return AchievementModel(
      id: 'achievement_${userId}_${type.name}',
      userId: userId,
      type: type.name,
      title: data.titleUk,
      description: data.descriptionUk,
      unlockedAt: unlockedAt,
      progress: progress,
    );
  }

  StreakModel createTestStreak({
    String id = 'streak_user_1',
    String userId = 'user_1',
    int currentStreak = 0,
    int longestStreak = 0,
  }) {
    return StreakModel(
      id: id,
      userId: userId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }

  FeedingEventModel createTestFeedingEvent({
    required String id,
    String fishId = 'fish_1',
    String aquariumId = 'aq1',
    DateTime? feedingTime,
  }) {
    return FeedingEventModel(
      id: id,
      fishId: fishId,
      aquariumId: aquariumId,
      feedingTime: feedingTime ?? DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  UserProgressModel createTestProgress({
    String userId = 'user_1',
    int totalXp = 0,
  }) {
    return UserProgressModel(
      id: 'progress_$userId',
      userId: userId,
      totalXp: totalXp,
    );
  }

  group('checkAchievements', () {
    test('should return validation error when userId is empty', () async {
      final result = await useCase.checkAchievements('');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) =>
            expect(failure.toString(), contains('User ID is required')),
        (_) => fail('Should return failure'),
      );
    });

    test('should unlock firstFeeding when user has 1 feeding', () async {
      // Arrange
      when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn([
        createTestFeedingEvent(id: 'feed_1'),
      ]);
      when(() => mockStreakDs.getStreakByUserId('user_1')).thenReturn(null);

      // All achievements initially locked
      for (final type in AchievementType.values) {
        when(() => mockAchievementDs.isAchievementUnlocked('user_1', type))
            .thenReturn(false);
      }

      // Unlock firstFeeding
      when(() => mockAchievementDs.unlockAchievement(
            'user_1',
            AchievementType.firstFeeding,
          )).thenAnswer((_) async =>
          createTestAchievement(
            type: AchievementType.firstFeeding,
            unlockedAt: DateTime.now(),
            progress: 1.0,
          ));

      // Update progress for other achievements
      when(() => mockAchievementDs.updateProgress(
            any(),
            any(),
            any(),
          )).thenAnswer((_) async => createTestAchievement(
            type: AchievementType.streak7,
          ));

      when(() => mockProgressDs.addXp(any(), any()))
          .thenAnswer((_) async => createTestProgress());

      // Act
      final result = await useCase.checkAchievements('user_1');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should return success'),
        (checkResult) {
          expect(checkResult.hasUnlocked, isTrue);
          expect(checkResult.newlyUnlocked.length, 1);
          expect(
            checkResult.newlyUnlocked.first.achievementType,
            AchievementType.firstFeeding,
          );
          expect(checkResult.totalXpAwarded, AchievementType.firstFeeding.xpReward);
        },
      );
    });

    test('should unlock streak7 when streak reaches 7 days', () async {
      // Arrange
      when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn([]);
      when(() => mockStreakDs.getStreakByUserId('user_1'))
          .thenReturn(createTestStreak(currentStreak: 7));

      for (final type in AchievementType.values) {
        when(() => mockAchievementDs.isAchievementUnlocked('user_1', type))
            .thenReturn(false);
      }

      when(() => mockAchievementDs.unlockAchievement(
            'user_1',
            AchievementType.streak7,
          )).thenAnswer((_) async =>
          createTestAchievement(
            type: AchievementType.streak7,
            unlockedAt: DateTime.now(),
            progress: 1.0,
          ));

      when(() => mockAchievementDs.unlockAchievement(
            'user_1',
            AchievementType.weekWithoutMiss,
          )).thenAnswer((_) async =>
          createTestAchievement(
            type: AchievementType.weekWithoutMiss,
            unlockedAt: DateTime.now(),
            progress: 1.0,
          ));

      when(() => mockAchievementDs.updateProgress(any(), any(), any()))
          .thenAnswer(
              (_) async => createTestAchievement(type: AchievementType.streak30));

      when(() => mockProgressDs.addXp(any(), any()))
          .thenAnswer((_) async => createTestProgress());

      // Act
      final result = await useCase.checkAchievements('user_1');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should return success'),
        (checkResult) {
          expect(checkResult.hasUnlocked, isTrue);
          final unlockedTypes =
              checkResult.newlyUnlocked.map((a) => a.achievementType).toList();
          expect(unlockedTypes, contains(AchievementType.streak7));
        },
      );
    });

    test('should not unlock achievement that is already unlocked', () async {
      // Arrange
      when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn([
        createTestFeedingEvent(id: 'feed_1'),
      ]);
      when(() => mockStreakDs.getStreakByUserId('user_1')).thenReturn(null);

      // firstFeeding is already unlocked
      when(() =>
              mockAchievementDs.isAchievementUnlocked('user_1', AchievementType.firstFeeding))
          .thenReturn(true);

      // Other achievements are locked
      for (final type in AchievementType.values) {
        if (type != AchievementType.firstFeeding) {
          when(() => mockAchievementDs.isAchievementUnlocked('user_1', type))
              .thenReturn(false);
        }
      }

      when(() => mockAchievementDs.updateProgress(any(), any(), any()))
          .thenAnswer(
              (_) async => createTestAchievement(type: AchievementType.streak7));

      // Act
      final result = await useCase.checkAchievements('user_1');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should return success'),
        (checkResult) {
          // firstFeeding should NOT be in newly unlocked
          final unlockedTypes =
              checkResult.newlyUnlocked.map((a) => a.achievementType).toList();
          expect(unlockedTypes, isNot(contains(AchievementType.firstFeeding)));
        },
      );

      // Verify unlockAchievement was never called for firstFeeding
      verifyNever(
          () => mockAchievementDs.unlockAchievement('user_1', AchievementType.firstFeeding));
    });

    test('should unlock feedings100 when user has 100 feedings', () async {
      // Arrange
      final feedings = List.generate(
        100,
        (i) => createTestFeedingEvent(id: 'feed_$i'),
      );
      when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn(feedings);
      when(() => mockStreakDs.getStreakByUserId('user_1')).thenReturn(null);

      for (final type in AchievementType.values) {
        when(() => mockAchievementDs.isAchievementUnlocked('user_1', type))
            .thenReturn(false);
      }

      when(() => mockAchievementDs.unlockAchievement('user_1', any()))
          .thenAnswer((invocation) async {
        final type = invocation.positionalArguments[1] as AchievementType;
        return createTestAchievement(
          type: type,
          unlockedAt: DateTime.now(),
          progress: 1.0,
        );
      });

      when(() => mockAchievementDs.updateProgress(any(), any(), any()))
          .thenAnswer(
              (_) async => createTestAchievement(type: AchievementType.streak7));

      when(() => mockProgressDs.addXp(any(), any()))
          .thenAnswer((_) async => createTestProgress());

      // Act
      final result = await useCase.checkAchievements('user_1');

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should return success'),
        (checkResult) {
          final unlockedTypes =
              checkResult.newlyUnlocked.map((a) => a.achievementType).toList();
          expect(unlockedTypes, contains(AchievementType.feedings100));
          expect(unlockedTypes, contains(AchievementType.firstFeeding));
        },
      );
    });
  });

  group('getProgress', () {
    test('should return validation error when userId is empty', () async {
      final result =
          await useCase.getProgress('', AchievementType.firstFeeding);

      expect(result.isLeft(), isTrue);
    });

    test('should return stored progress if achievement exists', () async {
      when(() => mockAchievementDs.getAchievementByType(
            'user_1',
            AchievementType.streak7,
          )).thenReturn(createTestAchievement(
        type: AchievementType.streak7,
        progress: 0.5,
      ));

      final result =
          await useCase.getProgress('user_1', AchievementType.streak7);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should return success'),
        (progress) {
          expect(progress, 0.5);
        },
      );
    });

    test('should calculate progress if achievement does not exist', () async {
      when(() => mockAchievementDs.getAchievementByType(
            'user_1',
            AchievementType.streak7,
          )).thenReturn(null);

      when(() => mockFeedingDs.getAllFeedingEvents()).thenReturn([]);
      when(() => mockStreakDs.getStreakByUserId('user_1'))
          .thenReturn(createTestStreak(currentStreak: 3));

      final result =
          await useCase.getProgress('user_1', AchievementType.streak7);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should return success'),
        (progress) {
          // 3 out of 7 days = ~0.43
          expect(progress, closeTo(3 / 7, 0.01));
        },
      );
    });
  });

  group('getAllAchievements', () {
    test('should return validation error when userId is empty', () async {
      final result = await useCase.getAllAchievements('');

      expect(result.isLeft(), isTrue);
    });

    test('should return all achievements in order', () async {
      final achievements = AchievementConstants.orderedAchievements
          .map((type) => createTestAchievement(type: type).toEntity())
          .toList();

      when(() => mockAchievementDs.getAllAchievementsOrdered('user_1'))
          .thenAnswer((_) async => achievements);

      final result = await useCase.getAllAchievements('user_1');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should return success'),
        (list) {
          expect(list.length, AchievementType.values.length);
        },
      );
    });
  });

  group('getUnlockedAchievements', () {
    test('should return only unlocked achievements', () async {
      final unlockedAchievements = [
        createTestAchievement(
          type: AchievementType.firstFeeding,
          unlockedAt: DateTime.now(),
        ),
        createTestAchievement(
          type: AchievementType.streak7,
          unlockedAt: DateTime.now(),
        ),
      ];

      when(() => mockAchievementDs.getUnlockedAchievements('user_1'))
          .thenReturn(unlockedAchievements);

      final result = await useCase.getUnlockedAchievements('user_1');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should return success'),
        (list) {
          expect(list.length, 2);
          expect(list.every((a) => a.isUnlocked), isTrue);
        },
      );
    });
  });

  group('counts', () {
    test('getUnlockedCount should return correct count', () {
      final unlockedAchievements = [
        createTestAchievement(
          type: AchievementType.firstFeeding,
          unlockedAt: DateTime.now(),
        ),
      ];

      when(() => mockAchievementDs.getUnlockedAchievements('user_1'))
          .thenReturn(unlockedAchievements);

      final count = useCase.getUnlockedCount('user_1');

      expect(count, 1);
    });

    test('getTotalCount should return total number of achievement types', () {
      final count = useCase.getTotalCount();

      expect(count, AchievementType.values.length);
    });
  });
}
