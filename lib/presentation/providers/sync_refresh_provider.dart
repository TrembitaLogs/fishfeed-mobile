import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/presentation/providers/calendar_data_provider.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/providers/statistics_provider.dart';

/// Provider that triggers UI refresh after successful sync.
///
/// Increment this value to signal that sync-dependent providers should refresh.
/// Widgets can watch this provider to react to sync completions.
///
/// Usage:
/// ```dart
/// final refreshCount = ref.watch(syncRefreshProvider);
/// ```
final syncRefreshProvider = StateProvider<int>((ref) => 0);

/// Extension method to invalidate sync-dependent providers.
///
/// Call this after successful sync to ensure UI reflects latest data
/// from both local changes that were synced and server events received.
///
/// Usage:
/// ```dart
/// // In a provider or notifier
/// ref.refreshAfterSync();
/// ```
extension SyncRefreshExtension on Ref {
  /// Invalidates all sync-dependent providers to refresh UI.
  ///
  /// Providers invalidated:
  /// - [todayFeedingsProvider] - Today's feeding schedule
  /// - [currentStreakProvider] - Current feeding streak
  /// - [calendarDataProvider] - Calendar month data
  /// - [statisticsProvider] - User statistics
  ///
  /// Also increments [syncRefreshProvider] to notify any listeners.
  void refreshAfterSync() {
    invalidate(todayFeedingsProvider);
    invalidate(currentStreakProvider);
    invalidate(calendarDataProvider);
    invalidate(statisticsProvider);
    read(syncRefreshProvider.notifier).state++;
  }
}
