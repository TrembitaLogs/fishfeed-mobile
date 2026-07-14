import 'package:hive_flutter/hive_flutter.dart';

part 'sync_metadata_model.g.dart';

/// Hive model for sync metadata tracking.
///
/// Stores information about the last successful sync operation
/// to enable delta sync (only fetching changes since last sync).
@HiveType(typeId: 22)
class SyncMetadataModel extends HiveObject {
  SyncMetadataModel({
    this.lastSyncAt,
    this.syncToken,
    this.cursor,
    this.recoveryFullSyncDone = false,
    this.hadLocalData = false,
  });

  /// Timestamp of the last successful sync.
  ///
  /// Used for delta sync - server returns only changes after this time.
  @HiveField(0)
  DateTime? lastSyncAt;

  /// Token received from server after last sync.
  ///
  /// Used to verify sync state consistency with server.
  @HiveField(1)
  String? syncToken;

  /// Pagination cursor for resuming interrupted syncs.
  ///
  /// If sync was interrupted, this allows resuming from where it stopped.
  @HiveField(2)
  String? cursor;

  /// Whether the one-time post-upgrade recovery full sync has run.
  ///
  /// Set once after the first successful full sync following the deletion-bug
  /// fix, so a stale local tombstone for a still-alive aquarium is reconciled
  /// against the server exactly once (a delta sync omits unchanged-alive rows
  /// and would leave a purged/hidden aquarium unrecoverable). See deletion
  /// bug #2.
  @HiveField(3, defaultValue: false)
  bool recoveryFullSyncDone;

  /// Whether the last successful sync left local entity data present.
  ///
  /// Distinguishes a background-isolate box wipe (we HAD data, now the
  /// aquariums box is empty -> force a recovery full sync) from an account that
  /// legitimately has no aquariums yet (never had data -> keep using delta).
  /// Self-correcting: refreshed to `localAquariumCount > 0` after every
  /// successful sync, so a genuinely empty account converges to false after a
  /// single full sync instead of forcing a full sync forever. Lives in the
  /// syncMetadata box, which the notification-refill background isolate never
  /// opens, so it survives the wipe it is used to detect.
  @HiveField(4, defaultValue: false)
  bool hadLocalData;

  /// Whether this is the first sync (initial sync).
  bool get isInitialSync => lastSyncAt == null;

  /// Updates metadata after a successful sync.
  void updateAfterSync({
    required DateTime syncTime,
    required String token,
    String? nextCursor,
  }) {
    lastSyncAt = syncTime;
    syncToken = token;
    cursor = nextCursor;
    save();
  }

  /// Resets metadata for a fresh full sync.
  void reset() {
    lastSyncAt = null;
    syncToken = null;
    cursor = null;
    save();
  }
}
