import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/onboarding_provider.dart';

/// Step 4: Add more aquarium decision step.
///
/// Final step in the aquarium-first onboarding flow.
/// Shows summary of created aquariums and fish.
/// User can choose to add another aquarium or finish setup.
class AddMoreAquariumStep extends ConsumerWidget {
  const AddMoreAquariumStep({
    super.key,
    this.onAddAnotherAquarium,
  });

  /// Callback when user wants to add another aquarium.
  /// If provided, this is called instead of directly resetting state.
  /// This allows the parent to save data before resetting.
  final VoidCallback? onAddAnotherAquarium;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final createdAquariums = ref.watch(createdAquariumsProvider);
    final selectedSpecies = ref.watch(selectedSpeciesProvider);
    final currentAquariumName = ref.watch(currentOnboardingAquariumNameProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            l10n.aquariumSetupComplete,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addMoreAquariumQuestion,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Current aquarium summary card
          _AquariumSummaryCard(
            aquariumName: currentAquariumName ?? l10n.myAquarium,
            fishCount: selectedSpecies.fold<int>(
              0,
              (sum, s) => sum + s.quantity,
            ),
            speciesCount: selectedSpecies.length,
            isCurrentAquarium: true,
          ),

          // Previously created aquariums
          if (createdAquariums.length > 1) ...[
            const SizedBox(height: 16),
            Text(
              l10n.previouslyCreated,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ...createdAquariums
                .take(createdAquariums.length - 1)
                .map((aquarium) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AquariumSummaryCard(
                        aquariumName: aquarium.name,
                        fishCount: 0, // We don't track fish count per aquarium during onboarding
                        speciesCount: 0,
                        isCurrentAquarium: false,
                      ),
                    )),
          ],

          const Spacer(),

          // Add another aquarium button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _onAddAnotherAquarium(ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.addAnotherAquarium),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Total aquariums count
          Center(
            child: Text(
              l10n.totalAquariums(createdAquariums.length),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _onAddAnotherAquarium(WidgetRef ref) {
    if (onAddAnotherAquarium != null) {
      // Use callback to allow parent to save data before resetting
      onAddAnotherAquarium!();
    } else {
      // Fallback: directly reset (may lose unsaved data)
      ref.read(onboardingNotifierProvider.notifier).resetForNewAquarium();
    }
  }
}

/// Summary card for a single aquarium.
class _AquariumSummaryCard extends StatelessWidget {
  const _AquariumSummaryCard({
    required this.aquariumName,
    required this.fishCount,
    required this.speciesCount,
    required this.isCurrentAquarium,
  });

  final String aquariumName;
  final int fishCount;
  final int speciesCount;
  final bool isCurrentAquarium;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentAquarium
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: isCurrentAquarium
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Aquarium icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isCurrentAquarium
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.water_drop,
              color: isCurrentAquarium
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Aquarium info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        aquariumName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentAquarium) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.justCreated,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (isCurrentAquarium && speciesCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.fishCountWithSpecies(fishCount, speciesCount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Check mark for current aquarium
          if (isCurrentAquarium)
            Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
              size: 24,
            ),
        ],
      ),
    );
  }
}
