import 'package:flutter/material.dart';

/// A single benefit item displayed in the paywall benefits list.
///
/// Shows an icon and text describing a premium feature benefit.
class BenefitItem extends StatelessWidget {
  const BenefitItem({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
  });

  /// The icon representing the benefit.
  final IconData icon;

  /// The text description of the benefit.
  final String text;

  /// Optional custom color for the icon.
  /// Defaults to primary color.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 22,
              color: iconColor ?? theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.check_circle,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
