import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/data/repositories/user_repository_impl.dart';
import 'package:fishfeed/domain/repositories/user_repository.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';

/// State for the profile screen.
///
/// Tracks user data, loading states, and any errors during profile operations.
class ProfileState {
  const ProfileState({
    this.isUpdatingNickname = false,
    this.isUpdatingAvatar = false,
    this.error,
    this.nicknameError,
  });

  /// Initial profile state.
  const ProfileState.initial()
      : isUpdatingNickname = false,
        isUpdatingAvatar = false,
        error = null,
        nicknameError = null;

  /// Whether a nickname update is in progress.
  final bool isUpdatingNickname;

  /// Whether an avatar upload is in progress.
  final bool isUpdatingAvatar;

  /// General error from profile operations.
  final Failure? error;

  /// Validation error for nickname field.
  final String? nicknameError;

  /// Whether any update operation is in progress.
  bool get isLoading => isUpdatingNickname || isUpdatingAvatar;

  /// Creates a copy with updated fields.
  ProfileState copyWith({
    bool? isUpdatingNickname,
    bool? isUpdatingAvatar,
    Failure? error,
    String? nicknameError,
    bool clearError = false,
    bool clearNicknameError = false,
  }) {
    return ProfileState(
      isUpdatingNickname: isUpdatingNickname ?? this.isUpdatingNickname,
      isUpdatingAvatar: isUpdatingAvatar ?? this.isUpdatingAvatar,
      error: clearError ? null : (error ?? this.error),
      nicknameError: clearNicknameError ? null : (nicknameError ?? this.nicknameError),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileState &&
        other.isUpdatingNickname == isUpdatingNickname &&
        other.isUpdatingAvatar == isUpdatingAvatar &&
        other.error == error &&
        other.nicknameError == nicknameError;
  }

  @override
  int get hashCode => Object.hash(
        isUpdatingNickname,
        isUpdatingAvatar,
        error,
        nicknameError,
      );
}

/// Notifier for managing profile state.
///
/// Provides methods for updating user profile information including
/// nickname and avatar.
class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier({
    required UserRepository userRepository,
    required AuthNotifier authNotifier,
  })  : _userRepository = userRepository,
        _authNotifier = authNotifier,
        super(const ProfileState.initial());

  final UserRepository _userRepository;
  final AuthNotifier _authNotifier;

  /// Minimum nickname length.
  static const int minNicknameLength = 3;

  /// Maximum nickname length.
  static const int maxNicknameLength = 20;

  /// Updates the user's display name (nickname).
  ///
  /// Validates the nickname before sending to the server.
  /// Updates the auth state on success.
  Future<bool> updateNickname(String nickname) async {
    // Validate nickname
    final trimmedNickname = nickname.trim();

    if (trimmedNickname.isEmpty) {
      state = state.copyWith(nicknameError: 'Nickname cannot be empty');
      return false;
    }

    if (trimmedNickname.length < minNicknameLength) {
      state = state.copyWith(
        nicknameError: 'Nickname must be at least $minNicknameLength characters',
      );
      return false;
    }

    if (trimmedNickname.length > maxNicknameLength) {
      state = state.copyWith(
        nicknameError: 'Nickname cannot exceed $maxNicknameLength characters',
      );
      return false;
    }

    state = state.copyWith(
      isUpdatingNickname: true,
      clearError: true,
      clearNicknameError: true,
    );

    final result = await _userRepository.updateDisplayName(
      displayName: trimmedNickname,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isUpdatingNickname: false,
          error: failure,
        );
        return false;
      },
      (user) {
        state = state.copyWith(isUpdatingNickname: false);
        _authNotifier.updateUser(user);
        return true;
      },
    );
  }

  /// Updates the user's avatar.
  ///
  /// Uploads the image file and updates the auth state on success.
  Future<bool> updateAvatar(File avatarFile) async {
    state = state.copyWith(
      isUpdatingAvatar: true,
      clearError: true,
    );

    final result = await _userRepository.updateAvatar(
      avatarFile: avatarFile,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isUpdatingAvatar: false,
          error: failure,
        );
        return false;
      },
      (user) {
        state = state.copyWith(isUpdatingAvatar: false);
        _authNotifier.updateUser(user);
        return true;
      },
    );
  }

  /// Validates a nickname without updating.
  ///
  /// Returns null if valid, or an error message if invalid.
  String? validateNickname(String nickname) {
    final trimmedNickname = nickname.trim();

    if (trimmedNickname.isEmpty) {
      return 'Nickname cannot be empty';
    }

    if (trimmedNickname.length < minNicknameLength) {
      return 'Nickname must be at least $minNicknameLength characters';
    }

    if (trimmedNickname.length > maxNicknameLength) {
      return 'Nickname cannot exceed $maxNicknameLength characters';
    }

    return null;
  }

  /// Clears any errors.
  void clearErrors() {
    state = state.copyWith(
      clearError: true,
      clearNicknameError: true,
    );
  }

  /// Clears the nickname validation error.
  void clearNicknameError() {
    state = state.copyWith(clearNicknameError: true);
  }
}

/// Provider for [ProfileNotifier].
final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  final authNotifier = ref.watch(authNotifierProvider.notifier);

  return ProfileNotifier(
    userRepository: userRepository,
    authNotifier: authNotifier,
  );
});

/// Provider for profile loading state.
final profileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(profileNotifierProvider).isLoading;
});

/// Provider for nickname update loading state.
final nicknameUpdatingProvider = Provider<bool>((ref) {
  return ref.watch(profileNotifierProvider).isUpdatingNickname;
});

/// Provider for avatar update loading state.
final avatarUpdatingProvider = Provider<bool>((ref) {
  return ref.watch(profileNotifierProvider).isUpdatingAvatar;
});
