import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/core/constants/levels.dart';

void main() {
  group('UserLevel', () {
    test('should have 4 levels in correct order', () {
      expect(UserLevel.values.length, 4);
      expect(UserLevel.values[0], UserLevel.beginnerAquarist);
      expect(UserLevel.values[1], UserLevel.caretaker);
      expect(UserLevel.values[2], UserLevel.fishMaster);
      expect(UserLevel.values[3], UserLevel.aquariumPro);
    });
  });

  group('UserLevelExtension', () {
    test('displayName returns English names', () {
      expect(UserLevel.beginnerAquarist.displayName, 'Beginner');
      expect(UserLevel.caretaker.displayName, 'Caretaker');
      expect(UserLevel.fishMaster.displayName, 'Master');
      expect(UserLevel.aquariumPro.displayName, 'Pro');
    });

    test('displayNameEn returns English names', () {
      expect(UserLevel.beginnerAquarist.displayNameEn, 'Beginner Aquarist');
      expect(UserLevel.caretaker.displayNameEn, 'Caretaker');
      expect(UserLevel.fishMaster.displayNameEn, 'Fish Master');
      expect(UserLevel.aquariumPro.displayNameEn, 'Aquarium Pro');
    });

    test('minXp returns correct thresholds', () {
      expect(UserLevel.beginnerAquarist.minXp, 0);
      expect(UserLevel.caretaker.minXp, 100);
      expect(UserLevel.fishMaster.minXp, 500);
      expect(UserLevel.aquariumPro.minXp, 2000);
    });

    test('maxXp returns correct upper bounds', () {
      expect(UserLevel.beginnerAquarist.maxXp, 100);
      expect(UserLevel.caretaker.maxXp, 500);
      expect(UserLevel.fishMaster.maxXp, 2000);
      expect(UserLevel.aquariumPro.maxXp, isNull);
    });

    test('nextLevel returns correct next level', () {
      expect(UserLevel.beginnerAquarist.nextLevel, UserLevel.caretaker);
      expect(UserLevel.caretaker.nextLevel, UserLevel.fishMaster);
      expect(UserLevel.fishMaster.nextLevel, UserLevel.aquariumPro);
      expect(UserLevel.aquariumPro.nextLevel, isNull);
    });
  });

  group('LevelConstants.getLevelForXp', () {
    test('returns beginnerAquarist for XP 0-99', () {
      expect(LevelConstants.getLevelForXp(0), UserLevel.beginnerAquarist);
      expect(LevelConstants.getLevelForXp(50), UserLevel.beginnerAquarist);
      expect(LevelConstants.getLevelForXp(99), UserLevel.beginnerAquarist);
    });

    test('returns caretaker for XP 100-499', () {
      expect(LevelConstants.getLevelForXp(100), UserLevel.caretaker);
      expect(LevelConstants.getLevelForXp(250), UserLevel.caretaker);
      expect(LevelConstants.getLevelForXp(499), UserLevel.caretaker);
    });

    test('returns fishMaster for XP 500-1999', () {
      expect(LevelConstants.getLevelForXp(500), UserLevel.fishMaster);
      expect(LevelConstants.getLevelForXp(1000), UserLevel.fishMaster);
      expect(LevelConstants.getLevelForXp(1999), UserLevel.fishMaster);
    });

    test('returns aquariumPro for XP 2000+', () {
      expect(LevelConstants.getLevelForXp(2000), UserLevel.aquariumPro);
      expect(LevelConstants.getLevelForXp(5000), UserLevel.aquariumPro);
      expect(LevelConstants.getLevelForXp(10000), UserLevel.aquariumPro);
    });

    test('handles boundary values correctly', () {
      // Test exact boundaries
      expect(LevelConstants.getLevelForXp(99), UserLevel.beginnerAquarist);
      expect(LevelConstants.getLevelForXp(100), UserLevel.caretaker);
      expect(LevelConstants.getLevelForXp(499), UserLevel.caretaker);
      expect(LevelConstants.getLevelForXp(500), UserLevel.fishMaster);
      expect(LevelConstants.getLevelForXp(1999), UserLevel.fishMaster);
      expect(LevelConstants.getLevelForXp(2000), UserLevel.aquariumPro);
    });
  });

  group('LevelConstants.getXpProgress', () {
    test('returns 0.0 at level start', () {
      expect(LevelConstants.getXpProgress(0), 0.0);
      expect(LevelConstants.getXpProgress(100), 0.0);
      expect(LevelConstants.getXpProgress(500), 0.0);
    });

    test('returns 0.5 at level midpoint', () {
      // beginnerAquarist: 0-99, midpoint = 50
      expect(LevelConstants.getXpProgress(50), closeTo(0.5, 0.01));
      // caretaker: 100-499, midpoint = 300
      expect(LevelConstants.getXpProgress(300), closeTo(0.5, 0.01));
      // fishMaster: 500-1999, midpoint = 1250
      expect(LevelConstants.getXpProgress(1250), closeTo(0.5, 0.01));
    });

    test('returns 1.0 at max level', () {
      expect(LevelConstants.getXpProgress(2000), 1.0);
      expect(LevelConstants.getXpProgress(5000), 1.0);
    });

    test('correctly calculates progress within level', () {
      // In caretaker level (100-500), at 200 XP
      // Progress = (200-100) / (500-100) = 100/400 = 0.25
      expect(LevelConstants.getXpProgress(200), closeTo(0.25, 0.01));

      // In fishMaster level (500-2000), at 1000 XP
      // Progress = (1000-500) / (2000-500) = 500/1500 = 0.333
      expect(LevelConstants.getXpProgress(1000), closeTo(0.333, 0.01));
    });
  });

  group('LevelConstants.getXpToNextLevel', () {
    test('returns correct XP needed for each level', () {
      // From 0 to 100
      expect(LevelConstants.getXpToNextLevel(0), 100);
      expect(LevelConstants.getXpToNextLevel(50), 50);
      expect(LevelConstants.getXpToNextLevel(99), 1);

      // From 100 to 500
      expect(LevelConstants.getXpToNextLevel(100), 400);
      expect(LevelConstants.getXpToNextLevel(300), 200);

      // From 500 to 2000
      expect(LevelConstants.getXpToNextLevel(500), 1500);
      expect(LevelConstants.getXpToNextLevel(1000), 1000);
    });

    test('returns 0 at max level', () {
      expect(LevelConstants.getXpToNextLevel(2000), 0);
      expect(LevelConstants.getXpToNextLevel(5000), 0);
    });
  });

  group('Level thresholds', () {
    test('orderedLevels matches enum order', () {
      expect(LevelConstants.orderedLevels.length, 4);
      expect(LevelConstants.orderedLevels[0], UserLevel.beginnerAquarist);
      expect(LevelConstants.orderedLevels[1], UserLevel.caretaker);
      expect(LevelConstants.orderedLevels[2], UserLevel.fishMaster);
      expect(LevelConstants.orderedLevels[3], UserLevel.aquariumPro);
    });

    test('levelThresholds contains all levels', () {
      expect(LevelConstants.levelThresholds.length, 4);
      expect(LevelConstants.levelThresholds.containsKey(UserLevel.beginnerAquarist), isTrue);
      expect(LevelConstants.levelThresholds.containsKey(UserLevel.caretaker), isTrue);
      expect(LevelConstants.levelThresholds.containsKey(UserLevel.fishMaster), isTrue);
      expect(LevelConstants.levelThresholds.containsKey(UserLevel.aquariumPro), isTrue);
    });
  });
}
