import 'package:hive_flutter/hive_flutter.dart';

part 'sync_metadata_model.g.dart';

/// Hive model for sync metadata tracking.
///
/// Stores information about the last successful sync operation
/// to enable delta sync (only fetching changes since last sync).
@HiveType(typeId: 22)
class SyncMetadataModel extends HiveObject {
  SyncMetadataModel({this.lastSyncAt, this.syncToken, this.cursor});

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
