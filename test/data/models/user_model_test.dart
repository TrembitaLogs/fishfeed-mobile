import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/user_model.dart';
import 'package:fishfeed/data/models/user_settings_model.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';
import 'package:fishfeed/domain/entities/user_settings.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_user_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await HiveBoxes.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('UserModel', () {
    test('should create UserModel with required fields', () {
      final now = DateTime.now();
      final model = UserModel(
        id: 'user-123',
        email: 'test@example.com',
        createdAt: now,
      );

      expect(model.id, 'user-123');
      expect(model.email, 'test@example.com');
      expect(model.createdAt, now);
      expect(model.displayName, isNull);
      expect(model.avatarKey, isNull);
      expect(model.subscriptionStatus, const SubscriptionStatus.free());
      expect(model.freeAiScansRemaining, 5);
      expect(model.settings, isA<UserSettingsModel>());
    });

    test('should create UserModel with all fields', () {
      final now = DateTime.now();
      final settings = UserSettingsModel(
        notificationsEnabled: false,
        feedingReminderMinutesBefore: 30,
        darkModeEnabled: true,
        language: 'de',
      );

      final model = UserModel(
        id: 'user-456',
        email: 'premium@example.com',
        displayName: 'Premium User',
        avatarKey: 'https://example.com/avatar.png',
        createdAt: now,
        subscriptionStatus: SubscriptionStatus.premium(),
        freeAiScansRemaining: 0,
        settings: settings,
      );

      expect(model.id, 'user-456');
      expect(model.email, 'premium@example.com');
      expect(model.displayName, 'Premium User');
      expect(model.avatarKey, 'https://example.com/avatar.png');
      expect(model.subscriptionStatus, SubscriptionStatus.premium());
      expect(model.freeAiScansRemaining, 0);
      expect(model.settings.darkModeEnabled, true);
      expect(model.settings.language, 'de');
    });
  });

  group('UserModel - entity conversion', () {
    test('toEntity should convert to User entity', () {
      final now = DateTime.now();
      final model = UserModel(
        id: 'user-123',
        email: 'test@example.com',
        displayName: 'Test User',
        avatarKey: 'https://example.com/avatar.png',
        createdAt: now,
        subscriptionStatus: SubscriptionStatus.premium(),
        freeAiScansRemaining: 3,
        settings: UserSettingsModel(
          notificationsEnabled: false,
          feedingReminderMinutesBefore: 10,
          darkModeEnabled: true,
          language: 'de',
        ),
      );

      final entity = model.toEntity();

      expect(entity, isA<User>());
      expect(entity.id, 'user-123');
      expect(entity.email, 'test@example.com');
      expect(entity.displayName, 'Test User');
      expect(entity.avatarKey, 'https://example.com/avatar.png');
      expect(entity.createdAt, now);
      expect(entity.subscriptionStatus, SubscriptionStatus.premium());
      expect(entity.freeAiScansRemaining, 3);
      expect(entity.settings.notificationsEnabled, false);
      expect(entity.settings.feedingReminderMinutesBefore, 10);
      expect(entity.settings.darkModeEnabled, true);
      expect(entity.settings.language, 'de');
    });

    test('fromEntity should create model from User entity', () {
      final now = DateTime.now();
      final entity = User(
        id: 'user-789',
        email: 'entity@example.com',
        displayName: 'Entity User',
        avatarKey: 'https://example.com/entity.png',
        createdAt: now,
        subscriptionStatus: const SubscriptionStatus.free(),
        freeAiScansRemaining: 5,
        settings: const UserSettings(
          notificationsEnabled: true,
          feedingReminderMinutesBefore: 15,
          language: 'en',
        ),
      );

      final model = UserModel.fromEntity(entity);

      expect(model.id, 'user-789');
      expect(model.email, 'entity@example.com');
      expect(model.displayName, 'Entity User');
      expect(model.avatarKey, 'https://example.com/entity.png');
      expect(model.createdAt, now);
      expect(model.subscriptionStatus, const SubscriptionStatus.free());
      expect(model.freeAiScansRemaining, 5);
      expect(model.settings.notificationsEnabled, true);
      expect(model.settings.feedingReminderMinutesBefore, 15);
      expect(model.settings.language, 'en');
    });

    test('round-trip conversion should preserve data', () {
      final now = DateTime.now();
      final originalEntity = User(
        id: 'round-trip',
        email: 'roundtrip@example.com',
        displayName: 'Round Trip',
        createdAt: now,
        subscriptionStatus: SubscriptionStatus.premium(),
        freeAiScansRemaining: 2,
        settings: const UserSettings(
          notificationsEnabled: false,
          feedingReminderMinutesBefore: 20,
          darkModeEnabled: false,
          language: 'de',
        ),
      );

      final model = UserModel.fromEntity(originalEntity);
      final resultEntity = model.toEntity();

      expect(resultEntity, equals(originalEntity));
    });
  });

  group('UserModel - toSyncJson', () {
    test('should NOT include avatar_key when it starts with local://', () {
      final model = UserModel(
        id: 'user-123',
        email: 'test@example.com',
        createdAt: DateTime(2025, 1, 15),
        avatarKey: 'local://a1b2c3d4-e5f6-7890-abcd-ef1234567890',
      );

      final json = model.toSyncJson();

      expect(json.containsKey('avatar_key'), false);
      expect(json['id'], 'user-123');
      expect(json['nickname'], isNull);
      expect(json.containsKey('settings'), true);
    });

    test('should include avatar_key when it is a valid S3 key', () {
      final model = UserModel(
        id: 'user-456',
        email: 'test@example.com',
        createdAt: DateTime(2025, 1, 15),
        avatarKey: 'avatars/user-456/f7a3b2c1.webp',
      );

      final json = model.toSyncJson();

      expect(json['avatar_key'], 'avatars/user-456/f7a3b2c1.webp');
    });

    test('should NOT include avatar_key when it is null', () {
      final model = UserModel(
        id: 'user-789',
        email: 'test@example.com',
        createdAt: DateTime(2025, 1, 15),
      );

      final json = model.toSyncJson();

      expect(json.containsKey('avatar_key'), false);
    });

    test('should always include other fields regardless of avatar_key', () {
      final model = UserModel(
        id: 'user-100',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime(2025, 1, 15),
        avatarKey: 'local://some-uuid',
      );

      final json = model.toSyncJson();

      expect(json['id'], 'user-100');
      expect(json['nickname'], 'Test User');
      expect(json['settings'], isA<Map<String, dynamic>>());
      expect(json.containsKey('avatar_key'), false);
    });
  });

  group('UserModel - Hive persistence', () {
    setUp(() async {
      await HiveBoxes.initForTesting();
    });

    test('should save and retrieve UserModel from Hive', () async {
      final now = DateTime.now();
      final model = UserModel(
        id: 'persist-user',
        email: 'persist@example.com',
        displayName: 'Persist User',
        createdAt: now,
        subscriptionStatus: const SubscriptionStatus.free(),
        freeAiScansRemaining: 5,
      );

      await HiveBoxes.users.put(model.id, model);
      final retrieved = HiveBoxes.users.get(model.id) as UserModel;

      expect(retrieved.id, model.id);
      expect(retrieved.email, model.email);
      expect(retrieved.displayName, model.displayName);
      expect(retrieved.subscriptionStatus, model.subscriptionStatus);
      expect(retrieved.freeAiScansRemaining, model.freeAiScansRemaining);
    });

    test('should save UserModel with nested UserSettingsModel', () async {
      final now = DateTime.now();
      final model = UserModel(
        id: 'nested-user',
        email: 'nested@example.com',
        createdAt: now,
        settings: UserSettingsModel(
          notificationsEnabled: false,
          feedingReminderMinutesBefore: 25,
          darkModeEnabled: true,
          language: 'de',
        ),
      );

      await HiveBoxes.users.put(model.id, model);
      final retrieved = HiveBoxes.users.get(model.id) as UserModel;

      expect(retrieved.settings.notificationsEnabled, false);
      expect(retrieved.settings.feedingReminderMinutesBefore, 25);
      expect(retrieved.settings.darkModeEnabled, true);
      expect(retrieved.settings.language, 'de');
    });
  });
}
