import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/datasources/local/feeding_local_ds.dart';
import 'package:fishfeed/data/datasources/local/streak_local_ds.dart';
import 'package:fishfeed/data/datasources/local/sync_queue_ds.dart';
import 'package:fishfeed/data/models/feeding_event_model.dart';
import 'package:fishfeed/data/models/streak_model.dart';
import 'package:fishfeed/data/models/sync_operation_model.dart';
import 'package:fishfeed/domain/entities/feeding_status.dart';
import 'package:fishfeed/domain/usecases/mark_feeding_usecase.dart';

class MockFeedingLocalDataSource extends Mock implements FeedingLocalDataSource {
}

class MockStreakLocalDataSource extends Mock implements StreakLocalDataSource {}

class MockSyncQueueDataSource extends Mock implements SyncQueueDataSource {}

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  late MockFeedingLocalDataSource mockFeedingDs;
  late MockStreakLocalDataSource mockStreakDs;
  late MockSyncQueueDataSource mockSyncQueueDs;
  late MarkFeedingUseCase useCase;

  setUpAll(() {
    registerFallbackValue(FeedingEventModel(
      id: 'test',
      fishId: 'fish',
      aquariumId: 'aquarium',
      feedingTime: DateTime.now(),
      synced: false,
      createdAt: DateTime.now(),
    ));
    registerFallbackValue(SyncOperationModel(
      id: 'test',
      operationType: SyncOperationType.create,
      entityType: 'feeding_event',
      entityId: 'test',
      payload: '{}',
      timestamp: DateTime.now(),
    ));
  });

  setUp(() {
    mockFeedingDs = MockFeedingLocalDataSource();
    mockStreakDs = MockStreakLocalDataSource();
    mockSyncQueueDs = MockSyncQueueDataSource();
    useCase = MarkFeedingUseCase(
      feedingDataSource: mockFeedingDs,
      streakDataSource: mockStreakDs,
      syncQueueDataSource: mockSyncQueueDs,
    );
  });

  StreakModel createTestStreak({
    String userId = 'user_1',
    int currentStreak = 5,
    int longestStreak = 10,
    DateTime? lastFeedingDate,
  }) {
    return StreakModel(
      id: 'streak_$userId',
      userId: userId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastFeedingDate: lastFeedingDate ?? DateTime(2025, 6, 15),
      streakStartDate: DateTime(2025, 6, 10),
    );
  }

  group('MarkFeedingUseCase', () {
    group('Validation', () {
      test('should return ValidationFailure when scheduledFeedingId is empty',
          () async {
        final result = await useCase(const MarkFeedingParams(
          scheduledFeedingId: '',
          newStatus: FeedingStatus.fed,
          userId: 'user_1',
          aquariumId: 'aquarium_1',
        ));

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            final validationFailure = failure as ValidationFailure;
            expect(
                validationFailure.errors['scheduledFeedingId'], isNotEmpty);
          },
          (_) => fail('Should be Left'),
        );
      });

      test('should return ValidationFailure when userId is empty', () async {
        final result = await useCase(const MarkFeedingParams(
          scheduledFeedingId: 'feeding_1',
          newStatus: FeedingStatus.fed,
          userId: '',
          aquariumId: 'aquarium_1',
        ));

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            final validationFailure = failure as ValidationFailure;
            expect(validationFailure.errors['userId'], isNotEmpty);
          },
          (_) => fail('Should be Left'),
        );
      });

      test('should return ValidationFailure when aquariumId is empty', () async {
        final result = await useCase(const MarkFeedingParams(
          scheduledFeedingId: 'feeding_1',
          newStatus: FeedingStatus.fed,
          userId: 'user_1',
          aquariumId: '',
        ));

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            final validationFailure = failure as ValidationFailure;
            expect(validationFailure.errors['aquariumId'], isNotEmpty);
          },
          (_) => fail('Should be Left'),
        );
      });

      test('should return ValidationFailure when status is pending', () async {
        final result = await useCase(const MarkFeedingParams(
          scheduledFeedingId: 'feeding_1',
          newStatus: FeedingStatus.pending,
          userId: 'user_1',
          aquariumId: 'aquarium_1',
        ));

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            final validationFailure = failure as ValidationFailure;
            expect(validationFailure.errors['newStatus'], isNotEmpty);
          },
          (_) => fail('Should be Left'),
        );
      });
    });

    group('Mark as Fed', () {
      test('should create FeedingEvent when marking as fed', () async {
        final streak = createTestStreak();
        when(() => mockFeedingDs.createFeedingEvent(any()))
            .thenAnswer((_) async {});
        when(() => mockSyncQueueDs.addToQueue(any()))
            .thenAnswer((_) async {});
        when(() => mockStreakDs.incrementStreak(any(), any()))
            .thenAnswer((_) async => streak);

        final result = await useCase(const MarkFeedingParams(
          scheduledFeedingId: 'feeding_1',
          newStatus: FeedingStatus.fed,
          userId: 'user_1',
          aquariumId: 'aquarium_1',
          fishId: 'fish_1',
          amount: 5.0,
          foodType: 'pellets',
        ));

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (markResult) {
            expect(markResult.wasCreated, isTrue);
            expect(markResult.feedingEvent, isNotNull);
            expect(markResult.feedingEvent!.aquariumId, 'aquarium_1');
            expect(markResult.feedingEvent!.fishId, 'fish_1');
            expect(markResult.feedingEvent!.amount, 5.0);
            expect(markResult.feedingEvent!.foodType, 'pellets');
            expect(markResult.feedingEvent!.synced, isFalse);
          },
        );

        verify(() => mockFeedingDs.createFeedingEvent(any())).called(1);
        verify(() => mockSyncQueueDs.addToQueue(any())).called(1);
        verify(() => mockStreakDs.incrementStreak('user_1', any())).called(1);
      });

      test('should use aquariumId as fishId when fishId not provided', () async {
        final streak = createTestStreak();
        when(() => mockFeedingDs.createFeedingEvent(any()))
            .thenAnswer((_) async {});
        when(() => mockSyncQueueDs.addToQueue(any()))
            .thenAnswer((_) async {});
        when(() => mockStreakDs.incrementStreak(any(), any()))
            .thenAnswer((_) async => streak);

        final result = await useCase(const MarkFeedingParams(
          scheduledFeedingId: 'feeding_1',
          newStatus: FeedingStatus.fed,
          userId: 'user_1',
          aquariumId: 'aquarium_1',
        ));

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (markResult) {
            expect(markResult.feedingEvent!.fishId, 'aquarium_1');
          },
        );
      });

      test('should increment streak when marking as fed', () async {
        final streak = createTestStreak(currentStreak: 6);
        when(() => mockFeedingDs.createFeedingEvent(any()))
            .thenAnswer((_) async {});
        when(() => mockSyncQueueDs.addToQueue(any()))
            .thenAnswer((_) async {});
        when(() => mockStreakDs.incrementStreak(any(), any()))
            .thenAnswer((_) async => streak);

        final result = await useCase(const MarkFeedingParams(
          scheduledFeedingId: 'feeding_1',
          newStatus: FeedingStatus.fed,
          userId: 'user_1',
          aquariumId: 'aquarium_1',
        ));

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (markResult) {
            expect(markResult.updatedStreak.currentStreak, 6);
          },
        );
      });

      test('should add to sync queue when marking as fed', () async {
        final streak = createTestStreak();
        when(() => mockFeedingDs.createFeedingEvent(any()))
            .thenAnswer((_) async {});
        when(() => mockSyncQueueDs.addToQueue(any()))
            .thenAnswer((_) async {});
        when(() => mockStreakDs.incrementStreak(any(), any()))
            .thenAnswer((_) async => streak);

        await useCase(const MarkFeedingParams(
          scheduledFeedingId: 'feeding_1',
          newStatus: FeedingStatus.fed,
          userId: 'user_1',
          aquariumId: 'aquarium_1',
        ));

        final captured = verify(() => mockSyncQueueDs.addToQueue(captureAny()))
            .captured
            .single as SyncOperationModel;

        expect(captured.operationType, SyncOperationType.create);
        expect(captured.entityType, 'feeding_event');
        expect(captured.status, SyncOperationStatus.pending);
      });
    });

    group('Mark as Missed', () {
      test('should reset streak when marking as missed', () async {
        final streak = createTestStreak(currentStreak: 0);
        when(() => mockStreakDs.resetStreak(any()))
            .thenAnswer((_) async => streak);

        final result = await useCase(const MarkFeedingParams(
          scheduledFeedingId: 'feeding_1',
          newStatus: FeedingStatus.missed,
          userId: 'user_1',
          aquariumId: 'aquarium_1',
        ));

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (markResult) {
            expect(markResult.wasCreated, isFalse);
            expect(markResult.feedingEvent, isNull);
            expect(markResult.updatedStreak.currentStreak, 0);
          },
        );

        verify(() => mockStreakDs.resetStreak('user_1')).called(1);
        verifyNever(() => mockFeedingDs.createFeedingEvent(any()));
        verifyNever(() => mockSyncQueueDs.addToQueue(any()));
      });

      test('should create default streak when none exists and marking as missed',
          () async {
        when(() => mockStreakDs.resetStreak(any()))
            .thenAnswer((_) async => null);

        final result = await useCase(const MarkFeedingParams(
          scheduledFeedingId: 'feeding_1',
          newStatus: FeedingStatus.missed,
          userId: 'user_1',
          aquariumId: 'aquarium_1',
        ));

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Should be Right'),
          (markResult) {
            expect(markResult.updatedStreak.userId, 'user_1');
            expect(markResult.updatedStreak.currentStreak, 0);
          },
        );
      });
    });

    group('Error Handling', () {
      test('should return CacheFailure when datasource throws exception',
          () async {
        when(() => mockFeedingDs.createFeedingEvent(any()))
            .thenThrow(Exception('Hive error'));

        final result = await useCase(const MarkFeedingParams(
          scheduledFeedingId: 'feeding_1',
          newStatus: FeedingStatus.fed,
          userId: 'user_1',
          aquariumId: 'aquarium_1',
        ));

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<CacheFailure>());
            expect(failure.message, contains('Failed to mark feeding'));
          },
          (_) => fail('Should be Left'),
        );
      });
    });
  });
}
