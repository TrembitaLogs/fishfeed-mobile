import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/constants/species_data.dart';
import 'package:fishfeed/domain/entities/species.dart';
import 'package:fishfeed/presentation/providers/onboarding_provider.dart';
import 'package:fishfeed/presentation/providers/species_provider.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';

/// Step 1: Species selection with search and multi-select.
///
/// Allows users to select 1-3 fish species from a searchable grid.
/// Includes "I don't know my species" option with default parameters.
/// Features debounced search (300ms) and selected species chips.
class SpeciesSelectionStep extends ConsumerStatefulWidget {
  const SpeciesSelectionStep({super.key});

  @override
  ConsumerState<SpeciesSelectionStep> createState() =>
      _SpeciesSelectionStepState();
}

class _SpeciesSelectionStepState extends ConsumerState<SpeciesSelectionStep> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  /// Debounce duration for search input.
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      ref.read(speciesSearchQueryProvider.notifier).state = query;
      ref.read(speciesListProvider.notifier).searchSpecies(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedSpecies = ref.watch(selectedSpeciesProvider);
    final speciesState = ref.watch(speciesListProvider);
    final filteredSpecies = speciesState.species;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'What fish do you have?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select up to 3 species',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          // Selected species chips
          if (selectedSpecies.isNotEmpty) ...[
            _SelectedSpeciesChips(
              selectedSpecies: selectedSpecies,
              onRemove: (speciesId) => ref
                  .read(onboardingNotifierProvider.notifier)
                  .removeSpecies(speciesId),
            ),
            const SizedBox(height: 16),
          ],
          // Search field
          _SearchField(
            controller: _searchController,
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),
          // "I don't know" button
          _UnknownSpeciesButton(
            isSelected: selectedSpecies.any(
              (s) => s.species.id == SpeciesData.defaultSpecies.id,
            ),
            onTap: () => ref
                .read(onboardingNotifierProvider.notifier)
                .toggleSpecies(SpeciesData.defaultSpecies),
          ),
          const SizedBox(height: 16),
          // Species grid
          Expanded(
            child: speciesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _SpeciesGrid(
                    species: filteredSpecies,
                    selectedSpecies: selectedSpecies,
                    onToggle: (species) => ref
                        .read(onboardingNotifierProvider.notifier)
                        .toggleSpecies(species),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Displays selected species as removable chips.
class _SelectedSpeciesChips extends StatelessWidget {
  const _SelectedSpeciesChips({
    required this.selectedSpecies,
    required this.onRemove,
  });

  final List<SpeciesSelection> selectedSpecies;
  final void Function(String speciesId) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: selectedSpecies.map((selection) {
        final isDefault = selection.species.id == SpeciesData.defaultSpecies.id;
        return Chip(
          avatar: isDefault
              ? Icon(
                  Icons.help_outline,
                  size: 18,
                  color: theme.colorScheme.onSecondaryContainer,
                )
              : selection.species.imageUrl != null
              ? AppCachedAvatar(
                  imageUrl: selection.species.imageUrl,
                  radius: 12,
                  fallbackIcon: Icons.pets,
                )
              : Icon(
                  Icons.pets,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
          label: Text(
            isDefault ? 'Unknown' : selection.species.name,
            style: theme.textTheme.bodyMedium,
          ),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () => onRemove(selection.species.id),
          backgroundColor: theme.colorScheme.primaryContainer,
          deleteIconColor: theme.colorScheme.onPrimaryContainer,
        );
      }).toList(),
    );
  }
}

/// Search text field for filtering species.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search species...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}

/// Button for users who don't know their fish species.
class _UnknownSpeciesButton extends StatelessWidget {
  const _UnknownSpeciesButton({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.secondaryContainer
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.help_outline,
                color: isSelected
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "I don't know my species",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.onSecondaryContainer
                            : null,
                      ),
                    ),
                    Text(
                      "We'll use safe default settings",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onSecondaryContainer.withValues(
                                alpha: 0.7,
                              )
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid view of species cards for selection.
class _SpeciesGrid extends StatelessWidget {
  const _SpeciesGrid({
    required this.species,
    required this.selectedSpecies,
    required this.onToggle,
  });

  final List<Species> species;
  final List<SpeciesSelection> selectedSpecies;
  final void Function(Species) onToggle;

  @override
  Widget build(BuildContext context) {
    if (species.isEmpty) {
      return Center(
        child: Text(
          'No species found',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: species.length,
      itemBuilder: (context, index) {
        final speciesItem = species[index];
        final isSelected = selectedSpecies.any(
          (s) => s.species.id == speciesItem.id,
        );

        return _SpeciesCard(
          species: speciesItem,
          isSelected: isSelected,
          onTap: () => onToggle(speciesItem),
        );
      },
    );
  }
}

/// Individual species card with image and selection state.
class _SpeciesCard extends StatelessWidget {
  const _SpeciesCard({
    required this.species,
    required this.isSelected,
    required this.onTap,
  });

  final Species species;
  final bool isSelected;
  final VoidCallback onTap;

  Widget _buildSpeciesImage(ThemeData theme) {
    final placeholder = Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.pets,
          size: 48,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );

    // Prefer network image if available
    if (species.imageUrl != null && species.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: species.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => placeholder,
        errorWidget: (context, url, error) => placeholder,
        fadeInDuration: const Duration(milliseconds: 300),
      );
    }

    // Fallback to asset image
    if (species.imageAsset != null && species.imageAsset!.isNotEmpty) {
      return Image.asset(
        species.imageAsset!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    return placeholder;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildSpeciesImage(theme),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      species.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Selection indicator
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
