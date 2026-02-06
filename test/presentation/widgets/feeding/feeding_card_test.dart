import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
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

  FeedingLogModel createLog({
    bool synced = true,
    String? actedByUserName,
    DateTime? actedAt,
  }) {
    return FeedingLogModel(
      id: 'log-1',
      scheduleId: 'schedule-1',
      fishId: 'fish-1',
      aquariumId: 'aq-1',
      scheduledFor: today.add(const Duration(hours: 9)),
      action: 'fed',
      actedAt: actedAt ?? today.add(const Duration(hours: 9, minutes: 5)),
      actedByUserId: 'user-1',
      actedByUserName: actedByUserName,
      deviceId: 'device-1',
      createdAt: today,
      synced: synced,
    );
  }

  ComputedFeedingEvent createFeeding({
    String scheduleId = 'schedule-1',
    EventStatus status = EventStatus.pending,
    String fishName = 'Guppy',
    String aquariumName = 'Living Room Tank',
    String foodType = 'Flakes',
    String? portionHint,
    int fishQuantity = 1,
    int hour = 14,
    String? avatarUrl,
    FeedingLogModel? log,
  }) {
    return ComputedFeedingEvent(
      scheduleId: scheduleId,
      fishId: 'fish_1',
      aquariumId: 'aq1',
      scheduledFor: today.add(Duration(hours: hour)),
      time: '${hour.toString().padLeft(2, '0')}:00',
      foodType: foodType,
      portionHint: portionHint,
      status: status,
      fishName: fishName,
      aquariumName: aquariumName,
      avatarUrl: avatarUrl,
      fishQuantity: fishQuantity,
      log: log,
    );
  }

  Widget buildTestWidget({
    required ComputedFeedingEvent feeding,
    FeedingStatusCallback? onMarkAsFed,
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
          ),
        ),
      ),
    );
  }

  group('FeedingCard', () {
    group('Display', () {
      testWidgets('displays fish name', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(feeding: createFeeding(fishName: 'Betta')),
        );

        expect(find.text('Betta'), findsOneWidget);
      });

      testWidgets('displays aquarium name', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(feeding: createFeeding(aquariumName: 'Bedroom Tank')),
        );

        expect(find.text('Bedroom Tank'), findsOneWidget);
      });

      testWidgets('displays food type', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(feeding: createFeeding(foodType: 'Pellets')),
        );

        expect(find.text('Pellets'), findsOneWidget);
      });

      testWidgets('displays formatted time', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(feeding: createFeeding(hour: 8)),
        );

        expect(find.text('08:00'), findsOneWidget);
      });

      testWidgets('displays chevron icon for all states', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(feeding: createFeeding(status: EventStatus.pending)),
        );

        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });

      testWidgets('displays chevron icon for fed state too', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            feeding: createFeeding(status: EventStatus.fed, log: createLog()),
          ),
        );

        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });

      testWidgets('does not display old touch_app icon', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(feeding: createFeeding(status: EventStatus.pending)),
        );

        expect(find.byIcon(Icons.touch_app_outlined), findsNothing);
      });

      testWidgets('displays fish quantity when > 1', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(feeding: createFeeding(fishQuantity: 5)),
        );

        expect(find.text('5 fish'), findsOneWidget);
      });

      testWidgets('does not display fish quantity when = 1', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(feeding: createFeeding(fishQuantity: 1)),
        );

        // "1 fish" should NOT appear as a separate label
        expect(find.text('1 fish'), findsNothing);
      });
    });

    group('Card States', () {
      testWidgets('pending card has normal background', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(feeding: createFeeding(status: EventStatus.pending)),
        );

        // Card should exist without green styling
        expect(find.byType(Card), findsOneWidget);
        // No green border indicator
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(Card),
            matching: find.byType(Container).first,
          ),
        );
        final decoration = container.decoration as BoxDecoration?;
        expect(decoration?.border, isNull);
      });

      testWidgets('fed card has green background', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            feeding: createFeeding(status: EventStatus.fed, log: createLog()),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(Card),
            matching: find.byType(Container).first,
          ),
        );
        final decoration = container.decoration as BoxDecoration?;
        // Fed card should have green-tinted background
        expect(decoration?.color, isNotNull);
        // Fed card should have left green border
        expect(decoration?.border, isNotNull);
      });

      testWidgets('fed card shows "Fed at HH:mm"', (tester) async {
        final actedAt = today.add(const Duration(hours: 9, minutes: 15));
        await tester.pumpWidget(
          buildTestWidget(
            feeding: createFeeding(
              status: EventStatus.fed,
              log: createLog(actedAt: actedAt),
            ),
          ),
        );

        expect(find.textContaining('Fed at'), findsOneWidget);
      });

      testWidgets('syncing state shows cloud upload icon', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            feeding: createFeeding(
              status: EventStatus.fed,
              log: createLog(synced: false),
            ),
          ),
        );

        expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
      });

      testWidgets('synced fed state shows check icon (not cloud)', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            feeding: createFeeding(
              status: EventStatus.fed,
              log: createLog(synced: true),
            ),
          ),
        );

        expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('pending state shows schedule icon', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(feeding: createFeeding(status: EventStatus.pending)),
        );

        expect(find.byIcon(Icons.schedule), findsOneWidget);
      });

      testWidgets('applies strikethrough to title for fed status', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            feeding: createFeeding(
              status: EventStatus.fed,
              fishName: 'Guppy',
              log: createLog(),
            ),
          ),
        );

        final titleFinder = find.text('Guppy');
        final titleWidget = tester.widget<Text>(titleFinder);

        expect(titleWidget.style?.decoration, TextDecoration.lineThrough);
      });

      testWidgets('does not apply strikethrough for pending status', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            feeding: createFeeding(
              status: EventStatus.pending,
              fishName: 'Guppy',
            ),
          ),
        );

        final titleFinder = find.text('Guppy');
        final titleWidget = tester.widget<Text>(titleFinder);

        expect(
          titleWidget.style?.decoration,
          isNot(TextDecoration.lineThrough),
        );
      });
    });

    group('Tap Interaction', () {
      testWidgets('tap on pending card opens bottom sheet', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            feeding: createFeeding(
              status: EventStatus.pending,
              fishName: 'Betta',
              foodType: 'Pellets',
            ),
          ),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Bottom sheet with "Feeding Details" should appear
        expect(find.text('Feeding Details'), findsOneWidget);
      });

      testWidgets('tap on fed card opens bottom sheet', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            feeding: createFeeding(
              status: EventStatus.fed,
              fishName: 'Betta',
              log: createLog(),
            ),
          ),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(find.text('Feeding Details'), findsOneWidget);
      });

      testWidgets('tap does NOT directly call onMarkAsFed', (tester) async {
        var wasCalled = false;

        await tester.pumpWidget(
          buildTestWidget(
            feeding: createFeeding(
              status: EventStatus.pending,
              scheduleId: 'test-123',
            ),
            onMarkAsFed: (_) => wasCalled = true,
          ),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Tap should open detail sheet, NOT directly mark as fed
        expect(wasCalled, isFalse);
      });
    });

    group('Swipe Actions', () {
      testWidgets('contains Dismissible widget', (tester) async {
        await tester.pumpWidget(buildTestWidget(feeding: createFeeding()));

        expect(find.byType(Dismissible), findsOneWidget);
      });

      testWidgets('pending card allows only startToEnd swipe', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(feeding: createFeeding(status: EventStatus.pending)),
        );

        final dismissible = tester.widget<Dismissible>(
          find.byType(Dismissible),
        );
        expect(dismissible.direction, DismissDirection.startToEnd);
      });

      testWidgets('fed card disables swipe (direction none)', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            feeding: createFeeding(status: EventStatus.fed, log: createLog()),
          ),
        );

        final dismissible = tester.widget<Dismissible>(
          find.byType(Dismissible),
        );
        expect(dismissible.direction, DismissDirection.none);
      });

      testWidgets('swipe right opens confirmation dialog', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(feeding: createFeeding(status: EventStatus.pending)),
        );

        // Perform a fling gesture to trigger confirmDismiss
        await tester.fling(
          find.byType(Dismissible),
          const Offset(300, 0),
          1000,
        );
        await tester.pumpAndSettle();

        // Confirmation dialog should appear
        expect(find.text('Mark as fed?'), findsOneWidget);
      });

      testWidgets('swipe right + confirm calls onMarkAsFed', (tester) async {
        String? markedId;

        await tester.pumpWidget(
          buildTestWidget(
            feeding: createFeeding(
              scheduleId: 'test-456',
              status: EventStatus.pending,
            ),
            onMarkAsFed: (id) => markedId = id,
          ),
        );

        // Fling right to trigger confirmDismiss
        await tester.fling(
          find.byType(Dismissible),
          const Offset(300, 0),
          1000,
        );
        await tester.pumpAndSettle();

        // Confirm in dialog
        await tester.tap(find.text('Yes, Fed'));
        await tester.pumpAndSettle();

        expect(markedId, equals('test-456'));
      });

      testWidgets('swipe right + cancel does NOT call onMarkAsFed', (
        tester,
      ) async {
        var wasCalled = false;

        await tester.pumpWidget(
          buildTestWidget(
            feeding: createFeeding(status: EventStatus.pending),
            onMarkAsFed: (_) => wasCalled = true,
          ),
        );

        // Fling right to trigger confirmDismiss
        await tester.fling(
          find.byType(Dismissible),
          const Offset(300, 0),
          1000,
        );
        await tester.pumpAndSettle();

        // Cancel in dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(wasCalled, isFalse);
      });

      testWidgets('no secondary background (swipe left removed)', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(feeding: createFeeding(status: EventStatus.pending)),
        );

        final dismissible = tester.widget<Dismissible>(
          find.byType(Dismissible),
        );
        expect(dismissible.secondaryBackground, isNull);
      });

      testWidgets('dismissible has unique key per feeding', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(feeding: createFeeding(scheduleId: 'unique-123')),
        );

        final dismissible = tester.widget<Dismissible>(
          find.byType(Dismissible),
        );
        expect(dismissible.key, equals(const Key('feeding_card_unique-123')));
      });
    });

    group('Removed API', () {
      testWidgets('FeedingCard constructor does not require onMarkAsMissed', (
        tester,
      ) async {
        // This test verifies the old onMarkAsMissed parameter is removed.
        // If it were still required, this would fail to compile.
        await tester.pumpWidget(
          buildTestWidget(feeding: createFeeding(), onMarkAsFed: (_) {}),
        );

        expect(find.byType(FeedingCard), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('InkWell is present for tap interaction', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(feeding: createFeeding(status: EventStatus.pending)),
        );

        expect(find.byType(InkWell), findsOneWidget);
      });

      testWidgets('Card is present', (tester) async {
        await tester.pumpWidget(buildTestWidget(feeding: createFeeding()));

        expect(find.byType(Card), findsOneWidget);
      });
    });
  });
}
