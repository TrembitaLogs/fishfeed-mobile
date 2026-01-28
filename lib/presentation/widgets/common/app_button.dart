import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Button type variants for [AppButton].
enum AppButtonType {
  /// Primary filled button using ElevatedButton style.
  primary,

  /// Secondary outlined button using OutlinedButton style.
  secondary,

  /// Text-only button using TextButton style.
  text,
}

/// A reusable button widget that supports different styles, loading states,
/// disabled states, and haptic feedback.
///
/// Uses the app's theme for consistent styling across the application.
/// Includes light haptic feedback on tap for better user experience.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.buttonType = AppButtonType.primary,
    this.icon,
    this.enableHaptic = true,
  });

  /// The text to display on the button.
  final String label;

  /// Callback when the button is pressed.
  /// When null, the button is in disabled state.
  final VoidCallback? onPressed;

  /// Whether to show a loading indicator instead of the label.
  final bool isLoading;

  /// The visual style of the button.
  final AppButtonType buttonType;

  /// Optional icon to display before the label.
  final IconData? icon;

  /// Whether to trigger haptic feedback on tap.
  final bool enableHaptic;

  void _handlePress() {
    if (enableHaptic) {
      HapticFeedback.lightImpact();
    }
    onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    return switch (buttonType) {
      AppButtonType.primary => _buildElevatedButton(context, isDisabled),
      AppButtonType.secondary => _buildOutlinedButton(context, isDisabled),
      AppButtonType.text => _buildTextButton(context, isDisabled),
    };
  }

  Widget _buildElevatedButton(BuildContext context, bool isDisabled) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: isDisabled ? null : _handlePress,
      child: _buildContent(
        theme.colorScheme.onPrimary,
        isDisabled ? theme.colorScheme.onSurface.withValues(alpha: 0.38) : null,
      ),
    );
  }

  Widget _buildOutlinedButton(BuildContext context, bool isDisabled) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: isDisabled ? null : _handlePress,
      child: _buildContent(
        theme.colorScheme.primary,
        isDisabled ? theme.colorScheme.onSurface.withValues(alpha: 0.38) : null,
      ),
    );
  }

  Widget _buildTextButton(BuildContext context, bool isDisabled) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: isDisabled ? null : _handlePress,
      child: _buildContent(
        theme.colorScheme.primary,
        isDisabled ? theme.colorScheme.onSurface.withValues(alpha: 0.38) : null,
      ),
    );
  }

  Widget _buildContent(Color activeColor, Color? disabledColor) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            disabledColor ?? activeColor,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }

    return Text(label);
  }
}
