import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/repositories/family_repository_impl.dart';
import 'package:fishfeed/domain/entities/family_invite.dart';
import 'package:fishfeed/domain/entities/family_member.dart';
import 'package:fishfeed/domain/repositories/family_repository.dart';

/// State for family sharing feature.
class FamilyState {
  const FamilyState({
    this.invites = const [],
    this.members = const [],
    this.isLoading = false,
    this.error,
    this.lastCreatedInvite,
  });

  /// Initial empty state.
  const FamilyState.initial()
      : invites = const [],
        members = const [],
        isLoading = false,
        error = null,
        lastCreatedInvite = null;

  /// Active invitations for the aquarium.
  final List<FamilyInvite> invites;

  /// Family members with access to the aquarium.
  final List<FamilyMember> members;

  /// Whether a family operation is in progress.
  final bool isLoading;

  /// Current error, if any.
  final Failure? error;

  /// The most recently created invite (for sharing).
  final FamilyInvite? lastCreatedInvite;

  /// Creates a copy with updated fields.
  FamilyState copyWith({
    List<FamilyInvite>? invites,
    List<FamilyMember>? members,
    bool? isLoading,
    Failure? error,
    FamilyInvite? lastCreatedInvite,
    bool clearError = false,
    bool clearLastInvite = false,
  }) {
    return FamilyState(
      invites: invites ?? this.invites,
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastCreatedInvite:
          clearLastInvite ? null : (lastCreatedInvite ?? this.lastCreatedInvite),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FamilyState &&
        _listEquals(other.invites, invites) &&
        _listEquals(other.members, members) &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.lastCreatedInvite == lastCreatedInvite;
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(invites),
        Object.hashAll(members),
        isLoading,
        error,
        lastCreatedInvite,
      );
}

/// Notifier for managing family sharing state.
class FamilyNotifier extends StateNotifier<FamilyState> {
  FamilyNotifier({
    required FamilyRepository repository,
  })  : _repository = repository,
        super(const FamilyState.initial());

  final FamilyRepository _repository;

  /// Loads family data (invites and members) for an aquarium.
  Future<void> loadFamilyData(String aquariumId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final results = await Future.wait([
      _repository.getInvites(aquariumId: aquariumId),
      _repository.getMembers(aquariumId: aquariumId),
    ]);

    final invitesResult = results[0];
    final membersResult = results[1];

    List<FamilyInvite> invites = [];
    List<FamilyMember> members = [];
    Failure? error;

    invitesResult.fold(
      (failure) => error = failure,
      (data) => invites = data as List<FamilyInvite>,
    );

    membersResult.fold(
      (failure) => error ??= failure,
      (data) => members = data as List<FamilyMember>,
    );

    state = state.copyWith(
      invites: invites,
      members: members,
      isLoading: false,
      error: error,
    );
  }

  /// Creates a new family invitation.
  Future<void> createInvite(String aquariumId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearLastInvite: true);

    final result = await _repository.createInvite(aquariumId: aquariumId);

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure);
      },
      (invite) {
        state = state.copyWith(
          invites: [...state.invites, invite],
          isLoading: false,
          lastCreatedInvite: invite,
        );
      },
    );
  }

  /// Cancels an existing invitation.
  Future<void> cancelInvite(String inviteId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.cancelInvite(inviteId: inviteId);

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure);
      },
      (_) {
        state = state.copyWith(
          invites: state.invites.where((i) => i.id != inviteId).toList(),
          isLoading: false,
        );
      },
    );
  }

  /// Removes a family member.
  Future<void> removeMember(String memberId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.removeMember(memberId: memberId);

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure);
      },
      (_) {
        state = state.copyWith(
          members: state.members.where((m) => m.id != memberId).toList(),
          isLoading: false,
        );
      },
    );
  }

  /// Accepts a family invitation.
  Future<void> acceptInvite(String inviteCode) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.acceptInvite(inviteCode: inviteCode);

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure);
      },
      (member) {
        state = state.copyWith(
          members: [...state.members, member],
          isLoading: false,
        );
      },
    );
  }

  /// Clears the last created invite.
  void clearLastInvite() {
    state = state.copyWith(clearLastInvite: true);
  }

  /// Clears any errors.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for [FamilyNotifier].
final familyNotifierProvider =
    StateNotifierProvider<FamilyNotifier, FamilyState>((ref) {
  final repository = ref.watch(familyRepositoryProvider);

  return FamilyNotifier(repository: repository);
});

/// Provider for family state.
final familyStateProvider = Provider<FamilyState>((ref) {
  return ref.watch(familyNotifierProvider);
});

/// Provider for family members list.
final familyMembersProvider = Provider<List<FamilyMember>>((ref) {
  return ref.watch(familyNotifierProvider).members;
});

/// Provider for active invites list.
final familyInvitesProvider = Provider<List<FamilyInvite>>((ref) {
  return ref.watch(familyNotifierProvider).invites;
});

/// Provider for checking if family is loading.
final familyLoadingProvider = Provider<bool>((ref) {
  return ref.watch(familyNotifierProvider).isLoading;
});
