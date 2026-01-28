import 'package:equatable/equatable.dart';

/// User-specific application settings.
class UserSettings extends Equatable {
  const UserSettings({
    this.notificationsEnabled = true,
    this.feedingReminderMinutesBefore = 15,
    this.darkModeEnabled,
    this.language = 'en',
  });

  /// Whether push notifications are enabled.
  final bool notificationsEnabled;

  /// Minutes before feeding time to send reminder.
  final int feedingReminderMinutesBefore;

  /// Whether dark mode is enabled. Null means follow system.
  final bool? darkModeEnabled;

  /// Preferred language code (e.g., 'en', 'de').
  final String language;

  /// Creates a copy with updated fields.
  UserSettings copyWith({
    bool? notificationsEnabled,
    int? feedingReminderMinutesBefore,
    bool? darkModeEnabled,
    String? language,
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      feedingReminderMinutesBefore:
          feedingReminderMinutesBefore ?? this.feedingReminderMinutesBefore,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [
        notificationsEnabled,
        feedingReminderMinutesBefore,
        darkModeEnabled,
        language,
      ];
}
