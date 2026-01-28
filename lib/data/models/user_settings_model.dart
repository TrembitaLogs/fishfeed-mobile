import 'package:hive_flutter/hive_flutter.dart';

import 'package:fishfeed/domain/entities/user_settings.dart';

part 'user_settings_model.g.dart';

/// Hive model for [UserSettings].
@HiveType(typeId: 3)
class UserSettingsModel extends HiveObject {
  UserSettingsModel({
    this.notificationsEnabled = true,
    this.feedingReminderMinutesBefore = 15,
    this.darkModeEnabled,
    this.language = 'en',
  });

  /// Creates a model from a domain entity.
  factory UserSettingsModel.fromEntity(UserSettings entity) {
    return UserSettingsModel(
      notificationsEnabled: entity.notificationsEnabled,
      feedingReminderMinutesBefore: entity.feedingReminderMinutesBefore,
      darkModeEnabled: entity.darkModeEnabled,
      language: entity.language,
    );
  }

  /// Whether push notifications are enabled.
  @HiveField(0)
  bool notificationsEnabled;

  /// Minutes before feeding time to send reminder.
  @HiveField(1)
  int feedingReminderMinutesBefore;

  /// Whether dark mode is enabled. Null means follow system.
  @HiveField(2)
  bool? darkModeEnabled;

  /// Preferred language code (e.g., 'en', 'de').
  @HiveField(3)
  String language;

  /// Converts this model to a domain entity.
  UserSettings toEntity() {
    return UserSettings(
      notificationsEnabled: notificationsEnabled,
      feedingReminderMinutesBefore: feedingReminderMinutesBefore,
      darkModeEnabled: darkModeEnabled,
      language: language,
    );
  }
}
