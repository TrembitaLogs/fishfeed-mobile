import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/utils/date_time_utils.dart';

/// Events that can occur during app lifecycle.
enum AppLifecycleEvent {
  /// App was resumed from background.
  resumed,

  /// Midnight crossed while app was in background or foreground.
  midnightCrossed,

  /// DST (Daylight Saving Time) transition detected.
  dstTransition,

  /// App went to background.
  paused,
}

/// Data associated with a lifecycle event.
class LifecycleEventData {
  const LifecycleEventData({
    required this.event,
    required this.timestamp,
    this.previousTimestamp,
    this.previousTimezoneOffset,
  });

  /// The type of event.
  final AppLifecycleEvent event;

  /// When the event occurred.
  final DateTime timestamp;

  /// The previous relevant timestamp (e.g., when app was paused).
  final DateTime? previousTimestamp;

  /// Previous timezone offset (for DST detection).
  final Duration? previousTimezoneOffset;

  /// Duration the app was in background (for resumed events).
  Duration? get backgroundDuration {
    if (event != AppLifecycleEvent.resumed || previousTimestamp == null) {
      return null;
    }
    return timestamp.difference(previousTimestamp!);
  }
}

/// Service for monitoring app lifecycle and detecting edge cases.
///
/// Handles:
/// - App resume after long background periods
/// - Midnight crossing detection
/// - DST transition detection
class AppLifecycleService with WidgetsBindingObserver {
  AppLifecycleService();

  final _eventController = StreamController<LifecycleEventData>.broadcast();
  Timer? _midnightTimer;
  DateTime? _lastPausedTime;
  Duration? _lastTimezoneOffset;
  bool _isInitialized = false;

  /// Stream of lifecycle events.
  Stream<LifecycleEventData> get eventStream => _eventController.stream;

  /// Whether the service is initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes the service and starts monitoring.
  void initialize() {
    if (_isInitialized) return;

    WidgetsBinding.instance.addObserver(this);
    _lastTimezoneOffset = DateTimeUtils.currentTimezoneOffset;
    _scheduleMidnightCheck();

    _isInitialized = true;
    debugPrint('AppLifecycleService: Initialized');
  }

  /// Disposes the service and stops monitoring.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    _eventController.close();
    _isInitialized = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _handleResume();
        break;
      case AppLifecycleState.paused:
        _handlePause();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _handleResume() {
    final now = DateTime.now();
    final currentOffset = DateTimeUtils.currentTimezoneOffset;

    debugPrint('AppLifecycleService: App resumed');

    // Check for DST transition
    if (_lastTimezoneOffset != null && _lastTimezoneOffset != currentOffset) {
      debugPrint('AppLifecycleService: DST transition detected');
      _eventController.add(
        LifecycleEventData(
          event: AppLifecycleEvent.dstTransition,
          timestamp: now,
          previousTimezoneOffset: _lastTimezoneOffset,
        ),
      );
    }
    _lastTimezoneOffset = currentOffset;

    // Check for midnight crossing
    if (_lastPausedTime != null &&
        DateTimeUtils.hasMidnightCrossed(_lastPausedTime!)) {
      debugPrint('AppLifecycleService: Midnight crossed during background');
      _eventController.add(
        LifecycleEventData(
          event: AppLifecycleEvent.midnightCrossed,
          timestamp: now,
          previousTimestamp: _lastPausedTime,
        ),
      );
    }

    // Emit resume event
    _eventController.add(
      LifecycleEventData(
        event: AppLifecycleEvent.resumed,
        timestamp: now,
        previousTimestamp: _lastPausedTime,
      ),
    );

    // Reschedule midnight check
    _scheduleMidnightCheck();
  }

  void _handlePause() {
    _lastPausedTime = DateTime.now();
    _midnightTimer?.cancel();

    debugPrint('AppLifecycleService: App paused');

    _eventController.add(
      LifecycleEventData(
        event: AppLifecycleEvent.paused,
        timestamp: _lastPausedTime!,
      ),
    );
  }

  void _scheduleMidnightCheck() {
    _midnightTimer?.cancel();

    final durationUntilMidnight = DateTimeUtils.durationUntilMidnight;

    // Add a small buffer to ensure we're past midnight
    final scheduledDuration =
        durationUntilMidnight + const Duration(seconds: 5);

    debugPrint(
      'AppLifecycleService: Scheduling midnight check in '
      '${scheduledDuration.inMinutes} minutes',
    );

    _midnightTimer = Timer(scheduledDuration, _onMidnight);
  }

  void _onMidnight() {
    debugPrint('AppLifecycleService: Midnight crossed');

    _eventController.add(
      LifecycleEventData(
        event: AppLifecycleEvent.midnightCrossed,
        timestamp: DateTime.now(),
      ),
    );

    // Schedule next midnight check
    _scheduleMidnightCheck();
  }
}

/// Provider for the app lifecycle service.
final appLifecycleServiceProvider = Provider<AppLifecycleService>((ref) {
  final service = AppLifecycleService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for lifecycle events stream.
final lifecycleEventsProvider = StreamProvider<LifecycleEventData>((ref) {
  final service = ref.watch(appLifecycleServiceProvider);
  return service.eventStream;
});

/// Provider that indicates if midnight has crossed since last check.
///
/// Useful for triggering streak recalculation.
final midnightCrossedProvider = Provider<bool>((ref) {
  final asyncValue = ref.watch(lifecycleEventsProvider);
  return asyncValue.maybeWhen(
    data: (event) => event.event == AppLifecycleEvent.midnightCrossed,
    orElse: () => false,
  );
});
