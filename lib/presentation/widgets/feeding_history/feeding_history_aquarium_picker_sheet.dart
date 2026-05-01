import 'package:flutter/material.dart';

import 'package:fishfeed/l10n/app_localizations.dart';

class AquariumPickerEntry {
  const AquariumPickerEntry({required this.id, required this.name});
  final String id;
  final String name;
}

/// Returns the selected aquarium id, or `null` when the user picks "All
/// aquariums" or dismisses the sheet.
Future<String?> showFeedingHistoryAquariumPicker(
  BuildContext context, {
  required List<AquariumPickerEntry> aquariums,
  required String? currentSelection,
}) {
  return showModalBottomSheet<String?>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(l10n.feedingHistoryAllAquariums),
              trailing: currentSelection == null
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.of(ctx).pop(null),
            ),
            const Divider(height: 1),
            for (final aq in aquariums)
              ListTile(
                title: Text(aq.name),
                trailing: currentSelection == aq.id
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(ctx).pop(aq.id),
              ),
          ],
        ),
      );
    },
  );
}
