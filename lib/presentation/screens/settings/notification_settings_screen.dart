import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/presentation/providers/settings_provider.dart';

/// Screen for managing notification settings.
///
/// Includes:
/// - Master toggle for all notifications
/// - Individual toggles for feeding reminders, streak alerts, weekly summary
/// - Quiet hours time range picker
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          // Master toggle section
          _MasterToggleSection(
            isEnabled: settings.notificationsEnabled,
            onChanged: (value) => notifier.setNotificationsEnabled(value),
          ),
          const Divider(height: 32),

          // Individual notification toggles
          _NotificationTogglesSection(
            masterEnabled: settings.notificationsEnabled,
            feedingRemindersEnabled: settings.feedingRemindersEnabled,
            streakAlertsEnabled: settings.streakAlertsEnabled,
            weeklySummaryEnabled: settings.weeklySummaryEnabled,
            onFeedingRemindersChanged: (value) =>
                notifier.setFeedingRemindersEnabled(value),
            onStreakAlertsChanged: (value) =>
                notifier.setStreakAlertsEnabled(value),
            onWeeklySummaryChanged: (value) =>
                notifier.setWeeklySummaryEnabled(value),
          ),
          const Divider(height: 32),

          // Quiet hours section
          _QuietHoursSection(
            masterEnabled: settings.notificationsEnabled,
            quietHoursEnabled: settings.quietHoursEnabled,
            startMinutes: settings.quietHoursStart,
            endMinutes: settings.quietHoursEnd,
            onQuietHoursToggled: (enabled) {
              if (enabled) {
                // Set default quiet hours: 22:00 - 08:00
                notifier.setQuietHours(
                  startMinutes: 22 * 60,
                  endMinutes: 8 * 60,
                );
              } else {
                notifier.disableQuietHours();
              }
            },
            onStartTimeChanged: (minutes) => notifier.setQuietHours(
              startMinutes: minutes,
              endMinutes: settings.quietHoursEnd,
            ),
            onEndTimeChanged: (minutes) => notifier.setQuietHours(
              startMinutes: settings.quietHoursStart,
              endMinutes: minutes,
            ),
          ),

          // Info text
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Notification preferences are saved locally and will be synced with your account when online.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Master toggle section for enabling/disabling all notifications.
class _MasterToggleSection extends StatelessWidget {
  const _MasterToggleSection({
    required this.isEnabled,
    required this.onChanged,
  });

  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SwitchListTile(
      title: const Text('Enable Notifications'),
      subtitle: Text(
        isEnabled
            ? 'Receive feeding reminders and alerts'
            : 'All notifications are disabled',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEnabled
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isEnabled ? Icons.notifications_active : Icons.notifications_off,
          color: isEnabled
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      value: isEnabled,
      onChanged: onChanged,
    );
  }
}

/// Section for individual notification toggles.
class _NotificationTogglesSection extends StatelessWidget {
  const _NotificationTogglesSection({
    required this.masterEnabled,
    required this.feedingRemindersEnabled,
    required this.streakAlertsEnabled,
    required this.weeklySummaryEnabled,
    required this.onFeedingRemindersChanged,
    required this.onStreakAlertsChanged,
    required this.onWeeklySummaryChanged,
  });

  final bool masterEnabled;
  final bool feedingRemindersEnabled;
  final bool streakAlertsEnabled;
  final bool weeklySummaryEnabled;
  final ValueChanged<bool> onFeedingRemindersChanged;
  final ValueChanged<bool> onStreakAlertsChanged;
  final ValueChanged<bool> onWeeklySummaryChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Notification Types',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _NotificationToggleTile(
          icon: Icons.restaurant,
          title: 'Feeding Reminders',
          subtitle: 'Get notified when it\'s time to feed',
          value: feedingRemindersEnabled,
          enabled: masterEnabled,
          onChanged: onFeedingRemindersChanged,
        ),
        _NotificationToggleTile(
          icon: Icons.local_fire_department,
          title: 'Streak Alerts',
          subtitle: 'Warnings when your streak is at risk',
          value: streakAlertsEnabled,
          enabled: masterEnabled,
          onChanged: onStreakAlertsChanged,
        ),
        _NotificationToggleTile(
          icon: Icons.summarize,
          title: 'Weekly Summary',
          subtitle: 'Weekly feeding activity overview',
          value: weeklySummaryEnabled,
          enabled: masterEnabled,
          onChanged: onWeeklySummaryChanged,
        ),
      ],
    );
  }
}

/// A single notification toggle tile.
class _NotificationToggleTile extends StatelessWidget {
  const _NotificationToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveValue = enabled && value;

    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? null : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
      value: effectiveValue,
      onChanged: enabled ? onChanged : null,
    );
  }
}

/// Section for quiet hours configuration.
class _QuietHoursSection extends StatelessWidget {
  const _QuietHoursSection({
    required this.masterEnabled,
    required this.quietHoursEnabled,
    required this.startMinutes,
    required this.endMinutes,
    required this.onQuietHoursToggled,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
  });

  final bool masterEnabled;
  final bool quietHoursEnabled;
  final int? startMinutes;
  final int? endMinutes;
  final ValueChanged<bool> onQuietHoursToggled;
  final ValueChanged<int> onStartTimeChanged;
  final ValueChanged<int> onEndTimeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = masterEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Quiet Hours',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SwitchListTile(
          title: Text(
            'Enable Quiet Hours',
            style: TextStyle(
              color: enabled ? null : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          subtitle: Text(
            'Mute notifications during specified hours',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: enabled
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.bedtime,
              color: enabled
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          value: quietHoursEnabled,
          onChanged: enabled ? onQuietHoursToggled : null,
        ),
        if (quietHoursEnabled && enabled) ...[
          const SizedBox(height: 8),
          _TimeRangePicker(
            startMinutes: startMinutes ?? 22 * 60,
            endMinutes: endMinutes ?? 8 * 60,
            onStartTimeChanged: onStartTimeChanged,
            onEndTimeChanged: onEndTimeChanged,
          ),
        ],
      ],
    );
  }
}

/// Time range picker for quiet hours.
class _TimeRangePicker extends StatelessWidget {
  const _TimeRangePicker({
    required this.startMinutes,
    required this.endMinutes,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
  });

  final int startMinutes;
  final int endMinutes;
  final ValueChanged<int> onStartTimeChanged;
  final ValueChanged<int> onEndTimeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _TimePickerButton(
              label: 'From',
              minutes: startMinutes,
              onChanged: onStartTimeChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              Icons.arrow_forward,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: _TimePickerButton(
              label: 'To',
              minutes: endMinutes,
              onChanged: onEndTimeChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Button that shows a time picker when tapped.
class _TimePickerButton extends StatelessWidget {
  const _TimePickerButton({
    required this.label,
    required this.minutes,
    required this.onChanged,
  });

  final String label;
  final int minutes;
  final ValueChanged<int> onChanged;

  String _formatTime(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final theme = Theme.of(context);
    final initialTime = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: theme.colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      final newMinutes = selectedTime.hour * 60 + selectedTime.minute;
      onChanged(newMinutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _showTimePicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(minutes),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
