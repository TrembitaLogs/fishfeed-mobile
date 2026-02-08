import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:fishfeed/data/models/user_model.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await HiveBoxes.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HiveBoxNames', () {
    test('should have correct box names', () {
      expect(HiveBoxNames.users, 'users');
      expect(HiveBoxNames.aquariums, 'aquariums');
      expect(HiveBoxNames.fish, 'fish');
      expect(HiveBoxNames.species, 'species');
      expect(HiveBoxNames.streaks, 'streaks');
      expect(HiveBoxNames.achievements, 'achievements');
      expect(HiveBoxNames.syncQueue, 'syncQueue');
      expect(HiveBoxNames.appPreferences, 'appPreferences');
      expect(HiveBoxNames.schedules, 'schedules');
      expect(HiveBoxNames.feedingLogs, 'feedingLogs');
    });
  });

  group('AppPreferenceKeys', () {
    test('should have correct preference keys', () {
      expect(AppPreferenceKeys.onboardingCompleted, 'onboardingCompleted');
      expect(AppPreferenceKeys.pushToken, 'pushToken');
      expect(AppPreferenceKeys.pushTokenPlatform, 'pushTokenPlatform');
    });
  });

  group('HiveBoxes - before initialization', () {
    test('isInitialized should be false before init', () {
      expect(HiveBoxes.isInitialized, isFalse);
    });

    test('accessing users box before init should throw StateError', () {
      expect(() => HiveBoxes.users, throwsStateError);
    });

    test('accessing aquariums box before init should throw StateError', () {
      expect(() => HiveBoxes.aquariums, throwsStateError);
    });

    test('accessing fish box before init should throw StateError', () {
      expect(() => HiveBoxes.fish, throwsStateError);
    });

    test('accessing species box before init should throw StateError', () {
      expect(() => HiveBoxes.species, throwsStateError);
    });

    test('accessing streaks box before init should throw StateError', () {
      expect(() => HiveBoxes.streaks, throwsStateError);
    });

    test('accessing achievements box before init should throw StateError', () {
      expect(() => HiveBoxes.achievements, throwsStateError);
    });

    test('accessing syncQueue box before init should throw StateError', () {
      expect(() => HiveBoxes.syncQueue, throwsStateError);
    });

    test(
      'accessing appPreferences box before init should throw StateError',
      () {
        expect(() => HiveBoxes.appPreferences, throwsStateError);
      },
    );

    test('getOnboardingCompleted before init should throw StateError', () {
      expect(() => HiveBoxes.getOnboardingCompleted(), throwsStateError);
    });

    test('setOnboardingCompleted before init should throw StateError', () {
      expect(() => HiveBoxes.setOnboardingCompleted(true), throwsStateError);
    });
  });

  group('HiveBoxes - after initialization', () {
    setUp(() async {
      await HiveBoxes.initForTesting();
    });

    test('isInitialized should be true after init', () {
      expect(HiveBoxes.isInitialized, isTrue);
    });

    test('should provide access to users box', () {
      expect(HiveBoxes.users, isA<Box<dynamic>>());
      expect(HiveBoxes.users.name, HiveBoxNames.users);
    });

    test('should provide access to aquariums box', () {
      expect(HiveBoxes.aquariums, isA<Box<dynamic>>());
      expect(HiveBoxes.aquariums.name, HiveBoxNames.aquariums);
    });

    test('should provide access to fish box', () {
      expect(HiveBoxes.fish, isA<Box<dynamic>>());
      expect(HiveBoxes.fish.name, HiveBoxNames.fish);
    });

    test('should provide access to species box', () {
      expect(HiveBoxes.species, isA<Box<dynamic>>());
      expect(HiveBoxes.species.name, HiveBoxNames.species);
    });

    test('should provide access to streaks box', () {
      expect(HiveBoxes.streaks, isA<Box<dynamic>>());
      expect(HiveBoxes.streaks.name, HiveBoxNames.streaks);
    });

    test('should provide access to achievements box', () {
      expect(HiveBoxes.achievements, isA<Box<dynamic>>());
      expect(HiveBoxes.achievements.name, HiveBoxNames.achievements);
    });

    test('should provide access to syncQueue box', () {
      expect(HiveBoxes.syncQueue, isA<Box<dynamic>>());
      expect(
        HiveBoxes.syncQueue.name.toLowerCase(),
        HiveBoxNames.syncQueue.toLowerCase(),
      );
    });

    test('should provide access to appPreferences box', () {
      expect(HiveBoxes.appPreferences, isA<Box<dynamic>>());
      expect(
        HiveBoxes.appPreferences.name.toLowerCase(),
        HiveBoxNames.appPreferences.toLowerCase(),
      );
    });

    test('calling init again should throw StateError', () async {
      expect(() => HiveBoxes.initForTesting(), throwsStateError);
    });
  });

  group('HiveBoxes - onboarding completion', () {
    setUp(() async {
      await HiveBoxes.initForTesting();
    });

    test('getOnboardingCompleted should return false by default', () {
      expect(HiveBoxes.getOnboardingCompleted(), isFalse);
    });

    test('setOnboardingCompleted should persist value', () async {
      await HiveBoxes.setOnboardingCompleted(true);
      expect(HiveBoxes.getOnboardingCompleted(), isTrue);
    });

    test('setOnboardingCompleted should allow setting to false', () async {
      await HiveBoxes.setOnboardingCompleted(true);
      expect(HiveBoxes.getOnboardingCompleted(), isTrue);

      await HiveBoxes.setOnboardingCompleted(false);
      expect(HiveBoxes.getOnboardingCompleted(), isFalse);
    });
  });

  group('HiveBoxes - box operations', () {
    setUp(() async {
      await HiveBoxes.initForTesting();
    });

    test('should be able to write and read from users box', () async {
      final user = UserModel(
        id: 'test_user',
        email: 'test@example.com',
        createdAt: DateTime(2024),
      );
      await HiveBoxes.users.put('test_key', user);
      expect(HiveBoxes.users.get('test_key')?.id, 'test_user');
    });

    test('should be able to write and read from schedules box', () async {
      final schedule = ScheduleModel(
        id: 'schedule_1',
        fishId: 'fish_1',
        aquariumId: 'aquarium_1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: DateTime(2024),
        foodType: 'flakes',
        active: true,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        createdByUserId: 'user_1',
      );
      await HiveBoxes.schedules.put('schedule_1', schedule);
      expect(HiveBoxes.schedules.get('schedule_1')?.id, 'schedule_1');
    });

    test('clearAll should clear all boxes', () async {
      // Add data to multiple boxes
      final user = UserModel(
        id: 'u1',
        email: 'a@b.com',
        createdAt: DateTime(2024),
      );
      final aquarium = AquariumModel(
        id: 'a1',
        userId: 'u1',
        name: 'Tank',
        createdAt: DateTime(2024),
      );
      final fish = FishModel(
        id: 'f1',
        aquariumId: 'a1',
        speciesId: 's1',
        addedAt: DateTime(2024),
      );
      final schedule = ScheduleModel(
        id: 'sc1',
        fishId: 'f1',
        aquariumId: 'a1',
        time: '09:00',
        intervalDays: 1,
        anchorDate: DateTime(2024),
        foodType: 'flakes',
        active: true,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
        createdByUserId: 'u1',
      );
      final log = FeedingLogModel(
        id: 'l1',
        scheduleId: 'sc1',
        fishId: 'f1',
        aquariumId: 'a1',
        scheduledFor: DateTime(2024),
        action: 'fed',
        actedAt: DateTime(2024),
        actedByUserId: 'u1',
        deviceId: 'dev1',
        createdAt: DateTime(2024),
      );
      await HiveBoxes.users.put('key1', user);
      await HiveBoxes.aquariums.put('key2', aquarium);
      await HiveBoxes.fish.put('key3', fish);
      await HiveBoxes.schedules.put('key4', schedule);
      await HiveBoxes.feedingLogs.put('key5', log);
      await HiveBoxes.setOnboardingCompleted(true);

      // Clear all
      await HiveBoxes.clearAll();

      // Verify all boxes are empty
      expect(HiveBoxes.users.isEmpty, isTrue);
      expect(HiveBoxes.aquariums.isEmpty, isTrue);
      expect(HiveBoxes.fish.isEmpty, isTrue);
      expect(HiveBoxes.species.isEmpty, isTrue);
      expect(HiveBoxes.streaks.isEmpty, isTrue);
      expect(HiveBoxes.achievements.isEmpty, isTrue);
      expect(HiveBoxes.syncQueue.isEmpty, isTrue);
      expect(HiveBoxes.appPreferences.isEmpty, isTrue);
      expect(HiveBoxes.schedules.isEmpty, isTrue);
      expect(HiveBoxes.feedingLogs.isEmpty, isTrue);
      expect(HiveBoxes.getOnboardingCompleted(), isFalse);
    });
  });

  group('HiveBoxes - close', () {
    test('close should reset isInitialized flag', () async {
      await HiveBoxes.initForTesting();
      expect(HiveBoxes.isInitialized, isTrue);

      await HiveBoxes.close();
      expect(HiveBoxes.isInitialized, isFalse);
    });

    test('close should be safe to call when not initialized', () async {
      expect(HiveBoxes.isInitialized, isFalse);
      // Should not throw
      await HiveBoxes.close();
      expect(HiveBoxes.isInitialized, isFalse);
    });
  });

  group('HiveBoxes - push token storage', () {
    setUp(() async {
      await HiveBoxes.initForTesting();
    });

    test('getPushToken should return null by default', () {
      expect(HiveBoxes.getPushToken(), isNull);
    });

    test('getPushTokenPlatform should return null by default', () {
      expect(HiveBoxes.getPushTokenPlatform(), isNull);
    });

    test('setPushToken should store token and platform', () async {
      await HiveBoxes.setPushToken('test-token-123', 'android');

      expect(HiveBoxes.getPushToken(), 'test-token-123');
      expect(HiveBoxes.getPushTokenPlatform(), 'android');
    });

    test('setPushToken should handle iOS platform', () async {
      await HiveBoxes.setPushToken('ios-token-456', 'ios');

      expect(HiveBoxes.getPushToken(), 'ios-token-456');
      expect(HiveBoxes.getPushTokenPlatform(), 'ios');
    });

    test('setPushToken should overwrite existing values', () async {
      await HiveBoxes.setPushToken('old-token', 'android');
      await HiveBoxes.setPushToken('new-token', 'ios');

      expect(HiveBoxes.getPushToken(), 'new-token');
      expect(HiveBoxes.getPushTokenPlatform(), 'ios');
    });

    test('clearPushToken should remove token and platform', () async {
      await HiveBoxes.setPushToken('token-to-clear', 'android');
      expect(HiveBoxes.getPushToken(), 'token-to-clear');

      await HiveBoxes.clearPushToken();

      expect(HiveBoxes.getPushToken(), isNull);
      expect(HiveBoxes.getPushTokenPlatform(), isNull);
    });

    test('clearPushToken should be safe when no token stored', () async {
      expect(HiveBoxes.getPushToken(), isNull);

      // Should not throw
      await HiveBoxes.clearPushToken();

      expect(HiveBoxes.getPushToken(), isNull);
    });

    test('clearAll should also clear push token data', () async {
      await HiveBoxes.setPushToken('token-in-all', 'android');
      expect(HiveBoxes.getPushToken(), 'token-in-all');

      await HiveBoxes.clearAll();

      expect(HiveBoxes.getPushToken(), isNull);
      expect(HiveBoxes.getPushTokenPlatform(), isNull);
    });
  });

  group('HiveBoxes - clearUserData', () {
    setUp(() async {
      await HiveBoxes.initForTesting();
    });

    test(
      'clearUserData should clear schedules and feedingLogs boxes',
      () async {
        // Add data to boxes
        final schedule = ScheduleModel(
          id: 'schedule1',
          fishId: 'f1',
          aquariumId: 'a1',
          time: '09:00',
          intervalDays: 1,
          anchorDate: DateTime(2024),
          foodType: 'flakes',
          active: true,
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
          createdByUserId: 'u1',
        );
        final log = FeedingLogModel(
          id: 'log1',
          scheduleId: 'sc1',
          fishId: 'f1',
          aquariumId: 'a1',
          scheduledFor: DateTime(2024),
          action: 'fed',
          actedAt: DateTime(2024),
          actedByUserId: 'u1',
          deviceId: 'dev1',
          createdAt: DateTime(2024),
        );
        final user = UserModel(
          id: 'user1',
          email: 'a@b.com',
          createdAt: DateTime(2024),
        );
        await HiveBoxes.schedules.put('schedule1', schedule);
        await HiveBoxes.feedingLogs.put('log1', log);
        await HiveBoxes.users.put('user1', user);

        // Clear user data
        await HiveBoxes.clearUserData();

        // Verify all are cleared
        expect(HiveBoxes.schedules.isEmpty, isTrue);
        expect(HiveBoxes.feedingLogs.isEmpty, isTrue);
        expect(HiveBoxes.users.isEmpty, isTrue);
      },
    );

    test('clearUserData should reset onboarding', () async {
      await HiveBoxes.setOnboardingCompleted(true);
      expect(HiveBoxes.getOnboardingCompleted(), isTrue);

      await HiveBoxes.clearUserData();

      expect(HiveBoxes.getOnboardingCompleted(), isFalse);
    });
  });
}
