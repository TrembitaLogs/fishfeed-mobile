import 'dart:async';

import 'package:flutter/material.dart';

import 'package:fishfeed/core/constants/species_data.dart';
import 'package:fishfeed/domain/entities/species.dart';

/// Result returned when user selects a species from the bottom sheet.
class SpeciesSelectionResult {
  const SpeciesSelectionResult({
    required this.speciesId,
    required this.speciesName,
  });

  final String speciesId;
  final String speciesName;
}

/// Bottom sheet for manual species selection.
///
/// Shows a searchable list of popular fish species.
/// Returns [SpeciesSelectionResult] when a species is selected.
class SpeciesSelectionBottomSheet extends StatefulWidget {
  const SpeciesSelectionBottomSheet({super.key});

  /// Shows the species selection bottom sheet.
  ///
  /// Returns [SpeciesSelectionResult] if a species was selected, null otherwise.
  static Future<SpeciesSelectionResult?> show(BuildContext context) {
    return showModalBottomSheet<SpeciesSelectionResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const SpeciesSelectionBottomSheet(),
    );
  }

  @override
  State<SpeciesSelectionBottomSheet> createState() =>
      _SpeciesSelectionBottomSheetState();
}

class _SpeciesSelectionBottomSheetState
    extends State<SpeciesSelectionBottomSheet> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';

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
      setState(() {
        _searchQuery = query;
      });
    });
  }

  void _selectSpecies(Species species) {
    Navigator.of(context).pop(
      SpeciesSelectionResult(
        speciesId: species.id,
        speciesName: species.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredSpecies = SpeciesData.searchByName(_searchQuery);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Fish Species',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search species...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Species list
            Expanded(
              child: filteredSpecies.isEmpty
                  ? Center(
                      child: Text(
                        'No species found',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredSpecies.length,
                      itemBuilder: (context, index) {
                        final species = filteredSpecies[index];
                        return _SpeciesListItem(
                          species: species,
                          onTap: () => _selectSpecies(species),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Single species item in the list.
class _SpeciesListItem extends StatelessWidget {
  const _SpeciesListItem({
    required this.species,
    required this.onTap,
  });

  final Species species;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.set_meal_rounded,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        species.name,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        _formatFeedingInfo(species),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  String _formatFeedingInfo(Species species) {
    final frequency = species.feedingFrequency;
    if (frequency == null || frequency.isEmpty) {
      return 'Tap to select';
    }
    return 'Feeding: $frequency';
  }
}
