import 'package:flutter_test/flutter_test.dart';
import 'package:fishfeed/presentation/providers/auth_state.dart';

void main() {
  group('AuthState', () {
    late AuthState authState;

    setUp(() {
      authState = AuthState();
    });

    tearDown(() {
      authState.dispose();
    });

    group('initial state', () {
      test('isLoggedIn is false by default', () {
        expect(authState.isLoggedIn, false);
      });

      test('hasCompletedOnboarding is false by default', () {
        expect(authState.hasCompletedOnboarding, false);
      });
    });

    group('login', () {
      test('sets isLoggedIn to true', () {
        authState.login();
        expect(authState.isLoggedIn, true);
      });

      test('notifies listeners', () {
        var notified = false;
        authState.addListener(() => notified = true);

        authState.login();

        expect(notified, true);
      });
    });

    group('logout', () {
      test('sets isLoggedIn to false', () {
        authState.login();
        authState.logout();
        expect(authState.isLoggedIn, false);
      });

      test('notifies listeners', () {
        authState.login();

        var notified = false;
        authState.addListener(() => notified = true);

        authState.logout();

        expect(notified, true);
      });
    });

    group('completeOnboarding', () {
      test('sets hasCompletedOnboarding to true', () {
        authState.completeOnboarding();
        expect(authState.hasCompletedOnboarding, true);
      });

      test('notifies listeners', () {
        var notified = false;
        authState.addListener(() => notified = true);

        authState.completeOnboarding();

        expect(notified, true);
      });
    });

    group('resetOnboarding', () {
      test('sets hasCompletedOnboarding to false', () {
        authState.completeOnboarding();
        authState.resetOnboarding();
        expect(authState.hasCompletedOnboarding, false);
      });

      test('notifies listeners', () {
        authState.completeOnboarding();

        var notified = false;
        authState.addListener(() => notified = true);

        authState.resetOnboarding();

        expect(notified, true);
      });
    });

    group('updateState', () {
      test('updates both isLoggedIn and hasCompletedOnboarding', () {
        authState.updateState(isLoggedIn: true, hasCompletedOnboarding: true);

        expect(authState.isLoggedIn, true);
        expect(authState.hasCompletedOnboarding, true);
      });

      test('notifies listeners once', () {
        var notifyCount = 0;
        authState.addListener(() => notifyCount++);

        authState.updateState(isLoggedIn: true, hasCompletedOnboarding: true);

        expect(notifyCount, 1);
      });
    });
  });
}
