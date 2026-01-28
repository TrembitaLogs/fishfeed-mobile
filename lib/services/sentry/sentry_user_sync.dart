import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/services/sentry/sentry_service.dart';

/// Provider that syncs user context with Sentry.
///
/// Listens to authentication state changes and updates Sentry
/// user context accordingly. Sets user on login, clears on logout.
///
/// Usage: Watch this provider in a widget near the app root
/// to ensure it stays active:
/// ```dart
/// ref.watch(sentryUserSyncProvider);
/// ```
final sentryUserSyncProvider = Provider<void>((ref) {
  final sentryService = ref.watch(sentryServiceProvider);

  ref.listen<AuthenticationState>(authNotifierProvider, (previous, next) {
    _syncUserContext(previous, next, sentryService);
  });

  // Initial sync on provider creation
  final currentState = ref.read(authNotifierProvider);
  if (currentState.isAuthenticated && currentState.user != null) {
    final user = currentState.user!;
    sentryService.setUser(userId: user.id, email: user.email);
  }
});

/// Syncs user context based on auth state changes.
void _syncUserContext(
  AuthenticationState? previous,
  AuthenticationState next,
  SentryService sentryService,
) {
  final wasAuthenticated = previous?.isAuthenticated ?? false;
  final isAuthenticated = next.isAuthenticated;

  // User logged in
  if (!wasAuthenticated && isAuthenticated && next.user != null) {
    final user = next.user!;
    sentryService.setUser(userId: user.id, email: user.email);
    return;
  }

  // User logged out
  if (wasAuthenticated && !isAuthenticated) {
    sentryService.clearUser();
    return;
  }

  // User updated (e.g., email changed)
  if (isAuthenticated && next.user != null) {
    final previousUser = previous?.user;
    final currentUser = next.user!;

    if (previousUser?.id != currentUser.id ||
        previousUser?.email != currentUser.email) {
      sentryService.setUser(userId: currentUser.id, email: currentUser.email);
    }
  }
}
