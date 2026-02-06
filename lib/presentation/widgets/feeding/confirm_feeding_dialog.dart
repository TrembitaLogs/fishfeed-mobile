import 'package:flutter/material.dart';

import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/l10n/app_localizations.dart';

/// Shows a confirmation dialog before marking a feeding as done.
///
/// Returns `true` if confirmed, `false` if cancelled or dismissed.
/// Based on spec section 3.3.
Future<bool> showConfirmFeedingDialog(
  BuildContext context,
  ComputedFeedingEvent feeding,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ConfirmFeedingDialog(feeding: feeding),
  ).then((v) => v ?? false);
}

/// Dialog content for confirming a feeding action.
class ConfirmFeedingDialog extends StatelessWidget {
  const ConfirmFeedingDialog({super.key, required this.feeding});

  /// The feeding event to confirm.
  final ComputedFeedingEvent feeding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.markAsFedQuestion),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Species + aquarium
          _InfoRow(
            icon: Icons.pets,
            text:
                '${feeding.fishName ?? "Fish"} (${feeding.aquariumName ?? ""})',
            theme: theme,
          ),
          const SizedBox(height: 8),
          // Time
          _InfoRow(icon: Icons.schedule, text: feeding.time, theme: theme),
          const SizedBox(height: 8),
          // Quantity
          _InfoRow(
            icon: Icons.tag,
            text: l10n.fishCount(feeding.fishQuantity),
            theme: theme,
          ),
          // Portion hint (only if available)
          if (feeding.portionHint != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.lightbulb_outline,
              text: '${l10n.portionHintLabel}: ${feeding.portionHint}',
              theme: theme,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.yesFed),
        ),
      ],
    );
  }
}

/// A row with icon and text for dialog content.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, required this.theme});

  final IconData icon;
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
