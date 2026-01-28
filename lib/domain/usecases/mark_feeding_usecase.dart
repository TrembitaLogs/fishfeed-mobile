import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/data/datasources/local/sync_queue_ds.dart';
import 'package:fishfeed/data/models/feeding_event_model.dart';
import 'package:fishfeed/data/models/sync_operation_model.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/domain/entities/feeding_status.dart';
import 'package:fishfeed/domain/entities/streak.dart';

/// Parameters for [MarkFeedingUseCase].
class MarkFeedingParams {
  const MarkFeedingParams({
    required this.scheduledFeedingId,
    required this.newStatus,
    required this.userId,
    required this.aquariumId,
    this.fishId,
    this.amount,
    this.foodType,
    this.notes,
    this.userDisplayName,
    this.userAvatarUrl,
  });

  /// ID of the scheduled feeding being marked.
  final String scheduledFeedingId;

  /// New status to set (fed or missed).
  final FeedingStatus newStatus;

  /// ID of the user performing the action.
  final String userId;

  /// ID of the aquarium for this feeding.
  final String aquariumId;

  /// ID of the specific fish (optional).
  final String? fishId;

  /// Amount of food given in grams (optional, for fed status).
  final double? amount;

  /// Type of food used (optional, for fed status).
  final String? foodType;

  /// Additional notes (optional).
  final String? notes;

  /// Display name of the user (for family mode attribution).
  final String? userDisplayName;

  /// Avatar URL of the user (for family mode attribution).
  final String? userAvatarUrl;
}

/// Result of marking a feeding.
class MarkFeedingResult {
  const MarkFeedingResult({
    this.feedingEvent,
    required this.updatedStreak,
    required this.wasCreated,
  });

  /// The feeding event created (only for fed status).
  final FeedingEvent? feedingEvent;

  /// The updated streak after marking.
  final Streak updatedStreak;

  /// Whether a new feeding event was created.
  final bool wasCreated;
}

/// Use case for marking a scheduled feeding as fed or missed.
///
/// When marked as fed:
/// - Creates a new FeedingEvent record in Hive
/// - Updates the user's streak (increment if all today's feedings are done)
/// - Adds the operation to sync queue for offline support
///
/// When marked as missed:
/// - Resets the user's streak to 0
/// - Does not create a FeedingEvent (no feeding occurred)
///
/// Returns [Right(MarkFeedingResult)] on success.
/// Returns [Left(Failure)] on error.
class MarkFeedingUseCase {
  MarkFeedingUseCase({
    required FeedingLocalDataSource feedingDataSource,
    required StreakLocalDataSource streakDataSource,
    required SyncQueueDataSource syncQueueDataSource,
  }) : _feedingDataSource = feedingDataSource,
       _streakDataSource = streakDataSource,
       _syncQueueDataSource = syncQueueDataSource;

  final FeedingLocalDataSource _feedingDataSource;
  final StreakLocalDataSource _streakDataSource;
  final SyncQueueDataSource _syncQueueDataSource;

  final _uuid = const Uuid();

  /// Executes the mark feeding use case.
  Future<Either<Failure, MarkFeedingResult>> call(
    MarkFeedingParams params,
  ) async {
    // Validate params
    final validationError = _validate(params);
    if (validationError != null) {
      return Left(validationError);
    }

    try {
      FeedingEvent? feedingEvent;
      Streak updatedStreak;
      bool wasCreated = false;

      if (params.newStatus == FeedingStatus.fed) {
        // Create FeedingEvent for fed status
        final now = DateTime.now();
        final eventId = _uuid.v4();

        feedingEvent = FeedingEvent(
          id: eventId,
          fishId: params.fishId ?? params.aquariumId,
          aquariumId: params.aquariumId,
          feedingTime: now,
          amount: params.amount,
          foodType: params.foodType,
          notes: params.notes,
          synced: false,
          createdAt: now,
          localId: eventId,
          completedBy: params.userId,
          completedByName: params.userDisplayName,
          completedByAvatar: params.userAvatarUrl,
        );

        // Save to Hive
        final model = FeedingEventModel.fromEntity(feedingEvent);
        await _feedingDataSource.createFeedingEvent(model);
        wasCreated = true;

        // Add to sync queue
        await _addToSyncQueue(feedingEvent);

        // Update streak - increment for successful feeding
        final streakModel = await _streakDataSource.incrementStreak(
          params.userId,
          now,
        );
        updatedStreak = streakModel.toEntity();
      } else if (params.newStatus == FeedingStatus.missed) {
        // Reset streak for missed feeding
        final streakModel = await _streakDataSource.resetStreak(params.userId);

        if (streakModel != null) {
          updatedStreak = streakModel.toEntity();
        } else {
          // Create a new streak with 0 count if none exists
          updatedStreak = Streak(
            id: 'streak_${params.userId}',
            userId: params.userId,
            currentStreak: 0,
            longestStreak: 0,
          );
        }
      } else {
        // Pending status - no action needed
        final existingStreak = _streakDataSource.getStreakByUserId(
          params.userId,
        );
        updatedStreak =
            existingStreak?.toEntity() ??
            Streak(id: 'streak_${params.userId}', userId: params.userId);
      }

      return Right(
        MarkFeedingResult(
          feedingEvent: feedingEvent,
          updatedStreak: updatedStreak,
          wasCreated: wasCreated,
        ),
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to mark feeding: $e'));
    }
  }

  /// Adds a feeding event to the sync queue.
  Future<void> _addToSyncQueue(FeedingEvent event) async {
    final payload = jsonEncode({
      'id': event.id,
      'fishId': event.fishId,
      'aquariumId': event.aquariumId,
      'feedingTime': event.feedingTime.toIso8601String(),
      'amount': event.amount,
      'foodType': event.foodType,
      'notes': event.notes,
      'createdAt': event.createdAt.toIso8601String(),
      'localId': event.localId,
      'completedBy': event.completedBy,
      'completedByName': event.completedByName,
      'completedByAvatar': event.completedByAvatar,
    });

    final operation = SyncOperationModel(
      id: _uuid.v4(),
      operationType: SyncOperationType.create,
      entityType: 'feeding_event',
      entityId: event.id,
      payload: payload,
      timestamp: DateTime.now(),
    );

    await _syncQueueDataSource.addToQueue(operation);
  }

  /// Validates mark feeding parameters.
  ValidationFailure? _validate(MarkFeedingParams params) {
    final errors = <String, List<String>>{};

    if (params.scheduledFeedingId.isEmpty) {
      errors['scheduledFeedingId'] = ['Scheduled feeding ID is required'];
    }

    if (params.userId.isEmpty) {
      errors['userId'] = ['User ID is required'];
    }

    if (params.aquariumId.isEmpty) {
      errors['aquariumId'] = ['Aquarium ID is required'];
    }

    if (params.newStatus == FeedingStatus.pending) {
      errors['newStatus'] = ['Cannot mark feeding as pending'];
    }

    if (errors.isNotEmpty) {
      return ValidationFailure(errors: errors);
    }

    return null;
  }
}
