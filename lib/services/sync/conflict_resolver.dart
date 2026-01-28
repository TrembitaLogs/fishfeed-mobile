import 'package:equatable/equatable.dart';

/// Result of conflict resolution between local and server data.
///
/// Determines which version should be kept when there's a conflict.
enum ConflictResolution {
  /// Use the local version (local timestamp is newer).
  useLocal,

  /// Use the server version (server timestamp is newer).
  useServer,

  /// Conflict requires manual user intervention.
  ///
  /// This happens when timestamps are very close (< 5 seconds)
  /// and the data differs significantly.
  requireManual,
}

/// Status of conflict for a synced entity.
///
/// Tracks whether an entity has unresolved conflicts.
enum ConflictStatus {
  /// No conflict exists.
  none,

  /// Conflict detected, awaiting resolution.
  pending,

  /// Conflict has been resolved.
  resolved,
}

/// Type of sync conflict between local and server data.
///
/// Determines how the conflict should be presented to the user
/// and what resolution options are available.
enum ConflictType {
  /// Both local and server modified the same entity.
  ///
  /// User chooses between local or server version.
  dataConflict,

  /// Server deleted the entity but it was modified locally.
  ///
  /// User chooses to restore (keep local) or delete permanently.
  deletionConflict,

  /// Same ID was created on both local and server independently.
  ///
  /// Rare case, usually handled by keeping both with different IDs.
  creationConflict,
}

/// Represents a detected conflict between local and server versions.
///
/// Contains both versions of the data and metadata about the conflict.
class SyncConflict<T> extends Equatable {
  const SyncConflict({
    required this.entityId,
    required this.entityType,
    required this.localVersion,
    required this.serverVersion,
    required this.localUpdatedAt,
    required this.serverUpdatedAt,
    required this.resolution,
    this.conflictType = ConflictType.dataConflict,
    this.conflictFields = const [],
    this.serverDeletedAt,
  });

  /// ID of the conflicting entity.
  final String entityId;

  /// Type of entity (e.g., 'feeding_event', 'aquarium').
  final String entityType;

  /// Local version of the data.
  final T localVersion;

  /// Server version of the data.
  final T serverVersion;

  /// When local version was last updated.
  final DateTime localUpdatedAt;

  /// When server version was last updated.
  final DateTime serverUpdatedAt;

  /// Recommended resolution for this conflict.
  final ConflictResolution resolution;

  /// Type of conflict (data, deletion, or creation).
  final ConflictType conflictType;

  /// List of field names that differ between versions.
  final List<String> conflictFields;

  /// When the server version was deleted (for deletion conflicts).
  final DateTime? serverDeletedAt;

  /// Time difference between local and server updates.
  Duration get timeDifference =>
      localUpdatedAt.difference(serverUpdatedAt).abs();

  /// Whether this conflict requires manual resolution.
  bool get requiresManualResolution =>
      resolution == ConflictResolution.requireManual;

  /// Whether this is a deletion conflict.
  bool get isDeletionConflict => conflictType == ConflictType.deletionConflict;

  /// Whether this is a creation conflict.
  bool get isCreationConflict => conflictType == ConflictType.creationConflict;

  @override
  List<Object?> get props => [
    entityId,
    entityType,
    localUpdatedAt,
    serverUpdatedAt,
    resolution,
    conflictType,
    conflictFields,
    serverDeletedAt,
  ];
}

/// Service for resolving conflicts between local and server data.
///
/// Implements last-write-wins strategy with special handling for
/// critical conflicts where timestamps are very close.
///
/// Example:
/// ```dart
/// final resolver = ConflictResolver();
/// final result = resolver.resolveConflict(
///   localUpdatedAt: localEvent.updatedAt,
///   serverUpdatedAt: serverEvent.updatedAt,
///   hasDataDifferences: localEvent.amount != serverEvent.amount,
/// );
///
/// switch (result) {
///   case ConflictResolution.useLocal:
///     // Push local to server
///     break;
///   case ConflictResolution.useServer:
///     // Pull server to local
///     break;
///   case ConflictResolution.requireManual:
///     // Show conflict UI to user
///     break;
/// }
/// ```
class ConflictResolver {
  ConflictResolver({this.criticalThreshold = const Duration(seconds: 5)});

