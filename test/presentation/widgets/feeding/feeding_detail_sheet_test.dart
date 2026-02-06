import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/widgets/feeding/feeding_detail_sheet.dart';

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

  ComputedFeedingEvent createFeeding({
    String fishName = 'Guppy',
    String aquariumName = 'Living Room Tank',
    String foodType = 'Flakes',
    String? portionHint,
    int fishQuantity = 3,
    int hour = 9,
  }) {
    return ComputedFeedingEvent(
      scheduleId: 'schedule-1',
      fishId: 'fish-1',
      aquariumId: 'aq-1',
      scheduledFor: today.add(Duration(hours: hour)),
      time: '${hour.toString().padLeft(2, '0')}:00',
      foodType: foodType,
      status: EventStatus.pending,
      fishName: fishName,
      aquariumName: aquariumName,
      portionHint: portionHint,
      fishQuantity: fishQuantity,
    );
  }

  Widget buildTestWidget(ComputedFeedingEvent feeding) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showFeedingDetailSheet(context, feeding),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(
    WidgetTester tester,
    ComputedFeedingEvent feeding,
  ) async {
    await tester.pumpWidget(buildTestWidget(feeding));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('FeedingDetailSheet', () {
    testWidgets('displays fish name', (tester) async {
      await openSheet(tester, createFeeding(fishName: 'Betta'));

      expect(find.text('Betta'), findsOneWidget);
    });

    testWidgets('displays aquarium name', (tester) async {
      await openSheet(tester, createFeeding(aquariumName: 'Bedroom Tank'));

      expect(find.text('Bedroom Tank'), findsOneWidget);
    });

    testWidgets('displays fish quantity', (tester) async {
      await openSheet(tester, createFeeding(fishQuantity: 5));

      expect(find.text('5 fish'), findsOneWidget);
    });

    testWidgets('displays food type', (tester) async {
      await openSheet(tester, createFeeding(foodType: 'Pellets'));

      expect(find.text('Pellets'), findsOneWidget);
    });

    testWidgets('displays portion hint when available', (tester) async {
      await openSheet(tester, createFeeding(portionHint: '2 pinches'));

      expect(find.textContaining('2 pinches'), findsOneWidget);
    });

    testWidgets('does not display portion hint when null', (tester) async {
      await openSheet(tester, createFeeding(portionHint: null));

      expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
    });

    testWidgets('displays scheduled time', (tester) async {
      await openSheet(tester, createFeeding(hour: 14));

      expect(find.text('14:00'), findsOneWidget);
    });

    testWidgets('displays Feeding Details title', (tester) async {
      await openSheet(tester, createFeeding());

      expect(find.text('Feeding Details'), findsOneWidget);
    });

    testWidgets('Close button closes the sheet', (tester) async {
      await openSheet(tester, createFeeding());

      // Sheet is open
      expect(find.text('Feeding Details'), findsOneWidget);

      // Tap close
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Sheet is closed
      expect(find.text('Feeding Details'), findsNothing);
    });
  });
}
