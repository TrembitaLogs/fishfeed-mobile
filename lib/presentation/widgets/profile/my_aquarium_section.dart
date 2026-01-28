import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/core/constants/species_data.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/presentation/router/app_router.dart';

/// Compact section displaying aquarium preview on Profile Screen.
///
/// Shows:
/// - Header with "My Aquarium" title and water drop icon
/// - Preview of first 3 fish (species name + quantity)
/// - "+X more" text if more than 3 fish
/// - "Manage" and "Add Fish" action buttons
///
/// Empty state shows "No fish yet" with "Add your first fish" CTA.
class MyAquariumSection extends ConsumerStatefulWidget {
  const MyAquariumSection({super.key});

  /// Maximum number of fish to show in preview.
  static const int _maxPreviewFish = 3;

  @override
  ConsumerState<MyAquariumSection> createState() => _MyAquariumSectionState();
}

class _MyAquariumSectionState extends ConsumerState<MyAquariumSection> {
  @override
  Widget build(BuildContext context) {
    final fishState = ref.watch(fishManagementProvider);

    if (fishState.isLoading) {
      return const _MyAquariumSectionShimmer();
    }

    return _MyAquariumSectionContent(
      fish: fishState.userFish,
      onAddFish: _addFish,
    );
  }

  Future<void> _addFish() async {
    final l = AppLocalizations.of(context)!;

    // Show bottom sheet to choose add method
    final choice = await showModalBottomSheet<_AddFishChoice>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l.scanWithAiCamera),
              subtitle: Text(l.takePhotoToIdentify),
              onTap: () => Navigator.pop(ctx, _AddFishChoice.aiCamera),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: Text(l.selectFromList),
              subtitle: Text(l.chooseFromSpeciesList),
              onTap: () => Navigator.pop(ctx, _AddFishChoice.manual),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || choice == null) return;

    switch (choice) {
      case _AddFishChoice.aiCamera:
        context.push(AppRouter.aiCamera);
        break;
      case _AddFishChoice.manual:
        context.push(AppRouter.addFish);
        break;
    }
  }
}

/// Choice for adding fish method.
enum _AddFishChoice {
  aiCamera,
  manual,
}

/// Content widget displaying the aquarium section.
class _MyAquariumSectionContent extends StatelessWidget {
  const _MyAquariumSectionContent({
    required this.fish,
    required this.onAddFish,
  });

  final List<Fish> fish;
  final VoidCallback onAddFish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = fish.isEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _Header(fishCount: fish.length),
            const SizedBox(height: 16),

            // Fish preview or empty state
            if (isEmpty)
              _EmptyState(onAddFish: onAddFish)
            else
              _FishPreview(fish: fish, onAddFish: onAddFish),
          ],
        ),
      ),
    );
  }
}

/// Header with icon and title.
class _Header extends StatelessWidget {
  const _Header({required this.fishCount});

  final int fishCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Row(
      children: [
        Icon(
          Icons.water_drop_rounded,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          l.myAquarium,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (fishCount > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$fishCount',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Empty state when no fish in aquarium.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddFish});

  final VoidCallback onAddFish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      children: [
        Icon(
          Icons.pets_outlined,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 12),
        Text(
          l.emptyAquarium,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onAddFish,
          icon: const Icon(Icons.add),
          label: Text(l.addFirstFish),
        ),
      ],
    );
  }
}

/// Fish preview list with action buttons.
class _FishPreview extends StatelessWidget {
  const _FishPreview({
    required this.fish,
    required this.onAddFish,
  });

  final List<Fish> fish;
  final VoidCallback onAddFish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final previewFish = fish.take(MyAquariumSection._maxPreviewFish).toList();
    final remainingCount = fish.length - previewFish.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fish list
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              ...previewFish.map((f) => _FishPreviewItem(fish: f)),
              if (remainingCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l.moreCount(remainingCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Action buttons
        _ActionButtons(onAddFish: onAddFish),
      ],
    );
  }
}

/// Single fish item in preview list.
class _FishPreviewItem extends StatelessWidget {
  const _FishPreviewItem({required this.fish});

  final Fish fish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final species = SpeciesData.findById(fish.speciesId);
    final displayName = fish.name ?? species.name;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.set_meal_rounded,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayName,
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'x${fish.quantity}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Action buttons row.
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onAddFish});

  final VoidCallback onAddFish;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/aquarium'),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(l.manageFish),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onAddFish,
            icon: const Icon(Icons.add, size: 18),
            label: Text(l.addFish),
          ),
        ),
      ],
    );
  }
}

/// Shimmer loading placeholder.
class _MyAquariumSectionShimmer extends StatefulWidget {
  const _MyAquariumSectionShimmer();

  @override
  State<_MyAquariumSectionShimmer> createState() =>
      _MyAquariumSectionShimmerState();
}

class _MyAquariumSectionShimmerState extends State<_MyAquariumSectionShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShimmerBox(height: 20, width: 120),
            const SizedBox(height: 16),
            _buildShimmerBox(height: 80, width: double.infinity),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildShimmerBox(height: 40, width: double.infinity)),
                const SizedBox(width: 12),
                Expanded(child: _buildShimmerBox(height: 40, width: double.infinity)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox({required double height, required double width}) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
            ),
          ),
        );
      },
    );
  }
}
