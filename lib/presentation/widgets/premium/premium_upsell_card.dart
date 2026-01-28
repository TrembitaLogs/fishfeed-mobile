import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/presentation/providers/purchase_provider.dart';

/// A card that promotes premium subscription to free users.
///
/// Shows premium benefits and a CTA to upgrade.
/// Only visible to non-premium users.
class PremiumUpsellCard extends ConsumerWidget {
  const PremiumUpsellCard({
    super.key,
    this.onDismiss,
    this.showDismissButton = true,
  });

  /// Callback when user dismisses the card.
  final VoidCallback? onDismiss;

  /// Whether to show a dismiss button.
  final bool showDismissButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    if (isPremium) {
      return const SizedBox.shrink();
    }

    return _buildCard(context);
  }

  Widget _buildCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber.shade50,
              Colors.orange.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.workspace_premium,
                      color: Colors.amber.shade800,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade to Premium',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        Text(
                          'Unlock all features',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showDismissButton)
                    IconButton(
                      onPressed: onDismiss,
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.amber.shade700,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _BenefitChip(label: 'No Ads'),
                  _BenefitChip(label: 'Unlimited AI Scans'),
                  _BenefitChip(label: '6 Months History'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/paywall'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('View Plans'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 14,
            color: Colors.amber.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.amber.shade900,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
