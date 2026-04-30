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

    test('maps user/GDPR/family codes to localized EN strings', () async {
      final l10n = await _loadL10n(const Locale('en'));

      expect(
        localizeApiErrorCode(ApiErrorCodes.userNotFound, l10n),
        'User account not found.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.gdprExportFailed, l10n),
        'Failed to export your data. Please try again later.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.gdprDeleteFailed, l10n),
        'Failed to delete your data. Please try again later.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.familyMemberLimitExceeded, l10n),
        'Family member limit reached. Upgrade to Premium for more spaces.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.familyInviteNotFound, l10n),
        'This invite link is invalid. Please request a new one.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.familyInviteExpired, l10n),
        'This invite link has expired. Please request a new one.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.familyAlreadyMember, l10n),
        'You are already a member of this aquarium.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.familyMemberNotFound, l10n),
        'This member is not part of the aquarium.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.familyCannotRemoveOwner, l10n),
        'The aquarium owner cannot be removed.',
      );
    });

    test('maps user/GDPR/family codes to localized DE strings', () async {
      final l10n = await _loadL10n(const Locale('de'));

      expect(
        localizeApiErrorCode(ApiErrorCodes.userNotFound, l10n),
        'Benutzerkonto nicht gefunden.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.gdprExportFailed, l10n),
        'Datenexport fehlgeschlagen. Bitte versuchen Sie es später erneut.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.familyMemberLimitExceeded, l10n),
        'Familienmitglieder-Limit erreicht. Upgrade auf Premium für mehr Plätze.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.familyInviteExpired, l10n),
        'Dieser Einladungslink ist abgelaufen. Bitte fordern Sie einen neuen an.',
      );
      expect(
        localizeApiErrorCode(ApiErrorCodes.familyCannotRemoveOwner, l10n),
        'Der Aquariumsbesitzer kann nicht entfernt werden.',
      );
    });

    test(
      'returns null for storage_not_configured to avoid leaking server detail',
      () async {
        final l10n = await _loadL10n(const Locale('en'));
        expect(
          localizeApiErrorCode(ApiErrorCodes.storageNotConfigured, l10n),
          isNull,
          reason:
              'Server-misconfig codes intentionally fall back to generic '
              'localized message instead of leaking implementation details.',
        );
      },
    );
  });
}
