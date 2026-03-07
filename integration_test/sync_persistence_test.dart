import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:fishfeed/data/datasources/local/hive_boxes.dart';
import 'package:fishfeed/domain/entities/water_type.dart';

import 'helpers/test_app.dart';
import 'helpers/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(tearDownTestApp);

  group('Sync Persistence — Hive Data', () {
    testWidgets('Aquarium with water_type and capacity persists in Hive',
        (tester) async {
      await initTestApp(tester, seedData: seedDefaultTestData);

      // Verify seeded aquarium persists with all fields
      final aquarium = HiveBoxes.aquariums.get(testAquariumId);
      expect(aquarium, isNotNull);
      expect(aquarium!.name, 'Freshwater Tank');
      expect(aquarium.waterType, WaterType.freshwater);
      expect(aquarium.capacity, 120.0);

      // Verify second aquarium
      final aquarium2 = HiveBoxes.aquariums.get(testAquarium2Id);
      expect(aquarium2, isNotNull);
      expect(aquarium2!.waterType, WaterType.saltwater);
      expect(aquarium2.capacity, 200.0);
    });

    testWidgets('Fish with notes persists in Hive', (tester) async {
      await initTestApp(tester, seedData: seedDefaultTestData);

      final fish = HiveBoxes.fish.get(testFishId);
      expect(fish, isNotNull);
      expect(fish!.name, 'My Guppy');
      expect(fish.notes, 'Loves bloodworms');
      expect(fish.quantity, 5);
      expect(fish.aquariumId, testAquariumId);
    });

    testWidgets('Update fish notes persists in Hive', (tester) async {
      await initTestApp(tester, seedData: seedDefaultTestData);

      // Directly update the fish model in Hive (simulating save)
      final fish = HiveBoxes.fish.get(testFishId)!;
      fish.notes = 'Updated: now loves brine shrimp';
      fish.synced = false;
      fish.updatedAt = DateTime.now();
      await HiveBoxes.fish.put(testFishId, fish);

      // Verify update persisted
      final updated = HiveBoxes.fish.get(testFishId)!;
      expect(updated.notes, 'Updated: now loves brine shrimp');
      expect(updated.synced, isFalse);
    });

    testWidgets('Move fish between aquariums updates aquariumId in Hive',
        (tester) async {
      await initTestApp(tester, seedData: seedDefaultTestData);

      // Verify initial state
      final before = HiveBoxes.fish.get(testFishId)!;
      expect(before.aquariumId, testAquariumId);

      // Move fish to aquarium 2
      before.aquariumId = testAquarium2Id;
      before.synced = false;
      before.updatedAt = DateTime.now();
      await HiveBoxes.fish.put(testFishId, before);

      // Verify move persisted
      final after = HiveBoxes.fish.get(testFishId)!;
      expect(after.aquariumId, testAquarium2Id);
      expect(after.synced, isFalse);

      // Fish no longer in aquarium 1's list
      final fishInAq1 =
          HiveBoxes.fish.values
              .where(
                (f) =>
                    f.aquariumId == testAquariumId &&
                    f.id == testFishId &&
                    f.deletedAt == null,
              )
              .toList();
      expect(fishInAq1, isEmpty);
    });
  });
}
