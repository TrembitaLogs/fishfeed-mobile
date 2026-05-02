import 'package:equatable/equatable.dart';
import 'package:timezone/timezone.dart' as tz;

/// Notification channel for routing PlannedAlarm to the right OS channel.
enum NotificationChannel {
  feedingReminders,
  missedEvents,
  confirmStatus,
  freezeAvailable,
}

/// Why a reconcile() pass was triggered. Logged + used to choose strategy
/// (e.g. localeChanged forces full cancel+replan instead of diff).
enum ReconcileReason {
  appLaunch,
  appResume,
  userMutation,
  onboardingComplete,
  syncComplete,
  localeChanged,
  permissionChanged,
  dailyRefill,
  migration,
}

/// Single planned notification — fully resolved, ready to hand to the OS.
class PlannedAlarm extends Equatable {
  const PlannedAlarm({
    required this.eventId,
    required this.scheduleId,
    required this.fishId,
    required this.aquariumId,
    required this.scheduledAt,
    required this.title,
    required this.body,
    required this.channel,
    required this.payload,
  });

  /// Deterministic 32-bit positive int. Same schedule+date+time → same id.
  final int eventId;
  final String scheduleId;
  final String fishId;
  final String aquariumId;
  final tz.TZDateTime scheduledAt;
  final String title;
  final String body;
  final NotificationChannel channel;

  /// Format: `feeding|{scheduleId}|{YYYY-MM-DD}|{HHmm}`.
  final String payload;

  @override
  List<Object?> get props => [
    eventId,
    scheduleId,
    fishId,
    aquariumId,
    scheduledAt,
    title,
    body,
    channel,
    payload,
  ];
}

/// Per-alarm error captured during _applyDiff.
class NotifError extends Equatable {
  const NotifError({
    required this.eventId,
    required this.kind,
    required this.message,
  });

  final int eventId;
  final String kind; // exception class name
  final String message;

  @override
  List<Object?> get props => [eventId, kind, message];
}

/// Aggregate result of a single reconcile() invocation.
class ReconcileResult extends Equatable {
  const ReconcileResult.success({
    required this.added,
    required this.cancelled,
    required this.kept,
    this.errors = const [],
    this.duration = Duration.zero,
  }) : isSuccess = true,
       error = null;

  const ReconcileResult.failed(Object thrown)
    : isSuccess = false,
      error = thrown,
      added = 0,
      cancelled = 0,
      kept = 0,
      errors = const [],
      duration = Duration.zero;

  final bool isSuccess;
  final Object? error;
  final int added;
  final int cancelled;
  final int kept;
  final List<NotifError> errors;
  final Duration duration;

  @override
  List<Object?> get props => [
    isSuccess,
    error,
    added,
    cancelled,
    kept,
    errors,
    duration,
  ];
}
