import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/domain/entities/species.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/presentation/providers/species_provider.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';

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
class ConfirmFeedingDialog extends ConsumerWidget {
  const ConfirmFeedingDialog({super.key, required this.feeding});

  /// The feeding event to confirm.
  final ComputedFeedingEvent feeding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final fish = ref.watch(fishByIdProvider(feeding.fishId));
    final speciesAsync = fish != null
        ? ref.watch(speciesByIdProvider(fish.speciesId))
        : null;

    return AlertDialog(
      title: Text(l10n.markAsFedQuestion),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fish photo
          _FishPhoto(fish: fish, speciesAsync: speciesAsync),
          const SizedBox(height: 16),
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

/// Displays a fish photo in the confirmation dialog.
///
/// Priority:
/// 1. User-uploaded fish photo (via [EntityImage] with S3 key)
/// 2. Species reference photo (via [CachedNetworkImage])
/// 3. Placeholder icon
class _FishPhoto extends ConsumerWidget {
  const _FishPhoto({required this.fish, required this.speciesAsync});

  final Fish? fish;
  final AsyncValue<Species?>? speciesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Priority 1: User-uploaded fish photo (S3 key)
    if (fish != null && fish!.photoKey != null && fish!.photoKey!.isNotEmpty) {
      return Center(
        child: EntityImage(
          photoKey: fish!.photoKey,
          entityType: 'fish',
          entityId: fish!.id,
          width: 80,
          height: 80,
          isCircular: true,
        ),
      );
    }

    // Priority 2: Species reference photo
    final speciesImageUrl = speciesAsync?.valueOrNull?.imageUrl;
    if (speciesImageUrl != null && speciesImageUrl.isNotEmpty) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: SizedBox(
            width: 80,
            height: 80,
            child: CachedNetworkImage(
              imageUrl: speciesImageUrl,
              fit: BoxFit.cover,
              memCacheWidth: 160,
              memCacheHeight: 160,
              placeholder: (_, __) => _buildPlaceholder(theme),
              errorWidget: (_, __, ___) => _buildPlaceholder(theme),
            ),
          ),
        ),
      );
    }

    // Priority 3: Placeholder icon
    return Center(child: _buildPlaceholder(theme));
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.set_meal_rounded,
        size: 36,
        color: theme.colorScheme.onSurfaceVariant,
      ),
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
