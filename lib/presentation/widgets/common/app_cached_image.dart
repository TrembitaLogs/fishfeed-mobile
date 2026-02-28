import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import 'package:fishfeed/presentation/providers/image_upload_provider.dart';
import 'package:fishfeed/presentation/providers/image_url_provider.dart';

/// A wrapper widget for CachedNetworkImage with standardized placeholder
/// and error handling.
///
/// Features:
/// - Shimmer loading placeholder
/// - Consistent error widget with fallback icon
/// - Memory and disk cache configuration
/// - Support for circular and rectangular shapes
class AppCachedImage extends StatelessWidget {
  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.isCircular = false,
    this.placeholderIcon = Icons.image,
    this.errorIcon = Icons.broken_image,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  /// The URL of the image to load.
  final String imageUrl;

  /// Width of the image widget.
  final double? width;

  /// Height of the image widget.
  final double? height;

  /// How to inscribe the image into the available space.
  final BoxFit fit;

  /// Border radius for rectangular images.
  final BorderRadius? borderRadius;

  /// Whether to display the image in a circular shape.
  final bool isCircular;

  /// Icon to show while loading (used as shimmer background).
  final IconData placeholderIcon;

  /// Icon to show on error.
  final IconData errorIcon;

  /// Width for memory cache (for performance optimization).
  final int? memCacheWidth;

  /// Height for memory cache (for performance optimization).
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (context, url) => _ShimmerPlaceholder(
        width: width,
        height: height,
        isCircular: isCircular,
        borderRadius: borderRadius,
        icon: placeholderIcon,
      ),
      errorWidget: (context, url, error) => _ErrorPlaceholder(
        width: width,
        height: height,
        icon: errorIcon,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        iconColor: theme.colorScheme.onSurfaceVariant,
      ),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
    );

    if (isCircular) {
      return ClipOval(child: image);
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}

/// Circular avatar variant of AppCachedImage for profile pictures.
///
/// Provides a consistent avatar appearance with shimmer loading
/// and fallback person icon.
class AppCachedAvatar extends StatelessWidget {
  const AppCachedAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24,
    this.fallbackIcon = Icons.person,
  });

  /// The URL of the avatar image. If null, shows fallback icon.
  final String? imageUrl;

  /// Radius of the avatar.
  final double radius;

  /// Icon to show when no image is available.
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = radius * 2;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          fallbackIcon,
          size: radius,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder: (context, imageProvider) =>
            CircleAvatar(radius: radius, backgroundImage: imageProvider),
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: theme.colorScheme.surfaceContainerLow,
          highlightColor: theme.colorScheme.surfaceContainerHigh,
          child: CircleAvatar(
            radius: radius,
            backgroundColor: theme.colorScheme.surfaceContainerLow,
          ),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: radius,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            fallbackIcon,
            size: radius,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 300),
        memCacheWidth: (size * 2).toInt(),
        memCacheHeight: (size * 2).toInt(),
      ),
    );
  }
}

