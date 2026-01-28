import 'package:flutter/foundation.dart';

/// Authentication state for router redirect logic.
///
/// This is a temporary implementation for routing purposes.
/// Will be replaced with actual authentication logic in auth tasks.
class AuthState extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _hasCompletedOnboarding = false;

  /// Whether the user is currently logged in.
  bool get isLoggedIn => _isLoggedIn;

  /// Whether the user has completed the onboarding flow.
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  /// Log the user in (mock implementation).
  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  /// Log the user out (mock implementation).
  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  /// Mark onboarding as completed.
  void completeOnboarding() {
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  /// Reset onboarding status.
  void resetOnboarding() {
    _hasCompletedOnboarding = false;
    notifyListeners();
  }

  /// Update full auth state at once.
  void updateState({
    required bool isLoggedIn,
    required bool hasCompletedOnboarding,
  }) {
    _isLoggedIn = isLoggedIn;
    _hasCompletedOnboarding = hasCompletedOnboarding;
    notifyListeners();
  }
}
