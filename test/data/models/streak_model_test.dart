import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/streak_model.dart';
import 'package:fishfeed/domain/entities/streak.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_streak_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await HiveBoxes.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('StreakModel', () {
    test('should create StreakModel with required fields', () {
      final model = StreakModel(
        id: 'streak-123',
        userId: 'user-456',
      );

      expect(model.id, 'streak-123');
      expect(model.userId, 'user-456');
      expect(model.currentStreak, 0);
      expect(model.longestStreak, 0);
      expect(model.lastFeedingDate, isNull);
      expect(model.streakStartDate, isNull);
    });

    test('should create StreakModel with all fields', () {
      final lastFeeding = DateTime.now();
      final streakStart = DateTime.now().subtract(const Duration(days: 5));
      final model = StreakModel(
        id: 'streak-full',
        userId: 'user-full',
        currentStreak: 5,
        longestStreak: 10,
        lastFeedingDate: lastFeeding,
        streakStartDate: streakStart,
      );

      expect(model.id, 'streak-full');
      expect(model.userId, 'user-full');
      expect(model.currentStreak, 5);
      expect(model.longestStreak, 10);
      expect(model.lastFeedingDate, lastFeeding);
      expect(model.streakStartDate, streakStart);
    });

    test('default streak values should be zero', () {
      final model = StreakModel(
        id: 'new-user',
        userId: 'user-new',
      );

      expect(model.currentStreak, 0);
      expect(model.longestStreak, 0);
    });
  });

  group('StreakModel - entity conversion', () {
    test('toEntity should convert to Streak entity', () {
      final lastFeeding = DateTime.now();
      final streakStart = DateTime.now().subtract(const Duration(days: 7));
      final model = StreakModel(
        id: 'streak-123',
        userId: 'user-456',
        currentStreak: 7,
        longestStreak: 14,
        lastFeedingDate: lastFeeding,
        streakStartDate: streakStart,
      );

      final entity = model.toEntity();

      expect(entity, isA<Streak>());
      expect(entity.id, 'streak-123');
      expect(entity.userId, 'user-456');
      expect(entity.currentStreak, 7);
      expect(entity.longestStreak, 14);
      expect(entity.lastFeedingDate, lastFeeding);
      expect(entity.streakStartDate, streakStart);
    });

    test('fromEntity should create model from Streak entity', () {
      final lastFeeding = DateTime.now();
      final streakStart = DateTime.now().subtract(const Duration(days: 3));
      final entity = Streak(
        id: 'entity-streak',
        userId: 'entity-user',
        currentStreak: 3,
        longestStreak: 20,
        lastFeedingDate: lastFeeding,
        streakStartDate: streakStart,
      );

      final model = StreakModel.fromEntity(entity);

      expect(model.id, 'entity-streak');
      expect(model.userId, 'entity-user');
      expect(model.currentStreak, 3);
      expect(model.longestStreak, 20);
      expect(model.lastFeedingDate, lastFeeding);
      expect(model.streakStartDate, streakStart);
    });

    test('round-trip conversion should preserve data', () {
      final lastFeeding = DateTime.now();
      final streakStart = DateTime.now().subtract(const Duration(days: 10));
      final originalEntity = Streak(
        id: 'round-trip',
        userId: 'user-rt',
        currentStreak: 10,
        longestStreak: 30,
        lastFeedingDate: lastFeeding,
        streakStartDate: streakStart,
      );

      final model = StreakModel.fromEntity(originalEntity);
      final resultEntity = model.toEntity();

      expect(resultEntity, equals(originalEntity));
    });

    test('round-trip should preserve null optional fields', () {
      const originalEntity = Streak(
        id: 'minimal',
        userId: 'user-minimal',
      );

      final model = StreakModel.fromEntity(originalEntity);
      final resultEntity = model.toEntity();

      expect(resultEntity, equals(originalEntity));
      expect(resultEntity.lastFeedingDate, isNull);
      expect(resultEntity.streakStartDate, isNull);
      expect(resultEntity.currentStreak, 0);
      expect(resultEntity.longestStreak, 0);
    });
  });

  group('StreakModel - Hive persistence', () {
    setUp(() async {
      await HiveBoxes.initForTesting();
    });

    test('should save and retrieve StreakModel from Hive', () async {
      final lastFeeding = DateTime.now();
      final model = StreakModel(
        id: 'persist-streak',
        userId: 'persist-user',
        currentStreak: 15,
        longestStreak: 25,
        lastFeedingDate: lastFeeding,
      );

      await HiveBoxes.streaks.put(model.id, model);
      final retrieved = HiveBoxes.streaks.get(model.id) as StreakModel;

      expect(retrieved.id, model.id);
      expect(retrieved.userId, model.userId);
      expect(retrieved.currentStreak, model.currentStreak);
      expect(retrieved.longestStreak, model.longestStreak);
    });

    test('should update streak values', () async {
      final model = StreakModel(
        id: 'update-streak',
        userId: 'update-user',
        currentStreak: 1,
        longestStreak: 1,
      );

      await HiveBoxes.streaks.put(model.id, model);

      model.currentStreak = 2;
      model.longestStreak = 2;
      model.lastFeedingDate = DateTime.now();
      await HiveBoxes.streaks.put(model.id, model);

      final retrieved = HiveBoxes.streaks.get(model.id) as StreakModel;
      expect(retrieved.currentStreak, 2);
      expect(retrieved.longestStreak, 2);
      expect(retrieved.lastFeedingDate, isNotNull);
    });
  });

  group('StreakModel - TypeAdapter', () {
    test('should have correct typeId', () {
      final adapter = StreakModelAdapter();
      expect(adapter.typeId, 5);
    });
  });
}
