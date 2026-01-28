import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/core/constants/species_data.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/presentation/router/app_router.dart';
import 'package:fishfeed/services/analytics/analytics_service.dart';

/// Full screen for managing aquarium fish.
///
/// Displays a list of all fish with options to edit or delete each one.
/// Includes FAB for adding new fish via AI Camera.
class MyAquariumScreen extends ConsumerStatefulWidget {
  const MyAquariumScreen({super.key});

  @override
  ConsumerState<MyAquariumScreen> createState() => _MyAquariumScreenState();
}

class _MyAquariumScreenState extends ConsumerState<MyAquariumScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(analyticsServiceProvider).trackMyAquariumOpened();
  }

  @override
  Widget build(BuildContext context) {
    final fishState = ref.watch(fishManagementProvider);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.myAquarium)),
      body: _buildBody(fishState),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFish,
        tooltip: l.addFishTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(FishManagementState fishState) {
    if (fishState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (fishState.hasError) {
      return _ErrorState(
        message: fishState.error!,
        onRetry: () => ref.read(fishManagementProvider.notifier).refresh(),
      );
    }

    if (fishState.isEmpty) {
      return _EmptyStateWidget(onAddFish: _addFish);
    }

    return _FishList(fish: fishState.userFish);
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

/// List of fish with pull-to-refresh.
class _FishList extends ConsumerWidget {
  const _FishList({required this.fish});

  final List<Fish> fish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(fishManagementProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        itemCount: fish.length,
        itemBuilder: (context, index) => _FishListItem(fish: fish[index]),
      ),
    );
  }
}

/// Single fish item in the list.
class _FishListItem extends ConsumerWidget {
  const _FishListItem({required this.fish});

  final Fish fish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final species = SpeciesData.findById(fish.speciesId);
    final displayName = fish.name ?? species.name;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.set_meal_rounded,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        'x${fish.quantity}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: PopupMenuButton<_FishAction>(
        icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
        onSelected: (action) => _handleAction(context, ref, action),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _FishAction.edit,
            child: Row(
              children: [
                const Icon(Icons.edit_outlined),
                const SizedBox(width: 12),
                Text(l.edit),
              ],
            ),
          ),
          PopupMenuItem(
            value: _FishAction.delete,
            child: Row(
              children: [
                Icon(Icons.delete_outlined, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Text(
                  l.delete,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
            ),
          ),
        ],
      ),
      onTap: () => _handleAction(context, ref, _FishAction.edit),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, _FishAction action) {
    switch (action) {
      case _FishAction.edit:
        context.push('/aquarium/fish/${fish.id}/edit');
        break;
      case _FishAction.delete:
        _showDeleteConfirmation(context, ref);
        break;
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final species = SpeciesData.findById(fish.speciesId);
    final displayName = fish.name ?? species.name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteFishTitle(displayName)),
        content: Text(l.confirmDeleteFish),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(l.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(fishManagementProvider.notifier)
          .deleteFish(fish.id);
      if (success && context.mounted) {
        ref
            .read(analyticsServiceProvider)
            .trackFishDeleted(speciesId: fish.speciesId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.fishDeletedSuccessfully),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Actions available for fish items.
enum _FishAction { edit, delete }

/// Choice for adding fish method.
enum _AddFishChoice { aiCamera, manual }

/// Empty state when no fish in aquarium.
class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget({required this.onAddFish});

  final VoidCallback onAddFish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets_outlined,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              l.emptyAquarium,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.addFirstFishDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAddFish,
              icon: const Icon(Icons.add),
              label: Text(l.addFirstFish),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state with retry button.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(l.errorStateServerTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }
}
