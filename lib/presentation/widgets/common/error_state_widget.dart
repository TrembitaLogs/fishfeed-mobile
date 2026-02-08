import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fishfeed/core/config/animation_config.dart';

/// Error type enum for categorizing errors.
enum ErrorType {
  /// Network connectivity error.
  network,

  /// Server error (5xx).
  server,

  /// Request timeout.
  timeout,

  /// Generic/unknown error.
  generic,
}

/// A reusable error state widget that displays an error icon, title,
/// description, retry button, and optional secondary action.
///
/// Used when an operation fails and needs user intervention.
/// Supports different error types with appropriate icons and messages.
class ErrorStateWidget extends StatefulWidget {
  const ErrorStateWidget({
    super.key,
    required this.title,
    required this.description,
    required this.onRetry,
    this.retryLabel,
    this.errorType = ErrorType.generic,
    this.illustration,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.animate = true,
  });

  /// Factory constructor for network errors.
  factory ErrorStateWidget.network({
    required String title,
    required String description,
    required Future<void> Function() onRetry,
    String? retryLabel,
  }) {
    return ErrorStateWidget(
      title: title,
      description: description,
      onRetry: onRetry,
      retryLabel: retryLabel,
      errorType: ErrorType.network,
    );
  }

  /// Factory constructor for server errors.
  factory ErrorStateWidget.server({
    required String title,
    required String description,
    required Future<void> Function() onRetry,
    String? retryLabel,
  }) {
    return ErrorStateWidget(
      title: title,
      description: description,
      onRetry: onRetry,
      retryLabel: retryLabel,
      errorType: ErrorType.server,
    );
  }

  /// Factory constructor for timeout errors.
  factory ErrorStateWidget.timeout({
    required String title,
    required String description,
    required Future<void> Function() onRetry,
    String? retryLabel,
  }) {
    return ErrorStateWidget(
      title: title,
      description: description,
      onRetry: onRetry,
      retryLabel: retryLabel,
      errorType: ErrorType.timeout,
    );
  }

  /// The main error title text.
  final String title;

  /// The error description text.
  final String description;

  /// Callback when the retry button is pressed.
  final Future<void> Function() onRetry;

  /// Custom label for the retry button. Defaults to "Try Again".
  final String? retryLabel;

  /// The type of error for determining the icon.
  final ErrorType errorType;

  /// Optional custom illustration widget to replace the default icon.
  final Widget? illustration;

  /// Optional secondary action button label (e.g., "Contact Support").
  final String? secondaryActionLabel;

  /// Callback for the secondary action button.
  final VoidCallback? onSecondaryAction;

  /// Whether to animate the widget on appearance.
  final bool animate;

  @override
  State<ErrorStateWidget> createState() => _ErrorStateWidgetState();
}

class _ErrorStateWidgetState extends State<ErrorStateWidget> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
    });

    try {
      await widget.onRetry();
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  IconData _getIconForErrorType() {
    return switch (widget.errorType) {
      ErrorType.network => Icons.wifi_off_rounded,
      ErrorType.server => Icons.cloud_off_rounded,
      ErrorType.timeout => Icons.timer_off_rounded,
      ErrorType.generic => Icons.error_outline_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIllustration(theme),
            const SizedBox(height: 24),
            Text(
              widget.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildRetryButton(theme),
            if (widget.secondaryActionLabel != null &&
                widget.onSecondaryAction != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onSecondaryAction,
                child: Text(widget.secondaryActionLabel!),
              ),
            ],
          ],
        ),
      ),
    );

    if (widget.animate && !AnimationConfig.shouldReduceMotion(context)) {
      content = content
          .animate()
          .fadeIn(
            duration: AnimationConfig.durationNormal,
            curve: AnimationConfig.entranceCurve,
          )
          .scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1.0, 1.0),
            duration: AnimationConfig.durationNormal,
            curve: AnimationConfig.entranceCurve,
          );
    }

    return content;
  }

  Widget _buildIllustration(ThemeData theme) {
    if (widget.illustration != null) {
      return widget.illustration!;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getIconForErrorType(),
        size: 40,
        color: theme.colorScheme.error,
      ),
    );
  }

  Widget _buildRetryButton(ThemeData theme) {
    return FilledButton.icon(
      onPressed: _isRetrying ? null : _handleRetry,
      icon: _isRetrying
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onPrimary,
              ),
            )
          : const Icon(Icons.refresh_rounded),
      label: Text(widget.retryLabel ?? 'Try Again'),
    );
  }
}

/// A scrollable error state widget that works with [RefreshIndicator].
///
/// Use this variant when the error state needs to support pull-to-refresh.
class ScrollableErrorState extends StatelessWidget {
  const ScrollableErrorState({
    super.key,
    required this.title,
    required this.description,
    required this.onRetry,
    this.retryLabel,
    this.errorType = ErrorType.generic,
    this.illustration,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.animate = true,
  });

  final String title;
  final String description;
  final Future<void> Function() onRetry;
  final String? retryLabel;
  final ErrorType errorType;
  final Widget? illustration;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorStateWidget(
            title: title,
            description: description,
            onRetry: onRetry,
            retryLabel: retryLabel,
            errorType: errorType,
            illustration: illustration,
            secondaryActionLabel: secondaryActionLabel,
            onSecondaryAction: onSecondaryAction,
            animate: animate,
          ),
        ),
      ],
    );
  }
}
