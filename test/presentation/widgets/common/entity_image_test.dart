import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'package:fishfeed/core/config/theme.dart';
import 'package:fishfeed/presentation/providers/image_upload_provider.dart';
import 'package:fishfeed/presentation/providers/image_url_provider.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    AppTheme.useDefaultFonts = true;
  });

  tearDownAll(() {
    AppTheme.useDefaultFonts = false;
  });

  Widget buildTestWidget({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // State 1: null / empty photoKey → placeholder
  // ---------------------------------------------------------------------------
  group('EntityImage — State 1: null photoKey', () {
    testWidgets('renders placeholder with default aquarium icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const EntityImage(
            photoKey: null,
            entityType: 'aquarium',
            entityId: 'aq-1',
            width: 100,
            height: 100,
          ),
        ),
      );

      expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byType(Shimmer), findsNothing);
    });

    testWidgets('renders placeholder with default fish icon', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const EntityImage(
            photoKey: null,
            entityType: 'fish',
            entityId: 'fish-1',
            width: 100,
            height: 100,
          ),
        ),
      );

      expect(find.byIcon(Icons.set_meal_rounded), findsOneWidget);
    });

    testWidgets('renders placeholder with default avatar icon', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const EntityImage(
            photoKey: null,
            entityType: 'avatar',
            entityId: 'user-1',
            width: 100,
            height: 100,
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders fallback icon for unknown entity type', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const EntityImage(
            photoKey: null,
            entityType: 'unknown',
            entityId: 'id-1',
            width: 100,
            height: 100,
          ),
        ),
      );

      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('renders custom placeholder icon when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const EntityImage(
            photoKey: null,
            entityType: 'aquarium',
            entityId: 'aq-1',
            width: 100,
            height: 100,
            placeholderIcon: Icons.camera_alt,
          ),
        ),
      );

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.water_drop_outlined), findsNothing);
    });

    testWidgets('treats empty string as null', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const EntityImage(
            photoKey: '',
            entityType: 'aquarium',
            entityId: 'aq-1',
            width: 100,
            height: 100,
          ),
        ),
      );

      expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // State 2: local:// photoKey → local file
  // ---------------------------------------------------------------------------
  group('EntityImage — State 2: local:// photoKey', () {
    testWidgets('renders shimmer while loading local path', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            localImagePathProvider.overrideWith(
              (ref, localKey) => Completer<String?>().future,
            ),
          ],
          child: const EntityImage(
            photoKey: 'local://test-uuid',
            entityType: 'aquarium',
            entityId: 'aq-1',
            width: 100,
            height: 100,
          ),
        ),
      );

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('renders placeholder when local path is null', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            localImagePathProvider.overrideWith((ref, localKey) async => null),
          ],
          child: const EntityImage(
            photoKey: 'local://test-uuid',
            entityType: 'aquarium',
            entityId: 'aq-1',
            width: 100,
            height: 100,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('renders Image.file when local path resolves', (tester) async {
      // Create a temporary file (content doesn't matter for widget tree test)
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/entity_image_test.webp');
      tempFile.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0]); // JPEG magic bytes

      addTearDown(() {
        if (tempFile.existsSync()) tempFile.deleteSync();
      });

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            localImagePathProvider.overrideWith(
              (ref, localKey) async => tempFile.path,
            ),
          ],
          child: const EntityImage(
            photoKey: 'local://test-uuid',
            entityType: 'aquarium',
            entityId: 'aq-1',
            width: 100,
            height: 100,
          ),
        ),
      );

      // Let the FutureProvider resolve
      await tester.pump();

      // Should render Image.file (not CachedNetworkImage)
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);

      // Verify the Image uses a FileImage provider with the correct path
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.image, isA<FileImage>());
      expect((imageWidget.image as FileImage).file.path, tempFile.path);
    });

    testWidgets('renders placeholder on local path provider error', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            localImagePathProvider.overrideWith(
              (ref, localKey) async => throw Exception('Queue read failed'),
            ),
          ],
          child: const EntityImage(
            photoKey: 'local://test-uuid',
            entityType: 'fish',
            entityId: 'fish-1',
            width: 100,
            height: 100,
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.set_meal_rounded), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // State 3: S3 key, URL loading → shimmer
  // ---------------------------------------------------------------------------
  group('EntityImage — State 3: S3 key loading', () {
    testWidgets('renders shimmer while URL is loading', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            photoUrlProvider.overrideWith(
              (ref, param) => Completer<String?>().future,
            ),
          ],
          child: const EntityImage(
            photoKey: 'aquariums/aq-1/f7a3b2c1.webp',
            entityType: 'aquarium',
            entityId: 'aq-1',
            width: 100,
            height: 100,
          ),
        ),
      );

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // State 4: S3 key + presigned URL → CachedNetworkImage
  // ---------------------------------------------------------------------------
  group('EntityImage — State 4: S3 key + URL', () {
    testWidgets('renders CachedNetworkImage with correct cacheKey', (
      tester,
    ) async {
      const testPhotoKey = 'aquariums/aq-1/f7a3b2c1.webp';
      const testUrl = 'https://s3.example.com/presigned?sig=abc';

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            photoUrlProvider.overrideWith((ref, param) async => testUrl),
          ],
          child: const EntityImage(
            photoKey: testPhotoKey,
            entityType: 'aquarium',
            entityId: 'aq-1',
            width: 100,
            height: 100,
          ),
        ),
      );

      // Let the FutureProvider resolve
      await tester.pump();

      final cachedImage = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(cachedImage.imageUrl, testUrl);
      // CRITICAL: cacheKey must be photoKey, not the URL
      expect(cachedImage.cacheKey, testPhotoKey);
    });

    testWidgets('renders placeholder when URL is null (no photo on server)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            photoUrlProvider.overrideWith((ref, param) async => null),
          ],
          child: const EntityImage(
            photoKey: 'aquariums/aq-1/f7a3b2c1.webp',
            entityType: 'aquarium',
            entityId: 'aq-1',
            width: 100,
            height: 100,
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets(
      'passes memCacheWidth and memCacheHeight to CachedNetworkImage',
      (tester) async {
        const testPhotoKey = 'fish/fish-1/a1b2c3d4.webp';
        const testUrl = 'https://s3.example.com/presigned?sig=def';

        await tester.pumpWidget(
          buildTestWidget(
            overrides: [
              photoUrlProvider.overrideWith((ref, param) async => testUrl),
            ],
            child: const EntityImage(
              photoKey: testPhotoKey,
              entityType: 'fish',
              entityId: 'fish-1',
              width: 200,
              height: 200,
              memCacheWidth: 400,
              memCacheHeight: 400,
            ),
          ),
        );

        await tester.pump();

        final cachedImage = tester.widget<CachedNetworkImage>(
          find.byType(CachedNetworkImage),
        );
        expect(cachedImage.memCacheWidth, 400);
        expect(cachedImage.memCacheHeight, 400);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------
  group('EntityImage — error state', () {
    testWidgets('renders error placeholder on provider error', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            photoUrlProvider.overrideWith(
              (ref, param) async => throw Exception('Network error'),
            ),
          ],
          child: const EntityImage(
            photoKey: 'aquariums/aq-1/f7a3b2c1.webp',
            entityType: 'aquarium',
            entityId: 'aq-1',
            width: 100,
            height: 100,
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Circular mode
  // ---------------------------------------------------------------------------
  group('EntityImage — circular mode', () {
    testWidgets('applies ClipOval when isCircular is true', (tester) async {
      const testUrl = 'https://s3.example.com/presigned?sig=abc';

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            photoUrlProvider.overrideWith((ref, param) async => testUrl),
          ],
          child: const EntityImage(
            photoKey: 'avatars/user-1/a1b2c3d4.webp',
            entityType: 'avatar',
            entityId: 'user-1',
            width: 48,
            height: 48,
            isCircular: true,
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(ClipOval), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('placeholder uses CircleAvatar when isCircular is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const EntityImage(
            photoKey: null,
            entityType: 'avatar',
            entityId: 'user-1',
            width: 48,
            height: 48,
            isCircular: true,
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('error placeholder uses CircleAvatar when isCircular is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            photoUrlProvider.overrideWith(
              (ref, param) async => throw Exception('fail'),
            ),
          ],
          child: const EntityImage(
            photoKey: 'avatars/user-1/a1b2c3d4.webp',
            entityType: 'avatar',
            entityId: 'user-1',
            width: 48,
            height: 48,
            isCircular: true,
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Border radius
  // ---------------------------------------------------------------------------
  group('EntityImage — border radius', () {
    testWidgets('applies ClipRRect when borderRadius is provided', (
      tester,
    ) async {
      const testUrl = 'https://s3.example.com/presigned?sig=abc';

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            photoUrlProvider.overrideWith((ref, param) async => testUrl),
          ],
          child: const EntityImage(
            photoKey: 'aquariums/aq-1/f7a3b2c1.webp',
            entityType: 'aquarium',
            entityId: 'aq-1',
            width: 100,
            height: 100,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(ClipRRect), findsOneWidget);
      expect(find.byType(ClipOval), findsNothing);
    });

    testWidgets(
      'placeholder container has borderRadius when borderRadius is provided',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            child: const EntityImage(
              photoKey: null,
              entityType: 'aquarium',
              entityId: 'aq-1',
              width: 100,
              height: 100,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration! as BoxDecoration;
        expect(
          decoration.borderRadius,
          const BorderRadius.all(Radius.circular(12)),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // No clipping without borderRadius or isCircular
  // ---------------------------------------------------------------------------
  group('EntityImage — no clipping', () {
    testWidgets('no ClipOval or ClipRRect by default', (tester) async {
      const testUrl = 'https://s3.example.com/presigned?sig=abc';

      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            photoUrlProvider.overrideWith((ref, param) async => testUrl),
          ],
          child: const EntityImage(
            photoKey: 'aquariums/aq-1/f7a3b2c1.webp',
            entityType: 'aquarium',
            entityId: 'aq-1',
            width: 100,
            height: 100,
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(ClipOval), findsNothing);
      expect(find.byType(ClipRRect), findsNothing);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });
  });
}
