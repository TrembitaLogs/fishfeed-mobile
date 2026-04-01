import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/core/di/repository_providers.dart';
import 'package:fishfeed/domain/repositories/user_repository.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

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
      nicknameError: clearNicknameError
          ? null
          : (nicknameError ?? this.nicknameError),
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
  int get hashCode =>
      Object.hash(isUpdatingNickname, isUpdatingAvatar, error, nicknameError);
}

/// Notifier for managing profile state.
///
/// Provides methods for updating user profile information including
/// nickname and avatar.
class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier({
    required UserRepository userRepository,
    required AuthNotifier authNotifier,
    required SyncService syncService,
  }) : _userRepository = userRepository,
       _authNotifier = authNotifier,
       _syncService = syncService,
       super(const ProfileState.initial());

  final UserRepository _userRepository;
  final AuthNotifier _authNotifier;
  final SyncService _syncService;

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
        nicknameError:
            'Nickname must be at least $minNicknameLength characters',
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

    try {
      // 1. Get current user from auth state
      final currentUser = _authNotifier.state.user;
      if (currentUser == null) {
        state = state.copyWith(
          isUpdatingNickname: false,
          error: const UnexpectedFailure(message: 'No authenticated user'),
        );
        return false;
      }

      // 2. Save to local storage via repository (offline-first)
      final result = await _userRepository.updateDisplayNameLocally(
        currentUser: currentUser,
        displayName: trimmedNickname,
      );

      return result.fold(
        (failure) {
          state = state.copyWith(isUpdatingNickname: false, error: failure);
          return false;
        },
        (updatedUser) async {
          // 3. Update auth state
          _authNotifier.updateUser(updatedUser);

          // 4. Trigger sync to push changes to server
          await _syncService.syncAll();

          state = state.copyWith(isUpdatingNickname: false);
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(
        isUpdatingNickname: false,
        error: UnexpectedFailure(message: e.toString()),
      );
      return false;
    }
  }

  /// Updates the user's avatar.
  ///
  /// Uploads the image file and updates the auth state on success.
  Future<bool> updateAvatar(File avatarFile) async {
    state = state.copyWith(isUpdatingAvatar: true, clearError: true);

    final result = await _userRepository.updateAvatar(avatarFile: avatarFile);

    return result.fold(
      (failure) {
        state = state.copyWith(isUpdatingAvatar: false, error: failure);
        return false;
      },
      (user) {
        state = state.copyWith(isUpdatingAvatar: false);
        _authNotifier.updateUser(user);
        return true;
      },
    );
  }

  /// Updates the user's avatar key locally.
  ///
  /// Sets [avatarKey] on the local user model and auth state.
  /// Used by [ImagePickerButton] flow: the key is either a `local://{uuid}`
  /// (pending upload) or `null` (remove avatar).
  /// The actual S3 upload is handled by [ImageUploadService].
  Future<bool> updateAvatarKey(String? avatarKey) async {
    try {
      // 1. Get current user from auth state
      final currentUser = _authNotifier.state.user;
      if (currentUser == null) return false;

      // 2. Save to local storage via repository (offline-first)
      final result = await _userRepository.updateAvatarKeyLocally(
        currentUser: currentUser,
        avatarKey: avatarKey,
      );

      return result.fold(
        (failure) {
          state = state.copyWith(error: failure);
          return false;
        },
        (updatedUser) {
          // 3. Update auth state for immediate UI reactivity
          _authNotifier.updateUser(updatedUser);
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(error: UnexpectedFailure(message: e.toString()));
      return false;
    }
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
    state = state.copyWith(clearError: true, clearNicknameError: true);
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
      final syncService = ref.watch(syncServiceProvider);

      return ProfileNotifier(
        userRepository: userRepository,
        authNotifier: authNotifier,
        syncService: syncService,
      );
    });

/// Provider for profile loading state.
final profileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(profileNotifierProvider.select((s) => s.isLoading));
});

/// Provider for nickname update loading state.
final nicknameUpdatingProvider = Provider<bool>((ref) {
  return ref.watch(profileNotifierProvider.select((s) => s.isUpdatingNickname));
});

/// Provider for avatar update loading state.
final avatarUpdatingProvider = Provider<bool>((ref) {
  return ref.watch(profileNotifierProvider.select((s) => s.isUpdatingAvatar));
});
