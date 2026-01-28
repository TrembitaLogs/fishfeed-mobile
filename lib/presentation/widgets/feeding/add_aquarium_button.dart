import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/router/app_router.dart';

/// Button widget for adding a new aquarium from the Today view.
///
/// Displays an outlined button that navigates to the onboarding flow
/// in "add aquarium" mode.
class AddAquariumButton extends StatelessWidget {
  const AddAquariumButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: OutlinedButton.icon(
        onPressed: () => _onAddAquarium(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addAnotherAquarium),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _onAddAquarium(BuildContext context) {
    // Navigate to add aquarium screen
    context.push(AppRouter.addAquarium);
  }
}