/// Displays entity images with 4-state support for the image sync system.
///
/// States:
/// 1. [photoKey] is `null` or empty — placeholder icon based on [entityType]
/// 2. [photoKey] starts with `local://` — local file from the upload queue
/// 3. S3 key, presigned URL loading — shimmer placeholder
/// 4. S3 key + presigned URL ready — [CachedNetworkImage] with [photoKey]
///    as `cacheKey`
///
/// Uses [photoUrlProvider] for presigned URL resolution and
/// [localImagePathProvider] for pending upload file paths.
///
/// IMPORTANT: [CachedNetworkImage] uses [photoKey] as `cacheKey`
/// (not the presigned URL), because URLs expire every hour while the
/// file content stays the same as long as the key doesn't change.
///
/// Example:
/// ```dart
/// EntityImage(
///   photoKey: aquarium.photoKey,
///   entityType: 'aquarium',
///   entityId: aquarium.id,
///   width: 120,
///   height: 120,
///   borderRadius: BorderRadius.circular(12),
/// )
/// ```
class EntityImage extends ConsumerWidget {
  const EntityImage({
    super.key,
    required this.photoKey,
    required this.entityType,
    required this.entityId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.isCircular = false,
    this.placeholderIcon,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  /// The S3 object key, `local://{uuid}`, or `null`.
  final String? photoKey;

  /// Entity type: `"aquarium"`, `"fish"`, or `"avatar"`.
  final String entityType;

  /// The entity's unique identifier.
  final String entityId;

  /// Width of the image widget.
  final double? width;

  /// Height of the image widget.
  final double? height;

  /// How to inscribe the image into the available space.
  final BoxFit fit;

  /// Border radius for rectangular images. Ignored when [isCircular] is true.
  final BorderRadius? borderRadius;

  /// Whether to display the image in a circular shape.
  final bool isCircular;

  /// Override the default placeholder icon.
  ///
  /// If `null`, uses a default icon based on [entityType]:
  /// - `"aquarium"` → [Icons.water_drop_outlined]
  /// - `"fish"` → [Icons.set_meal_rounded]
  /// - `"avatar"` → [Icons.person]
  final IconData? placeholderIcon;

  /// Width for memory cache (for performance optimization).
  final int? memCacheWidth;

  /// Height for memory cache (for performance optimization).
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // State 1: No photo
    if (photoKey == null || photoKey!.isEmpty) {
      return _buildPlaceholder(context);
    }

    // State 2: Local file (pending upload)
    if (photoKey!.startsWith('local://')) {
      return _buildLocalImage(context, ref);
    }

    // States 3 & 4: S3 key
    return _buildRemoteImage(context, ref);
  }

  /// State 2: Resolves local file path and shows the image.
  Widget _buildLocalImage(BuildContext context, WidgetRef ref) {
    final pathAsync = ref.watch(localImagePathProvider(photoKey!));

    return pathAsync.when(
      data: (path) {
        if (path == null) return _buildPlaceholder(context);
        return _clip(
          Image.file(
            File(path),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildPlaceholder(context),
          ),
        );
      },
      loading: () => _buildShimmer(context),
      error: (_, __) => _buildPlaceholder(context),
    );
  }

  /// States 3 & 4: Fetches presigned URL and shows the remote image.
  Widget _buildRemoteImage(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(
      photoUrlProvider((
        entityType: entityType,
        entityId: entityId,
        photoKey: photoKey,
      )),
    );

    return urlAsync.when(
      data: (url) {
        if (url == null) return _buildPlaceholder(context);
        return _clip(
          CachedNetworkImage(
            imageUrl: url,
            cacheKey: photoKey!, // Use photo_key, not URL!
            width: width,
            height: height,
            fit: fit,
            memCacheWidth: memCacheWidth,
            memCacheHeight: memCacheHeight,
            placeholder: (_, __) => _buildShimmer(context),
            errorWidget: (_, __, ___) => _buildErrorPlaceholder(context),
            fadeInDuration: const Duration(milliseconds: 300),
            fadeOutDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      loading: () => _buildShimmer(context),
      error: (_, __) => _buildErrorPlaceholder(context),
    );
  }

  /// Applies clipping for circular or rounded shapes.
  Widget _clip(Widget child) {
    if (isCircular) {
      return ClipOval(child: child);
    }
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  /// Placeholder widget for null/missing photos.
  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    final icon = placeholderIcon ?? _defaultIcon;

    if (isCircular) {
      final size = width ?? height ?? 48;
      return SizedBox(
        width: size,
        height: size,
        child: CircleAvatar(
          radius: size / 2,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            icon,
            size: size * 0.4,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          icon,
          color: theme.colorScheme.onSurfaceVariant,
          size: _calculateIconSize(),
        ),
      ),
    );
  }

  /// Shimmer placeholder for loading states.
  Widget _buildShimmer(BuildContext context) {
    return _ShimmerPlaceholder(
      width: width,
      height: height,
      isCircular: isCircular,
      borderRadius: borderRadius,
      icon: placeholderIcon ?? _defaultIcon,
    );
  }

  /// Error placeholder for failed image loads.
  Widget _buildErrorPlaceholder(BuildContext context) {
    final theme = Theme.of(context);

    if (isCircular) {
      final size = width ?? height ?? 48;
      return SizedBox(
        width: size,
        height: size,
        child: CircleAvatar(
          radius: size / 2,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image,
            size: size * 0.4,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return _ErrorPlaceholder(
      width: width,
      height: height,
      icon: Icons.broken_image,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      iconColor: theme.colorScheme.onSurfaceVariant,
    );
  }

  /// Default icon based on entity type.
  IconData get _defaultIcon {
    return switch (entityType) {
      'aquarium' => Icons.water_drop_outlined,
      'fish' => Icons.set_meal_rounded,
      'avatar' => Icons.person,
      _ => Icons.image,
    };
  }

  /// Calculates icon size based on widget dimensions.
  double _calculateIconSize() {
    if (width != null && height != null) {
      return (width! < height! ? width! : height!) * 0.4;
    }
    return 24;
  }
}

/// Shimmer placeholder widget for loading states.
class _ShimmerPlaceholder extends StatelessWidget {
  const _ShimmerPlaceholder({
    this.width,
    this.height,
    this.isCircular = false,
    this.borderRadius,
    this.icon,
  });

  final double? width;
  final double? height;
  final bool isCircular;
  final BorderRadius? borderRadius;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerLow,
      highlightColor: theme.colorScheme.surfaceContainerHigh,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircular ? null : borderRadius,
        ),
        child: icon != null
            ? Center(
                child: Icon(
                  icon,
                  color: theme.colorScheme.surfaceContainerHigh,
                  size: _calculateIconSize(),
                ),
              )
            : null,
      ),
    );
  }

  double _calculateIconSize() {
    if (width != null && height != null) {
      return (width! < height! ? width! : height!) * 0.4;
    }
    return 24;
  }
}

/// Error placeholder widget for failed image loads.
class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder({
    this.width,
    this.height,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final double? width;
  final double? height;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: Center(
        child: Icon(icon, color: iconColor, size: _calculateIconSize()),
      ),
    );
  }

  double _calculateIconSize() {
    if (width != null && height != null) {
      return (width! < height! ? width! : height!) * 0.4;
    }
    return 24;
  }
}
