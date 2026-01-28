import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:storage_space/storage_space.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Minimum recommended free storage in MB.
const int kLowStorageThresholdMb = 100;

/// Result of a storage check.
class StorageInfo {
  const StorageInfo({
    required this.freeSpaceMb,
    required this.cacheSizeMb,
    required this.isLowStorage,
  });

  /// Free disk space in megabytes.
  final double freeSpaceMb;

  /// App cache size in megabytes.
  final double cacheSizeMb;

  /// Whether the device is low on storage (below threshold).
  final bool isLowStorage;

  /// Creates a copy with updated values.
  StorageInfo copyWith({
    double? freeSpaceMb,
    double? cacheSizeMb,
    bool? isLowStorage,
  }) {
    return StorageInfo(
      freeSpaceMb: freeSpaceMb ?? this.freeSpaceMb,
      cacheSizeMb: cacheSizeMb ?? this.cacheSizeMb,
      isLowStorage: isLowStorage ?? this.isLowStorage,
    );
  }
}

/// Service for managing device storage and app cache.
///
/// Provides functionality to:
/// - Check available disk space
/// - Calculate app cache size
/// - Clear app cache
/// - Detect low storage conditions
class StorageService {
  StorageService();

  /// Checks the current storage status.
  ///
  /// Returns [StorageInfo] with free space, cache size, and low storage flag.
  Future<StorageInfo> checkStorage() async {
    try {
      final freeSpaceMb = await _getFreeSpace();
      final cacheSizeMb = await _getCacheSize();
      final isLowStorage = freeSpaceMb < kLowStorageThresholdMb;

      debugPrint(
        'StorageService: Free space: ${freeSpaceMb.toStringAsFixed(1)} MB, '
        'Cache: ${cacheSizeMb.toStringAsFixed(1)} MB, '
        'Low storage: $isLowStorage',
      );

      return StorageInfo(
        freeSpaceMb: freeSpaceMb,
        cacheSizeMb: cacheSizeMb,
        isLowStorage: isLowStorage,
      );
    } catch (e) {
      debugPrint('StorageService: Error checking storage: $e');
      // Return safe defaults on error
      return const StorageInfo(
        freeSpaceMb: double.infinity,
        cacheSizeMb: 0,
        isLowStorage: false,
      );
    }
  }

  /// Gets the free disk space in megabytes.
  Future<double> _getFreeSpace() async {
    try {
      final storageSpace = await getStorageSpace(
        lowOnSpaceThreshold: kLowStorageThresholdMb * 1024 * 1024,
        fractionDigits: 1,
      );
      // Convert bytes to MB
      return (storageSpace.free ?? 0) / (1024 * 1024);
    } catch (e) {
      debugPrint('StorageService: Error getting free space: $e');
      return double.infinity;
    }
  }

  /// Calculates the app cache size in megabytes.
  Future<double> _getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final size = await _getDirectorySize(cacheDir);
      return size / (1024 * 1024); // Convert to MB
    } catch (e) {
      debugPrint('StorageService: Error getting cache size: $e');
      return 0;
    }
  }

  /// Recursively calculates directory size in bytes.
  Future<int> _getDirectorySize(Directory dir) async {
    int size = 0;
    try {
      if (await dir.exists()) {
        await for (final entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            try {
              size += await entity.length();
            } catch (_) {
              // Skip files we can't read
            }
          }
        }
      }
    } catch (e) {
      debugPrint('StorageService: Error calculating directory size: $e');
    }
    return size;
  }

  /// Clears the app cache.
  ///
  /// Returns the amount of space freed in megabytes.
  Future<double> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final sizeBefore = await _getDirectorySize(cacheDir);

      await _clearDirectory(cacheDir);

      final sizeAfter = await _getDirectorySize(cacheDir);
      final freedMb = (sizeBefore - sizeAfter) / (1024 * 1024);

      debugPrint(
        'StorageService: Cleared ${freedMb.toStringAsFixed(1)} MB of cache',
      );

      return freedMb;
    } catch (e) {
      debugPrint('StorageService: Error clearing cache: $e');
      return 0;
    }
  }

  /// Recursively deletes contents of a directory.
  Future<void> _clearDirectory(Directory dir) async {
    try {
      if (await dir.exists()) {
        await for (final entity in dir.list(followLinks: false)) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } catch (e) {
            debugPrint('StorageService: Error deleting ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('StorageService: Error clearing directory: $e');
    }
  }

  /// Checks if there's enough space for a download of the given size.
  ///
  /// [sizeMb] - The size of the download in megabytes.
  /// Returns true if there's enough space, false otherwise.
  Future<bool> hasSpaceForDownload(double sizeMb) async {
    try {
      final freeSpace = await _getFreeSpace();
      // Require at least the download size plus the threshold for safety
      return freeSpace >= (sizeMb + kLowStorageThresholdMb);
    } catch (e) {
      debugPrint('StorageService: Error checking download space: $e');
      return true; // Allow download on error
    }
  }
}

/// Provider for the storage service.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider for the current storage info.
///
/// Use this to check storage status and show warnings.
final storageInfoProvider = FutureProvider<StorageInfo>((ref) async {
  final service = ref.watch(storageServiceProvider);
  return service.checkStorage();
});

/// Provider that returns true when storage is low.
final isLowStorageProvider = Provider<bool>((ref) {
  final asyncValue = ref.watch(storageInfoProvider);
  return asyncValue.maybeWhen(
    data: (info) => info.isLowStorage,
    orElse: () => false,
  );
});
