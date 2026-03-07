import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/presentation/widgets/feeding/confirm_feeding_dialog.dart';

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

  late bool? dialogResult;

  Widget buildTestWidget(ComputedFeedingEvent feeding) {
    return ProviderScope(
      overrides: [
        // Return null so the dialog shows placeholder icon instead of
        // attempting to load fish photo from Hive/network.
        fishByIdProvider.overrideWith((ref, fishId) => null),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                dialogResult = await showConfirmFeedingDialog(context, feeding);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openDialog(
    WidgetTester tester,
    ComputedFeedingEvent feeding,
  ) async {
    dialogResult = null;
    await tester.pumpWidget(buildTestWidget(feeding));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('ConfirmFeedingDialog', () {
    testWidgets('displays "Mark as fed?" title', (tester) async {
      await openDialog(tester, createFeeding());

      expect(find.text('Mark as fed?'), findsOneWidget);
    });

    testWidgets('displays species name and aquarium name', (tester) async {
      await openDialog(
        tester,
        createFeeding(fishName: 'Betta', aquariumName: 'Kitchen'),
      );

      expect(find.text('Betta (Kitchen)'), findsOneWidget);
    });

    testWidgets('displays scheduled time', (tester) async {
      await openDialog(tester, createFeeding(hour: 14));

      expect(find.text('14:00'), findsOneWidget);
    });

    testWidgets('displays fish quantity', (tester) async {
      await openDialog(tester, createFeeding(fishQuantity: 5));

      expect(find.text('5 fish'), findsOneWidget);
    });

    testWidgets('displays portion hint when available', (tester) async {
      await openDialog(tester, createFeeding(portionHint: '2 pinches'));

      expect(find.textContaining('2 pinches'), findsOneWidget);
    });

    testWidgets('does not display portion hint when null', (tester) async {
      await openDialog(tester, createFeeding(portionHint: null));

      // Only 3 info rows: species, time, quantity (no portion hint)
      expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
    });

    testWidgets('"Yes, Fed" button returns true', (tester) async {
      await openDialog(tester, createFeeding());

      await tester.tap(find.text('Yes, Fed'));
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
    });

    testWidgets('"Cancel" button returns false', (tester) async {
      await openDialog(tester, createFeeding());

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(dialogResult, isFalse);
    });

    testWidgets('dismiss returns false', (tester) async {
      await openDialog(tester, createFeeding());

      // Dismiss by tapping outside the dialog
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(dialogResult, isFalse);
    });
  });
}
