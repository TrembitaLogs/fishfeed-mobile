import 'package:fishfeed/core/errors/api_error_codes.dart';
import 'package:fishfeed/l10n/app_localizations.dart';

/// Maps a backend `error_code` to a localized user-facing string.
///
/// Returns `null` when no mapping exists for the given code (or when [code]
/// itself is `null`). Callers should fall back to per-failure-type defaults
/// in that case.
///
/// Codes that don't have a dedicated user-facing message (e.g. server
/// internal errors, sync internals) intentionally return `null` so that the
/// generic localized fallback is shown instead of leaking machine identifiers.
String? localizeApiErrorCode(String? code, AppLocalizations l10n) {
  if (code == null) return null;

  return switch (code) {
    ApiErrorCodes.authEmailExists => l10n.errorEmailAlreadyExists,
    ApiErrorCodes.authInvalidCredentials => l10n.errorInvalidCredentials,
    ApiErrorCodes.authInvalidRefreshToken => l10n.errorSessionExpired,
    ApiErrorCodes.authInvalidOAuthToken => l10n.errorOAuth,
    ApiErrorCodes.authOAuthNotConfigured => l10n.errorOAuthProviderUnavailable,
    ApiErrorCodes.authInvalidResetToken => l10n.errorInvalidResetLink,
    ApiErrorCodes.authOAuthPasswordChangeDisallowed =>
      l10n.errorOAuthAccountPasswordChange,
    ApiErrorCodes.authInvalidOldPassword => l10n.errorInvalidOldPassword,
    ApiErrorCodes.rateLimited => l10n.errorTooManyRequests,
    // User namespace
    ApiErrorCodes.userNotFound => l10n.errorUserNotFound,
    // GDPR namespace
    ApiErrorCodes.gdprExportFailed => l10n.errorGdprExportFailed,
    ApiErrorCodes.gdprDeleteFailed => l10n.errorGdprDeleteFailed,
    // Family namespace
    ApiErrorCodes.familyMemberLimitExceeded =>
      l10n.errorFamilyMemberLimitExceeded,
    ApiErrorCodes.familyInviteNotFound => l10n.errorFamilyInviteNotFound,
    ApiErrorCodes.familyInviteExpired => l10n.errorFamilyInviteExpired,
    ApiErrorCodes.familyAlreadyMember => l10n.errorFamilyAlreadyMember,
    ApiErrorCodes.familyMemberNotFound => l10n.errorFamilyMemberNotFound,
    ApiErrorCodes.familyCannotRemoveOwner => l10n.errorFamilyCannotRemoveOwner,
    _ => null,
  };
}
