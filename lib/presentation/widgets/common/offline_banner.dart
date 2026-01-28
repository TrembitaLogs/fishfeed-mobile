import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/services/connectivity/connectivity_service.dart';

/// A banner that displays when the device is offline.
///
/// Shows a colored bar at the top of the content with an offline message.
/// Automatically hides when connectivity is restored.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({
    super.key,
    this.child,
  });

  /// The child widget to display below the banner.
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isOffline ? null : 0,
          child: isOffline
              ? _OfflineBannerContent(l10n: l10n)
              : const SizedBox.shrink(),
        ),
        if (child != null) Expanded(child: child!),
      ],
    );
  }
}

class _OfflineBannerContent extends StatelessWidget {
  const _OfflineBannerContent({
    required this.l10n,
  });

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Row(
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 20,
                color: colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.offlineBannerTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                    Text(
                      l10n.offlineBannerDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that wraps content and adds an offline banner at the top.
///
/// Use this as a wrapper for your main app content to automatically
/// show an offline notification when connectivity is lost.
class OfflineBannerWrapper extends ConsumerWidget {
  const OfflineBannerWrapper({
    super.key,
    required this.child,
  });

  /// The main content to display.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        // Main content with padding when offline
        AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.only(
            top: isOffline ? 60 : 0,
          ),
          child: child,
        ),
        // Offline banner
        if (isOffline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _OfflineBannerContent(l10n: l10n),
          ),
      ],
    );
  }
}
