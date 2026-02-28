import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/data/datasources/remote/api_client.dart';
import 'package:fishfeed/presentation/providers/image_url_provider.dart';

// --- Mocks ---

class MockDio extends Mock implements Dio {}

class MockApiClient extends Mock implements ApiClient {}

class MockImageUrlProvider extends Mock implements ImageUrlProvider {}

// --- Helpers ---

/// Creates a successful Dio response with the given items.
Response<Map<String, dynamic>> _successResponse(
  List<Map<String, dynamic>> items,
) {
  return Response<Map<String, dynamic>>(
    data: {'items': items},
    statusCode: 200,
    requestOptions: RequestOptions(path: '/images/urls'),
  );
}

void main() {
  late MockDio mockDio;
  late ImageUrlProvider provider;

  setUp(() {
    mockDio = MockDio();
    provider = ImageUrlProvider(dio: mockDio);
  });

  // ---------------------------------------------------------------------------
  // CachedUrl
  // ---------------------------------------------------------------------------
  group('CachedUrl', () {
    test('isExpired returns false when expiresAt is in the future', () {
      final cached = CachedUrl(
        url: 'https://s3.example.com/image.webp',
        photoKey: 'aquariums/abc/f7a3b.webp',
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
      );

      expect(cached.isExpired, isFalse);
    });

    test('isExpired returns true when expiresAt is in the past', () {
      final cached = CachedUrl(
        url: 'https://s3.example.com/image.webp',
        photoKey: 'aquariums/abc/f7a3b.webp',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      expect(cached.isExpired, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Default TTL
  // ---------------------------------------------------------------------------
  group('cache TTL', () {
    test('default cacheTtl is 50 minutes', () {
      expect(provider.cacheTtl, const Duration(minutes: 50));
    });

    test('custom cacheTtl is used when provided', () {
      final custom = ImageUrlProvider(
        dio: mockDio,
        cacheTtl: const Duration(minutes: 10),
      );
      expect(custom.cacheTtl, const Duration(minutes: 10));
    });
  });

  // ---------------------------------------------------------------------------
  // getUrl — null and local:// handling
  // ---------------------------------------------------------------------------
  group('getUrl - null and local:// keys', () {
    test('returns null for null photoKey', () async {
      final url = await provider.getUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: null,
      );

      expect(url, isNull);
      verifyZeroInteractions(mockDio);
    });

    test('returns null for local:// photoKey', () async {
      final url = await provider.getUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'local://a1b2c3d4-e5f6-7890-abcd-ef1234567890',
      );

      expect(url, isNull);
      verifyZeroInteractions(mockDio);
    });

    test('returns null for local:// with arbitrary suffix', () async {
      final url = await provider.getUrl(
        entityType: 'fish',
        entityId: 'fish-1',
        photoKey: 'local://anything',
      );

      expect(url, isNull);
      verifyZeroInteractions(mockDio);
    });
  });

  // ---------------------------------------------------------------------------
  // getUrl — API fetch
  // ---------------------------------------------------------------------------
  group('getUrl - API fetch', () {
    test('fetches URL from server on cache miss', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': 'aquariums/aq-1/f7a3b.webp',
            'url': 'https://s3.example.com/presigned?sig=abc',
          },
        ]),
      );

      final url = await provider.getUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/f7a3b.webp',
      );

      expect(url, 'https://s3.example.com/presigned?sig=abc');
      verify(
        () => mockDio.post<Map<String, dynamic>>(
          '/images/urls',
          data: {
            'items': [
              {'entity_type': 'aquarium', 'entity_id': 'aq-1'},
            ],
          },
        ),
      ).called(1);
    });

    test('returns null when server returns empty items', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer((_) async => _successResponse([]));

      final url = await provider.getUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/f7a3b.webp',
      );

      expect(url, isNull);
    });

    test(
      'returns null when server returns null url (entity has no photo)',
      () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => _successResponse([
            {
              'entity_type': 'aquarium',
              'entity_id': 'aq-1',
              'key': null,
              'url': null,
            },
          ]),
        );

        final url = await provider.getUrl(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'aquariums/aq-1/f7a3b.webp',
        );

        expect(url, isNull);
        // Should NOT cache null URLs
        expect(provider.cacheSize, 0);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // getUrl — caching
  // ---------------------------------------------------------------------------
  group('getUrl - caching', () {
    test('returns cached URL on second call with same photoKey', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': 'aquariums/aq-1/f7a3b.webp',
            'url': 'https://s3.example.com/presigned?sig=abc',
          },
        ]),
      );

      // First call — fetches from server
      final url1 = await provider.getUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/f7a3b.webp',
      );

      // Second call — should use cache
      final url2 = await provider.getUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/f7a3b.webp',
      );

      expect(url1, 'https://s3.example.com/presigned?sig=abc');
      expect(url2, 'https://s3.example.com/presigned?sig=abc');

      // Dio should only be called once
      verify(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).called(1);
    });

    test('invalidates cache when photoKey changes (new upload)', () async {
      var callCount = 0;

      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer((_) async {
        callCount++;
        return _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': 'aquariums/aq-1/new-key.webp',
            'url': 'https://s3.example.com/presigned?sig=v$callCount',
          },
        ]);
      });

      // First call with original photoKey
      await provider.getUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/old-key.webp',
      );

      // Second call with DIFFERENT photoKey (user uploaded a new photo)
      final url = await provider.getUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/new-key.webp',
      );

      // Should have made two API calls (cache invalidated by key change)
      expect(callCount, 2);
      expect(url, 'https://s3.example.com/presigned?sig=v2');
    });

    test('re-fetches when cache TTL expires', () async {
      // Use a very short TTL for testing
      final shortTtlProvider = ImageUrlProvider(
        dio: mockDio,
        cacheTtl: Duration.zero,
      );

      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': 'aquariums/aq-1/f7a3b.webp',
            'url': 'https://s3.example.com/presigned?sig=abc',
          },
        ]),
      );

      // First call
      await shortTtlProvider.getUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/f7a3b.webp',
      );

      // Second call — TTL is zero, so cache should be expired
      await shortTtlProvider.getUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/f7a3b.webp',
      );

      // Should have made two API calls
      verify(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).called(2);
    });

    test('caches different entities independently', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': 'aquariums/aq-1/abc.webp',
            'url': 'https://s3.example.com/aquarium-url',
          },
        ]),
      );

      await provider.getUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/abc.webp',
      );

      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _successResponse([
          {
            'entity_type': 'fish',
            'entity_id': 'fish-1',
            'key': 'fish/fish-1/def.webp',
            'url': 'https://s3.example.com/fish-url',
          },
        ]),
      );

      await provider.getUrl(
        entityType: 'fish',
        entityId: 'fish-1',
        photoKey: 'fish/fish-1/def.webp',
      );

      expect(provider.cacheSize, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // refreshUrl
  // ---------------------------------------------------------------------------
  group('refreshUrl', () {
    test('clears cache and re-fetches URL', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': 'aquariums/aq-1/f7a3b.webp',
            'url': 'https://s3.example.com/presigned?sig=refreshed',
          },
        ]),
      );

      // Populate cache
      await provider.getUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/f7a3b.webp',
      );

      // Refresh — should clear cache and re-fetch
      final url = await provider.refreshUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/f7a3b.webp',
      );

      expect(url, 'https://s3.example.com/presigned?sig=refreshed');

      // Two API calls: initial + refresh
      verify(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).called(2);
    });

    test('returns null for null photoKey', () async {
      final url = await provider.refreshUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: null,
      );

      expect(url, isNull);
      verifyZeroInteractions(mockDio);
    });

    test('returns null for local:// photoKey', () async {
      final url = await provider.refreshUrl(
        entityType: 'avatar',
        entityId: 'user-1',
        photoKey: 'local://some-uuid',
      );

      expect(url, isNull);
      verifyZeroInteractions(mockDio);
    });
  });

  // ---------------------------------------------------------------------------
  // clearCache
  // ---------------------------------------------------------------------------
  group('clearCache', () {
    test('removes all cached entries', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': 'aquariums/aq-1/abc.webp',
            'url': 'https://s3.example.com/url1',
          },
        ]),
      );

      await provider.getUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/abc.webp',
      );
      expect(provider.cacheSize, 1);

      provider.clearCache();
      expect(provider.cacheSize, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // getUrls — batch fetching
  // ---------------------------------------------------------------------------
  group('getUrls', () {
    test(
      'returns null for null and local:// photoKeys without API call',
      () async {
        final results = await provider.getUrls([
          const ImageUrlRequest(
            entityType: 'aquarium',
            entityId: 'aq-1',
            photoKey: null,
          ),
          const ImageUrlRequest(
            entityType: 'fish',
            entityId: 'fish-1',
            photoKey: 'local://a1b2c3d4-e5f6-7890-abcd-ef1234567890',
          ),
          const ImageUrlRequest(
            entityType: 'avatar',
            entityId: 'user-1',
            photoKey: 'local://anything',
          ),
        ]);

        expect(results['aquarium:aq-1'], isNull);
        expect(results['fish:fish-1'], isNull);
        expect(results['avatar:user-1'], isNull);
        expect(results.length, 3);
        verifyZeroInteractions(mockDio);
      },
    );

    test('returns empty map for empty input', () async {
      final results = await provider.getUrls([]);

      expect(results, isEmpty);
      verifyZeroInteractions(mockDio);
    });

    test('serves cached URLs without API call', () async {
      // Pre-populate cache via getUrl
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': 'aquariums/aq-1/abc.webp',
            'url': 'https://s3.example.com/cached-url',
          },
        ]),
      );

      await provider.getUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/abc.webp',
      );

      // Reset mock to track only getUrls calls
      reset(mockDio);

      final results = await provider.getUrls([
        const ImageUrlRequest(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'aquariums/aq-1/abc.webp',
        ),
      ]);

      expect(results['aquarium:aq-1'], 'https://s3.example.com/cached-url');
      verifyZeroInteractions(mockDio);
    });

    test('fetches URLs for uncached items via POST /images/urls', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': 'aquariums/aq-1/abc.webp',
            'url': 'https://s3.example.com/aq-url',
          },
          {
            'entity_type': 'fish',
            'entity_id': 'fish-1',
            'key': 'fish/fish-1/def.webp',
            'url': 'https://s3.example.com/fish-url',
          },
        ]),
      );

      final results = await provider.getUrls([
        const ImageUrlRequest(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'aquariums/aq-1/abc.webp',
        ),
        const ImageUrlRequest(
          entityType: 'fish',
          entityId: 'fish-1',
          photoKey: 'fish/fish-1/def.webp',
        ),
      ]);

      expect(results['aquarium:aq-1'], 'https://s3.example.com/aq-url');
      expect(results['fish:fish-1'], 'https://s3.example.com/fish-url');
      expect(results.length, 2);

      verify(
        () => mockDio.post<Map<String, dynamic>>(
          '/images/urls',
          data: {
            'items': [
              {'entity_type': 'aquarium', 'entity_id': 'aq-1'},
              {'entity_type': 'fish', 'entity_id': 'fish-1'},
            ],
          },
        ),
      ).called(1);
    });

    test('caches fetched URLs for subsequent calls', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': 'aquariums/aq-1/abc.webp',
            'url': 'https://s3.example.com/aq-url',
          },
        ]),
      );

      // First call — fetches from server
      await provider.getUrls([
        const ImageUrlRequest(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'aquariums/aq-1/abc.webp',
        ),
      ]);

      expect(provider.cacheSize, 1);

      // Reset and verify second call uses cache
      reset(mockDio);

      final results = await provider.getUrls([
        const ImageUrlRequest(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'aquariums/aq-1/abc.webp',
        ),
      ]);

      expect(results['aquarium:aq-1'], 'https://s3.example.com/aq-url');
      verifyZeroInteractions(mockDio);
    });

    test('chunks 120 items into 3 sequential requests of 50/50/20', () async {
      final callBodies = <List<Map<String, dynamic>>>[];

      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer((invocation) async {
        final data = invocation.namedArguments[#data] as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>;
        callBodies.add(items.cast<Map<String, dynamic>>());

        // Return URLs for all requested items
        return _successResponse(
          items.cast<Map<String, dynamic>>().map((item) {
            final entityType = item['entity_type'] as String;
            final entityId = item['entity_id'] as String;
            return {
              'entity_type': entityType,
              'entity_id': entityId,
              'key': '$entityType/$entityId/photo.webp',
              'url': 'https://s3.example.com/$entityType-$entityId',
            };
          }).toList(),
        );
      });

      // Create 120 items
      final items = List.generate(
        120,
        (i) => ImageUrlRequest(
          entityType: 'fish',
          entityId: 'fish-$i',
          photoKey: 'fish/fish-$i/photo.webp',
        ),
      );

      final results = await provider.getUrls(items);

      // Should have made exactly 3 API calls
      expect(callBodies.length, 3);
      expect(callBodies[0].length, 50);
      expect(callBodies[1].length, 50);
      expect(callBodies[2].length, 20);

      // All 120 items should be in results
      expect(results.length, 120);

      // Verify sequential order (first chunk starts with fish-0)
      expect(callBodies[0].first['entity_id'], 'fish-0');
      expect(callBodies[1].first['entity_id'], 'fish-50');
      expect(callBodies[2].first['entity_id'], 'fish-100');
    });

    test(
      'returns combined results from cache, local://, null, and server',
      () async {
        // Pre-populate cache for aq-1
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => _successResponse([
            {
              'entity_type': 'aquarium',
              'entity_id': 'aq-1',
              'key': 'aquariums/aq-1/cached.webp',
              'url': 'https://s3.example.com/cached',
            },
          ]),
        );

        await provider.getUrl(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'aquariums/aq-1/cached.webp',
        );

        // Now set up mock for the batch call (only fish-1 needs fetching)
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => _successResponse([
            {
              'entity_type': 'fish',
              'entity_id': 'fish-1',
              'key': 'fish/fish-1/new.webp',
              'url': 'https://s3.example.com/fish-new',
            },
          ]),
        );

        final results = await provider.getUrls([
          // Cached
          const ImageUrlRequest(
            entityType: 'aquarium',
            entityId: 'aq-1',
            photoKey: 'aquariums/aq-1/cached.webp',
          ),
          // null photoKey
          const ImageUrlRequest(entityType: 'aquarium', entityId: 'aq-2'),
          // local:// key
          const ImageUrlRequest(
            entityType: 'fish',
            entityId: 'fish-2',
            photoKey: 'local://pending-upload',
          ),
          // Needs fetch
          const ImageUrlRequest(
            entityType: 'fish',
            entityId: 'fish-1',
            photoKey: 'fish/fish-1/new.webp',
          ),
        ]);

        expect(results['aquarium:aq-1'], 'https://s3.example.com/cached');
        expect(results['aquarium:aq-2'], isNull);
        expect(results['fish:fish-2'], isNull);
        expect(results['fish:fish-1'], 'https://s3.example.com/fish-new');
        expect(results.length, 4);

        // Only one API call for the uncached item (fish-1)
        verify(
          () => mockDio.post<Map<String, dynamic>>(
            '/images/urls',
            data: {
              'items': [
                {'entity_type': 'fish', 'entity_id': 'fish-1'},
              ],
            },
          ),
        ).called(1);
      },
    );

    test('returns null for items server omits (no access)', () async {
      // Server returns only aq-1, omits aq-2 (no access)
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': 'aquariums/aq-1/abc.webp',
            'url': 'https://s3.example.com/aq-url',
          },
        ]),
      );

      final results = await provider.getUrls([
        const ImageUrlRequest(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'aquariums/aq-1/abc.webp',
        ),
        const ImageUrlRequest(
          entityType: 'aquarium',
          entityId: 'aq-2',
          photoKey: 'aquariums/aq-2/def.webp',
        ),
      ]);

      expect(results['aquarium:aq-1'], 'https://s3.example.com/aq-url');
      expect(results['aquarium:aq-2'], isNull);
    });

    test('returns null for items where server returns null url', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': null,
            'url': null,
          },
        ]),
      );

      final results = await provider.getUrls([
        const ImageUrlRequest(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'aquariums/aq-1/abc.webp',
        ),
      ]);

      expect(results['aquarium:aq-1'], isNull);
      // Should NOT cache null URLs
      expect(provider.cacheSize, 0);
    });

    test(
      'handles partial chunk failure — first succeeds, second fails',
      () async {
        var callCount = 0;

        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            // First chunk succeeds
            return _successResponse(
              List.generate(
                50,
                (i) => {
                  'entity_type': 'fish',
                  'entity_id': 'fish-$i',
                  'key': 'fish/fish-$i/photo.webp',
                  'url': 'https://s3.example.com/fish-$i',
                },
              ),
            );
          }
          // Second chunk fails
          throw DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: '/images/urls'),
          );
        });

        // 60 items → 2 chunks: 50 + 10
        final items = List.generate(
          60,
          (i) => ImageUrlRequest(
            entityType: 'fish',
            entityId: 'fish-$i',
            photoKey: 'fish/fish-$i/photo.webp',
          ),
        );

        final results = await provider.getUrls(items);

        // All 60 items should be in results
        expect(results.length, 60);

        // First 50 items have URLs (successful chunk)
        for (var i = 0; i < 50; i++) {
          expect(results['fish:fish-$i'], 'https://s3.example.com/fish-$i');
        }

        // Last 10 items are null (failed chunk)
        for (var i = 50; i < 60; i++) {
          expect(results['fish:fish-$i'], isNull);
        }

        // 50 items cached from successful chunk, none from failed
        expect(provider.cacheSize, 50);
      },
    );

    test(
      'does not fetch items with expired cache but different photoKey',
      () async {
        // Pre-populate cache with old photoKey
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => _successResponse([
            {
              'entity_type': 'aquarium',
              'entity_id': 'aq-1',
              'key': 'aquariums/aq-1/old.webp',
              'url': 'https://s3.example.com/old-url',
            },
          ]),
        );

        await provider.getUrl(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'aquariums/aq-1/old.webp',
        );

        // Now batch with NEW photoKey — cache should be invalidated
        when(
          () => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => _successResponse([
            {
              'entity_type': 'aquarium',
              'entity_id': 'aq-1',
              'key': 'aquariums/aq-1/new.webp',
              'url': 'https://s3.example.com/new-url',
            },
          ]),
        );

        final results = await provider.getUrls([
          const ImageUrlRequest(
            entityType: 'aquarium',
            entityId: 'aq-1',
            photoKey: 'aquariums/aq-1/new.webp',
          ),
        ]);

        expect(results['aquarium:aq-1'], 'https://s3.example.com/new-url');
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Concurrent access
  // ---------------------------------------------------------------------------
  group('concurrent access', () {
    test('handles concurrent getUrl calls for same entity', () async {
      var callCount = 0;

      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer((_) async {
        callCount++;
        // Simulate network delay
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': 'aquariums/aq-1/f7a3b.webp',
            'url': 'https://s3.example.com/presigned?sig=v$callCount',
          },
        ]);
      });

      // Fire two concurrent requests for the same entity
      final results = await Future.wait([
        provider.getUrl(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'aquariums/aq-1/f7a3b.webp',
        ),
        provider.getUrl(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'aquariums/aq-1/f7a3b.webp',
        ),
      ]);

      // Both should return valid URLs (no errors)
      expect(results[0], isNotNull);
      expect(results[1], isNotNull);

      // Both calls hit the API (no deduplication in this implementation)
      // but the cache ends up with a single entry
      expect(provider.cacheSize, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // invalidateUrl
  // ---------------------------------------------------------------------------
  group('invalidateUrl', () {
    test('removes only the specified entity from cache', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': 'aquariums/aq-1/abc.webp',
            'url': 'https://s3.example.com/aq-url',
          },
        ]),
      );

      // Populate cache with two entries
      await provider.getUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/abc.webp',
      );

      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _successResponse([
          {
            'entity_type': 'fish',
            'entity_id': 'fish-1',
            'key': 'fish/fish-1/def.webp',
            'url': 'https://s3.example.com/fish-url',
          },
        ]),
      );

      await provider.getUrl(
        entityType: 'fish',
        entityId: 'fish-1',
        photoKey: 'fish/fish-1/def.webp',
      );

      expect(provider.cacheSize, 2);

      // Invalidate only aquarium
      provider.invalidateUrl(entityType: 'aquarium', entityId: 'aq-1');

      expect(provider.cacheSize, 1);

      // Fish should still be cached
      reset(mockDio);
      final fishUrl = await provider.getUrl(
        entityType: 'fish',
        entityId: 'fish-1',
        photoKey: 'fish/fish-1/def.webp',
      );
      expect(fishUrl, 'https://s3.example.com/fish-url');
      verifyZeroInteractions(mockDio);
    });

    test('does not trigger any network calls', () {
      provider.invalidateUrl(entityType: 'aquarium', entityId: 'aq-1');

      verifyZeroInteractions(mockDio);
    });

    test('is a no-op when entity is not cached', () {
      expect(provider.cacheSize, 0);

      provider.invalidateUrl(entityType: 'aquarium', entityId: 'nonexistent');

      expect(provider.cacheSize, 0);
      verifyZeroInteractions(mockDio);
    });
  });

  // ---------------------------------------------------------------------------
  // refreshUrl — retry limit
  // ---------------------------------------------------------------------------
  group('refreshUrl - retry limit', () {
    test('returns null after maxRefreshRetries consecutive calls', () async {
      var callCount = 0;

      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer((_) async {
        callCount++;
        return _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': 'aquariums/aq-1/abc.webp',
            'url': 'https://s3.example.com/presigned?sig=v$callCount',
          },
        ]);
      });

      // Calls 1..maxRefreshRetries should succeed
      for (var i = 0; i < ImageUrlProvider.maxRefreshRetries; i++) {
        final url = await provider.refreshUrl(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'aquariums/aq-1/abc.webp',
        );
        expect(url, isNotNull, reason: 'Refresh #${i + 1} should succeed');
      }

      expect(callCount, ImageUrlProvider.maxRefreshRetries);

      // Next call should be blocked
      final url = await provider.refreshUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/abc.webp',
      );

      expect(url, isNull);
      // No additional API call
      expect(callCount, ImageUrlProvider.maxRefreshRetries);
    });

    test('retry counter resets when getUrl serves from cache', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': 'aquariums/aq-1/abc.webp',
            'url': 'https://s3.example.com/presigned',
          },
        ]),
      );

      // Exhaust all but one retry
      for (var i = 0; i < ImageUrlProvider.maxRefreshRetries - 1; i++) {
        await provider.refreshUrl(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'aquariums/aq-1/abc.webp',
        );
      }

      expect(provider.refreshRetryCount, 1);

      // getUrl with cache hit resets the counter
      // (last refreshUrl cached the URL, so getUrl will serve from cache)
      final cachedUrl = await provider.getUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/abc.webp',
      );

      expect(cachedUrl, isNotNull);
      expect(provider.refreshRetryCount, 0);

      // Now refreshUrl should work again (counter was reset)
      final refreshed = await provider.refreshUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/abc.webp',
      );
      expect(refreshed, isNotNull);
    });

    test('retry counter resets when photoKey changes in getUrl', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': 'aquariums/aq-1/old.webp',
            'url': 'https://s3.example.com/old',
          },
        ]),
      );

      // Exhaust all retries
      for (var i = 0; i < ImageUrlProvider.maxRefreshRetries; i++) {
        await provider.refreshUrl(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'aquariums/aq-1/old.webp',
        );
      }

      // Verify retries are exhausted
      final blocked = await provider.refreshUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/old.webp',
      );
      expect(blocked, isNull);

      // New photo uploaded — getUrl with different photoKey
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': 'aquariums/aq-1/new.webp',
            'url': 'https://s3.example.com/new',
          },
        ]),
      );

      final newUrl = await provider.getUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/new.webp',
      );
      expect(newUrl, 'https://s3.example.com/new');

      // refreshUrl should work again for the new key
      final refreshed = await provider.refreshUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/new.webp',
      );
      expect(refreshed, isNotNull);
    });

    test('clearCache resets all retry counters', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _successResponse([
          {
            'entity_type': 'aquarium',
            'entity_id': 'aq-1',
            'key': 'aquariums/aq-1/abc.webp',
            'url': 'https://s3.example.com/url',
          },
        ]),
      );

      // Exhaust retries
      for (var i = 0; i < ImageUrlProvider.maxRefreshRetries; i++) {
        await provider.refreshUrl(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'aquariums/aq-1/abc.webp',
        );
      }

      expect(provider.refreshRetryCount, 1);

      provider.clearCache();

      expect(provider.refreshRetryCount, 0);
      expect(provider.cacheSize, 0);

      // refreshUrl should work again
      final url = await provider.refreshUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/abc.webp',
      );
      expect(url, isNotNull);
    });

    test('retry counters are independent per entity', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenAnswer((invocation) async {
        final data = invocation.namedArguments[#data] as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>;
        final item = (items.first as Map<String, dynamic>);
        return _successResponse([
          {
            'entity_type': item['entity_type'],
            'entity_id': item['entity_id'],
            'key': '${item['entity_type']}/${item['entity_id']}/a.webp',
            'url': 'https://s3.example.com/${item['entity_id']}',
          },
        ]);
      });

      // Exhaust retries for aq-1
      for (var i = 0; i < ImageUrlProvider.maxRefreshRetries; i++) {
        await provider.refreshUrl(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'aquariums/aq-1/a.webp',
        );
      }

      // aq-1 should be blocked
      final blockedUrl = await provider.refreshUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: 'aquariums/aq-1/a.webp',
      );
      expect(blockedUrl, isNull);

      // fish-1 should still work (independent counter)
      final fishUrl = await provider.refreshUrl(
        entityType: 'fish',
        entityId: 'fish-1',
        photoKey: 'fish/fish-1/a.webp',
      );
      expect(fishUrl, isNotNull);
    });

    test('refreshUrl does not increment counter for null photoKey', () async {
      await provider.refreshUrl(
        entityType: 'aquarium',
        entityId: 'aq-1',
        photoKey: null,
      );

      expect(provider.refreshRetryCount, 0);
      verifyZeroInteractions(mockDio);
    });

    test(
      'refreshUrl does not increment counter for local:// photoKey',
      () async {
        await provider.refreshUrl(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'local://some-uuid',
        );

        expect(provider.refreshRetryCount, 0);
        verifyZeroInteractions(mockDio);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Error propagation
  // ---------------------------------------------------------------------------
  group('error propagation', () {
    test('propagates DioException to caller', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/images/urls'),
        ),
      );

      expect(
        () => provider.getUrl(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'aquariums/aq-1/f7a3b.webp',
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('does not cache on error', () async {
      when(
        () =>
            mockDio.post<Map<String, dynamic>>(any(), data: any(named: 'data')),
      ).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/images/urls'),
          response: Response<dynamic>(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/images/urls'),
          ),
        ),
      );

      try {
        await provider.getUrl(
          entityType: 'aquarium',
          entityId: 'aq-1',
          photoKey: 'aquariums/aq-1/f7a3b.webp',
        );
      } on DioException {
        // Expected
      }

      expect(provider.cacheSize, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // Riverpod: imageUrlProvider
  // ---------------------------------------------------------------------------
  group('imageUrlProvider', () {
    test('creates ImageUrlProvider with Dio from apiClientProvider', () {
      final mockApiClient = MockApiClient();
      final mockDio = MockDio();
      when(() => mockApiClient.dio).thenReturn(mockDio);

      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockApiClient)],
      );
      addTearDown(container.dispose);

      final result = container.read(imageUrlProvider);

      expect(result, isA<ImageUrlProvider>());
      verify(() => mockApiClient.dio).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // Riverpod: photoUrlProvider
  // ---------------------------------------------------------------------------
  group('photoUrlProvider', () {
    late MockImageUrlProvider mockUrlProvider;
    late ProviderContainer container;

    setUp(() {
      mockUrlProvider = MockImageUrlProvider();
      container = ProviderContainer(
        overrides: [imageUrlProvider.overrideWithValue(mockUrlProvider)],
      );
    });

    tearDown(() => container.dispose());

    test('returns AsyncData with presigned URL for valid S3 key', () async {
      const photoKey = 'aquariums/abc/f7a3b.webp';
      const presignedUrl = 'https://s3.example.com/signed?token=abc';

      when(
        () => mockUrlProvider.getUrl(
          entityType: 'aquarium',
          entityId: 'abc',
          photoKey: photoKey,
        ),
      ).thenAnswer((_) async => presignedUrl);

      final result = await container.read(
        photoUrlProvider((
          entityType: 'aquarium',
          entityId: 'abc',
          photoKey: photoKey,
        )).future,
      );

      expect(result, equals(presignedUrl));
      verify(
        () => mockUrlProvider.getUrl(
          entityType: 'aquarium',
          entityId: 'abc',
          photoKey: photoKey,
        ),
      ).called(1);
    });

    test('returns AsyncData(null) for local:// key', () async {
      const localKey = 'local://a1b2c3d4-e5f6-7890-abcd-ef1234567890';

      when(
        () => mockUrlProvider.getUrl(
          entityType: 'aquarium',
          entityId: 'abc',
          photoKey: localKey,
        ),
      ).thenAnswer((_) async => null);

      final result = await container.read(
        photoUrlProvider((
          entityType: 'aquarium',
          entityId: 'abc',
          photoKey: localKey,
        )).future,
      );

      expect(result, isNull);
    });

    test('returns AsyncData(null) for null photoKey', () async {
      when(
        () => mockUrlProvider.getUrl(
          entityType: 'fish',
          entityId: 'def',
          photoKey: null,
        ),
      ).thenAnswer((_) async => null);

      final result = await container.read(
        photoUrlProvider((
          entityType: 'fish',
          entityId: 'def',
          photoKey: null,
        )).future,
      );

      expect(result, isNull);
    });

    test('caches result for identical parameters', () async {
      const photoKey = 'fish/def/c4e82.webp';
      const presignedUrl = 'https://s3.example.com/signed?token=xyz';

      when(
        () => mockUrlProvider.getUrl(
          entityType: 'fish',
          entityId: 'def',
          photoKey: photoKey,
        ),
      ).thenAnswer((_) async => presignedUrl);

      const param = (
        entityType: 'fish',
        entityId: 'def',
        photoKey: photoKey as String?,
      );

      // First read
      final result1 = await container.read(photoUrlProvider(param).future);

      // Second read with identical param — should use Riverpod cache
      final result2 = await container.read(photoUrlProvider(param).future);

      expect(result1, equals(presignedUrl));
      expect(result2, equals(presignedUrl));

      // getUrl should only be called once — second read served from cache
      verify(
        () => mockUrlProvider.getUrl(
          entityType: 'fish',
          entityId: 'def',
          photoKey: photoKey,
        ),
      ).called(1);
    });

    test('creates separate providers for different parameters', () async {
      const photoKey1 = 'aquariums/a1/f7a3b.webp';
      const photoKey2 = 'fish/f1/c4e82.webp';
      const url1 = 'https://s3.example.com/signed1';
      const url2 = 'https://s3.example.com/signed2';

      when(
        () => mockUrlProvider.getUrl(
          entityType: 'aquarium',
          entityId: 'a1',
          photoKey: photoKey1,
        ),
      ).thenAnswer((_) async => url1);

      when(
        () => mockUrlProvider.getUrl(
          entityType: 'fish',
          entityId: 'f1',
          photoKey: photoKey2,
        ),
      ).thenAnswer((_) async => url2);

      final result1 = await container.read(
        photoUrlProvider((
          entityType: 'aquarium',
          entityId: 'a1',
          photoKey: photoKey1 as String?,
        )).future,
      );

      final result2 = await container.read(
        photoUrlProvider((
          entityType: 'fish',
          entityId: 'f1',
          photoKey: photoKey2 as String?,
        )).future,
      );

      expect(result1, equals(url1));
      expect(result2, equals(url2));
    });

    test('propagates errors as AsyncError', () async {
      when(
        () => mockUrlProvider.getUrl(
          entityType: 'aquarium',
          entityId: 'abc',
          photoKey: 'aquariums/abc/f7a3b.webp',
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/images/urls'),
        ),
      );

      expect(
        () => container.read(
          photoUrlProvider((
            entityType: 'aquarium',
            entityId: 'abc',
            photoKey: 'aquariums/abc/f7a3b.webp' as String?,
          )).future,
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Widget test: photoUrlProvider AsyncValue states
  // ---------------------------------------------------------------------------
  group('photoUrlProvider widget integration', () {
    testWidgets('Consumer renders data state with presigned URL', (
      tester,
    ) async {
      final mockUrlProvider = MockImageUrlProvider();
      const photoKey = 'aquariums/abc/f7a3b.webp';
      const presignedUrl = 'https://s3.example.com/signed?token=abc';

      when(
        () => mockUrlProvider.getUrl(
          entityType: 'aquarium',
          entityId: 'abc',
          photoKey: photoKey,
        ),
      ).thenAnswer((_) async => presignedUrl);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [imageUrlProvider.overrideWithValue(mockUrlProvider)],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                final urlAsync = ref.watch(
                  photoUrlProvider((
                    entityType: 'aquarium',
                    entityId: 'abc',
                    photoKey: photoKey as String?,
                  )),
                );
                return urlAsync.when(
                  data: (url) => Text(url ?? 'no-photo'),
                  loading: () => const Text('loading'),
                  error: (_, __) => const Text('error'),
                );
              },
            ),
          ),
        ),
      );

      // Initially shows loading
      expect(find.text('loading'), findsOneWidget);

      // After async resolution
      await tester.pumpAndSettle();

      expect(find.text(presignedUrl), findsOneWidget);
    });

    testWidgets('Consumer renders error state on failure', (tester) async {
      final mockUrlProvider = MockImageUrlProvider();

      when(
        () => mockUrlProvider.getUrl(
          entityType: 'aquarium',
          entityId: 'abc',
          photoKey: 'aquariums/abc/f7a3b.webp',
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/images/urls'),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [imageUrlProvider.overrideWithValue(mockUrlProvider)],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                final urlAsync = ref.watch(
                  photoUrlProvider((
                    entityType: 'aquarium',
                    entityId: 'abc',
                    photoKey: 'aquariums/abc/f7a3b.webp' as String?,
                  )),
                );
                return urlAsync.when(
                  data: (url) => Text(url ?? 'no-photo'),
                  loading: () => const Text('loading'),
                  error: (_, __) => const Text('error'),
                );
              },
            ),
          ),
        ),
      );

      // Initially loading
      expect(find.text('loading'), findsOneWidget);

      // After async resolution — error
      await tester.pumpAndSettle();

      expect(find.text('error'), findsOneWidget);
    });

    testWidgets('Consumer renders null state for entity without photo', (
      tester,
    ) async {
      final mockUrlProvider = MockImageUrlProvider();

      when(
        () => mockUrlProvider.getUrl(
          entityType: 'avatar',
          entityId: 'user-1',
          photoKey: null,
        ),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [imageUrlProvider.overrideWithValue(mockUrlProvider)],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                final urlAsync = ref.watch(
                  photoUrlProvider((
                    entityType: 'avatar',
                    entityId: 'user-1',
                    photoKey: null,
                  )),
                );
                return urlAsync.when(
                  data: (url) => Text(url ?? 'no-photo'),
                  loading: () => const Text('loading'),
                  error: (_, __) => const Text('error'),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('no-photo'), findsOneWidget);
    });
  });
}
