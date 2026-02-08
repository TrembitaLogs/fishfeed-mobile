import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/data/models/user_settings_model.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/domain/entities/user.dart';

part 'user_model.g.dart';

/// Hive model for [User] entity.
///
/// Stores user data locally with offline support.
/// Use [toEntity] and [fromEntity] for domain layer conversion.
@HiveType(typeId: 0)
class UserModel extends HiveObject {
  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.subscriptionStatus = const SubscriptionStatus.free(),
    this.freeAiScansRemaining = 5,
    UserSettingsModel? settings,
    this.synced = true,
    this.serverUpdatedAt,
  }) : settings = settings ?? UserSettingsModel();

  /// Creates a model from a domain entity.
  factory UserModel.fromEntity(User entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      avatarUrl: entity.avatarUrl,
      createdAt: entity.createdAt,
      subscriptionStatus: entity.subscriptionStatus,
      freeAiScansRemaining: entity.freeAiScansRemaining,
      settings: UserSettingsModel.fromEntity(entity.settings),
      synced: true,
    );
  }

  /// Unique identifier for the user.
  @HiveField(0)
  String id;

  /// User's email address.
  @HiveField(1)
  String email;

  /// User's display name (nickname).
  @HiveField(2)
  String? displayName;

  /// URL to user's avatar image.
  @HiveField(3)
  String? avatarUrl;

  /// When the user account was created.
  @HiveField(4)
  DateTime createdAt;

  /// User's subscription status.
  @HiveField(5)
  SubscriptionStatus subscriptionStatus;

  /// Number of free AI scans remaining.
  @HiveField(6)
  int freeAiScansRemaining;

  /// User's application settings.
  @HiveField(7)
  UserSettingsModel settings;

  /// Whether this user has been synced to the server.
  @HiveField(8, defaultValue: true)
  bool synced;

  /// Server-side updated_at timestamp for delta sync.
  @HiveField(9)
  DateTime? serverUpdatedAt;

  /// Converts this model to JSON for the sync endpoint.
  Map<String, dynamic> toSyncJson() {
    return {
      'id': id,
      'nickname': displayName,
      'avatar_url': avatarUrl,
      'settings': {
        'notifications_enabled': settings.notificationsEnabled,
        'feeding_reminder_minutes_before':
            settings.feedingReminderMinutesBefore,
        'dark_mode_enabled': settings.darkModeEnabled,
        'language': settings.language,
      },
    };
  }

  /// Converts this model to a domain entity.
  User toEntity() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
      subscriptionStatus: subscriptionStatus,
      freeAiScansRemaining: freeAiScansRemaining,
      settings: settings.toEntity(),
    );
  }
}
