import 'package:flutter/material.dart';
import 'package:fishfeed/l10n/app_localizations.dart';

import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/domain/entities/feeding_status.dart';

/// Animated circular status indicator for feeding events.
///
/// Displays the feeding status with:
/// - Color-coded background (green=fed, red=missed, amber=pending)
/// - Status icon (check=fed, close=missed, schedule=pending)
/// - Smooth animated transitions between states
/// - Optional positive framing tooltip messages
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({
    super.key,
    required this.status,
    this.size = StatusIndicatorSize.medium,
    this.showTooltip = false,
  });

  /// The feeding status to display.
  final FeedingStatus status;

  /// Size variant of the indicator.
  final StatusIndicatorSize size;

  /// Whether to show a tooltip with positive framing message.
  final bool showTooltip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = getStatusColor(status);
    final icon = getStatusIcon(status);
    final dimensions = _getDimensions(size);

    final indicator = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: dimensions.containerSize,
      height: dimensions.containerSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(dimensions.borderRadius),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          icon,
          key: ValueKey(status),
          color: color,
          size: dimensions.iconSize,
        ),
      ),
    );

    if (showTooltip) {
      return Tooltip(
        message: getPositiveMessage(status, l10n),
        child: indicator,
      );
    }

    return indicator;
  }

  /// Returns the color for the given status.
  static Color getStatusColor(FeedingStatus status) {
    return switch (status) {
      FeedingStatus.fed => Colors.green,
      FeedingStatus.missed => Colors.red,
      FeedingStatus.pending => Colors.amber.shade700,
    };
  }

  /// Returns the color for the given EventStatus.
  static Color getEventStatusColor(EventStatus status) {
    return switch (status) {
      EventStatus.fed => Colors.green,
      EventStatus.skipped => Colors.red,
      EventStatus.overdue => Colors.red,
      EventStatus.pending => Colors.amber.shade700,
    };
  }

  /// Factory constructor from EventStatus.
  static StatusIndicator fromEventStatus({
    Key? key,
    required EventStatus status,
    StatusIndicatorSize size = StatusIndicatorSize.medium,
    bool showTooltip = false,
  }) {
    final feedingStatus = switch (status) {
      EventStatus.fed => FeedingStatus.fed,
      EventStatus.skipped => FeedingStatus.missed,
      EventStatus.overdue => FeedingStatus.missed,
      EventStatus.pending => FeedingStatus.pending,
    };
    return StatusIndicator(
      key: key,
      status: feedingStatus,
      size: size,
      showTooltip: showTooltip,
    );
  }

  /// Returns the icon for the given status.
  static IconData getStatusIcon(FeedingStatus status) {
    return switch (status) {
      FeedingStatus.fed => Icons.check,
      FeedingStatus.missed => Icons.close,
      FeedingStatus.pending => Icons.schedule,
    };
  }

  /// Returns a positive framing message for the given status.
  static String getPositiveMessage(
    FeedingStatus status,
    AppLocalizations l10n,
  ) {
    return switch (status) {
      FeedingStatus.fed => l10n.statusGreatJob,
      FeedingStatus.missed => l10n.statusNextTime,
      FeedingStatus.pending => l10n.statusPendingFeeding,
    };
  }

  _IndicatorDimensions _getDimensions(StatusIndicatorSize size) {
    return switch (size) {
      StatusIndicatorSize.small => const _IndicatorDimensions(
        containerSize: 32,
        iconSize: 18,
        borderRadius: 8,
      ),
      StatusIndicatorSize.medium => const _IndicatorDimensions(
        containerSize: 40,
        iconSize: 22,
        borderRadius: 10,
      ),
      StatusIndicatorSize.large => const _IndicatorDimensions(
        containerSize: 56,
        iconSize: 32,
        borderRadius: 14,
      ),
    };
  }
}

/// Size variants for StatusIndicator.
enum StatusIndicatorSize {
  /// Small indicator for compact displays.
  small,

  /// Medium indicator for standard use (default).
  medium,

  /// Large indicator for prominent displays.
  large,
}

/// Dimension configuration for indicator sizes.
class _IndicatorDimensions {
  const _IndicatorDimensions({
    required this.containerSize,
    required this.iconSize,
    required this.borderRadius,
  });

  final double containerSize;
  final double iconSize;
  final double borderRadius;
}
