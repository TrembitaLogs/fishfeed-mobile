import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:fishfeed/data/datasources/local/feeding_log_local_ds.dart';
import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/datasources/local/local_datasources_providers.dart';
import 'package:fishfeed/data/datasources/local/schedule_local_ds.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';
import 'package:fishfeed/domain/entities/streak.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

// ============================================================================
// FeedingResult - Sealed class for exhaustive pattern matching
// ============================================================================

/// Result of a feeding action (markAsFed or markAsSkipped).
///
/// Use pattern matching to handle all cases:
/// ```dart
/// switch (result) {
///   case FeedingSuccess(:final log, :final streak):
///     // Handle success
///   case FeedingAlreadyDone(:final scheduledFor, :final message):
///     // Handle conflict - show UI message
/// }
/// ```
sealed class FeedingResult {
  const FeedingResult();
}

/// Successful feeding action result.
///
/// Contains the created [FeedingLogModel] and updated [Streak].
final class FeedingSuccess extends FeedingResult {
  const FeedingSuccess({required this.log, required this.streak});

  /// The feeding log that was created.
  final FeedingLogModel log;

  /// The updated streak after this feeding action.
  final Streak streak;
}

/// Feeding was already done (conflict from server or local duplicate).
///
/// This occurs when:
/// - Another family member already marked this feeding
/// - The same device already has a log for this schedule+date
final class FeedingAlreadyDone extends FeedingResult {
  const FeedingAlreadyDone({required this.scheduledFor, required this.message});

  /// The scheduled time that was already marked.
  final DateTime scheduledFor;

  /// Human-readable message explaining the conflict.
  final String message;
}

// ============================================================================
// FeedingService
// ============================================================================

/// Service for marking feedings as done or skipped.
///
/// Uses the unified sync pipeline: save locally (synced: false) ->
/// ChangeTracker picks it up -> POST /sync -> synced_ids marks as synced.
///
/// Online flow: awaits sync for immediate conflict feedback.
/// Offline flow: fire-and-forget, async conflict via feedingConflictStream.
///
/// Example:
/// ```dart
/// final service = ref.watch(feedingServiceProvider);
/// final result = await service.markAsFed(
///   scheduleId: 'schedule-123',
///   scheduledFor: DateTime(2025, 1, 15, 9, 0),
///   userId: 'user-456',
/// );
///
/// switch (result) {
///   case FeedingSuccess(:final log, :final streak):
///     print('Fed! Streak: ${streak.currentStreak}');
///   case FeedingAlreadyDone(:final message):
///     showSnackBar(message);
/// }
/// ```
class FeedingService {
  FeedingService({
    required FeedingLogLocalDataSource feedingLogLocalDs,
    required ScheduleLocalDataSource scheduleLocalDs,
    required StreakLocalDataSource streakLocalDs,
    required SyncService syncService,
  }) : _feedingLogLocalDs = feedingLogLocalDs,
       _scheduleLocalDs = scheduleLocalDs,
       _streakLocalDs = streakLocalDs,
       _syncService = syncService;

  final FeedingLogLocalDataSource _feedingLogLocalDs;
  final ScheduleLocalDataSource _scheduleLocalDs;
  final StreakLocalDataSource _streakLocalDs;
  final SyncService _syncService;

  static const _uuid = Uuid();

  /// Marks a scheduled feeding as fed.
  ///
  /// [scheduleId] - ID of the schedule being marked.
  /// [scheduledFor] - The scheduled date/time for this feeding.
  /// [userId] - ID of the user performing the action.
  /// [userDisplayName] - Optional display name for family mode attribution.
  /// [notes] - Optional notes about this feeding.
  ///
  /// Returns [FeedingSuccess] with the created log and updated streak,
  /// or [FeedingAlreadyDone] if this feeding was already marked.
  Future<FeedingResult> markAsFed({
    required String scheduleId,
    required DateTime scheduledFor,
    required String userId,
    String? userDisplayName,
    String? notes,
  }) async {
    return _markFeeding(
      scheduleId: scheduleId,
      scheduledFor: scheduledFor,
      userId: userId,
      userDisplayName: userDisplayName,
      notes: notes,
      action: 'fed',
    );
  }

