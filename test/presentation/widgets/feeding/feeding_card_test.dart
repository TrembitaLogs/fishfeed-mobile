import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/domain/entities/feeding_status.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/domain/entities/scheduled_feeding.dart';
import 'package:fishfeed/presentation/widgets/feeding/feeding_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  ScheduledFeeding createFeeding({
    String id = '1',
    FeedingStatus status = FeedingStatus.pending,
    String speciesName = 'Guppy',
    String aquariumName = 'Living Room Tank',
    String? foodType = 'Flakes',
    int hour = 14,
    String? completedBy,
    String? completedByName,
    String? completedByAvatar,
  }) {
    return ScheduledFeeding(
      id: id,
      scheduledTime: today.add(Duration(hours: hour)),
      aquariumId: 'aq1',
      aquariumName: aquariumName,
      speciesName: speciesName,
      status: status,
      foodType: foodType,
      portionGrams: 0.5,
      completedBy: completedBy,
      completedByName: completedByName,
      completedByAvatar: completedByAvatar,
    );
  }

  Widget buildTestWidget({
    required ScheduledFeeding feeding,
    FeedingStatusCallback? onMarkAsFed,
    FeedingStatusCallback? onMarkAsMissed,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: FeedingCard(
            feeding: feeding,
            onMarkAsFed: onMarkAsFed ?? (_) {},
            onMarkAsMissed: onMarkAsMissed ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('FeedingCard', () {
    group('Display', () {
      testWidgets('displays species name', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(speciesName: 'Betta'),
        ));

        expect(find.text('Betta'), findsOneWidget);
      });

      testWidgets('displays aquarium name', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(aquariumName: 'Bedroom Tank'),
        ));

        expect(find.text('Bedroom Tank'), findsOneWidget);
      });

      testWidgets('displays food type when provided', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(foodType: 'Pellets'),
        ));

        expect(find.text('Pellets'), findsOneWidget);
      });

      testWidgets('displays formatted time', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(hour: 8),
        ));

        expect(find.text('08:00'), findsOneWidget);
      });

      testWidgets('displays touch hint icon for pending status', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(status: FeedingStatus.pending),
        ));

        expect(find.byIcon(Icons.touch_app_outlined), findsOneWidget);
      });

      testWidgets('does not display touch hint for fed status', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(status: FeedingStatus.fed),
        ));

        expect(find.byIcon(Icons.touch_app_outlined), findsNothing);
      });

      testWidgets('does not display touch hint for missed status', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(status: FeedingStatus.missed),
        ));

        expect(find.byIcon(Icons.touch_app_outlined), findsNothing);
      });
    });

    group('Status Indicators', () {
      testWidgets('displays check icon for fed status', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(status: FeedingStatus.fed),
        ));

        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('displays schedule icon for pending status', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(status: FeedingStatus.pending),
        ));

        expect(find.byIcon(Icons.schedule), findsOneWidget);
      });

      testWidgets('displays close icon for missed status', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(status: FeedingStatus.missed),
        ));

        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('applies strikethrough to title for fed status', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(status: FeedingStatus.fed, speciesName: 'Guppy'),
        ));

        final titleFinder = find.text('Guppy');
        final titleWidget = tester.widget<Text>(titleFinder);

        expect(titleWidget.style?.decoration, TextDecoration.lineThrough);
      });

      testWidgets('does not apply strikethrough for pending status', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(status: FeedingStatus.pending, speciesName: 'Guppy'),
        ));

        final titleFinder = find.text('Guppy');
        final titleWidget = tester.widget<Text>(titleFinder);

        expect(titleWidget.style?.decoration, isNot(TextDecoration.lineThrough));
      });
    });

    group('One-tap Interaction', () {
      testWidgets('calls onMarkAsFed when tapping pending card', (tester) async {
        String? markedId;

        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(id: 'test-123', status: FeedingStatus.pending),
          onMarkAsFed: (id) => markedId = id,
        ));

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(markedId, equals('test-123'));
      });

      testWidgets('does not call onMarkAsFed when tapping fed card', (tester) async {
        var wasCalled = false;

        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(status: FeedingStatus.fed),
          onMarkAsFed: (_) => wasCalled = true,
        ));

        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(wasCalled, isFalse);
      });

      testWidgets('does not call onMarkAsFed when tapping missed card', (tester) async {
        var wasCalled = false;

        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(status: FeedingStatus.missed),
          onMarkAsFed: (_) => wasCalled = true,
        ));

        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(wasCalled, isFalse);
      });

      testWidgets('shows success snackbar when marking as fed', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(status: FeedingStatus.pending, speciesName: 'Betta'),
        ));

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.text('Betta - Feeding completed!'), findsOneWidget);
      });
    });

    group('Swipe Actions', () {
      testWidgets('contains Dismissible widget', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(),
        ));

        expect(find.byType(Dismissible), findsOneWidget);
      });

      testWidgets('dismissible allows horizontal swipe', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(status: FeedingStatus.pending),
        ));

        final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
        expect(dismissible.direction, DismissDirection.horizontal);
      });

      testWidgets('dismissible has unique key per feeding', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(id: 'unique-123'),
        ));

        final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
        expect(dismissible.key, equals(const Key('feeding_card_unique-123')));
      });

      testWidgets('dismissible has background widget', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(status: FeedingStatus.pending),
        ));

        final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
        expect(dismissible.background, isNotNull);
      });

      testWidgets('dismissible has secondary background widget', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(status: FeedingStatus.pending),
        ));

        final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
        expect(dismissible.secondaryBackground, isNotNull);
      });

      testWidgets('dismissible has confirmDismiss callback', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(status: FeedingStatus.pending),
        ));

        final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
        expect(dismissible.confirmDismiss, isNotNull);
      });
    });

    group('Accessibility', () {
      testWidgets('InkWell is present for tap interaction', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(status: FeedingStatus.pending),
        ));

        expect(find.byType(InkWell), findsOneWidget);
      });

      testWidgets('Card is present', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(),
        ));

        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('Fed By Attribution', () {
      testWidgets('displays Fed by label for completed feeding with user name',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(
            status: FeedingStatus.fed,
            completedBy: 'user-123',
            completedByName: 'John',
          ),
        ));

        expect(find.text('John'), findsOneWidget);
      });

      testWidgets('does not display Fed by label when no user name',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(
            status: FeedingStatus.fed,
            completedBy: 'user-123',
          ),
        ));

        // Should not find CircleAvatar for attribution when no name
        expect(
            find.byWidgetPredicate(
              (widget) => widget is CircleAvatar && widget.radius == 8,
            ),
            findsNothing);
      });

      testWidgets('does not display Fed by label for pending feeding',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(
            status: FeedingStatus.pending,
            completedByName: 'John',
          ),
        ));

        // Should not find the attribution label for pending status
        expect(
            find.byWidgetPredicate(
              (widget) => widget is CircleAvatar && widget.radius == 8,
            ),
            findsNothing);
      });

      testWidgets('does not show person icon when completedByAvatar is provided',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(
            status: FeedingStatus.fed,
            completedBy: 'user-123',
            completedByName: 'Jane',
            completedByAvatar: 'https://example.com/avatar.jpg',
          ),
        ));
        await tester.pump();

        expect(find.text('Jane'), findsOneWidget);

        // The CircleAvatar should exist for the attribution
        expect(
            find.byWidgetPredicate(
              (widget) => widget is CircleAvatar && widget.radius == 8,
            ),
            findsOneWidget);
        // Should not show person icon when avatar is provided (icon is null when backgroundImage is set)
        expect(find.byIcon(Icons.person), findsNothing);
      },
          // Skip: NetworkImage causes test failure in test environment
          skip: true);

      testWidgets('displays fallback person icon when no avatar provided',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          feeding: createFeeding(
            status: FeedingStatus.fed,
            completedBy: 'user-123',
            completedByName: 'Bob',
          ),
        ));

        expect(find.text('Bob'), findsOneWidget);
        // The CircleAvatar should contain a person icon when no avatar URL
        expect(find.byIcon(Icons.person), findsOneWidget);
      });
    });
  });
}
