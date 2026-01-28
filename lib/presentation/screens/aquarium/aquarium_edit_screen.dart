import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/core/constants/species_data.dart';
import 'package:fishfeed/domain/entities/fish.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/fish_management_provider.dart';
import 'package:fishfeed/presentation/router/app_router.dart';
import 'package:fishfeed/presentation/widgets/common/app_text_field.dart';

/// Screen for editing an existing aquarium.
///
/// Allows users to rename the aquarium, manage fish, and delete the aquarium.
class AquariumEditScreen extends ConsumerStatefulWidget {
  const AquariumEditScreen({
    super.key,
    required this.aquariumId,
  });

  /// The ID of the aquarium to edit.
  final String aquariumId;

  @override
  ConsumerState<AquariumEditScreen> createState() => _AquariumEditScreenState();
}

class _AquariumEditScreenState extends ConsumerState<AquariumEditScreen> {
  late TextEditingController _nameController;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _initialName;
  Timer? _autoSaveTimer;

  static const _autoSaveDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    // Trigger rebuild to show/hide save button
    setState(() {});

    // Schedule auto-save with debounce
    _autoSaveTimer?.cancel();
    if (_hasNameChanged) {
      _autoSaveTimer = Timer(_autoSaveDelay, _autoSave);
    }
  }

  Future<void> _autoSave() async {
    if (!_hasNameChanged || _isSaving) return;
    await _saveName(showSuccessSnackbar: true);
  }

  void _initializeFromAquarium(String name) {
    if (_initialName == null) {
      _initialName = name;
      _nameController.text = name;
    }
  }

  bool get _hasNameChanged =>
      _initialName != null && _nameController.text.trim() != _initialName;

  Future<void> _saveName({bool showSuccessSnackbar = false}) async {
    if (!_hasNameChanged) return;

    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty || trimmedName.length > 50) return;

    // Cancel auto-save timer since we're saving now
    _autoSaveTimer?.cancel();

    setState(() {
      _isSaving = true;
    });

    final result = await ref.read(userAquariumsProvider.notifier).updateAquarium(
          aquariumId: widget.aquariumId,
          name: trimmedName,
        );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (result != null) {
        _initialName = trimmedName;
        if (showSuccessSnackbar) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.aquariumUpdated),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToUpdateAquarium),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteAquarium(String aquariumName) async {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteAquariumTitle(aquariumName)),
        content: Text(l.deleteAquariumConfirmation),
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

    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeleting = true;
    });

    final success = await ref
        .read(userAquariumsProvider.notifier)
        .deleteAquarium(widget.aquariumId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.aquariumDeleted),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go(AppRouter.home);
      } else {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.failedToDeleteAquarium),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToEditFish(String fishId) {
    context.push('/aquarium/fish/$fishId/edit');
  }

  Future<void> _deleteFish(Fish fish) async {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
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

    if (confirmed == true && mounted) {
      // Use direct deletion provider that works regardless of selected aquarium
      final result = await ref.read(deleteFishByIdProvider(fish.id).future);
      if (result && mounted) {
        // Refresh the fish list for this aquarium
        ref.invalidate(fishByAquariumIdProvider(widget.aquariumId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.fishDeletedSuccessfully),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.failedToSaveChanges),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _addFish() {
    context.push('${AppRouter.addFish}?aquariumId=${widget.aquariumId}');
  }

  @override
  Widget build(BuildContext context) {
    final aquarium = ref.watch(aquariumByIdProvider(widget.aquariumId));
    final l = AppLocalizations.of(context)!;

    if (aquarium == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l.editAquarium),
        ),
        body: _AquariumNotFoundState(),
      );
    }

    _initializeFromAquarium(aquarium.name);

    // Get fish for this aquarium directly from local storage
    final aquariumFish = ref.watch(fishByAquariumIdProvider(widget.aquariumId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l.editAquarium),
      ),
      body: _isDeleting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Aquarium Name Section
                  _NameSection(
                    controller: _nameController,
                    isSaving: _isSaving,
                    hasChanged: _hasNameChanged,
                    onSave: () => _saveName(showSuccessSnackbar: true),
                  ),
                  const SizedBox(height: 24),
                  // Fish Section
                  _FishSection(
                    fish: aquariumFish,
                    onEditFish: _navigateToEditFish,
                    onDeleteFish: _deleteFish,
                    onAddFish: _addFish,
                  ),
                  const SizedBox(height: 32),
                  // Delete Aquarium Button
                  _DeleteAquariumButton(
                    onDelete: () => _deleteAquarium(aquarium.name),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

/// Section for editing aquarium name.
class _NameSection extends StatelessWidget {
  const _NameSection({
    required this.controller,
    required this.isSaving,
    required this.hasChanged,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool isSaving;
  final bool hasChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.aquariumName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: controller,
                    hint: l.aquariumNameHint,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onSave(),
                  ),
                ),
                if (hasChanged) ...[
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: isSaving ? null : onSave,
                    icon: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Section displaying fish list with management options.
class _FishSection extends StatelessWidget {
  const _FishSection({
    required this.fish,
    required this.onEditFish,
    required this.onDeleteFish,
    required this.onAddFish,
  });

  final List<Fish> fish;
  final void Function(String fishId) onEditFish;
  final void Function(Fish fish) onDeleteFish;
  final VoidCallback onAddFish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.fishInAquarium(fish.length),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddFish,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l.addFish),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (fish.isEmpty)
              _EmptyFishState(onAddFish: onAddFish)
            else
              ...fish.map(
                (f) => _FishListTile(
                  fish: f,
                  onEdit: () => onEditFish(f.id),
                  onDelete: () => onDeleteFish(f),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Single fish list tile with edit/delete actions.
class _FishListTile extends StatelessWidget {
  const _FishListTile({
    required this.fish,
    required this.onEdit,
    required this.onDelete,
  });

  final Fish fish;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final species = SpeciesData.findById(fish.speciesId);
    final displayName = fish.name ?? species.name;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.set_meal_rounded,
          color: theme.colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(
        displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'x${fish.quantity}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: PopupMenuButton<_FishAction>(
        icon: Icon(
          Icons.more_vert,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onSelected: (action) {
          switch (action) {
            case _FishAction.edit:
              onEdit();
              break;
            case _FishAction.delete:
              onDelete();
              break;
          }
        },
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
                Icon(
                  Icons.delete_outlined,
                  color: theme.colorScheme.error,
                ),
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
      onTap: onEdit,
    );
  }
}

/// Empty state when aquarium has no fish.
class _EmptyFishState extends StatelessWidget {
  const _EmptyFishState({required this.onAddFish});

  final VoidCallback onAddFish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.pets_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              l.noFishInAquarium,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.addFishToAquarium,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Delete aquarium button with destructive styling.
class _DeleteAquariumButton extends StatelessWidget {
  const _DeleteAquariumButton({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onDelete,
        icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
        label: Text(l.deleteAquarium),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(color: theme.colorScheme.error),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

/// State shown when aquarium is not found.
class _AquariumNotFoundState extends StatelessWidget {
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
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              l.aquariumNotFound,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l.aquariumNotFoundDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: Text(l.goBack),
            ),
          ],
        ),
      ),
    );
  }
}

/// Actions available for fish items.
enum _FishAction {
  edit,
  delete,
}
