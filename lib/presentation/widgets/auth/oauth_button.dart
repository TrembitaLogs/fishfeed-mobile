import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// OAuth provider types supported by the application.
enum OAuthProvider {
  /// Google Sign-In.
  google,

  /// Sign in with Apple.
  apple,
}

/// A styled button for OAuth authentication.
///
/// Displays provider-specific styling (icon, colors, text) and handles
/// loading state with a progress indicator.
///
/// Example:
/// ```dart
/// OAuthButton(
///   provider: OAuthProvider.google,
///   onPressed: () => handleGoogleSignIn(),
///   isLoading: isSigningIn,
/// )
/// ```
class OAuthButton extends StatelessWidget {
  const OAuthButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  /// The OAuth provider this button represents.
  final OAuthProvider provider;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether to show loading indicator instead of content.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getBorderColor(isDark),
        ),
        color: _getBackgroundColor(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SizedBox(
              height: 24,
              child: isLoading
                  ? _buildLoadingIndicator(isDark)
                  : _buildContent(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIcon(isDark),
        const SizedBox(width: 8),
        Text(
          _getButtonText(),
          style: TextStyle(
            color: _getTextColor(isDark),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(bool isDark) {
    switch (provider) {
      case OAuthProvider.google:
        return Image.asset(
          'assets/icons/google_logo.png',
          width: 20,
          height: 20,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.g_mobiledata,
            size: 20,
            color: _getTextColor(isDark),
          ),
        );
      case OAuthProvider.apple:
        return Icon(
          Icons.apple,
          size: 20,
          color: _getTextColor(isDark),
        );
    }
  }

  Widget _buildLoadingIndicator(bool isDark) {
    return Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getTextColor(isDark)),
        ),
      ),
    );
  }

  String _getButtonText() {
    switch (provider) {
      case OAuthProvider.google:
        return 'Continue with Google';
      case OAuthProvider.apple:
        return 'Sign in with Apple';
    }
  }

  Color _getBackgroundColor(bool isDark) {
    switch (provider) {
      case OAuthProvider.google:
        return isDark ? Colors.grey[900]! : Colors.white;
      case OAuthProvider.apple:
        // Apple HIG: black button on light theme, white on dark
        return isDark ? Colors.white : Colors.black;
    }
  }

  Color _getTextColor(bool isDark) {
    switch (provider) {
      case OAuthProvider.google:
        return isDark ? Colors.white : Colors.black87;
      case OAuthProvider.apple:
        // Apple HIG: contrasting text color
        return isDark ? Colors.black : Colors.white;
    }
  }

  Color _getBorderColor(bool isDark) {
    switch (provider) {
      case OAuthProvider.google:
        return isDark ? Colors.grey[700]! : Colors.grey[300]!;
      case OAuthProvider.apple:
        // Apple button typically has no visible border
        return isDark ? Colors.white : Colors.black;
    }
  }
}

/// A column of OAuth buttons with platform-appropriate options.
///
/// Shows Google button on all platforms and Apple button only on iOS.
///
/// Example:
/// ```dart
/// OAuthButtonsRow(
///   onGooglePressed: () => handleGoogleSignIn(),
///   onApplePressed: () => handleAppleSignIn(),
///   isLoading: isSigningIn,
/// )
/// ```
class OAuthButtonsRow extends StatelessWidget {
  const OAuthButtonsRow({
    super.key,
    required this.onGooglePressed,
    this.onApplePressed,
    this.isLoading = false,
    @visibleForTesting this.showAppleButton,
  });

  /// Callback when Google button is pressed.
  final VoidCallback? onGooglePressed;

  /// Callback when Apple button is pressed.
  final VoidCallback? onApplePressed;

  /// Whether buttons should show loading state.
  final bool isLoading;

  /// Override for testing to control Apple button visibility.
  @visibleForTesting
  final bool? showAppleButton;

  @override
  Widget build(BuildContext context) {
    final shouldShowApple = showAppleButton ?? _isAppleAvailable();

    return Column(
      children: [
        OAuthButton(
          provider: OAuthProvider.google,
          onPressed: onGooglePressed,
          isLoading: isLoading,
        ),
        if (shouldShowApple) ...[
          const SizedBox(height: 12),
          OAuthButton(
            provider: OAuthProvider.apple,
            onPressed: onApplePressed,
            isLoading: isLoading,
          ),
        ],
      ],
    );
  }

  bool _isAppleAvailable() {
    // Platform.isIOS throws on web, so we check kIsWeb first
    if (kIsWeb) return false;
    return Platform.isIOS;
  }
}
