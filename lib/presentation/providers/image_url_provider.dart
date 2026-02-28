import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/config/api_config.dart';
import 'package:fishfeed/data/datasources/remote/api_client.dart';

// ============ Request ============

/// A request item for batch presigned URL fetching.
///
/// Contains the entity identification and its current [photoKey] value,
/// which is used for cache lookup and `local://` filtering.
class ImageUrlRequest {
  const ImageUrlRequest({
    required this.entityType,
    required this.entityId,
    this.photoKey,
  });

  /// The entity type: `"aquarium"`, `"fish"`, or `"avatar"`.
  final String entityType;

  /// The entity's unique identifier.
  final String entityId;

  /// The current S3 object key (or `local://...` or `null`).
  final String? photoKey;
}

// ============ Cache Entry ============

/// A cached presigned URL with expiration tracking.
///
/// Stores the presigned URL along with the [photoKey] that was current
/// when the URL was generated. This allows cache invalidation when the
/// entity's photo changes (new upload produces a different [photoKey]).
@visibleForTesting
class CachedUrl {
  CachedUrl({
    required this.url,
    required this.photoKey,
    required this.expiresAt,
  });

  /// The presigned URL for downloading the image from S3.
  final String url;

  /// The S3 object key that was current when this URL was generated.
  /// Used to detect when a new photo has been uploaded.
  final String photoKey;

  /// When this cache entry expires (based on [ImageUrlProvider.cacheTtl]).
  final DateTime expiresAt;

  /// Whether the TTL has elapsed.
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

// ============ ImageUrlProvider ============

/// Provides presigned URLs for entity images via the batch API.
///
/// Uses in-memory cache with configurable TTL (default 50 minutes, leaving
/// a 10-minute margin before the server-side 1-hour URL expiration).
///
/// The provider is lazy: URLs are only fetched when explicitly requested
/// by the UI for visible entities. This avoids generating hundreds of
/// presigned URLs at sync time for entities the user may never view.
///
/// Cache invalidation happens automatically when:
/// - The TTL expires
/// - The entity's [photoKey] changes (detected by comparing the key
///   stored in the cache entry with the one passed to [getUrl])
///
/// Usage:
/// ```dart
/// final url = await ref.read(imageUrlProviderInstance).getUrl(
///   entityType: 'aquarium',
///   entityId: aquariumId,
///   photoKey: aquarium.photoKey,
/// );
/// ```
class ImageUrlProvider {
  ImageUrlProvider({required Dio dio, Duration? cacheTtl})
    : _dio = dio,
      _cacheTtl = cacheTtl ?? defaultCacheTtl;

  /// Default cache TTL: 50 minutes (10-min margin before 1-hour URL expiry).
  static const Duration defaultCacheTtl = Duration(minutes: 50);

  /// Maximum number of items per batch request to `POST /images/urls`.
  ///
  /// The server enforces a limit of 50 items per request. Requests with
  /// more items are split into sequential chunks of this size.
  @visibleForTesting
  static const int maxBatchSize = 50;

  /// Maximum consecutive [refreshUrl] calls for the same entity before
  /// giving up and returning `null`.
  ///
  /// Prevents infinite 403 → refresh → 403 loops when an image is
  /// permanently inaccessible (e.g., deleted from S3, wrong permissions).
  /// The counter resets when:
  /// - [getUrl] serves a cached URL (meaning the previous URL worked)
  /// - [clearCache] is called (e.g., on logout)
  /// - A different [photoKey] is passed to [getUrl] (new photo uploaded)
  @visibleForTesting
  static const int maxRefreshRetries = 3;

  final Dio _dio;
  final Duration _cacheTtl;

  /// In-memory cache keyed by "entityType:entityId".
  final Map<String, CachedUrl> _urlCache = {};

  /// Consecutive [refreshUrl] attempt counts per entity.
  ///
  /// Incremented by [refreshUrl], reset by [getUrl] on cache hit or
  /// photoKey change, and cleared by [clearCache].
  final Map<String, int> _refreshRetries = {};

  /// The configured cache TTL. Exposed for testing.
  @visibleForTesting
  Duration get cacheTtl => _cacheTtl;

  /// Number of entries in the cache. Exposed for testing.
  @visibleForTesting
  int get cacheSize => _urlCache.length;

  /// Number of entities with active refresh retry counters. Exposed for testing.
  @visibleForTesting
  int get refreshRetryCount => _refreshRetries.length;

