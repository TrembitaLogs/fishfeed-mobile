import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/presentation/widgets/notifications/family_feeding_toast.dart';

void main() {
  FeedingEvent createTestEvent({
    String id = 'event_1',
    String? completedBy = 'user_2',
    String? completedByName = 'John',
    String? completedByAvatar,
  }) {
    return FeedingEvent(
      id: id,
      fishId: 'fish_1',
      aquariumId: 'aq1',
      feedingTime: DateTime.now(),
      createdAt: DateTime.now(),
      completedBy: completedBy,
      completedByName: completedByName,
      completedByAvatar: completedByAvatar,
    );
  }

  group('FamilyFeedingToast', () {
    testWidgets('displays feeding completed message', (tester) async {
      final event = createTestEvent(completedByName: 'John');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FamilyFeedingToast(event: event),
          ),
        ),
      );

      expect(find.text('Feeding completed'), findsOneWidget);
    });

    testWidgets('displays user name', (tester) async {
      final event = createTestEvent(completedByName: 'Jane Doe');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FamilyFeedingToast(event: event),
          ),
        ),
      );

      expect(find.text('Jane Doe'), findsOneWidget);
    });

    testWidgets('displays "Family member" when name is null', (tester) async {
      final event = createTestEvent(completedByName: null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FamilyFeedingToast(event: event),
          ),
        ),
      );

      expect(find.text('Family member'), findsOneWidget);
    });

    testWidgets('displays check icon', (tester) async {
      final event = createTestEvent();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FamilyFeedingToast(event: event),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('displays person icon when no avatar', (tester) async {
      final event = createTestEvent(completedByAvatar: null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FamilyFeedingToast(event: event),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('displays dismiss button when callback provided', (tester) async {
      final event = createTestEvent();
      var dismissCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FamilyFeedingToast(
              event: event,
              onDismiss: () => dismissCalled = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissCalled, isTrue);
    });

    testWidgets('does not display dismiss button when no callback', (tester) async {
      final event = createTestEvent();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FamilyFeedingToast(event: event),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('has correct styling', (tester) async {
      final event = createTestEvent();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FamilyFeedingToast(event: event),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(FamilyFeedingToast),
          matching: find.byType(Container).first,
        ),
      );

      expect(container.margin, const EdgeInsets.symmetric(horizontal: 16));
    });
  });

  // Note: FamilyFeedingToastOverlay tests are integration-level tests
  // that require more complex setup with Overlay. The basic widget
  // functionality is tested above in the FamilyFeedingToast group.
  //
  // For full overlay testing, consider running integration tests or
  // using a test harness that properly initializes the Overlay system.
}
