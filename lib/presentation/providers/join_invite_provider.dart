import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/core/di/repository_providers.dart';
import 'package:fishfeed/domain/entities/family_member.dart';
import 'package:fishfeed/domain/repositories/family_repository.dart';

/// State for the join invite operation.
sealed class JoinInviteState {
  const JoinInviteState();
}

/// Initial state before any action.
class JoinInviteInitial extends JoinInviteState {
  const JoinInviteInitial();
}

/// Loading state while accepting the invite.
class JoinInviteLoading extends JoinInviteState {
  const JoinInviteLoading();
}

/// Success state after accepting the invite.
class JoinInviteSuccess extends JoinInviteState {
  const JoinInviteSuccess({required this.member});

  /// The family member that was created.
  final FamilyMember member;
}

/// Error state when invite acceptance fails.
class JoinInviteError extends JoinInviteState {
  const JoinInviteError({required this.failure});

  /// The failure that occurred.
  final Failure failure;

  /// User-friendly error message.
  String get message {
    return switch (failure) {
      ValidationFailure(:final message) => message ?? 'Validation failed',
      AuthenticationFailure(:final message) =>
        message ?? 'Authentication required',
      _ => 'Failed to accept invitation. Please try again.',
    };
  }

  /// Whether the error indicates an invalid or expired code.
  bool get isInvalidCode =>
      failure is ValidationFailure &&
      ((failure as ValidationFailure).message?.toLowerCase().contains(
            'invalid',
          ) ??
          false);

  /// Whether the error indicates user is not authenticated.
  bool get requiresAuth => failure is AuthenticationFailure;
}

/// Notifier for managing join invite state.
class JoinInviteNotifier extends StateNotifier<JoinInviteState> {
  JoinInviteNotifier({required FamilyRepository repository})
    : _repository = repository,
      super(const JoinInviteInitial());

  final FamilyRepository _repository;

  /// Accepts an invite using the provided code.
  Future<void> acceptInvite(String inviteCode) async {
    state = const JoinInviteLoading();

    final result = await _repository.acceptInvite(inviteCode: inviteCode);

    result.fold(
      (failure) => state = JoinInviteError(failure: failure),
      (member) => state = JoinInviteSuccess(member: member),
    );
  }

  /// Resets the state to initial.
  void reset() {
    state = const JoinInviteInitial();
  }
}

/// Provider for [JoinInviteNotifier].
final joinInviteNotifierProvider =
    StateNotifierProvider.autoDispose<JoinInviteNotifier, JoinInviteState>((
      ref,
    ) {
      final repository = ref.watch(familyRepositoryProvider);

      return JoinInviteNotifier(repository: repository);
    });
