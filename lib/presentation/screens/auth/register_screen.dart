import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/widgets/widgets.dart';

/// Registration screen with email/password form and Terms of Service.
///
/// Provides:
/// - Email field with format validation
/// - Password field with visibility toggle and strength indicator
/// - Confirm password field with match validation
/// - Terms of Service checkbox (required)
/// - Create Account button with loading state
/// - Navigation to login
/// - Error display via snackbar
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _showTosError = false;

  /// Email validation regex pattern.
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Password validation: min 8 chars, 1 number, 1 uppercase.
  static final _passwordRegex = RegExp(
    r'^(?=.*[A-Z])(?=.*\d).{8,}$',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);

    // Note: Auth errors are handled globally in app.dart via _GlobalAuthErrorListener

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(theme, l10n),
                    const SizedBox(height: 48),
                    _buildEmailField(l10n),
                    const SizedBox(height: 16),
                    _buildPasswordField(l10n),
                    const SizedBox(height: 8),
                    _PasswordStrengthIndicator(
                      password: _passwordController.text,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 16),
                    _buildConfirmPasswordField(l10n),
                    const SizedBox(height: 24),
                    _buildTermsCheckbox(l10n, theme),
                    const SizedBox(height: 24),
                    _buildCreateAccountButton(l10n, authState.isLoading),
                    const SizedBox(height: 16),
                    _buildLoginLink(l10n),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppLocalizations l10n) {
    return Column(
      children: [
        Icon(
          Icons.person_add,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.createAccount,
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField(AppLocalizations l10n) {
    return AppTextField(
      controller: _emailController,
      label: l10n.email,
      hint: 'example@email.com',
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      prefixIcon: const Icon(Icons.email_outlined),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.fieldRequired;
        }
        if (!_emailRegex.hasMatch(value)) {
          return l10n.invalidEmailFormat;
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(AppLocalizations l10n) {
    return AppTextField(
      controller: _passwordController,
      label: l10n.password,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      prefixIcon: const Icon(Icons.lock_outlined),
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
      onChanged: (_) {
        // Trigger rebuild for password strength indicator
        setState(() {});
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.fieldRequired;
        }
        if (!_passwordRegex.hasMatch(value)) {
          return l10n.invalidPasswordFormat;
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField(AppLocalizations l10n) {
    return AppTextField(
      controller: _confirmPasswordController,
      label: l10n.confirmPassword,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      prefixIcon: const Icon(Icons.lock_outlined),
      suffixIcon: IconButton(
        icon: Icon(
          _obscureConfirmPassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
        onPressed: () {
          setState(() {
            _obscureConfirmPassword = !_obscureConfirmPassword;
          });
        },
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.fieldRequired;
        }
        if (value != _passwordController.text) {
          return l10n.passwordsDoNotMatch;
        }
        return null;
      },
      onSubmitted: (_) => _handleRegister(),
    );
  }

  Widget _buildTermsCheckbox(AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _agreedToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreedToTerms = value ?? false;
                    if (_agreedToTerms) {
                      _showTosError = false;
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _agreedToTerms = !_agreedToTerms;
                    if (_agreedToTerms) {
                      _showTosError = false;
                    }
                  });
                },
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(text: l10n.agreeToTermsPrefix),
                      TextSpan(
                        text: l10n.termsOfService,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = _openTermsOfService,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_showTosError)
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 8),
            child: Text(
              l10n.tosCheckboxRequired,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCreateAccountButton(AppLocalizations l10n, bool isLoading) {
    return AppButton(
      label: l10n.createAccountButton,
      isLoading: isLoading,
      onPressed: isLoading ? null : _handleRegister,
    );
  }

  Widget _buildLoginLink(AppLocalizations l10n) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(l10n.alreadyHaveAccount),
        TextButton(
          onPressed: () => context.pop(),
          child: Text(l10n.loginButton),
        ),
      ],
    );
  }

  void _handleRegister() {
    final formValid = _formKey.currentState?.validate() ?? false;

    if (!_agreedToTerms) {
      setState(() {
        _showTosError = true;
      });
    }

    if (formValid && _agreedToTerms) {
      ref.read(authNotifierProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          );
    }
  }

  void _openTermsOfService() {
    // TODO: Replace with actual Terms of Service URL
    const tosUrl = 'https://fishfeed.app/terms';
    launchUrl(Uri.parse(tosUrl), mode: LaunchMode.externalApplication);
  }
}

/// Password strength level.
enum _PasswordStrength {
  weak,
  medium,
  strong,
}

/// Widget that displays password strength as a colored progress bar.
class _PasswordStrengthIndicator extends StatelessWidget {
  const _PasswordStrengthIndicator({
    required this.password,
    required this.l10n,
  });

  final String password;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = _calculateStrength(password);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: _getProgressValue(strength),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(_getColor(strength)),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
        const SizedBox(height: 4),
        Text(
          _getLabel(strength),
          style: theme.textTheme.bodySmall?.copyWith(
            color: _getColor(strength),
          ),
        ),
      ],
    );
  }

  _PasswordStrength _calculateStrength(String password) {
    int score = 0;

    // Check length
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Check for uppercase letter
    if (password.contains(RegExp(r'[A-Z]'))) score++;

    // Check for number
    if (password.contains(RegExp(r'\d'))) score++;

    // Check for special character
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    if (score <= 2) {
      return _PasswordStrength.weak;
    } else if (score <= 4) {
      return _PasswordStrength.medium;
    } else {
      return _PasswordStrength.strong;
    }
  }

  double _getProgressValue(_PasswordStrength strength) {
    return switch (strength) {
      _PasswordStrength.weak => 0.33,
      _PasswordStrength.medium => 0.66,
      _PasswordStrength.strong => 1.0,
    };
  }

  Color _getColor(_PasswordStrength strength) {
    return switch (strength) {
      _PasswordStrength.weak => Colors.red,
      _PasswordStrength.medium => Colors.orange,
      _PasswordStrength.strong => Colors.green,
    };
  }

  String _getLabel(_PasswordStrength strength) {
    return switch (strength) {
      _PasswordStrength.weak => l10n.passwordWeak,
      _PasswordStrength.medium => l10n.passwordMedium,
      _PasswordStrength.strong => l10n.passwordStrong,
    };
  }
}
