import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/join_invite_provider.dart';
import 'package:fishfeed/presentation/router/app_router.dart';

/// Screen for accepting a family invite via deep link.
///
/// Handles the following scenarios:
/// - Loading: Shows progress while accepting the invite
/// - Success: Shows confirmation and redirects to the aquarium
/// - Invalid code: Shows error with option to go home
/// - Expired code: Shows error with option to go home
/// - Not authenticated: Redirects to login
class JoinFamilyScreen extends ConsumerStatefulWidget {
  const JoinFamilyScreen({
    super.key,
    required this.inviteCode,
  });

  /// The invite code from the deep link.
  final String inviteCode;

  @override
  ConsumerState<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends ConsumerState<JoinFamilyScreen> {
  bool _hasAccepted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _acceptInvite();
    });
  }

  void _acceptInvite() {
    if (_hasAccepted) return;
    _hasAccepted = true;

    ref.read(joinInviteNotifierProvider.notifier).acceptInvite(widget.inviteCode);
  }

  void _goHome() {
    context.go(AppRouter.home);
  }

  void _goToAquarium(String aquariumId) {
    context.go('${AppRouter.home}?selectedAquarium=$aquariumId');
  }

  void _goToLogin() {
    context.go(AppRouter.auth);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(joinInviteNotifierProvider);
    final theme = Theme.of(context);

    ref.listen<JoinInviteState>(
      joinInviteNotifierProvider,
      (previous, next) {
        if (next is JoinInviteSuccess) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _goToAquarium(next.member.aquariumId);
            }
          });
        }
        if (next is JoinInviteError && next.requiresAuth) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _goToLogin();
            }
          });
        }
      },
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: switch (state) {
              JoinInviteInitial() => _buildLoading(theme),
              JoinInviteLoading() => _buildLoading(theme),
              JoinInviteSuccess(:final member) => _buildSuccess(theme, member.aquariumId),
              JoinInviteError(:final message, :final requiresAuth) =>
                _buildError(theme, message, requiresAuth),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.joiningFamily,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.processingInvitation,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccess(ThemeData theme, String aquariumId) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 48,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.congratulations,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.joinedFamilySuccess,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          l10n.redirecting,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildError(ThemeData theme, String message, bool requiresAuth) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            requiresAuth ? Icons.lock_outline : Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          requiresAuth ? l10n.loginRequired : l10n.invitationError,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          requiresAuth
              ? l10n.loginToAcceptInvitation
              : message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (requiresAuth)
          FilledButton.icon(
            onPressed: _goToLogin,
            icon: const Icon(Icons.login),
            label: Text(l10n.logIn),
          )
        else
          OutlinedButton.icon(
            onPressed: _goHome,
            icon: const Icon(Icons.home),
            label: Text(l10n.toHome),
          ),
      ],
    );
  }
}
