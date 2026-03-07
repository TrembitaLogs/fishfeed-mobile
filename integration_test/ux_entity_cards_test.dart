import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:fishfeed/presentation/screens/aquarium/aquarium_edit_screen.dart';
import 'package:fishfeed/presentation/screens/aquarium/edit_fish_screen.dart';
import 'package:fishfeed/presentation/screens/feeding/feeding_cards_screen.dart';
import 'package:fishfeed/presentation/widgets/sheets/aquarium_card_sheet.dart';
import 'package:fishfeed/presentation/widgets/feeding/fish_card_sheet.dart';

import 'helpers/gestures.dart';
import 'helpers/test_app.dart';
import 'helpers/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(tearDownTestApp);

  group('Home — Aquarium Card Interactions', () {
    testWidgets('Swipe left on aquarium card opens AquariumCardSheet',
        (tester) async {
      await initTestApp(tester, seedData: seedDefaultTestData);

      final cardFinder = find.byKey(const Key('aquarium_$testAquariumId'));
      expect(cardFinder, findsOneWidget);

      await swipeLeft(tester, cardFinder);

      expect(find.byType(AquariumCardSheet), findsOneWidget);
    });

    testWidgets('AquariumCardSheet shows aquarium details', (tester) async {
      await initTestApp(tester, seedData: seedDefaultTestData);

      // Open sheet via swipe
      await swipeLeft(
        tester,
        find.byKey(const Key('aquarium_$testAquariumId')),
      );

      // Name
      expect(find.text('Freshwater Tank'), findsWidgets);
      // Water type label
      expect(find.textContaining('Freshwater'), findsWidgets);
      // Capacity
      expect(find.textContaining('120'), findsWidgets);
      // Fish names in the list
      expect(find.text('My Guppy'), findsOneWidget);
      expect(find.text('Neon School'), findsOneWidget);
    });

    testWidgets('Tap fish row in AquariumCardSheet navigates to EditFish',
        (tester) async {
      await initTestApp(tester, seedData: seedDefaultTestData);

      await swipeLeft(
        tester,
        find.byKey(const Key('aquarium_$testAquariumId')),
      );

      // Scroll to make fish row visible, then tap
      await tester.tap(find.text('My Guppy'));
      await tester.pumpAndSettle();

      expect(find.byType(EditFishScreen), findsOneWidget);
    });
  });

  group('Feeding Cards Screen — Navigation & AppBar', () {
    testWidgets('Tap aquarium card navigates to FeedingCardsScreen',
        (tester) async {
      await initTestApp(tester, seedData: seedDefaultTestData);

      await tester.tap(find.byKey(const Key('aquarium_$testAquariumId')));
      await tester.pumpAndSettle();

      expect(find.byType(FeedingCardsScreen), findsOneWidget);
    });

    testWidgets('Tap aquarium name in AppBar opens AquariumCardSheet',
        (tester) async {
      await initTestApp(tester, seedData: seedDefaultTestData);

      // Navigate to feeding cards
      await tester.tap(find.byKey(const Key('aquarium_$testAquariumId')));
      await tester.pumpAndSettle();

      // Tap aquarium name in AppBar (last match — the AppBar title)
      await tester.tap(find.text('Freshwater Tank').last);
      await tester.pumpAndSettle();

      expect(find.byType(AquariumCardSheet), findsOneWidget);
    });

    testWidgets('No gear icon in FeedingCards AppBar', (tester) async {
      await initTestApp(tester, seedData: seedDefaultTestData);

      await tester.tap(find.byKey(const Key('aquarium_$testAquariumId')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings), findsNothing);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
    });
  });

  group('Feeding Cards Screen — Card Interactions', () {
    testWidgets('Swipe left on feeding card opens EditFishScreen',
        (tester) async {
      await initTestApp(tester, seedData: seedDefaultTestData);

      // Navigate to feeding cards
      await tester.tap(find.byKey(const Key('aquarium_$testAquariumId')));
      await tester.pumpAndSettle();

      final feedingCard = find.byKey(const Key('feeding_card_$testScheduleId'));
      expect(feedingCard, findsOneWidget);

      await swipeLeft(tester, feedingCard);

      expect(find.byType(EditFishScreen), findsOneWidget);
    });

    testWidgets('Tap feeding card opens FishCardSheet', (tester) async {
      await initTestApp(tester, seedData: seedDefaultTestData);

      await tester.tap(find.byKey(const Key('aquarium_$testAquariumId')));
      await tester.pumpAndSettle();

      final feedingCard = find.byKey(const Key('feeding_card_$testScheduleId'));
      await tester.tap(feedingCard);
      await tester.pumpAndSettle();

      expect(find.byType(FishCardSheet), findsOneWidget);
    });

    testWidgets('FishCardSheet shows fish details', (tester) async {
      await initTestApp(tester, seedData: seedDefaultTestData);

      await tester.tap(find.byKey(const Key('aquarium_$testAquariumId')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('feeding_card_$testScheduleId')));
      await tester.pumpAndSettle();

      // Fish name
      expect(find.text('My Guppy'), findsWidgets);
      // Notes
      expect(find.text('Loves bloodworms'), findsOneWidget);
      // Food type
      expect(find.textContaining('Flakes'), findsWidgets);
    });

    testWidgets('Mark as Fed hidden for already-fed event', (tester) async {
      await initTestApp(tester, seedData: () async {
        await seedDefaultTestData();
        await seedFedEvent(
          scheduleId: testScheduleId,
          fishId: testFishId,
          aquariumId: testAquariumId,
        );
      });

      await tester.tap(find.byKey(const Key('aquarium_$testAquariumId')));
      await tester.pumpAndSettle();

      // Open the fed card's sheet
      await tester.tap(find.byKey(const Key('feeding_card_$testScheduleId')));
      await tester.pumpAndSettle();

      // "Mark as Fed" button should NOT be visible
      expect(find.textContaining('Mark'), findsNothing);
    });
  });

  group('Edit Screens', () {
    testWidgets('Edit Aquarium has water_type and capacity fields',
        (tester) async {
      await initTestApp(tester, seedData: seedDefaultTestData);

      // Open aquarium card sheet
      await swipeLeft(
        tester,
        find.byKey(const Key('aquarium_$testAquariumId')),
      );

      // Scroll down in the sheet to reveal the Edit button (it's below the fold
      // because the DraggableScrollableSheet's initialChildSize is 0.7).
      await tester.dragUntilVisible(
        find.text('Edit Aquarium'),
        find.byType(ListView).last,
        const Offset(0, -200),
      );

      // Tap Edit Aquarium
      await tester.tap(find.text('Edit Aquarium'));
      await tester.pumpAndSettle();

      expect(find.byType(AquariumEditScreen), findsOneWidget);

      // Water type selector
      expect(find.textContaining('Freshwater'), findsWidgets);
      // Capacity field
      expect(find.textContaining('120'), findsWidgets);
    });

    testWidgets('Edit Fish has notes field and aquarium dropdown',
        (tester) async {
      await initTestApp(tester, seedData: seedDefaultTestData);

      // Navigate to feeding cards, then swipe to edit
      await tester.tap(find.byKey(const Key('aquarium_$testAquariumId')));
      await tester.pumpAndSettle();

      await swipeLeft(
        tester,
        find.byKey(const Key('feeding_card_$testScheduleId')),
      );

      expect(find.byType(EditFishScreen), findsOneWidget);

      // Notes field contains existing notes
      expect(find.text('Loves bloodworms'), findsOneWidget);

      // Aquarium dropdown visible (2 aquariums seeded)
      expect(find.text('Freshwater Tank'), findsWidgets);
    });
  });

  group('Bottom Sheet Behavior', () {
    testWidgets('Sheet closes when dragged down', (tester) async {
      await initTestApp(tester, seedData: seedDefaultTestData);

      // Open sheet
      await swipeLeft(
        tester,
        find.byKey(const Key('aquarium_$testAquariumId')),
      );
      expect(find.byType(AquariumCardSheet), findsOneWidget);

      // Drag the sheet down past the dismiss threshold.
      // DraggableScrollableSheet first shrinks to minChildSize (0.4),
      // then further drag dismisses it entirely.
      await tester.drag(
        find.byType(AquariumCardSheet),
        const Offset(0, 600),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AquariumCardSheet), findsNothing);
    });
  });
}