  /// Marks a scheduled feeding as skipped.
  ///
  /// [scheduleId] - ID of the schedule being marked.
  /// [scheduledFor] - The scheduled date/time for this feeding.
  /// [userId] - ID of the user performing the action.
  /// [userDisplayName] - Optional display name for family mode attribution.
  /// [notes] - Optional notes about why it was skipped.
  ///
  /// Returns [FeedingSuccess] with the created log and updated streak,
  /// or [FeedingAlreadyDone] if this feeding was already marked.
  Future<FeedingResult> markAsSkipped({
    required String scheduleId,
    required DateTime scheduledFor,
    required String userId,
    String? userDisplayName,
    String? notes,
  }) async {
    return _markFeeding(
      scheduleId: scheduleId,
      scheduledFor: scheduledFor,
      userId: userId,
      userDisplayName: userDisplayName,
      notes: notes,
      action: 'skipped',
    );
  }

  /// Internal method to mark a feeding with the given action.
  Future<FeedingResult> _markFeeding({
    required String scheduleId,
    required DateTime scheduledFor,
    required String userId,
    String? userDisplayName,
    String? notes,
    required String action,
  }) async {
    // 1. Check if already logged locally
    if (_feedingLogLocalDs.hasLogForScheduleAndDate(scheduleId, scheduledFor)) {
      return FeedingAlreadyDone(
        scheduledFor: scheduledFor,
        message: 'This feeding has already been marked.',
      );
    }

    // 2. Get schedule to retrieve aquariumId and fishId
    final schedule = _scheduleLocalDs.getById(scheduleId);
    if (schedule == null) {
      return FeedingAlreadyDone(
        scheduledFor: scheduledFor,
        message: 'Schedule not found.',
      );
    }

    // 3. Get device ID for conflict detection
    final deviceId = await HiveBoxes.getDeviceId();

    // 4. Create FeedingLogModel
    final now = DateTime.now();
    final logId = _uuid.v4();

    final log = FeedingLogModel(
      id: logId,
      scheduleId: scheduleId,
      fishId: schedule.fishId,
      aquariumId: schedule.aquariumId,
      scheduledFor: scheduledFor,
      action: action,
      actedAt: now.toUtc(),
      actedByUserId: userId,
      actedByUserName: userDisplayName,
      deviceId: deviceId,
      notes: notes,
      createdAt: now,
      synced: false,
    );

    // 5. Save to Hive (synced: false -> ChangeTracker will pick it up)
    await _feedingLogLocalDs.save(log);

    // 6. Trigger sync
    if (_syncService.isOnline && !_syncService.isProcessing) {
      // Online: await sync for immediate conflict feedback
      final syncResult = await _syncService.syncAllWithResult();

      // Check if our entity was involved in a conflict
      final ourConflict = syncResult.conflicts.where(
        (c) => c.entityId == logId && c.entityType == 'feeding_log',
      );

      if (ourConflict.isNotEmpty) {
        final conflict = ourConflict.first;
        final actedByName = conflict.serverVersion['acted_by_user_name']
            ?.toString();
        final message = actedByName != null
            ? 'This feeding was already marked by $actedByName.'
            : 'This feeding was already marked by another family member.';

        return FeedingAlreadyDone(scheduledFor: scheduledFor, message: message);
      }
    } else {
      // Offline or sync busy: fire-and-forget, conflicts handled via stream
      unawaited(_syncService.syncNow().then((_) {}));
    }

    // 7. Update streak
    final updatedStreak = await _updateStreak(userId, action, now);

    return FeedingSuccess(log: log, streak: updatedStreak);
  }

  /// Updates the user's streak based on the feeding action.
  Future<Streak> _updateStreak(
    String userId,
    String action,
    DateTime feedingDate,
  ) async {
    if (action == 'fed') {
      // Increment streak for successful feeding
      final streakModel = await _streakLocalDs.incrementStreak(
        userId,
        feedingDate,
      );
      return streakModel.toEntity();
    } else {
      // Skipped - don't reset streak, just return current
      // Streak only resets when a day is completely missed (handled elsewhere)
      final existingStreak = _streakLocalDs.getStreakByUserId(userId);
      if (existingStreak != null) {
        return existingStreak.toEntity();
      }
      // No streak exists yet
      return Streak(
        id: 'streak_$userId',
        userId: userId,
        currentStreak: 0,
        longestStreak: 0,
      );
    }
  }
}

// ============================================================================
// Riverpod Providers
// ============================================================================

/// Provider for [FeedingService].
///
/// Usage:
/// ```dart
/// final feedingService = ref.watch(feedingServiceProvider);
/// final result = await feedingService.markAsFed(...);
/// ```
final feedingServiceProvider = Provider<FeedingService>((ref) {
  return FeedingService(
    feedingLogLocalDs: ref.watch(feedingLogLocalDataSourceProvider),
    scheduleLocalDs: ref.watch(scheduleLocalDataSourceProvider),
    streakLocalDs: ref.watch(streakLocalDataSourceProvider),
    syncService: ref.watch(syncServiceProvider),
  );
});
