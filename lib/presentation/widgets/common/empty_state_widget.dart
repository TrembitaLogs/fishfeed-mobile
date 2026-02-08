import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fishfeed/core/config/animation_config.dart';

/// A reusable empty state widget that displays an icon, title, description,
/// and optional action button.
///
/// Used when a list or view has no data to display.
/// Supports custom illustrations and integrates with the app's theme.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.illustration,
    this.animate = true,
  });

  /// The icon to display in the circular container.
  /// Ignored if [illustration] is provided.
  final IconData icon;

  /// The main title text.
  final String title;

  /// The description text below the title.
  final String description;

  /// Optional action button label.
  final String? actionLabel;

  /// Callback when the action button is pressed.
  /// Button is only shown when both [actionLabel] and [onAction] are provided.
  final VoidCallback? onAction;

  /// Optional custom illustration widget to replace the icon container.
  /// When provided, [icon] is ignored.
  final Widget? illustration;

  /// Whether to animate the widget on appearance.
  final bool animate;

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
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );

    if (animate && !AnimationConfig.shouldReduceMotion(context)) {
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
    if (illustration != null) {
      return illustration!;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 40, color: theme.colorScheme.primary),
    );
  }
}

/// A scrollable empty state widget that works with [RefreshIndicator].
///
/// Use this variant when the empty state needs to support pull-to-refresh.
class ScrollableEmptyState extends StatelessWidget {
  const ScrollableEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.illustration,
    this.animate = true,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? illustration;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyStateWidget(
            icon: icon,
            title: title,
            description: description,
            actionLabel: actionLabel,
            onAction: onAction,
            illustration: illustration,
            animate: animate,
          ),
        ),
      ],
    );
  }
}
