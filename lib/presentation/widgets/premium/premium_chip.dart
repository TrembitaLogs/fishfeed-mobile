import 'package:flutter/material.dart';

/// A small chip indicating a feature requires premium subscription.
///
/// Can be placed next to premium-only features to indicate they're locked.
class PremiumChip extends StatelessWidget {
  const PremiumChip({
    super.key,
    this.size = PremiumChipSize.small,
    this.showIcon = true,
  });

  /// Size variant of the chip.
  final PremiumChipSize size;

  /// Whether to show the crown icon.
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final dimensions = _getDimensions(size);
    const backgroundColor = Color(0xFFFFF8E1); // Amber 50
    const foregroundColor = Color(0xFFF57C00); // Amber 800

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dimensions.horizontalPadding,
        vertical: dimensions.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(dimensions.borderRadius),
        border: Border.all(
          color: foregroundColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.workspace_premium,
              size: dimensions.iconSize,
              color: foregroundColor,
            ),
            SizedBox(width: dimensions.spacing),
          ],
          Text(
            'PRO',
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.bold,
              fontSize: dimensions.fontSize,
            ),
          ),
        ],
      ),
    );
  }

  _ChipDimensions _getDimensions(PremiumChipSize size) {
    return switch (size) {
      PremiumChipSize.tiny => const _ChipDimensions(
          horizontalPadding: 4,
          verticalPadding: 2,
          iconSize: 10,
          fontSize: 8,
          spacing: 2,
          borderRadius: 6,
        ),
      PremiumChipSize.small => const _ChipDimensions(
          horizontalPadding: 6,
          verticalPadding: 2,
          iconSize: 12,
          fontSize: 10,
          spacing: 3,
          borderRadius: 8,
        ),
      PremiumChipSize.medium => const _ChipDimensions(
          horizontalPadding: 8,
          verticalPadding: 4,
          iconSize: 14,
          fontSize: 12,
          spacing: 4,
          borderRadius: 10,
        ),
    };
  }
}

/// Size variants for PremiumChip.
enum PremiumChipSize {
  /// Tiny chip for very compact displays.
  tiny,

  /// Small chip for compact displays (default).
  small,

  /// Medium chip for more prominent displays.
  medium,
}

/// Dimension configuration for chip sizes.
class _ChipDimensions {
  const _ChipDimensions({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.iconSize,
    required this.fontSize,
    required this.spacing,
    required this.borderRadius,
  });

  final double horizontalPadding;
  final double verticalPadding;
  final double iconSize;
  final double fontSize;
  final double spacing;
  final double borderRadius;
}
