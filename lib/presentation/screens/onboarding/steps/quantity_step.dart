import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/presentation/providers/onboarding_provider.dart';

/// Step 2: Quantity selection for each species.
///
/// Displays counters for each selected species to set fish count.
/// Allows setting quantity between 1 and 50 fish per species.
class QuantityStep extends ConsumerWidget {
  const QuantityStep({super.key});

  /// Maximum allowed quantity per species.
  static const int maxQuantity = 50;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedSpecies = ref.watch(selectedSpeciesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'How many fish?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set the quantity for each species',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: selectedSpecies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final selection = selectedSpecies[index];
                return _QuantityCard(
                  speciesName: selection.species.name,
                  quantity: selection.quantity,
                  onIncrement: selection.quantity < maxQuantity
                      ? () => ref
                          .read(onboardingNotifierProvider.notifier)
                          .updateQuantity(
                            selection.species.id,
                            selection.quantity + 1,
                          )
                      : null,
                  onDecrement: selection.quantity > 1
                      ? () => ref
                          .read(onboardingNotifierProvider.notifier)
                          .updateQuantity(
                            selection.species.id,
                            selection.quantity - 1,
                          )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityCard extends StatelessWidget {
  const _QuantityCard({
    required this.speciesName,
    required this.quantity,
    this.onIncrement,
    this.onDecrement,
  });

  final String speciesName;
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.pets,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                speciesName,
                style: theme.textTheme.titleMedium,
              ),
            ),
            _QuantitySelector(
              quantity: quantity,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    this.onIncrement,
    this.onDecrement,
  });

  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          onPressed: onDecrement,
          icon: const Icon(Icons.remove),
          iconSize: 20,
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton.filled(
          onPressed: onIncrement,
          icon: const Icon(Icons.add),
          iconSize: 20,
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
        ),
      ],
    );
  }
}
