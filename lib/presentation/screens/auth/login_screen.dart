import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/router/app_router.dart';
import 'package:fishfeed/presentation/widgets/widgets.dart';

/// Login screen with email/password form and OAuth options.
///
/// Provides:
/// - Email field with format validation
/// - Password field with visibility toggle
/// - Login button with loading state
/// - OAuth buttons (Google, Apple on iOS)
/// - Navigation to registration
/// - Error display via snackbar
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(theme, l10n),
                    const SizedBox(height: 48),
                    _buildEmailField(l10n),
                    const SizedBox(height: 16),
                    _buildPasswordField(l10n),
                    const SizedBox(height: 24),
                    _buildLoginButton(l10n, authState.isLoading),
                    const SizedBox(height: 16),
                    _buildRegisterLink(l10n),
                    const SizedBox(height: 32),
                    _buildDivider(l10n),
                    const SizedBox(height: 32),
                    _buildOAuthButtons(authState.isLoading),
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
          Icons.pets,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.welcomeMessage,
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
      textInputAction: TextInputAction.done,
      prefixIcon: const Icon(Icons.lock_outlined),
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.fieldRequired;
        }
        if (!_passwordRegex.hasMatch(value)) {
          return l10n.invalidPasswordFormat;
        }
        return null;
      },
      onSubmitted: (_) => _handleLogin(),
    );
  }

  Widget _buildLoginButton(AppLocalizations l10n, bool isLoading) {
    return AppButton(
      label: l10n.loginButton,
      isLoading: isLoading,
      onPressed: isLoading ? null : _handleLogin,
    );
  }

  Widget _buildRegisterLink(AppLocalizations l10n) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(l10n.noAccount),
        TextButton(
          onPressed: () => context.push(AppRouter.register),
          child: Text(l10n.registerButton),
        ),
      ],
    );
  }

  Widget _buildDivider(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.orContinueWith,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildOAuthButtons(bool isLoading) {
    return OAuthButtonsRow(
      onGooglePressed: _handleGoogleLogin,
      onApplePressed: _handleAppleLogin,
      isLoading: isLoading,
    );
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authNotifierProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  void _handleGoogleLogin() {
    ref.read(authNotifierProvider.notifier).loginWithGoogle();
  }

  void _handleAppleLogin() {
    ref.read(authNotifierProvider.notifier).loginWithApple();
  }
}
