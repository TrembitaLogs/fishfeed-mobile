import 'package:flutter/material.dart';

import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/l10n/app_localizations.dart';

/// Shows a bottom sheet with detailed feeding information.
///
/// Displays: species name, aquarium, quantity, food type, portion hint, time.
/// Based on spec section 3.4.
Future<void> showFeedingDetailSheet(
  BuildContext context,
  ComputedFeedingEvent feeding,
) {
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => FeedingDetailSheet(feeding: feeding),
  );
}

/// Bottom sheet content showing detailed feeding information.
class FeedingDetailSheet extends StatelessWidget {
  const FeedingDetailSheet({super.key, required this.feeding});

  /// The feeding event to display details for.
  final ComputedFeedingEvent feeding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              l10n.feedingDetails,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // Fish name
            _DetailRow(
              icon: Icons.pets,
              label: feeding.fishName ?? 'Fish',
              theme: theme,
            ),
            const SizedBox(height: 12),
            // Aquarium name
            _DetailRow(
              icon: Icons.water_drop_outlined,
              label: feeding.aquariumName ?? '',
              theme: theme,
            ),
            const SizedBox(height: 12),
            // Fish quantity
            _DetailRow(
              icon: Icons.tag,
              label: l10n.fishCount(feeding.fishQuantity),
              theme: theme,
            ),
            const SizedBox(height: 12),
            // Food type
            _DetailRow(
              icon: Icons.restaurant,
              label: feeding.foodType,
              theme: theme,
            ),
            // Portion hint (only if available)
            if (feeding.portionHint != null) ...[
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.lightbulb_outline,
                label: '${l10n.portionHintLabel}: ${feeding.portionHint}',
                theme: theme,
              ),
            ],
            const SizedBox(height: 12),
            // Scheduled time
            _DetailRow(icon: Icons.schedule, label: feeding.time, theme: theme),
            const SizedBox(height: 24),
            // Close button
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.closeButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row displaying an icon and label for feeding detail.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
      ],
    );
  }
}
