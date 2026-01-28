import 'package:flutter/material.dart';

/// Result of the paywall bottom sheet interaction.
enum PaywallAction {
  /// User chose to upgrade to premium.
  goPremium,

  /// User chose to add fish manually.
  addManually,

  /// User dismissed the paywall.
  dismissed,
}

/// Bottom sheet shown when user has exhausted free AI scans.
///
/// Presents options to:
/// - Upgrade to Premium for unlimited scans
/// - Add fish manually without using AI
/// - Dismiss and return later
///
/// Returns [PaywallAction] indicating user's choice.
class AiScanPaywallBottomSheet extends StatelessWidget {
  const AiScanPaywallBottomSheet({super.key});

  /// Shows the paywall bottom sheet and returns the user's action.
  ///
  /// Returns null if dismissed by dragging down or tapping outside.
  static Future<PaywallAction?> show(BuildContext context) {
    return showModalBottomSheet<PaywallAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AiScanPaywallBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Illustration
              _buildIllustration(theme),
              const SizedBox(height: 24),

              // Title
              Text(
                "You've used all free scans",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Upgrade to Premium for unlimited AI fish recognition '
                'and priority processing.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Benefits list
              _buildBenefitsList(theme),
              const SizedBox(height: 32),

              // Action buttons
              _buildActionButtons(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(ThemeData theme) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.camera_alt_rounded,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.block,
                size: 20,
                color: theme.colorScheme.onError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsList(ThemeData theme) {
    final benefits = [
      (Icons.all_inclusive, 'Unlimited AI scans'),
      (Icons.speed, 'Priority processing'),
      (Icons.auto_awesome, 'Higher accuracy'),
    ];

    return Column(
      children: benefits.map((benefit) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(benefit.$1, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                benefit.$2,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary: Go Premium
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(PaywallAction.goPremium),
          icon: const Icon(Icons.workspace_premium),
          label: const Text('Go Premium'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary: Add Manually
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(PaywallAction.addManually),
          icon: const Icon(Icons.edit),
          label: const Text('Add manually'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 8),

        // Tertiary: Maybe Later
        TextButton(
          onPressed: () => Navigator.of(context).pop(PaywallAction.dismissed),
          child: Text(
            'Maybe later',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
