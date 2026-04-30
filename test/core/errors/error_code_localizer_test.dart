import 'package:fishfeed/core/errors/api_error_codes.dart';
import 'package:fishfeed/core/errors/error_code_localizer.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppLocalizations> _loadL10n(Locale locale) async {
  final delegate = AppLocalizations.delegate;
  return delegate.load(locale);
}

void main() {
  group('localizeApiErrorCode', () {
    test('returns null for null code', () async {
      final l10n = await _loadL10n(const Locale('en'));
      expect(localizeApiErrorCode(null, l10n), isNull);
    });

    test('returns null for unmapped code', () async {
      final l10n = await _loadL10n(const Locale('en'));
      expect(
        localizeApiErrorCode(ApiErrorCodes.aquariumOwnerRequired, l10n),
        isNull,
        reason:
            'Aquarium codes have no dedicated user-facing string yet; '
            'caller falls back to per-failure-type defaults.',
      );
    });

    test('maps each auth code to a localized EN string', () async {
      final l10n = await _loadL10n(const Locale('en'));

      expect(
        localizeApiErrorCode(ApiErrorCodes.authEmailExists, l10n),
        'An account with this email already exists.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.authInvalidCredentials, l10n),
        'Invalid email or password. Please try again.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.authInvalidRefreshToken, l10n),
        'Your session has expired. Please sign in again.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.authInvalidResetToken, l10n),
        'This password reset link is invalid or has expired.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.authInvalidOldPassword, l10n),
        'Your current password is incorrect.',
      );
      expect(
        localizeApiErrorCode(
          ApiErrorCodes.authOAuthPasswordChangeDisallowed,
          l10n,
        ),
        "Password change isn't available for accounts created with Google or Apple.",
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.authOAuthNotConfigured, l10n),
        'This sign-in option is currently unavailable. Please try another method.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.rateLimited, l10n),
        'Too many attempts. Please wait a moment and try again.',
      );
    });

    test('maps the same codes to localized DE strings', () async {
      final l10n = await _loadL10n(const Locale('de'));

      expect(
        localizeApiErrorCode(ApiErrorCodes.authEmailExists, l10n),
        'Ein Konto mit dieser E-Mail existiert bereits.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.authInvalidOldPassword, l10n),
        'Ihr aktuelles Passwort ist falsch.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.rateLimited, l10n),
        'Zu viele Versuche. Bitte warten Sie einen Moment und versuchen Sie es erneut.',
      );
    });
  });
}
