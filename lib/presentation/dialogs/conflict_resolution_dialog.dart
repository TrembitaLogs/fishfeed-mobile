import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/services/sync/conflict_resolver.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

/// Dialog for resolving sync conflicts between local and server data.
///
/// Shows both versions side-by-side and allows user to choose which to keep.
/// Used when automatic conflict resolution cannot determine the correct version
/// (e.g., when timestamps are very close but data differs).
class ConflictResolutionDialog extends ConsumerWidget {
  const ConflictResolutionDialog({
    required this.conflict,
    super.key,
  });

  /// The conflict to resolve.
  final SyncConflict<Map<String, dynamic>> conflict;

  /// Shows the conflict resolution dialog.
  ///
  /// Returns `true` if local version was chosen, `false` if server version,
  /// or `null` if dialog was dismissed.
  static Future<bool?> show(
    BuildContext context,
    SyncConflict<Map<String, dynamic>> conflict,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConflictResolutionDialog(conflict: conflict),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final syncService = ref.watch(syncServiceProvider);
    final isDeletionConflict = conflict.isDeletionConflict;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isDeletionConflict
                ? Icons.delete_sweep_rounded
                : Icons.sync_problem_rounded,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isDeletionConflict
                  ? l10n.conflictDeletionTitle
                  : l10n.conflictDialogTitle,
              style: theme.textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isDeletionConflict
                    ? l10n.conflictDeletionDescription
                    : l10n.conflictDialogDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (conflict.conflictFields.isNotEmpty &&
                  !isDeletionConflict) ...[
                _ConflictFieldsList(
                  fields: conflict.conflictFields,
                  l10n: l10n,
                  theme: theme,
                ),
                const SizedBox(height: 16),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _VersionCard(
                      title: l10n.conflictLocalVersion,
                      timestamp: conflict.localUpdatedAt,
                      data: conflict.localVersion,
                      conflictFields: conflict.conflictFields,
                      isLocal: true,
                      isDeleted: false,
                      theme: theme,
                      l10n: l10n,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _VersionCard(
                      title: l10n.conflictServerVersion,
                      timestamp: conflict.serverUpdatedAt,
                      data: conflict.serverVersion,
                      conflictFields: conflict.conflictFields,
                      isLocal: false,
                      isDeleted: isDeletionConflict,
                      deletedAt: conflict.serverDeletedAt,
                      theme: theme,
                      l10n: l10n,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () async {
            await syncService.resolveConflictWithServer(conflict.entityId);
            if (context.mounted) {
              Navigator.of(context).pop(false);
            }
          },
          child: Text(
            isDeletionConflict
                ? l10n.conflictDeleteItem
                : l10n.conflictUseServerVersion,
          ),
        ),
        FilledButton(
          onPressed: () async {
            await syncService.resolveConflictWithLocal(conflict.entityId);
            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
          child: Text(
            isDeletionConflict
                ? l10n.conflictRestoreItem
                : l10n.conflictKeepMyVersion,
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    );
  }
}

class _ConflictFieldsList extends StatelessWidget {
  const _ConflictFieldsList({
    required this.fields,
    required this.l10n,
    required this.theme,
  });

  final List<String> fields;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.conflictDifferingFields,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: fields.map((field) {
              return Chip(
                label: Text(_formatFieldName(field)),
                labelStyle: theme.textTheme.bodySmall,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatFieldName(String field) {
    // Convert snake_case to Title Case
    return field
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.title,
    required this.timestamp,
    required this.data,
    required this.conflictFields,
    required this.isLocal,
    required this.theme,
    required this.l10n,
    this.isDeleted = false,
    this.deletedAt,
  });

  final String title;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final List<String> conflictFields;
  final bool isLocal;
  final ThemeData theme;
  final AppLocalizations l10n;
  final bool isDeleted;
  final DateTime? deletedAt;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMd().add_Hm();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDeleted
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
            : isLocal
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDeleted
              ? theme.colorScheme.error.withValues(alpha: 0.5)
              : isLocal
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDeleted
                    ? Icons.delete_rounded
                    : isLocal
                        ? Icons.phone_android_rounded
                        : Icons.cloud_rounded,
                size: 16,
                color: isDeleted
                    ? theme.colorScheme.error
                    : isLocal
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDeleted
                        ? theme.colorScheme.error
                        : isLocal
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (isDeleted && deletedAt != null) ...[
            Text(
              l10n.conflictDeletedOn(dateFormat.format(deletedAt!)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            Text(
              dateFormat.format(timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (!isDeleted) ...[
            const Divider(height: 16),
            ...conflictFields.map((field) {
              final value = data[field];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _FieldRow(
                  field: field,
                  value: value,
                  theme: theme,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.field,
    required this.value,
    required this.theme,
  });

  final String field;
  final dynamic value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            _formatFieldName(field),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _formatValue(value),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatFieldName(String field) {
    return field
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  String _formatValue(dynamic value) {
    if (value == null) return '-';
    if (value is DateTime) {
      return DateFormat.yMd().add_Hm().format(value);
    }
    if (value is double) {
      return value.toStringAsFixed(1);
    }
    return value.toString();
  }
}

/// Shows pending conflicts dialog when there are unresolved conflicts.
///
/// This widget should be placed high in the widget tree to listen for
/// conflicts and show dialogs as needed.
class ConflictResolutionListener extends ConsumerWidget {
  const ConflictResolutionListener({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);

    // Listen for new conflicts
    ref.listen<AsyncValue<SyncConflict<Map<String, dynamic>>?>>(
      pendingConflictProvider,
      (previous, next) {
        next.whenData((conflict) {
          if (conflict != null) {
            final prevConflict = previous?.valueOrNull;
            if (prevConflict?.entityId != conflict.entityId) {
              // Show conflict dialog
              _showConflictDialog(context, conflict);
            }
          }
        });
      },
    );

    // Check for existing conflicts on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (syncService.hasUnresolvedConflicts) {
        final conflict = syncService.pendingConflicts.first;
        _showConflictDialog(context, conflict);
      }
    });

    return child;
  }

  void _showConflictDialog(
    BuildContext context,
    SyncConflict<Map<String, dynamic>> conflict,
  ) {
    ConflictResolutionDialog.show(context, conflict);
  }
}

/// Provider for the next pending conflict that needs resolution.
final pendingConflictProvider =
    StreamProvider<SyncConflict<Map<String, dynamic>>?>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.conflictStream.map((conflict) => conflict);
});

/// Provider for the list of all pending conflicts.
final pendingConflictsProvider =
    Provider<List<SyncConflict<Map<String, dynamic>>>>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.pendingConflicts;
});

/// Provider for whether there are unresolved conflicts.
final hasUnresolvedConflictsProvider = Provider<bool>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.hasUnresolvedConflicts;
});