  /// Time threshold below which conflicts with data differences
  /// are considered critical and require manual resolution.
  final Duration criticalThreshold;

  /// Resolves a conflict between local and server versions.
  ///
  /// Uses last-write-wins strategy:
  /// - If local is newer → [ConflictResolution.useLocal]
  /// - If server is newer → [ConflictResolution.useServer]
  /// - If timestamps are within [criticalThreshold] and data differs →
  ///   [ConflictResolution.requireManual]
  ///
  /// [localUpdatedAt] - Timestamp of local version.
  /// [serverUpdatedAt] - Timestamp of server version.
  /// [hasDataDifferences] - Whether the actual data content differs.
  ConflictResolution resolveConflict({
    required DateTime localUpdatedAt,
    required DateTime serverUpdatedAt,
    required bool hasDataDifferences,
  }) {
    final difference = localUpdatedAt.difference(serverUpdatedAt);
    final absDifference = difference.abs();

    // If timestamps are very close and data differs, require manual resolution
    if (absDifference < criticalThreshold && hasDataDifferences) {
      return ConflictResolution.requireManual;
    }

    // Last-write-wins: newer timestamp takes precedence
    if (difference.isNegative) {
      // Server is newer (local is behind)
      return ConflictResolution.useServer;
    } else {
      // Local is newer or equal (local takes precedence on tie)
      return ConflictResolution.useLocal;
    }
  }

  /// Detects and creates a conflict object for feeding events.
  ///
  /// Compares local and server versions and returns a [SyncConflict]
  /// with the appropriate resolution strategy.
  ///
  /// [localEvent] - Map representation of local feeding event.
  /// [serverEvent] - Map representation of server feeding event.
  /// [entityId] - ID of the feeding event.
  SyncConflict<Map<String, dynamic>> detectFeedingEventConflict({
    required Map<String, dynamic> localEvent,
    required Map<String, dynamic> serverEvent,
    required String entityId,
  }) {
    final localUpdatedAt =
        _parseDateTime(localEvent['updated_at']) ??
        _parseDateTime(localEvent['created_at']) ??
        DateTime.now();
    final serverUpdatedAt =
        _parseDateTime(serverEvent['updated_at']) ??
        _parseDateTime(serverEvent['created_at']) ??
        DateTime.now();

    final conflictFields = _findDifferingFields(localEvent, serverEvent);
    final hasDataDifferences = conflictFields.isNotEmpty;

    final resolution = resolveConflict(
      localUpdatedAt: localUpdatedAt,
      serverUpdatedAt: serverUpdatedAt,
      hasDataDifferences: hasDataDifferences,
    );

    return SyncConflict<Map<String, dynamic>>(
      entityId: entityId,
      entityType: 'feeding_event',
      localVersion: localEvent,
      serverVersion: serverEvent,
      localUpdatedAt: localUpdatedAt,
      serverUpdatedAt: serverUpdatedAt,
      resolution: resolution,
      conflictFields: conflictFields,
    );
  }

  /// Finds fields that differ between local and server versions.
  ///
  /// Ignores metadata fields like timestamps and sync status.
  List<String> _findDifferingFields(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    final ignoredFields = {
      'updated_at',
      'created_at',
      'server_updated_at',
      'synced',
      'conflict_status',
      'local_id',
    };

    final differingFields = <String>[];

    // Check all fields in local
    for (final key in local.keys) {
      if (ignoredFields.contains(key)) continue;

      final localValue = local[key];
      final serverValue = server[key];

      if (!_valuesEqual(localValue, serverValue)) {
        differingFields.add(key);
      }
    }

    // Check for fields only in server
    for (final key in server.keys) {
      if (ignoredFields.contains(key)) continue;
      if (local.containsKey(key)) continue;

      differingFields.add(key);
    }

    return differingFields;
  }

  /// Compares two values for equality, handling nulls and type differences.
  bool _valuesEqual(dynamic a, dynamic b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;

    // Handle DateTime comparison
    if (a is DateTime && b is DateTime) {
      return a.isAtSameMomentAs(b);
    }

    // Handle numeric comparison (int vs double)
    if (a is num && b is num) {
      return a == b;
    }

    return a == b;
  }

  /// Parses a DateTime from various formats.
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }
}
