import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/onboarding_provider.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';

/// Step 0 (add-fish mode): Select which aquarium to add the fish to.
///
/// Shows a list of user's aquariums as selectable cards.
/// Stores the selected aquarium ID in onboarding state.
class AquariumSelectionStep extends ConsumerWidget {
  const AquariumSelectionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final aquariums = ref.watch(aquariumsListProvider);
    final selectedId = ref.watch(
      onboardingNotifierProvider.select((s) => s.selectedAquariumId),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            l10n.selectAquarium,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.selectAquariumDescription,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ...aquariums.map(
            (aquarium) => _AquariumCard(
              aquarium: aquarium,
              isSelected: aquarium.id == selectedId,
              onTap: () => ref
                  .read(onboardingNotifierProvider.notifier)
                  .setSelectedAquarium(aquarium.id),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AquariumCard extends StatelessWidget {
  const _AquariumCard({
    required this.aquarium,
    required this.isSelected,
    required this.onTap,
  });

  final Aquarium aquarium;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: EntityImage(
                    photoKey: aquarium.photoKey,
                    entityType: 'aquarium',
                    entityId: aquarium.id,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(8),
                    memCacheWidth: 96,
                    memCacheHeight: 96,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aquarium.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (aquarium.capacity != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${aquarium.capacity!.toStringAsFixed(0)}L',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                      .withValues(alpha: 0.7)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
