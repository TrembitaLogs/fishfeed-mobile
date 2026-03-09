import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/repositories/family_repository_impl.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/router/app_router.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

/// Screen for accepting a family invite via deep link.
///
/// Handles the full accept flow directly (without autoDispose StateNotifier)
/// to avoid disposal race conditions when GoRouter redirects mid-flight.
class JoinFamilyScreen extends ConsumerStatefulWidget {
  const JoinFamilyScreen({super.key, required this.inviteCode});

  /// The invite code from the deep link.
  final String inviteCode;

  @override
  ConsumerState<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

enum _ScreenState { loading, success, error }

class _JoinFamilyScreenState extends ConsumerState<JoinFamilyScreen> {
  _ScreenState _screenState = _ScreenState.loading;
  String? _errorMessage;
  bool _requiresAuth = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _acceptInvite();
    });
  }

  Future<void> _acceptInvite() async {
    final repository = ref.read(familyRepositoryProvider);
    final result = await repository.acceptInvite(inviteCode: widget.inviteCode);

    if (!mounted) return;

    await result.fold(
      (failure) async {
        if (!mounted) return;
        setState(() {
          _screenState = _ScreenState.error;
          _requiresAuth = failure is AuthenticationFailure;
          _errorMessage = switch (failure) {
            ValidationFailure(:final message) => message ?? 'Validation failed',
            AuthenticationFailure(:final message) =>
              message ?? 'Authentication required',
            _ => 'Failed to accept invitation. Please try again.',
          };
        });
        if (_requiresAuth) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) context.go(AppRouter.auth);
          });
        }
      },
      (member) async {
        if (!mounted) return;
        setState(() {
          _screenState = _ScreenState.success;
        });

        // Wait for any in-progress sync to finish, then do a full sync
        // to fetch the shared aquarium. Delta sync misses it because
        // the aquarium's updated_at didn't change when the member was added.
        final syncService = ref.read(syncServiceProvider);
        while (syncService.isProcessing) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          if (!mounted) return;
        }
        await syncService.syncAll(fullSync: true);
        if (!mounted) return;

        // Reload aquariums from local storage after sync
        await ref.read(userAquariumsProvider.notifier).loadAquariums();
        if (!mounted) return;

        // Complete onboarding and navigate. This triggers GoRouter
        // refreshListenable which redirects away from this screen.
        ref.read(authNotifierProvider.notifier).completeOnboarding();
        context.go('${AppRouter.home}?selectedAquarium=${member.aquariumId}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: switch (_screenState) {
              _ScreenState.loading => _buildLoading(theme),
              _ScreenState.success => _buildSuccess(theme),
              _ScreenState.error => _buildError(theme),
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
          child: const Center(child: CircularProgressIndicator()),
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

  Widget _buildSuccess(ThemeData theme) {
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

  Widget _buildError(ThemeData theme) {
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
            _requiresAuth ? Icons.lock_outline : Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _requiresAuth ? l10n.loginRequired : l10n.invitationError,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _requiresAuth ? l10n.loginToAcceptInvitation : (_errorMessage ?? ''),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (_requiresAuth)
          FilledButton.icon(
            onPressed: () => context.go(AppRouter.auth),
            icon: const Icon(Icons.login),
            label: Text(l10n.logIn),
          )
        else
          OutlinedButton.icon(
            onPressed: () => context.go(AppRouter.home),
            icon: const Icon(Icons.home),
            label: Text(l10n.toHome),
          ),
      ],
    );
  }
}