  /// Returns a presigned URL for the entity's image.
  ///
  /// Returns `null` immediately if:
  /// - [photoKey] is `null` (entity has no photo)
  /// - [photoKey] starts with `local://` (upload still pending)
  ///
  /// Uses the in-memory cache when available and not expired.
  /// On cache miss, fetches a fresh URL from `POST /images/urls`.
  ///
  /// The [photoKey] is also used for cache invalidation: if the entity's
  /// photo has changed since the last fetch, the cached URL is discarded.
  Future<String?> getUrl({
    required String entityType,
    required String entityId,
    String? photoKey,
  }) async {
    if (photoKey == null) return null;
    if (photoKey.startsWith('local://')) return null;

    final key = _cacheKey(entityType, entityId);
    final cached = _urlCache[key];

    if (cached != null && !cached.isExpired && cached.photoKey == photoKey) {
      // Cache hit with matching key — the previous URL is working fine.
      _refreshRetries.remove(key);
      return cached.url;
    }

    // Any cache miss resets the retry counter. The counter only accumulates
    // through consecutive refreshUrl() calls (403 recovery loop). A getUrl()
    // call represents a fresh attempt (new screen, re-mount, photoKey change).
    _refreshRetries.remove(key);

    return _fetchUrl(
      entityType: entityType,
      entityId: entityId,
      photoKey: photoKey,
    );
  }

  /// Invalidates the cache for an entity and fetches a fresh URL.
  ///
  /// Useful when a presigned URL returns 403 (expired) — the caller
  /// can request a new one without waiting for the TTL to elapse.
  ///
  /// Returns `null` if:
  /// - [photoKey] is `null` or starts with `local://`
  /// - The retry limit ([maxRefreshRetries]) has been reached for this entity
  ///
  /// The retry counter is incremented on each call and reset when [getUrl]
  /// successfully serves a cached URL or receives a new [photoKey].
  Future<String?> refreshUrl({
    required String entityType,
    required String entityId,
    String? photoKey,
  }) async {
    final key = _cacheKey(entityType, entityId);
    _urlCache.remove(key);

    if (photoKey == null || photoKey.startsWith('local://')) return null;

    final retries = _refreshRetries[key] ?? 0;
    if (retries >= maxRefreshRetries) {
      debugPrint(
        'ImageUrlProvider: max refresh retries ($maxRefreshRetries) '
        'reached for $key, returning null',
      );
      return null;
    }
    _refreshRetries[key] = retries + 1;

    return _fetchUrl(
      entityType: entityType,
      entityId: entityId,
      photoKey: photoKey,
    );
  }

  /// Batch fetch presigned URLs for multiple entities.
  ///
  /// For each [ImageUrlRequest]:
  /// - Items with `null` or `local://` photoKey get `null` immediately.
  /// - Items already in the cache (valid TTL, matching photoKey) are served
  ///   from cache without a network call.
  /// - Remaining items are fetched from the server in sequential chunks
  ///   of [maxBatchSize] (50) to respect the server-side limit.
  ///
  /// Returns a map keyed by `"entityType:entityId"` with presigned URL
  /// strings (or `null` for items with no photo / pending upload / no access).
  ///
  /// Network errors for individual chunks are caught — the corresponding
  /// items will have `null` values in the result map. Other chunks are
  /// still processed.
  Future<Map<String, String?>> getUrls(List<ImageUrlRequest> items) async {
    final results = <String, String?>{};
    final toFetch = <ImageUrlRequest>[];

    for (final item in items) {
      final key = _cacheKey(item.entityType, item.entityId);

      // Skip null or local:// keys
      if (item.photoKey == null || item.photoKey!.startsWith('local://')) {
        results[key] = null;
        continue;
      }

      // Serve from cache if valid
      final cached = _urlCache[key];
      if (cached != null &&
          !cached.isExpired &&
          cached.photoKey == item.photoKey) {
        results[key] = cached.url;
        continue;
      }

      toFetch.add(item);
    }

    // Fetch remaining items in sequential chunks
    for (var i = 0; i < toFetch.length; i += maxBatchSize) {
      final end = i + maxBatchSize;
      final chunk = toFetch.sublist(
        i,
        end > toFetch.length ? toFetch.length : end,
      );

      try {
        final response = await _dio.post<Map<String, dynamic>>(
          ApiEndpoints.imageUrls,
          data: {
            'items': chunk
                .map(
                  (r) => {'entity_type': r.entityType, 'entity_id': r.entityId},
                )
                .toList(),
          },
        );

        final responseItems = response.data?['items'] as List<dynamic>? ?? [];

        for (final responseItem in responseItems) {
          final item = responseItem as Map<String, dynamic>;
          final entityType = item['entity_type'] as String;
          final entityId = item['entity_id'] as String;
          final url = _rewriteUrlForEmulator(item['url'] as String?);
          final key = _cacheKey(entityType, entityId);

          results[key] = url;

          if (url != null) {
            // Find the matching request to get photoKey for cache storage.
            final request = chunk.firstWhere(
              (r) => r.entityType == entityType && r.entityId == entityId,
            );
            _urlCache[key] = CachedUrl(
              url: url,
              photoKey: request.photoKey!,
              expiresAt: DateTime.now().add(_cacheTtl),
            );
          }
        }

        // Items not in response = no access (server omits them)
        for (final item in chunk) {
          final key = _cacheKey(item.entityType, item.entityId);
          results.putIfAbsent(key, () => null);
        }
      } on DioException catch (e) {
        debugPrint('ImageUrlProvider: batch chunk failed: ${e.message}');
        for (final item in chunk) {
          final key = _cacheKey(item.entityType, item.entityId);
          results.putIfAbsent(key, () => null);
        }
      }
    }

    return results;
  }

