import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
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
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
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
        child: Icon(
          icon,
          color: iconColor,
          size: _calculateIconSize(),
        ),
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
