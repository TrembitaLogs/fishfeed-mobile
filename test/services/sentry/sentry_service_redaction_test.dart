import 'package:fishfeed/services/sentry/sentry_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  group('SentryService.redactSensitiveData', () {
    test('strips Authorization header from request on any path', () {
      final event = SentryEvent(
        request: SentryRequest(
          url: 'https://api.fishfeed.club/api/v1/aquariums',
          method: 'GET',
          headers: {
            'Authorization': 'Bearer secret-access-token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final redacted = SentryService.redactSensitiveData(event);

      expect(redacted.request?.headers['Authorization'], '<redacted>');
      expect(redacted.request?.headers['Content-Type'], 'application/json');
    });

    test('strips Cookie header from request on any path', () {
      final event = SentryEvent(
        request: SentryRequest(
          url: 'https://api.fishfeed.club/api/v1/aquariums',
          headers: {'Cookie': 'session=secret-session-id'},
        ),
      );

      final redacted = SentryService.redactSensitiveData(event);

      expect(redacted.request?.headers['Cookie'], '<redacted>');
    });

    test('replaces request data with <redacted> on /auth/login', () {
      final event = SentryEvent(
        request: SentryRequest(
          url: 'https://api.fishfeed.club/api/v1/auth/login',
          method: 'POST',
          data: {'email': 'user@example.com', 'password': 'plaintext-password'},
        ),
      );

      final redacted = SentryService.redactSensitiveData(event);

      expect(redacted.request?.data, '<redacted>');
    });

    test('replaces request data with <redacted> on /auth/refresh', () {
      final event = SentryEvent(
        request: SentryRequest(
          url: 'https://api.fishfeed.club/api/v1/auth/refresh',
          method: 'POST',
          data: '{"refresh_token":"rt-secret-jwt"}',
        ),
      );

      final redacted = SentryService.redactSensitiveData(event);

      expect(redacted.request?.data, '<redacted>');
    });

    test('replaces request data with <redacted> on /users/me/password', () {
      final event = SentryEvent(
        request: SentryRequest(
          url: 'https://api.fishfeed.club/api/v1/users/me/password',
          method: 'PUT',
          data: {'old_password': 'old-secret', 'new_password': 'new-secret'},
        ),
      );

      final redacted = SentryService.redactSensitiveData(event);

      expect(redacted.request?.data, '<redacted>');
    });

    test('preserves request data on non-sensitive endpoints', () {
      final originalData = {'name': 'My Aquarium', 'volume_liters': 100};
      final event = SentryEvent(
        request: SentryRequest(
          url: 'https://api.fishfeed.club/api/v1/aquariums',
          method: 'POST',
          data: originalData,
        ),
      );

      final redacted = SentryService.redactSensitiveData(event);

      expect(redacted.request?.data, originalData);
    });

    test('strips Authorization from http breadcrumb data', () {
      final event = SentryEvent(
        breadcrumbs: [
          Breadcrumb(
            category: 'http',
            type: 'http',
            data: {
              'url': 'https://api.fishfeed.club/api/v1/aquariums',
              'method': 'GET',
              'Authorization': 'Bearer secret-access-token',
            },
          ),
        ],
      );

      final redacted = SentryService.redactSensitiveData(event);

      expect(redacted.breadcrumbs?.first.data?['Authorization'], '<redacted>');
      expect(redacted.breadcrumbs?.first.data?['url'], isNotNull);
    });

    test(
      'redacts breadcrumb body fields when url targets sensitive endpoint',
      () {
        final event = SentryEvent(
          breadcrumbs: [
            Breadcrumb(
              category: 'http',
              type: 'http',
              data: {
                'url': 'https://api.fishfeed.club/api/v1/auth/login',
                'method': 'POST',
                'request_body': '{"email":"a@b.c","password":"plain"}',
                'response_body': '{"access_token":"jwt"}',
              },
            ),
          ],
        );

        final redacted = SentryService.redactSensitiveData(event);

        final crumbData = redacted.breadcrumbs?.first.data;
        expect(crumbData?['request_body'], '<redacted>');
        expect(crumbData?['response_body'], '<redacted>');
        expect(crumbData?['url'], isNotNull);
      },
    );

    test('handles event with null request gracefully', () {
      final event = SentryEvent(message: SentryMessage('error'));

      final redacted = SentryService.redactSensitiveData(event);

      expect(redacted.request, isNull);
      expect(redacted.message?.formatted, 'error');
    });

    test('handles event with null breadcrumbs gracefully', () {
      final event = SentryEvent(
        request: SentryRequest(url: 'https://api.fishfeed.club/health'),
      );

      final redacted = SentryService.redactSensitiveData(event);

      expect(redacted.breadcrumbs, isNull);
    });

    test('case-insensitive Authorization header match', () {
      final event = SentryEvent(
        request: SentryRequest(
          url: 'https://api.fishfeed.club/api/v1/aquariums',
          headers: {'authorization': 'Bearer secret-token'},
        ),
      );

      final redacted = SentryService.redactSensitiveData(event);

      final headers = redacted.request?.headers ?? const {};
      final hasUnredactedAuth = headers.entries.any(
        (e) =>
            e.key.toLowerCase() == 'authorization' && e.value != '<redacted>',
      );
      expect(hasUnredactedAuth, isFalse);
    });
  });
}
