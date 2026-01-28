import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/achievement_model.dart';
import 'package:fishfeed/domain/entities/achievement.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_achievement_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await HiveBoxes.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AchievementModel', () {
    test('should create AchievementModel with required fields', () {
      final model = AchievementModel(
        id: 'achievement-123',
        userId: 'user-456',
        type: 'streak',
        title: 'First Streak',
      );

      expect(model.id, 'achievement-123');
      expect(model.userId, 'user-456');
      expect(model.type, 'streak');
      expect(model.title, 'First Streak');
      expect(model.description, isNull);
      expect(model.unlockedAt, isNull);
      expect(model.iconUrl, isNull);
      expect(model.progress, 0.0);
    });

    test('should create AchievementModel with all fields', () {
      final unlockedAt = DateTime.now();
      final model = AchievementModel(
        id: 'achievement-full',
        userId: 'user-full',
        type: 'species_master',
        title: 'Species Expert',
        description: 'Own 10 different species',
        unlockedAt: unlockedAt,
        iconUrl: 'https://example.com/icon.png',
        progress: 1.0,
      );

      expect(model.id, 'achievement-full');
      expect(model.type, 'species_master');
      expect(model.title, 'Species Expert');
      expect(model.description, 'Own 10 different species');
      expect(model.unlockedAt, unlockedAt);
      expect(model.iconUrl, 'https://example.com/icon.png');
      expect(model.progress, 1.0);
    });

    test('default progress should be zero', () {
      final model = AchievementModel(
        id: 'new-achievement',
        userId: 'user-new',
        type: 'first_feed',
        title: 'First Feeding',
      );

      expect(model.progress, 0.0);
    });
  });

  group('AchievementModel - entity conversion', () {
    test('toEntity should convert to Achievement entity', () {
      final unlockedAt = DateTime.now();
      final model = AchievementModel(
        id: 'achievement-123',
        userId: 'user-456',
        type: 'streak_7',
        title: 'Week Warrior',
        description: 'Maintain a 7-day streak',
        unlockedAt: unlockedAt,
        iconUrl: 'https://example.com/week.png',
        progress: 1.0,
      );

      final entity = model.toEntity();

      expect(entity, isA<Achievement>());
      expect(entity.id, 'achievement-123');
      expect(entity.userId, 'user-456');
      expect(entity.type, 'streak_7');
      expect(entity.title, 'Week Warrior');
      expect(entity.description, 'Maintain a 7-day streak');
      expect(entity.unlockedAt, unlockedAt);
      expect(entity.iconUrl, 'https://example.com/week.png');
      expect(entity.progress, 1.0);
    });

    test('fromEntity should create model from Achievement entity', () {
      final unlockedAt = DateTime.now();
      final entity = Achievement(
        id: 'entity-achievement',
        userId: 'entity-user',
        type: 'first_aquarium',
        title: 'New Aquarist',
        description: 'Create your first aquarium',
        unlockedAt: unlockedAt,
        iconUrl: 'https://example.com/first.png',
        progress: 1.0,
      );

      final model = AchievementModel.fromEntity(entity);

      expect(model.id, 'entity-achievement');
      expect(model.userId, 'entity-user');
      expect(model.type, 'first_aquarium');
      expect(model.title, 'New Aquarist');
      expect(model.description, 'Create your first aquarium');
      expect(model.unlockedAt, unlockedAt);
      expect(model.iconUrl, 'https://example.com/first.png');
      expect(model.progress, 1.0);
    });

    test('round-trip conversion should preserve data', () {
      final unlockedAt = DateTime.now();
      final originalEntity = Achievement(
        id: 'round-trip',
        userId: 'user-rt',
        type: 'streak_30',
        title: 'Monthly Master',
        description: 'Maintain a 30-day streak',
        unlockedAt: unlockedAt,
        iconUrl: 'https://example.com/month.png',
        progress: 1.0,
      );

      final model = AchievementModel.fromEntity(originalEntity);
      final resultEntity = model.toEntity();

      expect(resultEntity, equals(originalEntity));
    });

    test('round-trip should preserve partial progress', () {
      const originalEntity = Achievement(
        id: 'in-progress',
        userId: 'user-ip',
        type: 'streak_7',
        title: 'Week Warrior',
        progress: 0.5,
      );

      final model = AchievementModel.fromEntity(originalEntity);
      final resultEntity = model.toEntity();

      expect(resultEntity.progress, 0.5);
      expect(resultEntity.unlockedAt, isNull);
      expect(resultEntity.isUnlocked, false);
    });
  });

  group('Achievement - isUnlocked behavior', () {
    test('isUnlocked should return true when unlockedAt is set', () {
      final entity = Achievement(
        id: 'unlocked',
        userId: 'user-1',
        type: 'test',
        title: 'Test',
        unlockedAt: DateTime.now(),
        progress: 0.5,
      );

      expect(entity.isUnlocked, true);
    });

    test('isUnlocked should return true when progress is 1.0', () {
      const entity = Achievement(
        id: 'full-progress',
        userId: 'user-1',
        type: 'test',
        title: 'Test',
        progress: 1.0,
      );

      expect(entity.isUnlocked, true);
    });

    test('isUnlocked should return false when progress < 1.0 and no unlockedAt',
        () {
      const entity = Achievement(
        id: 'locked',
        userId: 'user-1',
        type: 'test',
        title: 'Test',
        progress: 0.9,
      );

      expect(entity.isUnlocked, false);
    });
  });

  group('AchievementModel - Hive persistence', () {
    setUp(() async {
      await HiveBoxes.initForTesting();
    });

    test('should save and retrieve AchievementModel from Hive', () async {
      final model = AchievementModel(
        id: 'persist-achievement',
        userId: 'persist-user',
        type: 'first_feed',
        title: 'First Feeding',
        description: 'Feed your fish for the first time',
        progress: 0.5,
      );

      await HiveBoxes.achievements.put(model.id, model);
      final retrieved =
          HiveBoxes.achievements.get(model.id) as AchievementModel;

      expect(retrieved.id, model.id);
      expect(retrieved.userId, model.userId);
      expect(retrieved.type, model.type);
      expect(retrieved.title, model.title);
      expect(retrieved.description, model.description);
      expect(retrieved.progress, model.progress);
    });

    test('should retrieve achievements by user', () async {
      final achievement1 = AchievementModel(
        id: 'ach-1',
        userId: 'user-1',
        type: 'streak',
        title: 'Streak 1',
      );

      final achievement2 = AchievementModel(
        id: 'ach-2',
        userId: 'user-1',
        type: 'feed',
        title: 'Feed 1',
      );

      final achievement3 = AchievementModel(
        id: 'ach-3',
        userId: 'user-2',
        type: 'streak',
        title: 'Streak 1',
      );

      await HiveBoxes.achievements.put(achievement1.id, achievement1);
      await HiveBoxes.achievements.put(achievement2.id, achievement2);
      await HiveBoxes.achievements.put(achievement3.id, achievement3);

      final allAchievements =
          HiveBoxes.achievements.values.cast<AchievementModel>().toList();
      final user1Achievements =
          allAchievements.where((a) => a.userId == 'user-1').toList();

      expect(allAchievements.length, 3);
      expect(user1Achievements.length, 2);
    });

    test('should update achievement progress', () async {
      final model = AchievementModel(
        id: 'progress-achievement',
        userId: 'progress-user',
        type: 'streak_10',
        title: '10 Day Streak',
        progress: 0.3,
      );

      await HiveBoxes.achievements.put(model.id, model);

      model.progress = 0.7;
      await HiveBoxes.achievements.put(model.id, model);

      final retrieved =
          HiveBoxes.achievements.get(model.id) as AchievementModel;
      expect(retrieved.progress, 0.7);
    });
  });

  group('AchievementModel - TypeAdapter', () {
    test('should have correct typeId', () {
      final adapter = AchievementModelAdapter();
      expect(adapter.typeId, 6);
    });
  });
}
