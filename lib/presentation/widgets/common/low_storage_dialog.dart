import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/services/storage/storage_service.dart';

/// A dialog that warns the user about low storage.
///
/// Provides options to clear the cache or dismiss the warning.
class LowStorageDialog extends ConsumerStatefulWidget {
  const LowStorageDialog({
    super.key,
    required this.freeSpaceMb,
  });

  /// The current free space in megabytes.
  final double freeSpaceMb;

  /// Shows the low storage warning dialog.
  ///
  /// Returns true if the user cleared the cache, false otherwise.
  static Future<bool> show(BuildContext context, double freeSpaceMb) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LowStorageDialog(freeSpaceMb: freeSpaceMb),
    );
    return result ?? false;
  }

  @override
  ConsumerState<LowStorageDialog> createState() => _LowStorageDialogState();
}

class _LowStorageDialogState extends ConsumerState<LowStorageDialog> {
  bool _isClearing = false;

  Future<void> _clearCache() async {
    setState(() => _isClearing = true);

    try {
      final storageService = ref.read(storageServiceProvider);
      await storageService.clearCache();

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cacheCleared),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: Icon(
        Icons.storage_rounded,
        size: 48,
        color: colorScheme.error,
      ),
      title: Text(l10n.lowStorageTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.lowStorageDescription(kLowStorageThresholdMb),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_rounded,
                  size: 20,
                  color: colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.freeSpaceMb.toStringAsFixed(0)} MB',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isClearing ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.lowStorageDismiss),
        ),
        FilledButton.icon(
          onPressed: _isClearing ? null : _clearCache,
          icon: _isClearing
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.delete_sweep_rounded, size: 18),
          label: Text(l10n.lowStorageClearCache),
        ),
      ],
    );
  }
}

/// Mixin for widgets that should check storage on initialization.
///
/// Add this to a StatefulWidget or ConsumerStatefulWidget to automatically
/// check storage when the widget is mounted.
mixin StorageCheckMixin<T extends StatefulWidget> on State<T> {
  bool _hasCheckedStorage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkStorageIfNeeded();
  }

  Future<void> _checkStorageIfNeeded() async {
    if (_hasCheckedStorage) return;
    _hasCheckedStorage = true;

    // Delay slightly to ensure the widget is fully built
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final storageService = StorageService();
    final info = await storageService.checkStorage();

    if (info.isLowStorage && mounted) {
      await LowStorageDialog.show(context, info.freeSpaceMb);
    }
  }
}

/// Provider-based widget for checking storage on app startup.
///
/// Add this widget near the root of your widget tree to check storage
/// when the app starts.
class StorageCheckWidget extends ConsumerStatefulWidget {
  const StorageCheckWidget({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<StorageCheckWidget> createState() => _StorageCheckWidgetState();
}

class _StorageCheckWidgetState extends ConsumerState<StorageCheckWidget> {
  bool _hasCheckedStorage = false;

  @override
  void initState() {
    super.initState();
    _checkStorage();
  }

  Future<void> _checkStorage() async {
    if (_hasCheckedStorage) return;
    _hasCheckedStorage = true;

    // Delay to ensure app is fully loaded
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final info = await ref.read(storageInfoProvider.future);

    if (info.isLowStorage && mounted) {
      await LowStorageDialog.show(context, info.freeSpaceMb);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