  /// Removes the cached URL for a specific entity without re-fetching.
  ///
  /// Useful when you know the URL is stale but don't need a new one yet
  /// (e.g., the entity's photo was deleted locally).
  void invalidateUrl({required String entityType, required String entityId}) {
    _urlCache.remove(_cacheKey(entityType, entityId));
  }

  /// Removes all cached URLs and resets retry counters.
  void clearCache() {
    _urlCache.clear();
    _refreshRetries.clear();
  }

  /// Fetches a single presigned URL from the server.
  ///
  /// Sends a batch request with one item to `POST /images/urls`.
  /// The server looks up the entity's current `photo_key` in the DB
  /// and returns a presigned GET URL (the client never sends the key).
  Future<String?> _fetchUrl({
    required String entityType,
    required String entityId,
    required String photoKey,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.imageUrls,
      data: {
        'items': <Map<String, dynamic>>[
          {'entity_type': entityType, 'entity_id': entityId},
        ],
      },
    );

    final items = response.data?['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return null;

    final item = items.first as Map<String, dynamic>;
    final url = _rewriteUrlForEmulator(item['url'] as String?);

    if (url != null) {
      _urlCache[_cacheKey(entityType, entityId)] = CachedUrl(
        url: url,
        photoKey: photoKey,
        expiresAt: DateTime.now().add(_cacheTtl),
      );
    }

    return url;
  }

  /// Rewrites presigned URLs for Android emulator compatibility.
  ///
  /// In dev, the backend generates presigned URLs with `localhost` as the
  /// host (via S3_PRESIGNED_ENDPOINT_URL). The Android emulator cannot
  /// reach `localhost` — it needs `10.0.2.2` to access the host machine.
  /// iOS simulator shares the host network, so no rewrite is needed.
  static String? _rewriteUrlForEmulator(String? url) {
    if (url == null) return null;
    if (!kDebugMode || !Platform.isAndroid) return url;
    return url.replaceFirst('://localhost:', '://10.0.2.2:');
  }

  /// Builds a cache key from entity type and ID.
  String _cacheKey(String entityType, String entityId) =>
      '$entityType:$entityId';
}

// ============ Riverpod Providers ============

/// Singleton provider for [ImageUrlProvider].
///
/// Uses the app's configured [Dio] instance with full interceptor chain
/// (auth, token refresh, retry, error handling).
final imageUrlProvider = Provider<ImageUrlProvider>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ImageUrlProvider(dio: apiClient.dio);
});

/// Parameter for [photoUrlProvider].
///
/// Uses a Dart record for structural equality, which ensures
/// [FutureProvider.family] correctly deduplicates and caches results.
typedef PhotoUrlParam = ({
  String entityType,
  String entityId,
  String? photoKey,
});

/// Provides an [AsyncValue<String?>] for a single entity's presigned image URL.
///
/// Returns:
/// - `AsyncData(url)` — presigned URL ready for [CachedNetworkImage]
/// - `AsyncData(null)` — no photo, `local://` key, or no access
/// - `AsyncLoading()` — fetching URL from server
/// - `AsyncError(e, st)` — network or server error
///
/// Auto-disposed when no longer watched (e.g., widget unmounted).
/// Re-watching triggers [ImageUrlProvider.getUrl] which serves from
/// its in-memory cache when available (instant, no network call).
///
/// Usage:
/// ```dart
/// final urlAsync = ref.watch(photoUrlProvider((
///   entityType: 'aquarium',
///   entityId: aquarium.id,
///   photoKey: aquarium.photoKey,
/// )));
/// urlAsync.when(
///   data: (url) => url != null
///       ? CachedNetworkImage(imageUrl: url, cacheKey: aquarium.photoKey!)
///       : const PlaceholderWidget(),
///   loading: () => const ShimmerPlaceholder(),
///   error: (_, __) => const ErrorPlaceholder(),
/// );
/// ```
final photoUrlProvider = FutureProvider.autoDispose
    .family<String?, PhotoUrlParam>((ref, param) async {
      final provider = ref.watch(imageUrlProvider);
      return provider.getUrl(
        entityType: param.entityType,
        entityId: param.entityId,
        photoKey: param.photoKey,
      );
    });
