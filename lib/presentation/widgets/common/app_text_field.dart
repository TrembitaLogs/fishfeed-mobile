import 'package:flutter/material.dart';

/// A styled text field wrapper that uses the app's InputDecorationTheme.
///
/// Provides a consistent text input experience with validation support.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.enabled = true,
    this.autofocus = false,
  });

  /// Controller for the text field.
  final TextEditingController? controller;

  /// Label text displayed above the input.
  final String? label;

  /// Hint text displayed when the input is empty.
  final String? hint;

  /// Error message to display below the input.
  final String? errorText;

  /// Whether to obscure the text (for passwords).
  final bool obscureText;

  /// Icon displayed at the start of the input.
  final Widget? prefixIcon;

  /// Icon displayed at the end of the input.
  final Widget? suffixIcon;

  /// Validation function that returns an error message or null.
  final String? Function(String?)? validator;

  /// Callback when the text changes.
  final ValueChanged<String>? onChanged;

  /// Callback when the user submits the text.
  final ValueChanged<String>? onSubmitted;

  /// The type of keyboard to display.
  final TextInputType? keyboardType;

  /// The action button on the keyboard.
  final TextInputAction? textInputAction;

  /// Maximum number of lines for the input.
  final int maxLines;

  /// Whether the text field is enabled.
  final bool enabled;

  /// Whether to focus the field automatically.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      enabled: enabled,
      autofocus: autofocus,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
    );
  }
}
