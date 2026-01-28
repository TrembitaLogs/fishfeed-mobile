import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/core/utils/auth_error_handler.dart';
import 'package:fishfeed/l10n/app_localizations.dart';

void main() {
  group('AuthErrorHandler extension', () {
    Widget buildTestWidget({required Widget Function(BuildContext) builder}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) => Scaffold(body: builder(context))),
      );
    }

    group('showAuthError', () {
      testWidgets('shows error snackbar for NetworkFailure', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            builder: (context) => ElevatedButton(
              onPressed: () {
                context.showAuthError(const NetworkFailure());
              },
              child: const Text('Show'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(
          find.text('No internet connection. Please check your network.'),
          findsOneWidget,
        );
      });

      testWidgets('shows error snackbar for ServerFailure', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            builder: (context) => ElevatedButton(
              onPressed: () {
                context.showAuthError(const ServerFailure());
              },
              child: const Text('Show'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(
          find.text('Server error. Please try again later.'),
          findsOneWidget,
        );
      });

      testWidgets('shows error snackbar for AuthenticationFailure', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            builder: (context) => ElevatedButton(
              onPressed: () {
                context.showAuthError(const AuthenticationFailure());
              },
              child: const Text('Show'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(
          find.text('Invalid email or password. Please try again.'),
          findsOneWidget,
        );
      });

      testWidgets('shows error snackbar for ValidationFailure', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            builder: (context) => ElevatedButton(
              onPressed: () {
                context.showAuthError(
                  const ValidationFailure(
                    errors: {
                      'email': ['Email is already taken'],
                    },
                  ),
                );
              },
              child: const Text('Show'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.text('Email is already taken'), findsOneWidget);
      });

      testWidgets('shows generic validation message for empty errors', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            builder: (context) => ElevatedButton(
              onPressed: () {
                context.showAuthError(const ValidationFailure());
              },
              child: const Text('Show'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(
          find.text('Please check your input and try again.'),
          findsOneWidget,
        );
      });

      testWidgets('shows error snackbar for Google OAuthFailure', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            builder: (context) => ElevatedButton(
              onPressed: () {
                context.showAuthError(const OAuthFailure(provider: 'google'));
              },
              child: const Text('Show'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(
          find.text('Google sign in failed. Please try again.'),
          findsOneWidget,
        );
      });

      testWidgets('shows error snackbar for Apple OAuthFailure', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            builder: (context) => ElevatedButton(
              onPressed: () {
                context.showAuthError(const OAuthFailure(provider: 'apple'));
              },
              child: const Text('Show'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(
          find.text('Apple sign in failed. Please try again.'),
          findsOneWidget,
        );
      });

      testWidgets('shows generic OAuth error for unknown provider', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            builder: (context) => ElevatedButton(
              onPressed: () {
                context.showAuthError(const OAuthFailure());
              },
              child: const Text('Show'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.text('Sign in failed. Please try again.'), findsOneWidget);
      });

      testWidgets('shows error snackbar for CancellationFailure', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            builder: (context) => ElevatedButton(
              onPressed: () {
                context.showAuthError(const CancellationFailure());
              },
              child: const Text('Show'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.text('Operation was cancelled.'), findsOneWidget);
      });

      testWidgets('shows error snackbar for CacheFailure', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            builder: (context) => ElevatedButton(
              onPressed: () {
                context.showAuthError(const CacheFailure());
              },
              child: const Text('Show'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(
          find.text('Local storage error. Please restart the app.'),
          findsOneWidget,
        );
      });

      testWidgets('shows error snackbar for UnexpectedFailure', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            builder: (context) => ElevatedButton(
              onPressed: () {
                context.showAuthError(const UnexpectedFailure());
              },
              child: const Text('Show'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(
          find.text('An unexpected error occurred. Please try again.'),
          findsOneWidget,
        );
      });
    });

    group('showAuthSuccess', () {
      testWidgets('shows success snackbar', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            builder: (context) => ElevatedButton(
              onPressed: () {
                context.showAuthSuccess('Welcome back!');
              },
              child: const Text('Show'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.text('Welcome back!'), findsOneWidget);
      });
    });
  });

  group('FailureMessageMapper', () {
    test('returns correct message for NetworkFailure', () {
      final message = FailureMessageMapper.toMessage(const NetworkFailure());
      expect(message, 'No internet connection. Please check your network.');
    });

    test('returns correct message for ServerFailure', () {
      final message = FailureMessageMapper.toMessage(const ServerFailure());
      expect(message, 'Server error. Please try again later.');
    });

    test('returns correct message for AuthenticationFailure', () {
      final message = FailureMessageMapper.toMessage(
        const AuthenticationFailure(),
      );
      expect(message, 'Invalid credentials. Please try again.');
    });

    test('returns custom message for ValidationFailure', () {
      final message = FailureMessageMapper.toMessage(
        const ValidationFailure(message: 'Custom validation error'),
      );
      expect(message, 'Custom validation error');
    });

    test('returns default message for ValidationFailure without message', () {
      final message = FailureMessageMapper.toMessage(const ValidationFailure());
      expect(message, 'Validation failed');
    });

    test('returns custom message for OAuthFailure', () {
      final message = FailureMessageMapper.toMessage(
        const OAuthFailure(provider: 'google', message: 'Custom OAuth error'),
      );
      expect(message, 'Custom OAuth error');
    });

    test('returns default message for OAuthFailure with provider', () {
      // OAuthFailure has a default message, so it uses that
      final message = FailureMessageMapper.toMessage(
        const OAuthFailure(provider: 'google'),
      );
      expect(message, 'OAuth authentication failed');
    });

    test('returns default message for OAuthFailure without provider', () {
      final message = FailureMessageMapper.toMessage(const OAuthFailure());
      expect(message, 'OAuth authentication failed');
    });

    test('returns correct message for CancellationFailure', () {
      final message = FailureMessageMapper.toMessage(
        const CancellationFailure(),
      );
      expect(message, 'Operation was cancelled.');
    });

    test('returns correct message for CacheFailure', () {
      final message = FailureMessageMapper.toMessage(const CacheFailure());
      expect(message, 'Local storage error. Please restart the app.');
    });

    test('returns custom message for UnexpectedFailure', () {
      final message = FailureMessageMapper.toMessage(
        const UnexpectedFailure(message: 'Custom error'),
      );
      expect(message, 'Custom error');
    });

    test('returns default message for UnexpectedFailure without message', () {
      final message = FailureMessageMapper.toMessage(const UnexpectedFailure());
      expect(message, 'An unexpected error occurred');
    });
  });
}
