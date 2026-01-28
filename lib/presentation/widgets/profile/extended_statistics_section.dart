import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/core/utils/premium_gate.dart';
import 'package:fishfeed/presentation/widgets/premium/premium_chip.dart';

/// Extended statistics section for premium users.
///
/// Shows 6 months of feeding history for premium users,
/// or a blurred preview with upgrade CTA for free users.
class ExtendedStatisticsSection extends ConsumerWidget {
  const ExtendedStatisticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAccess = ref.watch(
      featureAccessProvider(PremiumFeature.extendedStatistics),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(hasAccess: hasAccess),
          const SizedBox(height: 12),
          if (hasAccess)
            const _ExtendedStatsContent()
          else
            const _LockedStatsPreview(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.hasAccess});

  final bool hasAccess;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(Icons.trending_up, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          'Feeding History',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        if (!hasAccess) const PremiumChip(size: PremiumChipSize.tiny),
        const Spacer(),
        Text(
          hasAccess ? '6 months' : '7 days',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ExtendedStatsContent extends StatelessWidget {
  const _ExtendedStatsContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Placeholder for feeding history chart
          SizedBox(height: 120, child: _FeedingHistoryChart(isPremium: true)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'This Week', value: '92%'),
              _StatItem(label: 'This Month', value: '88%'),
              _StatItem(label: '6 Months', value: '85%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LockedStatsPreview extends StatelessWidget {
  const _LockedStatsPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push('/paywall'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Blurred background content
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 120,
                      child: _FeedingHistoryChart(isPremium: false),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(label: 'This Week', value: '92%'),
                        _StatItem(label: 'This Month', value: '--'),
                        _StatItem(label: '6 Months', value: '--'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Upgrade overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.amber.shade200,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 24,
                        color: Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'View 6 Months of History',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upgrade to Premium',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.amber.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.amber.shade800,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedingHistoryChart extends StatelessWidget {
  const _FeedingHistoryChart({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Placeholder chart bars
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(12, (index) {
        // Show fewer bars for free users (only last 2-3 visible)
        final isVisible = isPremium || index >= 9;
        final height = isVisible
            ? 40.0 + (index * 5) % 80
            : 20.0 + (index * 3) % 30;

        return Container(
          width: 16,
          height: height,
          decoration: BoxDecoration(
            color: isVisible
                ? theme.colorScheme.primary.withValues(
                    alpha: 0.7 + (index * 0.025),
                  )
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: value == '--' ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
