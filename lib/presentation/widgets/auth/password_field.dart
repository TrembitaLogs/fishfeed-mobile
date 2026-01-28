import 'package:flutter/material.dart';

/// A styled password text field with visibility toggle.
///
/// Provides a reusable password input with:
/// - Lock icon prefix
/// - Eye icon suffix to toggle password visibility
/// - Secure keyboard settings (no suggestions, no autocorrect)
/// - Full validation support
///
/// Example:
/// ```dart
/// PasswordField(
///   controller: _passwordController,
///   label: 'Password',
///   validator: (value) {
///     if (value == null || value.isEmpty) {
///       return 'Password is required';
///     }
///     return null;
///   },
/// )
/// ```
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofocus = false,
  });

  /// Controller for the text field.
  final TextEditingController controller;

  /// Label text displayed above the input.
  final String? label;

  /// Hint text displayed when the input is empty.
  final String? hint;

  /// Error message to display below the input.
  final String? errorText;

  /// Validation function that returns an error message or null.
  final String? Function(String?)? validator;

  /// Callback when the text changes.
  final ValueChanged<String>? onChanged;

  /// Callback when the user submits the text.
  final ValueChanged<String>? onSubmitted;

  /// The action button on the keyboard.
  final TextInputAction? textInputAction;

  /// Whether to focus the field automatically.
  final bool autofocus;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofocus: widget.autofocus,
      enableSuggestions: false,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: widget.label ?? 'Password',
        hintText: widget.hint,
        errorText: widget.errorText,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: Semantics(
          label: _obscureText ? 'Show password' : 'Hide password',
          child: IconButton(
            icon: Icon(
              _obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: _toggleVisibility,
            tooltip: _obscureText ? 'Show password' : 'Hide password',
          ),
        ),
      ),
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
    );
  }
}
