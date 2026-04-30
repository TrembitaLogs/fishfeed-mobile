/// Stable backend error_code identifiers, mirroring `app/core/errors.py::ErrorCode`.
///
/// Keep these in sync with the backend enum. The backend's
/// `tests/core/test_errors.py::test_error_code_values_are_stable` is the
/// canonical reference — if a value changes there, update it here too.
///
/// String constants instead of an enum so they can appear directly in `switch`
/// patterns and round-trip from JSON without conversion.
abstract final class ApiErrorCodes {
  ApiErrorCodes._();

  // Generic / framework
  static const String validationError = 'validation.error';
  static const String internalError = 'server.internal_error';
  static const String rateLimited = 'rate_limited';

  // Auth namespace
  static const String authEmailExists = 'auth.email_already_exists';
  static const String authInvalidCredentials = 'auth.invalid_credentials';
  static const String authInvalidRefreshToken = 'auth.invalid_refresh_token';
  static const String authInvalidOAuthToken = 'auth.invalid_oauth_token';
  static const String authOAuthNotConfigured = 'auth.oauth_not_configured';
  static const String authInvalidResetToken = 'auth.invalid_reset_token';
  static const String authOAuthPasswordChangeDisallowed =
      'auth.oauth_password_change_disallowed';
  static const String authInvalidOldPassword = 'auth.invalid_old_password';

  // Aquarium namespace
  static const String aquariumNotFound = 'aquarium.not_found';
  static const String aquariumAccessDenied = 'aquarium.access_denied';
  static const String aquariumOwnerRequired = 'aquarium.owner_required';

  // Fish namespace
  static const String fishNotFound = 'fish.not_found';

  // Species namespace
  static const String speciesNotFound = 'species.not_found';
  static const String speciesAlreadyExists = 'species.already_exists';

  // Sync namespace
  static const String syncValidation = 'sync.validation_error';
  static const String syncAccessDenied = 'sync.access_denied';
  static const String syncFailed = 'sync.processing_failed';

  // Feeding namespace
  static const String feedingValidation = 'feeding.validation_error';
  static const String feedingScheduleNotFound = 'feeding.schedule_not_found';
  static const String feedingLogConflict = 'feeding.log_conflict';
  static const String feedingDateRangeTooLarge = 'feeding.date_range_too_large';
}
