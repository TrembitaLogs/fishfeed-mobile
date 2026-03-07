import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/data/models/aquarium_model.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';
import 'package:fishfeed/data/models/fish_model.dart';
import 'package:fishfeed/data/models/schedule_model.dart';
import 'package:fishfeed/data/models/species_model.dart';
import 'package:fishfeed/data/models/user_model.dart';
import 'package:fishfeed/domain/entities/water_type.dart';

// Test data constants
const testUserId = 'test-user-123';
const testAquariumId = 'aquarium-001';
const testAquarium2Id = 'aquarium-002';
const testFishId = 'fish-001';
const testFish2Id = 'fish-002';
const testScheduleId = 'schedule-001';
const testSchedule2Id = 'schedule-002';
const testSpeciesId = 'guppy';
const testSpecies2Id = 'neon-tetra';

/// Seeds the default test data into Hive boxes.
///
/// Creates: 1 user, 2 aquariums, 2 fish with notes, 2 daily schedules,
/// 2 species entries. No feeding logs (events appear as pending).
Future<void> seedDefaultTestData() async {
  // User — store under 'current_user' key (AuthLocalDataSource looks it up
  // by this key) and under user ID for other datasources.
  // Hive requires distinct object instances per key.
  await HiveBoxes.users.put(
    'current_user',
    UserModel(
      id: testUserId,
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: DateTime(2024, 1, 15),
    ),
  );
  await HiveBoxes.users.put(
    testUserId,
    UserModel(
      id: testUserId,
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: DateTime(2024, 1, 15),
    ),
  );

  // Aquariums
  await HiveBoxes.aquariums.put(
    testAquariumId,
    AquariumModel(
      id: testAquariumId,
      userId: testUserId,
      name: 'Freshwater Tank',
      waterType: WaterType.freshwater,
      capacity: 120.0,
      createdAt: DateTime(2024, 1, 20),
      synced: true,
    ),
  );

  await HiveBoxes.aquariums.put(
    testAquarium2Id,
    AquariumModel(
      id: testAquarium2Id,
      userId: testUserId,
      name: 'Saltwater Reef',
      waterType: WaterType.saltwater,
      capacity: 200.0,
      createdAt: DateTime(2024, 2, 1),
      synced: true,
    ),
  );

  // Species
  await HiveBoxes.species.put(
    testSpeciesId,
    SpeciesModel(id: testSpeciesId, name: 'Guppy'),
  );

  await HiveBoxes.species.put(
    testSpecies2Id,
    SpeciesModel(id: testSpecies2Id, name: 'Neon Tetra'),
  );

  // Fish
  await HiveBoxes.fish.put(
    testFishId,
    FishModel(
      id: testFishId,
      aquariumId: testAquariumId,
      speciesId: testSpeciesId,
      name: 'My Guppy',
      quantity: 5,
      notes: 'Loves bloodworms',
      addedAt: DateTime(2024, 1, 25),
      synced: true,
    ),
  );

  await HiveBoxes.fish.put(
    testFish2Id,
    FishModel(
      id: testFish2Id,
      aquariumId: testAquariumId,
      speciesId: testSpecies2Id,
      name: 'Neon School',
      quantity: 10,
      addedAt: DateTime(2024, 2, 5),
      synced: true,
    ),
  );

  // Schedules (daily, anchored 30 days ago so they fire today)
  final now = DateTime.now();
  final anchor = DateTime(now.year, now.month, now.day)
      .subtract(const Duration(days: 30));

  await HiveBoxes.schedules.put(
    testScheduleId,
    ScheduleModel(
      id: testScheduleId,
      fishId: testFishId,
      aquariumId: testAquariumId,
      time: '09:00',
      intervalDays: 1,
      anchorDate: anchor,
      foodType: 'Flakes',
      portionHint: '2 pinches',
      active: true,
      createdAt: DateTime(2024, 1, 25),
      updatedAt: DateTime(2024, 1, 25),
      createdByUserId: testUserId,
      synced: true,
    ),
  );

  await HiveBoxes.schedules.put(
    testSchedule2Id,
    ScheduleModel(
      id: testSchedule2Id,
      fishId: testFish2Id,
      aquariumId: testAquariumId,
      time: '18:00',
      intervalDays: 1,
      anchorDate: anchor,
      foodType: 'Pellets',
      active: true,
      createdAt: DateTime(2024, 2, 5),
      updatedAt: DateTime(2024, 2, 5),
      createdByUserId: testUserId,
      synced: true,
    ),
  );

  // Mark onboarding as completed
  await HiveBoxes.setOnboardingCompleted(true);
}

/// Seeds a feeding log marking [scheduleId] as fed for today.
Future<void> seedFedEvent({
  required String scheduleId,
  required String fishId,
  required String aquariumId,
}) async {
  final now = DateTime.now();
  final today9am = DateTime(now.year, now.month, now.day, 9, 0);

  await HiveBoxes.feedingLogs.put(
    'fed-log-$scheduleId',
    FeedingLogModel(
      id: 'fed-log-$scheduleId',
      scheduleId: scheduleId,
      fishId: fishId,
      aquariumId: aquariumId,
      scheduledFor: today9am,
      action: 'fed',
      actedAt: now.toUtc(),
      actedByUserId: testUserId,
      actedByUserName: 'Test User',
      deviceId: 'test-device',
      createdAt: now,
      synced: true,
    ),
  );
}

/// Seeds an aquarium owned by a different user (for Family Mode tests).
Future<void> seedNonOwnerAquarium() async {
  await HiveBoxes.aquariums.put(
    'aquarium-other',
    AquariumModel(
      id: 'aquarium-other',
      userId: 'other-user-999',
      name: 'Other Tank',
      waterType: WaterType.freshwater,
      capacity: 50.0,
      createdAt: DateTime(2024, 3, 1),
      synced: true,
    ),
  );
}
