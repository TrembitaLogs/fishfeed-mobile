import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/widgets/feeding_history/feeding_history_aquarium_picker_sheet.dart';

void main() {
  testWidgets(
    'All aquariums entry plus one tile per aquarium; tap returns id',
    (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                return TextButton(
                  onPressed: () async {
                    selected = await showFeedingHistoryAquariumPicker(
                      ctx,
                      aquariums: const [
                        AquariumPickerEntry(id: 'aq_1', name: 'Office'),
                        AquariumPickerEntry(id: 'aq_2', name: 'Home'),
                      ],
                      currentSelection: null,
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('All aquariums'), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);

      await tester.tap(find.text('Office'));
      await tester.pumpAndSettle();
      expect(selected, 'aq_1');
    },
  );
}
